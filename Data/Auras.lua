local Parrot = Parrot
local L = LibStub("AceLocale-3.0"):GetLocale("Parrot_Auras")

local newList, del = Parrot.newList, Parrot.del
local newDict = Parrot.newDict
local deepCopy = Parrot.deepCopy
local unpackDictAndDel = Parrot.unpackDictAndDel
local debug = Parrot.debug

local _G = _G
local PET = _G.PET

local bit_band = bit.band
local function checkFlags(flags1, flags2)
	return bit_band(flags1, flags2) == flags2
end

local HOSTILE = _G.COMBATLOG_OBJECT_REACTION_HOSTILE
local FRIENDLY = _G.COMBATLOG_OBJECT_REACTION_FRIENDLY

local TYPE_PET = _G.COMBATLOG_OBJECT_TYPE_PET
local CONTROL_PLAYER = _G.COMBATLOG_OBJECT_CONTROL_PLAYER
local AFFILIATION_MINE = _G.COMBATLOG_OBJECT_AFFILIATION_MINE

local PET_FLAGS = bit.bor(
	TYPE_PET,
	CONTROL_PLAYER,
	FRIENDLY,
	AFFILIATION_MINE
)

--[[
-- AURA-HACK for 3.3
--]]
local mod = Parrot:NewModule("Aura", "AceEvent-3.0")

-- only do player-buffs for now
-- aura-cache
local auras = {
	["player"] = {
		["BUFF"] = {},
		["DEBUFF"] = {},
	},
}

local auraActions = {
	["player"] = {
		["BUFF"] = {
			gain = {
				combat = "Buff gains",
				trigger = "Aura gain",
			},
			fade = {
				combat = "Buff fades",
				trigger = "Aura fade",
			},
			stackgain = {
				combat = "Buff stack gains",
				trigger = "Aura stack gain",
			},
		},
	},
}

function mod:OnInitialize()
	Parrot:RegisterDebugSpace("Aura-HACK")
	self:RegisterEvent("UNIT_AURA")
end

local function initialAuracheck(unit, btype)
	local i = 1
	while(true) do
		-- not beautiful, but ...
		local name, rank, icon, count, debuffType, duration, expirationTime,
			unitCaster, isStealable, shouldConsolidate, spellId =
				UnitAura(unit, i, btype == "BUFF" and "HELPFUL" or "HARMFUL")
		if not name then
			break;
		end
		-- add new aura
		auras[unit][btype][spellId] = count
		i = i + 1
	end
end

function mod:OnEnable()
	-- only do buffs for now
	initialAuracheck("player", "BUFF")
end

function mod:FireAuraTriggerCondition(unit, btype, event, info2)
	Parrot:FirePrimaryTriggerCondition(auraActions[unit][btype][event].trigger, info2, 0)
end

function mod:GetDebugHooks()
	return {
		FireAuraTriggerCondition = function(self, unit, btype, event, info2)
				return "Aura-HACK", event, info2
			end,
	}
end

local function checkAuras(unit, btype)
	--debug("check auras")
	local cache = deepCopy(auras[unit][btype])
	local uguid = UnitGUID(unit)
	local uname = UnitName(unit)
	local i = 1
	local deleteLater = false
	-- scan current auras
	while(true) do
		-- not beautiful, but ...
		local name, rank, icon, count, debuffType, duration, expirationTime,
			unitCaster, isStealable, shouldConsolidate, spellId =
				UnitAura(unit, i, btype == "BUFF" and "HELPFUL" or "HARMFUL")
		if not name then
			break;
		end
		debug("found buff/debuff ", name)
		local oldcount = cache[spellId]
		if oldcount then
			if oldcount > 0 and oldcount ~= count then
				local info2 = newDict("dstGUID", uguid, "spellId", spellId, "spellName", name, "amount", count, "auraType", btype, "force", true)
				mod:FireAuraTriggerCondition(unit, btype, "stackgain", info2)
				-- Parrot:FirePrimaryTriggerCondition(auraActions[unit][btype].stackgain.trigger, info2, 0)
				auras[unit][btype][spellId] = count
				info2 = del(info2)
			end
			-- still present
			-- TODO dirty workaround for buffs that can be present multiple
			-- times (like berserk)
			if spellId ~= 59620 then
				cache[spellId] = nil
			else
				deleteLater = true
			end
			debug(name, " is an old buff/debuff")
		else
			debug("new aura detected ", name)
			auras[unit][btype][spellId] = count
			local info2 = newDict("dstGUID", uguid, "spellId", spellId, "spellName", name, "amount", count, "auraType", btype, "force", true)
			if count > 0 then
				-- trigger combatevent
				mod:FireAuraTriggerCondition(unit, btype, "gain", info2)
				mod:FireAuraTriggerCondition(unit, btype, "stackgain", info2)
				-- Parrot:SaveDebug("Aura-HACK", "Aura stackable gain", info2)
				-- Parrot:FirePrimaryTriggerCondition(auraActions[unit][btype].gain.trigger, info2, 0)
				-- Parrot:FirePrimaryTriggerCondition(auraActions[unit][btype].stackgain.trigger, info2, 0)
			else
				-- Parrot:SaveDebug("Aura-HACK", "Aura gain", info2)
				mod:FireAuraTriggerCondition(unit, btype, "gain", info2)
				--Parrot:FirePrimaryTriggerCondition(auraActions[unit][btype].gain.trigger, info2, 0)
			end
			info2 = del(info2)
		end
		i = i + 1
	end

	if deleteLater then
		cache[59620] = nil
	end

	-- scan for missing auras
	for k,v in pairs(cache) do
		local name = GetSpellInfo(k)
		debug("aura faded ", name)
		local info2 = newDict("dstGUID", uguid, "spellId", k, "spellName", name, "auraType", btype, "force", true)
		-- Parrot:SaveDebug("Aura-HACK", "Aura fade", info2)
		mod:FireAuraTriggerCondition(unit, btype, "fade", info2)
		--Parrot:FirePrimaryTriggerCondition(auraActions[unit][btype].fade.trigger, info2, 0)
		auras[unit][btype][k] = nil
		info2 = del(info2)
	end

	cache = del(cache)

end

function mod:UNIT_AURA(_, unit)
	--debug("UNIT_AURA occured - ", unit)
	local tbl = auras[unit]
	if not tbl then
		return
	end
	checkAuras(unit, "BUFF")
end

--[[
-- end of AURA-HACK for 3.3
--]]

local function parseAura(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)

	local info = newList()
	info.spellID = spellId
	info.abilityName = spellName
	info.sourceID = srcGUID
	info.sourceName = srcName
	info.recipientID = dstGUID
	info.recipientName = dstName
	info.icon = select(3, GetSpellInfo(spellId))
	info.amount = amount
	return info

end

local function retrieveDestName(info)
	if not info.recipientName then return end
	if Parrot.db1.profile.showNameRealm then
		return info.recipientName
	else
		return info.recipientName:gsub("-.*", "")
	end
end

--[[============================================================================
-- Players Auras
--============================================================================]]

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Buff gains",
	localName = L["Buff gains"],
	defaultTag = "([Name])",
	combatLogEvents = {
		SPELL_AURA_APPLIED = {
			check = function(_, _, _, dstGUID, _, _, _, _, _, auraType)
					return auraType == "BUFF" and dstGUID == UnitGUID("player")
				end,
			func = parseAura,
		},
	},
	tagTranslations = {
		Name = "abilityName",
		Icon = "icon",
	},
	tagTranslationsHelp = {
		Name = L["The name of the buff gained."],
	},
	color = "b2b200", -- dark yellow
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Debuff gains",
	localName = L["Debuff gains"],
	defaultTag = "([Name])",
	combatLogEvents = {
		SPELL_AURA_APPLIED = {
			check = function(_, _, _, dstGUID, _, _, _, _, _, auraType)
					return auraType == "DEBUFF" and dstGUID == UnitGUID("player")
				end,
			func = parseAura,
		},
	},
	tagTranslations = {
		Name = "abilityName",
		Icon = "icon",
	},
	tagTranslationsHelp = {
		Name = L["The name of the debuff gained."],
	},
	color = "007f7f", -- dark cyan
}


Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Buff stack gains",
	localName = L["Buff stack gains"],
	defaultTag = "([Name] -[Amount]-)",
	combatLogEvents = {
		SPELL_AURA_APPLIED_DOSE = {
			check = function(_, _, _, dstGUID, _, _, _, _, _, auraType)
					return auraType == "BUFF" and dstGUID == UnitGUID("player")
				end,
			func = parseAura,
		}
	},
	tagTranslations = {
		Name = "abilityName",
		Icon = "icon",
		Amount = "amount",
	},
	tagTranslationsHelp = {
		Name = L["The name of the buff gained."],
		Name = L["New Amount of stacks of the buff."],
	},
	color = "b2b200", -- dark yellow
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Debuff stack gains",
	localName = L["Debuff stack gains"],
	defaultTag = "([Name] -[Amount]-)",
	combatLogEvents = {
		SPELL_AURA_APPLIED_DOSE = {
			check = function(_, _, _, dstGUID, _, _, _, _, _, auraType)
					return auraType == "DEBUFF" and dstGUID == UnitGUID("player")
				end,
			func = parseAura,
		}
	},
	tagTranslations = {
		Name = "abilityName",
		Icon = "icon",
		Amount = "amount",
	},
	tagTranslationsHelp = {
		Name = L["The name of the debuff gained."],
		Name = L["New Amount of stacks of the debuff."],
	},
	color = "007f7f", -- dark cyan
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Buff fades",
	localName = L["Buff fades"],
	defaultTag = "-([Name])",
	combatLogEvents = {
		SPELL_AURA_REMOVED = {
			check = function(_, _, _, dstGUID, _, _, _, _, _, auraType)
					return auraType == "BUFF" and dstGUID == UnitGUID("player")
				end,
			func = parseAura,
		},
	},
	tagTranslations = {
		Name = "abilityName",
		Icon = "icon",
	},
	tagTranslationsHelp = {
		Name = L["The name of the buff lost."],
	},
	color = "e5e500", -- yellow
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Debuff fades",
	localName = L["Debuff fades"],
	defaultTag = "-([Name])",
	combatLogEvents = {
		SPELL_AURA_REMOVED = {
			check = function(_, _, _, dstGUID, _, _, _, _, _, auraType)
					return auraType == "DEBUFF" and dstGUID == UnitGUID("player")
				end,
			func = parseAura,
		},
	},
	tagTranslations = {
		Name = "abilityName",
		Icon = "icon",
	},
	tagTranslationsHelp = {
		Name = L["The name of the debuff lost."],
	},
	color = "00d8d8", -- cyan
}

--[[============================================================================
-- Target's Auras
--============================================================================]]
Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Target buff gains",
	localName = L["Target buff gains"],
	defaultTag = "[Unitname] gains [Buffname]",
	combatLogEvents = {
		SPELL_AURA_APPLIED = {
			check = function(_, _, _, dstGUID, _, _, _, _, _, auraType)
					return auraType == "BUFF" and dstGUID == UnitGUID("target")
				end,
			func = parseAura,
		}
	},
	tagTranslations = {
		Buffname = "abilityName",
		Icon = "icon",
		Unitname = "recipientName",
	},
	tagTranslationsHelp = {
		Buffname = L["The name of the buff gained."],
		Unitname = L["The name of the unit that gained the buff."],
	},
	color = "b2b200", -- dark yellow
	defaultDisabled = true,
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Target buff stack gains",
	localName = L["Target buff stack gains"],
	defaultTag = "[Unitname] gains [Buffname] -[Amount]-)",
	combatLogEvents = {
		SPELL_AURA_APPLIED_DOSE = {
			check = function(_, _, _, dstGUID, _, _, _, _, _, auraType)
					return auraType == "BUFF" and dstGUID == UnitGUID("target")
				end,
			func = parseAura,
		}
	},

	tagTranslations = {
		Buffname = "abilityName",
		Icon = "icon",
		Amount = "amount",
		Unitname = "dstName",
	},
	tagTranslationsHelp = {
		Buffname = L["The name of the buff gained."],
		Amount = L["New Amount of stacks of the buff."],
		Unitname = L["The name of the unit that gained the buff."],
	},
	color = "b2b200", -- dark yellow
	defaultDisabled = true,
}

--[[============================================================================
-- Pet's Auras
--============================================================================]]

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Pet buff gains",
	localName = L["Pet buff gains"],
	defaultTag = PET .. " ([Spell])",
	combatLogEvents = {
		SPELL_AURA_APPLIED = {
			check = function(_, _, _, dstGUID, _, dstFlags, _, _, _, auraType)
					return auraType == "BUFF" and checkFlags(dstFlags, PET_FLAGS)
				end,
			func = parseAura,
		},
	},
	tagTranslations = {
		Name = retrieveDestName,
		Spell = "abilityName",
		Icon = "icon",
	},
	tagTranslationsHelp = {
		Name = L["The name of the pet that gained the buff"],
		Spell = L["The name of the buff gained."],
	},
	color = "b2b200", -- dark yellow
	defaultDisabled = true,
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Pet debuff gains",
	localName = L["Pet debuff gains"],
	defaultTag = PET .. " ([Spell])",
	combatLogEvents = {
		SPELL_AURA_APPLIED = {
			check = function(_, _, _, dstGUID, _, dstFlags, _, _, _, auraType)
					return auraType == "DEBUFF" and checkFlags(dstFlags, PET_FLAGS)
				end,
			func = parseAura,
		},
	},
	tagTranslations = {
		Name = retrieveDestName,
		Spell = "abilityName",
		Icon = "icon",
	},
	tagTranslationsHelp = {
		Name = L["The name of the pet that gained the debuff"],
		Spell = L["The name of the debuff gained."],
	},
	color = "007f7f", -- dark cyan
	defaultDisabled = true,
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Pet buff fades",
	localName = L["Pet buff fades"],
	defaultTag = PET .. " -([Spell])",
	combatLogEvents = {
		SPELL_AURA_REMOVED = {
			check = function(_, _, _, dstGUID, _, dstFlags, _, _, _, auraType)
					return auraType == "BUFF" and checkFlags(dstFlags, PET_FLAGS)
				end,
			func = parseAura,
		},
	},
	tagTranslations = {
		Name = retrieveDestName,
		Spell = "abilityName",
		Icon = "icon",
	},
	tagTranslationsHelp = {
		Name = L["The name of the pet that lost the buff"],
		Spell = L["The name of the buff lost."],
	},
	color = "e5e500", -- yellow
	defaultDisabled = true,
}


Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Pet debuff fades",
	localName = L["Pet debuff fades"],
	defaultTag = PET .. " -([Spell])",
	combatLogEvents = {
		SPELL_AURA_REMOVED = {
			check = function(_, _, _, dstGUID, _, dstFlags, _, _, _, auraType)
					return auraType == "DEBUFF" and checkFlags(dstFlags, PET_FLAGS)
				end,
			func = parseAura,
		},
	},
	tagTranslations = {
		Name = retrieveDestName,
		Spell = "abilityName",
		Icon = "icon",
	},
	tagTranslationsHelp = {
		Name = L["The name of the pet that lost the debuff"],
		Spell = L["The name of the debuff gained."],
	},
	color = "00d8d8", -- cyan
	defaultDisabled = true,
}

--[[============================================================================
-- Enemy's Auras
--============================================================================]]

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Enemy buff gains",
	localName = L["Enemy buff gains"],
	defaultTag = "[Name] ([Spell])",
	combatLogEvents = {
		SPELL_AURA_APPLIED = {
			check = function(_, _, _, dstGUID, _, dstFlags, _, _, _, auraType)
					return auraType == "BUFF" and checkFlags(dstFlags, HOSTILE)
				end,
			func = parseAura,
		},
	},
	tagTranslations = {
		Name = retrieveDestName,
		Spell = "abilityName",
		Icon = "icon",
	},
	tagTranslationsHelp = {
		Name = L["The enemy that gained the buff"],
		Spell = L["The name of the buff gained."],
	},
	color = "b2b200", -- dark yellow
	defaultDisabled = true,
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Enemy debuff gains",
	localName = L["Enemy debuff gains"],
	defaultTag = "[Name] ([Spell])",
	combatLogEvents = {
		SPELL_AURA_APPLIED = {
			check = function(_, _, _, dstGUID, _, dstFlags, _, _, _, auraType)
					return auraType == "DEBUFF" and checkFlags(dstFlags, HOSTILE)
				end,
			func = parseAura,
		},
	},
	tagTranslations = {
		Name = retrieveDestName,
		Spell = "abilityName",
		Icon = "icon",
	},
	tagTranslationsHelp = {
		Name = L["The enemy that gained the debuff"],
		Spell = L["The name of the debuff gained."],
	},
	color = "007f7f", -- dark cyan
	defaultDisabled = true,
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Enemy buff fades",
	localName = L["Enemy buff fades"],
	defaultTag = "[Name] -([Spell])",
	combatLogEvents = {
		SPELL_AURA_REMOVED = {
			check = function(_, _, _, dstGUID, _, dstFlags, _, _, _, auraType)
					return auraType == "BUFF" and checkFlags(dstFlags, HOSTILE)
				end,
			func = parseAura,
		},
	},
	tagTranslations = {
		Name = retrieveDestName,
		Spell = "abilityName",
		Icon = "icon",
	},
	tagTranslationsHelp = {
		Name = L["The enemy that lost the buff"],
		Spell = L["The name of the buff lost."],
	},
	color = "e5e500", -- yellow
	defaultDisabled = true,
}


Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Enemy debuff fades",
	localName = L["Enemy debuff fades"],
	defaultTag = "[Name] -([Spell])",
	combatLogEvents = {
		SPELL_AURA_REMOVED = {
			check = function(_, _, _, dstGUID, _, dstFlags, _, _, _, auraType)
					return auraType == "DEBUFF" and checkFlags(dstFlags, HOSTILE)
				end,
			func = parseAura,
		},
	},
	tagTranslations = {
		Name = retrieveDestName,
		Spell = "abilityName",
		Icon = "icon",
	},
	tagTranslationsHelp = {
		Name = L["The enemy that lost the debuff"],
		Spell = L["The name of the debuff lost."],
	},
	color = "00d8d8", -- cyan
	defaultDisabled = true,
}

--[[============================================================================
-- Item Buffs
--============================================================================]]
local function parseItembuff(srcGUID, srcName, srcFlags, dstGUID, dstName,
		dstFlags, spellName, itemId, itemName)
	local info = newList()
	info.itemId = itemId
	info.abilityName = spellName
	info.itemName = itemName
	return info
end

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Item buff gains",
	localName = L["Item buff gains"],
	defaultTag = "([Name])",
	combatLogEvents = {
		ENCHANT_APPLIED = {
			check = function(_, _, _, dstGUID)
					return dstGUID == UnitGUID("player")
				end,
			func = parseItembuff,
		},
	},
	tagTranslations = {
		Name = "abilityName",
		ItemName = "itemName",
		Icon = function(info)
			return GetItemIcon(info.itemId)
		end,
	},
	tagTranslationsHelp = {
		Name = L["The name of the item buff gained."],
		ItemName = L["The name of the item, the buff has been applied to."],
	},
	color = "b2b2b2", -- gray
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Item buff fades",
	localName = L["Item buff fades"],
	defaultTag = "-([Name])",
	combatLogEvents = {
		ENCHANT_REMOVED = {
			check = function(_, _, _, dstGUID)
					return dstGUID == UnitGUID("player")
				end,
			func = parseItembuff,
		},
	},
	tagTranslations = {
		Name = "abilityName",
		ItemName = "itemName",
		Icon = function(info)
			return GetItemIcon(info.itemId)
		end,
	},
	tagTranslationsHelp = {
		Name = L["The name of the item buff lost."],
		ItemName = L["The name of the item, the buff has faded from."],
	},
	color = "e5e5e5", -- light gray
}



local function compareUnitAndSpell(ref, info)
	if not ref.unit or not ref.spell or not info.dstGUID then
		debug("bailout, incomplete ref")
		return false
	end

	if info.dstGUID == UnitGUID("player") and info.auraType == "BUFF" and not info.force then
		debug("this event should be handled with the UNIT_AURA-hack")
		return
	end

	local good = (info.dstGUID == UnitGUID(ref.unit)) and (ref.auraType == info.auraType)
	if good then
		if type(ref.spell) == 'number' then
			return ref.spell == info.spellId
		else
			return ref.spell == info.spellName
		end
	end
	return false
end

local unitChoices = {
	["player"] = PLAYER,
	["focus"] = FOCUS,
	["target"] = TARGET,
	["pet"] = PET,
}

local auraTypeChoices = {
	["BUFF"] = L["Buff"],
	["DEBUFF"] = L["Debuff"],
}

local function parseSpell(arg)
	return tostring(arg or "")
end
local function saveSpell(arg)
	return tonumber(arg) or arg
end

Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Aura gain",
	localName = L["Aura gain"],
	combatLogEvents = {
		{
			eventType = "SPELL_AURA_APPLIED",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				return newDict(
					"spellId", spellId,
					"spellName", spellName,
					"dstGUID", dstGUID,
					"auraType", auraType
				)
			end,
		},
	},
	defaultParam = {
		unit = "player",
		auraType = "BUFF",
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
			spell = {
				name = L["Spell"],
				desc = L["Buff name or spell id"],
				type = 'string',
				usage = "<Buff name or spell id>",
				save = saveSpell,
				parse = parseSpell,
			},
			auraType = {
				name = L["Aura type"],
				desc = L["Type of the aura"],
				type = 'select',
				values = auraTypeChoices,
			},
		},
	},
	check = compareUnitAndSpell,
}

Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Aura stack gain",
	localName = L["Aura stack gain"],
	combatLogEvents = {
		{
			eventType = "SPELL_AURA_APPLIED_DOSE",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				return newDict(
					"spellId", spellId,
					"spellName", spellName,
					"dstGUID", dstGUID,
					"auraType", auraType,
					"amount", amount
				)
			end,
		},
	},
	defaultParam = {
		unit = "player",
		auraType = "BUFF",
		amount = 5,
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
			spell = {
				name = L["Spell"],
				desc = L["Buff name or spell id"],
				type = 'string',
				usage = "<Buff name or spell id>",
				save = saveSpell,
				parse = parseSpell,
			},
			amount = {
				name = L["Amount"],
				desc = L["Amount of stacks of the aura"],
				type = 'number',
				min = 1,
				max = 100,
				step = 1,
			},
			auraType = {
				name = L["Aura type"],
				desc = L["Type of the aura"],
				type = 'select',
				values = auraTypeChoices,
			},
		},
	},
	check = function(ref, info)
			if not ref.amount then
				return false
			end
			return compareUnitAndSpell(ref, info) and ref.amount == info.amount
		end,
}

Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Aura fade",
	localName = L["Aura fade"],
	combatLogEvents = {
		{
			eventType = "SPELL_AURA_REMOVED",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				return newDict(
					"spellId", spellId,
					"spellName", spellName,
					"dstGUID", dstGUID,
					"auraType", auraType
				)
			end,
		},
	},
	defaultParam = {
		unit = "player",
		auraType = "BUFF",
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
			spell = {
				name = L["Spell"],
				desc = L["Buff name or spell id"],
				type = 'string',
				usage = "<Buff name or spell id>",
				save = saveSpell,
				parse = parseSpell,
			},
			auraType = {
				name = L["Aura type"],
				desc = L["Type of the aura"],
				type = 'select',
				values = auraTypeChoices,
			},
		},
	},
	check = compareUnitAndSpell,
}

local function checkItemBuff(ref, info)
	if ref.unit and ref.spell then
		return ref.spell == info.spellName and UnitGUID(ref.unit) == info.dstGUID
	else
		return false
	end
end

Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Item buff gain",
	localName = L["Item buff gain"],
	combatLogEvents = {
		{
			eventType = "ENCHANT_APPLIED",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellName, itemId, itemName)
				return {
					spellName = spellName,
					itemName = itemName,
					dstGUID = dstGUID,
				}
			end,
		}
	},
	defaultParam = {
		unit = "player",
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
			spell = {
				name = L["Spell"],
				desc = L["Buff name"],
				type = 'string',
			},
		},
	},
	check = checkItemBuff,
}

Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Item buff fade",
	localName = L["Item buff fade"],
	combatLogEvents = {
		{
			eventType = "ENCHANT_REMOVED",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellName, itemId, itemName)
				return {
					spellName = spellName,
					itemName = itemName,
					dstGUID = dstGUID,
				}
			end,
		}
	},
	defaultParam = {
		unit = "player",
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
			spell = {
				name = L["Spell"],
				desc = L["Buff name"],
				type = 'string',
			},
		},
	},
	check = checkItemBuff,
}

Parrot:RegisterSecondaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Buff inactive",
	localName = L["Buff inactive"],
--	notLocalName = L["Aura active"],
	defaultParam = {
		unit = "player",
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
			spell = {
				name = L["Spell"],
				desc = L["Buff name or spell id"],
				type = 'string',
				usage = "<Buff name or spell id>",
				save = saveSpell,
				parse = parseSpell,
			},
			byplayer = {
				name = L["Own aura"],
				desc = L["Only return true, if the Aura has been applied by yourself"],
				type = 'toggle',
			},
		},
	},
	check = function(param)
		if not param.unit or not param.spell then
			return false
		end
		local name, _, _, _, _, _, _, unitCaster = UnitAura(param.unit, param.spell)
		if name then
			-- aura present, but condition is false if the aura has not been cast by
			-- the player?
			if param.byplayer then
				return unitCaster ~= "player"
			else
				return false
			end
		else
			return true
		end
	end,
}

Parrot:RegisterSecondaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Buff active",
	localName = L["Buff active"],
--	notLocalName = L["Aura active"],
	defaultParam = {
		unit = "player",
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
			spell = {
				name = L["Spell"],
				desc = L["Buff name or spell id"],
				type = 'string',
				usage = "<Buff name or spell id>",
				save = saveSpell,
				parse = parseSpell,
			},
			byplayer = {
				name = L["Own aura"],
				desc = L["Only return true, if the Aura has been applied by yourself"],
				type = 'toggle',
			},
		},
	},
	check = function(param)
		if not param.unit or not param.spell then
			return false
		end
		local name, _, _, _, _, _, _, unitCaster = UnitAura(param.unit, param.spell)
		if name then
			if param.byplayer == true then
				return unitCaster == "player"
			else
				return true
			end
		else
			return false
		end
--		return not UnitAura(param.unit, param.spell or "")
	end,
}

Parrot:RegisterSecondaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Debuff inactive",
	localName = L["Debuff inactive"],
	defaultParam = {
		unit = "player",
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
			spell = {
				name = L["Spell"],
				desc = L["Buff name or spell id"],
				type = 'string',
				usage = "<Buff name or spell id>",
				save = saveSpell,
				parse = parseSpell,
			},
			byplayer = {
				name = L["Own aura"],
				desc = L["Only return true, if the Aura has been applied by yourself"],
				type = 'toggle',
			},
		},
	},
	check = function(param)
		if not param.unit or not param.spell then
			return false
		end
		local name, _, _, _, _, _, _, unitCaster = UnitDebuff(param.unit, param.spell)
		if name then
			-- aura present, but condition is false if the aura has not been cast by
			-- the player?
			if param.byplayer then
				return unitCaster ~= "player"
			else
				return false
			end
		else
			return true
		end
	end,
}

Parrot:RegisterSecondaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Debuff active",
	localName = L["Debuff active"],
--	notLocalName = L["Aura active"],
	defaultParam = {
		unit = "player",
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
			spell = {
				name = L["Spell"],
				desc = L["Buff name or spell id"],
				type = 'string',
				usage = "<Buff name or spell id>",
				save = saveSpell,
				parse = parseSpell,
			},
			byplayer = {
				name = L["Own aura"],
				desc = L["Only return true, if the Aura has been applied by yourself"],
				type = 'toggle',
			},
		},
	},
	check = function(param)
		if not param.unit or not param.spell then
			return false
		end
		local name, _, _, _, _, _, _, unitCaster = UnitDebuff(param.unit, param.spell)
		if name then
			if param.byplayer == true then
				return unitCaster == "player"
			else
				return true
			end
		else
			return false
		end
--		return not UnitAura(param.unit, param.spell or "")
	end,
}

Parrot:RegisterSecondaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Item buff active",
	localName = L["Item buff active"],
	param = {
		type = 'select',
		values = {
			[0] = L["Any"],
			[1] = L["Main hand"],
			[2] = L["Off hand"],
			[3] = L["Both"],
		},
	},
	check = function(param)
		if not param then
			return false
		end
		local main, _, _, off = GetWeaponEnchantInfo()
		if param == 0 then
			return main == 1 or off == 1
		elseif param == 1 then
			return main == 1
		elseif param == 2 then
			return off == 1
		elseif param == 3 then
			return main == 1 and off == 1
		end
	end,
}
