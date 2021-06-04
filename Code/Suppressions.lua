local _, ns = ...
local Parrot = ns.addon
if not Parrot then return end

local module = Parrot:NewModule("Suppressions")
local L = LibStub("AceLocale-3.0"):GetLocale("Parrot")

local string_find = _G.string.find
local pcall = _G.pcall

local db = nil
local defaults = {
	profile = {
		suppressions = {},
	}
}

function module:OnInitialize()
	self.db = Parrot.db:RegisterNamespace("Suppressions", defaults)
	db = self.db.profile
end

function module:OnProfileChanged()
	db = self.db.profile
	if Parrot.options.args.suppressions then
		Parrot.options.args.suppressions = nil
		self:OnOptionsCreate()
	end
end

function module:OnOptionsCreate()
	local suppressions_opt = {
		type = 'group',
		name = L["Suppressions"],
		desc = L["List of strings that will be squelched if found."],
		disabled = function()
			return not self:IsEnabled()
		end,
		args = {},
		order = 10,
	}
	local function makeValidateString(key)
		return function(value)
			if key == value then
				return true
			end
			if db.suppressions[value] ~= nil then
				return false
			end
			local nonLua = db.suppressions[key]
			if nonLua then
				return true
			end
			local success = pcall(string_find, '', value)
			return success
		end
	end
	local function setString(info, new)
		if db.suppressions[new] ~= nil then
			return
		end
		local old = info.arg
		db.suppressions[new] = db.suppressions[old]
		db.suppressions[old] = nil
		local opt = suppressions_opt.args[info[#info-1]]
		local name = new == '' and L["New suppression"] or new

		opt.order = new == '' and -110 or -100
		opt.name = name
		opt.desc = name
		opt.args.edit.arg = new
		opt.args.edit.validate = makeValidateString(new)
		opt.args.escape.arg = new
		opt.args.delete.arg = new
	end
	local function getEscape(info)
		return not db.suppressions[info.arg]
	end
	local function setEscape(info, value)
		db.suppressions[info.arg] = not value
	end
	local function remove(info)
		db.suppressions[info.arg] = nil
		suppressions_opt.args[info[#info-1]] = nil
	end
	local function makeTable(k)
		local name = k == '' and L["New suppression"] or k
		return {
			type = 'group',
			name = name,
			desc = name,
			args = {
				edit = {
					type = 'input',
					name = L["Edit"],
					desc = L["Edit search string"],
					get = function(info) return info.arg end,
					set = setString,
					validate = makeValidateString(k),
					usage = L["<Any text> or <Lua search expression>"],
					arg = k,
					order = 1,
				},
				escape = {
					type = 'toggle',
					name = L["Lua search expression"],
					desc = L["Whether the search string is a lua search expression or not."],
					get = getEscape,
					set = setEscape,
					arg = k,
					order = 2,
				},
				delete = {
					type = 'execute',
					confirm = true,
					confirmText = L["Are you sure?"],
					name = L["Remove"],
					desc = L["Remove suppression"],
					func = remove,
					arg = k,
					order = -1,
				}
			}
		}
	end

	local function optkey(table)
		return tostring(table):gsub("table: ","")
	end

	Parrot:AddOption('suppressions', suppressions_opt)
	suppressions_opt.args.new = {
		order = 1,
		type = 'execute',
		name = L["New suppression"],
		desc = L["Add a new suppression."],
		func = function()
			db.suppressions[''] = true
			local t = makeTable('')
			suppressions_opt.args[optkey(t)] = t
		end,
		disabled = function()
			return not db.suppressions or db.suppressions[''] ~= nil
		end,
	}
	for k in next, db.suppressions do
		local t = makeTable(k)
		suppressions_opt.args[optkey(t)] = t
	end
end

function module:ShouldSuppress(text)
	if not self:IsEnabled() then
		return false
	end
	for suppression, escape in next, db.suppressions do
		if suppression ~= '' then
			local success, ret = pcall(string_find, text, suppression, nil, not not escape)
			if success and ret then
				return true
			end
		end
	end
	return false
end
