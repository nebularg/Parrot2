local _, ns = ...
local Parrot = ns.addon
if not Parrot then return end

local module = Parrot:NewModule("TriggerConditions", "AceEvent-3.0")

local Parrot_Triggers

local del = Parrot.del

local conditions = {}
local secondaryConditions = {}

local primaryChoices = {}
local secondaryChoices = {}

function module:OnEnable()
	Parrot_Triggers = Parrot:GetModule("Triggers")
	Parrot:RegisterCombatLog(self)
end

function module:OnDisable()
	Parrot:UnregisterCombatLog(module)
end

-- #NODOC
function module:EventHandler(uid, event, arg1, ...)
	for _, data in next, conditions do
		if data.events then
			local info = data.events[event]
			if type(info) == "function" then
				info = info(arg1, ...)
			else
				info = info == arg1
			end
			if info then
				self:FirePrimaryTriggerCondition(data.name, info, uid, data.check)
			end
		end
	end
end

module.combatLogEvents = {}
--[[----------------------------------------------------------------------------------
Arguments:
	string - the name of the trigger condition to fire, in English.
	[optional] string or number - a vital argument to provide information about the trigger condition.
Notes:
	* You have to register a trigger condition with :RegisterPrimaryTriggerCondition(data) first.
	* In most cases, if you use normal events in the registration or Parser-3.0, this shouldn't need to be called.
Example:
	Parrot:FirePrimaryTriggerCondition("My trigger condition", 50)
------------------------------------------------------------------------------------]]
function module:FirePrimaryTriggerCondition(name, arg, uid)
	if Parrot_Triggers and Parrot_Triggers:IsEnabled() then
		local check
		if conditions[name] then
			check = conditions[name].check
		end
		Parrot_Triggers:OnTriggerCondition(name, arg, uid, check)
	end
end
Parrot.FirePrimaryTriggerCondition = module.FirePrimaryTriggerCondition

--[[----------------------------------------------------------------------------------
Arguments:
	table - a data table holding the details of a primary trigger condition.
Notes:
	The data table is of the following style:
	<pre>{
		name = "Name of the condition in English",
		localName = "Name of the condition in the current locale",
		events = { -- this is optional
			NAME_OF_EVENT = value, -- where NAME_OF_EVENT is the event to check, only works when value is equal to arg1. Also, value could be true in which case it is always checked.
			-- there can be multiple events.
		},
		param = {
			-- AceOptions argument here.
			-- do not specify get, set, name, or desc.
		}
	}</pre>
------------------------------------------------------------------------------------]]
function module:RegisterPrimaryTriggerCondition(data)
	local name = data.name
	if type(name) ~= "string" then
		error(("Bad argument #2 to `RegisterCombatEvent'. name must be a %q, got %q."):format("string", type(name)), 2)
	end
	local localName = data.localName
	if type(localName) ~= "string" then
		error(("Bad argument #2 to `RegisterCombatEvent'. localName must be a %q, got %q."):format("string", type(localName)), 2)
	end
	local events = data.events
	if events and type(events) ~= "table" then
		error(("Bad argument #2 to `RegisterCombatEvent'. events must be a %q, got %q."):format("table", type(events)), 2)
	end
	if conditions[name] then
		error(("Trigger condition %q already registered"):format(name), 2)
	end
	conditions[name] = data
	primaryChoices[name] = localName

	-- combatlog-stuff
	if data.combatLogEvents then
		local combatLogEvents = module.combatLogEvents
		for _, v in ipairs(data.combatLogEvents) do
			local eventType = v.eventType
			if not combatLogEvents[eventType] then
				combatLogEvents[eventType] = {}
			end
			table.insert(combatLogEvents[eventType], {
				category = data.category,
				name = data.name,
				triggerData = v.triggerData
			})
		end

	end

	-- Refresh events
	Parrot:UnregisterAllBlizzardEvents(module)
	if module:IsEnabled() then
		for k, v in next, conditions do
			if v.events then
				for event in next, v.events do
					Parrot:RegisterBlizzardEvent(module, event, "EventHandler")
				end
			end
		end
	end
end
Parrot.RegisterPrimaryTriggerCondition = module.RegisterPrimaryTriggerCondition

--[[----------------------------------------------------------------------------------
Arguments:
	table - a data table holding the details of a secondary trigger condition.
Notes:
	The data table is of the following style:
	<pre>{
		name = "Name of the condition in English",
		localName = "Name of the condition in the current locale",
		check = function(param)
			return GetSomeValue() == param
		end,
		defaultParam = 0.5, -- the default value
		param = {
			-- AceOptions argument here.
			-- do not specify get, set, name, or desc.
		}
	}</pre>
Example:
	Parrot:RegisterSecondaryTriggerCondition {
		name = "Minimum power amount",
		localName = L["Minimum power amount"],
		defaultParam = 0.5,
		param = {
			type = 'range',
			min = 0,
			max = 10000,
			step = 1,
			bigStep = 50,
		},
		check = function(param)
			if UnitIsDeadOrGhost("player") then
				return false
			end
			return UnitMana("player")/UnitManaMax("player") >= param
		end,
	}
------------------------------------------------------------------------------------]]
function module:RegisterSecondaryTriggerCondition(data)
	local name = data.name
	if type(name) ~= "string" then
		error(("Bad argument #2 to `RegisterCombatEvent'. name must be a %q, got %q."):format("string", type(name)), 2)
	end
	local localName = data.localName
	if type(localName) ~= "string" then
		error(("Bad argument #2 to `RegisterCombatEvent'. localName must be a %q, got %q."):format("string", type(localName)), 2)
	end
	secondaryConditions[name] = data
	secondaryChoices[name] = localName
	local notLocalName = data.notLocalName
	if type(notLocalName) == "string" then
		secondaryChoices["~" .. name] = notLocalName
	end
end
Parrot.RegisterSecondaryTriggerCondition = module.RegisterSecondaryTriggerCondition

-- #NODOC
function module:GetPrimaryConditionChoices()
	return primaryChoices
end

-- #NODOC
function module:GetSecondaryConditionChoices()
	return secondaryChoices
end

-- #NODOC
function module:GetPrimaryConditionParamDetails(name)
	local data = conditions[name]
	if not data then
		return
	end
	return data.param, data.defaultParam
end

function module:GetSecondary()
	return secondaryConditions
end

-- #NODOC
function module:GetSecondaryConditionParamDetails(name)
	local data = secondaryConditions[name]
	if not data then
		if name:find("^~") then
			data = secondaryConditions[name:sub(2)]
		end
		if not data then
			return
		end
	end
	return data.param, data.defaultParam
end

function module:IsExclusive(name)
	if not conditions[name] then
		return false
	else
		return not not conditions[name].exclusive
	end
end

function module:SecondaryIsExclusive(name)
	if name:match("^~.*") then
		name = name:sub(2)
	end
	if not secondaryConditions[name] then
		return false
	else
		return not not secondaryConditions[name].exclusive
	end
end

-- #NODOC
function module:DoesSecondaryTriggerConditionPass(name, arg)
	local notted = false
	if name:find("^~") then
		notted = true
		name = name:sub(2)
	end
	local data = secondaryConditions[name]
	if not data then
		return false
	end
	if not arg and data.param then
		return false
	end
	local value = data.check(arg)
	if notted then
		return not value
	else
		return value
	end
end

function module:HandleCombatlogEvent(uid, timestamp, eventType, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	local registeredHandlers = self.combatLogEvents[eventType]
	if registeredHandlers then
		for _,v in ipairs(registeredHandlers) do
			local arg = v.triggerData(sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...)
			if arg == true then
				self:FirePrimaryTriggerCondition(v.name, nil, uid)
			else
				self:FirePrimaryTriggerCondition(v.name, arg, uid)
			end
			if type(arg) == 'table' then
				arg = del(arg)
			end
		end
	end
end
