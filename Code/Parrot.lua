Parrot = LibStub("AceAddon-3.0"):NewAddon("Parrot", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
local Parrot, self = Parrot, Parrot
--@debug@
Parrot.version = "dev"
--@end-debug@

local L = LibStub("AceLocale-3.0"):GetLocale("Parrot")
local TimerFrame

local localeTables = {}

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")

--@debug@
-- function is not needed at all when debug is off
local function debugTableValues(table, tabs, stop)
	if not tabs then tabs = 0 end
	if stop then
		for k,v in pairs(table) do
			local line = ("  "):rep(tabs)
			line = line .. ("[%s]"):format(tonumber(k) or tostring(k))
			line = line .. (" = %s,"):format(tonumber(v) or tostring(v))
			ChatFrame4:AddMessage(line)
		end
	else
		for k,v in pairs(table) do
			local line = ("  "):rep(tabs)
			line = line .. ("[%s] = "):format(tonumber(k) or tostring(k))

			if type(v) == 'table' then
				ChatFrame4:AddMessage(line .. "{")
				debugTableValues(v, tabs + 1, true)
				ChatFrame4:AddMessage(("  "):rep(tabs) .. "}")
			else
				ChatFrame4:AddMessage("  " .. line .. tostring(v) .. ",")
			end
		end

	end
end--@end-debug@

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


--[[##########################################################################
--  ####################### Table recycling stuff ############################
--  ##########################################################################]]

local wipe = table.wipe
local weak = {__mode = 'kv'}
local pool = setmetatable({}, weak)
local activetables = {}

local function table_size(t)
	local c = 0
	for k in pairs(t) do
		c = c + 1
	end
	return c
end

local function psize()
	local c = 0
	for k in pairs(pool) do
		c = c + 1
	end
	return c
end
Parrot.psize = psize

local function newList(...)
	local t = next(pool)
	local n = select('#', ...)
	if t then
--		debug("taking ++", t, "++ from pool")
		pool[t] = nil
		for i = 1, n do
			t[i] = select(i, ...)
		end
	else
		t = { ... }
	end
	return t, n
end

local function newDict(...)

	local c = select('#', ...)
	local t = next(pool)
	if t then
		pool[t] = nil
	else
		t = {}
		debug("poolsize is now ", psize())
	end

	for i = 1, select('#', ...), 2 do
		local k, v = select(i, ...)
--		debug("assign ", k, " -> ", v)
		if k then
			t[k] = v
		else
--			debug("*********************************")
		end
	end
	activetables[t] = true
	return t
end

local function newSet(...)
	local t = next(pool)
	if t then
		pool[t] = nil
	else
		t = {}
	end

	for i = 1, select('#', ...) do
		t[select(i, ...)] = true
	end
	return t
end

local function del(t)
	if not t then
		error(("Bad argument #1 to `del'. Expected %q, got %q."):format("table", type(t)), 2)
	end
	if pool[t] then
		local _, ret = pcall(error, "Error, double-free syndrome.", 3)
		geterrorhandler()(ret)
	end
	setmetatable(t, nil)
	wipe(t)
	pool[t] = true
	return nil
end

local function f1(t, start, finish)
	if start > finish then
		wipe(t)
		pool[t] = true
		return
	end
	return t[start], f1(t, start+1, finish)
end
local function unpackListAndDel(t, start, finish)
	if not t then
		error(("Bad argument #1 to `unpackListAndDel'. Expected %q, got %q."):format("table", type(t)), 2)
	end
	if not start then
		start = 1
	end
	if not finish then
		finish = #t
	end
	setmetatable(t, nil)
	return f1(t, start, finish)
end

local function f2(t, current)
	current = next(t, current)
	if current == nil then
		wipe(t)
		pool[t] = true
		return
	end
	return current, f2(t, current)
end
local function unpackSetAndDel(t)
	if not t then
		error(("Bad argument #1 to `unpackListAndDel'. Expected %q, got %q."):format("table", type(t)), 2)
	end
	setmetatable(t, nil)
	return f2(t, nil)
end

local function f3(t, current)
	local value
	current, value = next(t, current)
	if current == nil then
		wipe(t)
		pool[t] = true
		return
	end
	return current, value, f3(t, current)
end
local function unpackDictAndDel(t)
	if not t then
		error(("Bad argument #1 to `unpackListAndDel'. Expected %q, got %q."):format("table", type(t)), 2)
	end
	setmetatable(t, nil)
	return f3(t, nil)
end

Parrot.newList = newList
Parrot.newDict = newDict
Parrot.newSet = newSet
Parrot.del = del
Parrot.unpackListAndDel = unpackListAndDel
Parrot.unpackSetAndDel = unpackSetAndDel
Parrot.unpackDictAndDel = unpackDictAndDel

--[[##########################################################################
--  ####################### End Table recycling stuff ########################
--  ##########################################################################]]

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
	self:RegisterChatCommand("par", "ShowConfig")
	self:RegisterChatCommand("parrot", "ShowConfig")

	-- use db1 to fool LibRock-1.0
	-- even without the RockDB-mixin, LibRock operates on self.db
	self.db1 = LibStub("AceDB-3.0"):New("ParrotDB", dbDefaults, "Default")

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
		},
	}

	LibStub("AceConfig-3.0"):RegisterOptionsTable("Parrot", Parrot.options)
	AceConfigDialog:AddToBlizOptions("Parrot", "Parrot")
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
	t["1"] = L["Inherit"]
	return t
end
function Parrot:OnEnable()
	if not TimerFrame then
		TimerFrame = CreateFrame("Frame", "ParrotTimerFrame", UIParent)
		TimerFrame:SetScript("OnUpdate", Parrot.OnUpdate)
	end

	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	_G.SHOW_COMBAT_TEXT = "0"
	if type(_G.CombatText_UpdateDisplayedMessages) == "function" then
	   _G.CombatText_UpdateDisplayedMessages()
	end

	if _G.CombatText_OnEvent then
		self:RawHook("CombatText_OnEvent", function()
			_G.SHOW_COMBAT_TEXT = "0"
			if type(_G.CombatText_UpdateDisplayedMessages) == "function" then
			   _G.CombatText_UpdateDisplayedMessages()
			end
		end, true)
	end

	SetCVar("CombatDamage", self.db1.profile.gameDamage and "1" or "0")
	SetCVar("CombatHealing", self.db1.profile.gameHealing and "1" or "0")

	SetCVar("CombatLogPeriodicSpells", 1)
	SetCVar("PetMeleeDamage", 1)
end

function Parrot:OnDisable()
	SetCVar("CombatDamage", "1")
	SetCVar("CombatHealing", "1")
	_G.SHOW_COMBAT_TEXT = "1"

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

local updateFrameMods = {}
local onUpdateFuncs = {}
function Parrot:OnUpdate()
	for _, v in ipairs(onUpdateFuncs) do
		v()
	end
end
function Parrot:RegisterOnUpdate(func)
	table.insert(onUpdateFuncs, func)
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
