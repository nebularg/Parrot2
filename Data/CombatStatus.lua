local VERSION = tonumber(("$Revision: 73474 $"):match("%d+"))

local Parrot = Parrot
if Parrot.revision < VERSION then
	Parrot.version = "r" .. VERSION
	Parrot.revision = VERSION
	Parrot.date = ("$Date: 2008-05-11 17:44:45 +0200 (Sun, 11 May 2008) $"):match("%d%d%d%d%-%d%d%-%d%d")
end

-- local L = Parrot:L("Parrot_CombatStatus")
-- TODO make modular
local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot_CombatStatus")

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Combat status"],
	name = "Enter combat",
	localName = L["Enter combat"],
	defaultTag = L["+Combat"],
	blizzardEvent = "PLAYER_REGEN_DISABLED",
	color = "ffffff", -- white
}

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Combat status"],
	name = "Leave combat",
	localName = L["Leave combat"],
	defaultTag = L["-Combat"],
	blizzardEvent = "PLAYER_REGEN_ENABLED",
	color = "ffffff", -- white
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Enter combat",
	localName = L["Enter combat"],
	events = {
		PLAYER_REGEN_DISABLED = true,
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	name = "Leave combat",
	localName = L["Leave combat"],
	events = {
		PLAYER_REGEN_ENABLED = true,
	},
}

Parrot:RegisterSecondaryTriggerCondition {
	name = "In combat",
	localName = L["In combat"],
	notLocalName = L["Not in combat"],
	check = function()
		return InCombatLockdown()
	end,
}
