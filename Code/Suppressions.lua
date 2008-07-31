local VERSION = tonumber(("$Revision: 73474 $"):match("%d+"))

local Parrot = Parrot
local Parrot_Suppressions = Parrot:NewModule("Suppressions")
if Parrot.revision < VERSION then
	Parrot.version = "r" .. VERSION
	Parrot.revision = VERSION
	Parrot.date = ("$Date: 2008-05-11 17:44:45 +0200 (Sun, 11 May 2008) $"):match("%d%d%d%d%-%d%d%-%d%d")
end

-- local L = Parrot:L("Parrot_Suppressions")
-- TODO make modular
local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot_Suppressions")

local _G = _G

local string_find = _G.string.find
local pcall = _G.pcall

Parrot_Suppressions.db = Parrot:GetDatabaseNamespace("Suppressions")
Parrot:SetDatabaseNamespaceDefaults("Suppressions", 'profile', {
	suppressions = {}
})

function Parrot_Suppressions:OnOptionsCreate()
	local suppressions_opt = {
		type = 'group',
		name = L["Suppressions"],
		desc = L["List of strings that will be squelched if found."],
		disabled = function()
			return not self:IsActive()
		end,
		args = {}
	}
	local function ret(...)
		return ...
	end
	local function makeValidateString(key)
		return function(value)
			if key == value then
				return true
			end
			if Parrot_Suppressions.db.profile.suppressions[value] ~= nil then
				return false
			end
			local nonLua = Parrot_Suppressions.db.profile.suppressions[key]
			if nonLua then
				return true
			end
			local success = pcall(string_find, '', value)
			return success
		end
	end
	local function setString(old, new)
		if Parrot_Suppressions.db.profile.suppressions[new] ~= nil then
			return
		end
		Parrot_Suppressions.db.profile.suppressions[new] = Parrot_Suppressions.db.profile.suppressions[old]
		Parrot_Suppressions.db.profile.suppressions[old] = nil
		local opt
		for k,v in pairs(suppressions_opt.args) do
			if v.k == old then
				opt = v
			end
		end
		local name = new == '' and L["New suppression"] or new
		opt.k = new
		opt.order = new == '' and -110 or -100
		opt.name = name
		opt.desc = name
		opt.args.edit.passValue = new
		opt.args.edit.validate = makeValidateString(new)
		opt.args.escape.passValue = new
		opt.args.delete.passValue = new
--		AceLibrary("Dewdrop-2.0"):Refresh()
--		local waterfall = AceLibrary:HasInstance("Waterfall-1.0") and AceLibrary("Waterfall-1.0")
--		if waterfall and waterfall:IsRegistered("Parrot") then
--			waterfall:Refresh("Parrot")
--		end
	end
	local function getEscape(key)
		return not Parrot_Suppressions.db.profile.suppressions[key]
	end
	local function setEscape(key, value)
		Parrot_Suppressions.db.profile.suppressions[key] = not value
	end
	local function remove(key)
		Parrot_Suppressions.db.profile.suppressions[key] = nil
		for k, v in pairs(suppressions_opt.args) do
			if v.k == key then
				suppressions_opt.args[k] = nil
				break
			end
		end
	end
	local function makeTable(k)
		local name = k == '' and L["New suppression"] or k
		return {
			type = 'group',
			name = name,
			desc = name,
			order = k == '' and -110 or -100,
			k = k,
			args = {
				edit = {
					type = 'string',
					name = L["Edit"],
					desc = L["Edit search string"],
					get = ret,
					set = setString,
					validate = makeValidateString(k),
					usage = L["<Any text> or <Lua search expression>"],
					passValue = k,
					order = 1,
				},
				escape = {
					type = 'boolean',
					name = L["Lua search expression"],
					desc = L["Whether the search string is a lua search expression or not."],
					get = getEscape,
					set = setEscape,
					passValue = k,
					order = 2,
				},
				delete = {
					type = 'execute',
					confirmText = L["Are you sure?"],
					buttonText = L["Remove"],
					name = L["Remove"],
					desc = L["Remove suppression"],
					func = remove,
					passValue = k,
					order = -1,
				}
			}
		}
	end
	Parrot:AddOption('suppressions', suppressions_opt)
	suppressions_opt.args[1] = {
		order = 1,
		type = 'execute',
		buttonText = L["Create"],
		name = L["New suppression"],
		desc = L["Add a new suppression."],
		func = function()
			self.db.profile.suppressions[''] = true
			local t = makeTable('')
			suppressions_opt.args[tostring(t)] = t
		end,
		disabled = function()
			return not self.db.profile.suppressions or self.db.profile.suppressions[''] ~= nil
		end,
	}
	for k in pairs(self.db.profile.suppressions) do
		local t = makeTable(k)
		suppressions_opt.args[tostring(t)] = t
	end
end

function Parrot_Suppressions:ShouldSuppress(text)
	if not Parrot:IsModuleActive(self) then
		return false
	end
	for suppression, escape in pairs(self.db.profile.suppressions) do
		if suppression ~= '' then
			local success, ret = pcall(string_find, text, suppression, nil, not not escape)
			if success and ret then
				return true
			end
		end
	end
	return false
end
