#!/usr/bin/lua

require "lfs"
lfs.mkdir("./Strings")

--[[
	Prefix to all files if this script is run from a subdir, for example
]]
local filePrefix = "../"

local allfiles = {
	Parrot = { "Code/Parrot.lua", },
	Parrot_CombatEvents = { "Code/CombatEvents.lua", },
	Parrot_Display = { "Code/Display.lua", },
	Parrot_ScrollAreas = { "Code/ScrollAreas.lua", },
	Parrot_Suppressions = { "Code/Suppressions.lua", },
	Parrot_TriggerConditions = { "Code/TriggerConditions.lua", },
	Parrot_Triggers = { "Code/Triggers.lua", },
	Parrot_AnimationStyles = { "Data/AnimationStyles.lua", },
	Parrot_Auras = { "Data/Auras.lua", },
	Parrot_CombatEvents_Data = { "Data/CombatEvents.lua", },
	Parrot_CombatStatus = { "Data/CombatStatus.lua", },
	Parrot_Cooldowns = { "Data/Cooldowns.lua", },
	Parrot_Loot = { "Data/Loot.lua", },
	Parrot_PointGains = { "Data/PointGains.lua", },
	Parrot_TriggerConditions_Data = { "Data/TriggerConditions.lua", },
}

local ordered = { -- order in the locale files
	"Parrot",
	"Parrot_CombatEvents",
	"Parrot_Display",
	"Parrot_ScrollAreas",
	"Parrot_Suppressions",
	"Parrot_TriggerConditions",
	"Parrot_Triggers",
	"Parrot_AnimationStyles",
	"Parrot_Auras",
	"Parrot_CombatEvents_Data",
	"Parrot_CombatStatus",
	"Parrot_Cooldowns",
	"Parrot_Loot",
	"Parrot_PointGains",
	"Parrot_TriggerConditions_Data",
}

local function saveLocales(namespace, strings)
	local file = io.open("Strings/" .. namespace .. ".lua", "w")
	for i, v in ipairs(strings) do
		file:write(string.format("L[\"%s\"] = true\n", v))
	end
	file:close()
end

local function parseFile(filename)
	local strings = {}
	local file = assert(io.open(string.format("%s%s", filePrefix or "", filename), "r"), "Could not open " .. filename)
	local text = file:read("*all")
	file:close()

	for match in string.gmatch(text, "L%[\"(.-)\"%]") do
		strings[match] = true
	end
	return strings
end


local locale = io.open("Strings/enUS.lua", "w")
locale:write('local debug = nil\n---@debug@\ndebug = true\n---@end-debug@\n\n')

-- extract data from specified lua files
for _, namespace in ipairs(ordered) do
	print(namespace)
	for _, file in ipairs(allfiles[namespace]) do
		local strings = parseFile(file)

		local sorted = {}
		for k in next, strings do
			table.insert(sorted, k)
		end
		table.sort(sorted)
		if #sorted > 0 then
			saveLocales(namespace, sorted)
		end

		locale:write(string.format('local L = LibStub("AceLocale-3.0"):NewLocale("%s", "enUS", true, debug)\n', namespace))
		for _, v in ipairs(sorted) do
			locale:write(string.format('L["%s"] = true\n', v))
		end
		locale:write('\n\n')

		print("  (" .. #sorted .. ") " .. file)
	end
end

locale:close()
