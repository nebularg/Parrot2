local Parrot = LibStub("AceAddon-3.0"):NewAddon("Parrot", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
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
	AceConfig:RegisterOptionsTable("Parrot", Parrot.options)
end

local dbDefaults = {
	profile = {
		gameText = false,
		gameDamage = false,
		gameHealing = false,
	}
}
local dbpr

function Parrot:OnInitialize()
	self:RegisterChatCommand("par", "ShowConfig")
	self:RegisterChatCommand("parrot", "ShowConfig")

	-- use db1 to fool LibRock-1.0
	-- even without the RockDB-mixin, LibRock operates on self.db
	self.db1 = LibStub("AceDB-3.0"):New("ParrotDB", dbDefaults, "Default")

	self.db1.RegisterCallback(self, "OnProfileChanged", "ChangeProfile")
	self.db1.RegisterCallback(self, "OnProfileCopied", "ChangeProfile")
	self.db1.RegisterCallback(self, "OnProfileReset", "ChangeProfile")
	dbpr = self.db1.profile
	Parrot.options = {
		name = L["Parrot"],
		desc = L["Floating Combat Text of awesomeness. Caw. It'll eat your crackers."],
		type = 'group',
		icon = [[Interface\Icons\Spell_Nature_ForceOfNature]],
		args = {},
	}
	local bliz_options = CopyTable(Parrot.options)
	bliz_options.args.load = {
		name = L["Load config"],
		desc = L["Load configuration options"],
		type = 'execute',
		func = "ShowConfig",
		handler = Parrot,
	}

	LibStub("AceConfig-3.0"):RegisterOptionsTable("Parrot_bliz", bliz_options)
	AceConfigDialog:AddToBlizOptions("Parrot_bliz", "Parrot")
end

function Parrot:ChangeProfile()
	dbpr = self.db1.profile
	for k,v in Parrot:IterateModules() do
		if type(v.ChangeProfile) == 'function' then
			v:ChangeProfile()
		end
	end
end

function Parrot.inheritFontChoices()
	local t = newList()
	for _,v in ipairs(SharedMedia:List('font')) do
		t[v] = v
	end
	t["1"] = L["Inherit"]
	return t
end
function Parrot:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	if dbpr.gameText then
		SetCVar("CombatDamage", dbpr.gameDamage and "1" or "0")
		SetCVar("CombatHealing", dbpr.gameHealing and "1" or "0")
		SetCVar("CombatLogPeriodicSpells", 1)
		SetCVar("PetMeleeDamage", 1)
	end
	self:ChangeProfile()
end

Parrot.IsActive = Parrot.IsEnabled

function Parrot:OnDisable()
	for name, module in self:IterateModules() do
		self:DisableModule(module)
	end
end

function Parrot:ShowConfig()
	initOptions()
	AceConfigDialog:Open("Parrot")
end

local uid = 0
local function nextUID()
	uid = uid + 1
	return uid
end

local combatLogHandlers = {}

function Parrot:RegisterCombatLog(mod)
	if type(mod.HandleCombatlogEvent) ~= 'function' then
		error("mod must have function named HandleCombatlogEvent")
	end
	table.insert(combatLogHandlers, mod)
end

function Parrot:UnregisterCombatLog(mod)
	for i,v in ipairs(combatLogHandlers) do
		if v == mod then
			table.remove(i)
		end
	end
end

function Parrot:COMBAT_LOG_EVENT_UNFILTERED(...)
	local uid = nextUID()
	for _, v in ipairs(combatLogHandlers) do
		v:HandleCombatlogEvent(uid, ...)
	end
end

local blizzardEventHandlers = {}

function Parrot:RegisterBlizzardEvent(mod, eventName, handlerfunc)
	if handlerfunc then
		if type(mod[handlerfunc]) ~= 'function' then
			error(("Bad argument #2 for 'RegisterBlizzardEvent'. module must contain a function named %s"):format(handlerfunc))
		end
	else
		if type(mod[eventName]) ~= 'function' then
			error(("Bad argument #2 for 'RegisterBlizzardEvent'. module must contain a function named %s"):format(eventName))
		end
	end

	if not blizzardEventHandlers[eventName] then
		blizzardEventHandlers[eventName] = {}
		self:RegisterEvent(eventName, "OnBlizzardEvent")
	end
	if not blizzardEventHandlers[eventName][mod] then
		blizzardEventHandlers[eventName][mod] = {}
	end

	blizzardEventHandlers[eventName][mod] = handlerfunc or eventName

end

function Parrot:UnRegisterBlizzardEvent(mod, eventName)
	blizzardEventHandlers[eventName][mod] = nil
	if not next(blizzardEventHandlers[eventName]) then
		self:RemoveEventListener(eventName)
		blizzardEventHandlers[eventName] = nil
	end
end

function Parrot:UnRegisterAllEvents(mod)
	for eventName,v in pairs(blizzardEventHandlers) do
		v[mod] = nil
	end
end

function Parrot:OnBlizzardEvent(eventName, ...)
	local uid = nextUID()
	for k,v in pairs(blizzardEventHandlers[eventName]) do
		k[v](k, uid, eventName, ...)
	end
end

local function setOption(info, value)
	local name = info[#info]
	dbpr[name] = value
end
local function getOption(info)
	local name = info[#info]
	return dbpr[name]
end

function Parrot:OnOptionsCreate()
	self:AddOption("profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db1))
	self.options.args.profiles.order = -1
	self:AddOption('general', {
			type = 'group',
			name = L["General"],
			desc = L["General settings"],
			disabled = function()
				return not self:IsEnabled()
			end,
			order = 1,
			args = {
				gameText = {
					type = 'group',
					inline = true,
					name = L["Game options"],
					set = setOption,
					get = getOption,
					args = {
						gameText = {
							type = 'toggle',
							name = L["Control game options"],
							desc = L["Whether Parrot should control the default interface's options below.\nThese settings always override manual changes to the default interface options."],
							order = 1,
						},
						gameDamage = {
							type = 'toggle',
							name = L["Game damage"],
							desc = L["Whether to show damage over the enemy's heads."],
							disabled = function() return not dbpr.gameText end,
							set = function(info, value)
								setOption(info, value)
								SetCVar("CombatDamage", value and "1" or "0")
							end,
							order = 2,
						},
						gameHealing = {
							type = 'toggle',
							name = L["Game healing"],
							desc = L["Whether to show healing over the enemy's heads."],
							disabled = function() return not dbpr.gameText end,
							set = function(info, value)
								setOption(info, value)
								SetCVar("CombatHealing", value and "1" or "0")
							end,
							order = 3,
						},
					},
				},
			}
	})
end

function Parrot:AddOption(key, table)
	self.options.args[key] = table
end

Parrot.options = {
	name = L["Parrot"],
	desc = L["Floating Combat Text of awesomeness. Caw. It'll eat your crackers."],
	type = 'group',
	icon = [[Interface\Icons\Spell_Nature_ForceOfNature]],
	args = {},
}
