local Parrot = Parrot

local mod = Parrot:NewModule("CombatEventsData", "LibRockEvent-1.0")

local _, playerClass = _G.UnitClass("player")

local L = LibStub("AceLocale-3.0"):GetLocale("Parrot_CombatEvents_Data")

local newList, del = Rock:GetRecyclingFunctions("Parrot", "newList", "del")

local debug = Parrot.debug

local SchoolParser =
{
	[1] = "Physical",
	[2] = "Holy",
	[4] = "Fire",
	[8] = "Nature",
	[16] = "Frost",
	[20] = "FrostFire",
	[24] = "Froststorm",
	[32] = "Shadow",
	[40] = "Shadowstorm",
	[64] = "Arcane"
}

local EnvironmentalParser =
{
	["DROWNING"] = "Drowning",
	["FALLING"] = "Falling",
	["FATIGUE"] = "Fatigue",
	["FIRE"] = "Fire",
	["LAVA"] = "Lava",
	["SLIME"] = "Slime"
}

local MANA = _G.MANA
local RAGE = _G.RAGE
local FOCUS = _G.FOCUS
local ENERGY = _G.ENERGY
local HAPPINESS = _G.HAPPINESS
local RUNES = _G.RUNES
local RUNIC_POWER = _G.RUNIC_POWER

local PowerTypeParser = {
	[-2] = HEALTH,
	[0] = MANA,
	[1] = RAGE,
	[2] = FOCUS,
	[3] = ENERGY,
	[4] = HAPPINESS,
	[5] = RUNES,
	[6] = RUNIC_POWER,
}

local onEnableFuncs = {}
function mod:OnEnable()
	for _,v in ipairs(onEnableFuncs) do
		v()
	end
end

------------------------------------------------------------------------------
-- Incoming events -----------------------------------------------------------
------------------------------------------------------------------------------
local coloredDamageAmount = function(info)
	local db = Parrot:GetModule("CombatEvents").db.profile.damageTypes
	if db.color and db[info.damageType] then
		return "|cff" .. db[info.damageType] .. info.amount .. "|r"
	else
		return info.amount
	end
end

local damageTypeString = function(info)
	if info.damageType then
		return L[info.damageType]
	else
		return ""
	end

end

Parrot:RegisterFilterType("Incoming damage", L["Incoming damage"], 0)
Parrot:RegisterThrottleType("Melee damage", L["Melee damage"], 0.1, true)

local bit_bor = bit.bor
local bit_band = bit.band
local GUARDIAN_FLAGS = bit_bor(
	COMBATLOG_OBJECT_AFFILIATION_MINE,
	COMBATLOG_OBJECT_CONTROL_PLAYER,
	COMBATLOG_OBJECT_TYPE_GUARDIAN
	)

local function checkFlags(flags1, flags2)
	return (bit_band(flags1, flags2) == flags2)
end

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Melee"],
	name = "Melee damage",
	localName = L["Melee damage"],
	defaultTag = "([Name]) -[Amount]",
	combatLogEvents = {
		{
			eventType = "SWING_DAMAGE",
			check = function(_, _, _, dstGUID)
					return (dstGUID == UnitGUID("player"))
				end,
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)

				local info = {}
				info.damageType = SchoolParser[school]
				info.recipientID = dstGUID
				info.recipientName = dstName
				info.sourceID = srcGUID
				info.sourceName = srcName
				info.amount = amount
				info.overkill = overkill
				info.absorbAmount = absorbed or 0
				info.blockAmount = blocked or 0
				info.resistAmount = resisted or 0
				info.isCrit = (critical ~= nil)
				info.isCrushing = (crushing ~= nil)
				info.isGlancing = (glancing ~= nil)

				return info
			end,
		},
	},
	tagTranslations = {
		Name = "sourceName",
		Amount = coloredDamageAmount,
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy that attacked you."],
		Amount = L["The amount of damage done."],
	},
	color = "ff0000", -- red
	canCrit = true,
	filterType = { "Incoming damage", 'amount' },
	throttle = { "Melee damage", 'recipientID', { 'throttleCount', 'isCrit', function(info)
		local numNorm = info.throttleCount_isCrit_false or 0
		local numCrit = info.throttleCount_isCrit_true or 0
		info.isCrit = numCrit > 0
		if numNorm == 1 then
			if numCrit == 1 then
				return L[" (%d hit, %d crit)"]:format(1, 1)
			elseif numCrit == 0 then
				-- just one hit
				return nil
			else -- >= 2
				return L[" (%d hit, %d crits)"]:format(1, numCrit)
			end
		elseif numNorm == 0 then
			if numCrit == 1 then
				-- just one crit
				return nil
			else -- >= 2
				return L[" (%d crits)"]:format(numCrit)
			end
		else -- >= 2
			if numCrit == 1 then
				return L[" (%d hits, %d crit)"]:format(numNorm, 1)
			elseif numCrit == 0 then
				-- just one hit
				return L[" (%d hits)"]:format(numNorm)
			else -- >= 2
				return L[" (%d hits, %d crits)"]:format(numNorm, numCrit)
			end
		end
	end }, sourceName = L["Multiple"] },
}

Parrot:RegisterThrottleType("Avoids", L["Avoids"], 1.0, true)

local missThrottleFunc = function(info)
		local num = info.throttleCount or 0
		if num > 1 then
			return (" (%dx)"):format(num)
		else
			return ""
		end
	end

local missThrottle = {
	 "Avoids",
	 'missType',
	 { 'throttleCount', missThrottleFunc, },
	 sourceName = L["Multiple"],
}

local parseMissInfo = function( srcGUID, srcName, _, dstGUID, dstName, _, missType, amountMissed )

	local info = newList()
	info.recipientID = dstGUID
	info.recipientName = dstName
	info.sourceID = srcGUID
	info.sourceName = srcName
	info.missType = missType
	info.amount = amountMissed
	return info

end

local missTagTranslations = {
	Name = "sourceName",
	Amount = "amount",
}

local incMissTagTranslationHelp = {
	Name = L["The name of the enemy that attacked you."],
	Amount = L["Amount of the damage that was missed."],
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Melee"],
	name = "Melee misses",
	localName = L["Melee misses"],
	defaultTag = MISS .. "!",
	combatLogEvents = {
		{
			eventType = "SWING_MISSED",
			check = function( _, _, _, dstGUID, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "MISS")
				end,
			func = parseMissInfo,
		},
	},
	tagTranslations = missTagTranslations,
	tagTranslationsHelp = incMissTagTranslationHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Melee"],
	name = "Melee dodges",
	localName = L["Melee dodges"],
	defaultTag = DODGE .. "!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		check = function( _, _, _, dstGUID, _, _, missType)
				return (dstGUID == UnitGUID("player") and missType == "DODGE")
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = missTagTranslations,
	tagTranslationsHelp = incMissTagTranslationHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Melee"],
	name = "Melee parries",
	localName = L["Melee parries"],
	defaultTag = PARRY .. "!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		check = function( _, _, _, dstGUID, _, _, missType)
				return (dstGUID == UnitGUID("player") and missType == "PARRY")
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = missTagTranslations,
	tagTranslationsHelp = incMissTagTranslationHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Melee"],
	name = "Melee blocks",
	localName = L["Melee blocks"],
	defaultTag = BLOCK .. "!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		check = function( _, _, _, dstGUID, _, _, missType)
				return (dstGUID == UnitGUID("player") and missType == "BLOCK")
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = missTagTranslations,
	tagTranslationsHelp = incMissTagTranslationHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Melee"],
	name = "Melee absorbs",
	localName = L["Melee absorbs"],
	defaultTag = ABSORB .. " [Amount]!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		check = function( _, _, _, dstGUID, _, _, missType)
				return (dstGUID == UnitGUID("player") and missType == "ABSORB")
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = missTagTranslations,
	tagTranslationsHelp = incMissTagTranslationHelp,
	throttle = missThrottle,
	color = "ffff00", -- yellow
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Melee"],
	name = "Melee immunes",
	localName = L["Melee immunes"],
	defaultTag = IMMUNE .. "!",
	combatLogEvents = {
		{
			eventType = "SWING_MISSED",
			check = function( _, _, _, dstGUID, _, _, missType)
				return (dstGUID == UnitGUID("player") and missType == "IMMUNE")
			end,
			func = parseMissInfo,
		},
	},
	tagTranslations = missTagTranslations,
	tagTranslationsHelp = incMissTagTranslationHelp,
	throttle = missThrottle,
	color = "ffff00", -- yellow
}

local function retrieveAbilityName(info)
	return Parrot:GetModule("CombatEvents"):GetAbbreviatedSpell(info.abilityName)
end

local function retrieveExtraAbilityName(info)
	return Parrot:GetModule("CombatEvents"):GetAbbreviatedSpell(info.extraAbilityName)
end


-- this table is needed because some spells emit Spellids
-- to the combatlog that have wrong icons
-- maps the spellid emitted by the comabat log to the spellID from the spell with the icon
local dumbIconOverride = {
	[31818] = select(3, GetSpellInfo(27222)), -- Life Tap
	[22482] = select(3, GetSpellInfo(13877)), -- Blade Flurry
	[48665] = select(3, GetSpellInfo(34411)), -- Mutilate
	[48664] = select(3, GetSpellInfo(34411)), -- Mutilate
}

local function retrieveIconFromAbilityName(info)

	local icon

	if(info.spellID) then
		icon = dumbIconOverride[info.spellID] or select(3, GetSpellInfo(info.spellID))
	elseif info.abilityName then
		--shouldn't be needed though, but to be sure
		icon = select(3, GetSpellInfo(info.abilityName))
	end

	return icon
end


Parrot:RegisterThrottleType("Skill damage", L["Skill damage"], 0.1, true)

local skillThrottleFunc = function(info)
		local numNorm = info.throttleCount_isCrit_false or 0
		local numCrit = info.throttleCount_isCrit_true or 0
		info.isCrit = numCrit > 0
		if numNorm == 1 then
			if numCrit == 1 then
				return L[" (%d hit, %d crit)"]:format(1, 1)
			elseif numCrit == 0 then
				-- just one hit
				return nil
			else -- >= 2
				return L[" (%d hit, %d crits)"]:format(1, numCrit)
			end
		elseif numNorm == 0 then
			if numCrit == 1 then
				-- just one crit
				return nil
			else -- >= 2O
				return L[" (%d crits)"]:format(numCrit)
			end
		else -- >= 2
			if numCrit == 1 then
				return L[" (%d hits, %d crit)"]:format(numNorm, 1)
			elseif numCrit == 0 then
				-- just one hit
				return L[" (%d hits)"]:format(numNorm)
			else -- >= 2
				return L[" (%d hits, %d crits)"]:format(numNorm, numCrit)
			end
		end
	end

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Skills"],
	name = "Reactive skills",
	localName = L["Reactive skills"],
	defaultTag = "([Name]) -[Amount]",
	combatLogEvents = {
		{
			eventType = "DAMAGE_SHIELD",
			check = function( _, _, _, dstGUID)
				return (dstGUID == UnitGUID("player"))
			end,
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)

			local info = newList()
			info.spellID = spellId
			info.damageType = SchoolParser[school] or SchoolParser[spellSchool]
			info.sourceName = srcName
			info.abilityName = spellName
			info.absorbAmount = absorbed or 0
			info.blockAmount = blocked or 0
			info.resistAmount = resisted or 0
			info.amount = amount
			info.overkill = overkill
			info.isCrit = (critical ~= nil)
			info.isCrushing = (crushing ~= nil)
			info.isGlancing = (glancing ~= nil)


			return info
		end,
		},
	},
	tagTranslations = {
		Name = "sourceName",
		Amount = coloredDamageAmount,
		Type = damageTypeString,
		Skill = retrieveAbilityName,
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy that attacked you."],
		Amount = L["The amount of damage done."],
		Type = L["The type of damage done."],
		Skill = L["The spell or ability that the enemy attacked you with."],
	},
	color = "ff0000", -- red
	canCrit = true,
	throttle = { "Skill damage", 'abilityName', { 'throttleCount', 'isCrit', skillThrottleFunc}, sourceName = L["Multiple"] },
	filterType = { "Incoming damage", 'amount' },

}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Skills"],
	name = "Skill damage",
	localName = L["Skill damage"],
	defaultTag = "([Name]) -[Amount]",
	combatLogEvents = {
		{
		eventType = "SPELL_DAMAGE",
		check = function( _, _, _, dstGUID)
				return (dstGUID == UnitGUID("player"))
			end,
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)

			local info = newList()
			info.spellID = spellId
			info.damageType = SchoolParser[school] or SchoolParser[spellSchool]
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceName = srcName
			info.sourceID = srcGUID
			info.abilityName = spellName
			info.absorbAmount = absorbed or 0
			info.blockAmount = blocked or 0
			info.resistAmount = resisted or 0
			info.amount = amount
			info.overkill = overkill
			info.isCrit = (critical ~= nil)
			info.isCrushing = (crushing ~= nil)
			info.isGlancing = (glancing ~= nil)

			return info
		end,
		},
		{
			eventType = "RANGE_DAMAGE",
			check = function( _, _, _, dstGUID)
				return (dstGUID == UnitGUID("player"))
			end,
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)

			local info = newList()
			info.spellID = spellId
			info.damageType = SchoolParser[school] or SchoolParser[spellSchool]
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceName = srcName
			info.sourceID = srcGUID
			info.abilityName = spellName
			info.absorbAmount = absorbed or 0
			info.blockAmount = blocked or 0
			info.resistAmount = resisted or 0
			info.amount = amount
			info.overkill = overkill
			info.isCrit = (critical ~= nil)
			info.isCrushing = (crushing ~= nil)
			info.isGlancing = (glancing ~= nil)


			return info
			end,
		},
		{
			eventType = "DAMAGE_SPLIT",
			check = function( _, _, _, dstGUID)
				return (dstGUID == UnitGUID("player"))
			end,
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)

			local info = newList()
			info.spellID = spellId
			info.damageType = SchoolParser[school] or SchoolParser[spellSchool]
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceName = srcName
			info.sourceID = srcGUID
			info.abilityName = spellName
			info.absorbAmount = absorbed or 0
			info.blockAmount = blocked or 0
			info.resistAmount = resisted or 0
			info.amount = amount
			info.overkill = overkill
			info.isCrit = (critical ~= nil)
			info.isCrushing = (crushing ~= nil)
			info.isGlancing = (glancing ~= nil)

			return info
			end,
		}
	},
	tagTranslations = {
		Name = "sourceName",
		Amount = coloredDamageAmount,
		Type = damageTypeString,
		Skill = retrieveAbilityName,
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy that attacked you."],
		Amount = L["The amount of damage done."],
		Type = L["The type of damage done."],
		Skill = L["The spell or ability that the enemy attacked you with."],
	},
	color = "ff0000", -- red
	canCrit = true,
	throttle = { "Skill damage", 'abilityName', { 'throttleCount', 'isCrit', skillThrottleFunc }, sourceName = L["Multiple"] },
	filterType = { "Incoming damage", 'amount' },
}

Parrot:RegisterThrottleType("DoTs and HoTs", L["DoTs and HoTs"], 2)

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Skills"],
	name = "Skill DoTs",
	localName = L["Skill DoTs"],
	defaultTag = "([Name]) -[Amount]",
	canCrit = true,
	combatLogEvents = {
		{
		eventType = "SPELL_PERIODIC_DAMAGE",
		check = function( _, _, _, dstGUID)
				return (dstGUID == UnitGUID("player"))
			end,
		func = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing )

			local info = newList()
			info.spellID = spellId
			info.damageType = SchoolParser[spellSchool]
			info.recipientID = dstGUID
			info.recipientName = dstName
			-- Shadowword: Death feedback damage workaround
			if( spellId == 32409 and srcName == nil ) then
				info.sourceName = dstName
			else
				info.sourceName = srcName
			end
			info.sourceID = srcGUID
			info.abilityName = spellName
			info.amount = amount + (extraAmount or 0)
			info.overkill = overkill
			info.isCrit = (critical ~= nil)
			info.isCrushing = (crushing ~= nil)
			info.isGlancing = (glancing ~= nil)
			info.absorbed = absorbed
			info.resisted = resisted
			info.blocked = blocked


			return info
		end,
		},
	},
	tagTranslations = {
		Name = "sourceName",
		Amount = coloredDamageAmount,
		Type = damageTypeString,
		Skill = retrieveAbilityName,
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy that attacked you."],
		Amount = L["The amount of damage done."],
		Type = L["The type of damage done."],
		Skill = L["The spell or ability that the enemy attacked you with."],
	},
	color = "ff0000", -- red
	throttle = { "DoTs and HoTs", 'abilityName', { 'throttleCount', 'isCrit', skillThrottleFunc }, sourceName = L["Multiple"] },
}

local parseSpellMissInfo = function(srcGUID, srcName, srcFlags, dstGUID,
	dstName, dstFlags, spellId, spellName, spellSchool, missType, amountMissed)

	local info = newList()
	info.spellID = spellId
	info.recipientID = dstGUID
	info.recipientName = dstName
	info.sourceID = srcGUID
	info.sourceName = srcName
	info.abilityName = spellName
	info.missType = missType
	info.amount = amountMissed

	return info
end

local spellMissTagTranslations = {
	Name = "sourceName",
	Skill = retrieveAbilityName,
	Icon = retrieveIconFromAbilityName,
	Amount = "amount",
}

local spellMissTagTranslationsHelp = {
	Name = L["The name of the enemy that attacked you."],
	Skill = L["The spell or ability that the enemy attacked you with."],
	Amount = L["Amount of the damage that was missed."],
},

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Skills"],
	name = "Ability misses",
	localName = L["Ability misses"],
	defaultTag = "([Skill]) " .. MISS .. "!",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
				return (dstGUID == UnitGUID("player") and missType == "MISS")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
				return (dstGUID == UnitGUID("player") and missType == "MISS")
			end,
		func = parseSpellMissInfo,
		},
		{
			eventType = "RANGE_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "MISS")
				end,
			func = parseSpellMissInfo,
		},
	},
	tagTranslations = spellMissTagTranslations,
	tagTranslationsHelp = spellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Skills"],
	name = "Ability dodges",
	localName = L["Ability dodges"],
	defaultTag = "([Skill]) " .. DODGE .. "!",
	combatLogEvents = {
		{
			eventType = "SPELL_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "DODGE")
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "SPELL_PERIODIC_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "DODGE")
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "RANGE_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "DODGE")
				end,
			func = parseSpellMissInfo,
		},
	},
	tagTranslations = spellMissTagTranslations,
	tagTranslationsHelp = spellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Skills"],
	name = "Ability parries",
	localName = L["Ability parries"],
	defaultTag = "([Skill]) " .. PARRY .. "!",
	combatLogEvents = {
		{
			eventType = "SPELL_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "PARRY")
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "SPELL_PERIODIC_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "PARRY")
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "RANGE_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "PARRY")
				end,
			func = parseSpellMissInfo,
		},
	},
	tagTranslations = spellMissTagTranslations,
	tagTranslationsHelp = spellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Skills"],
	name = "Ability blocks",
	localName = L["Ability blocks"],
	defaultTag = "([Skill]) " .. BLOCK .. "!",
	combatLogEvents = {
		{
			eventType = "SPELL_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "BLOCK")
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "SPELL_PERIODIC_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "BLOCK")
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "RANGE_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "BLOCK")
				end,
			func = parseSpellMissInfo,
		},
	},
	tagTranslations = spellMissTagTranslations,
	tagTranslationsHelp = spellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Skills"],
	name = "Spell resists",
	localName = L["Spell resists"],
	defaultTag = "([Skill]) " .. RESIST .. "!",
	combatLogEvents = {
		{
			eventType = "SPELL_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "RESIST")
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "SPELL_PERIODIC_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "RESIST")
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "RANGE_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "RESIST")
				end,
			func = parseSpellMissInfo,
		},
	},
	tagTranslations = spellMissTagTranslations,
	tagTranslationsHelp = spellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "7f007f", -- purple
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Skills"],
	name = "Skill absorbs",
	localName = L["Skill absorbs"],
	defaultTag = "([Skill]) " .. ABSORB .. " [Amount]!",
	combatLogEvents = {
		{
			eventType = "SPELL_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "ABSORB")
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "RANGE_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "ABSORB")
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "SPELL_PERIODIC_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "ABSORB")
				end,
			func = parseSpellMissInfo,
		},
	},
	tagTranslations = spellMissTagTranslations,
	tagTranslationsHelp = spellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "ffff00", -- yellow
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Skills"],
	name = "Skill immunes",
	localName = L["Skill immunes"],
	defaultTag = "([Skill]) " .. IMMUNE .. "!",
	combatLogEvents = {
		{
			eventType = "SPELL_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "IMMUNE")
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "RANGE_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "IMMUNE")
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "SPELL_PERIODIC_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "IMMUNE")
				end,
			func = parseSpellMissInfo,
		},
	},
	tagTranslations = spellMissTagTranslations,
	tagTranslationsHelp = spellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "ffff00", -- yellow
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Skills"],
	name = "Skill reflects",
	localName = L["Skill reflects"],
	defaultTag = "([Skill]) " .. REFLECT .. "!",
	combatLogEvents = {
		{
			eventType = "SPELL_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "REFLECT")
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "RANGE_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "REFLECT")
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "SPELL_PERIODIC_MISSED",
			check = function( _, _, _, dstGUID, _, _,_, _, _, missType)
					return (dstGUID == UnitGUID("player") and missType == "REFLECT")
				end,
			func = parseSpellMissInfo,
		},
	},
	tagTranslations = spellMissTagTranslations,
	tagTranslationsHelp = spellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "7f007f", -- purple
--	canCrit = true,
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Skills"],
	name = "Skill interrupts",
	localName = L["Skill interrupts"],
	defaultTag = "([Skill]) " .. INTERRUPT .. "! {[ExtraSkill]}",
	combatLogEvents = {
		{
		eventType = "SPELL_INTERRUPT",
		check = function( _, _, _, dstGUID)
					return (dstGUID == UnitGUID("player"))
				end,
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, extraSpellId, extraSpellName, extraSpellSchool)

			local info = newList()
			info.spellID = spellId
			info.extraSpellID = extraSpellId
			info.damageType = SchoolParser[spellSchool]
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceName = srcName
			info.sourceID = srcGUID
			info.abilityName = spellName
			info.extraAbilityName = extraSpellName

			return info
		end,
		},
	},
	tagTranslations = {
		Name = "sourceName",
		Skill = retrieveAbilityName,
		ExtraSkill = retrieveExtraAbilityName,
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy that attacked you."],
		Skill = L["The spell or ability that the enemy attacked you with."],
		ExtraSkill = L["Skill you were interrupted in casting"]
	},
	color = "ffff00", -- yellow
}

Parrot:RegisterFilterType("Incoming heals", L["Incoming heals"], 0)
Parrot:RegisterThrottleType("Heals", L["Heals"], 0.1, true)

local healThrottleFunc = function(info)
		local numNorm = info.throttleCount_isCrit_false or 0
		local numCrit = info.throttleCount_isCrit_true or 0
		info.isCrit = numCrit > 0
		if numNorm == 1 then
			if numCrit == 1 then
				return L[" (%d heal, %d crit)"]:format(1, 1)
			elseif numCrit == 0 then
				-- just one hit
				return nil
			else -- >= 2
				return L[" (%d heal, %d crits)"]:format(1, numCrit)
			end
		elseif numNorm == 0 then
			if numCrit == 1 then
				-- just one crit
				return nil
			else -- >= 2
				return L[" (%d crits)"]:format(numCrit)
			end
		else -- >= 2
			if numCrit == 1 then
				return L[" (%d heals, %d crit)"]:format(numNorm, 1)
			elseif numCrit == 0 then
				-- just one hit
				return L[" (%d heals)"]:format(numNorm)
			else -- >= 2
				return L[" (%d heals, %d crits)"]:format(numNorm, numCrit)
			end
		end
	end

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Heals"],
	name = "Heals",
	localName = L["Heals"],
	defaultTag = "([Skill] - [Name]) +[Amount]",
	combatLogEvents = {
		{
		eventType = "SPELL_HEAL",
		check = function(srcGUID, _, _, dstGUID)
					return (dstGUID == UnitGUID("player") and srcGUID ~= UnitGUID("player") and srcGUID ~= UnitGUID("pet"))
				end,
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags,spellId, spellName, spellSchool, amount, overheal, critical)

			local info = newList()
			info.damageType = SchoolParser[school]
			info.spellID = spellId
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName
			info.amount = amount
			info.realAmount = amount-overheal
			info.abilityName = spellName
			info.isCrit = (critical ~= nil)

			info.isHoT = false
			info.overhealAmount = overheal

			return info

		end,
		},
	},
	tagTranslations = {
		Name = "sourceName",
		Skill = retrieveAbilityName,
		Amount = "realAmount",
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the ally that healed you."],
		Skill = L["The spell or ability that the ally healed you with."],
		Amount = L["The amount of healing done."],
	},
	color = "00ff00", -- green
	canCrit = true,
	filterType = { "Incoming heals", 'realAmount' },
	throttle = { "Heals", 'abilityName', { 'throttleCount', 'isCrit', healThrottleFunc}, sourceName = L["Multiple"] },
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Heals"],
	name = "Self heals",
	localName = L["Self heals"],
	defaultTag = "([Skill]) +[Amount]",
	combatLogEvents = {
		{
		eventType = "SPELL_HEAL",
		check = function(srcGUID, _, _, dstGUID)
				return (dstGUID == UnitGUID("player") and srcGUID == UnitGUID("player"))
			end,
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags,spellId, spellName, spellSchool, amount, overheal, critical)

			local info = newList()
			info.damageType = SchoolParser[school]
			info.spellID = spellId
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName
			info.amount = amount
			info.realAmount = amount-overheal
			info.abilityName = spellName
			info.isCrit = (critical ~= nil)

			info.isHoT = false
			info.overhealAmount = overheal

			return info

		end,
		},
	},
	tagTranslations = {
		Name = "sourceName",
		Skill = retrieveAbilityName,
		Amount = "realAmount",
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the ally that healed you."],
		Skill = L["The spell or ability that the ally healed you with."],
		Amount = L["The amount of healing done."],
	},
	color = "00ff00", -- green
	canCrit = true,
	filterType = { "Incoming heals", 'realAmount' },
	throttle = { "Heals", 'abilityName', { 'throttleCount', 'isCrit', healThrottleFunc }, sourceName = L["Multiple"] },
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Heals"],
	name = "Heals over time",
	localName = L["Heals over time"],
	defaultTag = "([Skill] - [Name]) +[Amount]",
	canCrit = true,
	combatLogEvents = {
		{
		eventType = "SPELL_PERIODIC_HEAL",
		check = function(srcGUID, _, _, dstGUID)
					return (dstGUID == UnitGUID("player") and srcGUID ~= UnitGUID("player") and srcGUID ~= UnitGUID("pet"))
				end,
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags,spellId, spellName, spellSchool, amount, overheal, critical)

			local info = newList()
			info.damageType = SchoolParser[school]
			info.spellID = spellId
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName
			info.amount = amount
			info.realAmount = amount-overheal
			info.abilityName = spellName
			info.isCrit = (critical ~= nil)

			info.isHoT = true
			info.overhealAmount = overheal

			return info
		end,
		},
	},
	tagTranslations = {
		Name = "sourceName",
		Skill = retrieveAbilityName,
		Amount = "realAmount",
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the ally that healed you."],
		Skill = L["The spell or ability that the ally healed you with."],
		Amount = L["The amount of healing done."],
	},
	throttle = { "DoTs and HoTs", 'abilityName', { 'throttleCount', 'isCrit', healThrottleFunc}, sourceName = L["Multiple"] },
	color = "00ff00", -- green
	filterType = { "Incoming heals", 'realAmount' },
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Heals"],
	name = "Self heals over time",
	localName = L["Self heals over time"],
	defaultTag = "([Skill]) +[Amount]",
	canCrit = true,
	combatLogEvents = {
		{
		eventType = "SPELL_PERIODIC_HEAL",
		check = function(srcGUID, _, _, dstGUID)
					return (dstGUID == UnitGUID("player") and srcGUID == UnitGUID("player"))
				end,
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags,spellId, spellName, spellSchool, amount, overheal, critical)

			local info = newList()
			info.damageType = SchoolParser[school]
			info.spellID = spellId
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName
			info.amount = amount
			info.realAmount = amount-overheal
			info.abilityName = spellName
			info.isCrit = (critical ~= nil)

			info.isHoT = true
			info.overhealAmount = overheal

			return info

		end,
		},
	},
	tagTranslations = {
		Name = "sourceName",
		Skill = retrieveAbilityName,
		Amount = "realAmount",
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the ally that healed you."],
		Skill = L["The spell or ability that the ally healed you with."],
		Amount = L["The amount of healing done."],
	},
	throttle = { "DoTs and HoTs", 'abilityName', { 'throttleCount', 'isCrit', healThrottleFunc }, sourceName = L["Multiple"] },
	color = "00ff00", -- green
	filterType = { "Incoming heals", 'realAmount' },
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	name = "Environmental damage",
	localName = L["Environmental damage"],
	defaultTag = "-[Amount] [Type]",
	combatLogEvents = {
		{
		eventType = "ENVIRONMENTAL_DAMAGE",
		check = function(_, _, _, dstGUID)
					return (dstGUID == UnitGUID("player"))
				end,
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, enviromentalType, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)

			local info = newList()
			info.damageType = SchoolParser[school]
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName
			info.absorbAmount = absorbed or 0
			info.blockAmount = blocked or 0
			info.resistAmount = resisted or 0
			info.hazardTypeLocal = EnvironmentalParser[enviromentalType]
			info.amount = amount
			info.overkill = overkill
			info.isCrit = (critical ~= nil)
			info.isCrushing = (crushing ~= nil)
			info.isGlancing = (glancing ~= nil)


			return info
		end,
		},
	},
	tagTranslations = {
		Amount = coloredDamageAmount,
		Type = "hazardTypeLocal",
	},
	tagTranslationsHelp = {
		Amount = L["The amount of damage done."],
		Type = L["The type of damage done."],
	},
	color = "ff0000", -- red
}

-------------------------------------------------------------------------------
--incoming Pet events----------------------------------------------------------
-------------------------------------------------------------------------------

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet melee"],
	name = "Pet melee damage",
	localName = L["Pet melee damage"],
	defaultTag = PET .. " -[Amount]",
	combatLogEvents = {
		{
		eventType = "SWING_DAMAGE",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags)
				if checkFlags(dstFlags, GUARDIAN_FLAGS) then
					return Parrot.db.profile.totemDamage
				elseif dstGUID == UnitGUID("pet") then
					return true
				else
					return false
				end
			end,
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)

			local info = {}
			info.damageType = SchoolParser[school]
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName
			info.amount = amount
			info.overkill = overkill
			info.absorbAmount = absorbed or 0
			info.blockAmount = blocked or 0
			info.resistAmount = resisted or 0
			info.isCrit = (critical ~= nil)
			info.isCrushing = (crushing ~= nil)
			info.isGlancing = (glancing ~= nil)


			return info
		end,
		},
	},
	tagTranslations = {
		Name = "sourceName",
		Amount = coloredDamageAmount,
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy that attacked your pet."],
		Amount = L["The amount of damage done."],
	},
	color = "ff0000", -- red
	canCrit = true,
	filterType = { "Incoming damage", 'amount' },
	throttle = { "Melee damage", 'recipientID', { 'throttleCount', 'isCrit', function(info)
		local numNorm = info.throttleCount_isCrit_false or 0
		local numCrit = info.throttleCount_isCrit_true or 0
		info.isCrit = numCrit > 0
		if numNorm == 1 then
			if numCrit == 1 then
				return L[" (%d hit, %d crit)"]:format(1, 1)
			elseif numCrit == 0 then
				-- just one hit
				return nil
			else -- >= 2
				return L[" (%d hit, %d crits)"]:format(1, numCrit)
			end
		elseif numNorm == 0 then
			if numCrit == 1 then
				-- just one crit
				return nil
			else -- >= 2
				return L[" (%d crits)"]:format(numCrit)
			end
		else -- >= 2
			if numCrit == 1 then
				return L[" (%d hits, %d crit)"]:format(numNorm, 1)
			elseif numCrit == 0 then
				-- just one hit
				return L[" (%d hits)"]:format(numNorm)
			else -- >= 2
				return L[" (%d hits, %d crits)"]:format(numNorm, numCrit)
			end
		end
	end }, sourceName = L["Multiple"] },
}

petIncMissTagTranslationsHelp = {
	Name = L["The name of the enemy that attacked your pet."],
	Amount = L["Amount of the damage that was missed."],
},

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet melee"],
	name = "Pet melee misses",
	localName = L["Pet melee misses"],
	defaultTag = PET .. " " .. MISS .. "!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "MISS" then
					if dstGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = missTagTranslations,
	tagTranslationsHelp = petIncMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet melee"],
	name = "Pet melee dodges",
	localName = L["Pet melee dodges"],
	defaultTag = PET .. " " .. DODGE .. "!",
		combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "DODGE" then
					if dstGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = missTagTranslations,
	tagTranslationsHelp = petIncMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet melee"],
	name = "Pet melee parries",
	localName = L["Pet melee parries"],
	defaultTag = PET .. " " .. PARRY .. "!",
		combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "PARRY" then
					if dstGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
			func = parseMissInfo,
		},
	},
	tagTranslations = missTagTranslations,
	tagTranslationsHelp = petIncMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet melee"],
	name = "Pet melee blocks",
	localName = L["Pet melee blocks"],
	defaultTag = PET .. " " .. BLOCK .. "!",
		combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "BLOCK" then
					if dstGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = missTagTranslations,
	tagTranslationsHelp = petIncMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet melee"],
	name = "Pet melee absorbs",
	localName = L["Pet melee absorbs"],
	defaultTag = PET .. " " .. ABSORB .. " [Amount]!",
		combatLogEvents = {
		{
			eventType = "SWING_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "ABSORB" then
					if dstGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
			func = parseMissInfo,
		},
	},
	tagTranslations = missTagTranslations,
	tagTranslationsHelp = petIncMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "ffff00", -- yellow
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet melee"],
	name = "Pet melee immunes",
	localName = L["Pet melee immunes"],
	defaultTag = PET .. " " .. IMMUNE .. "!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "IMMUNE" then
					if dstGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = missTagTranslations,
	tagTranslationsHelp = petIncMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "ffff00", -- yellow
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet skills"],
	name = "Pet skill damage",
	localName = L["Pet skill damage"],
	defaultTag = PET .. " -[Amount]",
	combatLogEvents = {
		{
		eventType = "SPELL_DAMAGE",
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)

			if checkFlags(dstFlags, GUARDIAN_FLAGS) then
				if not Parrot.db.profile.totemDamage then
					return nil
				end
			elseif dstGUID ~= (UnitGUID("pet") or 0) then
				return nil
			end

			local info = newList()
			info.spellID = spellId
			info.damageType = SchoolParser[school] or SchoolParser[spellSchool]
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceName = srcName
			info.sourceID = srcGUID
			info.abilityName = spellName
			info.absorbAmount = absorbed or 0
			info.blockAmount = blocked or 0
			info.resistAmount = resisted or 0
			info.amount = amount
			info.overkill = overkill
			info.isCrit = (critical ~= nil)
			info.isCrushing = (crushing ~= nil)
			info.isGlancing = (glancing ~= nil)



			return info
		end,
		},
	},
	tagTranslations = {
		Name = "sourceName",
		Amount = coloredDamageAmount,
		Type = damageTypeString,
		Skill = retrieveAbilityName,
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy that attacked your pet."],
		Amount = L["The amount of damage done."],
		Type = L["The type of damage done."],
		Skill = L["The spell or ability that the enemy attacked your pet with."],
	},
	color = "ff0000", -- red
	canCrit = true,
	throttle = { "Skill damage", 'abilityName', { 'throttleCount', 'isCrit', skillThrottleFunc }, sourceName = L["Multiple"] },
	filterType = { "Incoming damage", 'amount' },
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet skills"],
	name = "Pet skill DoTs",
	localName = L["Pet skill DoTs"],
	defaultTag = PET .. " -[Amount]",
	canCrit = true,
	combatLogEvents = {
		{
		eventType = "SPELL_PERIODIC_DAMAGE",
		func = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing )
			if checkFlags(dstFlags, GUARDIAN_FLAGS) then
				if not Parrot.db.profile.totemDamage then
					return nil
				end
			elseif dstGUID ~= UnitGUID("pet") then
				return nil
			end

			local info = newList()
			info.spellID = spellId
			info.damageType = SchoolParser[spellSchool]
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceName = srcName
			info.sourceID = srcGUID
			info.abilityName = spellName
			info.amount = amount + (extraAmount or 0)
			info.overkill = overkill
			info.absorbed = absorbed
			info.resisted = resisted
			info.blocked = blocked
			info.isCrit = (critical ~= nil)
			info.isCrushing = (crushing ~= nil)
			info.isGlancing = (glancing ~= nil)

			return info
		end,
		},
	},
	tagTranslations = {
		Name = "sourceName",
		Amount = coloredDamageAmount,
		Type = damageTypeString,
		Skill = retrieveAbilityName,
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy that attacked your pet."],
		Amount = L["The amount of damage done."],
		Type = L["The type of damage done."],
		Skill = L["The spell or ability that the enemy attacked your pet with."],
	},
	color = "ff0000", -- red
	throttle = { "DoTs and HoTs", 'abilityName', { 'throttleCount', 'isCrit', skillThrottleFunc }, sourceName = L["Multiple"] },
}

local incPetSpellMissTagTranslationsHelp = {
	Name = L["The name of the enemy that attacked you."],
	Skill = L["The spell or ability that the enemy attacked you with."],
	Amount = L["Amount of the damage that was missed."],
},

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet skills"],
	name = "Pet ability misses",
	localName = L["Pet ability misses"],
	defaultTag = PET .. " " .. MISS .. "! ([Skill])",
	combatLogEvents = {
		{
			eventType = "SPELL_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "MISS" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "SPELL_PERIODIC_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "MISS" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "RANGE_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "MISS" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
	},
	tagTranslations = spellMissTagTranslations,
	tagTranslationsHelp = incPetSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet skills"],
	name = "Pet ability dodges",
	localName = L["Pet ability dodges"],
	defaultTag = PET .. " " .. DODGE .. "! ([Skill])",
	combatLogEvents = {
		{
			eventType = "SPELL_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "DODGE" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "SPELL_PERIODIC_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "DODGE" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "RANGE_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "DODGE" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
	},
	tagTranslations = spellMissTagTranslations,
	tagTranslationsHelp = incPetSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet skills"],
	name = "Pet ability parries",
	localName = L["Pet ability parries"],
	defaultTag = PET .. " " .. PARRY .. "! ([Skill])",
	combatLogEvents = {
		{
			eventType = "SPELL_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "PARRY" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "SPELL_PERIODIC_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "PARRY" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "RANGE_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "PARRY" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
	},
	tagTranslations = spellMissTagTranslations,
	tagTranslationsHelp = incPetSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet skills"],
	name = "Pet ability blocks",
	localName = L["Pet ability blocks"],
	defaultTag = PET .. " " .. BLOCK .. "! ([Skill])",
	combatLogEvents = {
		{
			eventType = "SPELL_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "BLOCK" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "SPELL_PERIODIC_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "BLOCK" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "RANGE_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "BLOCK" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
	},
	tagTranslations = spellMissTagTranslations,
	tagTranslationsHelp = incPetSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet skills"],
	name = "Pet spell resists",
	localName = L["Pet spell resists"],
	defaultTag = PET .. " " .. RESIST .. "! ([Skill])",
	combatLogEvents = {
		{
			eventType = "SPELL_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "RESIST" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "SPELL_PERIODIC_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "RESIST" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "RANGE_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "RESIST" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
	},
	tagTranslations = spellMissTagTranslations,
	tagTranslationsHelp = incPetSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "7f7fb2", -- blue-gray
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet skills"],
	name = "Pet skill absorbs",
	localName = L["Pet skill"],
	defaultTag = PET .. " " .. ABSORB .. " [Amount]! ([Skill])",
	combatLogEvents = {
		{
			eventType = "SPELL_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "ABSORB" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "SPELL_PERIODIC_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "ABSORB" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "RANGE_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "ABSORB" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
	},
	tagTranslations = spellMissTagTranslations,
	tagTranslationsHelp = incPetSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "7f7fff", -- light blue
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet skills"],
	name = "Pet skill immunes",
	localName = L["Pet skill immunes"],
	defaultTag = PET .. " " .. IMMUNE .. "! ([Skill])",
	combatLogEvents = {
		{
			eventType = "SPELL_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "IMMUNE" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "SPELL_PERIODIC_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "IMMUNE" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "RANGE_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "IMMUNE" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
	},
	tagTranslations = spellMissTagTranslations,
	tagTranslationsHelp = incPetSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "7f7fff", -- light blue
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet skills"],
	name = "Pet skill reflects",
	localName = L["Pet skill reflects"],
	defaultTag = PET .. " " .. REFLECT .. "! ([Skill])",
	combatLogEvents = {
		{
			eventType = "SPELL_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "REFLECT" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "SPELL_PERIODIC_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "REFLECT" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "RANGE_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "REFLECT" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
	},
	tagTranslations = spellMissTagTranslations,
	tagTranslationsHelp = incPetSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "7f7fff", -- light blue
--	canCrit = true,
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet skills"],
	name = "Pet skill evades",
	localName = L["Pet skill evades"],
	defaultTag = PET .. " " .. EVADE .. "! ([Skill])",
	ccombatLogEvents = {
		{
			eventType = "SPELL_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "EVADE" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "SPELL_PERIODIC_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "EVADE" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
		{
			eventType = "RANGE_MISSED",
			check = function(srcGUID, _, _, dstGUID, _, dstFlags, _, _, _, missType)
					if missType == "EVADE" then
						if dstGUID == UnitGUID("pet") then
							return true
						elseif checkFlags(dstFlags, GUARDIAN_FLAGS) then
							return Parrot.db.profile.totemDamage
						end
					end
					return false
				end,
			func = parseSpellMissInfo,
		},
	},
	tagTranslations = spellMissTagTranslations,
	tagTranslationsHelp = incPetSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "ff7fff", -- pink
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet heals"],
	name = "Pet heals",
	localName = L["Pet heals"],
	defaultTag = PET .. " +[Amount]",
	combatLogEvents = {
		{
		eventType = "SPELL_HEAL",
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags,spellId, spellName, spellSchool, amount, overheal, critical)
			if dstGUID ~= (UnitGUID("pet") or 0) then
				return nil
			end

			local info = newList()
			info.damageType = SchoolParser[school]
			info.spellID = spellId
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName
			info.amount = amount
			info.realAmount = amount-overheal
			info.abilityName = spellName
			info.isCrit = (critical ~= nil)

			info.isHoT = false
			info.overhealAmount = overheal

			return info

		end,
		},
	},
	tagTranslations = {
		Name = "destName",
		Skill = retrieveAbilityName,
		Amount = "realAmount",
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the ally that healed your pet."],
		Skill = L["The spell or ability that the ally healed your pet with."],
		Amount = L["The amount of healing done."],
	},
	color = "00ff00", -- green
	canCrit = true,
	filterType = { "Incoming heals", 'realAmount' },
	throttle = { "Heals", 'abilityName', { 'throttleCount', 'isCrit', healThrottleFunc }, sourceName = L["Multiple"] },
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	subCategory = L["Pet heals"],
	name = "Pet heals over time",
	localName = L["Pet heals over time"],
	defaultTag = PET .. " ([Skill] - [Name]) +[Amount]",
	canCrit = true,
	combatLogEvents = {
		{
		eventType = "SPELL_PERIODIC_HEAL",
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags,spellId, spellName, spellSchool, amount, overheal, critical)
			if dstGUID ~= (UnitGUID("pet") or 0) then
				return nil
			end

			local info = newList()
			info.damageType = SchoolParser[school]
			info.spellID = spellId
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName
			info.amount = amount
			info.realAmount = amount-overheal
			info.abilityName = spellName
			info.isCrit = (critical ~= nil)

			info.isHoT = true
			info.overhealAmount = overheal

			return info
		end,
		},
	},
	tagTranslations = {
		Name = "sourceName",
		Skill = retrieveAbilityName,
		Amount = "realAmount",
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the ally that healed your pet."],
		Skill = L["The spell or ability that the ally healed your pet with."],
		Amount = L["The amount of healing done."],
	},
	throttle = { "DoTs and HoTs", 'abilityName', { 'throttleCount', 'isCrit', healThrottleFunc }, sourceName = L["Multiple"] },
	color = "00ff00", -- green
	filterType = { "Incoming heals", 'realAmount' },
}

------------------------------------------------------------------------------
-- Outgoing events -----------------------------------------------------------
------------------------------------------------------------------------------
Parrot:RegisterFilterType("Outgoing damage", L["Outgoing damage"], 0)

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Melee"],
	name = "Melee damage",
	localName = L["Melee damage"],
	defaultTag = "[Amount]",
	combatLogEvents = {
		{
		eventType = "SWING_DAMAGE",
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
			if srcGUID ~= UnitGUID("player") then
				return nil
			end

			local info = {}
			info.damageType = SchoolParser[school]
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName
			info.amount = amount
			info.overkill = overkill
			info.absorbAmount = absorbed or 0
			info.blockAmount = blocked or 0
			info.resistAmount = resisted or 0
			info.isCrit = (critical ~= nil)
			info.isCrushing = (crushing ~= nil)
			info.isGlancing = (glancing ~= nil)


			return info
		end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
		Amount = coloredDamageAmount,
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy you attacked."],
		Amount = L["The amount of damage done."],
	},
	color = "ffffff", -- white
	canCrit = true,
	filterType = { "Outgoing damage", 'amount' },
	throttle = { "Melee damage", 'sourceID', { 'throttleCount', 'isCrit', function(info)
		local numNorm = info.throttleCount_isCrit_false or 0
		local numCrit = info.throttleCount_isCrit_true or 0
		info.isCrit = numCrit > 0
		if numNorm == 1 then
			if numCrit == 1 then
				return L[" (%d hit, %d crit)"]:format(1, 1)
			elseif numCrit == 0 then
				-- just one hit
				return nil
			else -- >= 2
				return L[" (%d hit, %d crits)"]:format(1, numCrit)
			end
		elseif numNorm == 0 then
			if numCrit == 1 then
				-- just one crit
				return nil
			else -- >= 2
				return L[" (%d crits)"]:format(numCrit)
			end
		else -- >= 2
			if numCrit == 1 then
				return L[" (%d hits, %d crit)"]:format(numNorm, 1)
			elseif numCrit == 0 then
				-- just one hit
				return L[" (%d hits)"]:format(numNorm)
			else -- >= 2
				return L[" (%d hits, %d crits)"]:format(numNorm, numCrit)
			end
		end
	end }, recipientName = L["Multiple"] },
}

local outMissTagTranslations = {
	Name = "recipientName",
	Amount = "amount",
}

local outMissTagTranslationHelp = {
	Name = L["The name of the enemy you attacked."],
	Amount = L["Amount of the damage that was missed."],
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Melee"],
	name = "Melee misses",
	localName = L["Melee misses"],
	defaultTag = MISS .. "!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		check = function(srcGUID, _, _, _, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "MISS")
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = outMissTagTranslations,
	tagTranslationsHelp = outMissTagTranslationHelp,
	throttle = missThrottle,
	color = "ffffff", -- white
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Melee"],
	name = "Melee dodges",
	localName = L["Melee dodges"],
	defaultTag = DODGE .. "!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		check = function(srcGUID, _, _, _, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "DODGE")
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = outMissTagTranslations,
	tagTranslationsHelp = outMissTagTranslationHelp,
	throttle = missThrottle,
	color = "ffffff", -- white
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Melee"],
	name = "Melee parries",
	localName = L["Melee parries"],
	defaultTag = PARRY .. "!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		check = function(srcGUID, _, _, _, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "PARRY")
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = outMissTagTranslations,
	tagTranslationsHelp = outMissTagTranslationHelp,
	throttle = missThrottle,
	color = "ffffff", -- white
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Melee"],
	name = "Melee blocks",
	localName = L["Melee blocks"],
	defaultTag = BLOCK .. "!",
		combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		check = function(srcGUID, _, _, _, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "BLOCK")
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = outMissTagTranslations,
	tagTranslationsHelp = outMissTagTranslationHelp,
	throttle = missThrottle,
	color = "ffffff", -- white
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Melee"],
	name = "Melee absorbs",
	localName = L["Melee absorbs"],
	defaultTag = ABSORB .. " [Amount]!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		check = function(srcGUID, _, _, _, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "ABSORB")
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = outMissTagTranslations,
	tagTranslationsHelp = outMissTagTranslationHelp,
	throttle = missThrottle,
	color = "ffff00", -- yellow
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Melee"],
	name = "Melee immunes",
	localName = L["Melee immunes"],
	defaultTag = IMMUNE .. "!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		check = function(srcGUID, _, _, _, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "IMMUNE")
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = outMissTagTranslations,
	tagTranslationsHelp = outMissTagTranslationHelp,
	throttle = missThrottle,
	color = "ffff00", -- yellow
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Melee"],
	name = "Melee evades",
	localName = L["Melee evades"],
	defaultTag = EVADE .. "!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		check = function(srcGUID, _, _, _, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "EVADE")
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = outMissTagTranslations,
	tagTranslationsHelp = outMissTagTranslationHelp,
	throttle = missThrottle,
	color = "ff7f00", -- orange
}


Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Skills"],
	name = "Reactive skills",
	localName = L["Reactive skills"],
	defaultTag = "[Amount] ([Skill])",
	combatLogEvents = {
		{
			eventType = "DAMAGE_SHIELD",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
			if srcGUID ~= UnitGUID("player") then
				return nil
			end

			local info = newList()
			info.spellID = spellId
			info.damageType = SchoolParser[school] or SchoolParser[spellSchool]
			info.sourceName = srcName
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.abilityName = spellName
			info.absorbAmount = absorbed or 0
			info.blockAmount = blocked or 0
			info.resistAmount = resisted or 0
			info.amount = amount
			info.overkill = overkill
			info.isCrit = (critical ~= nil)
			info.isCrushing = (crushing ~= nil)
			info.isGlancing = (glancing ~= nil)


			return info
		end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
		Amount = coloredDamageAmount,
		Type = damageTypeString,
		Skill = retrieveAbilityName,
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy you attacked."],
		Amount = L["The amount of damage done."],
		Type = L["The type of damage done."],
		Skill = L["The spell or ability that you used."],
	},
	color = "ff0000", -- red
	canCrit = true,
	throttle = { "Skill damage", 'abilityName', { 'throttleCount', 'isCrit', skillThrottleFunc }, sourceName = L["Multiple"] },
	filterType = { "Outgoing damage", 'amount' },

}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Skills"],
	name = "Skill damage",
	localName = L["Skill damage"],
	defaultTag = "[Amount] ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_DAMAGE",
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill,  school, resisted, blocked, absorbed, critical, glancing, crushing)
			-- 2nd condition is to prevent self-damage shown as outgoing
			if srcGUID ~= UnitGUID("player") or dstGUID == UnitGUID("player") then
				return nil
			end

			local info = newList()
			info.spellID = spellId
			info.damageType = SchoolParser[school] or SchoolParser[spellSchool]
			info.recipientID = dstGUID
			info.recipientName = drcName
			info.sourceName = srcName
			info.sourceID = srcGUID
			info.abilityName = spellName
			info.absorbAmount = absorbed or 0
			info.blockAmount = blocked or 0
			info.resistAmount = resisted or 0
			info.amount = amount
			info.overkill = overkill
			info.isCrit = (critical ~= nil)
			info.isCrushing = (crushing ~= nil)
			info.isGlancing = (glancing ~= nil)



			return info
		end,
		},
		{
			eventType = "RANGE_DAMAGE",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
				if srcGUID ~= UnitGUID("player") then
				return nil
			end

			local info = newList()
			info.spellID = spellId
			info.damageType = SchoolParser[school] or SchoolParser[spellSchool]
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceName = srcName
			info.sourceID = srcGUID
			info.abilityName = spellName
			info.absorbAmount = absorbed or 0
			info.blockAmount = blocked or 0
			info.resistAmount = resisted or 0
			info.amount = amount
			info.overkill = overkill
			info.isCrit = (critical ~= nil)
			info.isCrushing = (crushing ~= nil)
			info.isGlancing = (glancing ~= nil)



			return info
			end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
		Amount = coloredDamageAmount,
		Type = damageTypeString,
		Skill = retrieveAbilityName,
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy you attacked."],
		Amount = L["The amount of damage done."],
		Type = L["The type of damage done."],
		Skill = L["The spell or ability that you used."],
	},
	color = "ffff00", -- yellow
	canCrit = true,
	throttle = { "Skill damage", 'abilityName', { 'throttleCount', 'isCrit', skillThrottleFunc }, recipientName = L["Multiple"] },
	filterType = { "Outgoing damage", 'amount' },
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Skills"],
	name = "Skill DoTs",
	localName = L["Skill DoTs"],
	defaultTag = "[Amount] ([Skill])",
	canCrit = true,
	combatLogEvents = {
		{
		eventType = "SPELL_PERIODIC_DAMAGE",
		func = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing )
			if srcGUID ~= UnitGUID("player") then
				return nil
			end

			local info = newList()
			info.spellID = spellId
			info.damageType = SchoolParser[spellSchool]
			info.recipientID = dstGUID
			info.recipientName = dName
			info.sourceName = srcName
			info.sourceID = srcGUID
			info.abilityName = spellName
			info.amount = amount + (extraAmount or 0)
			info.overkill = overkill
			info.isCrit = (critical ~= nil)
			info.isCrushing = (crushing ~= nil)
			info.isGlancing = (glancing ~= nil)
			info.absorbed = absorbed
			info.resisted = resisted
			info.blocked = blocked
--

			return info
		end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
		Amount = coloredDamageAmount,
		Type = damageTypeString,
		Skill = retrieveAbilityName,
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy you attacked."],
		Amount = L["The amount of damage done."],
		Type = L["The type of damage done."],
		Skill = L["The spell or ability that you used."],
	},
	throttle = { "DoTs and HoTs", 'abilityName', { 'throttleCount', 'isCrit', skillThrottleFunc }, recipientName = L["Multiple"] },
	color = "ffff00", -- yellow
}

local outSpellMissTagTranslations = {
	Name = "recipientName",
	Skill = retrieveAbilityName,
	Icon = retrieveIconFromAbilityName,
	Amount = "amount",
}
local outSpellMissTagTranslationsHelp = {
	Name = L["The name of the enemy you attacked."],
	Skill = L["The spell or ability that you used."],
	Amount = L["Amount of the damage that was missed."],
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Skills"],
	name = "Ability misses",
	localName = L["Ability misses"],
	defaultTag = MISS .. "! ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "MISS")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "MISS")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "RANGE_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "MISS")
			end,
		func = parseSpellMissInfo,
		},
	},
	tagTranslations = outSpellMissTagTranslations,
	tagTranslationsHelp = outSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "ffffff", -- white
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Skills"],
	name = "Ability dodges",
	localName = L["Ability dodges"],
	defaultTag = DODGE .. "! ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "DODGE")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "DODGE")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "RANGE_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "DODGE")
			end,
		func = parseSpellMissInfo,
		},
	},
	tagTranslations = outSpellMissTagTranslations,
	tagTranslationsHelp = outSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "ffffff", -- white
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Skills"],
	name = "Ability parries",
	localName = L["Ability parries"],
	defaultTag = PARRY .. "! ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "PARRY")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "PARRY")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "RANGE_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "PARRY")
			end,
		func = parseSpellMissInfo,
		},
	},
	tagTranslations = outSpellMissTagTranslations,
	tagTranslationsHelp = outSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "ffffff", -- white
}


Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Skills"],
	name = "Ability blocks",
	localName = L["Ability blocks"],
	defaultTag = BLOCK .. "! ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "BLOCK")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "BLOCK")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "RANGE_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "BLOCK")
			end,
		func = parseSpellMissInfo,
		},
	},
	tagTranslations = outSpellMissTagTranslations,
	tagTranslationsHelp = outSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "ffffff", -- white
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Skills"],
	name = "Spell resists",
	localName = L["Spell resists"],
	defaultTag = RESIST .. "! ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "RESIST")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "RESIST")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "RANGE_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "RESIST")
			end,
		func = parseSpellMissInfo,
		},
	},
	tagTranslations = outSpellMissTagTranslations,
	tagTranslationsHelp = outSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "7f7fb2", -- blue-gray
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Skills"],
	name = "Skill absorbs",
	localName = L["Skill absorbs"],
	defaultTag = ABSORB .. " [Amount]! ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "ABSORB")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "ABSORB")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "RANGE_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "ABSORB")
			end,
		func = parseSpellMissInfo,
		},
	},
	tagTranslations = outSpellMissTagTranslations,
	tagTranslationsHelp = outSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "ffff00", -- yellow
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Skills"],
	name = "Skill immunes",
	localName = L["Skill immunes"],
	defaultTag = IMMUNE .. "! ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "IMMUNE")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "IMMUNE")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "RANGE_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "IMMUNE")
			end,
		func = parseSpellMissInfo,
		},
	},
	tagTranslations = outSpellMissTagTranslations,
	tagTranslationsHelp = outSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "ffff00", -- yellow
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Skills"],
	name = "Skill reflects",
	localName = L["Skill reflects"],
	defaultTag = REFLECT .. "! ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "REFLECT")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "REFLECT")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "RANGE_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "REFLECT")
			end,
		func = parseSpellMissInfo,
		},
	},
	tagTranslations = outSpellMissTagTranslations,
	tagTranslationsHelp = outSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "ffff00", -- yellow
--	canCrit = true,
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Skills"],
	name = "Skill evades",
	localName = L["Skill evades"],
	defaultTag = EVADE .. "! ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "EVADE")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "EVADE")
			end,
		func = parseSpellMissInfo,
		},
		{
		eventType = "RANGE_MISSED",
		check = function( srcGUID, _, _, _, _, _,_, _, _, missType)
				return (srcGUID == UnitGUID("player") and missType == "EVADE")
			end,
		func = parseSpellMissInfo,
		},
	},
	tagTranslations = outSpellMissTagTranslations,
	tagTranslationsHelp = outSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "ff7f00", -- orange
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Skills"],
	name = "Spell interrupts",
	localName = L["Skill interrupts"],
	defaultTag = "([Skill]) " .. INTERRUPT .. "! {[ExtraSkill]}",
	combatLogEvents = {
		{
		eventType = "SPELL_INTERRUPT",
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, extraSpellId, extraSpellName, extraSpellSchool)
			if srcGUID ~= UnitGUID("player") then
				return nil
			end

			local info = newList()
			info.spellID = spellId
			info.extraSpellID = extraSpellId
			info.damageType = SchoolParser[spellSchool]
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceName = srcName
			info.sourceID = srcGUID
			info.abilityName = spellName
			info.extraAbilityName = extraSpellName



			return info
		end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
		Skill = retrieveAbilityName,
		ExtraSkill = retrieveExtraAbilityName,
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy you attacked."],
		Skill = L["The spell or ability that you used."],
		ExtraSkill = L["The spell you interrupted"]
	},
	color = "ffff00", -- yellow
}

Parrot:RegisterFilterType("Outgoing heals", L["Outgoing heals"], 0)

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Heals"],
	name = "Heals",
	localName = L["Heals"],
	defaultTag = "+[Amount] ([Skill] - [Name])",
	combatLogEvents = {
		{
		eventType = "SPELL_HEAL",
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags,spellId, spellName, spellSchool, amount, overheal, critical)
			if srcGUID ~= UnitGUID("player") or dstGUID == UnitGUID("player") or dstGUID == UnitGUID("pet") then
				return nil
			end

			local info = newList()
			info.damageType = SchoolParser[school]
			info.spellID = spellId
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName
			info.amount = amount
			info.realAmount = amount-overheal
			info.abilityName = spellName
			info.isCrit = (critical ~= nil)

			info.isHoT = false
			info.overhealAmount = overheal

			return info

		end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
		Skill = retrieveAbilityName,
		Amount = "realAmount",
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the ally you healed."],
		Skill = L["The spell or ability that you used."],
		Amount = L["The amount of healing done."],
	},
	color = "00ff00", -- green
	canCrit = true,
	filterType = { "Outgoing heals", 'realAmount' },
	throttle = { "Heals", 'abilityName', { 'throttleCount', 'isCrit', healThrottleFunc }, sourceName = L["Multiple"] },
}


Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Heals"],
	name = "Self heals",
	localName = L["Self heals"],
	defaultTag = "+[Amount] ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_HEAL",
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags,spellId, spellName, spellSchool, amount, overheal, critical)
			if srcGUID ~= UnitGUID("player") or dstGUID ~= UnitGUID("player") then
				return nil
			end

			local info = newList()
			info.damageType = SchoolParser[school]
			info.spellID = spellId
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName
			info.amount = amount
			info.realAmount = amount-overheal
			info.abilityName = spellName
			info.isCrit = (critical ~= nil)

			info.isHoT = false
			info.overhealAmount = overheal

			return info

		end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
		Skill = retrieveAbilityName,
		Amount = "realAmount",
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the ally you healed."],
		Skill = L["The spell or ability that you used."],
		Amount = L["The amount of healing done."],
	},
	color = "00ff00", -- green
	canCrit = true,
	defaultDisabled = true,
	filterType = { "Outgoing heals", 'realAmount' },
	throttle = { "Heals", 'abilityName', { 'throttleCount', 'isCrit', healThrottleFunc }, sourceName = L["Multiple"] },
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Heals"],
	name = "Heals over time",
	localName = L["Heals over time"],
	defaultTag = "+[Amount] ([Skill] - [Name])",
	canCrit = true,
	combatLogEvents = {
		{
		eventType = "SPELL_PERIODIC_HEAL",
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags,spellId, spellName, spellSchool, amount, overheal, critical)
			if srcGUID ~= UnitGUID("player") or dstGUID == UnitGUID("player") or dstGUID == UnitGUID("pet") then
				return nil
			end

			local info = newList()
			info.damageType = SchoolParser[school]
			info.spellID = spellId
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName
			info.amount = amount
			info.realAmount = amount-overheal
			info.abilityName = spellName
			info.isCrit = (critical ~= nil)

			info.isHoT = true
			info.overhealAmount = overheal

			return info
		end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
		Skill = retrieveAbilityName,
		Amount = "realAmount",
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the ally you healed."],
		Skill = L["The spell or ability that you used."],
		Amount = L["The amount of healing done."],
	},
	throttle = { "DoTs and HoTs", 'abilityName', { 'throttleCount', 'isCrit', healThrottleFunc }, recipientName = L["Multiple"] },
	color = "00ff00", -- green
	filterType = { "Outgoing heals", 'realAmount' },
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Heals"],
	name = "Self heals over time",
	localName = L["Self heals over time"],
	defaultTag = "+[Amount] ([Skill])",
	canCrit = true,
	combatLogEvents = {
		{
		eventType = "SPELL_PERIODIC_HEAL",
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags,spellId, spellName, spellSchool, amount, overheal, critical)
			if dstGUID ~= UnitGUID("player") or srcGUID ~= UnitGUID("player") then
				return nil
			end

			local info = newList()
			info.damageType = SchoolParser[school]
			info.spellID = spellId
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName
			info.amount = amount
			info.realAmount = amount-overheal
			info.abilityName = spellName
			info.isCrit = (critical ~= nil)

			info.isHoT = true
			info.overhealAmount = overheal

			return info

		end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
		Skill = retrieveAbilityName,
		Amount = "realAmount",
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the ally you healed."],
		Skill = L["The spell or ability that you used."],
		Amount = L["The amount of healing done."],
	},
	throttle = { "DoTs and HoTs", 'abilityName', { 'throttleCount', 'isCrit', skillThrottleFunc }, recipientName = L["Multiple"] },
	color = "00ff00", -- green
	filterType = { "Outgoing heals", 'realAmount' },
	defaultDisabled = true,
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet melee"],
	name = "Pet melee damage",
	localName = L["Pet melee damage"],
	defaultTag = PET .. " [Amount]",
	combatLogEvents = {
		{
		eventType = "SWING_DAMAGE",
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
			if checkFlags(srcFlags, GUARDIAN_FLAGS) then
				if not Parrot.db.profile.totemDamage then
					return nil
				end
			elseif srcGUID ~= (UnitGUID("pet") or 0) then
				return nil
			end

			local info = {}
			info.damageType = SchoolParser[school]
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName
			info.amount = amount
			info.overkill = overkill
			info.absorbAmount = absorbed or 0
			info.blockAmount = blocked or 0
			info.resistAmount = resisted or 0
			info.isCrit = (critical ~= nil)
			info.isCrushing = (crushing ~= nil)
			info.isGlancing = (glancing ~= nil)


			return info
		end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
		Amount = "amount",
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy your pet attacked."],
		Amount = L["The amount of damage done."],
	},
	color = "ff7f00", -- orange
	canCrit = true,
	throttle = { "Melee damage", 'sourceID', { 'throttleCount', 'isCrit', function(info)
		local numNorm = info.throttleCount_isCrit_false or 0
		local numCrit = info.throttleCount_isCrit_true or 0
		info.isCrit = numCrit > 0
		if numNorm == 1 then
			if numCrit == 1 then
				return L[" (%d hit, %d crit)"]:format(1, 1)
			elseif numCrit == 0 then
				-- just one hit
				return nil
			else -- >= 2
				return L[" (%d hit, %d crits)"]:format(1, numCrit)
			end
		elseif numNorm == 0 then
			if numCrit == 1 then
				-- just one crit
				return nil
			else -- >= 2
				return L[" (%d crits)"]:format(numCrit)
			end
		else -- >= 2
			if numCrit == 1 then
				return L[" (%d hits, %d crit)"]:format(numNorm, 1)
			elseif numCrit == 0 then
				-- just one hit
				return L[" (%d hits)"]:format(numNorm)
			else -- >= 2
				return L[" (%d hits, %d crits)"]:format(numNorm, numCrit)
			end
		end
	end }, recipientName = L["Multiple"] },
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet melee"],
	name = "Pet melee misses",
	localName = L["Pet melee misses"],
	defaultTag = PET .. " " .. MISS .. "!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		func = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType, amountMissed )
			if missType ~= "MISS" then
				return
			end
			if checkFlags(srcFlags, GUARDIAN_FLAGS) then
				if not Parrot.db.profile.totemDamage then
					return nil
				end
			elseif srcGUID ~= (UnitGUID("pet") or 0) then
				return nil
			end

			local info = newList()
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName


			return info
		end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy your pet attacked."],
	},
	color = "ff7f00", -- orange
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet melee"],
	name = "Pet melee dodges",
	localName = L["Pet melee dodges"],
	defaultTag = PET .. " " .. DODGE .. "!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		func = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType, amountMissed )
			if missType ~= "DODGE" then
				return
			end
			if checkFlags(srcFlags, GUARDIAN_FLAGS) then
				if not Parrot.db.profile.totemDamage then
					return nil
				end
			elseif srcGUID ~= (UnitGUID("pet") or 0) then
				return nil
			end

			local info = newList()
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName


			return info
		end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy your pet attacked."],
	},
	color = "ff7f00", -- orange
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet melee"],
	name = "Pet melee parries",
	localName = L["Pet melee parries"],
	defaultTag = PET .. " " .. PARRY .. "!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		func = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType, amountMissed )
			if missType ~= "PARRY" then
				return
			end
			if checkFlags(srcFlags, GUARDIAN_FLAGS) then
				if not Parrot.db.profile.totemDamage then
					return nil
				end
			elseif srcGUID ~= (UnitGUID("pet") or 0) then
				return nil
			end

			local info = newList()
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName


			return info
		end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy your pet attacked."],
	},
	color = "ff7f00", -- orange
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet melee"],
	name = "Pet melee blocks",
	localName = L["Pet melee blocks"],
	defaultTag = PET .. " " .. BLOCK .. "!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		func = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType, amountMissed )
			if missType ~= "BLOCK" then
				return
			end
			if checkFlags(srcFlags, GUARDIAN_FLAGS) then
				if not Parrot.db.profile.totemDamage then
					return nil
				end
			elseif srcGUID ~= (UnitGUID("pet") or 0) then
				return nil
			end

			local info = newList()
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName


			return info
		end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy your pet attacked."],
	},
	color = "ff7f00", -- orange
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet melee"],
	name = "Pet melee absorbs",
	localName = L["Pet melee absorbs"],
	defaultTag = PET .. " " .. ABSORB .. " [Amount]!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		func = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType, amountMissed )
			if missType ~= "ABSORB" then
				return
			end
			if checkFlags(srcFlags, GUARDIAN_FLAGS) then
				if not Parrot.db.profile.totemDamage then
					return nil
				end
			elseif srcGUID ~= (UnitGUID("pet") or 0) then
				return nil
			end

			local info = newList()
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName


			return info
		end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy your pet attacked."],
	},
	color = "7f7fff", -- light blue
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet melee"],
	name = "Pet melee immunes",
	localName = L["Pet melee immunes"],
	defaultTag = PET .. " " .. IMMUNE .. "!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		func = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType, amountMissed )
			if missType ~= "IMMUNE" then
				return
			end
			if checkFlags(srcFlags, GUARDIAN_FLAGS) then
				if not Parrot.db.profile.totemDamage then
					return nil
				end
			elseif srcGUID ~= (UnitGUID("pet") or 0) then
				return nil
			end

			local info = newList()
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName


			return info
		end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy your pet attacked."],
	},
	color = "7f7fff", -- light blue
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet melee"],
	name = "Pet melee evades",
	localName = L["Pet melee evades"],
	defaultTag = PET .. " " .. EVADE .. "!",
	combatLogEvents = {
		{
		eventType = "SWING_MISSED",
		func = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missType, amountMissed )
			if missType ~= "EVADE" then
				return
			end
			if checkFlags(srcFlags, GUARDIAN_FLAGS) then
				if not Parrot.db.profile.totemDamage then
					return nil
				end
			elseif srcGUID ~= (UnitGUID("pet") or 0) then
				return nil
			end

			local info = newList()
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName


			return info
		end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy your pet attacked."],
	},
	color = "ff7fff", -- pink
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet skills"],
	name = "Pet skill damage",
	localName = L["Pet skill damage"],
	defaultTag = PET .. " [Amount] ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_DAMAGE",
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
			if checkFlags(srcFlags, GUARDIAN_FLAGS) then
				if not Parrot.db.profile.totemDamage then
					return nil
				end
			elseif srcGUID ~= (UnitGUID("pet") or 0) then
				return nil
			end

			local info = newList()
			info.spellID = spellId
			info.damageType = SchoolParser[school] or SchoolParser[spellSchool]
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceName = srcName
			info.sourceID = srcGUID
			info.abilityName = spellName
			info.absorbAmount = absorbed or 0
			info.blockAmount = blocked or 0
			info.resistAmount = resisted or 0
			info.amount = amount
			info.overkill = overkill
			info.isCrit = (critical ~= nil)
			info.isCrushing = (crushing ~= nil)
			info.isGlancing = (glancing ~= nil)



			return info
		end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
		Amount = coloredDamageAmount,
		Type = damageTypeString,
		Skill = retrieveAbilityName,
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy your pet attacked."],
		Amount = L["The amount of damage done."],
		Type = L["The type of damage done."],
		Skill = L["The ability or spell your pet used."],
	},
	color = "0000ff", -- blue
	canCrit = true,
	throttle = { "Skill damage", 'abilityName', { 'throttleCount', 'isCrit', skillThrottleFunc }, recipientName = L["Multiple"] },
	filterType = { "Outgoing damage", 'amount' },

}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet skills"],
	name = "Pet skill DoTs",
	localName = L["Pet skill DoTs"],
	defaultTag = PET .. "[Amount] ([Skill])",
	canCrit = true,
	combatLogEvents = {
		{
		eventType = "SPELL_PERIODIC_DAMAGE",
		func = function( srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing )
			if checkFlags(srcFlags, GUARDIAN_FLAGS) then
				if not Parrot.db.profile.totemDamage then
					return nil
				end
			elseif srcGUID ~= UnitGUID("pet") then
				return nil
			end

			local info = newList()
			info.spellID = spellId
			info.damageType = SchoolParser[spellSchool]
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceName = srcName
			info.sourceID = srcGUID
			info.abilityName = spellName
			info.amount = amount + (extraAmount or 0)
			info.overkill = overkill
			info.absorbed = absorbed
			info.resisted = resisted
			info.blocked = blocked
			info.isCrit = (critical ~= nil)
			info.isCrushing = (crushing ~= nil)
			info.isGlancing = (glancing ~= nil)


			return info
		end,
		},
	},
	tagTranslations = {
		Name = "recipientName",
		Amount = coloredDamageAmount,
		Type = damageTypeString,
		Skill = retrieveAbilityName,
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the enemy your pet attacked."],
		Amount = L["The amount of damage done."],
		Type = L["The type of damage done."],
		Skill = L["The spell or ability that your pet used."],
	},
	throttle = { "DoTs and HoTs", 'abilityName', { 'throttleCount', 'isCrit', skillThrottleFunc }, recipientName = L["Multiple"] },
	color = "ffff00", -- yellow
}


--##
local petOutSpellMissTagTranslationsHelp = {
	Name = L["The name of the enemy your pet attacked."],
	Skill = L["The ability or spell your pet used."],
	Amount = L["Amount of the damage that was missed."],
},

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet skills"],
	name = "Pet ability misses",
	localName = L["Pet ability misses"],
	defaultTag = PET .. " " .. MISS .. "! ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "MISS" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "MISS" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
		{
		eventType = "RANGE_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "MISS" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = outSpellMissTagTranslations,
	tagTranslationsHelp = petOutSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet skills"],
	name = "Pet ability dodges",
	localName = L["Pet ability dodges"],
	defaultTag = PET .. " " .. DODGE .. "! ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "DODGE" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "DODGE" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
		{
		eventType = "RANGE_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "DODGE" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = outSpellMissTagTranslations,
	tagTranslationsHelp = petOutSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet skills"],
	name = "Pet ability parries",
	localName = L["Pet ability parries"],
	defaultTag = PET .. " " .. PARRY .. "! ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "PARRY" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "PARRY" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
		{
		eventType = "RANGE_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "PARRY" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = outSpellMissTagTranslations,
	tagTranslationsHelp = petOutSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet skills"],
	name = "Pet ability blocks",
	localName = L["Pet ability blocks"],
	defaultTag = PET .. " " .. BLOCK .. "! ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "BLOCK" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "BLOCK" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
		{
		eventType = "RANGE_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "BLOCK" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = outSpellMissTagTranslations,
	tagTranslationsHelp = petOutSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "0000ff", -- blue
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet skills"],
	name = "Pet spell resists",
	localName = L["Pet spell resists"],
	defaultTag = PET .. " " .. RESIST .. "! ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "RESIST" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "RESIST" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
		{
		eventType = "RANGE_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "RESIST" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = outSpellMissTagTranslations,
	tagTranslationsHelp = petOutSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "7f7fb2", -- blue-gray
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet skills"],
	name = "Pet skill absorbs",
	localName = L["Pet skill"],
	defaultTag = PET .. " " .. ABSORB .. " [Amount]! ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "ABSORB" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "ABSORB" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
		{
		eventType = "RANGE_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "ABSORB" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = outSpellMissTagTranslations,
	tagTranslationsHelp = petOutSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "7f7fff", -- light blue
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet skills"],
	name = "Pet skill immunes",
	localName = L["Pet skill immunes"],
	defaultTag = PET .. " " .. IMMUNE .. "! ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "IMMUNE" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "IMMUNE" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
		{
		eventType = "RANGE_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "IMMUNE" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = outSpellMissTagTranslations,
	tagTranslationsHelp = petOutSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "7f7fff", -- light blue
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet skills"],
	name = "Pet skill reflects",
	localName = L["Pet skill reflects"],
	defaultTag = PET .. " " .. REFLECT .. "! ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "REFLECT" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "REFLECT" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
		{
		eventType = "RANGE_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "REFLECT" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = outSpellMissTagTranslations,
	tagTranslationsHelp = petOutSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "7f7fff", -- light blue
--	canCrit = true,
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet skills"],
	name = "Pet skill evades",
	localName = L["Pet skill evades"],
	defaultTag = PET .. " " .. EVADE .. "! ([Skill])",
	combatLogEvents = {
		{
		eventType = "SPELL_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "EVADE" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
		{
		eventType = "SPELL_PERIODIC_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "EVADE" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
		{
		eventType = "RANGE_MISSED",
		check = function(srcGUID, _, _, dstGUID, _, dstFlags, missType)
				if missType == "EVADE" then
					if srcGUID == UnitGUID("pet") then
						return true
					elseif checkFlags(srcFlags, GUARDIAN_FLAGS) then
						return Parrot.db.profile.totemDamage
					end
				end
				return false
			end,
		func = parseMissInfo,
		},
	},
	tagTranslations = outSpellMissTagTranslations,
	tagTranslationsHelp = petOutSpellMissTagTranslationsHelp,
	throttle = missThrottle,
	color = "ff7fff", -- pink
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet heals"],
	name = "Pet heals",
	localName = L["Pet heals"],
	defaultTag = PET .. " +[Amount]",
	combatLogEvents = {
		{
		eventType = "SPELL_HEAL",
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags,spellId, spellName, spellSchool, amount, overheal, critical)
			if srcGUID ~= (UnitGUID("pet") or 0) then
				return nil
			end

			local info = newList()
			info.damageType = SchoolParser[school]
			info.spellID = spellId
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName
			info.amount = amount
			info.realAmount = amount-overheal
			info.abilityName = spellName
			info.isCrit = (critical ~= nil)

			info.isHoT = false
			info.overhealAmount = overheal

			return info

		end,
		},
	},
	tagTranslations = {
		Name = "destName",
		Skill = retrieveAbilityName,
		Amount = "realAmount",
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the unit that your pet healed."],
		Skill = L["The spell or ability that the pet used to heal."],
		Amount = L["The amount of healing done."],
	},
	color = "00ff00", -- green
	canCrit = true,
	filterType = { "Outgoing heals", 'realAmount' },
	throttle = { "Heals", 'abilityName', { 'throttleCount', 'isCrit', healThrottleFunc }, sourceName = L["Multiple"] },
}
Parrot:RegisterCombatEvent{
	category = "Outgoing",
	subCategory = L["Pet heals"],
	name = "Pet heals over time",
	localName = L["Pet heals over time"],
	defaultTag = PET .. " ([Skill] - [Name]) +[Amount]",
	canCrit = true, -- Pets cannot crit-heal (or can they?)
	combatLogEvents = {
		{
		eventType = "SPELL_PERIODIC_HEAL",
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags,spellId, spellName, spellSchool, amount, overheal, critical)
			if srcGUID ~= (UnitGUID("pet") or 0) then
				return nil
			end

			local info = newList()
			info.damageType = SchoolParser[school]
			info.spellID = spellId
			info.recipientID = dstGUID
			info.recipientName = dstName
			info.sourceID = srcGUID
			info.sourceName = srcName
			info.amount = amount
			info.realAmount = amount-overheal
			info.abilityName = spellName
			info.isCrit = (critical ~= nil)

			info.isHoT = true
			info.overhealAmount = overheal

			return info
		end,
		},
	},
	tagTranslations = {
		Name = "destName",
		Skill = retrieveAbilityName,
		Amount = "realAmount",
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Name = L["The name of the unit that your pet healed."],
		Skill = L["The spell or ability that the pet used to heal."],
		Amount = L["The amount of healing done."],
	},
	throttle = { "DoTs and HoTs", 'abilityName', { 'throttleCount', 'isCrit', healThrottleFunc }, sourceName = L["Multiple"] },
	color = "00ff00", -- green
	filterType = { "Incoming heals", 'realAmount' },
}

------------------------------------------------------------------------------
-- Notification events -------------------------------------------------------
------------------------------------------------------------------------------

Parrot:RegisterThrottleType("Power gain/loss", L["Power gain/loss"], 3)
Parrot:RegisterFilterType("Power gain", L["Power gain"], 0)

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Power change"],
	name = "Power gain",
	localName = L["Power gain"],
	defaultTag = "+[Amount] [Type]",
	combatLogEvents = {
		{
			eventType = "SPELL_ENERGIZE",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, powerType)
				if dstGUID ~= UnitGUID("player") then
					return nil
				end

				local info = newList()
				info.spellID = spellId
				info.damageType = SchoolParser[spellSchool]
				info.recipientID = srcGUID
				info.sourceName = srcName
				info.sourceID = srcGUID
				info.abilityName = spellName
				info.attributeLocal = PowerTypeParser[powerType]
				info.amount = amount
				info.isCrit = (critical ~= nil)
				info.isCrushing = (crushing ~= nil)
				info.isGlancing = (glancing ~= nil)



				return info

			end,
		},
		{
			eventType = "SPELL_PERIODIC_ENERGIZE",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, powerType)
				if dstGUID ~= UnitGUID("player") then
					return nil
				end

				local info = newList()
				info.spellID = spellId
				info.damageType = SchoolParser[spellSchool]
				info.recipientID = srcGUID
				info.sourceName = srcName
				info.sourceID = srcGUID
				info.abilityName = spellName
				info.attributeLocal = PowerTypeParser[powerType]
				info.amount = amount
				info.isCrit = (critical ~= nil)
				info.isCrushing = (crushing ~= nil)
				info.isGlancing = (glancing ~= nil)



				return info

			end,
		},
		{
			eventType = "SPELL_LEECH",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, powerType)
				if srcGUID ~= UnitGUID("player") then
					return nil
				end

				local info = newList()
				info.spellID = spellId
				info.damageType = SchoolParser[spellSchool]
				info.recipientID = srcGUID
				info.sourceName = srcName
				info.sourceID = srcGUID
				info.abilityName = spellName
				info.attributeLocal = PowerTypeParser[powerType]
				info.amount = amount
				info.isCrit = (critical ~= nil)
				info.isCrushing = (crushing ~= nil)
				info.isGlancing = (glancing ~= nil)



				return info

			end,
		},
		{
			eventType = "SPELL_PERIODIC_LEECH",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, powerType)
				if srcGUID ~= UnitGUID("player") then
					return nil
				end

				local info = newList()
				info.spellID = spellId
				info.damageType = SchoolParser[spellSchool]
				info.recipientID = srcGUID
				info.sourceName = srcName
				info.sourceID = srcGUID
				info.abilityName = spellName
				info.attributeLocal = PowerTypeParser[powerType]
				info.amount = amount
				info.isCrit = (critical ~= nil)
				info.isCrushing = (crushing ~= nil)
				info.isGlancing = (glancing ~= nil)



				return info

			end,
		},
	},
	tagTranslations = {
		Amount = function(info)
			return info.amountGained or info.amount
		end,

		Type = function(info)
			return info.attributeGainedLocal or info.attributeLocal
		end,

		Skill = retrieveAbilityName,
		Name = function(info)
			return info.sourceGainedName and info.recipientName or info.sourceName
		end,

		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Amount = L["The amount of power gained."],
		Type = L["The type of power gained (Mana, Rage, Energy)."],
		Skill = L["The ability or spell used to gain power."],
		Name = L["The character that the power comes from."],
	},
	color = "ffff00", -- yellow
	throttle = { "Power gain/loss", 'abilityName', { 'throttleCount', function(info)
		local numNorm = info.throttleCount or 0
		if numNorm == 1 then
			-- just one gain
			return nil
		else -- >= 2
			return L[" (%d gains)"]:format(numNorm)
		end
	end }, sourceName = L["Multiple"], recipientName = L["Multiple"] },
	filterType = { "Power gain", function(info)
		return info.amountGained or info.amount
	end}
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Power change"],
	name = "Power loss",
	localName = L["Power loss"],
	defaultTag = "-[Amount] [Type]",
	combatLogEvents = {
		{
		eventType = "SPELL_DRAIN",
		func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, powerType)
			if dstGUID ~= UnitGUID("player") then
				return nil
			end

			local info = newList()
			info.spellID = spellId
			info.damageType = SchoolParser[spellSchool]
			info.recipientID = srcGUID
			info.sourceName = srcName
			info.sourceID = srcGUID
			info.abilityName = spellName
			info.attributeLocal = PowerTypeParser[powerType]
			info.amount = amount
			info.isCrit = (critical ~= nil)
			info.isCrushing = (crushing ~= nil)
			info.isGlancing = (glancing ~= nil)



			return info

		end,
		},
		{
			eventType = "SPELL_LEECH",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, powerType)
				if dstGUID ~= UnitGUID("player") then
					return nil
				end

				local info = newList()
				info.spellID = spellId
				info.damageType = SchoolParser[spellSchool]
				info.recipientID = srcGUID
				info.sourceName = srcName
				info.sourceID = srcGUID
				info.abilityName = spellName
				info.attributeLocal = PowerTypeParser[powerType]
				info.amount = amount
				info.isCrit = (critical ~= nil)
				info.isCrushing = (crushing ~= nil)
				info.isGlancing = (glancing ~= nil)



				return info

			end,
		},
		{
			eventType = "SPELL_PERIODIC_LEECH",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, powerType)
				if dstGUID ~= UnitGUID("player") then
					return nil
				end

				local info = newList()
				info.spellID = spellId
				info.damageType = SchoolParser[spellSchool]
				info.recipientID = srcGUID
				info.sourceName = srcName
				info.sourceID = srcGUID
				info.abilityName = spellName
				info.attributeLocal = PowerTypeParser[powerType]
				info.amount = amount
				info.isCrit = (critical ~= nil)
				info.isCrushing = (crushing ~= nil)
				info.isGlancing = (glancing ~= nil)



				return info

			end,
		},
	},
	tagTranslations = {
		Amount = "amount",
		Type = "attributeLocal",
		Skill = retrieveAbilityName,
		Name = "sourceName",
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationsHelp = {
		Amount = L["The amount of power lost."],
		Type = L["The type of power lost (Mana, Rage, Energy)."],
		Skill = L["The ability or spell take away your power."],
		Name = L["The character that caused the power loss."],
	},
	color = "ffff00", -- yellow
	throttle = { "Power gain/loss", 'abilityName', { 'throttleCount', function(info)
		local numNorm = info.throttleCount or 0
		if numNorm == 1 then
			-- just one loss
			return nil
		else -- >= 2
			return L[" (%d losses)"]:format(numNorm)
		end
	end }, sourceName = L["Multiple"] },
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Combo points"],
	name = "Combo point gain",
	localName = L["Combo point gain"],
	defaultTag = L["[Num] CP"],
	tagTranslations = {
		Num = 1
	},
	tagTranslationHelp = {
		Num = L["The current number of combo points."]
	},
	color = "ff7f00", -- orange
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Combo points"],
	name = "Combo points full",
	localName = L["Combo points full"],
	defaultTag = L["[Num] CP Finish It!"],
	tagTranslations = {
		Num = 1
	},
	tagTranslationHelp = {
		Num = L["The current number of combo points."]
	},
	color = "ff7f00", -- orange
}

onEnableFuncs[#onEnableFuncs+1] = function()
	mod:AddEventListener("UNIT_COMBO_POINTS", function()
		local num = GetComboPoints("player","target")
		if num == 0 then
			return
		end
		local info = newList(num)
		Parrot:TriggerCombatEvent("Notification", num == 5 and "Combo points full" or "Combo point gain", info)
		info = del(info)
	end)
end

Parrot:RegisterCombatEvent{
	category = "Notification",
	name = "Honor gains",
	localName = L["Honor gains"],
	defaultTag = "+[Amount] " .. HONOR_CONTRIBUTION_POINTS,

	tagTranslations = {
		Amount = "amount",
-- 		Name = "sourceName", -- not supported anymore
-- 		Rank = "sourceRank", -- not supported anymore
	},
	tagTranslationHelp = {
		Amount = L["The amount of honor gained."],
		-- Name = L["The name of the enemy slain."],
		-- Rank = L["The rank of the enemy slain."],
	},
	color = "7f7fb2", -- blue-gray
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Reputation"],
	name = "Reputation gains",
	localName = L["Reputation gains"],
	defaultTag = "+[Amount] " .. REPUTATION .. " ([Faction])",
	parserEvent = {
		eventType = "Reputation",
		amount_gt = 0,
	},
	tagTranslations = {
		Amount = "amount",
		Faction = "faction",
	},
	tagTranslationHelp = {
		Amount = L["The amount of reputation gained."],
		Faction = L["The name of the faction."],
	},
	color = "7f7fb2", -- blue-gray
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Reputation"],
	name = "Reputation losses",
	localName = L["Reputation losses"],
	defaultTag = "-[Amount] " .. REPUTATION .. " ([Faction])",
	parserEvent = {
		eventType = "Reputation",
		amount_lt = 0,
	},
	tagTranslations = {
		Amount = function(info) return info.amount end,
		Faction = "faction",
	},
	tagTranslationHelp = {
		Amount = L["The amount of reputation lost."],
		Faction = L["The name of the faction."],
	},
	color = "7f7fb2", -- blue-gray
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	name = "Skill gains",
	localName = L["Skill gains"],
	defaultTag = "[Skill]: [Amount]",
	parserEvent = {
		eventType = "Skill",
	},
	tagTranslations = {
		Skill = retrieveAbilityName,
		Amount = "amount",
	},
	tagTranslationHelp = {
		Skill = L["The skill which experienced a gain."],
		Amount = L["The amount of skill points currently."]
	},
	color = "5555ff", -- semi-light blue
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	name = "Experience gains",
	localName = L["Experience gains"],
	defaultTag = "[Amount] " .. XP,
	parserEvent = {
		eventType = "Experience",
		recipientID = "player",
	},
	tagTranslations = {
		-- Name = "sourceName", -- not supported anymore by the event
		Amount = "amount",
	},
	tagTranslationHelp = {
		-- Name = L["The name of the enemy slain."], not supported anymore by the event
		Amount = L["The amount of experience points gained."]
	},
	color = "bf4ccc", -- magenta
	sticky = true,
	defaultDisabled = true,
}

Parrot:RegisterThrottleType("Killing blows", L["Killing blows"], 0.1, true)

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Killing blows"],
	name = "Player killing blows",
	localName = L["Player killing blows"],
	defaultTag = L["Killing Blow!"] .. " ([Name])",
	combatLogEvents = {
		{
			eventType = "PARTY_KILL",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags)
				if srcGUID ~= UnitGUID("player") or not UnitIsPVP(dstName) then
					return nil
				end
				local info = newList()
				info.recipientID = dstGUID
				info.recipientName = dstName
				info.sourceName = srcName
				info.sourceID = srcGUID


				return info
			end
		}
	},
	tagTranslations = {
		Name = "recipientName",
		Skill = function(info) return info.abilityName or PLAYERSTAT_MELEE_COMBAT end,
	},
	tagTranslationHelp = {
		Name = L["The name of the enemy slain."],
		Skill = L["The spell or ability used to slay the enemy."],
	},
	color = "5555ff", -- semi-light blue
	sticky = true,

	throttle = { "Killing blows", 'sourceID', { 'throttleCount', function(info)
		local numNorm = info.throttleCount or 0
		if numNorm == 1 then
			-- just one hit
			return nil
		else -- >= 2
			 return string.format(" (%d)",format(numNorm))
		end

	end }, recipientName = L["Multiple"] },
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Killing blows"],
	name = "NPC killing blows",
	localName = L["NPC killing blows"],
	defaultTag = L["Killing Blow!"] .. " ([Name])",
	combatLogEvents = {
		{
			eventType = "PARTY_KILL",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags)
				if srcGUID ~= UnitGUID("player") or UnitIsPVP(dstName) then
					return nil
				end
				local info = newList()
				info.recipientID = dstGUID
				info.recipientName = dstName
				info.sourceName = srcName
				info.sourceID = srcGUID


				return info
			end
		}
	},
	tagTranslations = {
		Name = "recipientName",
		Skill = function(info) return info.abilityName or PLAYERSTAT_MELEE_COMBAT end,
	},
	tagTranslationHelp = {
		Name = L["The name of the enemy slain."],
		Skill = L["The spell or ability used to slay the enemy."],
	},
	color = "5555ff", -- semi-light blue
	sticky = true,
	throttle = { "Killing blows", 'sourceID', { 'throttleCount', function(info)

		local numNorm = info.throttleCount or 0
		if numNorm == 1 then
			-- just one hit
			return nil
		else -- >= 2
			 return string.format(" (%d)",format(numNorm))
		end

	end }, recipientName = L["Multiple"] },
}

if playerClass == "WARLOCK" then
	Parrot:RegisterCombatEvent{
		category = "Notification",
		name = "Soul shard gains",
		localName = L["Soul shard gains"],
		defaultTag = "+[Name]",
		tagTranslations = {
			Name = "itemName",
			Icon = function(info)
				local itemLink = info.itemLink
				if itemLink then
					local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemLink)
					return texture
				end
			end
		},
		tagTranslationHelp = {
			Name = L["The name of the soul shard."],
		},
		color = "990099", -- purple
		sticky = true,
	}
end

Parrot:RegisterCombatEvent{
	category = "Notification",
	name = "Extra attacks",
	localName = L["Extra attacks"],
	defaultTag = L["%s!"]:format("[Skill]"),
	combatLogEvents = {
		{
			eventType = "SPELL_EXTRA_ATTACKS",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount)
				if srcGUID ~= UnitGUID("player") then
					return nil
				end
				local info = newList()
				info.spellID = spellId
				info.recipientID = dstGUID
				info.recipientName = dstName
				info.sourceName = srcName
				info.sourceID = srcGUID
				info.abilityName = spellName
				info.damageType = SchoolParser[spellSchool]
				info.amount = amount


				return info

			end,
		},
	},
	tagTranslations = {
		Skill = retrieveAbilityName,
		Icon = retrieveIconFromAbilityName,
	},
	tagTranslationHelp = {
		Skill = L["The name of the spell or ability which provided the extra attacks."],
	},
	color = "ffff00", -- yellow
	sticky = true,
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	name = "Dispel",
	localName = L["Dispel"],
	defaultTag = "[Skill] -[ExtraSkill]",
	combatLogEvents = {
		{
			eventType = "SPELL_DISPEL",
			check = function(srcGUID)
					return srcGUID == UnitGUID("player")
				end,
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, extraSpellID, extraSpellName, extraSchool, auraType)
					local info = {
						spellID = spellId,
						sourceID = srcGUID,
						sourceName = srcName,
						recipientID = dstGUID,
						recpientName = dstName,
						abilityName = spellName,
						extraAbilityName = extraSpellName,
						damageType = SchoolParser[school] or SchoolParser[spellSchool],
					}
					return info
				end,
		},
	},
	tagTranslations = {
		Skill = retrieveAbilityName,
		Icon = retrieveIconFromAbilityName,
		ExtraSkill = "extraAbilityName",
	},
	tagTranslationHelp = {
		Skill = L["The name of the spell that has been used for dispelling."],
		ExtraSkill = L["The name of the spell that has been dispelled."],
	},
	defaultDisabled = true,
	color = "ffffff" -- white
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	name = "Dispel fail",
	localName = L["Dispel fail"],
	defaultTag = L["%s failed"]:format("[Skill]"),
	combatLogEvents = {
		{
			eventType = "SPELL_DISPEL_FAILED",
			check = function(srcGUID)
					return srcGUID == UnitGUID("player")
				end,
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, extraSpellID, extraSpellName, extraSchool)
					local info = {
						spellID = spellId,
						sourceID = srcGUID,
						sourceName = srcName,
						recipientID = dstGUID,
						recpientName = dstName,
						abilityName = spellName,
						extraAbilityName = extraSpellName,
						damageType = SchoolParser[school] or SchoolParser[spellSchool]
					}
					return info
				end,
		},
	},
	tagTranslations = {
		Skill = retrieveAbilityName,
		Icon = retrieveIconFromAbilityName,
		ExtraSkill = "extraAbilityName",
	},
	tagTranslationHelp = {
		Skill = L["The name of the spell that has been used for dispelling."],
		ExtraSkill = L["The name of the spell that has not been dispelled."],
	},
	defaultDisabled = true,
	sticky = true,
	color = "ffffff" -- white
}

Parrot:RegisterCombatEvent{
	category = "Outgoing",
	name = "Spell steal",
	localName = L["Spell steal"],
	defaultTag = L["%s stole %s"]:format("[Skill]", "[ExtraSkill]"),
	combatLogEvents = {
		{
			eventType = "SPELL_STOLEN",
			check = function(srcGUID)
					return srcGUID == UnitGUID("player")
				end,
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, extraSpellID, extraSpellName, extraSchool, auraType)
					local info = {
						spellID = spellId,
						sourceID = srcGUID,
						sourceName = srcName,
						recipientID = dstGUID,
						recpientName = dstName,
						abilityName = spellName,
						extraAbilityName = extraSpellName,
						damageType = SchoolParser[school] or SchoolParser[spellSchool]
					}
					return info
				end,
		},
	},
	tagTranslations = {
		Skill = retrieveAbilityName,
		Icon = retrieveIconFromAbilityName,
		ExtraSkill = "extraAbilityName",
	},
	tagTranslationHelp = {
		Skill = L["The name of the spell that has been used for stealing."],
		ExtraSkill = L["The name of the spell that has been stolen."],
	},
	defaultDisabled = true,
	color = "ffffff" -- white
}



Parrot:RegisterCombatEvent{
	category = "Incoming",
	name = "Dispel",
	localName = L["Dispel"],
	defaultTag = "[Skill] -[ExtraSkill]",
	combatLogEvents = {
		{
			eventType = "SPELL_DISPEL",
			check = function(_, _, _, dstGUID)
					return dstGUID == UnitGUID("player")
				end,
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, extraSpellID, extraSpellName, extraSchool, auraType)
					local info = {
						spellID = spellId,
						sourceID = srcGUID,
						sourceName = srcName,
						recipientID = dstGUID,
						recpientName = dstName,
						abilityName = spellName,
						extraAbilityName = extraSpellName,
						damageType = SchoolParser[school] or SchoolParser[spellSchool]
					}
					return info
				end,
		},
	},
	tagTranslations = {
		Skill = retrieveAbilityName,
		Icon = retrieveIconFromAbilityName,
		ExtraSkill = "extraAbilityName",
	},
	tagTranslationHelp = {
		Skill = L["The name of the spell that has been used for dispelling."],
		ExtraSkill = L["The name of the spell that has been dispelled."],
	},
	defaultDisabled = true,
	sticky = true,
	color = "ffffff" -- white
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	name = "Dispel fail",
	localName = L["Dispel fail"],
	defaultTag = L["%s failed"]:format("[Skill]"),
	combatLogEvents = {
		{
			eventType = "SPELL_DISPEL_FAILED",
			check = function(_, _, _, dstGUID)
					return dstGUID == UnitGUID("player")
				end,
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, extraSpellID, extraSpellName, extraSchool)
					local info = {
						spellID = spellId,
						sourceID = srcGUID,
						sourceName = srcName,
						recipientID = dstGUID,
						recpientName = dstName,
						abilityName = spellName,
						extraAbilityName = extraSpellName,
						damageType = SchoolParser[school] or SchoolParser[spellSchool]
					}
					return info
				end,
		},
	},
	tagTranslations = {
		Skill = retrieveAbilityName,
		Icon = retrieveIconFromAbilityName,
		ExtraSkill = "extraAbilityName",
	},
	tagTranslationHelp = {
		Skill = L["The name of the spell that has been used for dispelling."],
		ExtraSkill = L["The name of the spell that has not been dispelled."],
	},
	defaultDisabled = true,
	color = "ffffff" -- white
}

Parrot:RegisterCombatEvent{
	category = "Incoming",
	name = "Spell steal",
	localName = L["Spell steal"],
	defaultTag = L["%s stole %s"]:format("[Skill]", "[ExtraSkill]"),
	combatLogEvents = {
		{
			eventType = "SPELL_STOLEN",
			check = function(_, _, _, dstGUID)
					return dstGUID == UnitGUID("player")
				end,
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, extraSpellID, extraSpellName, extraSchool, auraType)
					local info = {
						spellID = spellId,
						sourceID = srcGUID,
						sourceName = srcName,
						recipientID = dstGUID,
						recpientName = dstName,
						abilityName = spellName,
						extraAbilityName = extraSpellName,
						damageType = SchoolParser[school] or SchoolParser[spellSchool]
					}
					return info
				end,
		},
	},
	tagTranslations = {
		Skill = retrieveAbilityName,
		Icon = retrieveIconFromAbilityName,
		ExtraSkill = "extraAbilityName",
	},
	tagTranslationHelp = {
		Skill = L["The name of the spell that has been used for stealing."],
		ExtraSkill = L["The name of the spell that has been stolen."],
	},
	defaultDisabled = true,
	color = "ffffff" -- white
}
