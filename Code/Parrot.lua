local Parrot = LibStub("AceAddon-3.0"):NewAddon("Parrot", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "LibSink-2.0")
_G.Parrot = Parrot

--@debug@
Parrot.version = "dev"
--@end-debug@

local L = LibStub("AceLocale-3.0"):GetLocale("Parrot")

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")

-- Debug
Parrot.PARROT_DEBUG_FRAME = _G.ChatFrame4
Parrot.debug = function(arg1, ...)
	--@debug@
	if type(arg1) == "table" then
		if not _G.DevTools_Dump then
			assert(LoadAddOn("Blizzard_DebugTools"))
		end
		Parrot.PARROT_DEBUG_FRAME:AddMessage("|cff00ff00Parrot|r: +++ table-dump")
		_G.DEVTOOLS_DEPTH_CUTOFF = 2
		_G.DEFAULT_CHAT_FRAME = Parrot.PARROT_DEBUG_FRAME
		_G.DevTools_Dump(arg1)
		_G.DEFAULT_CHAT_FRAME = _G.ChatFrame1
		_G.DEVTOOLS_DEPTH_CUTOFF = 10
		Parrot.PARROT_DEBUG_FRAME:AddMessage("|cff00ff00Parrot|r: --- end of table-dump")
		Parrot.debug(...)
	else
		local text = strjoin(" ", tostringall(...))
		Parrot.PARROT_DEBUG_FRAME:AddMessage("|cff00ff00Parrot|r: " .. text)
	end
	--@end-debug@
end

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
local db = nil
local defaults = {
	profile = {
		gameText = false,
		gameSelf = false,
		gameDamage = false,
		gamePetDamage = false,
		gameHealing = false,
		gameLowHealth = false,
		gameReactives = false,
	}
}

function Parrot:OnProfileChanged(event, database)
	db = self.db.profile
	for _, mod in self:IterateModules() do
		if type(mod.OnProfileChanged) == "function" then
			mod:OnProfileChanged(event, database)
		end
	end
end

function Parrot:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("ParrotDB", defaults, true)
  LibStub("LibDualSpec-1.0"):EnhanceDatabase(self.db, "Parrot")
	db = self.db.profile

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

	self:RegisterChatCommand("parrot", "ShowConfig")
	self:RegisterChatCommand("par", "ShowConfig")

	local function sink(addon, text, r, g, b, font, size, outline, sticky, location, icon)
		self:ShowMessage(text, location or "Notification", sticky, r, g, b, font, size, outline, icon)
	end
	local function getScrollAreasChoices()
		local tmp = {}
		for k, v in next, self:GetScrollAreasChoices() do
			tmp[#tmp+1] = v
		end
		return tmp
	end
	self:RegisterSink("Parrot", L["Parrot"], nil, sink, getScrollAreasChoices, true)
end

do
	local fct = {
	  "enableFloatingCombatText",
	  "floatingCombatTextCombatDamage",
	  "floatingCombatTextCombatDamageAllAutos",
	  "floatingCombatTextCombatLogPeriodicSpells",
	  "floatingCombatTextPetMeleeDamage",
	  "floatingCombatTextPetSpellDamage",
	  "floatingCombatTextCombatHealing",
	  "floatingCombatTextCombatHealingAbsorbTarget",
	  "floatingCombatTextCombatHealingAbsorbSelf",
	  "floatingCombatTextReactives",
	  "floatingCombatTextLowManaHealth",
		-- the rest default to off and we don't have toggles for them
	  -- "floatingCombatTextCombatState",
	  -- "floatingCombatTextDodgeParryMiss",
	  -- "floatingCombatTextDamageReduction",
	  -- "floatingCombatTextRepChanges",
	  -- "floatingCombatTextFriendlyHealers",
	  -- "floatingCombatTextComboPoints",
	  -- "floatingCombatTextEnergyGains",
	  -- "floatingCombatTextPeriodicEnergyGains",
	  -- "floatingCombatTextHonorGains",
	  -- "floatingCombatTextAuras",
	  -- "floatingCombatTextAllSpellMechanics",
	  -- "floatingCombatTextSpellMechanics",
	  -- "floatingCombatTextSpellMechanicsOther",
	}

	function Parrot:UpdateFCT()
		if db.gameText then
			SetCVar("enableFloatingCombatText", db.gameSelf and "1" or "0")

			local damage = db.gameDamage and "1" or "0"
			SetCVar("floatingCombatTextCombatDamage", damage)
			SetCVar("floatingCombatTextCombatDamageAllAutos", damage)
			SetCVar("floatingCombatTextCombatLogPeriodicSpells", damage)

			local petDamage = db.gamePetDamage and "1" or "0"
			SetCVar("floatingCombatTextPetMeleeDamage", petDamage)
			SetCVar("floatingCombatTextPetSpellDamage", petDamage)

			local healing = db.gameHealing and "1" or "0"
			SetCVar("floatingCombatTextCombatHealing", healing)
			SetCVar("floatingCombatTextCombatHealingAbsorbTarget", healing)
			SetCVar("floatingCombatTextCombatHealingAbsorbSelf", healing)

			SetCVar("floatingCombatTextReactives", db.gameLowHealth and "1" or "0")
			SetCVar("floatingCombatTextLowManaHealth", db.gameReactives and "1" or "0")
		else
			for _, var in next, fct do
				SetCVar(var, GetCVarDefault(var))
			end
		end
	end
end

function Parrot:OnEnable()
	self:UpdateFCT()
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

	local function OnCombatLogEvent(...)
		local uid = nextUID()
		for mod in next, combatLogHandlers do
			mod:HandleCombatlogEvent(uid, ...)
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

do
	local values = {}
	function Parrot.fontValues()
		wipe(values)
		for _, font in ipairs(SharedMedia:List("font")) do
			values[font] = font
		end
		values["1"] = L["Inherit"]
		return values
	end
end

function Parrot:AddOption(name, args)
	self.options.args[name] = args
end

function Parrot:OnOptionsCreate()
	local function setCVarOption(info, value)
		db[info[#info]] = value
		self:UpdateFCT()
	end

	self:AddOption("profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
	self.options.args.profiles.order = -1
	LibStub("LibDualSpec-1.0"):EnhanceOptions(self.options.args.profiles, self.db)

	self:AddOption("general", {
		type = "group",
		name = L["General"],
		desc = L["General settings"],
		disabled = function() return not self:IsEnabled() end,
		order = 1,
		args = {
			gameText = {
				type = "group",
				inline = true,
				name = _G.COMBAT_TEXT_LABEL, -- Floating Combat Text
				get = function(info) return db[info[#info]] end,
				set = setCVarOption,
				args = {
					gameText = {
						type = "toggle",
						name = L["Control game options"],
						desc = L["Whether Parrot should control the default interface's options below.\nThese settings always override manual changes to the default interface options."],
						descStyle = "inline",
						order = 0,
						width = "full",
					},
					gameSelf = {
						type = "toggle",
						name = _G.COMBAT_SELF, -- Combat Self
						desc = _G.OPTION_TOOLTIP_SHOW_COMBAT_TEXT, -- Checking this will enable additional combat messages to appear in the playfield.
						disabled = function() return not db.gameText end,
						order = 1,
					},
					gameDamage = {
						type = "toggle",
						name = _G.SHOW_DAMAGE_TEXT, -- Damage
						desc = _G.OPTION_TOOLTIP_SHOW_DAMAGE, -- Display damage numbers over hostile creatures when damaged.
						disabled = function() return not db.gameText end,
						order = 2,
					},
					gamePetDamage = {
						type = "toggle",
						name = _G.SHOW_PET_MELEE_DAMAGE, -- Pet Damage
						desc = _G.OPTION_TOOLTIP_SHOW_PET_MELEE_DAMAGE, -- Show damage caused by your pet.
						disabled = function() return not db.gameText end,
						order = 3,
					},
					gameHealing = {
						type = "toggle",
						name = _G.SHOW_COMBAT_HEALING, -- Healing
						desc = _G.OPTION_TOOLTIP_SHOW_COMBAT_HEALING, -- Display amount of healing you did to the target.
						disabled = function() return not db.gameText end,
						order = 4,
					},
					gameLowHealth = {
						type = "toggle",
						name = _G.COMBAT_TEXT_SHOW_LOW_HEALTH_MANA_TEXT, -- Low Mana & Health
						desc = _G.OPTION_TOOLTIP_COMBAT_TEXT_SHOW_LOW_HEALTH_MANA, -- Shows a message when you fall below 20% mana or health.
						disabled = function() return not db.gameText end,
						order = 5,
					},
					gameReactives = {
						type = "toggle",
						name = _G.COMBAT_TEXT_SHOW_REACTIVES_TEXT, -- Spell Alerts
						desc = _G.OPTION_TOOLTIP_COMBAT_TEXT_SHOW_REACTIVES, -- Show alerts when certain important events occur.
						disabled = function() return not db.gameText end,
						order = 6,
					},
				},
			},
		}
	})
end

