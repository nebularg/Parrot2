
Parrot = Rock:NewAddon("Parrot", "LibRockDB-1.0", "LibRockConsole-1.0", "LibRockModuleCore-1.0", "LibRockEvent-1.0", "LibRockTimer-1.0", "LibRockHook-1.0", "LibRockConfig-1.0")
local Parrot, self = Parrot, Parrot
Parrot.version = "@project-version@"
Parrot.abbrhash = "@project-abbreviated-hash@"
Parrot.hash = "@project-hash@"
Parrot.revision = 0 -- DEPRICATED, not using svn anymore
Parrot.date = "@project-date-iso@"

local _G = _G

local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot")

local localeTables = {}

local SharedMedia = Rock("LibSharedMedia-3.0")

local newList, unpackListAndDel = Rock:GetRecyclingFunctions("Parrot", "newList", "unpackListAndDel")

Parrot:SetDatabase("ParrotDB")
Parrot:SetDatabaseDefaults('profile', {
	gameDamage = false,
	gameHealing = false,
	totemDamage = true,
})

function Parrot:OnInitialize()
	self:SetConfigSlashCommand("/Parrot", "/Par")

	if not self.db.account.firstTimeWoW21 then
		self.db.account.firstTimeWoW21 = true
		SetCVar("scriptErrors", "1")
	end
end

function Parrot.inheritFontChoices()
	local t = newList()
	for _,v in ipairs(SharedMedia:List('font')) do
		t[#t+1] = v
	end
	table.sort(t)
	table.insert(t, 1, L["Inherit"])
	return "@list", unpackListAndDel(t)
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

	SetCVar("CombatDamage", self.db.profile.gameDamage and "1" or "0")
	SetCVar("CombatHealing", self.db.profile.gameHealing and "1" or "0")

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

local function initOptions()
	Parrot:OnOptionsCreate()

	for k, v in Parrot:IterateModules() do
		if type(v.OnOptionsCreate) == "function" then
			v:OnOptionsCreate()
		end
	end
end

function Parrot:OnOptionsCreate()
	self:AddOption('general', {
		type = 'group',
		name = L["General"],
		desc = L["General settings"],
		disabled = function()
			return not self:IsActive()
		end,
		args = {
			gameDamage = {
				type = 'boolean',
				name = L["Game damage"],
				desc = L["Whether to show damage over the enemy's heads."],
				get = function()
					return Parrot.db.profile.gameDamage
				end,
				set = function(value)
					Parrot.db.profile.gameDamage = value
					SetCVar("CombatDamage", value and "1" or "0")
				end,
			},
			gameHealing = {
				type = 'boolean',
				name = L["Game healing"],
				desc = L["Whether to show healing over the enemy's heads."],
				get = function()
					return Parrot.db.profile.gameHealing
				end,
				set = function(value)
					Parrot.db.profile.gameHealing = value
					SetCVar("CombatHealing", value and "1" or "0")
				end,
			},
			totemDamage = {
				type = 'boolean',
				name = L["Show guardian events"],
				desc = L["Whether events involving your guardian(s) (totems, ...) should be displayed"],
				get = function()
					return Parrot.db.profile.totemDamage
				end,
				set = function(value)
					Parrot.db.profile.totemDamage = value
				end,
				default = true,
			}
		}
	})
end

local addedOptions
function Parrot:AddOption(key, table)
	addedOptions[key] = table
end

Parrot.options = {
	name = L["Parrot"],
	desc = L["Floating Combat Text of awesomeness. Caw. It'll eat your crackers."],
	type = 'group',
	icon = [[Interface\Icons\Spell_Nature_ForceOfNature]],
	args = function()
		addedOptions = {}
		Parrot.addedOptions = addedOptions
		initOptions()
		Parrot.addedOptions = nil
		local tmp = addedOptions
		addedOptions = nil
		return "@cache", tmp
	end,
}

Parrot:SetConfigTable(Parrot.options)
