local VERSION = tonumber(("$Revision: 79256 $"):match("%d+"))

local Parrot = Parrot
if Parrot.revision < VERSION then
	Parrot.version = "r" .. VERSION
	Parrot.revision = VERSION
	Parrot.date = ("$Date: 2008-07-27 16:19:08 +0200 (Sun, 27 Jul 2008) $"):match("%d%d%d%d%-%d%d%-%d%d")
end

local mod = Parrot:NewModule("TriggerConditionsData")

local onEnableFuncs = {}
function mod:OnEnable()
	for _,v in ipairs(onEnableFuncs) do
		v()
	end
end

-- local L = Parrot:L("Parrot_TriggerConditions_Data")
-- TODO make modular
local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot_TriggerConditions_Data")

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
		}
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
		}
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
		}
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
		}
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
		usage = L["<Skill name>"],
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
		usage = L["<Skill name>"],
	},
}

Parrot:RegisterSecondaryTriggerCondition {
	name = "Minimum power amount",
	localName = L["Minimum power amount"],
	defaultParam = 0.5,
	param = {
		type = 'number',
		min = 0,
		max = function()
			return UnitManaMax("player")
		end,
		step = 1,
		bigStep = function()
			return math.min(50, UnitManaMax("player")/10)
		end,
	},
	check = function(param)
		if UnitIsDeadOrGhost("player") then
			return false
		end
		return UnitMana("player") >= param
	end,
}

Parrot:RegisterSecondaryTriggerCondition {
	name = "Warrior stance",
	localName = L["Warrior stance"],
	notLocalName = L["Not in warrior stance"],
	param = {
		type = 'choice',
		choices = {
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
		type = 'choice',
		choices = {
			["Bear Form"] = GetSpellInfo(5487),
			["Aquatic Form"] = GetSpellInfo(1066),
			["Cat Form"] = GetSpellInfo(768),
			["Travel Form"] = GetSpellInfo(783),
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
			return param == "Defensive Stance"
		elseif form == 3 then
			return param == "Cat Form"
		elseif form == 4 then
			return param == "Travel Form"
			--TODO flightform
		end
		return false
	end,
}
