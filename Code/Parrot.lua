local _, ns = ...
ns.addon = {}
local Parrot = LibStub("AceAddon-3.0"):NewAddon(ns.addon, "Parrot", "AceEvent-3.0", "LibSink-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Parrot")

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

Parrot.wow_classic_era = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
Parrot.wow_classic = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

-- Debug
local debug = function() end
--@debug@
do
	local PARROT_DEBUG_FRAME = _G.ChatFrame4
	local function nilCacheFunc() return nil end
	local function writeFunc(self, msg) PARROT_DEBUG_FRAME:AddMessage(msg) end

	function debug(arg1, ...)
		if type(arg1) == "table" then
			local loaded = LoadAddOn("Blizzard_DebugTools")
			if not loaded then
				PARROT_DEBUG_FRAME:AddMessage("|cff00ff00Parrot|r: !!! table-dump skipped")
				return debug(...)
			end

			local context = {
				depth = 2,
				GetTableName = nilCacheFunc,
				GetFunctionName = nilCacheFunc,
				GetUserdataName = nilCacheFunc,
				Write = writeFunc,
			}
			PARROT_DEBUG_FRAME:AddMessage("|cff00ff00Parrot|r: +++ table-dump")
			_G.DevTools_RunDump(arg1, context)
			PARROT_DEBUG_FRAME:AddMessage("|cff00ff00Parrot|r: --- end of table-dump")
			return debug(...)
		else
			local text = strjoin(" ", tostringall(arg1, ...))
			PARROT_DEBUG_FRAME:AddMessage("|cff00ff00Parrot|r: " .. text)
		end
	end
end
--@end-debug@
Parrot.debug = debug

-- Table recycling
local new, del
do
	local pool = setmetatable({}, {__mode = 'kv'})

	function new()
		local t = next(pool)
		if t then
			pool[t] = nil
		else
			t = {}
		end
		return t
	end

	function del(t)
		if not t then
			error(("Bad argument #1 to 'del'. Expected %q, got %q."):format("table", type(t)), 2)
		end
		setmetatable(t, nil)
		wipe(t)
		pool[t] = true
		return nil
	end
end

local function newList(...)
	local t = new()
	for i = 1, select('#', ...) do
		t[i] = select(i, ...)
	end
	return t
end

local function newDict(...)
	local t = new()
	for i = 1, select('#', ...), 2 do
		local k, v = select(i, ...)
		t[k] = v
	end
	return t
end

Parrot.newList = newList
Parrot.newDict = newDict
Parrot.del = del

-- LibDeformat-3.0 replacement
-- This is Jerry's GetPattern function from LibItemBonus-2.0.
local GetPattern
do
	-- This is very much a ripoff of Deformat, simplified in that it does not
	-- handle merged patterns

	local next, ipairs, assert, loadstring = next, ipairs, assert, loadstring
	local tconcat = table.concat
	local function donothing() end

	local cache = {}
	local sequences = {
		["%d*d"] = "%%-?%%d+",
		["s"] = ".+",
		["[fg]"] = "%%-?%%d+%%.?%%d*",
		["%%%.%d[fg]"] = "%%-?%%d+%%.?%%d*",
		["c"] = ".",
	}

	local function get_first_pattern(s)
		local first_pos, first_pattern
		for pattern in next, sequences do
			local pos = s:find("%%%%"..pattern)
			if pos and (not first_pos or pos < first_pos) then
				first_pos, first_pattern = pos, pattern
			end
		end
		return first_pattern
	end

	local function get_indexed_pattern(s, i)
		for pattern in next, sequences do
			if s:find("%%%%" .. i .. "%%%$" .. pattern) then
				return pattern
			end
		end
	end

	local function unpattern_unordered(unpattern, f)
		local i = 1
		while true do
			local pattern = get_first_pattern(unpattern)
			if not pattern then return unpattern, i > 1 end

			unpattern = unpattern:gsub("%%%%" .. pattern, "(" .. sequences[pattern] .. ")", 1)
			f[i] = (pattern ~= "c" and pattern ~= "s")
			i = i + 1
		end
	end

	local function unpattern_ordered(unpattern, f)
		local i = 1
		while true do
			local pattern = get_indexed_pattern(unpattern, i)
			if not pattern then return unpattern, i > 1 end

			unpattern = unpattern:gsub("%%%%" .. i .. "%%%$" .. pattern, "(" .. sequences[pattern] .. ")", 1)
			f[i] = (pattern ~= "c" and pattern ~= "s")
			i = i + 1
		end
	end

	function GetPattern(pattern)
		local unpattern, f, matched = '^' .. pattern:gsub("([%(%)%.%*%+%-%[%]%?%^%$%%])", "%%%1") .. '$', {}
		if not pattern:find("%1$", nil, true) then
			unpattern, matched = unpattern_unordered(unpattern, f)
			if not matched then
				return donothing
			else
				local locals, returns = {}, {}
				for index, number in ipairs(f) do
					local l = ("v%d"):format(index)
					locals[index] = l
					if number then
						returns[#returns + 1] = "n("..l..")"
					else
						returns[#returns + 1] = l
					end
				end
				locals = tconcat(locals, ",")
				returns = tconcat(returns, ",")
				local code = ("local m, n = string.match, tonumber return function(s) local %s = m(s, %q) return %s end"):format(locals, unpattern, returns)
				return assert(loadstring(code))()
			end
		else
			unpattern, matched = unpattern_ordered(unpattern, f)
			if not matched then
				return donothing
			else
				local i, o = 1, {}
				pattern:gsub("%%(%d)%$", function(w) o[i] = tonumber(w); i = i + 1; end)
				local sorted_locals, returns = {}, {}
				for index, number in ipairs(f) do
					local l = ("v%d"):format(index)
					sorted_locals[index] = ("v%d"):format(o[index])
					if number then
						returns[#returns + 1] = "n("..l..")"
					else
						returns[#returns + 1] = l
					end
				end
				sorted_locals = tconcat(sorted_locals, ",")
				returns = tconcat(returns, ",")
				local code =("local m, n = string.match, tonumber return function(s) local %s = m(s, %q) return %s end"):format(sorted_locals, unpattern, returns)
				return assert(loadstring(code))()
			end
		end
	end

	function Parrot.Deformat(text, pattern)
		local func = cache[pattern]
		if not func then
			func = GetPattern(pattern)
			cache[pattern] = func
		end
		return func(text)
	end
end

-- Init
local defaults = {
	profile = {}
}

function Parrot:OnProfileChanged(event, database)
	for _, mod in self:IterateModules() do
		if type(mod.OnProfileChanged) == "function" then
			mod:OnProfileChanged(event, database)
		end
	end
end

function Parrot:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("ParrotDB", defaults, true)

	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

	self.options = {
		name = L["Parrot"],
		desc = L["Floating Combat Text of awesomeness. Caw. It'll eat your crackers."],
		type = "group",
		icon = [[Interface\Icons\Spell_Nature_ForceOfNature]],
		args = {},
	}

	-- stub options table to show in Interface Options
	local options = CopyTable(self.options)
	options.args.load = {
		type = "execute",
		name = L["Load config"],
		desc = L["Load configuration options"],
		func = "ShowConfig",
		handler = self,
	}
	AceConfig:RegisterOptionsTable("Parrot/Blizzard", options)
	AceConfigDialog:AddToBlizOptions("Parrot/Blizzard", L["Parrot"])

	SLASH_PARROT1 = "/parrot"
	SLASH_PARROT2 = "/par"
	function SlashCmdList.PARROT()
		self:ShowConfig()
	end

	local LibSink = LibStub("LibSink-2.0")
	local function sink(addon, text, r, g, b, font, size, outline, sticky, location, icon)
		local storage = LibSink.storageForAddon[addon]
		if storage then
			location = storage.sink20ScrollArea or location or "Notification"
			sticky = storage.sink20Sticky or sticky
		end
		self:ShowMessage(text, location, sticky, r, g, b, font, size, outline, icon)
	end
	local function getScrollAreasChoices()
		local tmp = {}
		for k, v in next, self:GetScrollAreasChoices() do
			tmp[#tmp+1] = v
		end
		return tmp
	end
	self:RegisterSink("Parrot", L["Parrot"], nil, sink, getScrollAreasChoices, true)

	LibStub("LibDataBroker-1.1"):NewDataObject("Parrot", {
		type = "launcher",
		icon = "Interface\\Icons\\Spell_Nature_ForceOfNature",
		OnClick = function(_, button)
			if button == "LeftButton" then
				Parrot:ShowConfig()
			end
		end,
		label = L["Parrot"],
	})

end

function Parrot:OnEnable()
end

-- Event handling
local nextUID
do
	local uid = 0
	function nextUID()
		uid = uid + 1
		return uid
	end
end

do
	local combatLogHandlers = {}

	local function OnCombatLogEvent()
		local uid = nextUID()
		for mod in next, combatLogHandlers do
			mod:HandleCombatlogEvent(uid, CombatLogGetCurrentEventInfo())
		end
	end

	function Parrot:RegisterCombatLog(mod)
		if type(mod.HandleCombatlogEvent) ~= "function" then
			error("Bad argument #1 for 'RegisterCombatLog'. Module must contain a function named HandleCombatlogEvent")
		end

		if not next(combatLogHandlers) then
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", OnCombatLogEvent)
		end
		combatLogHandlers[mod] = true
	end

	function Parrot:UnregisterCombatLog(mod)
		combatLogHandlers[mod] = nil
		if not next(combatLogHandlers) then
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end
	end
end

do
	local blizzardEventHandlers = {}

	local function OnBlizzardEvent(event, ...)
		local uid = nextUID()
		for mod, func in next, blizzardEventHandlers[event] do
			mod[func](mod, uid, event, ...)
		end
	end

	function Parrot:RegisterBlizzardEvent(mod, event, func)
		if func then
			if type(mod[func]) ~= "function" then
				error(("Bad argument #3 for 'RegisterBlizzardEvent'. Module must contain a function named %s"):format(func))
			end
		elseif type(mod[event]) ~= "function" then
			error(("Bad argument #2 for 'RegisterBlizzardEvent'. Module must contain a function named %s"):format(event))
		end

		if not blizzardEventHandlers[event] then
			blizzardEventHandlers[event] = {}
			self:RegisterEvent(event, OnBlizzardEvent)
		end
		if not blizzardEventHandlers[event][mod] then
			blizzardEventHandlers[event][mod] = {}
		end
		blizzardEventHandlers[event][mod] = func or event
	end

	function Parrot:UnregisterBlizzardEvent(mod, event)
		blizzardEventHandlers[event][mod] = nil
		if not next(blizzardEventHandlers[event]) then
			self:UnregisterEvent(event)
			blizzardEventHandlers[event] = nil
		end
	end

	function Parrot:UnregisterAllBlizzardEvents(mod)
		for _, modules in next, blizzardEventHandlers do
			modules[mod] = nil
		end
	end
end

-- Config
do
	local LibSharedMedia = LibStub("LibSharedMedia-3.0")

	Parrot.soundValues = LibSharedMedia:List("sound")
	Parrot.fontValues = LibSharedMedia:List("font")
	Parrot.fontWithInheritValues = {}

	local function rebuild(_, mediatype)
		if mediatype == "font" then
			wipe(Parrot.fontWithInheritValues)
			for i, v in next, Parrot.fontValues do
				Parrot.fontWithInheritValues[i] = v
			end
			Parrot.fontWithInheritValues[-1] = L["Inherit"]
		end
	end
	rebuild(nil, "font")

	LibSharedMedia.RegisterCallback(Parrot, "LibSharedMedia_Registered", rebuild)
end

function Parrot:ShowConfig()
	if self.OnOptionsCreate then
		self:OnOptionsCreate()

		for _, mod in self:IterateModules() do
			if type(mod.OnOptionsCreate) == "function" then
				mod:OnOptionsCreate()
			end
		end
		AceConfig:RegisterOptionsTable("Parrot", self.options)

		self.OnOptionsCreate = nil
	end

	AceConfigDialog:Open("Parrot")
end

function Parrot:AddOption(name, args)
	self.options.args[name] = args
end

function Parrot:OnOptionsCreate()
	self:AddOption("profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
	self.options.args.profiles.order = -1

	self:AddOption("general", {
		type = "group",
		name = L["General"],
		desc = L["General settings"],
		disabled = function() return not self:IsEnabled() end,
		order = 1,
		args = {}
	})
end

_G.Parrot = Parrot
