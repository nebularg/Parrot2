-- local VERSION = tonumber(("$Revision: 425 $"):match("%d+"))

local Parrot = Parrot
local Parrot_Triggers = Parrot:NewModule("Triggers", "LibRockTimer-1.0")

local L = LibStub("AceLocale-3.0"):GetLocale("Parrot_Triggers")
local BCL = LibStub("LibBabble-Class-3.0"):GetLookupTable()

local newList, newSet, newDict, del, unpackDictAndDel = Rock:GetRecyclingFunctions("Parrot", "newList", "newSet", "newDict", "del", "unpackDictAndDel")

local debug = Parrot.debug

local _,playerClass = UnitClass("player")

local SharedMedia = LibStub("LibSharedMedia-3.0")

Parrot_Triggers.db = Parrot:GetDatabaseNamespace("Triggers")

Parrot:SetDatabaseNamespaceDefaults("Triggers", 'profile', {})

local default_triggers = {
			{
				id = 1,
				-- 34939 = Backlash
				name = L["%s!"]:format(GetSpellInfo(34939)),
				icon = 34939,
				class = "WARLOCK",
				conditions = {
					["Self buff gain"] = GetSpellInfo(34939),
				},
				sticky = true,
				color = "ff00ff",
				locale = GetLocale(),
			},
			{
				-- 16246 = Clearcasting (Priest) TODO
				id = 3,
				name = L["%s!"]:format(GetSpellInfo(16246)),
				icon = 16246,
				class = "MAGE;PRIEST;SHAMAN",
				conditions = {
					["Self buff gain"] = GetSpellInfo(16246),
				},
				sticky = true,
				color = "ffff00",
				locale = GetLocale(),
			},
			{
				id = 4,
				-- 27067 = Counterattack
				name = L["%s!"]:format(GetSpellInfo(27067)),
				icon = 27067,
				class = "HUNTER",
				conditions = {
					["Incoming parry"] = true,
				},
				secondaryConditions = {
					["Spell ready"] = GetSpellInfo(27067),
				},
				sticky = true,
				color = "ffff00",
				locale = GetLocale(),
			},
			{
				id = 5,
				-- 25236 = Execute
				name = L["%s!"]:format(GetSpellInfo(25236)),
				icon = 25236,
				class = "WARRIOR",
				conditions = {
					["Enemy target health percent"] = 0.19,
				},
				secondaryConditions = {
					["Spell ready"] = GetSpellInfo(25236),
				},
				sticky = true,
				color = "ffff00",
				locale = GetLocale(),
			},
			{
				id = 6,
				-- Frostbite = 12497
				name = L["%s!"]:format(GetSpellInfo(12497)),
				icon = 12497,
				class = "MAGE",
				conditions = {
					["Target debuff gain"] = GetSpellInfo(12497),
				},
				sticky = true,
				color = "0000ff",
				locale = GetLocale(),
			},
			{
					id = 7,
				-- 27180 - Hammer of Wrath
				name = L["%s!"]:format(GetSpellInfo(27180)),
				icon = 27180,
				class = "PALADIN",
				conditions = {
					["Enemy target health percent"] = 0.2,
				},
				secondaryConditions = {
					["Spell ready"] = GetSpellInfo(27180),
				},
				sticky = true,
				color = "ffff00",
				locale = GetLocale(),
			},
			{
				id = 8,
				-- Impact = 11103
				name = L["%s!"]:format(GetSpellInfo(11103)),
				icon = 11103,
				class = "MAGE",
				conditions = {
					["Target debuff gain"] = GetSpellInfo(11103),
				},
				sticky = true,
				color = "ff0000",
				locale = GetLocale(),
			},
			{
				id = 9,
				-- Kill Command = 34026
				name = L["%s!"]:format(GetSpellInfo(34026)),
				icon = 34026,
				class = "HUNTER",
				conditions = {
					["Outgoing crit"] = true,
				},
				secondaryConditions = {
					["Spell ready"] = GetSpellInfo(34026),
				},
				sticky = true,
				color = "ff0000",
				disabled = true,
				locale = GetLocale(),
			},
			{
				id = 10,
				name = L["Low Health!"],
				class = "DRUID;HUNTER;MAGE;PALADIN;PRIEST;ROGUE;SHAMAN;WARLOCK;WARRIOR;DEATHKNIGHT",
				conditions = {
					["Self health percent"] = 0.4,
				},
				secondaryConditions = {
					["Trigger cooldown"] = 3,
				},
				sticky = true,
				color = "ff7f7f",
				locale = GetLocale(),
			},
			{
				id = 11,
				name = L["Low Mana!"],
				class = "DRUID;HUNTER;MAGE;PALADIN;PRIEST;SHAMAN;WARLOCK",
				conditions = {
					["Self mana percent"] = 0.35,
				},
				secondaryConditions = {
					["Trigger cooldown"] = 3,
				},
				sticky = true,
				color = "7f7fff",
				locale = GetLocale(),
			},
			{
				id = 12,
				name = L["Low Pet Health!"],
				class = "HUNTER;MAGE;WARLOCK;DEATHKNIGHT",
				conditions = {
					["Pet health percent"] = 0.4,
				},
				secondaryConditions = {
					["Trigger cooldown"] = 3,
				},
				color = "ff7f7f",
				locale = GetLocale(),
			},
			{
				id = 13,
				-- Mongoose Bite = 36916
				name = L["%s!"]:format(GetSpellInfo(36916)),
				icon = 36916,
				class = "HUNTER",
				conditions = {
					["Incoming dodge"] = true,
				},
				secondaryConditions = {
					["Spell ready"] = GetSpellInfo(36916),
				},
				sticky = true,
				color = "ffff00",
				locale = GetLocale(),
			},
			{
				id = 14,
				-- 18095 = Nightfall
				name = L["%s!"]:format(GetSpellInfo(18095)),
				icon = 18095,
				class = "WARLOCK",
				conditions = {
					-- 17941 = Shadow Trance
					["Self buff gain"] = GetSpellInfo(17941),
				},
				sticky = true,
				color = "7f007f",
				locale = GetLocale(),
			},
			{
				id = 15,
				-- Smite = 25364
				name = L["Free %s!"]:format(GetSpellInfo(25364)),
				icon = 25364,
				class = "PRIEST",
				conditions = {
					-- Surge of Light =33154
					["Self buff gain"] = GetSpellInfo(33154),
				},
				sticky = true,
				disabled = true,
				color = "ff0000",
				locale = GetLocale(),
			},
			{
				id = 16,
				-- Overpower = 11585
				name = L["%s!"]:format(GetSpellInfo(11585)),
				icon = 11585,
				class = "WARRIOR",
				conditions = {
					["Outgoing dodge"] = true,
				},
				secondaryConditions = {
					["Spell ready"] = GetSpellInfo(11585),
				},
				sticky = true,
				color = "7f007f",
				locale = GetLocale(),
			},
			{
				id = 17,
				-- Rampage = 29801
				name = L["%s!"]:format(GetSpellInfo(29801)),
				icon = 29801,
				class = "WARRIOR",
				conditions = {
					["Outgoing crit"] = true,
				},
				secondaryConditions = {
					["Spell ready"] = GetSpellInfo(29801),
					["Buff inactive"] = GetSpellInfo(29801),
					["Minimum power amount"] = 20,
				},
				sticky = true,
				color = "ff0000",
				locale = GetLocale(),
			},
			{
				id = 18,
				-- Revenge = 30357
				name = L["%s!"]:format(GetSpellInfo(30357)),
				icon = 30357,
				class = "WARRIOR",
				conditions = {
					["Incoming block"] = true,
					["Incoming dodge"] = true,
					["Incoming parry"] = true,
				},
				secondaryConditions = {
					["Spell ready"] = GetSpellInfo(30357),
					["Warrior stance"] = "Defensive Stance",
				},
				sticky = true,
				color = "ffff00",
				disabled = true,
				locale = GetLocale(),
			},
			{
				id = 19,
				-- Riposte = 14251
				name = L["%s!"]:format(GetSpellInfo(14251)),
				icon = 14251,
				class = "ROGUE",
				conditions = {
					["Incoming parry"] = true,
				},
				secondaryConditions = {
					["Spell ready"] = GetSpellInfo(14251),
				},
				sticky = true,
				color = "ffff00",
				locale = GetLocale(),
			},
			{
				id = 20,
				-- Maelstrom Weapon = 51532
				name = L["%s!"]:format(GetSpellInfo(51532)),
				icon = 51532,
				class = "SHAMAN",
				conditions = {
				      ["Self buff stacks gain"] = string.format("%s,%s",GetSpellInfo(51532),"5"),
				},
				sticky = true,
				color = "0000ff",
				locale = GetLocale(),
			},
			-- 4 Deathknight-triggers by waallen
			{
				id = 22,
				-- Freezing Fog = 59052
				name = L["%s!"]:format(GetSpellInfo(59052)),
				icon = 59052,
				class = "DEATHKNIGHT",
				conditions = {
					-- 59052 = Freezing Fog
					["Self buff gain"] = GetSpellInfo(59052),
				},
				sticky = true,
				color = "0000ff",
				locale = GetLocale(),
			},
			{
				id = 23,
				-- Killing Machine	= 51130
				name = L["%s!"]:format(GetSpellInfo(51130)),
				icon = 51130,
				class = "DEATHKNIGHT",
				conditions = {
					-- 51130 = Killing Machine
					["Self buff gain"] = GetSpellInfo(51130),
				},
				sticky = true,
				color = "0000ff",
				locale = GetLocale(),
			},
			{
				id = 24,
				-- Rune Strike = 56816
				name = L["%s!"]:format(GetSpellInfo(56816)),
				icon = 56816,
				class = "DEATHKNIGHT",
				conditions = {
					["Incoming dodge"] = true,
					["Incoming parry"] = true,
				},
				sticky = true,
				color = "0000ff",
				disabled = true,
				locale = GetLocale(),
			},
	}
	

local effectiveRegistry = {}
local function rebuildEffectiveRegistry()
	for i = 1, #effectiveRegistry do
		effectiveRegistry[i] = nil
	end
	for _,v in ipairs(Parrot_Triggers.db.profile.triggers) do
		if not v.disabled then
			local classes = newSet((';'):split(v.class))
			if classes[playerClass] then
				effectiveRegistry[#effectiveRegistry+1] = v
			end
			classes = del(classes)
		end
	end	
end

-- so triggers can be enabled/disabled from outside
function Parrot_Triggers:setTriggerEnabled(triggerindex, enabled)
	self.db.profile.triggers[triggerindex].disabled = not enabled
	rebuildEffectiveRegistry()
end

local cooldowns = {}
local currentTrigger
local Parrot_TriggerConditions
local Parrot_Display
local Parrot_ScrollAreas
local Parrot_CombatEvents
function Parrot_Triggers:OnInitialize()
	Parrot_Display = Parrot:GetModule("Display")
	Parrot_ScrollAreas = Parrot:GetModule("ScrollAreas")
	Parrot_TriggerConditions = Parrot:GetModule("TriggerConditions")
	Parrot_CombatEvents = Parrot:GetModule("CombatEvents")
end


	

function Parrot_Triggers:OnEnable(first)
	if not self.db.profile.triggers then
		self.db.profile.triggers = default_triggers
	else
	
		-- so that newly introduced triggers always get added.
		-- this also adds previously removed default-triggers
		
		for i,v in ipairs(default_triggers) do
		
			local found = false
			
			for i2, v2 in ipairs(self.db.profile.triggers) do
				if v2.name == v.name then
					found = true
					break
				end
			end
			
			if not found then
				table.insert(self.db.profile.triggers,v)
			end
			
		end
	
	end
	
	self:AddRepeatingTimer(0.1, function()
		Parrot:FirePrimaryTriggerCondition("Check every XX seconds")
	end)
	if first then
		Parrot_TriggerConditions:RegisterSecondaryTriggerCondition {
			name = "Trigger cooldown",
			localName = L["Trigger cooldown"],
			defaultParam = 3,
			param = {
				type = 'number',
				min = 0,
				max = 60,
				step = 0.1,
				bigStep = 1,
			},
			check = function(param)
				if not cooldowns[currentTrigger] then
					return true
				end
				local now = GetTime()
				return now - cooldowns[currentTrigger] > param
			end,
		}
		
		Parrot:RegisterPrimaryTriggerCondition {
			name = "Check every XX seconds",
			localName = L["Check every XX seconds"],
			defaultParam = 3,
			param = {
				type = 'number',
				min = 0,
				max = 60,
				step = 0.1,
				bigStep = 1,
			},
		}
		
		for _,data in ipairs(self.db.profile.triggers) do
			local t = newList()
			for k,v in pairs(data.conditions) do
				t[k] = v
				data.conditions[k] = nil
			end
			local choices = Parrot_TriggerConditions:GetPrimaryConditionChoices()
			for k,v in pairs(t) do
				if choices[k] then
					data.conditions[k] = v
					t[k] = nil
				else
					local k_lower = k:lower()
					for l,u in pairs(choices) do
						if l:lower() == k_lower then
							data.conditions[l] = v
							t[k] = nil
						end
					end
					if t[k] then
						data.conditions[k] = v
						t[k] = nil
					end
				end
			end
			t = del(t)
			if data.secondaryConditions then
				local t = newList()
				for k,v in pairs(data.secondaryConditions) do
					t[k] = v
					data.secondaryConditions[k] = nil
				end
				local choices = Parrot_TriggerConditions:GetSecondaryConditionChoices()
				for k,v in pairs(t) do
					if choices[k] then
						data.secondaryConditions[k] = v
						t[k] = nil
					else
						local k_lower = k:lower()
						for l,u in pairs(choices) do
							if l:lower() == k_lower then
								data.secondaryConditions[l] = v
								t[k] = nil
							end
						end
						if t[k] then
							data.secondaryConditions[k] = v
							t[k] = nil
						end
					end
				end
				t = del(t)
			end
		end
	end
	
	rebuildEffectiveRegistry()
end

local function hexColorToTuple(color)
	local num = tonumber(color, 16)
	return math.floor(num / 256^2)/255, math.floor((num / 256)%256)/255, (num%256)/255
end

-- to find the icon for old saved variables

local oldIconName = {
	["Backlash"] = 34939,
	["Blackout"] = 15326,
	["Clearcasting"] = 16246,
	["Counterattack"] = 27067,
	-- ["Execute"] = 25236, -- not needed
	["Frostbite"] = 12497,
	["Impact"] = 12360,
	["Kill Command"] = 34026,
	["Mongoose Bite"] = 36916,
	["Nightfall"] = 18095,
	-- ["Smite"] = 25364, -- not needed
	["Overpower"] = 11585,
	["Rampage"] = 30033,
	["Revenge"] = 30357,
	["Riposte"] = 14251,
	
}

local function figureIconPath(icon)
	if not icon then
		return nil
	end

	local path
	
	-- if the icon is a number, it's most likly a spellid
	local spellId = tonumber(icon)
	if spellId then
		path = select(3,GetSpellInfo(spellId))
		return path
	end
	
	-- if the spell is in the spellbook, the icon can be retrieved that way
	path = select(3, GetSpellInfo(icon))
	if path then
		return path
	end
	
	-- the last chance is, that it's an option saved by an old parrot version
	-- the strings from the default-options can be resolved by the table provided above
	local oldIcon = oldIconName[icon]
	if oldIcon then
		path = select(3, GetSpellInfo(oldIcon))
		if path then
			return path
		end
	end
	
	-- perhaps it's an item
	local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(icon)
	if texture then
		return texture
	end
	-- nothing worked, either it's a path or a spell where the icon cannot be retrieved
	return icon
end

local numberedConditions = {}
local timerCheck = {}

function Parrot_Triggers:OnTriggerCondition(name, arg, uid)
	if UnitIsDeadOrGhost("player") then
		return
	end
	for _,v in ipairs(effectiveRegistry) do
		local conditions = v.conditions
		if conditions then
			local param = conditions[name]
			if param then
				local good = false
				if param == true then
				 	good = true
				elseif type(arg) == "string" then
					good = param == arg
				elseif type(arg) == "number" then
					if not numberedConditions[v] then
						numberedConditions[v] = newList()
					end
					good = arg <= param and (not numberedConditions[v][name] or numberedConditions[v][name] > param)
					numberedConditions[v][name] = arg
				elseif name == "Check every XX seconds" then
					local val = timerCheck[name]
					if not val then
						val = 0
					end
					if param == 0 then
						val = 0
					else
						val = (val + 0.1) % param
					end
					timerCheck[name] = val
					if val < 0.1 then
						good = true
					end
				end
				if good then
					local secondaryConditions = v.secondaryConditions
					if secondaryConditions then
						currentTrigger = v.name
						for k, v in pairs(secondaryConditions) do
							if not Parrot_TriggerConditions:DoesSecondaryTriggerConditionPass(k, v) then
								good = false
								break
							end
						end
					end
					if good and Parrot_TriggerConditions:DoesSecondaryTriggerConditionPass("Trigger cooldown", 0.1) then
						cooldowns[v.name] = GetTime()
						local r, g, b = hexColorToTuple(v.color or 'ffffff')
						local icon = figureIconPath(v.icon)
						-- getIconById(v.iconSpellId) or figureIconPath(v.icon)
						
						Parrot_Display:ShowMessage(v.name, v.scrollArea or "Notification", v.sticky, r, g, b, v.font, v.fontSize, v.outline, icon)
						
						if v.sound then
							local sound = SharedMedia:Fetch('sound', v.sound)
							if sound then
								PlaySoundFile(sound)
							end
						end
						if uid then
							Parrot_CombatEvents:CancelEventsWithUID(uid)
						end
					end
				end
			end
		end
	end
end

local function getSoundChoices()
	local t = {}
	for _,v in ipairs(SharedMedia:List("sound")) do
		t[v] = v
	end
	return t
end

function Parrot_Triggers:OnOptionsCreate()
	
	local acetype = {
		['number'] = 'range',
		['string'] = 'input',
		['boolean'] = 'toggle',
	}	
		
	local makeOption
	local remove
	local triggers_opt = {
		type = 'group',
		name = L["Triggers"],
		desc = L["Triggers"],
		disabled = function()
			return not self:IsActive()
		end,
		args = {
			new = {
				type = 'execute',
--				buttonText = L["Create"],
				name = L["New trigger"],
				desc = L["Create a new trigger"],
				func = function()
					local t = {
						name = L["New trigger"],
						class = "DRUID;HUNTER;MAGE;PALADIN;PRIEST;ROGUE;SHAMAN;WARLOCK;WARRIOR;DEATHKNIGHT",
						conditions = {},
					}
					local registry = self.db.profile.triggers
					registry[#registry+1] = t
					makeOption(t)
					rebuildEffectiveRegistry()
				end,
				disabled = function()
					if not self.db.profile.triggers then
						return true
					end
					for _,v in ipairs(self.db.profile.triggers) do
						if v.name == L["New trigger"] then
							return true
						end
					end
					return false
				end
			},
			cleanup = {
				type = 'execute',
				order = 21,
				name = L["Cleanup Triggers"],
				-- buttonText = L["Cleanup Triggers"],
				desc = L["Delete all Triggers that belong to a different locale"],
				func = function()

					for _,v in ipairs(self.db.profile.triggers) do					
						if v.locale and v.locale ~= GetLocale() then

							Parrot:Print(string.format("Deleting Trigger \"%s\" because it is \'%s\'", v.name, v.locale))
							remove(v)
							
						end
					end
				end,
			}
		}
	}
	Parrot:AddOption('triggers', triggers_opt)
	
	local function getFontFace(t)
		local font = t.arg.font
		if font == nil then
--			return L["Inherit"]
			return "1"
		else
			return font
		end
	end
	local function setFontFace(t, value)
		if value == "1" then
			value = nil
		end
		t.arg.font = value
	end
	local function getFontSize(t)
		return t.arg.fontSize
	end
	local function setFontSize(t, value)
		t.arg.fontSize = value
	end
	local function getFontSizeInherit(t)
		return t.arg.fontSize == nil
	end
	local function setFontSizeInherit(t, value)
		if value then
			t.arg.fontSize = nil
		else
			t.arg.fontSize = 18
		end
	end
	local function getFontOutline(t)
		local outline = t.arg.fontOutline
		if outline == nil then
			return L["Inherit"]
		else
			return outline
		end
	end
	local function setFontOutline(t, value)
		if value == L["Inherit"] then
			value = nil
		end
		t.arg.fontOutline = value
	end
	local fontOutlineChoices = {
		NONE = L["None"],
		OUTLINE = L["Thin"],
		THICKOUTLINE = L["Thick"],
		[L["Inherit"]] = L["Inherit"],
	}
	local function getEnabled(t)
		return not t.arg.disabled
	end
	local function setEnabled(t, value)
		t.arg.disabled = not value or nil
		rebuildEffectiveRegistry()
	end
	local function getScrollArea(t)
		return t.arg.scrollArea or "Notification"
	end
	local function setScrollArea(t, value)
		if value == "Notification" then
			value = nil
		end
		t.arg.scrollArea = value
	end
	-- not local, declared above
	function remove(t)
		triggers_opt.args[tostring(t.arg)] = nil
		for i,v in ipairs(self.db.profile.triggers) do
			if v == t.arg then
				table.remove(self.db.profile.triggers, i)
				break
			end
		end
		rebuildEffectiveRegistry()
	end
	local function getSticky(t)
		return t.arg.sticky
	end
	local function setSticky(t, value)
		t.arg.sticky = value or nil
	end
	local function getName(t)
		return t.arg.name
	end
	local function setName(t, value)
		t.arg.name = value
		local opt = triggers_opt.args[tostring(t.arg)]
		opt.name = value
		opt.desc = value
		opt.order = value == L["New trigger"] and -110 or -100
	end
	
	local function getIcon(t)
		return tostring(t.arg.icon) or ''
	end
	local function setIcon(t, value)
		if value == '' then
			value = nil
		end
		t.arg.icon = tonumber(value) or value
	end
	
	local function tupleToHexColor(r, g, b)
		return ("%02x%02x%02x"):format(r * 255, g * 255, b * 255)
	end
	
	local function getColor(t)
		return hexColorToTuple(t.arg.color or "ffffff")
	end
	local function setColor(t, r, g, b)
		local color = tupleToHexColor(r, g, b)
		if color == "ffffff" then
			color = nil
		end
		t.arg.color = color
	end
	
	local function getClass(t, class)
		local tmp = newSet((";"):split(t.arg.class))
		local value = tmp[class]
		tmp = del(tmp)
		return value
	end
	
	local function setClass(t, class, value)
		local tmp = newSet((";"):split(t.arg.class))
		tmp[class] = value or nil
		local tmp2 = newList()
		for k in pairs(tmp) do
			tmp2[#tmp2+1] = k
		end
		tmp = del(tmp)
		t.arg.class = table.concat(tmp2, ";")
		tmp2 = del(tmp2)
		if class == playerClass then
			rebuildEffectiveRegistry()
		end
	end
	
	local function getSound(t)
		return t.arg.sound or "None"
	end
	
	local function setSound(t, value)
		PlaySoundFile(SharedMedia:Fetch('sound', value))
		if value == "None" then
			value = nil
		end
		t.arg.sound = value
	end
	
	local function test(t)
		local t = t
		if t.arg then
			t = t.arg
		end
		local r, g, b = hexColorToTuple(t.color or 'ffffff')
		--TODO
		Parrot_Display:ShowMessage(t.name, t.scrollArea or "Notification", t.sticky, r, g, b, t.font, t.fontSize, t.outline, figureIconPath(t.icon))
		if t.sound then
			local sound = SharedMedia:Fetch('sound', t.sound)
			if sound then
				PlaySoundFile(sound)
			end
		end
	end
	
	local classChoices = {
		DRUID = BCL["Druid"],
		ROGUE = BCL["Rogue"],
		SHAMAN = BCL["Shaman"],
		PALADIN = BCL["Paladin"],
		MAGE = BCL["Mage"],
		WARLOCK = BCL["Warlock"],
		PRIEST = BCL["Priest"],
		WARRIOR = BCL["Warrior"],
		HUNTER = BCL["Hunter"],
		DEATHKNIGHT = BCL["Deathknight"],
	}
	
	local function addPrimaryCondition(t, name, localName)
		local opt = triggers_opt.args[tostring(t)].args.primary
		local param, default = Parrot_TriggerConditions:GetPrimaryConditionParamDetails(name)
		if not param then
			opt.args[name] = newDict(
				'type', 'execute',
				-- 'buttonText', "---",
				'name', localName,
				'desc', localName,
				'func', function() end,
				'order', -100
			)
			return true
		else
			local tmp = newDict(
				'name', localName,
				'desc', localName,
				'get', function()
					return t.conditions[name]
				end,
				'set', function(info, value)
					t.conditions[name] = value
				end,
				'order', -100
			)
			for k, v in pairs(param) do
				if k == "type" then
					tmp[k] = acetype[v] or v
				else
					tmp[k] = v
				end
				
			end
			opt.args[name] = tmp
			if default then
				return default
			end
			if type(param.min) == "number" and type(param.max) == "number" then
				return (param.max + param.min) / 2
			end
			return false
		end
	end
	local function newPrimaryCondition(t, name)
		local t = t.arg
		local opt = triggers_opt.args[tostring(t)].args.primary
		local localName = Parrot_TriggerConditions:GetPrimaryConditionChoices()[name]
		t.conditions[name] = addPrimaryCondition(t, name, localName)
	end
	local function removePrimaryCondition(t, name)
		local t = t.arg
		local opt = triggers_opt.args[tostring(t)].args.primary
		opt.args[name] = del(opt.args[name])
		t.conditions[name] = nil
	end
	local function hasNoPrimaryConditions(t)
		return next(t.arg.conditions) == nil
	end
	local function hasAllPrimaryConditions(t)
		for k,v in pairs(Parrot_TriggerConditions:GetPrimaryConditionChoices()) do
			if t.arg.conditions[k] == nil then
				return false
			end
		end
		return true
	end
	local function getAvailablePrimaryConditions(t)
		local tmp = newList()
		for k,v in pairs(Parrot_TriggerConditions:GetPrimaryConditionChoices()) do
			if not t.arg.conditions[k] then
				tmp[k] = v
			end
		end
		return tmp
	end
	local function getUsedPrimaryConditions(t)
		local tmp = newList()
		for k,v in pairs(Parrot_TriggerConditions:GetPrimaryConditionChoices()) do
			if t.arg.conditions[k] then
				tmp[k] = v
			end
		end
		return tmp
	end
	
	local function addSecondaryCondition(t, name, localName)
		local opt = triggers_opt.args[tostring(t)].args.secondary
		local param, default = Parrot_TriggerConditions:GetSecondaryConditionParamDetails(name)
		if not param then
			opt.args[name] = newDict(
				'type', 'execute',
				-- 'buttonText', "---",
				'name', localName,
				'desc', localName,
				'func', function() end,
				'order', -100
			)
			return true
		else
			local tmp = newDict(
				'name', localName,
				'desc', localName,
				'get', function()
					return t.secondaryConditions[name]
				end,
				'set', function(info, value)
					t.secondaryConditions[name] = value
				end,
				'order', -100
			)
			for k, v in pairs(param) do
				-- TODO remove
				if k ~= "usage" then
					
			
				if k == "type" then
					tmp[k] = acetype[v] or v
				else
					tmp[k] = v
				end
				
				end
			end
			opt.args[name] = tmp
			if default then
				return default
			end
			if type(param.min) == "number" and type(param.max) == "number" then
				return (param.max + param.min) / 2
			end
			return false
		end
	end
	local function newSecondaryCondition(t, name)
		local t = t.arg
		local opt = triggers_opt.args[tostring(t)].args.secondary
		local localName = Parrot_TriggerConditions:GetSecondaryConditionChoices()[name]
		if not t.secondaryConditions then
			t.secondaryConditions = newList()
		end
		t.secondaryConditions[name] = addSecondaryCondition(t, name, localName)
	end
	local function removeSecondaryCondition(t, name)
		local t = t.arg
		local opt = triggers_opt.args[tostring(t)].args.secondary
		opt.args[name] = del(opt.args[name])
		t.secondaryConditions[name] = nil
		if next(t.secondaryConditions) == nil then
			t.secondaryConditions = del(t.secondaryConditions)
		end
	end
	local function hasNoSecondaryConditions(t)
		return not t.arg.secondaryConditions
	end
	local function hasAllSecondaryConditions(t)
		local t = t.arg
		if not t.secondaryConditions then
			return false
		end
		for k,v in pairs(Parrot_TriggerConditions:GetSecondaryConditionChoices()) do
			if t.secondaryConditions[k] == nil then
				return false
			end
		end
		return true
	end
	local function getAvailableSecondaryConditions(t)
		local t = t.arg
		local tmp = newList()
		for k,v in pairs(Parrot_TriggerConditions:GetSecondaryConditionChoices()) do
			if not t.secondaryConditions or not t.secondaryConditions[k] then
				tmp[k] = v
			end
		end
		return tmp
	end
	local function getUsedSecondaryConditions(t)
		local t = t.arg
		local tmp = newList()
		for k,v in pairs(Parrot_TriggerConditions:GetSecondaryConditionChoices()) do
			if t.secondaryConditions and t.secondaryConditions[k] then
				tmp[k] = v
			end
		end
		return tmp
	end
	
	function makeOption(t)
		local opt = {
			type = 'group',
			name = t.name,
			desc = t.name,
			order = t.name == L["New trigger"] and -110 or -100,
			args = {
				output = {
					type = 'input',
					name = L["Output"],
					desc = L["The text that is shown"],
					usage = L['<Text to show>'],
					get = getName,
					set = setName,
					arg = t,
					order = 1,
				},
				icon = {
					type = 'input',
					name = L["Icon"],
					desc = L["The icon that is shown"],--Note: Spells that are not in the Spellbook (i.e. some Talents) can only be identified by SpellId (retrievable at www.wowhead.com, looking at the URL)
					usage = L['<Spell name> or <Item name> or <Path> or <SpellId>'],
					get = getIcon,
					set = setIcon,
					arg = t,
				},
				enabled = {
					type = 'toggle',
					name = L["Enabled"],
					desc = L["Whether the trigger is enabled or not."],
					get = getEnabled,
					set = setEnabled,
					arg = t,
					order = -1,
				},
				remove = {
					type = 'execute',
					-- buttonText = L["Remove"],
					name = L["Remove trigger"],
					desc = L["Remove this trigger completely."],
					func = remove,
					arg = t,
					-- TODO confirm
--					confirm = L["Are you sure?"],
					order = -2,
				},
				color = {
					name = L["Color"],
					desc = L["Color of the text for this trigger."],
					type = 'color',
					get = getColor,
					set = setColor,
					arg = t,
				},
				sticky = {
					type = 'toggle',
					name = L["Sticky"],
					desc = L["Whether to show this trigger as a sticky."],
					get = getSticky,
					set = setSticky,
					arg = t,
				},
				classes = {
					type = 'multiselect',
					values = classChoices,
					name = L["Classes"],
					desc = L["Classes affected by this trigger."],
					get = getClass,
					set = setClass,
					arg = t,
				},
				scrollArea = {
					type = 'select',
					values = Parrot_ScrollAreas:GetScrollAreasChoices(),
					name = L["Scroll area"],
					desc = L["Which scroll area to output to."],
					get = getScrollArea,
					set = setScrollArea,
					arg = t,
				},
				sound = {
					type = 'select',
					values = getSoundChoices,
					name = L["Sound"],
					desc = L["What sound to play when the trigger is shown."],
					get = getSound,
					set = setSound,
					arg = t,
				},
				test = {
					type = 'execute',
					-- buttonText = L["Test"],
					name = L["Test"],
					desc = L["Test how the trigger will look and act."],
					func = test,
					arg = t,
				},
				font = {
					type = 'group',
					inline = true,
					name = L["Custom font"],
					desc = L["Custom font"],
					args = {
						fontface = {
							type = 'select',
							name = L["Font face"],
							desc = L["Font face"],
							values = Parrot.inheritFontChoices,
--							choiceFonts = SharedMedia:HashTable('font'),
							get = getFontFace,
							set = setFontFace,
							arg = t,
							order = 1,
						},
						fontSizeInherit = {
							type = 'toggle',
							name = L["Inherit font size"],
							desc = L["Inherit font size"],
							get = getFontSizeInherit,
							set = setFontSizeInherit,
							arg = t,
							order = 2,
						},
						fontSize = {
							type = 'range',
							name = L["Font size"],
							desc = L["Font size"],
							min = 12,
							max = 30,
							step = 1,
							get = getFontSize,
							set = setFontSize,
							disabled = getFontSizeInherit,
							arg = t,
							order = 3,
						},
						fontOutline = {
							type = 'select',
							name = L["Font outline"],
							desc = L["Font outline"],
							get = getFontOutline,
							set = setFontOutline,
							values = fontOutlineChoices,
							arg = t,
							order = 4,
						},
					},
				},
				primary = {
					type = 'group',
--					inline = true,
					name = L["Primary conditions"],
					desc = L["When any of these conditions apply, the secondary conditions are checked."],
					args = {
						new = {
							type = 'select',
							name = L["New condition"],
							desc = L["Add a new primary condition"],
							values = getAvailablePrimaryConditions,
							get = false,
							set = newPrimaryCondition,
							disabled = hasAllPrimaryConditions,
							arg = t,
							order = 1,
						},
						remove = {
							type = 'select',
							name = L["Remove condition"],
							desc = L["Remove a primary condition"],
							values = getUsedPrimaryConditions,
							get = false,
							set = removePrimaryCondition,
							disabled = hasNoPrimaryConditions,
							arg = t,
							order = 2,
						}
					}
				},
				secondary = {
					type = 'group',
--					inline = true,
					name = L["Secondary conditions"],
					desc = L["When all of these conditions apply, the trigger will be shown."],
					args = {
						new = {
							type = 'select',
							name = L["New condition"],
							desc = L["Add a new secondary condition"],
							values = getAvailableSecondaryConditions,
							get = false,
							set = newSecondaryCondition,
							disabled = hasAllSecondaryConditions,
							arg = t,
							order = 1,
						},
						remove = {
							type = 'select',
							name = L["Remove condition"],
							desc = L["Remove a secondary condition"],
							values = getUsedSecondaryConditions,
							get = false,
							set = removeSecondaryCondition,
							disabled = hasNoSecondaryConditions,
							arg = t,
							order = 2,
						}
					}
				},
			}
		}
		triggers_opt.args[tostring(t)] = opt
		for k,v in pairs(Parrot_TriggerConditions:GetPrimaryConditionChoices()) do
			if t.conditions[k] then
				addPrimaryCondition(t, k, v)
			end
		end
		for k,v in pairs(Parrot_TriggerConditions:GetSecondaryConditionChoices()) do
			if t.secondaryConditions and t.secondaryConditions[k] then
				addSecondaryCondition(t, k, v)
			end
		end
	end
	
	for _,t in ipairs(self.db.profile.triggers) do
		makeOption(t)
	end
end
