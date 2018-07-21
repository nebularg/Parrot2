
--[[
	Prefix to all files if this script is run from a subdir, for example
]]
local file_prefix = "../"

local all_files = {
	"Code/Parrot.lua",
	"Code/CombatEvents.lua",
	"Code/Display.lua",
	"Code/ScrollAreas.lua",
	"Code/Suppressions.lua",
	"Code/Triggers.lua",
	"Data/AnimationStyles.lua",
	"Data/Auras.lua",
	"Data/CombatEvents.lua",
	"Data/CombatStatus.lua",
	"Data/Cooldowns.lua",
	"Data/Loot.lua",
	"Data/PointGains.lua",
	"Data/TriggerConditions.lua",
}
local locale_files = {
	"deDE", "esES", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW",
}

-- extract data
local strings = {}
print("Parsing files")
for _, file in next, all_files do
	local fh = assert(io.open(string.format("%s%s", file_prefix or "", file), "r"), "Could not open " .. file)
	local text = fh:read("*all")
	fh:close()

	local count = 0
	for match in string.gmatch(text, "L%[\"(.-)\"%]") do
		strings[match] = true
		count = count + 1
	end
	print("  (" .. count .. ")\t" .. file)
end

print("\nGenerating locales")

-- dump the english locale
local sorted = {}
for key in next, strings do
	table.insert(sorted, key)
end
table.sort(sorted)

local locale = assert(io.open("enUS.lua", "wb"), "Could not open enUS.lua")
locale:write('local debug = true\r\n--@debug@\r\ndebug = nil\r\n--@end-debug@')
locale:write('\r\n\r\nlocal L = LibStub("AceLocale-3.0"):NewLocale("Parrot", "enUS", true, debug)\r\n\r\n')

for _, v in ipairs(sorted) do
	locale:write(string.format('L["%s"] = true\r\n', v))
end
locale:close()
print("  (" .. #sorted .. ")\tenUS")

-- dump the rest
local L
local m = { NewLocale = function() L = {} return L end }
_G.LibStub = setmetatable({}, { __call = function() return m end })

for _, file in next, locale_files do
	dofile(string.format("%sLocales/%s.lua", file_prefix or "", file))

	local locale = assert(io.open(string.format("%sLocales/%s.lua", file_prefix or "", file), "wb"), "Could not open " .. file)
	locale:write('local L = LibStub("AceLocale-3.0"):NewLocale("Parrot", "' .. file .. '")')
	if file == "esES" then
		locale:write(' or LibStub("AceLocale-3.0"):NewLocale("Parrot", "esMX")')
	end
	locale:write('\r\nif not L then return end\r\n\r\n')

	local count = 0
	for index, key in ipairs(sorted) do
		local value = L[key]
		if value then
			value = value:gsub("\n", "\\n"):gsub("\"", "\\\"")
			locale:write(string.format('L["%s"] = "%s"\r\n', key, value))
			count = count + 1
		else
			locale:write(string.format('-- L["%s"] = "%s"\r\n', key, key))
		end
	end
	locale:close()

	print("  (" .. count .. ")\t" .. file)
end
