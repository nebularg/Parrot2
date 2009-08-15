Parrot = Rock:NewAddon("Parrot", "LibRockConsole-1.0", "LibRockModuleCore-1.0", "LibRockEvent-1.0", "LibRockTimer-1.0", "LibRockHook-1.0")
local Parrot, self = Parrot, Parrot
--@debug@
Parrot.version = "v1.8.3+dev"
--@end-debug@
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

--@debug@
-- function is not needed at all when debug is off
local function debugTableValues(table, stop)
	if stop then
		for k,v in pairs(table) do
			local line = ""
			line = line .. ("[%s]"):format(tonumber(k) or tostring(k))
			line = line .. (" = %s,"):format(tonumber(v) or tostring(v))
			ChatFrame4:AddMessage(line)
		end
	else
		for k,v in pairs(table) do
			local line = ""
			line = line .. ("[%s] = {"):format(tonumber(k) or tostring(k))
			ChatFrame4:AddMessage(line)
			debugTableValues(v, true)
			ChatFrame4:AddMessage("}")
		end
	end
end
--@end-debug@

local function debug(...)
	--@debug@
	local first = select(1,...)
	if type(first) == 'table' then
		ChatFrame4:AddMessage("{")
		debugTableValues(first)
		ChatFrame4:AddMessage("}")
	else
		local text = ""
		for i = 1, select('#', ...) do
			text = text .. tostring(select(i, ...))
		end
		ChatFrame4:AddMessage(text)
	end
	--@end-debug@
end

Parrot.debug = debug

local function initOptions()
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

	self.db1.RegisterCallback(self, "OnProfileChanged", "UpdateModuleConfigs")
	self.db1.RegisterCallback(self, "OnProfileCopied", "UpdateModuleConfigs")
	self.db1.RegisterCallback(self, "OnProfileReset", "UpdateModuleConfigs")

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

function Parrot:UpdateModuleConfigs()
	for k,v in Parrot:IterateModules() do
		if type(v.ApplyConfig) == "function" then
			v:ApplyConfig()
		end
	end
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

	for name, module in self:IterateModules() do
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
			showNameRealm = {
				type = 'toggle',
				name = L["Show realm name"],
				desc = L["Display realm in player names (in battlegrounds)"],
				get = function() return Parrot.db1.profile.showNameRealm end,
				set = function(info, value)
						Parrot.db1.profile.showNameRealm = value
					end,

			}
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
