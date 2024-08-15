std = "lua51"
max_line_length = false
codes = true
exclude_files = {
	"**/Libs",
}
ignore = {
	"211/L", -- Unused local variable "L"
	"212", -- Unused argument
	"213", -- Unused loop variable
	"311", -- Value assigned to a local variable is unused (local var = nil :F)
}
globals = {
	"LibStub",
	"CONFIGMODE_CALLBACKS",

	"SLASH_PARROT1", "SLASH_PARROT2", "SlashCmdList",

	"GameTooltip",
	"UIParent",
	"Enum",

	"bit",
	"BreakUpLargeNumbers",
	"cos",
	"C_CurrencyInfo",
	"C_Spell",
	"C_SpellBook",
	"CombatLogGetCurrentEventInfo",
	"CopyTable",
	"CreateFrame",
	"format",
	"GetBuildInfo",
	"GetComboPoints",
	"GetCVarDefault",
	"geterrorhandler",
	"GetInventoryItemCooldown",
	"GetInventoryItemLink",
	"GetItemCount",
	"GetItemIcon",
	"GetItemInfo",
	"GetPlayerInfoByGUID",
	"GetSchoolString",
	"GetScreenHeight",
	"GetScreenWidth",
	"GetShapeshiftForm",
	"GetSpecialization",
	"GetSpecializationInfo",
	"GetSpecializationInfoByID",
	"GetTime",
	"GetUnitPowerBarStringsByID",
	"GetWeaponEnchantInfo",
	"InCombatLockdown",
	"IsInGroup",
	"IsInInstance",
	"IsMounted",
	"IsUsableSpell",
	"LoadAddOn",
	"PlaySoundFile",
	"SetCVar",
	"sin",
	"strjoin",
	"strsplit",
	"tostringall",
	"UnitClass",
	"UnitGUID",
	"UnitHasVehicleUI",
	"UnitHealth",
	"UnitHealthMax",
	"UnitInVehicle",
	"UnitIsDeadOrGhost",
	"UnitIsFriend",
	"UnitIsPlayer",
	"UnitName",
	"UnitPower",
	"UnitPowerBarID",
	"UnitPowerMax",
	"UnitXP",
	"wipe",

	"COMBATLOG_OBJECT_AFFILIATION_MINE",
	"COMBATLOG_OBJECT_CONTROL_PLAYER",
	"COMBATLOG_OBJECT_REACTION_FRIENDLY",
	"DISABLE",
	"ENABLE",
	"LARGE_NUMBER_SEPERATOR",
}
