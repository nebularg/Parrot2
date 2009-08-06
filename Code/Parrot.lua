Parrot = Rock:NewAddon("Parrot", "LibRockConsole-1.0", "LibRockModuleCore-1.0", "LibRockEvent-1.0", "LibRockTimer-1.0", "LibRockHook-1.0")
local Parrot, self = Parrot, Parrot
Parrot.version = "@project-version@"
Parrot.abbrhash = "@project-abbreviated-hash@"
Parrot.hash = "@project-hash@"
Parrot.date = "@project-date-iso@"

local _G = _G

local L = LibStub("AceLocale-3.0"):GetLocale("Parrot")

local localeTables = {}

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local SharedMedia = Rock("LibSharedMedia-3.0")

local newList, unpackListAndDel = Rock:GetRecyclingFunctions("Parrot", "newList", "unpackListAndDel")

local del = Rock:GetRecyclingFunctions("Parrot", "del")

local function debug(text)
	--@debug@
	if type(text) == 'table' then
		for k,v in pairs(text) do
			debug(string.format("[\"%s\"] = \"%s\",",k,tostring(v)))
		end
	else
		ChatFrame4:AddMessage(tostring(text))
	end
	--@end-debug@
end

Parrot.debug = debug

local function initOptions()
	debug("init options")
	if Parrot.options.args.general then
		return
	end

	Parrot:OnOptionsCreate()

	for k, v in Parrot:IterateModules() do
		if type(v.OnOptionsCreate) == "function" then
			v:OnOptionsCreate()
		end
	end

	Parrot.options.args.load = del(Parrot.options.args.load)
	debug("optins initialized")
end

local dbDefaults = {
	profile = {
		gameDamage = false,
		gameHealing = false,
		totemDamage = true,
	}
}

function Parrot:OnInitialize()
	self:AddSlashCommand("ShowConfig", {"/par", "/parrot"})

	-- use db1 to fool LibRock-1.0
	-- even without the RockDB-mixin, LibRock operates on self.db
	self.db1 = LibStub("AceDB-3.0"):New("ParrotDB", dbDefaults)

	Parrot.options = {
		name = L["Parrot"],
		desc = L["Floating Combat Text of awesomeness. Caw. It'll eat your crackers."],
		type = 'group',
		icon = [[Interface\Icons\Spell_Nature_ForceOfNature]],
		args = {
			load = {
				name = L["Load config"],
				desc = L["Load configuration options"],
				type = 'execute',
				func = initOptions,
			},
-- should it be implemented?
--			alwaysLoad = {
--				name = L["always load options"],
--				desc = L["always load all configuration options when loading Parrot."],
--				type = 'toggle',
--				get = function() return end,
--				set = function(info, value) return end,
--			},
		},
	}

	LibStub("AceConfig-3.0"):RegisterOptionsTable("Parrot", Parrot.options, {"/Parrot", "/Par"})

	AceConfigDialog:AddToBlizOptions("Parrot", "Parrot")

--[[	if not self.db1.account.firstTimeWoW21 then
		self.db1.account.firstTimeWoW21 = true
		SetCVar("scriptErrors", "1")
	end--]]
end

function Parrot.inheritFontChoices()

	local t = newList()
	for _,v in ipairs(SharedMedia:List('font')) do
		t[v] = v
	end
--	table.sort(t)
	t["1"] = L["Inherit"]
--	table.insert(t, 1, L["Inherit"])
	return t
end
function Parrot:OnEnable()

	debug("enable Parrot")

	_G.SHOW_COMBAT_TEXT = "0"
	if type(_G.CombatText_UpdateDisplayedMessages) == "function" then
	   _G.CombatText_UpdateDisplayedMessages()
	end

	if _G.CombatText_OnEvent then
		self:AddHook("CombatText_OnEvent", function()
			_G.SHOW_COMBAT_TEXT = "0"
			if type(_G.CombatText_UpdateDisplayedMessages) == "function" then
			   _G.CombatText_UpdateDisplayedMessages()
			end
		end)
	end

	SetCVar("CombatDamage", self.db1.profile.gameDamage and "1" or "0")
	SetCVar("CombatHealing", self.db1.profile.gameHealing and "1" or "0")

	SetCVar("CombatLogPeriodicSpells", 1)
	SetCVar("PetMeleeDamage", 1)

	debug("iterating moduels")
	for name, module in self:IterateModules() do
		debug("enable module " .. name)
		self:ToggleModuleActive(module, true)
	end
end
function Parrot:OnDisable()
	SetCVar("CombatDamage", "1")
	SetCVar("CombatHealing", "1")
	_G.SHOW_COMBAT_TEXT = "1"

	for name, module in self:IterateModules() do
		self:ToggleModuleActive(module, false)
	end
end
function Parrot:OnProfileEnable()
	if self:IsActive() then
		self:ToggleActive(false)
		self:ToggleActive(true)
	end
end


function Parrot:ShowConfig()
	initOptions()
	AceConfigDialog:Open("Parrot")
end

function Parrot:OnOptionsCreate()
	self:AddOption("profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db1))
	self.options.args.profiles.order = -1
	self:AddOption('general', {
		type = 'group',
		name = L["General"],
		desc = L["General settings"],
		disabled = function()
			return not self:IsActive()
		end,
		order = 1,
		args = {
			gameDamage = {
				type = 'toggle',
				name = L["Game damage"],
				desc = L["Whether to show damage over the enemy's heads."],
				get = function()
					return Parrot.db1.profile.gameDamage
				end,
				set = function(info, value)
					Parrot.db1.profile.gameDamage = value
					SetCVar("CombatDamage", value and "1" or "0")
				end,
			},
			gameHealing = {
				type = 'toggle',
				name = L["Game healing"],
				desc = L["Whether to show healing over the enemy's heads."],
				get = function()
					return Parrot.db1.profile.gameHealing
				end,
				set = function(info, value)
					Parrot.db1.profile.gameHealing = value
					SetCVar("CombatHealing", value and "1" or "0")
				end,
			},
			totemDamage = {
				type = 'toggle',
				name = L["Show guardian events"],
				desc = L["Whether events involving your guardian(s) (totems, ...) should be displayed"],
				get = function()
					return Parrot.db1.profile.totemDamage
				end,
				set = function(info, value)
					Parrot.db1.profile.totemDamage = value
				end,
			},
		}
	})
end

--local addedOptions = {}
function Parrot:AddOption(key, table)
--	addedOptions[key] = table
	self.options.args[key] = table
end

Parrot.options = {
	name = L["Parrot"],
	desc = L["Floating Combat Text of awesomeness. Caw. It'll eat your crackers."],
	type = 'group',
	icon = [[Interface\Icons\Spell_Nature_ForceOfNature]],
	args = {},
}

--Parrot:SetConfigTable(Parrot.options)
