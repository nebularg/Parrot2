local _, ns = ...
local Parrot = ns.addon
if not Parrot then return end

local module = Parrot:NewModule("CombatEvents", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Parrot")

local LibSharedMedia = LibStub("LibSharedMedia-3.0")

local tinsert, tremove, tconcat, tsort = table.insert, table.remove, table.concat, table.sort
local newList, del, newDict = Parrot.newList, Parrot.del, Parrot.newDict
local debug = Parrot.debug

-- used as table for data about combatEvents in the registry
local combatEvents = {}
local sthrottles
local playerGUID = UnitGUID("player")

-- lookup-table for damage-types
local LS = {
	["Physical"] = _G.STRING_SCHOOL_PHYSICAL,
	["Holy"] = _G.STRING_SCHOOL_HOLY,
	["Fire"] = _G.STRING_SCHOOL_FIRE,
	["Nature"] = _G.STRING_SCHOOL_NATURE,
	["Frost"] = _G.STRING_SCHOOL_FROST,
	["Frostfire"] = _G.STRING_SCHOOL_FROSTFIRE,
	["Froststorm"] = _G.STRING_SCHOOL_FROSTSTORM,
	["Shadow"] = _G.STRING_SCHOOL_SHADOW,
	["Shadowstorm"] = _G.STRING_SCHOOL_SHADOWSTORM,
	["Arcane"] = _G.STRING_SCHOOL_ARCANE,
}

local UNKNOWN = _G.UNKNOWN

local db = nil
local defaults = {
	profile = {
		['*'] = {
			['*'] = {}
		},
		dbver = 0, --[[this must remain 0 so that users upgrading from verions
		with no dbver run through all update-functions --]]
		cancelUIDSoon = true,
		filters = {},
		sfilters = {},
		throttles = {},
		sthrottles = {},
		useShortThrottleText = true,
		abbreviateStyle = "abbreviate",
		abbreviateLength = 30,
		stickyCrit = true,
		disable_in_raid = false,
		disable_in_battleground = false,
		hideFullOverheals = 1,
		hideSkillNames = false,
		hideUnitNames = false,
		shortenAmount = false,
		breakUpAmount = false,
		classcolor = true,
		totemDamage = true,
		hideRealm = true,
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

--[[
-- to upgrade the DB from previous.
-- usage: if the format is changed, change the defaults to the new format.
-- Then add functions for converting old settings.
--]]
local updateDBFuncs = {
	[1] = function()
		local entry = db.Notification["Skill cooldown finish"]
		if entry and entry.tag then
			entry.tag = entry.tag:gsub("%[Skill%]","[Spell]")
		end
	end,
	[2] = function()
		local entry = db.Notification["Skill gains"]
		if entry and entry.tag then
			entry.tag = entry.tag:gsub("%[Skill%]","[Skillname]")
		end
	end,
	[3] = function()
		db.hideRealm = not Parrot.db.profile.showNameRealm
		Parrot.db.profile.showNameRealm = nil
		db.totemEvents = Parrot.db.profile.totemDamage
		Parrot.db.profile.totemDamage = nil
	end,
	[4] = function()
		if db.hideFullOverheals == false then
			db.hideFullOverheals = 0
		end
	end,
	[5] = function()
		if db.disable_in_10man and db.disable_in_25man then
			db.disable_in_raid = true
		end
		db.disable_in_10man = nil
		db.disable_in_25man = nil
	end,
}

local function updateDB()
	if not db.dbver then
		db.dbver = 0
	end
	for i = db.dbver+1, #updateDBFuncs do
		updateDBFuncs[i]()
		db.dbver = i
	end
end

function module:OnNewProfile(_, database)
	database.profile.dbver = #updateDBFuncs
end

function module:OnProfileChanged()
	db = self.db.profile
	updateDB()
	sthrottles = db.sthrottles or {}
	if next(Parrot.options.args) then
		Parrot.options.args.events = del(Parrot.options.args.events)
		self:OnOptionsCreate()
	end
end

local function checkZone()
	local _, instance_type = IsInInstance()
	if  instance_type == "raid" and db.disable_in_raid then
		module:Disable()
	elseif instance_type == "pvp" and db.disable_in_battleground then
		module:Disable()
	elseif not module:IsEnabled() then
		module:Enable()
	end
end

function module:OnInitialize()
	self.db = Parrot.db:RegisterNamespace("CombatEvents", defaults)
	self.db.RegisterCallback(self, "OnNewProfile", "OnNewProfile")
	db = self.db.profile
	updateDB()
	sthrottles = db.sthrottles or {}

	-- Register with Addons CombatLogEvent-registry for uid-stuff
	Parrot:RegisterCombatLog(self)

	self:RegisterEvent("PLAYER_ENTERING_WORLD", checkZone)
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", checkZone)
end

function module:OnEnable()
	self:ScheduleRepeatingTimer("RunThrottle", 0.05)
end

--[[
-- helper-function for spell-abbriviation
--]]
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

--[[
-- abbriviate a spell according to options.
-- Example: "Shadow Bolt"
-- + None: "Shadow Bolt
-- + Truncate: "Shad..."
-- + Abbriviate: "SB"
--]]
function module:GetAbbreviatedSpell(name)
	if not name then return end
	local style = db.abbreviateStyle
	if style == "none" then
		return name
	end
	local name_len = 0
	local i = 1
	while i <= #name do
		name_len = name_len + 1
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
	local neededLen = db.abbreviateLength
	if name_len < neededLen then
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
		i = 0
		while i < #t do
			i = i + 1
			if t[i] == "" then
				tremove(t, i)
				i = i - 1
			end
		end
		if #t == 1 then
			t = del(t)
			return name
		end
		for j = 1, #t do
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
				local alpha, bravo = t[j]:sub(1, len), t[j]:sub(len+1)
				if bravo:find(":") then
					t[j] = alpha .. ":"
				else
					t[j] = alpha
				end
			else
				t[j] = ""
			end
		end
		local s = tconcat(t)
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
Parrot.GetAbbreviatedSpell = module.GetAbbreviatedSpell

local modifierTranslationHelps

local throttleTypes = {}
local throttleDefaultTimes = {}
local throttleWaitStyles = {}

local filterTypes = {}
local filterDefaults = {}

local function createOption() end
local function createThrottleOption() end
local function createFilterOption() end

local function setOption(info, value)
	local name = info[#info]
	debug("Parrot.db: set option ", name, " = ", value)
	db[name] = value
end
local function getOption(info)
	local name = info[#info]
	return db[name]
end

local function tupleToHexColor(r, g, b)
	return ("%02x%02x%02x"):format(r * 255, g * 255, b * 255)
end
local function hexColorToTuple(color)
	local num = tonumber(color, 16)
	return math.floor(num / 256^2)/255, math.floor((num / 256)%256)/255, (num%256)/255
end


function module:OnOptionsCreate()
	local function getSubOption(info)
		local name = info[#info]
		local category = info[#info - 1]
		return db[category][name]
	end
	local function getSubOptionFromArg(info)
		local name = info[#info]
		local arg = info[#info - 1]
		local category = info[#info - 2]
		debug(category, " - ", arg)
		return db[category][arg][name]
	end

	local function setSubOption(info, value)
		local name = info[#info]
		local category = info[#info - 1]
		db[category][name] = value
	end
	local function setSubOptionFromArg(info, value)
		local name = info[#info]
		local arg = info[#info - 1]
		local category = info[#info - 2]
		db[category][arg][name] = value
	end

	local events_opt
	events_opt = {
		type = 'group',
		name = L["Events"],
		desc = L["Change event settings"],
		order = 2,
		get = getOption,
		set = setOption,
		args = {
			enabled = {
				name = L["Enabled"],
				type = 'group',
				inline = true,
				args = {
					disable_in_raid = {
						type = 'toggle',
						name = L["Disable in raids"],
						desc = L["Disable this module while in a raid instance"],
						set = function(info, value)
							setOption(info, value)
							checkZone()
						end,
						order = 1,
					},
					disable_in_battleground = {
						type = 'toggle',
						name = L["Disable in pvp"],
						desc = L["Disable this module while in a battleground"],
						set = function(info, value)
							setOption(info, value)
							checkZone()
						end,
						order = 2,
					},
				},
			},
			textoptions = {
				name = L["Text options"],
				type = 'group',
				inline = true,
				args = {
					hideFullOverheals = {
						type = 'select',
						name = L["Hide full overheals"],
						desc = L["Do not show heal events when 100% of the amount is overheal"],
						values = {
							[0] = L["Off"],
							[1] = L["Only HoTs"],
							[2] = L["Only direct heals"],
							[3] = L["On"],
						},
						order = 1,
					},
					sep = {
						type = "description",
						name = "",
						order = 2,
					},
					hideSkillNames = {
						type = 'toggle',
						name = L["Hide skill names"],
						desc = L["Always hide skill names even when present in the tag"],
						order = 3,
					},
					hideUnitNames = {
						type = 'toggle',
						name = L["Hide unit names"],
						desc = L["Always hide unit names even when present in the tag"],
						order = 4,
					},
					hideRealm = {
						type = 'toggle',
						name = L["Hide realm"],
						desc = L["Hide realm in player names"],
						order = 5,
					},
					classcolor = {
						type = 'toggle',
						name = L["Color by class"],
						desc = L["Color unit names by class"],
						order = 6,
					},
					shortenAmount = {
						type = 'toggle',
						name = L["Shorten amounts"],
						desc = L["Abbreviate number values displayed (26500 -> 26.5k)"],
						disabled = function() return db.breakUpAmount end,
						order = 7,
					},
					breakUpAmount = {
						type = 'toggle',
						name = L["Break up amounts"],
						desc = L["Break up number values with '%s' (26500 -> %s)"]:format(LARGE_NUMBER_SEPERATOR, BreakUpLargeNumbers(26500)),
						disabled = function() return db.shortenAmount end,
						order = 8,
					}
				},
			},
			totemEvents = {
				type = 'toggle',
				name = L["Show guardian events"],
				desc = L["Whether events involving your guardian(s) (totems, ...) should be displayed"],
			},
			cancelUIDSoon = {
				type = 'toggle',
				name = L["Hide events used in triggers"],
				desc = L["Hides combat events when they were used in triggers"],
				width = "double",
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
			modifier = {
				type = 'group',
				name = L["Event modifiers"],
				desc = L["Options for event modifiers."],
				get = getSubOption,
				set = setSubOption,
				args = {
					color = {
						order = 1,
						type = 'toggle',
						name = L["Color"],
						desc = L["Whether to color event modifiers or not."],
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
							return db.damageTypes.color
						end,
						set = function(info, value)
							db.damageTypes.color = value
						end
					}
				}
			},
			stickyCrit = {
				type = 'toggle',
				name = L["Sticky crits"],
				desc = L["Enable to show crits in the sticky style."],
			},
			throttle = {
				type = 'group',
				name = L["Throttle events"],
				desc = L["Whether to merge mass events into single instances instead of excessive spam."],
				args = {
					useShortThrottleText = {
						type = 'toggle',
						name = L["Short texts"],
						desc = L["Use short throttle-texts (like \"2++\" instead of \"2 crits\")"],
						order = 1,
					}
				},
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
					abbreviateStyle = {
						type = 'select',
						name = L["Style"],
						desc = L["How or whether to shorten spell names."],
						values = {
							none = L["None"],
							abbreviate = L["Abbreviate"],
							truncate = L["Truncate"],
						},
						order = 1,
					},
					abbreviateLength = {
						type = 'range',
						name = L["Length"],
						desc = L["The length at which to shorten spell names."],
						disabled = function()
							return db.abbreviateStyle == "none"
						end,
						min = 1,
						max = 30,
						step = 1,
						order = 2,
					},
					abbrDesc = {
						type = 'description',
						name = ("%s: %s\n%s: %s\n%s: %s"):format(
							L["None"], L["Do not shorten spell names."],
							L["Abbreviate"], L["Gift of the Wild => GotW."],
							L["Truncate"], L["Gift of the Wild => Gift of t..."]
						),
						order = 3,
					},
				},
			},
		}
	}
	Parrot:AddOption('events', events_opt)

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

	do
		-- Event modifiers
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
		local function setTag(info, value)
			handler__tagTranslations = modifierTranslationHelps[info.arg]
			db.modifier[info.arg].tag = value:gsub("(%b[])", handler)
			handler__tagTranslations = nil
		end

		local function getModifierColor(info)
			return hexColorToTuple(db.modifier[info.arg].color)
		end
		local function setModifierColor(info, r, g, b)
			db.modifier[info.arg].color = tupleToHexColor(r, g, b)
		end

		for k,v in pairs(tmp) do
			local usage = L["<Tag>"]
			local translationHelp = modifierTranslationHelps[k]
			if translationHelp then
				local tags = newList()
				for tag in next, translationHelp do
					tags[#tags+1] = tag
				end
				tsort(tags)
				for _, tag in ipairs(tags) do
					usage = ("%s\n[%s] => %s"):format(usage, tag, translationHelp[tag])
				end
				tags = del(tags)
			end
			events_opt.args.modifier.args[k] = {
				type = 'group',
				name = v,
				desc = v,
				get = getSubOptionFromArg,
				set = setSubOptionFromArg,
				args = {
					enabled = {
						type = 'toggle',
						name = L["Enabled"],
						desc = L["Whether to enable showing this event modifier."],
						order = -1,
						arg = k,
					},
					color = {
						type = 'color',
						name = L["Color"],
						desc = L["What color this event modifier takes on."],
						get = getModifierColor,
						set = setModifierColor,
						arg = k,
					},
					tag = {
						type = 'input',
						name = L["Text"],
						desc = L["What text this event modifier shows."],
						usage = usage,
						set = setTag,
						arg = k,
					},
				}
			}
		end
		tmp = del(tmp)
	end

	do
		-- Damage types
		local tmp = newDict(
			"Physical", LS["Physical"],
			"Holy", LS["Holy"],
			"Fire", LS["Fire"],
			"Nature", LS["Nature"],
			"Frost", LS["Frost"],
			"Shadow", LS["Shadow"],
			"Arcane", LS["Arcane"],
			"Frostfire", LS["Frostfire"],
			"Froststorm", LS["Froststorm"],
			"Shadowstorm", LS["Shadowstorm"]
		)
		local function getColor(info)
			return hexColorToTuple(db.damageTypes[info.arg])
		end
		local function setColor(info, r, g, b)
			db.damageTypes[info.arg] = tupleToHexColor(r, g, b)
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
	end

	-- CombatEvents
	local function getArgs(info)
		local category = info[2]
		local name = info[4]
		-- for i,v in ipairs(info) do
		-- 	debug(i, " = ", v)
		-- end
		return category, name
	end
	local function getTag(info)
		local category, name = getArgs(info)
		return db[category][name].tag or combatEvents[category][name].defaultTag
	end
	local function setTag(info, value)
		local category, name = getArgs(info)
		handler__tagTranslations = combatEvents[category][name].tagTranslations
		value = value:gsub("(%b[])", handler)
		handler__tagTranslations = nil
		if value == "" or combatEvents[category][name].defaultTag == value then
			value = nil
		end
		db[category][name].tag = value
	end

	local function getColor(info)
		local category, name = getArgs(info)
		return hexColorToTuple(db[category][name].color or combatEvents[category][name].color)
	end
	local function setColor(info, r, g, b)
		local category, name = getArgs(info)
		local color = tupleToHexColor(r, g, b)
		local combatEvent = combatEvents[category][name]
		if combatEvent.color == color then
			color = nil
		end
		db[category][name].color = color
	end

	local function getSticky(info)
		local category, name = getArgs(info)
		local sticky = db[category][name].sticky
		if sticky ~= nil then
			return sticky
		else
			return combatEvents[category][name].sticky
		end
	end
	local function setSticky(info, value)
		local category, name = getArgs(info)
		if (not not combatEvents[category][name].sticky) == value then
			value = nil
		end
		db[category][name].sticky = value
	end

	local function getFontFace(info)
		local category, name = getArgs(info)
		local font = db[category][name].font
		if font == nil then
			return -1
		end
		for i, v in next, Parrot.fontValues do
			if v == font then return i end
		end
	end
	local function setFontFace(info, value)
		local category, name = getArgs(info)
		if value == -1 then
			db[category][name].font = nil
		else
			db[category][name].font = Parrot.fontValues[value]
		end
	end
	local function getFontSize(info)
		local category, name = getArgs(info)
		return db[category][name].fontSize
	end
	local function setFontSize(info, value)
		local category, name = getArgs(info)
		db[category][name].fontSize = value
	end
	local function getFontSizeInherit(info)
		local category, name = getArgs(info)
		return db[category][name].fontSize == nil
	end
	local function setFontSizeInherit(info, value)
		local category, name = getArgs(info)
		if value then
			db[category][name].fontSize = nil
		else
			db[category][name].fontSize = 18
		end
	end
	local function getFontOutline(info)
		local category, name = getArgs(info)
		local outline = db[category][name].fontOutline
		if outline == nil then
			return L["Inherit"]
		else
			return outline
		end
	end
	local function setFontOutline(info, value)
		local category, name = getArgs(info)
		if value == L["Inherit"] then
			value = nil
		end
		db[category][name].fontOutline = value
	end
	local fontOutlineChoices = {
		NONE = L["None"],
		MONOCHROME = L["Monochrome"],
		OUTLINE = L["Thin"],
		["OUTLINE,MONOCHROME"] = L["Thin, Monochrome"],
		THICKOUTLINE = L["Thick"],
		[L["Inherit"]] = L["Inherit"],
	}
	local function getEnable2(category, name)
		local disabled = db[category][name].disabled
		if disabled == nil then
			disabled = combatEvents[category][name].defaultDisabled
		end
		return not disabled
	end
	local function getEnable(info)
		return getEnable2(getArgs(info))
	end
	local function setEnable(info, value)
		local category, name = getArgs(info)
		local disabled = not value
		if (not not combatEvents[category][name].defaultDisabled) == disabled then
			disabled = nil
		end
		db[category][name].disabled = disabled
	end
	local function getScrollArea2(category, name)
		local scrollArea = db[category][name].scrollArea
		if scrollArea == nil then
			scrollArea = category
		end
		return scrollArea
	end
	local function getScrollArea(info)
		return getScrollArea2(getArgs(info))
	end
	local function doSetScrollArea(category, name, value)
		if value == category then
			value = nil
		end
		db[category][name].scrollArea = value
	end
	local function setScrollArea(info, value)
		local category, name = getArgs(info)
		doSetScrollArea(category, name, value)

	end
	local function getSound(info)
		local category, name = getArgs(info)
		local value = db[category][name].sound or "None"
		for i, v in next, Parrot.soundValues do
			if v == value then
				return i
			end
		end
	end
	local function setSound(info, value)
		local category, name = getArgs(info)
		local v = Parrot.soundValues[value]
		PlaySoundFile(LibSharedMedia:Fetch("sound", v), "Master")
		if v == "None" then
			v = nil
		end
		db[category][name].sound = v
	end

	local function getCommonEnabled(info)
		local category, subcat = info.arg[1], info.arg[2]

		local one_enabled, one_disabled = false, false
		for k,v in pairs(combatEvents[category]) do
			if v.subCategory == subcat then
				if getEnable2(category, v.name) then
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
				db[category][v.name].disabled = not value
			end
		end

	end

	local function getCommonScrollArea(info)
		local category, subcat = info.arg[1], info.arg[2]
		local common_choice
		for k,v in pairs(combatEvents[category]) do
			if v.subCategory == subcat then
				local choice = getScrollArea2(category, v.name)
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
				doSetScrollArea(category, v.name, value )
			end
		end
	end

	-- copy the choices
	local function getScrollAreasChoices()
		local tmp = {}
		for k,v in pairs(Parrot:GetScrollAreasChoices()) do
			tmp[k] = v
		end
		return tmp
	end

	function createOption(category, name)
		local data = combatEvents[category][name]

		if not events_opt.args[category] then
			events_opt.args[category] = {
				type = 'group',
				name = category,
				--desc = category,
				args = {},
				order = 2,
			}
		end

		local subcat = data.subCategory
		local arg = newList(category, subcat)
		-- added so that options get sorted into subcategories
		if not events_opt.args[category].args[subcat] then
			events_opt.args[category].args[subcat] = {
				type = 'group',
				name = subcat,
				--desc = subcat,
				args = {
					enabled = {
						name = L["Enabled"],
						desc = L["Whether all events in this category are enabled."],
						type = 'toggle',
						tristate = true,
						get = getCommonEnabled,
						set = setCommonEnabled,
						arg = arg,
					},
					scrollarea = {
						name = L["Scroll area"],
						desc = L["Scoll area where all events will be shown"],
						type = 'select',
						values = getScrollAreasChoices,
						get = getCommonScrollArea,
						set = setCommonScrollArea,
						arg = arg,
					},
				},
				order = 1,
			}
		end

		local usage = L["<Tag>"]
		if data.tagTranslationsHelp then
			local tags = newList()
			for tag in next, data.tagTranslationsHelp do
				tags[#tags+1] = tag
			end
			tsort(tags)
			for _, tag in ipairs(tags) do
				usage = ("%s\n[%s] => %s"):format(usage, tag, data.tagTranslationsHelp[tag])
			end
			tags = del(tags)
		end

		events_opt.args[category].args[subcat].args[name] = {
			type = 'group',
			name = data.localName,
			--desc = localName,
			args = {
				tag = {
					name = L["Tag"],
					desc = L["Tag to show for the current event."],
					type = 'input',
					usage = usage,
					get = getTag,
					set = setTag,
					order = 1,
				},
				color = {
					name = L["Color"],
					desc = L["Color of the text for the current event."],
					type = 'color',
					get = getColor,
					set = setColor,
				},
				sound = {
					type = 'select',
					name = L["Sound"],
					desc = L["What sound to play when the current event occurs."],
					values = Parrot.soundValues,
					get = getSound,
					set = setSound,
					itemControl = "DDI-Sound",
				},
				sticky = {
					name = L["Sticky"],
					desc = L["Whether the current event should be classified as \"Sticky\""],
					type = 'toggle',
					get = getSticky,
					set = setSticky,
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
							values = Parrot.fontWithInheritValues,
							get = getFontFace,
							set = setFontFace,
							itemControl = "DDI-Font",
							order = 1,
						},
						fontSizeInherit = {
							type = 'toggle',
							name = L["Inherit font size"],
							desc = L["Inherit font size"],
							get = getFontSizeInherit,
							set = setFontSizeInherit,
							order = 2,
						},
						fontSize = {
							type = 'range',
							name = L["Font size"],
							desc = L["Font size"],
							min = 6,
							max = 30,
							step = 1,
							get = getFontSize,
							set = setFontSize,
							disabled = getFontSizeInherit,
							order = 3,
						},
						fontOutline = {
							type = 'select',
							name = L["Font outline"],
							desc = L["Font outline"],
							get = getFontOutline,
							set = setFontOutline,
							values = fontOutlineChoices,
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
				},
				scrollArea = {
					type = 'select',
					name = L["Scroll area"],
					desc = L["Which scroll area to use."],
					values = getScrollAreasChoices,
					get = getScrollArea,
					set = setScrollArea,
				},
			},
		}
	end

	-- Throttle
	local function getTimespan(info)
		local throttleType = info.arg
		return db.throttles[throttleType] or throttleDefaultTimes[throttleType]
	end
	local function setTimespan(info, value)
		local throttleType = info.arg
		if value == throttleDefaultTimes[throttleType] then
			value = nil
		end
		db.throttles[throttleType] = value
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
		return db.filters[filterType] or filterDefaults[filterType]
	end
	local function setAmount(info, value)
		local filterType = info.arg
		if value == filterDefaults[filterType] then
			value = nil
		end
		db.filters[filterType] = value
	end
	function createFilterOption(filterType)
		local localName = filterTypes[filterType]
		events_opt.args.filters.args[filterType] = {
			type = 'range',
			name = localName,
			desc = L["What amount to filter out. Any amount below this will be filtered.\nNote: a value of 0 will mean no filtering takes place."],
			min = 0,
			max = 100000,
			step = 1,
			bigStep = 20,
			get = getAmount,
			set = setAmount,
			arg = filterType
		}
	end

	local sfilters_opt = events_opt.args.sfilters

	local function setSpellName(info, new)
		if db.sfilters[new] ~= nil then
			return
		end

		local old = info.arg
		db.sfilters[new] = db.sfilters[old]
		db.sfilters[old] = nil

		local opt = sfilters_opt.args[info[#info-1]]
		local name = new == '' and L["New filter"] or new

		opt.order = new == '' and -110 or -100
		opt.name = name
		opt.desc = name
		for k,v in pairs(opt.args) do
			v.arg = new
		end
	end

	local function removeFilter(info)
		db.sfilters[info.arg] = nil
		sfilters_opt.args[info[#info-1]] = nil
	end

	local function setFilterAmount(info, value)
		db.sfilters[info.arg].amount = tonumber(value)
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
					get = function(info) return tostring(db.sfilters[info.arg].amount or "") end,
					set = setFilterAmount,
					arg = k,
					order = 2,
				},
				inc = {
					type = 'toggle',
					name = L["Incoming"],
					desc = L["Filter incoming spells"],
					get = function(info) return not not db.sfilters[info.arg].inc end,
					set = function(info, value) db.sfilters[info.arg].inc = value end,
					arg = k,
					order = 3,
				},
				out = {
					type = 'toggle',
					name = L["Outgoing"],
					desc = L["Filter outgoing spells"],
					get = function(info) return not not db.sfilters[info.arg].out end,
					set = function(info, value) db.sfilters[info.arg].out = value end,
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
			db.sfilters[''] = {}
			local t = makeFilter('')
			sfilters_opt.args[tostring(t)] = t
		end,
	}

	-- per-spell-throttle-options
	local sthrottles_opt = events_opt.args.sthrottles

	local function setThrottleSpellName(info, new)
		if db.sfilters[new] ~= nil then
			return
		end
		local old = info.arg
		db.sthrottles[new] = db.sthrottles[old]
		db.sthrottles[old] = nil
		local opt = sthrottles_opt.args[info[#info-1]]
		local name = new == '' and L["New throttle"] or new

		opt.order = new == '' and -110 or -100
		opt.name = name
		opt.desc = name
		for k,v in pairs(opt.args) do
			v.arg = new
		end
	end

	local function removeThrottle(info)
		db.sthrottles[info.arg] = nil
		sthrottles_opt.args[info[#info-1]] = nil
	end

	local function setThrottleTime(info, value)
		if (value == 0) then
			value = nil
		end
		db.sthrottles[info.arg].time = value
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
					get = function(info) return (db.sthrottles[info.arg].time or 0) end,
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
					get = function(info) return db.sthrottles[info.arg].waitStyle end,
					set = function(info, value) db.sthrottles[info.arg].waitStyle = value end,
					arg = k,
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
			db.sthrottles[''] = {}
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
	for spellFilter in pairs(db.sfilters) do
		local f = makeFilter(spellFilter)
		sfilters_opt.args[tostring(f)] = f
	end
	for spellThrottle in pairs(db.sthrottles) do
		local f = makeSpellThrottle(spellThrottle)
		sthrottles_opt.args[tostring(f)] = f
	end
end

--[[
-- eventHandlerFunction-tables
--]]
local combatLogEvents = {}
local registeredBlizzardEvents = {}

local function truecheck()
	return true
end

--[[----------------------------------------------------------------------------------
-- TODO more args-doc
Arguments:
	table - a data table holding the details of a combat event.
Notes:
	The data table is of the following style:
	<pre>{
		category = "Name of the category in English",
		name = "Name of the condition in English",
		localName = "Name of the condition in the current locale",
		defaultTag = "The default tagstring in the current locale", -- this can and should include relevant tags.
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
			sourceName = L.Multiple -- any key-value mappings will change the info table if there are multiple throttled events.
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
		localName = L.Melee_dodges,
		defaultTag = L.DODGE,
		tagTranslations = {
			Name = "recipientName",
		},
		tagTranslationsHelp = {
			Name = L.The_name_of_the_enemy_you_attacked,
		},
		color = "ffffff", -- white
	}
------------------------------------------------------------------------------------]]
function module:RegisterCombatEvent(data)
	if type(data) ~= 'table' then
		error(("Bad argument #2 to 'RegisterCombatEvent'. data must be a %q, got %q."):format("table", type(data)))
	end
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

	if data.combatLogEvents then
		for eventType, v in pairs(data.combatLogEvents) do
			-- if type(v.func) ~= 'function' then
			-- 	error(("Bad argument #2 to `RegisterCombatEvent'. func must be a %q, got %q."):format("function", type(v.func)))
			-- end
			if not combatLogEvents[eventType] then
				combatLogEvents[eventType] = {}
			end
			local check = v.check or truecheck
			if type(check) ~= "function" then
				error(("Bad argument #2 to `RegisterCombatEvent'. check must be a %q or nil, got %q."):format("function", type(check)), 2)
			end
			tinsert(combatLogEvents[eventType], {
					category = category,
					name = data.name,
					infofunc = v.func,
					checkfunc = check,
				}
			)
		end
	end

	if data.events then
		for k,v in next, data.events do
			local check = v.check or truecheck
			if type(check) ~= "function" then
				error(("Bad argument #2 to `RegisterCombatEvent'. check must be a %q or nil, got %q."):format("function", type(check)), 2)
			end
			local parse = v.parse
			if not parse then
				parse = function() return { check() } end
			end
			if not registeredBlizzardEvents[k] then
				registeredBlizzardEvents[k] = newList()
			end
			tinsert(registeredBlizzardEvents[k], {
					category = category,
					name = data.name,
					parse = parse,
					check = check,
				}
			)
			Parrot:RegisterBlizzardEvent(module, k, "HandleBlizzardEvent")
		end
	end

	createOption(category, name)
end
Parrot.RegisterCombatEvent = module.RegisterCombatEvent

--[[----------------------------------------------------------------------------------
Arguments:
	string - the name of the throttle type in English.
	string - the name of the throttle type in the current locale.
	number - the default duration in seconds.
	boolean - whether to wait for the duration before firing (true) or to fire as long as it hasn't fired in the past duration (false).
Notes:
	waitStyle is good to be set to true in events where you expect multiple hits at once and don't want to show the first hit and then the rest of the hits in one conglomerate chunk. waitStyle is good to be set to false in events where you expect a steady stream but not necessarily one that is coming from a single source.
Example:
	Parrot:RegisterThrottleType("DoTs and HoTs", L[ [=[DoTs and HoTs]=] ], 2)
------------------------------------------------------------------------------------]]
function module:RegisterThrottleType(name, localName, duration, waitStyle)
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
Parrot.RegisterThrottleType = module.RegisterThrottleType

--[[----------------------------------------------------------------------------------
Arguments:
	string - the name of the throttle type in English.
	string - the name of the throttle type in the current locale.
	number - the default filter amount.
Notes:
	Filters work by suppressing messages that do not live up to a certain minimum amount.
Example:
	Parrot_CombatEvents:RegisterFilterType("Incoming heals", L.Incoming_heals, 0)
	-- allows for a filter on incoming heals, so that if you don't want to see small heals, it's easy to suppress.
------------------------------------------------------------------------------------]]
function module:RegisterFilterType(name, localName, default)
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
Parrot.RegisterFilterType = module.RegisterFilterType

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
		value = inner:gsub("(%b[])", handler)
		return ("[%s]"):format(value)
	end
end

local function round(num, idp)
	local mult = 10 ^ (idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function shortenAmount(val)
	if(val >= 1e7) then
		return ("%sm"):format(round(val / 1e6))
	elseif(val >= 1e6) then
		return ("%sm"):format(round(val / 1e6, 2))
	elseif(val >= 1e5) then
		return ("%sk"):format(round(val / 1e3))
	elseif(val >= 1e4) then
		return ("%sk"):format(round(val / 1e3, 1))
	else
		return val
	end
end

function module:ShortenAmount(val)
	if db.shortenAmount then
		return shortenAmount(val)
	elseif db.breakUpAmount then
		return BreakUpLargeNumbers(val)
	end
	return val
end
Parrot.ShortenAmount = module.ShortenAmount


local modifierTranslations = {}

local modifiersWithAmount = {
	absorb = "absorbAmount",
	block = "blockAmount",
	resist = "resistAmount",
	vulnerable = "vulnerable",
	overheal = "overhealAmount",
	overkill = "overkill",
}
for k,v in pairs(modifiersWithAmount) do
	-- local valAmountKey = v .. "Amount"
	modifierTranslations[k] = { Amount = function(info)
		local val = module:ShortenAmount(info[v])
		if db.modifier.color then
			return "|cff" .. db.modifier[k].color .. val .. "|r"
		else
			return val
		end
	end }
end

local modifiersWithFlag = {
	"glancing",
	"crushing",
	"crit",
}
for _,v in ipairs(modifiersWithFlag) do
	modifierTranslations[v] = { Text = function(info)
		if db.modifier.color then
			return "|r" .. info[1] .. "|cff" .. db.modifier[v].color
		else
			return info[1]
		end
	end }
end

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

-- save data about pending throttles
local throttleData = {}

local LAST_TIME = _G.newproxy() -- cheaper than {}
local NEXT_TIME = _G.newproxy() -- cheaper than {}
local STHROTTLE = _G.newproxy() -- for spell-throttle

-- #NODOC
function module:RunThrottle(force)
	local now = GetTime()
	for throttleType,w in pairs(throttleData) do
		local goodTime = now
		local waitStyle = throttleWaitStyles[throttleType]
		if not waitStyle then
			local throttleTime = db.throttles[throttleType] or throttleDefaultTimes[throttleType]
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
						if force or goodTime2 >= info[LAST_TIME] then
							local todel = true
							for k in pairs(info) do
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

local function get_sthrottle(info)
	local sthrottle = sthrottles[info.spellID] or sthrottles[info.abilityName]
	return sthrottle
end

local nextFrameCombatEvents = {}
local runCachedEvents
local combatTimerFrame
local cancelUIDSoon = {}

function module:CancelEventsWithUID(uid)
	if not db.cancelUIDSoon then
		return
	end
	local i = #nextFrameCombatEvents
	while i >= 1 do
		local v = nextFrameCombatEvents[i]
		if v and uid == v[3].uid then
			tremove(nextFrameCombatEvents, i)
		end
		i = i - 1
	end
	cancelUIDSoon[uid] = true
end
Parrot.CancelEventsWithUID = module.CancelEventsWithUID

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
function module:TriggerCombatEvent(category, name, info, throttleDone)
	if not module:IsEnabled() then return end -- TODO remove

	if cancelUIDSoon[info.uid] then
		return
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

	local cdb = db[category][name]
	local disabled = cdb.disabled
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
		local sthrottle = get_sthrottle(info)

		if (db.throttles[throttleType] or throttleDefaultTimes[throttleType]) > 0 or (sthrottle and sthrottle.time > 0) then
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
						elseif type(v) == "number" and k:match("[Aa]mount") then -- sum up amounts
							t[k] = t[k] + v
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
						t[NEXT_TIME] = GetTime() + (db.throttles[throttleType] or throttleDefaultTimes[throttleType])
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

	if throttleDone then

		for k in pairs(info) do
			if k ~= LAST_TIME and k ~= STHROTTLE then
				info[k] = nil
			end
		end
	end

	if #nextFrameCombatEvents == 0 then
		combatTimerFrame:Show()
	end

	nextFrameCombatEvents[#nextFrameCombatEvents+1] = newList(category, name, infoCopy)
end
Parrot.TriggerCombatEvent = module.TriggerCombatEvent

local function runEvent(category, name, info)
	local cdb = db[category][name]
	local data = combatEvents[category][name]

	local filterType = data.filterType
	if filterType then
		local actualType = filterType[1]
		local filterKey = filterType[2]
		local base = db.filters[actualType] or filterDefaults[actualType]
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

	local throttle = data.throttle
	local throttleSuffix
	if throttle then
		local throttleType = throttle[1]
		if (db.throttles[throttleType] or throttleDefaultTimes[throttleType]) > 0 then
			local throttleCountData = throttle[3]
			if throttleCountData then
				local func = throttleCountData[#throttleCountData]
				throttleSuffix = func(info)
			end
		end
	end

	local sticky = false
	if data.canCrit then
		sticky = info.isCrit and db.stickyCrit
	end
	if not sticky then
		sticky = cdb.sticky
		if sticky == nil then
			sticky = data.sticky
		end
	end

	local text = cdb.tag or data.defaultTag
	handler__translation = data.tagTranslations
	handler__info = info
	local icon
	if handler__translation then
		if db.hideSkillNames then
			text = text:gsub("%(%[Skill%]%)","")
			text = text:gsub("%(%[Skill%] %- ","(")
			text = text:gsub("%[Skill%]","")
		end
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

	text = text:gsub("%(__NONAME__%)","")
	text = text:gsub(" %- __NONAME__%)",")")
	text = text:gsub("__NONAME__","")

	local t = newList(text)
	local overhealAmount = info.overhealAmount
	local overkillAmount = info.overkill
	local modifierDB = db.modifier
	if overhealAmount and overhealAmount >= 1 then
		if modifierDB.overheal.enabled then
			handler__translation = modifierTranslations.overheal
			t[#t+1] = modifierDB.overheal.tag:gsub("(%b[])", handler)
		end
		text = tconcat(t)
	elseif overkillAmount and overkillAmount >= 1 then
		if modifierDB.overkill.enabled then
			handler__translation = modifierTranslations.overkill
			t[#t+1] = modifierDB.overkill.tag:gsub("(%b[])", handler)
		end
		text = tconcat(t)
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
		text = tconcat(t)
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
	local r, g, b = hexColorToTuple(cdb.color or data.color)

	if throttleSuffix then
		text = text .. throttleSuffix
	end
	Parrot:ShowMessage(text, cdb.scrollArea or category, sticky, r, g, b, cdb.font, cdb.fontSize, cdb.fontOutline, icon)
	if cdb.sound then
		PlaySoundFile(LibSharedMedia:Fetch('sound', cdb.sound), "Master")
	end
end

--[[
-- TODO fix
-- FIXME leaking memory here, that does not get GC'd!
--]]
function runCachedEvents()
	for i,v in ipairs(nextFrameCombatEvents) do
		nextFrameCombatEvents[i] = nil
		runEvent(unpack(v))
		del(v[3])
		del(v)
	end

	combatTimerFrame:Hide()

	for k in pairs(cancelUIDSoon) do
		cancelUIDSoon[k] = nil
	end
end

combatTimerFrame = CreateFrame("Frame")
combatTimerFrame:Hide()
combatTimerFrame:SetScript("OnUpdate", runCachedEvents)

function module:HandleBlizzardEvent(uid, eventName, ...)
	if not self:IsEnabled() then return end

	local handlers = registeredBlizzardEvents[eventName]
	if handlers then
		for _, data in ipairs(handlers) do
			if data.check(...) then
				local info = data.parse(...)
				if info then
					if type(info) == 'table' then
						info.uid = uid
					end
					self:TriggerCombatEvent(data.category, data.name, info)
				end
			end
		end
	end
end

local function sfiltered(info)
	local filter = db.sfilters[tostring(info.spellID)] or db.sfilters[info.abilityName]
	if filter and (not filter.amount or (filter.amount > (info.realAmount or info.amount or 0))) then
		if (filter.inc and playerGUID == info.recipientID) or
		(filter.out and playerGUID == info.sourceID) then
			return true
		end
	end

	return false
end

local moreParams = {
	DAMAGE_SHIELD = { "spellId", "spellName", "spellSchool", "amount", "overkill", "school", "resisted", "blocked", "absorbed", "critical", "glancing", "crushing", },
	DAMAGE_SPLIT = { "spellId", "spellName", "spellSchool", "amount", "overkill", "school", "resisted", "blocked", "absorbed", "critical", "glancing", "crushing", },
	ENVIRONMENTAL_DAMAGE = { "environmentalType", "amount", "overkill", "school", "resisted", "blocked", "absorbed", "critical", "glancing", "crushing", },
	PARTY_KILL = { },
	RANGE_DAMAGE = { "spellId", "spellName", "spellSchool", "amount", "overkill", "school", "resisted", "blocked", "absorbed", "critical", "glancing", "crushing", },
	RANGE_MISSED = { "spellId", "spellName", "spellSchool", "missType", "isOffHand", "amountMissed", },
	SPELL_BUILDING_DAMAGE = { "spellId", "spellName", "spellSchool", "amount", "overkill", "school", "resisted", "blocked", "absorbed", "critical", "glancing", "crushing", },
	SPELL_DAMAGE = { "spellId", "spellName", "spellSchool", "amount", "overkill", "school", "resisted", "blocked", "absorbed", "critical", "glancing", "crushing", "isOffHand", },
	SPELL_DISPEL = { "spellId", "spellName", "spellSchool", "extraSpellID", "extraSpellName", "extraSchool", "auraType", },
	SPELL_DISPEL_FAILED = { "spellId", "spellName", "spellSchool", "extraSpellID", "extraSpellName", "extraSchool", },
	SPELL_DRAIN = { "spellId", "spellName", "spellSchool", "amount", "powerType", "extraAmount", },
	SPELL_ENERGIZE = { "spellId", "spellName", "spellSchool", "amount", "arg2", "powerType", },
	SPELL_EXTRA_ATTACKS = { "spellId", "spellName", "spellSchool", "amount", },
	SPELL_HEAL = { "spellId", "spellName", "spellSchool", "amount", "overhealing", "absorbed", "critical", extra = { "info.realAmount = info.amount - info.overhealAmount", } },
	SPELL_INTERRUPT = { "spellId", "spellName", "spellSchool", "extraSpellID", "extraSpellName", "extraSchool", },
	SPELL_LEECH = { "spellId", "spellName", "spellSchool", "amount", "powerType", "extraAmount", },
	SPELL_MISSED = { "spellId", "spellName", "spellSchool", "missType", "isOffHand", "amountMissed", },
	SPELL_PERIODIC_DAMAGE = { "spellId", "spellName", "spellSchool", "amount", "overkill", "school", "resisted", "blocked", "absorbed", "critical", "glancing", "crushing", "isOffHand", },
	SPELL_PERIODIC_ENERGIZE = { "spellId", "spellName", "spellSchool", "amount", "arg2", "powerType", },
	SPELL_PERIODIC_HEAL = { "spellId", "spellName", "spellSchool", "amount", "overhealing", "absorbed", "critical", extra = { "info.realAmount = info.amount - info.overhealAmount", } },
	SPELL_PERIODIC_LEECH = { "spellId", "spellName", "spellSchool", "amount", "powerType", "extraAmount", },
	SPELL_PERIODIC_MISSED = { "spellId", "spellName", "spellSchool", "missType", "isOffHand", "amountMissed", },
	SPELL_STOLEN = { "spellId", "spellName", "spellSchool", "extraSpellID", "extraSpellName", "extraSchool", "auraType", },
	SWING_DAMAGE = { "amount", "overkill", "school", "resisted", "blocked", "absorbed", "critical", "glancing", "crushing", "isOffHand", },
	SWING_MISSED = { "missType", "isOffHand", "amountMissed", },
	SPELL_AURA_APPLIED = { "spellId", "spellName", "spellSchool", "auraType", },
	SPELL_AURA_APPLIED_DOSE = { "spellId", "spellName", "spellSchool", "auraType", "amount", },
	SPELL_AURA_REFRESH = { "spellId", "spellName", "spellSchool", "auraType", "amount", },
	SPELL_AURA_REMOVED = { "spellId", "spellName", "spellSchool", "auraType", },
	ENCHANT_APPLIED = { "spellName", "itemID", "itemName", },
	ENCHANT_REMOVED = { "spellName", "itemID", "itemName", },
}

local legacyNames = {
	absorbed = "absorbAmount",
	blocked = "blockAmount",
	resisted = "resistAmount",
	amountMissed = "amount",
	critical = "isCrit",
	crushing = "isCrushing",
	glancing = "isGlancing",
	spellId = "spellID",
	spellName = "abilityName",
	extraSpellName = "extraAbilityName",
	overhealing = "overhealAmount",
	spellSchool = "damageType",
}

local function makeParseFunction(event)
	local code = "return function(info, ...) "
	if next(moreParams[event]) then
		local paramCode = newList()
		for _,v in ipairs(moreParams[event]) do
			tinsert(paramCode, ("info.%s"):format(legacyNames[v] or v))
		end
		code = code .. tconcat(paramCode, ",") .. " = ...;"
		del(paramCode)
	end

	local extras = moreParams[event].extra
	if extras then
		code = code .. tconcat(extras, ";") .. ";"
	end

	code = code .. "end"
	local createFunc, err = loadstring(code)

	if createFunc then
		return createFunc()
	else
		geterrorhandler()(err)
	end
end
local combatLogParseFuncs = {}
for k in pairs(moreParams) do
	combatLogParseFuncs[k] = makeParseFunction(k)
end

wipe(moreParams)
moreParams = nil
makeParseFunction = nil

local FLAGS_RELEVANT = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER)
local bit_band = bit.band
local function checkForRelevance(sourceFlags, destFlags)
	return bit_band(sourceFlags, FLAGS_RELEVANT) == FLAGS_RELEVANT or
	bit_band(destFlags, FLAGS_RELEVANT) == FLAGS_RELEVANT
end

function module:HandleCombatlogEvent(uid, timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	if not self:IsEnabled() then return end -- TODO remove

	if checkForRelevance(sourceFlags, destFlags) then
		local registeredHandlers = combatLogEvents[eventType]
		if registeredHandlers then
			local info = newList()
			info.hideCaster = hideCaster
			info.sourceID = sourceGUID
			info.sourceName = sourceName or ""
			info.sourceFlags = sourceFlags
			info.recipientID = destGUID
			info.recipientName = destName or ""
			info.destFlags = destFlags
			local parseFunc = combatLogParseFuncs[eventType]
			if not parseFunc then
				debug("No parseFunc for " .. eventType)
			else
				parseFunc(info, ...)
				for i, v in ipairs(registeredHandlers) do
					-- TODO use raid-flags introduced in 4.2 here... seems dirty otherwise
					local check = v.checkfunc(sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...)
					if check and not sfiltered(info) then
						info.uid = uid
						self:TriggerCombatEvent(v.category, v.name, info)
					end
				end
			end
			info = del(info)
		end
	end
end
