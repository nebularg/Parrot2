local VERSION = tonumber(("$Revision: 432 $"):match("%d+"))

local Parrot = Parrot
if Parrot.revision < VERSION then
	Parrot.version = "r" .. VERSION
	Parrot.revision = VERSION
	Parrot.date = ("$Date: 2008-08-26 19:58:15 +0200 (Tue, 26 Aug 2008) $"):match("%d%d%d%d%-%d%d%-%d%d")
end

local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot_Auras")

local newList, del = Rock:GetRecyclingFunctions("Parrot", "newList", "del")

local current_player_auras = {}

local function checkAura(spellId)
  for i,v in ipairs(current_player_auras) do
    if v == spellId then
      return i
    end 
  end
  return nil
end

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Buff gains",
	localName = L["Buff gains"],
	defaultTag = "([Name])",
	combatLogEvents = {
		{
			eventType = "SPELL_AURA_APPLIED",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "BUFF" or dstGUID ~= UnitGUID("player") then
					return nil
				end
				
				auraid = checkAura(spellId)
				
				if auraid then
				  return nil
				else
				  table.insert(current_player_auras, spellId)
				end
				
				local info = newList()
				info.spellID = spellId
				info.abilityName = spellName
				info.recipientID = dstGUID
				info.recepientName = dstName
				info.icon = select(3, GetSpellInfo(spellId))
				
				return info
				
			end,
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
		{
			eventType = "SPELL_AURA_APPLIED",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "DEBUFF" or dstGUID ~= UnitGUID("player") then
					return nil
				end
				
				if auraid then
				  return nil
				else
				  table.insert(current_player_auras, spellId)
				end
				
				local info = newList()
				info.spellID = spellId
				info.abilityName = spellName
				info.recipientID = dstGUID
				info.recepientName = dstName
				info.icon = select(3, GetSpellInfo(spellId))
				
				return info
				
			end,
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
		{
			eventType = "SPELL_AURA_APPLIED_DOSE",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "BUFF" or dstGUID ~= UnitGUID("player") then
					return nil
				end
				
				
				
				local info = newList()
				info.spellID = spellId
				info.abilityName = spellName
				info.recipientID = dstGUID
				info.recepientName = dstName
				info.icon = select(3, GetSpellInfo(spellId))
				info.amount = amount
				
				return info
				
			end,
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
		{
			eventType = "SPELL_AURA_APPLIED_DOSE",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "DEBUFF" or dstGUID ~= UnitGUID("player") then
					return nil
				end
				
				local info = newList()
				info.spellID = spellId
				info.abilityName = spellName
				info.recipientID = dstGUID
				info.recepientName = dstName
				info.icon = select(3, GetSpellInfo(spellId))
				info.amount = amount
				
				return info
				
			end,
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
		{
			eventType = "SPELL_AURA_REMOVED",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "BUFF" or dstGUID ~= UnitGUID("player") then
					return nil
				end
				
				local auraid = checkAura(spellId)
				
				if auraid then
				  table.remove(current_player_auras, auraid)
				end
				
				local info = newList()
				info.spellID = spellId
				info.abilityName = spellName
				info.recipientID = dstGUID
				info.recepientName = dstName
				info.icon = select(3, GetSpellInfo(spellId))
				
				return info
				
			end,
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
		{
			eventType = "SPELL_AURA_REMOVED",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "DEBUFF" or dstGUID ~= UnitGUID("player") then
					return nil
				end
				
				local auraid = checkAura(spellId)
				
				if auraid then
				  table.remove(current_player_auras, auraid)
				end
				
				local info = newList()
				info.spellID = spellId
				info.abilityName = spellName
				info.recipientID = dstGUID
				info.recepientName = dstName
				info.icon = select(3, GetSpellInfo(spellId))
				
				return info
				
			end,
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


Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Target buff gains",
	localName = L["Target buff gains"],
	defaultTag = "[Unitname] gains [Buffname]",
	combatLogEvents = {
		{
			eventType = "SPELL_AURA_APPLIED",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "BUFF" or dstGUID ~= UnitGUID("target") then
					return nil
				end
				
				local info = newList()
				info.spellID = spellId
				info.abilityName = spellName
				info.recipientID = dstGUID
				info.recepientName = dstName
				info.icon = select(3, GetSpellInfo(spellId))
				
				return info
				
			end,
		}
	},
	tagTranslations = {
		Buffname = "abilityName",
		Icon = "icon",
		Unitname = "recepientName",
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
		{
			eventType = "SPELL_AURA_APPLIED_DOSE",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "BUFF" or dstGUID ~= UnitGUID("target") then
					return nil
				end
				
				local info = newList()
				info.spellID = spellId
				info.abilityName = spellName
				info.recipientID = dstGUID
				info.recepientName = dstName
				info.icon = select(3, GetSpellInfo(spellId))
				info.amount = amount
				
				return info
				
			end,
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

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Auras"],
	name = "Item buff gains",
	localName = L["Item buff gains"],
	defaultTag = "([Name])",
	combatLogEvents = {
		{
			eventType = "ENCHANT_APPLIED",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellName, itemId, itemName)
				if dstGUID ~= UnitGUID("player") then
					return nil
				end
				
				local info = newList()
				info.itemId = itemId
				info.abilityName = spellName
				info.itemName = itemName
				
				return info
				
			end,
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
		{
			eventType = "ENCHANT_REMOVED",
			func = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellName, itemId, itemName)
				if dstGUID ~= UnitGUID("player") then
					return nil
				end
				
				local info = newList()
				info.itemId = itemId
				info.abilityName = spellName
				info.itemName = itemName
				
				return info
				
			end,
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



Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Self buff gain",
	localName = L["Self buff gain"],
	combatLogEvents = {
		{
			eventType = "SPELL_AURA_APPLIED",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "BUFF" or dstGUID ~= UnitGUID("player") then
					return nil
				end
				
				return spellName
				
			end,
		},
	},
	param = {
		type = 'string',
		usage = L["<Buff name>"],
	},
}

-- Parrot:RegisterPrimaryTriggerCondition {
-- 	subCategory = L["Auras"],
-- 	name = "Self buff stacks gain",
-- 	localName = L["Self buff stacks gain"],
-- 	combatLogEvents = {
-- 		{
-- 			eventType = "SPELL_AURA_APPLIED_DOSE",
-- 			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
-- 				if auraType ~= "BUFF" or dstGUID ~= UnitGUID("player") then
-- 					return nil
-- 				end
-- 				
-- 				return spellName, amount
-- 				
-- 			end,
-- 		},
-- 	},
-- 	param = {
-- 		type = 'string',
-- 		usage = L["<Buff name>,<Number of stacks>"],
-- 	},
-- 	check = function(param)
-- 	  local a,b = string.find(param, ".*,")
-- 	  local spellId = param:sub(a,b-1)
-- 	  local amount = param:sub(b+1)
-- 	  
-- 	end
-- }

Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Self buff fade",
	localName = L["Self buff fade"],
	combatLogEvents = {
		{
			eventType = "SPELL_AURA_REMOVED",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "BUFF" or dstGUID ~= UnitGUID("player") then
					return nil
				end
				
				return spellName
				
			end,
		},
	},
	param = {
		type = 'string',
		usage = L["<Buff name>"],
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Self debuff gain",
	localName = L["Self debuff gain"],
	combatLogEvents = {
		{
			eventType = "SPELL_AURA_APPLIED",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "DEBUFF" or dstGUID ~= UnitGUID("player") then
					return nil
				end
				
				return spellName
				
			end,
		},
	},
	param = {
		type = 'string',
		usage = L["<Debuff name>"],
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Self debuff fade",
	localName = L["Self debuff fade"],
	combatLogEvents = {
		{
			eventType = "SPELL_AURA_REMOVED",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "DEBUFF" or dstGUID ~= UnitGUID("player") then
					return nil
				end
				
				return spellName
				
			end,
		},
	},
	param = {
		type = 'string',
		usage = L["<Debuff name>"],
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Self item buff gain",
	localName = L["Self item buff gain"],
	combatLogEvents = {
		{
			eventType = "ENCHANT_APPLIED",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellName, itemId, itemName)
				if dstGUID ~= UnitGUID("player") then
					return nil
				end
				
				return spellName
				
			end,
		}
	},
	param = {
		type = 'string',
		usage = L["<Item buff name>"],
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Self item buff fade",
	localName = L["Self item buff fade"],
	combatLogEvents = {
		{
			eventType = "ENCHANT_REMOVED",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellName, itemId, itemName)
				if dstGUID ~= UnitGUID("player") then
					return nil
				end
				
				return spellName
				
			end,
		}
	},
	param = {
		type = 'string',
		usage = L["<Item buff name>"],
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Target buff gain",
	localName = L["Target buff gain"],
	combatLogEvents = {
		{
			eventType = "SPELL_AURA_APPLIED",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "BUFF" or dstGUID ~= UnitGUID("target") then
					return nil
				end
				
				return spellName
				
			end,
		},
	},
	param = {
		type = 'string',
		usage = L["<Buff name>"],
	},
	parserArg = 'abilityName',
}

Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Target debuff gain",
	localName = L["Target debuff gain"],
	combatLogEvents = {
		{
			eventType = "SPELL_AURA_APPLIED",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "DEBUFF" or dstGUID ~= UnitGUID("target") then
					return nil
				end
				
				return spellName
				
			end,
		},
	},
	param = {
		type = 'string',
		usage = L["<Debuff name>"],
	},
}


Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Target buff fade",
	localName = L["Target buff fade"],
	combatLogEvents = {
		{
			eventType = "SPELL_AURA_REMOVED",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "BUFF" or dstGUID ~= UnitGUID("target") then
					return nil
				end
				
				return spellName
				
			end,
		},
	},
	param = {
		type = 'string',
		usage = L["<Buff name>"],
	},
	parserArg = 'abilityName',
}

Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Target debuff fade",
	localName = L["Target debuff fade"],
	combatLogEvents = {
		{
			eventType = "SPELL_AURA_REMOVED",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "DEBUFF" or dstGUID ~= UnitGUID("target") then
					return nil
				end
				
				return spellName
				
			end,
		},
	},
	param = {
		type = 'string',
		usage = L["<Debuff name>"],
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Focus buff gain",
	localName = L["Focus buff gain"],
	combatLogEvents = {
		{
			eventType = "SPELL_AURA_APPLIED",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "BUFF" or dstGUID ~= UnitGUID("focus") then
					return nil
				end
				
				return spellName
				
			end,
		},
	},
	param = {
		type = 'string',
		usage = L["<Buff name>"],
	},
	parserArg = 'abilityName',
}

Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Focus debuff gain",
	localName = L["Focus debuff gain"],
	combatLogEvents = {
		{
			eventType = "SPELL_AURA_APPLIED",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "DEBUFF" or dstGUID ~= UnitGUID("focus") then
					return nil
				end
				
				return spellName
				
			end,
		},
	},
	param = {
		type = 'string',
		usage = L["<Debuff name>"],
	},
	parserArg = 'abilityName',
}


Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Focus buff fade",
	localName = L["Focus buff fade"],
	combatLogEvents = {
		{
			eventType = "SPELL_AURA_REMOVED",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "BUFF" or dstGUID ~= UnitGUID("focus") then
					return nil
				end
				
				return spellName
				
			end,
		},
	},
	param = {
		type = 'string',
		usage = L["<Buff name>"],
	},
	parserArg = 'abilityName',
}

Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Focus debuff fade",
	localName = L["Focus debuff fade"],
	combatLogEvents = {
		{
			eventType = "SPELL_AURA_REMOVED",
			triggerData = function(srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType, amount)
				if auraType ~= "DEBUFF" or dstGUID ~= UnitGUID("focus") then
					return nil
				end
				
				return spellName
				
			end,
		},
	},
	param = {
		type = 'string',
		usage = L["<Debuff name>"],
	},
	parserArg = 'abilityName',
}

Parrot:RegisterSecondaryTriggerCondition {
	subCategory = L["Auras"],
	name = "Buff inactive",
	localName = L["Buff inactive"],
	notLocalName = L["Buff active"],
	param = {
		type = 'string',
		usage = "<Buff name>",
	},
	check = function(param)
		return not GetPlayerBuffName(param)
	end,
}
