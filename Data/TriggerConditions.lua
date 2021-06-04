local _, ns = ...
local Parrot = ns.addon
if not Parrot then return end

local module = Parrot:NewModule("TriggerConditionsData", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Parrot")

local newList = Parrot.newList

local playerGUID = UnitGUID("player")

function module:OnEnable()
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_PET")
end

local unitChoices = {
	["player"] = _G.PLAYER,
	["target"] = _G.TARGET,
	["pet"] = _G.PET,
}

local comparatorChoices = {
	["<"] = "<",
	["<="] = "<=",
	["=="] = "==",
	[">="] = ">=",
	[">"] = ">",
	--	["~="] = "~=",
}
local friendlyChoices = {
	[1] = _G.FRIENDLY,
	[0] = _G.HOSTILE,
	[-1] = L["Any"],
}

local comparatorFunc = {
	["<"] = function(arg1, arg2) return arg1 < arg2 end,
	["<="] = function(arg1, arg2) return arg1 <= arg2 end,
	["=="] = function(arg1, arg2) return arg1 == arg2 end,
	[">="] = function(arg1, arg2) return arg1 >= arg2 end,
	[">"] = function(arg1, arg2) return arg1 > arg2 end,
	--	["~="] = function(arg1, arg2) return arg1 ~= arg2 end,
}

local function ret(arg)
	return arg
end

local function compare(val1, comparator, val2)
	return comparatorFunc[comparator](val1, val2)
end

local unitHealthStates = {
	player = {},
	target = {},
	pet = {},
}


local function parseAmount(arg)
	if not arg then
		return ""
	elseif arg <= 1 then
		return (arg*100) .. "%"
	else
		return tostring(arg)
	end
end

local function saveAmount(arg)
	if arg:match("%d+%%") then
		local percent = tonumber(arg:sub(1,arg:len()-1))
		if percent then
			return percent/100
		end
		return
	else
		return tonumber(arg)
	end
end

Parrot:RegisterPrimaryTriggerCondition {
	name = "Unit health",
	localName = L["Unit health"],
	defaultParam = {
		unit = "player",
		friendly = -1,
		amount = 0.5,
		comparator = "<=",
	},
	param = {
		type = 'group',
		args = {
			unit = {
				name = L["Unit"],
				desc = L["The unit that is affected"],
				type = 'select',
				values = unitChoices,
			},
			friendly = {
				type = 'select',
				name = L["Hostility"],
				desc = L["Whether the unit should be friendly or hostile"],
				values = friendlyChoices,
			},
			amount = {
				type = 'string',
				name = L["Amount"],
				desc = L["Amount of health to compare"],
				parse = parseAmount,
				save = saveAmount,
			},
			comparator = {
				type = 'select',
				name = L["Comparator Type"],
				desc = L["How to compare actual value with parameter"],
				values = comparatorChoices,
			},
		},
	},
	events = {
		UNIT_HEALTH = ret,
		UNIT_MAXHEALTH = ret,
		UNIT_FACTION = ret,
	},
	check = function(ref, info)
		-- check if ref is complete
		if not ref.unit or not ref.amount or not ref.friendly or not ref.comparator or ref.unit ~= info then
			return false
		end
		-- check the friendly-flag
		if ref.friendly >= 0 then
			local friendly = UnitIsFriend("player", info) and 1 or 0
			if ref.friendly ~= friendly then
				return false
			end
		end
		-- everything fits, check the amount
		local amount = ref.amount
		if amount <= 1 then
			amount = UnitHealthMax(info) * ref.amount
		end
		local good = compare(UnitHealth(info), ref.comparator, amount)
		-- check if the state has changed
		if good ~= unitHealthStates[ref.unit][ref] then
			unitHealthStates[ref.unit][ref] = good
			return good
		end
	end,
}

local powerTypeChoices = {
	[-1] = L["Any"],
	[0] = _G.MANA,
	[1] = _G.RAGE,
	[2] = _G.FOCUS,
	[3] = _G.ENERGY,
	[4] = _G.HAPPINESS,
	[5] = _G.RUNES,
	[6] = _G.RUNIC_POWER,
	[14] = _G.COMBO_POINTS,
}

local unitPowerStates = {
	player = {},
	target = {},
	pet = {},
}

--[[
-- wipe the states for units that can change when they are changed
--]]

function module:PLAYER_TARGET_CHANGED()
	wipe(unitHealthStates.target)
	wipe(unitPowerStates.target)
end

function module:UNIT_PET(_, unit)
	if unit == "player" then
		wipe(unitHealthStates.pet)
		wipe(unitPowerStates.pet)
	end
end


local function checkPower(ref)
	local powerType = ref.powerType
	if powerType == -1 then
		powerType = nil
	end
	local unit = ref.unit
	-- check the friendly-flag
	if ref.friendly >= 0 then
		local friendly = UnitIsFriend("player", unit) and 1 or 0
		if ref.friendly ~= friendly then
			return false
		end
	end
	-- everything fits, check the amount
	local amount, percent = (ref.amount):match("(%d+)(%%)")
	if percent then
		amount = UnitPowerMax(unit, powerType) * amount / 100
	else
		amount = tonumber(ref.amount)
	end
	local actualAmount = UnitPower(unit, powerType)
	return compare(actualAmount, ref.comparator, amount)
end

Parrot:RegisterPrimaryTriggerCondition {
	name = "Unit power",
	localName = L["Unit power"],
	defaultParam = {
		unit = "player",
		friendly = -1,
		amount = "50%",
		comparator = "<=",
	},
	param = {
		type = 'group',
		args = {
			unit = {
				name = L["Unit"],
				desc = L["The unit that is affected"],
				type = 'select',
				values = unitChoices,
			},
			friendly = {
				type = 'select',
				name = L["Hostility"],
				desc = L["Whether the unit should be friendly or hostile"],
				values = friendlyChoices,
			},
			amount = {
				type = 'string',
				name = L["Amount"],
				desc = L["Amount of health to compare"],
			},
			comparator = {
				type = 'select',
				name = L["Comparator Type"],
				desc = L["How to compare actual value with parameter"],
				values = comparatorChoices,
			},
			powerType = {
				type = 'select',
				name = L["Power type"],
				desc = L["Type of power"],
				values = powerTypeChoices,
			},
		},
	},
	events = {
		UNIT_POWER_UPDATE = ret,
		UNIT_MAXPOWER = ret,
	},
	check = function(ref, info)
		-- check if ref is complete
		if not ref.unit or not ref.amount or not ref.friendly or not ref.comparator or not ref.powerType or ref.unit ~= info then
			return false
		end
		local state = checkPower(ref)
		if state ~= unitPowerStates[ref.unit][ref] then
			unitPowerStates[ref.unit][ref] = state
			return state
		end
		return false
	end,
}

local missTypeChoices = {
	["ABSORB"] = _G.ABSORB,
	["BLOCK"] = _G.BLOCK,
	["DEFLECT"] = _G.DEFLECT,
	["DODGE"] = _G.DODGE,
	["EVADE"] = _G.EVADE,
	["IMMUNE"] = _G.IMMUNE,
	["MISS"] = _G.MISS,
	["PARRY"] = _G.PARRY,
	["REFLECT"] = _G.REFLECT,
	["RESIST"] = _G.RESIST,
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Incoming miss",
	localName = L["Incoming miss"],
	combatLogEvents = {
		{
			eventType = "SWING_MISSED",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType )
				if dstGUID ~= playerGUID then
					return nil
				end
				return missType
			end,
		},
		{
			eventType = "SPELL_MISSED",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, missType )
					if dstGUID ~= playerGUID then
							return nil
					end
					return missType
			end,
		},
		{
			eventType = "RANGE_MISSED",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, missType )
					if dstGUID ~= playerGUID then
							return nil
					end
					return missType
			end,
		},
	},
	param = {
		type = 'select',
		name = L["Miss type"],
		desc = L["Reason for the miss"],
		values = missTypeChoices,
	}
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Outgoing miss",
	localName = L["Outgoing miss"],
	combatLogEvents = {
		{
			eventType = "SWING_MISSED",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType )
				if srcGUID ~= playerGUID then
					return nil
				end
				return missType
			end,
		},
		{
			eventType = "SPELL_MISSED",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, missType, amountMissed )
				if srcGUID ~= playerGUID then
						return nil
				end
				return missType
			end,
		},
		{
			eventType = "RANGE_MISSED",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, missType )
					if srcGUID ~= playerGUID then
							return nil
					end
					return missType
			end,
		},
	},
	param = {
		type = 'select',
		name = L["Miss type"],
		desc = L["Reason for the miss"],
		values = missTypeChoices,
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Incoming crit",
	localName = L["Incoming crit"],
	combatLogEvents = {
		{
			eventType = "SPELL_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if dstGUID ~= playerGUID or not critical then
					return nil
				end
				return true
			end,
		},
		{
			eventType = "SWING_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if dstGUID ~= playerGUID or not critical then
					return nil
				end
				return true
			end,
		},
		{
			eventType = "RANGE_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if dstGUID ~= playerGUID or not critical then
					return nil
				end
				return true
			end,
		},
	},
	exclusive = true,
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Outgoing crit",
	localName = L["Outgoing crit"],
	combatLogEvents = {
		{
			eventType = "SPELL_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if srcGUID ~= playerGUID or not critical then
					return nil
				end
				return true
			end,
		},
		{
			eventType = "SWING_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if srcGUID ~= playerGUID or not critical then
					return nil
				end
				return true
			end,
		},
		{
			eventType = "RANGE_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if srcGUID ~= playerGUID or not critical then
					return nil
				end
				return true
			end,
		},
	},
	exclusive = true,
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Outgoing cast",
	localName = L["Outgoing cast"],
	combatLogEvents = {
		{
			eventType = "SPELL_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if srcGUID ~= playerGUID then
					return nil
				end
				return spellName
			end,
		},
		{
			eventType = "SPELL_PERIODIC_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if srcGUID ~= playerGUID then
					return nil
				end
				return spellName
			end,
		},
	},
	param = {
		type = 'string',
		-- usage = L["<Skill name>"],
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Incoming cast",
	localName = L["Incoming cast"],
	combatLogEvents = {
		{
			eventType = "SPELL_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if dstGUID ~= playerGUID then
					return nil
				end
				return spellName
			end,
		},
		{
			eventType = "SPELL_PERIODIC_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if dstGUID ~= playerGUID then
					return nil
				end
				return spellName
			end,
		},
	},
	param = {
		type = 'string',
		-- usage = L["<Skill name>"],
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Cast started",
	localName = L["Cast started"],
	combatLogEvents = {
		{
			eventType = "SPELL_CAST_START",
			triggerData = function (_, srcName, _, _, dstName, _, spellId, spellName)
				local data = newList()
				data.srcName = srcName
				data.spellName = spellName
				data.spellId = spellId
				return data
			end,
		},
	},
	defaultParam = {
		unit = "target",
		spell = "",
	},
	param = {
		type = 'group',
		args = {
			unit = {
				name = L["Unit"],
				desc = L["The unit that started the cast"],
				type = 'select',
				values = unitChoices,
			},
			spell = {
				name = L["Spell"],
				desc = L["Spell name or spell id"],
				type = 'input',
			},
		},
	},
	check = function(ref, info)
		if not ref.unit or info.srcName ~= UnitName(ref.unit) then
			return false
		end
		local spellid = tonumber(ref.spell)
		if spellid then
			return info.spellId == spellid
		else
			return info.spellName == ref.spell
		end
	end,
}

local function parseSpellDamage(_, srcName, _, _, dstName, _, spellId, spellName, _, amount, _, _, _, _, critical)
	local data = newList()
	data.dstName = dstName
	data.srcName = srcName
	data.amount = amount
	data.critical = not not critical
	data.spellName = spellName
	data.spellId = spellId
	return data
end

local function parseSwingDamage(_, srcName, _, _, dstName, _, amount, _, _, _, _, _, critical)
	local data = newList()
	data.dstName = dstName
	data.srcName = srcName
	data.amount = amount
	data.critical = not not critical
	return data
end

Parrot:RegisterPrimaryTriggerCondition {
	name = "Incoming damage",
	localName = L["Incoming damage"],
	combatLogEvents = {
		{
			eventType = "SWING_DAMAGE",
			check = function(_, _, _, dstGUID)
				return dstGUID == playerGUID
			end,
			triggerData = parseSwingDamage,
		},
		{
			eventType = "SPELL_PERIODIC_DAMAGE",
			check = function(_, _, _, dstGUID)
				return dstGUID == playerGUID
			end,
			triggerData = parseSpellDamage,
		},
		{
			eventType = "SPELL_DAMAGE",
			check = function(_, _, _, dstGUID)
				return dstGUID == playerGUID
			end,
			triggerData = parseSpellDamage,
		},
		{
			eventType = "RANGE_DAMAGE",
			check = function(_, _, _, dstGUID)
				return dstGUID == playerGUID
			end,
			triggerData = parseSpellDamage,
		},
	},
	defaultParam = {
		unit = "target",
		comparator = ">",
		amount = 0,
	},
	param = {
		type = 'group',
		args = {
			unit = {
				name = L["Unit"],
				desc = L["The unit that attacked you"],
				type = 'input',
				usage = "\"player\" or \"target\" or \"<unit name>\"", -- TODO L[]
			},
			amount = {
				name = L["Amount"],
				desc = L["Amount of damage to compare with"],
				type = 'input',
				save = function(value) return tonumber(value) end,
				parse = function(value) return tostring(value or "") end,
			},
			comparator = {
				type = 'select',
				name = L["Comparator Type"],
				desc = L["How to compare actual value with parameter"],
				values = comparatorChoices,
			},
		},
	},
	check = function(ref, info)
		if not ref.unit or not ref.amount or not ref.comparator then
			return false
		end
		if ref.unit == info.srcName or info.srcName == UnitName(ref.unit) then
			return compare(info.amount, ref.comparator, ref.amount)
		end
		return false
	end,
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Outgoing damage",
	localName = L["Outgoing damage"],
	combatLogEvents = {
		{
			eventType = "SWING_DAMAGE",
			check = function(_, _, _, dstGUID)
				return dstGUID == playerGUID
			end,
			triggerData = parseSwingDamage,
		},
		{
			eventType = "SPELL_PERIODIC_DAMAGE",
			check = function(_, _, _, dstGUID)
				return dstGUID == playerGUID
			end,
			triggerData = parseSpellDamage,
		},
		{
			eventType = "SPELL_DAMAGE",
			check = function(_, _, _, dstGUID)
				return dstGUID == playerGUID
			end,
			triggerData = parseSpellDamage,
		},
		{
			eventType = "RANGE_DAMAGE",
			check = function(_, _, _, dstGUID)
				return dstGUID == playerGUID
			end,
			triggerData = parseSpellDamage,
		},
	},
	defaultParam = {
		unit = "target",
		comparator = ">",
		amount = 0,
	},
	param = {
		type = 'group',
		args = {
			unit = {
				name = L["Unit"],
				desc = L["The unit that you attacked"],
				type = 'input',
				usage = "\"player\" or \"target\" or \"<unit name>\"", -- TODO L[]
			},
			amount = {
				name = L["Amount"],
				desc = L["Amount of damage to compare with"],
				type = 'input',
				save = function(value) return tonumber(value) end,
				parse = function(value) return tostring(value or "") end,
			},
			comparator = {
				type = 'select',
				name = L["Comparator Type"],
				desc = L["How to compare actual value with parameter"],
				values = comparatorChoices,
			},
		},
	},
	check = function(ref, info)
		if not ref.unit or not ref.amount or not ref.comparator then
			return false
		end
		if ref.unit == info.dstName or info.dstName == UnitName(ref.unit) then
			return compare(info.amount, ref.comparator, ref.amount)
		end
		return false
	end,
}

Parrot:RegisterSecondaryTriggerCondition {
	name = "Unit power",
	localName = L["Unit power"],
	defaultParam = {
		unit = "player",
		comparator = "<=",
		amount = "40%",
		friendly = -1,
	},
	param = {
		type = 'group',
		args = {
			unit = {
				name = L["Unit"],
				desc = L["The unit that is affected"],
				type = 'select',
				values = unitChoices,
			},
			friendly = {
				type = 'select',
				name = L["Hostility"],
				desc = L["Whether the unit should be friendly or hostile"],
				values = friendlyChoices,
			},
			amount = {
				type = 'string',
				name = L["Amount"],
				desc = L["Amount of power to compare"],
			},
			powerType = {
				type = 'select',
				name = L["Power type"],
				desc = L["Type of power"],
				values = powerTypeChoices,
			},
			comparator = {
				type = 'select',
				name = L["Comparator Type"],
				desc = L["How to compare actual value with parameter"],
				values = comparatorChoices,
			},
		},
	},
	check = function(ref)
		-- check if ref is complete
		if not ref.unit or not ref.amount or not ref.friendly or not ref.comparator or not ref.powerType then
			return false
		end
		return checkPower(ref)
	end,
}

Parrot:RegisterSecondaryTriggerCondition {
	name = "Unit health",
	localName = L["Unit health"],
	defaultParam = {
		unit = "player",
		comparator = "<=",
		amount = 0.5,
		friendly = -1,
	},
	param = {
		type = 'group',
		args = {
			unit = {
				name = L["Unit"],
				desc = L["The unit that is affected"],
				type = 'select',
				values = unitChoices,
			},
			friendly = {
				type = 'select',
				name = L["Hostility"],
				desc = L["Whether the unit should be friendly or hostile"],
				values = friendlyChoices,
			},
			amount = {
				type = 'string',
				name = L["Amount"],
				desc = L["Amount of health to compare"],
				save = saveAmount,
				parse = parseAmount,
			},
			comparator = {
				type = 'select',
				name = L["Comparator Type"],
				desc = L["How to compare actual value with parameter"],
				values = comparatorChoices,
			},
		},
	},
	check = function(ref)
		if not ref.unit or not ref.amount or not ref.friendly or not ref.comparator then
			return false
		end
		if ref.friendly >= 0 then
			local friendly = UnitIsFriend("player", ref.unit) and 1 or 0
			if ref.friendly ~= friendly then
				return false
			end
		end
		local amount = ref.amount
		if amount <= 1 then
			amount = UnitHealthMax(ref.unit) * ref.amount
		end
		return compare(UnitHealth(ref.unit), ref.comparator, amount)
	end,
}

Parrot:RegisterSecondaryTriggerCondition {
	name = "Druid Form",
	localName = L["Druid Form"],
	notLocalName = L["Not in Druid Form"],
	param = {
		type = 'select',
		values = {
			["Bear Form"] = GetSpellInfo(5487),
			["Cat Form"] = GetSpellInfo(768),
			["Travel Form"] = GetSpellInfo(783),
			["Moonkin Form"] = GetSpellInfo(24858),
		}
	},
	check = function(param)
		if select(2,UnitClass("player")) ~= "DRUID" then
			return true
		end

		local form = GetShapeshiftForm(true)
		if form == 1 then
			return param == "Bear Form"
		elseif form == 2 then
			return param == "Cat Form"
		elseif form == 3 then
			return param == "Travel Form"
		elseif form == 4 then
			return param == "Moonkin Form"
		end
		return false
	end,
}

Parrot:RegisterSecondaryTriggerCondition {
	name = "Grouped",
	localName = L["In a group"],
	check = function()
		return IsInGroup()
	end,
	exclusive = true,
}

Parrot:RegisterSecondaryTriggerCondition {
	name = "Mounted",
	localName = L["Mounted"],
	notLocalName = L["Not mounted"],
	check = function()
		return IsMounted()
	end,
	exclusive = true,
}

Parrot:RegisterSecondaryTriggerCondition {
	name = "InVehicle",
	localName = L["In vehicle"],
	notLocalName = L["Not in vehicle"],
	check = function()
		return UnitInVehicle("player")
	end,
	exclusive = true
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Successful spell cast",
	localName = L["Successful spell cast"],
	combatLogEvents = {
		{
			eventType = "SPELL_CAST_SUCCESS",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName )
				local info = newList()
				info.srcGUID = srcGUID
				info.spellId = spellId
				info.spellName = spellName
				return info
			end,
		},
	},
	param = {
		type = 'group',
		args = {
			unit = {
				name = L["Unit"],
				desc = L["The unit that casted the spell"],
				type = 'select',
				values = unitChoices,
			},
			friendly = {
				type = 'select',
				name = L["Hostility"],
				desc = L["Whether the unit should be friendly or hostile"],
				values = friendlyChoices,
			},
			spell = {
				name = L["Spell"],
				desc = L["Spell name or spell id"],
				type = 'input',
			},
		},
	},
	check = function(ref, info)
		if not ref.unit or not ref.friendly or not ref.spell or UnitGUID(ref.unit) ~= info.srcGUID then
			return false
		end
		if ref.friendly >= 0 then
			local friendly = UnitIsFriend("player", ref.unit) and 1 or 0
			if ref.friendly ~= friendly then
				return false
			end
		end
		local spell = tonumber(ref.spell)
		if spell then
			return info.spellId == spell
		else
			return info.spellName == ref.spell
		end
	end,
}

Parrot:RegisterSecondaryTriggerCondition {
	name = "Target is player",
	localName = L["Target is player"],
	notLocalName = L["Target is NPC"],
	check = function()
		if UnitIsDeadOrGhost("target") then
			return false
		end
		return UnitIsPlayer("target")
	end,
	exclusive = true
}


local luacache = {}

Parrot:RegisterSecondaryTriggerCondition {
	name = "Lua function",
	localName = L["Lua function"],
	defaultParam = "return true",
	param = {
		type = 'string',
		multiline = true,
		width = 'full',
	},
	check = function(param)
		local func = luacache[param]
		if not func then
			-- It's not there yet. build it+
			if type(param) ~= 'string' then
				return false
			end
			local lua_string = 'return function() '..param..' end'
			local create_func, err = loadstring(lua_string)
			if create_func then
				func = create_func()
				-- and put it in the cache
				luacache[param] = func
			else
				geterrorhandler()(err)
				return false
			end
		end
		return func()
	end,
}
