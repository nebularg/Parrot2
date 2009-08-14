local Parrot = Parrot, Parrot
local Parrot_CombatEvents = Parrot:NewModule("CombatEvents", "LibRockEvent-1.0", "LibRockTimer-1.0")
local self = Parrot_CombatEvents


-- to track XP and Honor-gains
local currentXP
local currentHonor

-- #AUTODOC_NAMESPACE Parrot_CombatEvents

local L = LibStub("AceLocale-3.0"):GetLocale("Parrot_CombatEvents")

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

local debug = Parrot.debug

local bit_bor	= bit.bor
local bit_band  = bit.band

Parrot_CombatEvents.PlayerGUID = nil
Parrot_CombatEvents.PlayerName = nil
Parrot_CombatEvents.PetGUID = nil
Parrot_CombatEvents.PetName = nil

local dbDefaults = {
	profile = {
		['*'] = {
			['*'] = {}
		},
		filters = {},
		sfilters = {
			[GetSpellInfo(34460)] = { inc = true, }, -- Ferocious Inspiration
			[GetSpellInfo(30809)] = { inc = true, }, -- Unleashed Rage
			[GetSpellInfo(53136)] = { inc = true, }, -- Abominable Might
		},
		throttles = {},
		sthrottles = {},
		abbreviateStyle = "abbreviate",
		abbreviateLength = 30,
		stickyCrit = true,
		disable_in_10man = false,
		disable_in_25man = false,
		damageTypes = {
			color = true,
			["Physical"] = "ffffff",
			["Holy"] = "ffff7f",
			["Fire"] = "ff7f7f",
			["Nature"] = "7fff7f",
			["Frost"] = "7f7fff",
			["Shadow"] = "7f007f",
			["Arcane"] = "ff7fff",
			["Frostfire"] = "ff0088",
			["Froststorm"] = "7f7f7f",
			["Shadowstorm"] = "1f1f1f",
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
			overkill = {
				enabled = true,
				color = "00af7f",
				tag = L[" ([Amount] overkill)"],
			},
		},
	},
}

local combatEvents = {}

local Parrot_Display
local Parrot_ScrollAreas
local Parrot_TriggerConditions

function Parrot_CombatEvents:OnInitialize()

	Parrot_CombatEvents.db1 = Parrot.db1:RegisterNamespace("CombatEvents", dbDefaults)

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

local enabled = false
local disabled_by_raid = false
function Parrot_CombatEvents:check_raid_instance()

	if (not enabled) and (not disabled_by_raid) then
		return
	end

	local is_she, instance_type = IsInInstance()
	if is_she then
		if instance_type == "raid" then
			if GetInstanceDifficulty() == 2 then
				-- Heroic = 25man
				self:ToggleActive(not self.db1.profile.disable_in_25man)
			else
				-- Normal = 10man (or maybe some old raid-instance)
				self:ToggleActive(not self.db1.profile.disable_in_10man)
			end
		end
		if not self:IsActive() then
			disabled_by_raid = true
		end
	else
		self:ToggleActive(true)
		disabled_by_raid = false
	end

	self:AddEventListener("Blizzard", "PLAYER_ENTERING_WORLD", "check_raid_instance")
	self:AddEventListener("Blizzard", "PLAYER_LEAVING_WORLD", "check_raid_instance")
	self:AddEventListener("Blizzard", "ZONE_CHANGED_NEW_AREA", "check_raid_instance")


end

local onEnableFuncs = {}

function Parrot_CombatEvents:OnEnable(first)
	enabled = true


	self:AddEventListener("Blizzard", "PLAYER_ENTERING_WORLD", "check_raid_instance")
	self:AddEventListener("Blizzard", "PLAYER_LEAVING_WORLD", "check_raid_instance")
	self:AddEventListener("Blizzard", "ZONE_CHANGED_NEW_AREA", "check_raid_instance")

	if first then
		local tmp = newList("Notification", "Incoming", "Outgoing")
		for _,category in ipairs(tmp) do
			local t = newList()
			for name, data in pairs(self.db1.profile[category]) do
				t[name] = data
				self.db1.profile[category][name] = nil
			end
			for name, data in pairs(t) do
				if combatEvents[name] then
					self.db1.profile[category][name] = data
					t[name] = nil
				else
					local name_lower = name:lower()
					for k,v in pairs(combatEvents[category]) do
						if k:lower() == name_lower then
							self.db1.profile[category][k] = data
							t[name] = nil
							break
						end
					end
					if not t[name] then
						self.db1.profile[category][name] = data
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

local function addEventListeners()
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

table.insert(onEnableFuncs, addEventListeners)

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

	if type(name) ~= 'string' then
		--@debug@
		Parrot:Print("name was a " .. type(name))
		--@end-debug@
		return nil
	end

	local style = self.db1.profile.abbreviateStyle
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
	local neededLen = self.db1.profile.abbreviateLength
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
	local db = Parrot_CombatEvents.db1.profile[category][name]
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


local function getSoundChoices()
	local t = {}
	for _,v in ipairs(SharedMedia:List("sound")) do
		t[v] = v
	end
	return t
end


function Parrot_CombatEvents:OnOptionsCreate()
	local events_opt
	events_opt = {
		type = 'group',
		name = L["Events"],
		desc = L["Change event settings"],
		order = 2,
--		disabled = function()
--			return not self:IsActive()
--		end,
		args = {
			--[[enable_combat_events = {
				type = 'toggle',
				name = L["Enabled"],
				desc = L["Whether this module is enabled"],
				get = function() return self:GetModule("CombatEvents"):IsActive() end,
				set = function(value) self:GetModule("CombatEvents"):ToggleActive(value) self.db1.profile.disabled = value end,
			},]]--

			disable_in_10man = {
				type = 'toggle',
				name = L["Disable in normal raids"],
				desc = L["Disable CombatEvents when in a 10-man raid instance"],
				get = function() return self.db1.profile.disable_in_10man end,
				set = function(info, value)
						self.db1.profile.disable_in_10man = value
						self:check_raid_instance();
					end,
			},
			disable_in_25man = {
				type = 'toggle',
				name = L["Disable in heroic raids"],
				desc = L["Disable CombatEvents when in a 25-man raid instance"],
				get = function() return self.db1.profile.disable_in_25man end,
				set = function(info, value)
						self.db1.profile.disable_in_25man = value
						self:check_raid_instance()
					end,
			},

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
						type = 'toggle',
						name = L["Color"],
						desc = L["Whether to color event modifiers or not."],
						get = function()
							return self.db1.profile.modifier.color
						end,
						set = function(info, value)
							self.db1.profile.modifier.color = value
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
						type = 'toggle',
						name = L["Color"],
						desc = L["Whether to color damage types or not."],
						get = function()
							return self.db1.profile.damageTypes.color
						end,
						set = function(info, value)
							self.db1.profile.damageTypes.color = value
						end
					}
				}
			},
			stickyCrit = {
				type = 'toggle',
				name = L["Sticky crits"],
				desc = L["Enable to show crits in the sticky style."],
				get = function()
					return self.db1.profile.stickyCrit
				end,
				set = function(info, value)
					self.db1.profile.stickyCrit = value
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
			sfilters = {
				type = 'group',
				name = L["Spell filters"],
				desc = L["Filters that are applied to a single spell"],
				args = {},
			},
			sthrottles = {
				type = 'group',
				name = L["Spell throttles"],
				desc = L["Throttles that are applied to a single spell"],
				args = {},
			},
			abbreviate = {
				type = 'group',
				name = L["Shorten spell names"],
				desc = L["How or whether to shorten spell names."],
				args = {
					style = {
						type = 'select',
						name = L["Style"],
						desc = L["How or whether to shorten spell names."],
						get = function()
							return self.db1.profile.abbreviateStyle
						end,
						set = function(info, value)
							self.db1.profile.abbreviateStyle = value
						end,
						values = {
							none = L["None"],
							abbreviate = L["Abbreviate"],
							truncate = L["Truncate"],
						},
--[[						choiceDescs = {
							none = L["Do not shorten spell names."],
							abbreviate = L["Gift of the Wild => GotW."],
							truncate = L["Gift of the Wild => Gift of t..."],
						},--]]
					},
					length = {
						type = 'range',
						name = L["Length"],
						desc = L["The length at which to shorten spell names."],
						get = function()
							return self.db1.profile.abbreviateLength
						end,
						set = function(info, value)
							self.db1.profile.abbreviateLength = value
						end,
						disabled = function()
							return self.db1.profile.abbreviateStyle == "none"
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
		'overheal', L["Overheals"],
		'overkill', L["Overkills"]
	)
	local function getEnabled(info)
		return self.db1.profile.modifier[info.arg].enabled
	end
	local function setEnabled(info, value)
		self.db1.profile.modifier[info.arg].enabled = value
	end
	local function tupleToHexColor(r, g, b)
		return ("%02x%02x%02x"):format(r * 255, g * 255, b * 255)
	end
	local function getTag(info)
		return self.db1.profile.modifier[info.arg].tag
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
	local function setTag(info, value)
		handler__tagTranslations = modifierTranslationHelps[info.arg]
		self.db1.profile.modifier[info.arg].tag = value:gsub("(%b[])", handler)
		handler__tagTranslations = nil
	end
	local function getColor(info)
		return hexColorToTuple(self.db1.profile.modifier[info.arg].color)
	end
	local function setColor(info, r, g, b)
		self.db1.profile.modifier[info.arg].color = tupleToHexColor(r, g, b)
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
					type = 'toggle',
					name = L["Enabled"],
					desc = L["Whether to enable showing this event modifier."],
					get = getEnabled,
					set = setEnabled,
					order = -1,
					arg = k,
				},
				color = {
					type = 'color',
					name = L["Color"],
					desc = L["What color this event modifier takes on."],
					get = getColor,
					set = setColor,
					arg = k,
				},
				tag = {
					type = 'input',
					name = L["Text"],
					desc = L["What text this event modifier shows."],
					usage = usage,
					get = getTag,
					set = setTag,
					arg = k,
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
		"Arcane", L["Arcane"],
		"Frostfire", L["Frostfire"],
		"Froststorm", L["Froststorm"],
		"Shadowstorm", L["Shadowstorm"]
	)
	local function getColor(info)
		return hexColorToTuple(self.db1.profile.damageTypes[info.arg])
	end
	local function setColor(info, r, g, b)
		self.db1.profile.damageTypes[info.arg] = tupleToHexColor(r, g, b)
	end
	for k,v in pairs(tmp) do
		events_opt.args.damageTypes.args[k] = {
			type = 'color',
			name = v,
			desc = L["What color this damage type takes on."],
			get = getColor,
			set = setColor,
			arg = k,
		}
	end
	tmp = del(tmp)
	local function getTag(info)
		local category, name = info.arg[1], info.arg[2]
		return self.db1.profile[category][name].tag or combatEvents[category][name].defaultTag
	end
	local function setTag(info, value)
		local category, name = info.arg[1], info.arg[2]
		handler__tagTranslations = combatEvents[category][name].tagTranslations
		value = value:gsub("(%b[])", handler)
		handler__tagTranslations = nil
		if combatEvents[category][name].defaultTag == value then
			value = nil
		end
		self.db1.profile[category][name].tag = value
	end

	local function getColor(info)
		local category, name = info.arg[1], info.arg[2]
		return hexColorToTuple(self.db1.profile[category][name].color or combatEvents[category][name].color)
	end
	local function setColor(info, r, g, b)
		local category, name = info.arg[1], info.arg[2]
		local color = tupleToHexColor(r, g, b)
		local combatEvent = combatEvents[category][name]
		if combatEvent.color == color then
			color = nil
		end
		self.db1.profile[category][name].color = color
	end

	local function getSticky(info)
		local category, name = info.arg[1], info.arg[2]
		local sticky = self.db1.profile[category][name].sticky
		if sticky ~= nil then
			return sticky
		else
			return combatEvents[category][name].sticky
		end
	end
	local function setSticky(info, value)
		local category, name = info.arg[1], info.arg[2]
		if (not not combatEvents[category][name].sticky) == value then
			value = nil
		end
		self.db1.profile[category][name].sticky = value
	end

	local function getFontFace(info)
		local category, name = info.arg[1], info.arg[2]
		local font = self.db1.profile[category][name].font
		if font == nil then
			return "1"
		else
			return font
		end
	end
	local function setFontFace(info, value)
		local category, name = info.arg[1], info.arg[2]
		if value == "1" then
			value = nil
		end
		self.db1.profile[category][name].font = value
	end
	local function getFontSize(info)
		local category, name = info.arg[1], info.arg[2]
		return self.db1.profile[category][name].fontSize
	end
	local function setFontSize(info, value)
		local category, name = info.arg[1], info.arg[2]
		self.db1.profile[category][name].fontSize = value
	end
	local function getFontSizeInherit(info)
		local category, name = info.arg[1], info.arg[2]
		return self.db1.profile[category][name].fontSize == nil
	end
	local function setFontSizeInherit(info, value)
		local category, name = info.arg[1], info.arg[2]
		if value then
			self.db1.profile[category][name].fontSize = nil
		else
			self.db1.profile[category][name].fontSize = 18
		end
	end
	local function getFontOutline(info)
		local category, name = info.arg[1], info.arg[2]
		local outline = self.db1.profile[category][name].fontOutline
		if outline == nil then
			return L["Inherit"]
		else
			return outline
		end
	end
	local function setFontOutline(info, value)
		local category, name = info.arg[1], info.arg[2]
		if value == L["Inherit"] then
			value = nil
		end
		self.db1.profile[category][name].fontOutline = value
	end
	local fontOutlineChoices = {
		NONE = L["None"],
		OUTLINE = L["Thin"],
		THICKOUTLINE = L["Thick"],
		[L["Inherit"]] = L["Inherit"],
	}
	local function getEnable(info)
		local category, name = info.arg[1], info.arg[2]
		local disabled = self.db1.profile[category][name].disabled
		if disabled == nil then
			disabled = combatEvents[category][name].defaultDisabled
		end
		return not disabled
	end
	local function setEnable(info, value)
		local category, name = info.arg[1], info.arg[2]
		local disabled = not value
		if (not not combatEvents[category][name].defaultDisabled) == disabled then
			disabled = nil
		end
		self.db1.profile[category][name].disabled = disabled

		refreshEventRegistration(category, name)
	end
	local function getScrollArea(info)
		local category, name = info.arg[1], info.arg[2]
		local scrollArea = self.db1.profile[category][name].scrollArea
		if scrollArea == nil then
			scrollArea = category
		end
		return scrollArea
	end
	local function setScrollArea(info, value)
		local category, name = info.arg[1], info.arg[2]
		if value == category then
			value = nil
		end
		self.db1.profile[category][name].scrollArea = value
	end
	local function getSound(info)
		local category, name = info.arg[1], info.arg[2]
		return self.db1.profile[category][name].sound or "None"
	end
	local function setSound(info, value)
		local category, name = info.arg[1], info.arg[2]
		PlaySoundFile(SharedMedia:Fetch('sound', value))
		if value == "None" then
			value = nil
		end
		self.db1.profile[category][name].sound = value
	end

	local function getCommonEnabled(info)
		local category, subcat = info.arg[1], info.arg[2]

		local one_enabled, one_disabled = false, false
		for k,v in pairs(combatEvents[category]) do
			if v.subCategory == subcat then
				if getEnable( { arg = {category, v.name} } ) then
					one_enabled = true
				else
					one_disabled = true
				end
			end
		end

		if one_disabled and one_enabled then
			return nil
		elseif one_disabled then
			return false
		else
			return true
		end
	end

	local function setCommonEnabled(info, value)
		local category, subcat = info.arg[1], info.arg[2]
		for k,v in pairs(combatEvents[category]) do
			if v.subCategory == subcat then
				self.db1.profile[category][v.name].disabled = not value
			end
		end

	end

	local function getCommonScrollArea(info)
		local category, subcat = info.arg[1], info.arg[2]
		local common_choice
		for k,v in pairs(combatEvents[category]) do
			if v.subCategory == subcat then
				local choice = getScrollArea( { arg = {category, v.name} } )
				if common_choice then
					if choice ~= common_choice then
						common_choice = nil
						break
					end
				else
					common_choice = choice
				end
			end
		end
		return common_choice
	end

	local function setCommonScrollArea(info, value)
		local category, subcat = info.arg[1], info.arg[2]

		for k,v in pairs(combatEvents[category]) do
			if v.subCategory == subcat then
				setScrollArea( { arg = {category, v.name} }, value )
			end
		end


	end

	local function resortOptions(category)
--		local args = events_opt.args[category].args
--		local subcats = newList()
--		for k,v in pairs(args) do
--			if v.type == "header" then
--				subcats[#subcats+1] = k:sub(8)
--			end
--		end
--		table.sort(subcats)
--		local num_subcats = #subcats
--		local subcatOrders = newList()
--		for i,v in ipairs(subcats) do
--			subcats[i] = nil
--			subcatOrders[v] = i*2-1
--		end
--		local data = combatEvents[category]
--		for k,v in pairs(args) do
--			if v.type == "header" then
--				v.order = subcatOrders[k:sub(8)]
--				v.hidden = num_subcats == 1 or nil
--			else
--				v.order = subcatOrders[data[k].subCategory]+1
--			end
--		end
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

--[[		if not events_opt.args[category].args['subcat_' .. subcat] then
			local name = subcat ~= L["Uncategorized"] and subcat or nil
			events_opt.args[category].args['subcat_' .. subcat] = {
				type = 'header',
				name = name or L["Uncategorized"],
				desc = name or L["Uncategorized"],
			}
		end--]]

		-- copy the choices
		local scrollarea_choices = {}
		for k,v in pairs(Parrot_ScrollAreas:GetScrollAreasChoices()) do
			scrollarea_choices[k] = v
		end
		-- scrollarea_choices[" "] = " "

		-- added so that options get sorted into subcategories

		if not events_opt.args[category].args[subcat] then
			events_opt.args[category].args[subcat] = {
				type = 'group',
				name = subcat,
				desc = subcat,
				args = {
					enabled = {
						name = L["Enabled"],
						desc = L["Whether all events in this category are enabled."],
						type = 'toggle',
						tristate = true,
						get = getCommonEnabled,
						set = setCommonEnabled,
						arg = {category, subcat},
					},
					scrollarea = {
						name = L["Scroll area"],
						desc = L["Scoll area where all events will be shown"],
						type = 'select',
						values = function() return Parrot_ScrollAreas:GetScrollAreasChoices() end,
						get = getCommonScrollArea,
						set = setCommonScrollArea,
						arg = {category, subcat},
					},
				},
				order = 1,
			}
		end

		events_opt.args[category].args[subcat].args[name] = {
			type = 'group',
			name = localName,
			desc = localName,
			args = {
				tag = {
					name = L["Tag"],
					desc = L["Tag to show for the current event."],
					type = 'input',
					usage = usage,
					get = getTag,
					set = setTag,
					arg = {category, name},
					order = 1,
				},
				color = {
					name = L["Color"],
					desc = L["Color of the text for the current event."],
					type = 'color',
					get = getColor,
					set = setColor,
					arg = {category, name},
				},
				sound = {
					type = 'select',
					values = getSoundChoices,
					name = L["Sound"],
					desc = L["What sound to play when the current event occurs."],
					get = getSound,
					set = setSound,
					arg = {category, name},
				},
				sticky = {
					name = L["Sticky"],
					desc = L["Whether the current event should be classified as \"Sticky\""],
					type = 'toggle',
					get = getSticky,
					set = setSticky,
					arg = {category, name},
				},
				font = {
					type = 'group',
					inline = true,
					name = L["Custom font"],
					desc = L["Custom font"],
					args = {
						fontface = {
							type = 'select',
							name = L["Font face"],
							desc = L["Font face"],
							values = Parrot.inheritFontChoices,
--							choiceFonts = SharedMedia:HashTable("font"),
							get = getFontFace,
							set = setFontFace,
							arg = {category, name},
							order = 1,
						},
						fontSizeInherit = {
							type = 'toggle',
							name = L["Inherit font size"],
							desc = L["Inherit font size"],
							get = getFontSizeInherit,
							set = setFontSizeInherit,
							arg = {category, name},
							order = 2,
						},
						fontSize = {
							type = 'range',
							name = L["Font size"],
							desc = L["Font size"],
							min = 12,
							max = 30,
							step = 1,
							get = getFontSize,
							set = setFontSize,
							disabled = getFontSizeInherit,
							arg = {category, name},
							order = 3,
						},
						fontOutline = {
							type = 'select',
							name = L["Font outline"],
							desc = L["Font outline"],
							get = getFontOutline,
							set = setFontOutline,
							values = fontOutlineChoices,
							arg = {category, name},
							order = 4,
						},
					}
				},
				enable = {
					order = -1,
					type = 'toggle',
					name = L["Enabled"],
					desc = L["Enable the current event."],
					get = getEnable,
					set = setEnable,
					arg = {category, name},
				},
				scrollArea = {
					type = 'select',
					name = L["Scroll area"],
					desc = L["Which scroll area to use."],
					values = Parrot_ScrollAreas:GetScrollAreasChoices(),
					get = getScrollArea,
					set = setScrollArea,
					arg = {category, name},
				},
			}
		}
		resortOptions(category)
	end

	local function getTimespan(info)
		local throttleType = info.arg
		return self.db1.profile.throttles[throttleType] or throttleDefaultTimes[throttleType]
	end
	local function setTimespan(info, value)
		local throttleType = info.arg
		if value == throttleDefaultTimes[throttleType] then
			value = nil
		end
		self.db1.profile.throttles[throttleType] = value
	end
	function createThrottleOption(throttleType)
		local localName = throttleTypes[throttleType]
		events_opt.args.throttle.args[throttleType] = {
			type = 'range',
			name = localName,
			desc = L["What timespan to merge events within.\nNote: a time of 0s means no throttling will occur."],
			min = 0,
			max = 15,
			step = 0.1,
			bigStep = 1,
			get = getTimespan,
			set = setTimespan,
			arg = throttleType
		}
	end

	local function getAmount(info)
		local filterType = info.arg
		return self.db1.profile.filters[filterType] or filterDefaults[filterType]
	end
	local function setAmount(info, value)
		local filterType = info.arg
		if value == filterDefaults[filterType] then
			value = nil
		end
		self.db1.profile.filters[filterType] = value
	end
	function createFilterOption(filterType)
		local localName = filterTypes[filterType]
		events_opt.args.filters.args[filterType] = {
			type = 'range',
			name = localName,
			desc = L["What amount to filter out. Any amount below this will be filtered.\nNote: a value of 0 will mean no filtering takes place."],
			min = 0,
			max = 1000,
			step = 1,
			bigStep = 20,
			get = getAmount,
			set = setAmount,
			arg = filterType
		}
	end

	local sfilters_opt = events_opt.args.sfilters

	local function setSpellName(info, new)
		if self.db1.profile.sfilters[new] ~= nil then
			return
		end

		local old = info.arg
		self.db1.profile.sfilters[new] = self.db1.profile.sfilters[old]
		self.db1.profile.sfilters[old] = nil

		local opt = sfilters_opt.args[info[#info-1]]
		local name = new == '' and L["New filter"] or new

		opt.order = new == '' and -110 or -100
		opt.name = name
		opt.desc = name
		for k,v in pairs(opt.args) do
			v.arg = new
		end
--		opt.args.spell.arg = new
--		opt.args.amount.arg = new
--		opt.args.delete.arg = new
	end

	local function removeFilter(info)
		self.db1.profile.sfilters[info.arg] = nil
		sfilters_opt.args[info[#info-1]] = nil
	end

	local function setFilterAmount(info, value)
		self.db1.profile.sfilters[info.arg].amount = tonumber(value)
	end

	local function makeFilter(k)
		local name = k == '' and L["New filter"] or k
		return {
			type = 'group',
			name = name,
			desc = name,
			args = {
				spell = {
					type = 'input',
					name = L["Spell"],
					desc = L["Name or ID of the spell"],
					get = function(info) return info.arg end,
					set = setSpellName,
					arg = k,
					order = 1,
				},
				amount = {
					type = 'input',
					name = L["Amount"],
					desc = L["Filter when amount is lower than this value (leave blank to filter everything)"],
					get = function(info) return tostring(self.db1.profile.sfilters[info.arg].amount or "") end,
					set = setFilterAmount,
					arg = k,
					order = 2,
				},
				inc = {
					type = 'toggle',
					name = L["Incoming"],
					desc = L["Filter incoming spells"],
					get = function(info) return not not self.db1.profile.sfilters[info.arg].inc end,
					set = function(info, value) self.db1.profile.sfilters[info.arg].inc = value end,
					arg = k,
					order = 3,
				},
				out = {
					type = 'toggle',
					name = L["Outgoing"],
					desc = L["Filter outgoing spells"],
					get = function(info) return not not self.db1.profile.sfilters[info.arg].out end,
					set = function(info, value) self.db1.profile.sfilters[info.arg].out = value end,
					arg = k,
					order = 4,
				},
				delete = {
					type = 'execute',
					name = L["Remove"],
					desc = L["Remove filter"],
					func = removeFilter,
					arg = k,
					order = -1,
				},
			}
		}
	end

	events_opt.args.sfilters.args.new = {
		order = 1,
		type = 'execute',
		name = L["New filter"],
		desc = L["Add a new filter."],
		func = function()
			self.db1.profile.sfilters[''] = {}
			local t = makeFilter('')
			sfilters_opt.args[tostring(t)] = t
		end,
	}

	-- per-spell-throttle-options
	local sthrottles_opt = events_opt.args.sthrottles

	local function setThrottleSpellName(info, new)
		if self.db1.profile.sfilters[new] ~= nil then
			return
		end
		local old = info.arg
		self.db1.profile.sthrottles[new] = self.db1.profile.sthrottles[old]
		self.db1.profile.sthrottles[old] = nil
		local opt = sthrottles_opt.args[info[#info-1]]
		local name = new == '' and L["New throttle"] or new

		opt.order = new == '' and -110 or -100
		opt.name = name
		opt.desc = name
		for k,v in pairs(opt.args) do
			v.arg = new
		end
--		opt.args.spell.arg = new
--		opt.args.amount.arg = new
--		opt.args.delete.arg = new
	end

	local function removeThrottle(info)
		self.db1.profile.sthrottles[info.arg] = nil
		sthrottles_opt.args[info[#info-1]] = nil
	end

	local function setThrottleTime(info, value)
		if (value == 0) then
			value = nil
		end
		self.db1.profile.sthrottles[info.arg].time = value
	end

	local function makeSpellThrottle(k)
		local name = k == '' and L["New throttle"] or k
		return {
			type = 'group',
			name = name,
			desc = name,
			args = {
				spell = {
					type = 'input',
					name = L["Spell"],
					desc = L["Name or ID of the spell"],
					get = function(info) return info.arg end,
					set = setThrottleSpellName,
					arg = k,
					order = 1,
				},
				time = {
					type = 'range',
					name = L["Throttle time"],
					desc = L["Interval for collecting data"],
					get = function(info) return (self.db1.profile.sthrottles[info.arg].time or 0) end,
					set = setThrottleTime,
					min = 0,
					max = 15,
					step = 0.1,
					bigStep = 1,
					arg = k,
					order = 2,
				},
				-- TODO what to do when table-entry is active
				-- disable for now
--[[				waitStyle = {
					type = 'toggle',
					name = "TODO waitStyle",
					desc = "TODO waitStyle",
					get = function(info) return self.db1.profile.sthrottles[info.arg].waitStyle end,
					set = function(info, value) self.db1.profile.sthrottles[info.arg].waitStyle = value end,
					arg = k,
				},--]]
				--[[inc = {
					type = 'toggle',
					name = L["Incoming"],
					desc = L["Filter incoming spells"],
					get = function(info) return not not self.db1.profile.sfilters[info.arg].inc end,
					set = function(info, value) self.db1.profile.sfilters[info.arg].inc = value end,
					arg = k,
					order = 3,
				},
				out = {
					type = 'toggle',
					name = L["Outgoing"],
					desc = L["Filter outgoing spells"],
					get = function(info) return not not self.db1.profile.sfilters[info.arg].out end,
					set = function(info, value) self.db1.profile.sfilters[info.arg].out = value end,
					arg = k,
					order = 4,
				},--]]
				delete = {
					type = 'execute',
					name = L["Remove"],
					desc = L["Remove throttle"],
					func = removeThrottle,
					arg = k,
					order = -1,
				},
			}
		}
	end

	events_opt.args.sthrottles.args.new = {
		order = 1,
		type = 'execute',
		name = L["New throttle"],
		desc = L["Add a new throttle."],
		func = function()
			self.db1.profile.sthrottles[''] = {}
			local t = makeSpellThrottle('')
			sthrottles_opt.args[tostring(t)] = t
		end,
	}


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
	for spellFilter in pairs(self.db1.profile.sfilters) do
		local f = makeFilter(spellFilter)
		sfilters_opt.args[tostring(f)] = f
	end
	for spellThrottle in pairs(self.db1.profile.sthrottles) do
		local f = makeSpellThrottle(spellThrottle)
		sthrottles_opt.args[tostring(f)] = f
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
			local check = v.check
			if not check then
				--fallback when no check-function is present
				check = function() return true end
			end
			if type(check) ~= "function" then
				error(("Bad argument #2 to `RegisterCombatEvent'. check must be a %q or nil, got %q."):format("function", type(check)), 2)
			end
			table.insert(self.combatLogEvents[eventType], { category = data.category, name = data.name, infofunc = v.func, checkfunc = check })
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
		local db = Parrot_CombatEvents.db1.profile.modifier
		if db.color then
			return "|cff" .. db.absorb.color .. info.absorbAmount .. "|r"
		else
			return info.absorbAmount
		end
	end },
	block = { Amount = function(info)
		local db = Parrot_CombatEvents.db1.profile.modifier
		if db.color then
			return "|cff" .. db.block.color .. info.blockAmount .. "|r"
		else
			return info.blockAmount
		end
	end },
	resist = { Amount = function(info)
		local db = Parrot_CombatEvents.db1.profile.modifier
		if db.color then
			return "|cff" .. db.resist.color .. info.resistAmount .. "|r"
		else
			return info.resistAmount
		end
	end },
	vulnerable = { Amount = function(info)
		local db = Parrot_CombatEvents.db1.profile.modifier
		if db.color then
			return "|cff" .. db.vulnerable.color .. info.vulnerableAmount .. "|r"
		else
			return info.vulnerableAmount
		end
	end },
	overheal = { Amount = function(info)
		local db = Parrot_CombatEvents.db1.profile.modifier
		if db.color then
			return "|cff" .. db.overheal.color .. info.overhealAmount .. "|r"
		else
			return info.overhealAmount
		end
	end },
	--
	overkill = { Amount = function(info)
		local db = Parrot_CombatEvents.db1.profile.modifier
		if db.color then
			return "|cff" .. db.overkill.color .. info.overkill .. "|r"
		else
			return info.overkillAmount
		end
	end },
	--
	glancing = { Text = function(info)
		local db = Parrot_CombatEvents.db1.profile.modifier
		if db.color then
			return "|r" .. info[1] .. "|cff" .. db.glancing.color
		else
			return info[1]
		end
	end },
	crushing = { Text = function(info)
		local db = Parrot_CombatEvents.db1.profile.modifier
		if db.color then
			return "|r" .. info[1] .. "|cff" .. db.crushing.color
		else
			return info[1]
		end
	end },
	crit = { Text = function(info)
		local db = Parrot_CombatEvents.db1.profile.modifier
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
	overkill = { Amount = L["The amount of overkill."] },
	glancing = { Text = L["The normal text."] },
	crushing = { Text = L["The normal text."] },
	crit = { Text = L["The normal text."] },
}

local throttleData = {}

onEnableFuncs[#onEnableFuncs+1] = function()
--	Parrot_CombatEvents:AddRepeatingTimer(0.05, "RunThrottle")
	Parrot_CombatEvents:AddRepeatingTimer(1.0, "RunThrottle")
end

local LAST_TIME = _G.newproxy() -- cheaper than {}
local NEXT_TIME = _G.newproxy() -- cheaper than {}
local STHROTTLE = _G.newproxy() -- for spell-throttle

-- #NODOC
function Parrot_CombatEvents:RunThrottle(force)
	local now = GetTime()
	local action = false
	for throttleType,w in pairs(throttleData) do
		action = true
		local goodTime = now
		local waitStyle = throttleWaitStyles[throttleType]
		if not waitStyle then
			local throttleTime = self.db1.profile.throttles[throttleType] or throttleDefaultTimes[throttleType]
			goodTime = now - throttleTime
		end
		for category,v in pairs(w) do
			for name,u in pairs(v) do
				for id,info in pairs(u) do
					local goodTime2 = goodTime
					local waitStyle2 = waitStyle
					if info[STHROTTLE] then
						waitStyle2 = info[STHROTTLE].waitStyle
						if not waitStyle2 then
							goodTime2 = now - info[STHROTTLE].time
						end
					end
					if not waitStyle2 then
						if info[LAST_TIME] == nil then
							debug("--------------- now it's nil -------------")
						end
						if force or goodTime2 >= info[LAST_TIME] then
							local todel = true
							for k,v in pairs(info) do
								if k ~= LAST_TIME and k ~= STHROTTLE then
									todel = false
									break
								end
							end
							-- cleanup
							if todel then
								u[id] = del(info)
							else
								self:TriggerCombatEvent(category, name, info, true)
							end
						end
					else
						if force or goodTime2 >= info[NEXT_TIME] then
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

local sthrottles

onEnableFuncs[#onEnableFuncs + 1] = function()
	sthrottles = self.db1.profile.sthrottles
end

local function get_sthrottle(info)
	local sthrottle = sthrottles[info.spellID] or sthrottles[info.abilityName]
	return sthrottle
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

	local db = self.db1.profile[category][name]
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
		local base = self.db1.profile.filters[actualType] or filterDefaults[actualType]
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
		if info[STHROTTLE] then
			if info[STHROTTLE].waitStyle then
				info[NEXT_TIME] = nil
			else
				info[LAST_TIME] = GetTime()
			end
		else
			if throttleWaitStyles[data.throttle[1]] then

				info[NEXT_TIME] = nil
			else

				info[LAST_TIME] = GetTime()
			end
		end
	elseif data.throttle then
		local throttle = data.throttle
		local throttleType = throttle[1]
		-- TODO per-spell-throttle
		local sthrottle = get_sthrottle(info)

		if (self.db1.profile.throttles[throttleType] or throttleDefaultTimes[throttleType]) > 0 or (sthrottle and sthrottle.time > 0) then
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
				if (sthrottle) then
					if sthrottle.waitStyle then
						t[NEXT_TIME] = GetTime() + sthrottle.time
					else
						t[LAST_TIME] = 0
					end
					t[STHROTTLE] = sthrottle
				else
					if throttleWaitStyles[throttleType] then
						t[NEXT_TIME] = GetTime() + (self.db1.profile.throttles[throttleType] or throttleDefaultTimes[throttleType])
					else
						t[LAST_TIME] = 0
					end
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
			if k ~= LAST_TIME and k ~= STHROTTLE then
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
	local db = Parrot_CombatEvents.db1.profile[category][name]
	local data = combatEvents[category][name]

	local throttle = data.throttle
	local throttleSuffix
	if throttle then
		local throttleType = throttle[1]
		if (Parrot_CombatEvents.db1.profile.throttles[throttleType] or throttleDefaultTimes[throttleType]) > 0 then
			local throttleCountData = throttle[3]
			if throttleCountData then
				local func = throttleCountData[#throttleCountData]
				throttleSuffix = func(info)
			end
		end
	end

	local sticky = false
	if data.canCrit then
		sticky = info.isCrit and Parrot_CombatEvents.db1.profile.stickyCrit
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
	local overkillAmount = info.overkill
	local modifierDB = Parrot_CombatEvents.db1.profile.modifier
	if overhealAmount and overhealAmount >= 1 then
		if modifierDB.overheal.enabled then
			handler__translation = modifierTranslations.overheal
			t[#t+1] = modifierDB.overheal.tag:gsub("(%b[])", handler)
		end
		text = table.concat(t)
	elseif overkillAmount and overkillAmount >= 1 then
		if modifierDB.overkill.enabled then
			handler__translation = modifierTranslations.overkill
			t[#t+1] = modifierDB.overkill.tag:gsub("(%b[])", handler)
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

local sfilters
onEnableFuncs[#onEnableFuncs + 1] = function()
	sfilters = self.db1.profile.sfilters
end

local function sfiltered(info)
	local filter = sfilters[tostring(info.spellID)] or sfilters[info.abilityName]
	if filter and (not filter.amount or (filter.amount > (info.realAmount or info.amount or 0))) then
		if (filter.inc and UnitGUID("player") ~= info.recipientID) or
			(filter.out and UnitGUID("player") ~= info.sourceID) then

			return false
		end
		return true
	end

	return false
end

function Parrot_CombatEvents:HandleEvent(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)

	if not Parrot:IsModuleActive(Parrot_CombatEvents) then
		return
	end
	local registeredHandlers = self.combatLogEvents[eventtype]
	if registeredHandlers then
		for _, v in ipairs(registeredHandlers) do

			if v.checkfunc(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...) then
				local info = v.infofunc(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
				if info then
					if sfiltered(info) then
						info = del(info)
						return
					end
					info.uid = (srcGUID or 0) + (dstGUID or 0) + timestamp
					self:TriggerCombatEvent(v.category, v.name, info)
					info = del( info )
				end
			end

		end
	end

end
