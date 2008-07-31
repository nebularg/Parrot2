local VERSION = tonumber(("$Revision: 78982 $"):match("%d+"))

local Parrot = Parrot, Parrot
local Parrot_CombatEvents = Parrot:NewModule("CombatEvents", "LibRockEvent-1.0", "LibRockTimer-1.0")
local self = Parrot_CombatEvents
if Parrot.revision < VERSION then
	Parrot.version = "r" .. VERSION
	Parrot.revision = VERSION
	Parrot.date = ("$Date: 2008-07-23 14:17:53 +0200 (Wed, 23 Jul 2008) $"):match("%d%d%d%d%-%d%d%-%d%d")
end

-- to track XP and Honor-gains
local currentXP
local currentHonor

-- #AUTODOC_NAMESPACE Parrot_CombatEvents

local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot_CombatEvents")

local RockEvent = Rock("LibRockEvent-1.0")
local RockTimer = Rock("LibRockTimer-1.0")

local SharedMedia = LibStub("LibSharedMedia-3.0")
local deformat = AceLibrary("Deformat-2.0")

local _G = _G
local UNKNOWN = _G.UNKNOWN
if type(UNKNOWN) ~= "string" then
	UNKNOWN = "Unknown"
end

local _,playerClass = _G.UnitClass("player")
local newList, del, newDict = Rock:GetRecyclingFunctions("Parrot", "newList", "del", "newDict")

local bit_bor	= bit.bor
local bit_band  = bit.band

Parrot_CombatEvents.PlayerGUID = nil
Parrot_CombatEvents.PlayerName = nil
Parrot_CombatEvents.PetGUID = nil
Parrot_CombatEvents.PetName = nil

Parrot_CombatEvents.db = Parrot:GetDatabaseNamespace("CombatEvents")
Parrot:SetDatabaseNamespaceDefaults("CombatEvents", "profile", {
	['*'] = {
		['*'] = {}
	},
	filters = {},
	throttles = {},
	abbreviateStyle = "abbreviate",
	abbreviateLength = 30,
	stickyCrit = true,
	damageTypes = {
		color = true,
		["Physical"] = "ffffff",
		["Holy"] = "ffff7f",
		["Fire"] = "ff7f7f",
		["Nature"] = "7fff7f",
		["Frost"] = "7f7fff",
		["Shadow"] = "7f007f",
		["Arcane"] = "ff7fff",
	},
	modifier = {
		color = true,
		crit = {
			enabled = false,
			color = "ffffff",
			tag = L["[Text] (crit)"],
		},
		crushing = {
			enabled = true,
			color = "7f0000",
			tag = L["[Text] (crushing)"],
		},
		glancing = {
			enabled = true,
			color = "ff0000",
			tag = L["[Text] (glancing)"],
		},
		absorb = {
			enabled = true,
			color = "ffff00",
			tag = L[" ([Amount] absorbed)"],
		},
		block = {
			enabled = true,
			color = "7f00ff",
			tag = L[" ([Amount] blocked)"],
		},
		resist = {
			enabled = true,
			color = "7f007f",
			tag = L[" ([Amount] resisted)"],
		},
		vulnerable = {
			enabled = true,
			color = "7f7fff",
			tag = L[" ([Amount] vulnerable)"],
		},
		overheal = {
			enabled = true,
			color = "00af7f",
			tag = L[" ([Amount] overheal)"],
		},
	},
})

local combatEvents = {}

local Parrot_Display
local Parrot_ScrollAreas
local Parrot_TriggerConditions

function Parrot_CombatEvents:OnInitialize()
	Parrot_Display = Parrot:GetModule("Display")
	Parrot_ScrollAreas = Parrot:GetModule("ScrollAreas")
	Parrot_TriggerConditions = Parrot:GetModule("TriggerConditions")
	if (disabled) then
		
		-- Combatlog
		self:RemoveEventListener("Blizzard", "COMBAT_LOG_EVENT_UNFILTERED");
		
		-- loot
		self:RemoveEventListener("Blizzard", "CHAT_MSG_LOOT")
		self:RemoveEventListener("Blizzard", "CHAT_MSG_MONEY")
		
		-- XP-gains
		self:RemoveEventListener("Blizzard", "PLAYER_XP_UPDATE")
		
		-- honorgains
		self:RemoveEventListener("Blizzard", "HONOR_CURRENCY_UPDATE")
		
		-- Skillgains
		self:RemoveEventListener("Blizzard", "CHAT_MSG_SKILL")
		
		-- Reputationgains
		self:RemoveEventListener("Blizzard", "CHAT_MSG_COMBAT_FACTION_CHANGE")
		
	else
		
		-- Combatlog
		self:AddEventListener("Blizzard", "COMBAT_LOG_EVENT_UNFILTERED", "OnEvent");
		
		--LootEvents
		self:AddEventListener("Blizzard", "CHAT_MSG_LOOT", "OnLootEvent")
		self:AddEventListener("Blizzard", "CHAT_MSG_MONEY", "OnLootEvent")
		
		-- Experiencegains
		self:AddEventListener("Blizzard", "PLAYER_XP_UPDATE", "OnXPgainEvent" )
		
		-- honorgains
		self:AddEventListener("Blizzard", "HONOR_CURRENCY_UPDATE", "OnHonorgainEvent")
		
		-- Skillgains
		self:AddEventListener("Blizzard", "CHAT_MSG_SKILL", "OnSkillgainEvent" )
		
		-- Reputationgains
		self:AddEventListener("Blizzard", "CHAT_MSG_COMBAT_FACTION_CHANGE", "OnRepgainEvent")
		

		
	end
	
	
	
	

end

local onEnableFuncs = {}
local enabled = false
function Parrot_CombatEvents:OnEnable(first)
	enabled = true

	if first then
		local tmp = newList("Notification", "Incoming", "Outgoing")
		for _,category in ipairs(tmp) do
			local t = newList()
			for name, data in pairs(self.db.profile[category]) do
				t[name] = data
				self.db.profile[category][name] = nil
			end
			for name, data in pairs(t) do
				if combatEvents[name] then
					self.db.profile[category][name] = data
					t[name] = nil
				else
					local name_lower = name:lower()
					for k,v in pairs(combatEvents[category]) do
						if k:lower() == name_lower then
							self.db.profile[category][k] = data
							t[name] = nil
							break
						end
					end
					if not t[name] then
						self.db.profile[category][name] = data
					end
				end
			end
			t = del(t)
		end
		tmp = del(tmp)
	end
	
	for _,v in ipairs(onEnableFuncs) do
		v()
	end
	
		
	Parrot_CombatEvents.PlayerGUID = UnitGUID("player")
	Parrot_CombatEvents.PlayerName = UnitName("player")
	
	currentHonor = GetHonorCurrency()
	currentXP = UnitXP("player")

end

local onDisableFuncs = {}
function Parrot_CombatEvents:OnDisable()
	enabled = false
	for _,v in ipairs(onDisableFuncs) do
		v()
	end
end

local function utf8trunc(text, num)
	local len = 0
	local i = 1
	local text_len = #text
	while len < num and i <= text_len do
		len = len + 1
		local b = text:byte(i)
		if b <= 127 then
			i = i + 1
		elseif b <= 223 then
			i = i + 2
		elseif b <= 239 then
			i = i + 3
		else
			i = i + 4
		end
	end
	return text:sub(1, i-1)
end

function Parrot_CombatEvents:GetAbbreviatedSpell(name)
	local style = self.db.profile.abbreviateStyle
	if style == "none" then
		return name
	end
	local len = 0
	local i = 1
	local name_len = #name
	while i <= name_len do
		len = len + 1
		local b = name:byte(i)
		if b <= 127 then
			i = i + 1
		elseif b <= 223 then
			i = i + 2
		elseif b <= 239 then
			i = i + 3
		else
			i = i + 4
		end
	end
	local neededLen = self.db.profile.abbreviateLength
	if len < neededLen then
		return name
	end
	if style == "abbreviate" then
		if name:find("[%(%)]") then
			name = name:gsub("%b()", ""):gsub("  +", " "):gsub("^ +", ""):gsub(" +$", "")
		end
		local t = newList((" "):split(name))
		if #t == 1 then
			t = del(t)
			return name
		end
		local i = 0
		while i < #t do
			i = i + 1
			if t[i] == '' then
				table.remove(t, i)
				i = i - 1
			end
		end
		if #t == 1 then
			t = del(t)
			return name
		end
		for i = 1, #t do
			local len
			local b = t[i]:byte(1)
			if b <= 127 then
				len = 1
			elseif b <= 223 then
				len = 2
			elseif b <= 239 then
				len = 3
			else
				len = 4
			end
			if len then
				local alpha, bravo = t[i]:sub(1, len), t[i]:sub(len+1)
				if bravo:find(":") then
					t[i] = alpha .. ":"
				else
					t[i] = alpha
				end
			else
				t[i] = ''
			end
		end
		local s = table.concat(t)
		t = del(t)
		return s
	elseif style == "truncate" then
		local num = neededLen-3
		if num < 3 then
			num = 3
		end
		return utf8trunc(name, neededLen) .. "..."
	end
	return name
end

local function refreshEventRegistration(category, name)
	if not enabled then
		return
	end
	local data = combatEvents[category][name]
	local db = Parrot_CombatEvents.db.profile[category][name]
	local disabled = db.disabled
	if disabled == nil then
		disabled = data.defaultDisabled
	end
	local blizzardEvent = data.blizzardEvent
	local blizzardEvent_ns, blizzardEvent_ev
	if blizzardEvent then
		blizzardEvent_ns, blizzardEvent_ev = (";"):split(blizzardEvent, 2)
		if not blizzardEvent_ev then
			blizzardEvent_ns, blizzardEvent_ev = "Blizzard", blizzardEvent_ns
		end
	end
	if disabled then
		if blizzardEvent then
			Parrot_CombatEvents:RemoveEventListener(blizzardEvent_ns, blizzardEvent_ev)
		end
	else
		if blizzardEvent then
			Parrot_CombatEvents:AddEventListener(blizzardEvent_ns, blizzardEvent_ev, function(ns, event, ...)
				local info = newList(...)
				info.namespace = ns
				info.event = event
				info.uid = -RockEvent.currentUID
				Parrot_CombatEvents:TriggerCombatEvent(category, name, info)
				info = del(info)
			end)
		end
	end
end

onEnableFuncs[#onEnableFuncs+1] = function()
	assert(enabled)
	for category, q in pairs(combatEvents) do
		for name, data in pairs(q) do
			refreshEventRegistration(category, name)
		end
	end
end

local modifierTranslationHelps

local throttleTypes = {}
local throttleDefaultTimes = {}
local throttleWaitStyles = {}

local filterTypes = {}
local filterDefaults = {}

local function createOption() end
local function createThrottleOption() end
local function createFilterOption() end

local function hexColorToTuple(color)
	local num = tonumber(color, 16)
	return math.floor(num / 256^2)/255, math.floor((num / 256)%256)/255, (num%256)/255
end

function Parrot_CombatEvents:OnOptionsCreate()
	local events_opt
	events_opt = {
		type = 'group',
		name = L["Events"],
		desc = L["Change event settings"],
		disabled = function()
			return not self:IsActive()
		end,
		args = {
			Incoming = {
				type = 'group',
				name = L["Incoming"],
				desc = L["Incoming events are events which a mob or another player does to you."],
				args = {},
				order = 1,
			},
			Outgoing = {
				type = 'group',
				name = L["Outgoing"],
				desc = L["Outgoing events are events which you do to a mob or another player."],
				args = {},
				order = 1,
			},
			Notification = {
				type = 'group',
				name = L["Notification"],
				desc = L["Notification events are available to notify you of certain actions."],
				args = {},
				order = 1,
			},
--			spacer = {
--				type = 'header',
--				order = 3,
--			},
			modifier = {
				type = 'group',
				name = L["Event modifiers"],
				desc = L["Options for event modifiers."],
				args = {
					color = {
						order = 1,
						type = 'boolean',
						name = L["Color"],
						desc = L["Whether to color event modifiers or not."],
						get = function()
							return self.db.profile.modifier.color
						end,
						set = function(value)
							self.db.profile.modifier.color = value
						end
					}
				}
			},
			damageTypes = {
				type = 'group',
				name = L["Damage types"],
				desc = L["Options for damage types."],
				args = {
					color = {
						order = 1,
						type = 'boolean',
						name = L["Color"],
						desc = L["Whether to color damage types or not."],
						get = function()
							return self.db.profile.damageTypes.color
						end,
						set = function(value)
							self.db.profile.damageTypes.color = value
						end
					}
				}
			},
			stickyCrit = {
				type = 'boolean',
				name = L["Sticky crits"],
				desc = L["Enable to show crits in the sticky style."],
				get = function()
					return self.db.profile.stickyCrit
				end,
				set = function(value)
					self.db.profile.stickyCrit = value
				end,
			},
			throttle = {
				type = 'group',
				name = L["Throttle events"],
				desc = L["Whether to merge mass events into single instances instead of excessive spam."],
				args = {},
				hidden = function()
					return not next(events_opt.args.throttle.args)
				end,
			},
			filters = {
				type = 'group',
				name = L["Filters"],
				desc = L["Filters to be checked for a minimum amount of damage/healing/etc before showing."],
				args = {},
				hidden = function()
					return not next(events_opt.args.filters.args)
				end,
			},
			abbreviate = {
				type = 'group',
				name = L["Shorten spell names"],
				desc = L["How or whether to shorten spell names."],
				args = {
					style = {
						type = 'choice',
						name = L["Style"],
						desc = L["How or whether to shorten spell names."],
						get = function()
							return self.db.profile.abbreviateStyle
						end,
						set = function(value)
							self.db.profile.abbreviateStyle = value
						end,
						choices = {
							none = L["None"],
							abbreviate = L["Abbreviate"],
							truncate = L["Truncate"],
						},
						choiceDescs = {
							none = L["Do not shorten spell names."],
							abbreviate = L["Gift of the Wild => GotW."],
							truncate = L["Gift of the Wild => Gift of t..."],
						},
					},
					length = {
						type = 'number',
						name = L["Length"],
						desc = L["The length at which to shorten spell names."],
						get = function()
							return self.db.profile.abbreviateLength
						end,
						set = function(value)
							self.db.profile.abbreviateLength = value
						end,
						disabled = function()
							return self.db.profile.abbreviateStyle == "none"
						end,
						min = 1,
						max = 30,
						step = 1,
					},
				}
			},
		}
	}
	Parrot:AddOption('events', events_opt)
	local tmp = newDict(
		'crit', L["Critical hits/heals"],
		'crushing', L["Crushing blows"],
		'glancing', L["Glancing hits"],
		'absorb', L["Partial absorbs"],
		'block', L["Partial blocks"],
		'resist', L["Partial resists"],
		'vulnerable', L["Vulnerability bonuses"],
		'overheal', L["Overheals"]
	)
	local function getEnabled(passValue)
		return self.db.profile.modifier[passValue].enabled
	end
	local function setEnabled(passValue, value)
		self.db.profile.modifier[passValue].enabled = value
	end
	local function tupleToHexColor(r, g, b)
		return ("%02x%02x%02x"):format(r * 255, g * 255, b * 255)
	end
	local function getTag(passValue)
		return self.db.profile.modifier[passValue].tag
	end

	local handler__tagTranslations
	local function handler(literal)
		local inner = literal:sub(2, -2)
		if handler__tagTranslations[inner] then
			return literal
		end
		local inner_lower = inner:lower()
		for k in pairs(handler__tagTranslations) do
			if k:lower() == inner_lower then
				return "[" .. k .. "]"
			end
		end
		return "[" .. inner:gsub("(%b[])", handler) .. "]"
	end
	local function setTag(passValue, value)
		handler__tagTranslations = modifierTranslationHelps[passValue]
		self.db.profile.modifier[passValue].tag = value:gsub("(%b[])", handler)
		handler__tagTranslations = nil
	end
	local function getColor(passValue)
		return hexColorToTuple(self.db.profile.modifier[passValue].color)
	end
	local function setColor(passValue, r, g, b)
		self.db.profile.modifier[passValue].color = tupleToHexColor(r, g, b)
	end
	for k,v in pairs(tmp) do
		local usageT = newList(L["<Text>"])
		local translationHelp = modifierTranslationHelps[k]
		if translationHelp then
			local tmp = newList()
			for k in pairs(translationHelp) do
				tmp[#tmp+1] = k
			end
			table.sort(tmp)
			for _, k in ipairs(tmp) do
				usageT[#usageT+1] = "\n"
				usageT[#usageT+1] = "["
				usageT[#usageT+1] = k
				usageT[#usageT+1] = "] => "
				usageT[#usageT+1] = translationHelp[k]
			end
			tmp = del(tmp)
		end
		local usage = table.concat(usageT)
		usageT = del(usageT)
		events_opt.args.modifier.args[k] = {
			type = 'group',
			name = v,
			desc = v,
			args = {
				enabled = {
					type = 'boolean',
					name = L["Enabled"],
					desc = L["Whether to enable showing this event modifier."],
					get = getEnabled,
					set = setEnabled,
					order = -1,
					passValue = k,
				},
				color = {
					type = 'color',
					name = L["Color"],
					desc = L["What color this event modifier takes on."],
					get = getColor,
					set = setColor,
					passValue = k,
				},
				tag = {
					type = 'string',
					name = L["Text"],
					desc = L["What text this event modifier shows."],
					usage = usage,
					get = getTag,
					set = setTag,
					passValue = k,
				},
			}
		}
	end
	tmp = del(tmp)
	
	local tmp = newDict(
		"Physical", L["Physical"],
		"Holy", L["Holy"],
		"Fire", L["Fire"],
		"Nature", L["Nature"],
		"Frost", L["Frost"],
		"Shadow", L["Shadow"],
		"Arcane", L["Arcane"]
	)
	local function getColor(passValue)
		return hexColorToTuple(self.db.profile.damageTypes[passValue])
	end
	local function setColor(passValue, r, g, b)
		self.db.profile.damageTypes[passValue] = tupleToHexColor(r, g, b)
	end
	for k,v in pairs(tmp) do
		events_opt.args.damageTypes.args[k] = {
			type = 'color',
			name = v,
			desc = L["What color this damage type takes on."],
			get = getColor,
			set = setColor,
			passValue = k,
		}
	end
	tmp = del(tmp)
	local function getTag(category, name)
		return self.db.profile[category][name].tag or combatEvents[category][name].defaultTag
	end
	local function setTag(category, name, value)
		handler__tagTranslations = combatEvents[category][name].tagTranslations
		value = value:gsub("(%b[])", handler)
		handler__tagTranslations = nil
		if combatEvents[category][name].defaultTag == value then
			value = nil
		end
		self.db.profile[category][name].tag = value
	end
	
	local function getColor(category, name)
		return hexColorToTuple(self.db.profile[category][name].color or combatEvents[category][name].color)
	end
	local function setColor(category, name, r, g, b)
		local color = tupleToHexColor(r, g, b)
		local combatEvent = combatEvents[category][name]
		if combatEvent.color == color then
			color = nil
		end
		self.db.profile[category][name].color = color
	end

	local function getSticky(category, name)
		local sticky = self.db.profile[category][name].sticky
		if sticky ~= nil then
			return sticky
		else
			return combatEvents[category][name].sticky
		end
	end
	local function setSticky(category, name, value)
		if (not not combatEvents[category][name].sticky) == value then
			value = nil
		end
		self.db.profile[category][name].sticky = value
	end

	local function getFontFace(category, name)
		local font = self.db.profile[category][name].font
		if font == nil then
			return L["Inherit"]
		else
			return font
		end
	end
	local function setFontFace(category, name, value)
		if value == L["Inherit"] then
			value = nil
		end
		self.db.profile[category][name].font = value
	end
	local function getFontSize(category, name)
		return self.db.profile[category][name].fontSize
	end
	local function setFontSize(category, name, value)
		self.db.profile[category][name].fontSize = value
	end
	local function getFontSizeInherit(category, name)
		return self.db.profile[category][name].fontSize == nil
	end
	local function setFontSizeInherit(category, name, value)
		if value then
			self.db.profile[category][name].fontSize = nil
		else
			self.db.profile[category][name].fontSize = 18
		end
	end
	local function getFontOutline(category, name)
		local outline = self.db.profile[category][name].fontOutline
		if outline == nil then
			return L["Inherit"]
		else
			return outline
		end
	end
	local function setFontOutline(category, name, value)
		if value == L["Inherit"] then
			value = nil
		end
		self.db.profile[category][name].fontOutline = value
	end
	local fontOutlineChoices = {
		NONE = L["None"],
		OUTLINE = L["Thin"],
		THICKOUTLINE = L["Thick"],
		[L["Inherit"]] = L["Inherit"],
	}
	local function getEnable(category, name)
		local disabled = self.db.profile[category][name].disabled
		if disabled == nil then
			disabled = combatEvents[category][name].defaultDisabled
		end
		return not disabled
	end
	local function setEnable(category, name, value)
		local disabled = not value
		if (not not combatEvents[category][name].defaultDisabled) == disabled then
			disabled = nil
		end
		self.db.profile[category][name].disabled = disabled

		refreshEventRegistration(category, name)
	end
	local function getScrollArea(category, name)
		local scrollArea = self.db.profile[category][name].scrollArea
		if scrollArea == nil then
			scrollArea = category
		end
		return scrollArea
	end
	local function setScrollArea(category, name, value)
		if value == category then
			value = nil
		end
		self.db.profile[category][name].scrollArea = value
	end
	local function getSound(category, name)
		return self.db.profile[category][name].sound or "None"
	end
	local function setSound(category, name, value)
		PlaySoundFile(SharedMedia:Fetch('sound', value))
		if value == "None" then
			value = nil
		end
		self.db.profile[category][name].sound = value
	end
	local function resortOptions(category)
		local args = events_opt.args[category].args
		local subcats = newList()
		for k,v in pairs(args) do
			if v.type == "header" then
				subcats[#subcats+1] = k:sub(8)
			end
		end
		table.sort(subcats)
		local num_subcats = #subcats
		local subcatOrders = newList()
		for i,v in ipairs(subcats) do
			subcats[i] = nil
			subcatOrders[v] = i*2-1
		end
		local data = combatEvents[category]
		for k,v in pairs(args) do
			if v.type == "header" then
				v.order = subcatOrders[k:sub(8)]
				v.hidden = num_subcats == 1 or nil
			else
				v.order = subcatOrders[data[k].subCategory]+1
			end
		end
	end
	function createOption(category, name)
		local localName = combatEvents[category][name].localName
		local tagTranslationsHelp = combatEvents[category][name].tagTranslationsHelp
		local usageT = newList(L["<Tag>"])
		if tagTranslationsHelp then
			local tmp = newList()
			for k, v in pairs(tagTranslationsHelp) do
				tmp[#tmp+1] = k
			end
			table.sort(tmp)
			for _, k in ipairs(tmp) do
				usageT[#usageT+1] = "\n"
				usageT[#usageT+1] = "["
				usageT[#usageT+1] = k
				usageT[#usageT+1] = "] => "
				usageT[#usageT+1] = tagTranslationsHelp[k]
			end
		end
		local usage = table.concat(usageT)
		usageT = del(usageT)
		if not events_opt.args[category] then
			events_opt.args[category] = {
				type = 'group',
				name = category,
				desc = category,
				args = {},
				order = 2,
			}
		end
		local subcat = combatEvents[category][name].subCategory
		if not events_opt.args[category].args['subcat_' .. subcat] then
			local name = subcat ~= L["Uncategorized"] and subcat or nil
			events_opt.args[category].args['subcat_' .. subcat] = {
				type = 'header',
				name = name,
				desc = name,
			}
		end
		events_opt.args[category].args[name] = {
			type = 'group',
			name = localName,
			desc = localName,
			args = {
				tag = {
					name = L["Tag"],
					desc = L["Tag to show for the current event."],
					type = 'string',
					usage = usage,
					get = getTag,
					set = setTag,
					passValue = category,
					passValue2 = name,
					order = 1,
				},
				color = {
					name = L["Color"],
					desc = L["Color of the text for the current event."],
					type = 'color',
					get = getColor,
					set = setColor,
					passValue = category,
					passValue2 = name,
				},
				sound = {
					type = 'choice',
					choices = SharedMedia:List("sound"),
					name = L["Sound"],
					desc = L["What sound to play when the current event occurs."],
					get = getSound,
					set = setSound,
					passValue = category,
					passValue2 = name,
				},
				sticky = {
					name = L["Sticky"],
					desc = L["Whether the current event should be classified as \"Sticky\""],
					type = 'boolean',
					get = getSticky,
					set = setSticky,
					passValue = category,
					passValue2 = name,
				},
				font = {
					type = 'group',
					groupType = 'inline',
					name = L["Custom font"],
					desc = L["Custom font"],
					args = {
						fontface = {
							type = 'choice',
							name = L["Font face"],
							desc = L["Font face"],
							choices = Parrot.inheritFontChoices,
							choiceFonts = SharedMedia:HashTable("font"),
							get = getFontFace,
							set = setFontFace,
							passValue = category,
							passValue2 = name,
							order = 1,
						},
						fontSizeInherit = {
							type = 'boolean',
							name = L["Inherit font size"],
							desc = L["Inherit font size"],
							get = getFontSizeInherit,
							set = setFontSizeInherit,
							passValue = category,
							passValue2 = name,
							order = 2,
						},
						fontSize = {
							type = 'number',
							name = L["Font size"],
							desc = L["Font size"],
							min = 12,
							max = 30,
							step = 1,
							get = getFontSize,
							set = setFontSize,
							disabled = getFontSizeInherit,
							passValue = category,
							passValue2 = name,
							order = 3,
						},
						fontOutline = {
							type = 'choice',
							name = L["Font outline"],
							desc = L["Font outline"],
							get = getFontOutline,
							set = setFontOutline,
							choices = fontOutlineChoices,
							passValue = category,
							passValue2 = name,
							order = 4,
						},
					}
				},
				enable = {
					order = -1,
					type = 'boolean',
					name = L["Enabled"],
					desc = L["Enable the current event."],
					get = getEnable,
					set = setEnable,
					passValue = category,
					passValue2 = name,
				},
				scrollArea = {
					type = 'choice',
					name = L["Scroll area"],
					desc = L["Which scroll area to use."],
					choices = Parrot_ScrollAreas:GetScrollAreasChoices(),
					get = getScrollArea,
					set = setScrollArea,
					passValue = category,
					passValue2 = name,
				},
			}
		}
		resortOptions(category)
	end

	local function getTimespan(throttleType)
		return self.db.profile.throttles[throttleType] or throttleDefaultTimes[throttleType]
	end
	local function setTimespan(throttleType, value)
		if value == throttleDefaultTimes[throttleType] then
			value = nil
		end
		self.db.profile.throttles[throttleType] = value
	end
	function createThrottleOption(throttleType)
		local localName = throttleTypes[throttleType]
		events_opt.args.throttle.args[throttleType] = {
			type = 'number',
			name = localName,
			desc = L["What timespan to merge events within.\nNote: a time of 0s means no throttling will occur."],
			min = 0,
			max = 15,
			step = 0.1,
			bigStep = 1,
			get = getTimespan,
			set = setTimespan,
			passValue = throttleType
		}
	end

	local function getAmount(filterType)
		return self.db.profile.filters[filterType] or filterDefaults[filterType]
	end
	local function setAmount(filterType, value)
		if value == filterDefaults[filterType] then
			value = nil
		end
		self.db.profile.filters[filterType] = value
	end
	function createFilterOption(filterType)
		local localName = filterTypes[filterType]
		events_opt.args.filters.args[filterType] = {
			type = 'number',
			name = localName,
			desc = L["What amount to filter out. Any amount below this will be filtered.\nNote: a value of 0 will mean no filtering takes place."],
			min = 0,
			max = 1000,
			step = 1,
			bigStep = 20,
			get = getAmount,
			set = setAmount,
			passValue = filterType
		}
	end
	
	for category, q in pairs(combatEvents) do
		for name, data in pairs(q) do
			createOption(category, name)
		end
	end
	for throttleType in pairs(throttleTypes) do
		createThrottleOption(throttleType)
	end
	for filterType in pairs(filterTypes) do
		createFilterOption(filterType)
	end
end

-- TODO make local again
self.combatLogEvents = {}

--[[----------------------------------------------------------------------------------
Arguments:
	table - a data table holding the details of a combat event.
Notes:
	The data table is of the following style:
	<pre>{
		category = "Name of the category in English",
		name = "Name of the condition in English",
		localName = "Name of the condition in the current locale",
		defaultTag = "The default tagstring in the current locale", -- this can and should include relevant tags.
		parserEvent = { -- optional, will cause it to trigger when the filter passes.
			eventType = "Some eventType",
			-- see Parser-3.0 for more details.
		},
		blizzardEvent = "NAME_OF_EVENT", -- optional, will cause it to trigger when the event fires. Incompatible with parserEvent.
		color = "7f7fff", -- some color in the form of "rrggbb",
		tagTranslations = { -- optional, highly recommended
			Amount = "amount",
			Name = "sourceName", -- equivalent to function(info) return info.sourceName end
			Value = function(info)
				return "|cffff0000" .. info.value .. "|r"
			end,
			-- these are mappings of Tag to info table key (or to a function that will be called).
		},
		tagTranslationsHelp = { -- optional
			Amount = "The description of the [Amount] tag in the current locale.",
			Name = "The description of the [Name] tag in the current locale.",
			Value = "The description of the [Value] tag in the current locale.",
		},
		canCrit = true, -- or false/nil. Will cause the event to go sticky on critical.
		throttle = { -- optional
			"Throttle type in English",
			'infoTableKey', -- the key with which to categorize by.
			'throttleCount', -- the key which will be filled based on how many throttled events are in the single instance.
			sourceName = L["Multiple"] -- any key-value mappings will change the info table if there are multiple throttled events.
		},
		filterType = { -- optional
			"Filter type in English",
			'infoTableKey', -- the numeric key with which to check the filter against.
		},
	}</pre>
Example:
	Parrot:RegisterCombatEvent{
		category = "Outgoing",
		name = "Melee dodges",
		localName = L["Melee dodges"],
		defaultTag = L["Dodge!"],
		parserEvent = {
			eventType = "Miss",
			missType = "Dodge",
			sourceID = "player",
			recipientID_not = "player",
			abilityName = false,
		},
		tagTranslations = {
			Name = "recipientName",
		},
		tagTranslationsHelp = {
			Name = L["The name of the enemy you attacked."],
		},
		color = "ffffff", -- white
	}
------------------------------------------------------------------------------------]]
function Parrot_CombatEvents:RegisterCombatEvent(data)
	self = Parrot_CombatEvents -- so people can do Parrot:RegisterCombatEvent
--	AceLibrary.argCheck(self, data, 2, "table") -- TODO
	local category = data.category
	if type(category) ~= "string" then
		error(("Bad argument #2 to `RegisterCombatEvent'. category must be a %q, got %q."):format("string", type(category)), 2)
	end
	if not data.subCategory then
		-- REMOVE ME LATER
		data.subCategory = L["Uncategorized"]
	end
	local subCategory = data.subCategory
	if type(subCategory) ~= "string" then
		error(("Bad argument #2 to `RegisterCombatEvent'. subCategory must be a %q, got %q."):format("string", type(subCategory)), 2)
	end
	local name = data.name
	if type(name) ~= "string" then
		error(("Bad argument #2 to `RegisterCombatEvent'. name must be a %q, got %q."):format("string", type(name)), 2)
	end
	local localName = data.localName
	if type(localName) ~= "string" then
		error(("Bad argument #2 to `RegisterCombatEvent'. localName must be a %q, got %q."):format("string", type(localName)), 2)
	end
	local defaultTag = data.defaultTag
	if type(defaultTag) ~= "string" then
		error(("Bad argument #2 to `RegisterCombatEvent'. defaultTag must be a %q, got %q."):format("string", type(defaultTag)), 2)
	end
	local parserEvent = data.parserEvent
	if parserEvent and type(parserEvent) ~= "table" then
		error(("Bad argument #2 to `RegisterCombatEvent'. parserEvent must be a %q or nil, got %q."):format("table", type(parserEvent)), 2)
	end
	local blizzardEvent = data.blizzardEvent
	if blizzardEvent and type(blizzardEvent) ~= "string" then
		error(("Bad argument #2 to `RegisterCombatEvent'. blizzardEvent must be a %q or nil, got %q."):format("string", type(blizzardEvent)), 2)
	end
	if parserEvent and blizzardEvent then
		error("Bad argument #2 to `RegisterCombatEvent'. blizzardEvent and parserEvent cannot coexist.", 2)
	end
	local tagTranslations = data.tagTranslations
	if tagTranslations and type(tagTranslations) ~= "table" then
		error(("Bad argument #2 to `RegisterCombatEvent'. tagTranslations must be a %q or nil, got %q."):format("table", type(tagTranslations)), 2)
	end
	local tagTranslationsHelp = data.tagTranslationsHelp
	if tagTranslationsHelp and type(tagTranslationsHelp) ~= "table" then
		error(("Bad argument #2 to `RegisterCombatEvent'. tagTranslationsHelp must be a %q or nil, got %q."):format("table", type(tagTranslationsHelp)), 2)
	end
	local color = data.color
	if type(color) ~= "string" then
		error(("Bad argument #2 to `RegisterCombatEvent'. color must be a %q, got %q."):format("string", type(color)), 2)
	end
	if not combatEvents[category] then
		combatEvents[category] = newList()
	end
	combatEvents[category][name] = data
	refreshEventRegistration(category, name)
	
	local combatLogEvents = data.combatLogEvents
	if combatLogEvents then
		for _, v in ipairs(combatLogEvents) do
		
			local eventType = v.eventType
			if not self.combatLogEvents[eventType] then
				self.combatLogEvents[eventType] = {}
			end
			table.insert(self.combatLogEvents[eventType], { category = data.category, name = data.name, infofunc = v.func })
		end
		
	end
	
	createOption(category, name)
end
Parrot.RegisterCombatEvent = Parrot_CombatEvents.RegisterCombatEvent

--[[----------------------------------------------------------------------------------
Arguments:
	string - the name of the throttle type in English.
	string - the name of the throttle type in the current locale.
	number - the default duration in seconds.
	boolean - whether to wait for the duration before firing (true) or to fire as long as it hasn't fired in the past duration (false).
Notes:
	waitStyle is good to be set to true in events where you expect multiple hits at once and don't want to show the first hit and then the rest of the hits in one conglomerate chunk. waitStyle is good to be set to false in events where you expect a steady stream but not necessarily one that is coming from a single source.
Example:
	Parrot:RegisterThrottleType("DoTs and HoTs", L["DoTs and HoTs"], 2)
------------------------------------------------------------------------------------]]
function Parrot_CombatEvents:RegisterThrottleType(name, localName, duration, waitStyle)
	self = Parrot_CombatEvents -- for people who want to Parrot:RegisterThrottleType
	
	if type(name) ~= "string" then
		error(("Bad argument #2 to `RegisterThrottleType'. Expected %q, got %q."):format("string", type(name)), 2)
	end
	if type(localName) ~= "string" then
		error(("Bad argument #3 to `RegisterThrottleType'. Expected %q, got %q."):format("string", type(localName)), 2)
	end
	if type(duration) ~= "number" then
		error(("Bad argument #4 to `RegisterThrottleType'. Expected %q, got %q."):format("number", type(duration)), 2)
	end
	
	throttleTypes[name] = localName
	throttleDefaultTimes[name] = duration
	throttleWaitStyles[name] = not not waitStyle
	
	createThrottleOption(name)
end
Parrot.RegisterThrottleType = Parrot_CombatEvents.RegisterThrottleType

--[[----------------------------------------------------------------------------------
Arguments:
	string - the name of the throttle type in English.
	string - the name of the throttle type in the current locale.
	number - the default filter amount.
Notes:
	Filters work by suppressing messages that do not live up to a certain minimum amount.
Example:
	Parrot_CombatEvents:RegisterFilterType("Incoming heals", L["Incoming heals"], 0)
	-- allows for a filter on incoming heals, so that if you don't want to see small heals, it's easy to suppress.
------------------------------------------------------------------------------------]]
function Parrot_CombatEvents:RegisterFilterType(name, localName, default)
	self = Parrot_CombatEvents -- for people who want to Parrot:RegisterFilterType
	
	if type(name) ~= "string" then
		error(("Bad argument #2 to `RegisterFilterType'. Expected %q, got %q."):format("string", type(name)), 2)
	end
	if type(localName) ~= "string" then
		error(("Bad argument #3 to `RegisterFilterType'. Expected %q, got %q."):format("string", type(localName)), 2)
	end
	if type(default) ~= "number" then
		error(("Bad argument #4 to `RegisterFilterType'. Expected %q, got %q."):format("number", type(default)), 2)
	end
	
	filterTypes[name] = localName
	filterDefaults[name] = default

	createThrottleOption(name)
end
Parrot.RegisterFilterType = Parrot_CombatEvents.RegisterFilterType

local handler__translation
local handler__info
local function handler(literal)
	local inner = literal:sub(2, -2)
	local value = handler__translation[inner]
	if value then
		if type(value) == "function" then
			return tostring(value(handler__info) or UNKNOWN)
		else
			return tostring(handler__info[value] or UNKNOWN)
		end
	else
		return "[" .. inner:gsub("(%b[])", handler) .. "]"
	end
end

local modifierTranslations = {
	absorb = { Amount = function(info)
		local db = Parrot_CombatEvents.db.profile.modifier
		if db.color then
			return "|cff" .. db.absorb.color .. info.absorbAmount .. "|r"
		else
			return info.absorbAmount
		end
	end },
	block = { Amount = function(info)
		local db = Parrot_CombatEvents.db.profile.modifier
		if db.color then
			return "|cff" .. db.block.color .. info.blockAmount .. "|r"
		else
			return info.blockAmount
		end
	end },
	resist = { Amount = function(info)
		local db = Parrot_CombatEvents.db.profile.modifier
		if db.color then
			return "|cff" .. db.resist.color .. info.resistAmount .. "|r"
		else
			return info.resistAmount
		end
	end },
	vulnerable = { Amount = function(info)
		local db = Parrot_CombatEvents.db.profile.modifier
		if db.color then
			return "|cff" .. db.vulnerable.color .. info.vulnerableAmount .. "|r"
		else
			return info.vulnerableAmount
		end
	end },
	overheal = { Amount = function(info)
		local db = Parrot_CombatEvents.db.profile.modifier
		if db.color then
			return "|cff" .. db.overheal.color .. info.overhealAmount .. "|r"
		else
			return info.overhealAmount
		end
	end },
	glancing = { Text = function(info)
		local db = Parrot_CombatEvents.db.profile.modifier
		if db.color then
			return "|r" .. info[1] .. "|cff" .. db.glancing.color
		else
			return info[1]
		end
	end },
	crushing = { Text = function(info)
		local db = Parrot_CombatEvents.db.profile.modifier
		if db.color then
			return "|r" .. info[1] .. "|cff" .. db.crushing.color
		else
			return info[1]
		end
	end },
	crit = { Text = function(info)
		local db = Parrot_CombatEvents.db.profile.modifier
		if db.color then
			return "|r" .. info[1] .. "|cff" .. db.crit.color
		else
			return info[1]
		end
	end },
}
modifierTranslationHelps = {
	absorb = { Amount = L["The amount of damage absorbed."] },
	block = { Amount = L["The amount of damage blocked."] },
	resist = { Amount = L["The amount of damage resisted."] },
	vulnerable = { Amount = L["The amount of vulnerability bonus."] },
	overheal = { Amount = L["The amount of overhealing."] },
	glancing = { Text = L["The normal text."] },
	crushing = { Text = L["The normal text."] },
	crit = { Text = L["The normal text."] },
}

local throttleData = {}

onEnableFuncs[#onEnableFuncs+1] = function()
	Parrot_CombatEvents:AddRepeatingTimer(0.05, "RunThrottle")
end

local LAST_TIME = _G.newproxy() -- cheaper than {}
local NEXT_TIME = _G.newproxy() -- cheaper than {}

-- #NODOC
function Parrot_CombatEvents:RunThrottle(force)
	local now = GetTime()
	for throttleType,w in pairs(throttleData) do
		local goodTime = now
		local waitStyle = throttleWaitStyles[throttleType]
		if not waitStyle then
			local throttleTime = self.db.profile.throttles[throttleType] or throttleDefaultTimes[throttleType]
			goodTime = now - throttleTime
		end
		for category,v in pairs(w) do
			for name,u in pairs(v) do
				for id,info in pairs(u) do
					if not waitStyle then
						if force or goodTime >= info[LAST_TIME] then
							if next(info) == LAST_TIME and next(info, LAST_TIME) == nil then
								u[id] = del(info)
							else
								self:TriggerCombatEvent(category, name, info, true)
							end
						end
					else
						if force or goodTime >= info[NEXT_TIME] then
							self:TriggerCombatEvent(category, name, info, true)
							u[id] = del(info)
						end
					end
				end
				if not next(u) then
					v[name] = del(u)
				end
			end
			if not next(v) then
				w[category] = del(v)
			end
		end
		if not next(w) then
			throttleData[throttleType] = del(w)
		end
	end
end

local nextFrameCombatEvents = {}
local runCachedEvents
local cancelUIDSoon = {}

--[[----------------------------------------------------------------------------------
Arguments:
	string - the name of the category in English
	string - the name of the event in English
	table - the info table to pass in
	boolean - internal value
Notes:
	info can be any table and is meant to be recycled. The values within it will be exportable through the tagTranslations provided by :RegisterCombatEvent.
Example:
	local tmp = newList()
	tmp.value = 50
	Parrot:TriggerCombatEvent("Notification", "My event", tmp)
	tmp = del(tmp)
------------------------------------------------------------------------------------]]
function Parrot_CombatEvents:TriggerCombatEvent(category, name, info, throttleDone)
	self = Parrot_CombatEvents -- so people can do Parrot:TriggerCombatEvent
	if not Parrot:IsModuleActive(self) then
		return
	end
	if UnitIsDeadOrGhost("player") then
		return
	end
	if cancelUIDSoon[info.uid] then
		return
	elseif not info.uid then
		local uid
		if RockEvent.currentUID then
			uid = -RockEvent.currentUID
		elseif RockTimer.currentUID then
			uid = -RockTimer.currentUID - 1e10
		end
		if cancelUIDSoon[uid] then
			return
		end
	end
	if type(category) ~= "string" then
		error(("Bad argument #2 to `TriggerCombatEvent'. %q expected, got %q."):format("string", type(category)), 2)
		return
	end
	local data = combatEvents[category]
	if not data then
		error(("Bad argument #2 to `TriggerCombatEvent'. %q is an unknown category."):format(category), 2)
		return
	end
	if type(name) ~= "string" then
		error(("Bad argument #3 to `TriggerCombatEvent'. %q expected, got %q."):format("string", type(name)), 2)
		return
	end
	data = data[name]
	if not data then
		error(("Bad argument #3 to `TriggerCombatEvent'. %q is an unknown name for category %q."):format(name, category), 2)
		return
	end

	local db = self.db.profile[category][name]
	local disabled = db.disabled
	if disabled == nil then
		disabled = data.defaultDisabled
	end
	if disabled then
		return
	end

	if type(info) ~= "table" then
		error(("Bad argument #4 to `TriggerCombatEvent'. %q expected, got %q."):format("table", type(info)), 2)
		return
	end

	local filterType = data.filterType
	if filterType then
		local actualType = filterType[1]
		local filterKey = filterType[2]
		local base = self.db.profile.filters[actualType] or filterDefaults[actualType]
		local info_filterKey
		if type(filterKey) == "function" then
			info_filterKey = filterKey(info)
		else
			info_filterKey = info[filterKey]
		end
		if info_filterKey < base then
			return
		end
	end

	if throttleDone then
		if throttleWaitStyles[data.throttle[1]] then
			info[NEXT_TIME] = nil
		else
			info[LAST_TIME] = GetTime()
		end
	elseif data.throttle then
		local throttle = data.throttle
		local throttleType = throttle[1]
		if (self.db.profile.throttles[throttleType] or throttleDefaultTimes[throttleType]) > 0 then
			if not throttleData[throttleType] then
				throttleData[throttleType] = newList()
			end
			if not throttleData[throttleType][category] then
				throttleData[throttleType][category] = newList()
			end
			if not throttleData[throttleType][category][name] then
				throttleData[throttleType][category][name] = newList()
			end
			local throttleKey = throttle[2]
			local info_throttleKey
			if type(throttleKey) == "function" then
				info_throttleKey = throttleKey(info)
			else
				info_throttleKey = info[throttleKey]
			end
			local throttleCountData = throttle[3]
			local throttleCountKey = throttleCountData[1]
			for i = 2, #throttleCountData-1 do
				local v = throttleCountData[i]
				throttleCountKey = throttleCountKey .. "_" .. v .. "_" .. tostring(info[v])
			end
			local t = throttleData[throttleType][category][name][info_throttleKey]
			if next(info) == nil and getmetatable(info) then
				info = getmetatable(info).__raw
			end
			if t then
				for k, v in pairs(info) do
					if k ~= LAST_TIME and k ~= NEXT_TIME then
						if t[k] == nil then
							t[k] = v
						elseif throttle[k] and t[k] ~= v then
							t[k] = throttle[k]
						elseif type(v) == "number" then
							if(k ~= "spellID") then
								t[k] = t[k] + v
							end
						end
					end
				end
				t[throttleCountKey] = (t[throttleCountKey] or 0) + 1
				return
			else
				t = newList()
				if throttleWaitStyles[throttleType] then
					t[NEXT_TIME] = GetTime() + (self.db.profile.throttles[throttleType] or throttleDefaultTimes[throttleType])
				else
					t[LAST_TIME] = 0
				end
				throttleData[throttleType][category][name][info_throttleKey] = t
				for k, v in pairs(info) do
					t[k] = v
				end
				t[throttleCountKey] = 1
				return
			end
		end
	end

	local infoCopy = newList()
	if next(info) == nil and getmetatable(info) then
		info = getmetatable(info).__raw
	end
	for k, v in pairs(info) do
		infoCopy[k] = v
	end
	if not infoCopy.uid then
		local uid
		if RockEvent.currentUID then
			uid = -RockEvent.currentUID
		elseif RockTimer.currentUID then
			uid = -RockTimer.currentUID - 1e10
		end
		infoCopy.uid = uid
	end

	if throttleDone then
		for k in pairs(info) do
			if k ~= LAST_TIME then
				info[k] = nil
			end
		end
	end

	if #nextFrameCombatEvents == 0 then
		Parrot_CombatEvents:AddRepeatingTimer("Parrot_CombatEvents-runCachedEvents", 0, runCachedEvents)
	end

	nextFrameCombatEvents[#nextFrameCombatEvents+1] = newList(category, name, infoCopy)
end
Parrot.TriggerCombatEvent = Parrot_CombatEvents.TriggerCombatEvent

local function runEvent(category, name, info)
	local db = Parrot_CombatEvents.db.profile[category][name]
	local data = combatEvents[category][name]

	local throttle = data.throttle
	local throttleSuffix
	if throttle then
		local throttleType = throttle[1]
		if (Parrot_CombatEvents.db.profile.throttles[throttleType] or throttleDefaultTimes[throttleType]) > 0 then
			local throttleCountData = throttle[3]
			if throttleCountData then
				local func = throttleCountData[#throttleCountData]
				throttleSuffix = func(info)
			end
		end
	end

	local sticky = false
	if data.canCrit then
		sticky = info.isCrit and Parrot_CombatEvents.db.profile.stickyCrit
	end
	if not sticky then
		sticky = db.sticky
		if sticky == nil then
			sticky = data.sticky
		end
	end
	local text = db.tag or data.defaultTag
	handler__translation = data.tagTranslations
	handler__info = info
	local icon
	if handler__translation then
		text = text:gsub("(%b[])", handler)
		icon = handler__translation.Icon
		if icon then
			if type(icon) == "function" then
				icon = icon(info)
			else
				icon = info[icon]
			end
		end
	end

	local t = newList(text)
	local overhealAmount = info.overhealAmount
	local modifierDB = Parrot_CombatEvents.db.profile.modifier
	if overhealAmount and overhealAmount >= 1 then
		if modifierDB.overheal.enabled then
			handler__translation = modifierTranslations.overheal
			t[#t+1] = modifierDB.overheal.tag:gsub("(%b[])", handler)
		end
		text = table.concat(t)
	else
		if modifierDB.absorb.enabled then
			local absorbAmount = info.absorbAmount
			if absorbAmount and absorbAmount >= 1 then
				handler__translation = modifierTranslations.absorb
				t[#t+1] = modifierDB.absorb.tag:gsub("(%b[])", handler)
			end
		end
		if modifierDB.block.enabled then
			local blockAmount = info.blockAmount
			if blockAmount and blockAmount >= 1 then
				handler__translation = modifierTranslations.block
				t[#t+1] = modifierDB.block.tag:gsub("(%b[])", handler)
			end
		end
		if modifierDB.resist.enabled then
			local resistAmount = info.resistAmount
			if resistAmount and resistAmount >= 1 then
				handler__translation = modifierTranslations.resist
				t[#t+1] = modifierDB.resist.tag:gsub("(%b[])", handler)
			end
		end
		if modifierDB.vulnerable.enabled then
			local vulnerableAmount = info.vulnerableAmount
			if vulnerableAmount and vulnerableAmount >= 1 then
				handler__translation = modifierTranslations.vulnerable
				t[#t+1] = modifierDB.vulnerable.tag:gsub("(%b[])", handler)
			end
		end
		text = table.concat(t)
		if info.isGlancing then
			if modifierDB.glancing.enabled then
				handler__translation = modifierTranslations.glancing
				handler__info = newList(text)
				if modifierDB.color then
					text = "|cff" .. modifierDB.glancing.color .. modifierDB.glancing.tag:gsub("(%b[])", handler)
				else
					text = modifierDB.glancing.tag:gsub("(%b[])", handler)
				end
				handler__info = del(handler__info)
			end
		elseif info.isCrushing then
			if modifierDB.crushing.enabled then
				handler__translation = modifierTranslations.crushing
				handler__info = newList(text)
				if modifierDB.color then
					text = "|cff" .. modifierDB.crushing.color .. modifierDB.crushing.tag:gsub("(%b[])", handler)
				else
					text = modifierDB.crushing.tag:gsub("(%b[])", handler)
				end
				handler__info = del(handler__info)
			end
		end
	end
	if info.isCrit then
		if modifierDB.crit.enabled then
			handler__translation = modifierTranslations.crit
			handler__info = newList(text)
			if modifierDB.color then
				text = "|cff" .. modifierDB.crit.color .. modifierDB.crit.tag:gsub("(%b[])", handler)
			else
				text = modifierDB.crit.tag:gsub("(%b[])", handler)
			end
			handler__info = del(handler__info)
		end
	end
	t = del(t)
	handler__translation = nil
	handler__info = nil
	local r, g, b = hexColorToTuple(db.color or data.color)

	if throttleSuffix then
		text = text .. throttleSuffix
	end
	Parrot_Display:ShowMessage(text, db.scrollArea or category, sticky, r, g, b, db.font, db.fontSize, db.fontOutline, icon)
	if db.sound then
		PlaySoundFile(SharedMedia:Fetch('sound', db.sound))
	end
end

function runCachedEvents()
	for i,v in ipairs(nextFrameCombatEvents) do
		nextFrameCombatEvents[i] = nil
		runEvent(unpack(v))
		del(v[3])
		del(v)
	end

	Parrot_CombatEvents:RemoveTimer("Parrot_CombatEvents-runCachedEvents")

	for k in pairs(cancelUIDSoon) do
		cancelUIDSoon[k] = nil
	end
end

function Parrot_CombatEvents:CancelEventsWithUID(uid)
	local i = #nextFrameCombatEvents
	while i >= 1 do
		local v = nextFrameCombatEvents[i]
		if v and uid == v[3].uid then
			table.remove(nextFrameCombatEvents, i)
		end
		i = i - 1
	end
	cancelUIDSoon[uid] = true
end


-- function Parrot_CombatEvents:EnvironmentalDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, enviromentalType, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
-- 	local area, sId, sName, dId, dName = self:GetScrollArea( srcGUID, srcName, dstGUID, dstName )
-- 	if (area ~= nil) then
-- 		local info = newList()
-- 		info.damageType = SchoolParser[school]
-- 		info.recipientID = dId
-- 		info.recipientName = dName
-- 		info.sourceID = sId
-- 		info.sourceName = sName
-- 		info.absorbAmount = absorbed or 0
-- 		info.blockAmount = blocked or 0
-- 		info.resistAmount = resisted or 0
-- 		info.hazardTypeLocal = EnvironmentalParser[enviromentalType]
-- 		info.amount = amount
-- 		info.isCrit = (critical ~= nil)
-- 		info.isCrushing = (crushing ~= nil)
-- 		info.isGlancing = (glancing ~= nil)
-- 		info.uid = srcGUID		
-- 		
-- 		self:TriggerCombatEvent(area, "Environmental damage", info)
-- 
-- 		info = del( info )
-- 	end
-- end
-- 
-- function Parrot_CombatEvents:SpellDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
-- 	
-- 	--scroll-area-stuff
-- 	local area, sId, sName, dId, dName = Parrot_CombatEvents:GetScrollArea( srcGUID, srcName, dstGUID, dstName, srcFlags, dstFlags )
-- 	if (area ~= nil) then
-- 
-- 		local info = newList()
-- 		info.spellID = spellId
-- 		info.damageType = SchoolParser[school] or SchoolParser[spellSchool]
-- 		info.recipientID = dId
-- 		info.recipientName = dName
-- 		info.sourceName = sName
-- 		info.sourceID = sId
-- 		info.abilityName = spellName
-- 		info.absorbAmount = absorbed or 0
-- 		info.blockAmount = blocked or 0
-- 		info.resistAmount = resisted or 0
-- 		info.amount = amount
-- 		info.isCrit = (critical ~= nil)
-- 		info.isCrushing = (crushing ~= nil)
-- 		info.isGlancing = (glancing ~= nil)
-- 		info.uid = srcGUID
-- 		info.isDoT = false	
-- 		
-- 	if bit_band(srcFlags,LIB_FILTER_MY_PET) == LIB_FILTER_MY_PET or bit_band(dstFlags,LIB_FILTER_MY_PET) == LIB_FILTER_MY_PET then
-- 		
-- 		self:TriggerCombatEvent(area, "Pet skill damage", info);
-- 	elseif bit_band(srcFlags,LIB_FILTER_MY_GUARDIAN) == LIB_FILTER_MY_GUARDIAN or bit_band(dstFlags,LIB_FILTER_MY_GUARDIAN) == LIB_FILTER_MY_GUARDIAN then
-- 			self:TriggerCombatEvent(area, "Pet skill damage", info)
-- 	else
-- 		self:TriggerCombatEvent(area, "Skill damage", info);
-- 	end
-- 		
-- 		info = del( info )
-- 	end
-- 	
-- 	--trigger-stuff
-- 	
-- 	local name
-- 		
-- 	if srcGUID == self.PlayerGUID then
-- 		name = "Outgoing"
-- 	elseif dstGUID == self.PlayerGUID then
-- 		name = "Incoming"
-- 	else
-- 		return
-- 	end
-- 		
-- 	-- make sure no number-arg is passed
-- 	if type(spellName) == "string" then
-- 		Parrot_TriggerConditions:FirePrimaryTriggerCondition(name .. " cast", spellName)
-- 	end
-- 		
-- 	if critical then
-- 		Parrot_TriggerConditions:FirePrimaryTriggerCondition(name .. " crit")
-- 	end
-- 	
-- end
-- 
-- function Parrot_CombatEvents:SpellPeriodicDrainLeech( timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, powerType, extraAmount )
-- 	local area, sId, sName, dId, dName = Parrot_CombatEvents:GetScrollArea( srcGUID, srcName, dstGUID, dstName, srcFlags, dstFlags )
-- 	if (area ~= nil) then
-- 		local info = newList()
-- 		info.spellID = spellId
-- 		info.damageType = SchoolParser[spellSchool]
-- 		info.recipientID = dId
-- 		info.recipientName = dName
-- 
-- 	-- Shadowword: Death feedback damage workaround
-- 	if( spellId == 32409 and (srcName == nil) and dstGUID == self.PlayerGUID ) then
-- 		info.sourceName = dstName
-- 	else
-- 			info.sourceName = sName
-- 	end
-- 
-- 		info.sourceID = sId
-- 		info.abilityName = spellName
-- 		info.amount = amount + (extraAmount or 0)
-- 		info.uid = srcGUID
-- 		info.isDoT = false
-- 	
-- 	if bit_band(srcFlags,LIB_FILTER_MY_PET) == LIB_FILTER_MY_PET or bit_band(dstFlags,LIB_FILTER_MY_PET) == LIB_FILTER_MY_PET then
-- 		self:TriggerCombatEvent(area, "Pet skill DoTs", info)
-- 	elseif bit_band(srcFlags,LIB_FILTER_MY_GUARDIAN) == LIB_FILTER_MY_GUARDIAN or bit_band(dstFlags,LIB_FILTER_MY_GUARDIAN) == LIB_FILTER_MY_GUARDIAN then
-- 			self:TriggerCombatEvent(area, "Pet skill DoTs", info)
-- 	else
-- 		self:TriggerCombatEvent(area, "Skill DoTs", info)
-- 	end
-- 
-- 		info = del( info )
-- 	end
-- end
-- 
-- 
-- function Parrot_CombatEvents:SpellLeech( timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, powerType, extraAmount )
-- 	local area, sId, sName, dId, dName = Parrot_CombatEvents:GetScrollArea( srcGUID, srcName, dstGUID, dstName, srcFlags, dstFlags )
-- 	
-- 	if (area ~= nil) then
-- 		local info = newList()
-- 		info.spellID = spellId
-- 		info.damageType = SchoolParser[spellSchool]
-- 		info.recipientID = dId
-- 		info.recipientName = dName
-- 		info.sourceName = sName
-- 		info.sourceID = sId
-- 		info.abilityName = spellName
-- 		info.amount = amount
-- 		info.uid = dstGUID
-- 		info.attributeLocal = PowerTypeParser[powerType]
-- 		info.isDoT = false
-- 	
-- 		
-- 	if(dstGUID == self.PlayerGUID) then
-- 		self:TriggerCombatEvent("Notification", "Power loss", info)
-- 	else
-- 		self:TriggerCombatEvent("Notification", "Power gain", info)
-- 	end
-- 	
-- 	info = del( info )
-- 	end
-- end
-- 
-- function Parrot_CombatEvents:SpellInterrupt( timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, extraSpellId, extraSpellName, extraSpellSchool )
-- 	local area, sId, sName, dId, dName = Parrot_CombatEvents:GetScrollArea( srcGUID, srcName, dstGUID, dstName )
-- 	
-- 	if (area ~= nil) then
-- 		local info = newList()
-- 		info.spellID = spellId
-- 		info.extraSpellID = extraSpellId
-- 		info.damageType = SchoolParser[spellSchool]
-- 		info.recipientID = dId
-- 		info.recipientName = dName
-- 		info.sourceName = sName
-- 		info.sourceID = sId
-- 		info.abilityName = spellName
-- 	info.extraAbilityName = extraSpellName
-- 		info.uid = dstGUI
-- 		info.isDoT = false
-- 		
-- 	if bit_band(srcFlags,LIB_FILTER_MY_PET) == LIB_FILTER_MY_PET or bit_band(dstFlags,LIB_FILTER_MY_PET) == LIB_FILTER_MY_PET then
-- 		-- TODO? Pets interrupts?
-- 		return
-- 	else
-- 		self:TriggerCombatEvent(area, "Spell interrupts", info)
-- 	end
-- 	
-- 	info = del( info )
-- 	end
-- end
-- 
-- function Parrot_CombatEvents:SpellExtraAttack( timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount )
-- 	if (srcGUID == self.PlayerGUID) then
-- 		local info = newList()
-- 		info.spellID = spellId
-- 		info.recipientID = dstGUID
-- 		info.recipientName = dstName
-- 		info.sourceName = srcName
-- 		info.sourceID = srcGUID
-- 		info.abilityName = spellName
-- 		info.damageType = SchoolParser[spellSchool]
-- 		info.amount = amount
-- 		info.uid = srcGUID
-- 
-- 	self:TriggerCombatEvent("Notification", "Extra attacks", info)
-- 		info = del( info )
-- 	end
-- end
-- 
-- function Parrot_CombatEvents:MeleeMissed(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType)
-- 
-- 	-- scroll-area-stuff
-- 	local area, id, name = Parrot_CombatEvents:GetScrollArea( srcGUID, srcName, dstGUID, dstName, srcFlags, dstFlags )
-- 	local miss = nil
-- 	-- old code: if bit_band(srcFlags,LIB_FILTER_MY_PET) == LIB_FILTER_MY_PET then
-- 	if bit_band(srcFlags,LIB_FILTER_MY_PET) == LIB_FILTER_MY_PET or bit_band(dstFlags,LIB_FILTER_MY_PET) == LIB_FILTER_MY_PET then
-- 		miss = PetMeleeMissParser[missType]
-- 	else
-- 		miss = MeleeMissParser[missType];
-- 	end
-- 	
-- 
-- 	if (area ~= nil) and (miss ~= nil) then
-- 
-- 		local info = newList()
-- 		info.recipientID = id
-- 		info.recipientName = name
-- 		info.abilityName = srcName
-- 		info.Name = name
-- 		
-- 		self:TriggerCombatEvent(area, miss, info)
-- 
-- 		info = del( info )
-- 
-- 	end
-- 
-- 	-- Trigger-stuff
-- 	local name
-- 	if srcGUID == self.PlayerGUID then
-- 		name = "Outgoing"
-- 	elseif dstGUID == self.PlayerGUID then
-- 		name = "Incoming"
-- 	else
-- 		return
-- 	end
-- 	
-- 	--TODO performance improvement
-- 	
-- 	name = string.format("%s %s", name, _G[missType] or "")
-- 	Parrot_TriggerConditions:FirePrimaryTriggerCondition(name)
-- 
-- end
-- 
-- function Parrot_CombatEvents:SpellMissed(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags,spellId, spellName, spellSchool, missType)
-- 
-- 	local area, id, name = Parrot_CombatEvents:GetScrollArea( srcGUID, srcName, dstGUID, dstName )
-- 	local miss = nil
-- 	if bit_band(srcFlags,LIB_FILTER_MY_PET) == LIB_FILTER_MY_PET or bit_band(dstFlags,LIB_FILTER_MY_PET) == LIB_FILTER_MY_PET then
-- 	miss = PetSpellMissParser[missType]
-- 	else
-- 	miss = SpellMissParser[missType];
-- 	end
-- 
-- 	if (area ~= nil) and (miss ~= nil) then
-- 
-- 		local info = newList()
-- 		info.spellID = spellId
-- 		info.recipientID = id
-- 		info.recipientName = name
-- 		info.abilityName = spellName
-- 		info.Name = name
-- 
-- 		self:TriggerCombatEvent(area, miss, info)
-- 
-- 		info = del( info )
-- 
-- 	end
-- 
-- end
-- 
-- function Parrot_CombatEvents:SpellEnergize(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, powerType)
-- 
-- 	if (dstGUID == self.PlayerGUID) or (dstGUID == self.PetGUID) then
-- 		local info = newList()
-- 		info.spellID = spellId
-- 		info.damageType = SchoolParser[spellSchool]
-- 		info.recipientID = srcGUID
-- 		info.sourceName = srcName
-- 		info.attributeLocal = spellName
-- 		info.sourceID = srcGUID
-- 		info.abilityName = spellName
-- 		info.attributeLocal = PowerTypeParser[powerType]
-- 		info.amount = amount
-- 		info.isCrit = (critical ~= nil)
-- 		info.isCrushing = (crushing ~= nil)
-- 		info.isGlancing = (glancing ~= nil)
-- 		info.uid = srcGUID
-- 		info.isDoT = false
-- 	
-- 		self:TriggerCombatEvent("Notification", "Power gain", info)
-- 
-- 		info = del( info )
-- 	end
-- end
-- 
-- function Parrot_CombatEvents:SpellHeal(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags,spellId, spellName, spellSchool, amount, critical)
-- 
-- 	local area, sId, sName, dId, dName = Parrot_CombatEvents:GetScrollArea( srcGUID, srcName, dstGUID, dstName )
-- 	if (area ~= nil) then
-- 		local overHeal = 0;
-- 		if (UnitIsPlayer( srcName )) or (UnitPlayerControlled( srcName )) then
-- 			local hp_delta = UnitHealthMax(dstName) - UnitHealth(dstName)
-- 			if (amount > hp_delta) then
-- 				overHeal = amount-hp_delta
-- 			end
-- 		end
-- 
-- 	
-- 		if (srcGUID == self.PlayerGUID) then
-- 			sId = dstGUID
-- 			sName = dstName
-- 		else
-- 			sId = srcGUID
-- 			sName = srcName
-- 		end
-- 		dId = dstGUID
-- 		dName = dstName
-- 
-- 		local info = newList()
-- 		info.damageType = SchoolParser[school]
-- 		info.spellID = spellId
-- 		info.recipientID = dId
-- 		info.recipientName = dName
-- 		info.sourceID = sId
-- 		info.sourceName = sName
-- 		info.amount = amount
-- 		info.realAmount = amount-overHeal
-- 		info.abilityName = spellName
-- 		info.isCrit = (critical ~= nil)
-- 		info.uid = srcGUID
-- 		info.isHoT = false
-- 		info.overhealAmount = overHeal
-- 		
-- 	-- check if the heal involves the pet
-- 	if bit_band(srcFlags,LIB_FILTER_MY_PET) == LIB_FILTER_MY_PET or bit_band(dstFlags,LIB_FILTER_MY_PET) == LIB_FILTER_MY_PET then
-- 		self:TriggerCombatEvent(area, "Pet heals", info)
-- 	else
-- 		-- check if we heal ourself
-- 		if(srcGUID == dstGUID and srcGUID == self.PlayerGUID) then
-- 			self:TriggerCombatEvent("Incoming", "Self heals", info)
-- 			self:TriggerCombatEvent("Outgoing", "Self heals", info)
-- 		else
-- 			self:TriggerCombatEvent(area, "Heals", info)
-- 		end
-- 	end
-- 
-- 		info = del( info )
-- 
-- 	end
-- 
-- end
-- 
-- function Parrot_CombatEvents:SpellHoT(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags,spellId, spellName, spellSchool, amount, critical)
-- 
-- 	local area, sId, sName, dId, dName = Parrot_CombatEvents:GetScrollArea( srcGUID, srcName, dstGUID, dstName )
-- 	if (area ~= nil) then
-- 		local overHeal = 0;
-- 		if (UnitIsPlayer( srcName )) or (UnitPlayerControlled( srcName )) then
-- 			local hp_delta = UnitHealthMax(dstName) - UnitHealth(dstName)
-- 			if (amount > hp_delta) then
-- 				overHeal = amount-hp_delta
-- 			end
-- 		end
-- 
-- 		if (srcGUID == self.PlayerGUID) then
-- 			sId = dstGUID
-- 			sName = dstName
-- 		else
-- 			sId = srcGUID
-- 			sName = srcName
-- 		end
-- 		dId = dstGUID
-- 		dName = dstName
-- 
-- 		local info = newList()
-- 		info.spellID = spellId
-- 		info.damageType = SchoolParser[school]
-- 		info.recipientID = dId
-- 		info.recipientName = dName
-- 		info.sourceID = sId
-- 		info.sourceName = sName
-- 		info.amount = amount
-- 		info.realAmount = amount-overHeal
-- 		info.abilityName = spellName
-- 		info.isCrit = (critical ~= nil)
-- 		info.uid = srcGUID
-- 		info.isHoT = true
-- 		info.overhealAmount = overHeal
-- 
-- 	if bit_band(srcFlags,LIB_FILTER_MY_PET) == LIB_FILTER_MY_PET or bit_band(dstFlags,LIB_FILTER_MY_PET) == LIB_FILTER_MY_PET then
-- 		self:TriggerCombatEvent(area, "Pet heals", info)
-- 	else
-- 		-- check if we heal ourself
-- 		if(srcGUID == dstGUID and srcGUID == self.PlayerGUID) then
-- 			self:TriggerCombatEvent("Incoming", "Self heals over time", info)
-- 			self:TriggerCombatEvent("Outgoing", "Self heals over time", info)
-- 		else
-- 			self:TriggerCombatEvent(area, "Heals over time", info)
-- 		end
-- 	end
-- 	
-- 		info = del( info )
-- 
-- 	end
-- 
-- end
-- 
-- function Parrot_CombatEvents:EventIgnore() end
-- 
-- function Parrot_CombatEvents:PartyKill(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags)
-- 
-- 	if (srcGUID == self.PlayerGUID) or (srcGUID == self.PetGUID)then
-- 		local info = newList()
-- 		info.recipientID = dstGUID
-- 		info.recipientName = dstName
-- 		info.sourceName = srcName
-- 		info.sourceID = srcGUID
-- 		info.uid = srcGUID
-- 
-- 		self:TriggerCombatEvent("Notification", "Player killing blows", info)
-- 		info = del( info )
-- 	end
-- 
-- end
-- 
-- function Parrot_CombatEvents:AuraApplied(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
-- 	
-- 	-- check if the buff is already present to avoid some spam
-- 	if GetPlayerBuffName(spellName) and not amount then
-- 		return
-- 	end
-- 	
-- 	local area = "Notification"
-- 	local info = newList()
-- 	info.spellID = spellId
-- 	if amount then
-- 		info.amount = amount
-- 	end
-- 	info.abilityName = spellName
-- 	info.recipientID = dstGUID
-- 	info.recepientName = dstName
-- 	info.icon = select(3, GetSpellInfo(spellId))
-- 	-- info.auraType = auraType
-- 
-- 	if auraType == "BUFF" then
-- 		
-- 		if dstGUID == self.PlayerGUID then
-- 			if amount then
-- 				self:TriggerCombatEvent(area, "Buff stack gains", info)
-- 			else
-- 				self:TriggerCombatEvent(area, "Buff gains", info)
-- 			end
-- 			Parrot_TriggerConditions:FirePrimaryTriggerCondition("Self buff gain", spellName)
-- 			
-- 		end
-- 		
-- 		if dstGUID == UnitGUID("target") then
-- 			if UnitIsEnemy("target", "player") then
-- 				info.dstName = dstName
-- 				if amount then
-- 					self:TriggerCombatEvent(area, "Target buff stack gains", info)
-- 				else
-- 					self:TriggerCombatEvent(area, "Target buff gains", info)
-- 				end
-- 			end
-- 			
-- 			Parrot_TriggerConditions:FirePrimaryTriggerCondition("Target buff gain", spellName)
-- 		end
-- 		
-- 		if dstGUID == UnitGUID("focus") then
-- 			Parrot_TriggerConditions:FirePrimaryTriggerCondition("Focus buff gain", spellName)
-- 		end
-- 		
-- 	elseif auraType == "DEBUFF" then
-- 		
-- 		if dstGUID == self.PlayerGUID then
-- 			if amount then
-- 				self:TriggerCombatEvent(area, "Debuff stack gains", info)
-- 			else
-- 				self:TriggerCombatEvent(area, "Debuff gains", info)
-- 			end
-- 			
-- 			Parrot_TriggerConditions:FirePrimaryTriggerCondition("Self debuff gain", spellName)
-- 		end
-- 		
-- 		if dstGUID == UnitGUID("target") then
-- 			Parrot_TriggerConditions:FirePrimaryTriggerCondition("Target debuff gain", spellName)
-- 		end
-- 		
-- 		if dstGUID == UnitGUID("focus") then
-- 			Parrot_TriggerConditions:FirePrimaryTriggerCondition("Focus debuff gain", spellName)
-- 		end
-- 		
-- 	end
-- 
-- end
-- 
-- function Parrot_CombatEvents:AuraRemoved(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType)
-- 	
-- 	local area = "Notification"
-- 	
-- 	local info = newList()
-- 	info.spellID = spellId
-- 	if amount then
-- 		info.amount = amount
-- 	end
-- 	info.abilityName = spellName
-- 	info.recipientID = dstGUID
-- 	info.recepientName = dstName
-- 	info.icon = select(3, GetSpellInfo(spellId))
-- 	-- info.auraType = auraType
-- 
-- 	if auraType == "BUFF" then
-- 	
-- 		if dstGUID == self.PlayerGUID then
-- 			self:TriggerCombatEvent(area, "Buff fades", info)
-- 			Parrot_TriggerConditions:FirePrimaryTriggerCondition("Self buff fade", spellName)
-- 		end
-- 		
-- 		if dstGUID == UnitGUID("target") then
-- 			Parrot_TriggerConditions:FirePrimaryTriggerCondition("Target buff fade", spellName)
-- 		end
-- 		
-- 		if dstGUID == UnitGUID("focus") then
-- 			Parrot_TriggerConditions:FirePrimaryTriggerCondition("Focus buff fade", spellName)
-- 		end
-- 		
-- 	elseif auraType == "DEBUFF" then
-- 		
-- 		if dstGUID == self.PlayerGUID then
-- 			self:TriggerCombatEvent(area, "Debuff fades", info)
-- 			Parrot_TriggerConditions:FirePrimaryTriggerCondition("Self debuff fade", spellName)
-- 		end
-- 		
-- 		if dstGUID == UnitGUID("target") then
-- 			Parrot_TriggerConditions:FirePrimaryTriggerCondition("Target debuff fade", spellName)
-- 		end
-- 		
-- 		if dstGUID == UnitGUID("focus") then
-- 			Parrot_TriggerConditions:FirePrimaryTriggerCondition("Focus debuff fade", spellName)
-- 		end
-- 		
-- 	end
-- end
-- 
-- function Parrot_CombatEvents:EnchantApplied(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellName, itemId, itemName)
-- 	-- TODO
-- end
-- 
-- function Parrot_CombatEvents:EnchantRemoved(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellName, itemId, itemName)
-- 	-- TODO
-- end
-- 
-- local EventParse =
-- {
-- 	["ENVIRONMENTAL_DAMAGE"] = Parrot_CombatEvents.EnvironmentalDamage, -- Elsia: Environmental damage
-- 	["SWING_MISSED"] = Parrot_CombatEvents.MeleeMissed, -- Elsia: Misses
-- 	["RANGE_MISSED"] = Parrot_CombatEvents.SpellMissed,
-- 	["SPELL_MISSED"] = Parrot_CombatEvents.SpellMissed,
-- 	["SPELL_PERIODIC_MISSED"] = Parrot_CombatEvents.SpellMissed,
-- 	["DAMAGE_SHIELD_MISSED"] = Parrot_CombatEvents.SpellMissed,
-- 	["SPELL_HEAL"] = Parrot_CombatEvents.SpellHeal, -- Elsia: heals
-- 	["SPELL_ENERGIZE"] = Parrot_CombatEvents.SpellEnergize, -- Elsia: Energize
-- 	["SPELL_EXTRA_ATTACKS"] = Parrot_CombatEvents.SpellExtraAttack, -- Elsia: Extr  a attacks
-- 	["SPELL_DRAIN"] = Parrot_CombatEvents.SpellDamage, -- Elsia: Drains and leeches.
-- 	["SPELL_LEECH"] = Parrot_CombatEvents.SpellLeech,
-- 	["SPELL_PERIODIC_HEAL"] = Parrot_CombatEvents.SpellHoT,
-- 	["SPELL_PERIODIC_ENERGIZE"] = Parrot_CombatEvents.SpellEnergize,
-- 	["SPELL_PERIODIC_DRAIN"] = Parrot_CombatEvents.SpellPeriodicDrainLeech,
-- 	["SPELL_PERIODIC_LEECH"] = Parrot_CombatEvents.SpellLeech,

-- }

function Parrot_CombatEvents:OnEvent( _, _, ...)
	Parrot_CombatEvents:HandleEvent( ... )
end

local GOLD_AMOUNT = _G.GOLD_AMOUNT
local SILVER_AMOUNT = _G.SILVER_AMOUNT
local COPPER_AMOUNT = _G.COPPER_AMOUNT

local GOLD_AMOUNT_inv = GOLD_AMOUNT:gsub("%%d", "%%d+")
local SILVER_AMOUNT_inv = SILVER_AMOUNT:gsub("%%d", "%%d+")
local COPPER_AMOUNT_inv = COPPER_AMOUNT:gsub("%%d", "%%d+")

local function parseGoldLoot(chatmsg)
	local gold, silver, copper
	
	gold = (deformat(chatmsg:match(GOLD_AMOUNT_inv) or "", GOLD_AMOUNT)) or 0
	silver = (deformat(chatmsg:match(SILVER_AMOUNT_inv) or "", SILVER_AMOUNT)) or 0
	copper = (deformat(chatmsg:match(COPPER_AMOUNT_inv) or "", COPPER_AMOUNT)) or 0
	
	return tonumber(gold), tonumber(silver), tonumber(copper)
	
end

local YOU_LOOT_MONEY = _G.YOU_LOOT_MONEY
local LOOT_MONEY_SPLIT = _G.LOOT_MONEY_SPLIT
local LOOT_ITEM_SELF_MULTIPLE = _G.LOOT_ITEM_SELF_MULTIPLE
local LOOT_ITEM_SELF = _G.LOOT_ITEM_SELF
local LOOT_ITEM_CREATED_SELF = _G.LOOT_ITEM_CREATED_SELF

function Parrot_CombatEvents:OnLootEvent(_, eventName, chatmsg)
	
	-- parse the money loot
	if eventName == "CHAT_MSG_MONEY" then
		
		local moneystring = deformat(chatmsg, LOOT_MONEY_SPLIT) or deformat(chatmsg, YOU_LOOT_MONEY)
		
		if moneystring then
			local gold, silver, copper = parseGoldLoot(chatmsg)	
			local info = newList()
			info.amount = 10000*gold + 100 * silver + copper
			self:TriggerCombatEvent("Notification", "Loot money", info)
		end
		
	end
	
	if eventName == "CHAT_MSG_LOOT" then
		
		-- check for multiple-item-loot
		local itemLink, amount = deformat(chatmsg, LOOT_ITEM_SELF_MULTIPLE)
		if not itemLink then
			-- check for single-itemloot
			itemLink = deformat(chatmsg, LOOT_ITEM_SELF)
		end
		
		-- if something has been looted
		if itemLink then
			
			if not amount then
				amount = 1
			end
			
			local info = newList()
			info.itemLink = itemLink
			info.amount = amount
			self:TriggerCombatEvent("Notification", "Loot items", info)
		elseif playerClass == "WARLOCK" then
			-- check for soul shard-create
			itemLink = deformat(chatmsg, LOOT_ITEM_CREATED_SELF)
			itemName = GetItemInfo(6265)
			if itemLink and itemName and itemLink:match(".*" .. itemName .. ".*") then
				local info = newList()
				info.itemName = itemName
				info.itemLink = itemLink
				self:TriggerCombatEvent("Notification", "Soul shard gains", info)
			end
		end
		
	end
	
end

local FACTION_STANDING_INCREASED = _G.FACTION_STANDING_INCREASED
local FACTION_STANDING_DECREASED = _G.FACTION_STANDING_DECREASED

function Parrot_CombatEvents:OnRepgainEvent(_, eventName, chatmsg )

	local faction, amount
	
	-- try increase:
	faction, amount = deformat(chatmsg, FACTION_STANDING_INCREASED)
	
	if faction and amount then
		local info = newList()
		info.amount = amount
		info.faction = faction
		self:TriggerCombatEvent("Notification", "Reputation gains", info)
	end
	
	-- try decrease
	faction, amount = deformat(chatmsg, FACTION_STANDING_DECREASED)
	
	if faction and amount then
		local info = newList()
		info.amount = amount
		info.faction = faction
		self:TriggerCombatEvent("Notification", "Reputation losses", info)
	end
	
end



function Parrot_CombatEvents:OnHonorgainEvent(_, eventName)
	
	local newHonor = GetHonorCurrency()
	if newHonor > currentHonor then
		info = newList()
		info.amount = newHonor - currentHonor
		self:TriggerCombatEvent("Notification", "Honor gains", info)
	end
	
	currentHonor = newHonor
end

function Parrot_CombatEvents:OnXPgainEvent(_, eventName, unitId)
	local info = newList()
	local newXP = UnitXP("player")
	info.amount = newXP - currentXP
	currentXP = newXP
	self:TriggerCombatEvent("Notification", "Experience gains", info)
end

local SKILL_RANK_UP = _G.SKILL_RANK_UP

function Parrot_CombatEvents:OnSkillgainEvent(_, eventName, chatmsg)
	local skill, amount = deformat(chatmsg, SKILL_RANK_UP)
	if skill and amount then
		local info = newList()
		info.abilityName = skill
		info.amount = amount
		self:TriggerCombatEvent("Notification", "Skill gains", info)
	end
end

function Parrot_CombatEvents:HandleEvent(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if not Parrot:IsModuleActive(Parrot_CombatEvents) then
		return
	end
	local registeredHandlers = self.combatLogEvents[eventtype]
	if registeredHandlers then
		for _, v in ipairs(registeredHandlers) do
			local info = v.infofunc(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
			if info then
				self:TriggerCombatEvent(v.category, v.name, info)
				info = del( info )
			end
			
		end
	end
	
end
