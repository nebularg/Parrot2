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
Parrot.PARROT_DEBUG_FRAME = ChatFrame4
Parrot.debug = function(arg1, ...)
	--@debug@
	if type(arg1) == "table" then
		if not DevTools_Dump then
			assert(LoadAddOn("Blizzard_DebugTools"))
		end
		Parrot.PARROT_DEBUG_FRAME:AddMessage("|cff00ff00Parrot|r: +++ table-dump")
		DEVTOOLS_DEPTH_CUTOFF = 2
		DEFAULT_CHAT_FRAME = Parrot.PARROT_DEBUG_FRAME
		DevTools_Dump(arg1)
		DEFAULT_CHAT_FRAME = ChatFrame1
		DEVTOOLS_DEPTH_CUTOFF = 10
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

-- Init
local db = nil
local defaults = {
	profile = {
		gameText = false,
		gameDamage = false,
		gamePetDamage = false,
		gameHealing = false,
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

function Parrot:UpdateFCT()
	if db.gameText then
		local damage = db.gameDamage and "1" or "0"
		SetCVar("floatingCombatTextCombatDamage", damage)
		SetCVar("floatingCombatTextCombatLogPeriodicSpells", damage)

		local petDamage = db.gamePetDamage and "1" or "0"
		SetCVar("floatingCombatTextPetMeleeDamage", petDamage)
		SetCVar("floatingCombatTextPetSpellDamage", petDamage)

		local healing = db.gameHealing and "1" or "0"
		SetCVar("floatingCombatTextCombatHealing", healing)
		SetCVar("floatingCombatTextCombatHealingAbsorbTarget", healing)
		SetCVar("floatingCombatTextCombatHealingAbsorbSelf", healing)
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
				name = L["Game options"],
				set = function(info, value) db[info[#info]] = value end,
				get = function(info) return db[info[#info]] end,
				args = {
					gameText = {
						type = "toggle",
						name = L["Control game options"],
						desc = L["Whether Parrot should control the default interface's options below.\nThese settings always override manual changes to the default interface options."],
						order = 1,
					},
					gameDamage = {
						type = "toggle",
						name = _G.SHOW_DAMAGE_TEXT, -- Damage
						desc = _G.OPTION_TOOLTIP_SHOW_DAMAGE, -- Display damage numbers over hostile creatures when damaged.
						disabled = function() return not db.gameText end,
						set = setCVarOption,
						order = 2,
					},
					gamePetDamage = {
						type = "toggle",
						name = _G.SHOW_PET_MELEE_DAMAGE, -- Pet Damage
						desc = _G.OPTION_TOOLTIP_SHOW_PET_MELEE_DAMAGE, -- Show damage caused by your pet.
						disabled = function() return not db.gameText end,
						set = setCVarOption,
						order = 3,
					},
					gameHealing = {
						type = "toggle",
						name = _G.SHOW_COMBAT_HEALING, -- Healing
						desc = _G.OPTION_TOOLTIP_SHOW_COMBAT_HEALING, -- Display amount of healing you did to the target.
						disabled = function() return not db.gameText end,
						set = setCVarOption,
						order = 4,
					},
				},
			},
		}
	})
end

