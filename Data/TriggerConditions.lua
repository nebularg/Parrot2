local Parrot = Parrot

local mod = Parrot:NewModule("TriggerConditionsData")

local L = LibStub("AceLocale-3.0"):GetLocale("Parrot_TriggerConditions_Data")

local debug = Parrot.debug

local onEnableFuncs = {}
function mod:OnEnable()
	for _,v in ipairs(onEnableFuncs) do
		v()
	end
end


Parrot:RegisterPrimaryTriggerCondition {
	name = "Enemy target health percent",
	localName = L["Enemy target health percent"],
	defaultParam = 0.5,
	param = {
		type = "number",
		min = 0,
		max = 1,
		step = 0.01,
		bigStep = 0.05,
		isPercent = true,
	},
	getCurrent = function()
		if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDeadOrGhost("target") then
			return nil
		else
		 	return UnitHealth("target")/UnitHealthMax("target")
		end
	end,
	events = {
		UNIT_HEALTH = "target",
		UNIT_MAXHEALTH = "target",
		UNIT_FACTION = "target",
		PLAYER_TARGET_CHANGED = true,
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Friendly target health percent",
	localName = L["Friendly target health percent"],
	param = {
		type = "number",
		min = 0,
		max = 1,
		step = 0.01,
		bigStep = 0.05,
		isPercent = true,
	},
	getCurrent = function()
		if not UnitExists("target") or not UnitIsFriend("player", "target") or UnitIsDeadOrGhost("target") then
			return nil
		else
			return UnitHealth("target")/UnitHealthMax("target")
		end
	end,
	events = {
		UNIT_HEALTH = "target",
		UNIT_MAXHEALTH = "target",
		UNIT_FACTION = "target",
		PLAYER_TARGET_CHANGED = true,
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Self health percent",
	localName = L["Self health percent"],
	param = {
		type = "number",
		min = 0,
		max = 1,
		step = 0.01,
		bigStep = 0.05,
		isPercent = true,
	},
	getCurrent = function()
		if UnitIsDeadOrGhost("player") then
			return nil
		else
			return UnitHealth("player")/UnitHealthMax("player")
		end
	end,
	events = {
		UNIT_HEALTH = "player",
		UNIT_MAXHEALTH = "player",
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Self mana percent",
	localName = L["Self mana percent"],
	param = {
		type = "number",
		min = 0,
		max = 1,
		step = 0.01,
		bigStep = 0.05,
		isPercent = true,
	},
	getCurrent = function()
		if UnitIsDeadOrGhost("player") or UnitPowerType("player") ~= 0 then
			return nil
		else
			return UnitMana("player")/UnitManaMax("player")
		end
	end,
	events = {
		UNIT_MANA = "player",
		UNIT_MAXMANA = "player",
		UNIT_DISPLAYPOWER = "player",
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Pet health percent",
	localName = L["Pet health percent"],
	param = {
		type = "number",
		min = 0,
		max = 1,
		step = 0.01,
		bigStep = 0.05,
		isPercent = true,
	},
	getCurrent = function()
		if not UnitExists("pet") or UnitIsDeadOrGhost("pet") then
			return nil
		end
		return UnitHealth("pet")/UnitHealthMax("pet")
	end,
	events = {
		UNIT_HEALTH = "pet",
		UNIT_MAXHEALTH = "pet",
		PLAYER_PET_CHANGED = "pet",
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Pet mana percent",
	localName = L["Pet mana percent"],
	param = {
		type = "number",
		min = 0,
		max = 1,
		step = 0.01,
		bigStep = 0.05,
		isPercent = true,
	},
	getCurrent = function()
		if not UnitExists("pet") or UnitIsDeadOrGhost("pet") then
			return nil
		end
		return UnitHealth("pet")/UnitHealthMax("pet")
	end,
	events = {
		UNIT_MANA = "pet",
		UNIT_MAXMANA = "pet",
		PLAYER_PET_CHANGED = "pet",
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Incoming Block",
	localName = L["Incoming block"],
	combatLogEvents = {
		{
			eventType = "SWING_MISSED",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType )
				if dstGUID ~= UnitGUID("player") or missType ~= "BLOCK" then
					return nil
				end

				return true
			end,
		}
	}
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Incoming crit",
	localName = L["Incoming crit"],
	combatLogEvents = {
		{
			eventType = "SPELL_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if dstGUID ~= UnitGUID("player") or not critical then
					return nil
				end

				return true

			end,
		},
		{
			eventType = "SWING_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if dstGUID ~= UnitGUID("player") or not critical then
					return nil
				end

				return true

			end,
		},
		{
			eventType = "RANGE_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if dstGUID ~= UnitGUID("player") or not critical then
					return nil
				end

				return true

			end,

		},
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Incoming Dodge",
	localName = L["Incoming dodge"],
	combatLogEvents = {
		{
			eventType = "SWING_MISSED",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType )
				if dstGUID ~= UnitGUID("player") or missType ~= "DODGE" then
					return nil
				end

				return true
			end,
		},
		{
			eventType = "SPELL_MISSED",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType )
				if dstGUID ~= UnitGUID("player") or missType ~= "DODGE" then
					return nil
				end

				return true
			end,
		},
	}
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Incoming Parry",
	localName = L["Incoming parry"],
	combatLogEvents = {
		{
			eventType = "SWING_MISSED",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType )
				if dstGUID ~= UnitGUID("player") or missType ~= "PARRY" then
					return nil
				end

				return true
			end,
		},
		{
			eventType = "SPELL_MISSED",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType )
				if dstGUID ~= UnitGUID("player") or missType ~= "PARRY" then
					return nil
				end

				return true
			end,
		}
	}
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Outgoing Block",
	localName = L["Outgoing block"],
	combatLogEvents = {
		{
			eventType = "SWING_MISSED",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType )
				if srcGUID ~= UnitGUID("player") or missType ~= "BLOCK" then
					return nil
				end
				return true
			end,
		},
		{
			eventType = "SPELL_MISSED",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType )
				if srcGUID ~= UnitGUID("player") or missType ~= "BLOCK" then
					return nil
				end
				return true
			end,
		},
	}
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Outgoing crit",
	localName = L["Outgoing crit"],
	combatLogEvents = {
		{
			eventType = "SPELL_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if srcGUID ~= UnitGUID("player") or not critical then
					return nil
				end

				return true

			end,
		},
		{
			eventType = "SWING_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if srcGUID ~= UnitGUID("player") or not critical then
					return nil
				end

				return true

			end,
		},
		{
			eventType = "RANGE_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if srcGUID ~= UnitGUID("player") or not critical then
					return nil
				end

				return true

			end,

		},
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Outgoing Dodge",
	localName = L["Outgoing dodge"],
	combatLogEvents = {
		{
			eventType = "SWING_MISSED",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType )

				if srcGUID ~= UnitGUID("player") or missType ~= "DODGE" then
					return nil
				end
				return true
			end,
		},
		{
			eventType = "SPELL_MISSED",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType )

				if srcGUID ~= UnitGUID("player") or missType ~= "DODGE" then
					return nil
				end
				return true
			end,
		},
	}
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Outgoing Parry",
	localName = L["Outgoing parry"],
	combatLogEvents = {
		{
			eventType = "SWING_MISSED",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType )

				if srcGUID ~= UnitGUID("player") or missType ~= "PARRY" then
					return nil
				end
				return true
			end,
		},
		{
			eventType = "SPELL_MISSED",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType )

				if srcGUID ~= UnitGUID("player") or missType ~= "PARRY" then
					return nil
				end
				return true
			end,
		},
	}
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Outgoing cast",
	localName = L["Outgoing cast"],
	combatLogEvents = {
		{
			eventType = "SPELL_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if srcGUID ~= UnitGUID("player") then
					return nil
				end

				return spellName

			end,

		},
		{
			eventType = "SPELL_PERIODIC_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if srcGUID ~= UnitGUID("player") then
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
				if dstGUID ~= UnitGUID("player") then
					return nil
				end

				return spellName

			end,

		},
		{
			eventType = "SPELL_PERIODIC_DAMAGE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if dstGUID ~= UnitGUID("player") then
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

local function manastep()
	return math.min(50, UnitManaMax("player")/10)
end

Parrot:RegisterSecondaryTriggerCondition {
	name = "Minimum power amount",
	localName = L["Minimum power amount"],
	defaultParam = 0.5,
	param = {
		type = 'number',
		min = 0,
		max = UnitManaMax("player"),
		step = 1,
		bigStep = manastep(),
	},
	check = function(param)
		if UnitIsDeadOrGhost("player") then
			return false
		end
		return UnitMana("player") >= param
	end,
}

Parrot:RegisterSecondaryTriggerCondition {
	name = "Minimum power percent",
	localName = L["Minimum power percent"],
	param = {
		type = 'number',
		min = 0,
		max = 1,
		step = 0.01,
		bigStep = 0.05,
		isPercent = true,
	},
	check = function(param)
		if UnitIsDeadOrGhost("player") then
			return false
		end
		return UnitMana("player")/UnitManaMax("player") >= param
	end,
}

Parrot:RegisterSecondaryTriggerCondition {
	name = "Warrior stance",
	localName = L["Warrior stance"],
	notLocalName = L["Not in warrior stance"],
	param = {
		type = 'select',
		values = {
			["Battle Stance"] = GetSpellInfo(2457),
			["Defensive Stance"] = GetSpellInfo(71),
			["Berserker Stance"] = GetSpellInfo(2458),
		}
	},
	check = function(param)
		if select(2,UnitClass("player")) ~= "WARRIOR" then
			return true
		end
		local form = GetShapeshiftForm(true)
		if form == 1 then
			return param == "Battle Stance"
		elseif form == 2 then
			return param == "Defensive Stance"
		elseif form == 3 then
			return param == "Berserker Stance"
		end
		return false
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
			["Aquatic Form"] = GetSpellInfo(1066),
			["Cat Form"] = GetSpellInfo(768),
			["Travel Form"] = GetSpellInfo(783),
			["Flight Form"] = GetSpellInfo(33943),
			["Moonkin Form"] = GetSpellInfo(24858),
			["Tree of Life"] = GetSpellInfo(33891),
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
			return param == "Aquatic Form"
		elseif form == 3 then
			return param == "Cat Form"
		elseif form == 4 then
			return param == "Travel Form"
		elseif form == 5 then
			local real5 = GetShapeshiftFormInfo(5)
			if real5 == GetSpellInfo(24858) then
				return param == "Moonkin Form"
			elseif real5 == GetSpellInfo(33891) then
				return param == "Tree of Life"
			elseif real5 == GetSpellInfo(40120) or real5 == GetSpellInfo(33943) then
				return param == "Flight Form"
			end
		elseif form == 6 then
			return param == "Flight Form"
		end
		return false
	end,
}

Parrot:RegisterSecondaryTriggerCondition {
	name = "Deathknight presence",
	--TODO experimental
	localName = L["Deathknight presence"],
	notLocalName = L["Not Deathknight presence"],
	param = {
		type = 'select',
		values = {
			["Blood Presence"] = GetSpellInfo(50475),
			["Frost Presence"] = GetSpellInfo(61261),
			["Unholy Presence"] = GetSpellInfo(55222),
		}
	},
	check = function(param)
		if select(2,UnitClass("player")) ~= "DEATHKNIGHT" then
			return true
		end
		local form = GetShapeshiftForm(false)
		if form == 1 then
			return param == "Blood Presence"
		elseif form == 2 then
			return param == "Frost Presence"
		elseif form == 3 then
			return param == "Unholy Presence"
		end
		return false
	end,
}

Parrot:RegisterSecondaryTriggerCondition {
    name = "Grouped",
    localName = L["In a Group or Raid"],
    check = function()
        if GetNumPartyMembers() > 0 or UnitInRaid("player") then
            return true
        else
            return false
        end
    end,
}

Parrot:RegisterSecondaryTriggerCondition {
    name = "Mounted",
    localName = L["Mounted"],
    notLocalName = L["Not mounted"],
    check = function()
        return IsMounted()
    end,
}

Parrot:RegisterSecondaryTriggerCondition {
    name = "InVehicle",
    localName = L["In vehicle"],
    notLocalName = L["Not in vehicle"],
    check = function()
        return UnitInVehicle("player")
    end,
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Successful spell cast",
	localName = L["Successful spell cast"],
	combatLogEvents = {
		{
			eventType = "SPELL_CAST_SUCCESS",
			triggerData = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName )
				return ("%s,%s,%s"):format(srcName or "", dstName or "", spellName or "")
			end,
		},
	},
	param = {
		type = 'string',
		usage = L["<Sourcename>,<Destinationname>,<Spellname>"],
	},
}

Parrot:RegisterSecondaryTriggerCondition {
	name = "Minimum target health",
	localName = L["Minimum target health"],
	param = {
		type = 'number',
		min = 0,
		max = 20000,
		step = 1,
		bigStep = 1000,
	},
	check = function(param)
		if UnitIsDeadOrGhost("target") then
			return false
		end
		return UnitHealth("target") >= param
	end,
}

Parrot:RegisterSecondaryTriggerCondition {
	name = "Minimum target health percent",
	localName = L["Minimum target health percent"],
	param = {
		type = 'number',
		min = 0,
		max = 1,
		step = 0.01,
		bigStep = 0.05,
		isPercent = true,
	},
	check = function(param)
		debug(UnitHealth("target") .. "HP")
		if UnitIsDeadOrGhost("target") then
			return false
		end
		return UnitHealth("target")/UnitHealthMax("target") >= param
	end,
}

Parrot:RegisterSecondaryTriggerCondition {
	name = "Maximum target health percent",
	localName = L["Maximum target health percent"],
	param = {
		type = 'number',
		min = 0,
		max = 1,
		step = 0.01,
		bigStep = 0.05,
		isPercent = true,
	},
	check = function(param)
		if UnitIsDeadOrGhost("target") then
			return false
		end
		return UnitHealth("target")/UnitHealthMax("target") <= param
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
			-- It's not there yet. build it
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

Parrot:RegisterSecondaryTriggerCondition {
	name = "Active talents",
	localName = L["Active talents"],
	defaultParam = 1,
	param = {
		type = 'select',
		values = {
			[1] = L["Primary"],
			[2] = L["Secondary"],
		},
	},
	check = function(param)
			return GetActiveTalentGroup() == param
		end,
}
