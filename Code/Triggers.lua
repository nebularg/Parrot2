local _, ns = ...
local Parrot = ns.addon
local module = Parrot:NewModule("Triggers", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Parrot")

local Parrot_TriggerConditions

local LibSharedMedia = LibStub("LibSharedMedia-3.0")

local newList, del = Parrot.newList, Parrot.del

local function newSet(...)
	local t = newList()
	for i = 1, select("#", ...) do
		local k = select(i, ...)
		t[k] = true
	end
	return t
end

local function deserializeSet(setstring)
	return newSet(strsplit(";", setstring))
end

local function serializeSet(set)
	local t = newList()
	for k in next, set do
		t[#t+1] = k
	end
	del(set)
	local result = table.concat(t, ";")
	del(t)
	return result
end

local db = nil
local defaults = {
	profile = {
		triggers2 = {},
		dbver2 = 0,
	},
}

local _, playerClass = UnitClass("player")
local periodicCheckTimer = nil
local effectiveRegistry = {}
local cooldowns = {}

--[[
	List of default Triggers:
	Index is starting at 1001. User-created triggers start at index 1.
	The reason is that when a new default-trigger is added, it will always get
	inserted into the db, even if the user created some custom triggers in the
	meanwhile.
--]]

local defaultTriggers = {
	[1004] = [[{
		-- Execute
		name = L["%s!"]:format(GetSpellInfo(5308)),
		icon = 5308,
		spec = { WARRIOR = "71;72", },
		conditions = {
			["Unit health"] = {
				{
					unit = "target",
					amount = 0.20,
					comparator = "<",
					friendly = 0,
				},
			},
		},
		secondaryConditions = {
			["Spell ready"] = {
				[1] = GetSpellInfo(5308),
			},
		},
		sticky = true,
		color = "ffff00",
	}]],
	[1008] = [[{
		name = L["Low Health!"],
		spec = {
			DRUID = "102;103;104;105",
			HUNTER = "253;254;255",
			MAGE = "62;63;64",
			PALADIN = "65;66;70",
			PRIEST = "256;257;258",
			ROGUE = "259;260;261",
			SHAMAN = "262;263;264",
			WARLOCK = "265;266;267",
			WARRIOR = "71;72;73",
			DEATHKNIGHT = "250;251;252",
			MONK = "268;269;270",
			DEMONHUNTER = "577;581"
		},
		conditions = {
			["Unit health"] = {
				{
					unit = "player",
					amount = 0.40,
					comparator = "<=",
					friendly = 1,
				},
			},
		},
		secondaryConditions = {
			["Trigger cooldown"] = 3,
		},
		sticky = true,
		color = "ff7f7f",
	}]],
	[1009] = [[{
		name = L["Low Mana!"],
		spec = {
			DRUID = "102;103;104;105",
			MAGE = "62;63;64",
			PALADIN = "65;66;70",
			PRIEST = "256;257;258",
			SHAMAN = "262;263;264",
			WARLOCK = "265;266;267",
			MONK = "270",
		},
		conditions = {
			["Unit power"] = {
				{
					unit = "player",
					amount = "35%",
					comparator = "<=",
					friendly = 1,
					powerType = 0,
				},
			},
		},
		secondaryConditions = {
			["Trigger cooldown"] = 3,
		},
		sticky = true,
		color = "7f7fff",
	}]],
	[1010] = [[{
		name = L["Low Pet Health!"],
		spec = {
			HUNTER = "253;254;255",
			MAGE = "64",
			WARLOCK = "265;266;267",
			DEATHKNIGHT = "252",
		},
		conditions = {
			["Unit health"] = {
				[1] = {
					unit = "pet",
					amount = 0.40,
					comparator = "<=",
					friendly = 1,
				},
			},
		},
		secondaryConditions = {
			["Trigger cooldown"] = 3,
		},
		color = "ff7f7f",
	}]],
	[1014] = [[{
		-- Revenge
		name = L["%s!"]:format(GetSpellInfo(6572)),
		icon = 6572,
		spec = { WARRIOR = "73" },
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(5302),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "00ee00",
		disabled = true,
	}]],
	[1017] = [[{
		-- Rime
		name = L["%s!"]:format(GetSpellInfo(59052)),
		icon = 59052,
		spec = { DEATHKNIGHT = "251" },
		conditions = {
			["Aura gain"] = {
				[1] = {
					spell = GetSpellInfo(59052),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "0000ff",
	}]],
	[1018] = [[{
		-- Killing Machine
		name = L["%s!"]:format(GetSpellInfo(51124)),
		icon = 51124,
		spec = { DEATHKNIGHT = "251" },
		conditions = {
			["Aura gain"] = {
				[1] = {
					spell = GetSpellInfo(51124),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "0000ff",
	}]],
	[1021] = [[{
		-- Brain Freeze
		name = L["%s!"]:format(GetSpellInfo(190447)),
		icon = 190447,
		spec = { MAGE = "64" },
		conditions = {
			["Aura gain"] = {
				[1] = {
					["unit"] = "player",
					["spell"] = GetSpellInfo(190447),
					["auraType"] = "BUFF",
				},
			},
		},
		sticky = true,
		color = "005ba9",
	}]],
	[1031] = [[{
		-- Fingers of Frost
		name = L["%s!"]:format(GetSpellInfo(44544)),
		icon = 44544,
		spec = { MAGE = "64" },
		conditions = {
			["Aura gain"] = {
				[1] = {
					["unit"] = "player",
					["spell"] = GetSpellInfo(44544),
					["auraType"] = "BUFF",
				},
			},
		},
		sticky = true,
		color = "005ba9",
	}]],
	[1033] = [[{
		-- Crimson Scourge
		name = L["%s!"]:format(GetSpellInfo(81141)),
		icon = 81141,
		spec = { DEATHKNIGHT = "250" },
		conditions = {
			["Aura gain"] = {
				[1] = {
					unit = "player",
					spell = GetSpellInfo(81141),
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "ff0000",
	}]],
	[1041] = [[{
		-- Sudden Doom
		name = L["%s!"]:format(GetSpellInfo(81340)),
		icon = 81340,
		spec = { DEATHKNIGHT = "252" },
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(81340),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "9b00b3",
	}]],
	[1043] = [[{
		-- Hot Streak!
		name = GetSpellInfo(48108),
		icon = 48108,
		spec = { MAGE = "63" },
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(48108),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "b33f00",
	}]],
	[1044] = [[{
		-- Heating Up
		name = L["%s!"]:format(GetSpellInfo(48107)),
		icon = 48107,
		spec = { MAGE = "63" },
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(48107),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "ff5900",
	}]],
	[1046] = [[{
		-- Grand Crusader
		name = L["%s!"]:format(GetSpellInfo(85416)),
		icon = 85416,
		spec = { PALADIN = "66" },
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(85416),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "0038cd",
	}]],
	[1047] = [[{
		-- Lava Surge
		name = L["%s!"]:format(GetSpellInfo(77756)),
		icon = 77756,
		spec = { SHAMAN = "262;264" },
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(77756),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "ddb800",
	}]],
	[1050] = [[{
		-- Raging Blow
		name = L["%s!"]:format(GetSpellInfo(85288)),
		icon = 85288,
		spec = { WARRIOR = "72" },
		conditions = {
			["Spell overlay"] = {
				"85288",
			},
		},
		sticky = true,
		color = "ff0000",
	}]],
	[1051] = [[{
		-- Sudden Death
		name = L["%s!"]:format(GetSpellInfo(280776)),
		icon = 280776,
		spec = { WARRIOR = "71;72" },
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(280776),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "cd3700",
	}]],
	[1052] = [[{
		-- Shield Slam
		name = L["%s!"]:format(GetSpellInfo(23922)),
		icon = 23922,
		spec = { WARRIOR = "73" },
		conditions = {
			["Spell overlay"] = {
				"224324",
			},
		},
		secondaryConditions = {
			["Trigger cooldown"] = 1.5,
		},
		sticky = true,
		color = "ffff00",
	}]],
	[1053] = [[{
		-- Nightfall
		name = L["%s!"]:format(GetSpellInfo(108558)),
		icon = 108558,
		spec = { WARLOCK = "265" },
		conditions = {
			["Spell overlay"] = {
				"264571",
			},
		},
		sticky = true,
		color = "551A8B",
	}]],
	[1054] = [[{
		-- Lethal Shots
		name = L["%s!"]:format(GetSpellInfo(260395)),
		icon = 260395,
		spec = { HUNTER = "254" },
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(260395),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "ffff00",
	}]],
	[1055] = [[{
		-- Lock and Load
		name = L["%s!"]:format(GetSpellInfo(194594)),
		icon = 194594,
		spec = { HUNTER = "254" },
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(194594),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "ffffff",
	}]],
	[1056] = [[{
		-- Kill Command
		name = L["%s!"]:format(GetSpellInfo(259489)),
		icon = 259489,
		spec = { HUNTER = "255" },
		conditions = {
			["Spell overlay"] = {
				"259285",
			},
		},
		sticky = true,
		color = "c72520",
		disabled = true,
	}]],
	[1057] = [[{
		-- Viper's Venom
		name = L["%s!"]:format(GetSpellInfo(268552)),
		icon = 268423,
		spec = { HUNTER = "255" },
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(268552),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "008b00",
	}]],
	[1058] = [[{
		-- Clearcasting
		name = L["%s!"]:format(GetSpellInfo(16870)),
		icon = 16870,
		spec = {
			DRUID = "103;105",
			MAGE = "62",
		},
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(16870),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "1e90ff",
	}]],
	[1059] = [[{
		-- Gore
		name = L["%s!"]:format(GetSpellInfo(93622)),
		icon = 33917,
		spec = { DRUID = "104" },
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(93622),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "ff0000",
	}]],
	[1060] = [[{
		-- Galatic Guardian
		name = L["%s!"]:format(GetSpellInfo(213708)),
		icon = 8921,
		spec = { DRUID = "104" },
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(213708),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "ffffff",
	}]],
	[1061] = [[{
		-- Power of the Dark Side
		name = L["%s!"]:format(GetSpellInfo(198069)),
		icon = 198069,
		spec = { PRIEST = "256" },
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(198069),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "9b30ff",
		disabled = true,
	}]],
	[1062] = [[{
		-- Surge of Light
		name = L["%s!"]:format(GetSpellInfo(114255)),
		icon = 114255,
		spec = { PRIEST = "257" },
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(114255),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "ffff00",
	}]],
	[1063] = [[{
		-- Divine Purpose
		name = L["%s!"]:format(GetSpellInfo(223817)),
		icon = 223817,
		spec = { PALADIN = "65;70" },
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(223817),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "ffff00",
	}]],
	[1064] = [[{
		-- Stormbringer
		name = GetSpellInfo(201846),
		icon = 17364,
		spec = { SHAMAN = "263" },
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(201846),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "4876ff",
	}]],
	[1065] = [[{
		-- Opportunity
		name = GetSpellInfo(195627),
		icon = 195627,
		spec = { ROGUE = "260" },
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(195627),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "ee4000",
	}]],
	[1066] = [[{
		-- Blackout Kick!
		name = GetSpellInfo(116768),
		icon = 116768,
		spec = { MONK = "269" },
		conditions = {
			["Aura gain"] = {
				{
					spell = GetSpellInfo(116768),
					unit = "player",
					auraType = "BUFF",
				},
			},
		},
		sticky = true,
		color = "ff69b4",
	}]],
}
-- start new entries at 1067

local specChoices = {
	DEATHKNIGHT = {
		250, -- Blood
			-- 1033 Crimson Scourge
		251, -- Frost
			-- 1017 Rime
			-- 1018 Killing Machine
		252, -- Unholy
			-- 1041 Sudden Doom
	},
	DEMONHUNTER = {
		577, -- Havoc
		581, -- Vengeance
	},
	DRUID = {
		102, -- Balance
		103, -- Feral Combat
			-- 1058 Clearcasting
		104, -- Guardian
			-- 1059 Gore
			-- Galatic Guardian
		105, -- Restoration
			-- 1058 Clearcasting
	},
	HUNTER = {
		253, -- Beast Mastery
		254, -- Marksmanship
			-- 1054 Lethal Shots
			-- 1055 Lock and Load
		255, -- Survival
			-- 1056 Kill Command
			-- 1057 Viper's Venom
	},
	MAGE = {
		62, -- Arcane
			-- 1058 Clearcasting
		63, -- Fire
			-- 1044 Heating Up
			-- 1043 Hot Streak
		64, -- Frost
			-- 1021 Brain Freeze
			-- 1031 Fingers of Frost
	},
	MONK = {
		268, -- Brewmaster
		269, -- Windwalker
		  -- 1063 Blackout Kick!
		270, -- Mistweaver
	},
	PALADIN = {
		65, -- Holy
			-- 1060 Divine Purpose
		66, -- Protection
			-- 1046 Grand Crusader
		70, -- Retribution
			-- 1060 Divine Purpose
	},
	PRIEST = {
		256, -- Discipline
			-- 1061 Power of the Dark Side
		257, -- Holy
			-- 1062 Surge of Light
		258, -- Shadow
	},
	ROGUE = {
		259, -- Assassination
		260, -- Outlaw
			-- 1065 Opportunity
		261, -- Subtlety
	},
	SHAMAN = {
		262, -- Elemental
			-- 1047 Lava Surge
		263, -- Enhancement
			-- 1064 Stormbringer
		264, -- Restoration
			-- 1047 Lava Surge
	},
	WARLOCK = {
		265, -- Affliction
			-- 1053 Nightfall
		266, -- Demonology
		267, -- Destruction
	},
	WARRIOR = {
		71, -- Arms
			-- 1004 Execute
			-- 1051 Sudden Death
		72, -- Fury
			-- 1004 Execute
			-- 1051 Sudden Death
		73, -- Protection
			-- 1014 Revenge
			-- 1052 Shield Slam
	},
}

do
	local ScriptEnv = setmetatable({}, {__index = _G})
	ScriptEnv.L = L

	local safeGetSpellInfo = function(id, ...)
		if _G.GetSpellInfo(id, ...) then
			return _G.GetSpellInfo(id, ...)
		else
			return "_Unknown SpellId " .. id
		end
	end

	local function hasMissingSpellIds(code)
		for spellId in code:gmatch("GetSpellInfo%((%d+)%)") do
			if not GetSpellInfo(spellId) then
				print("Parrot: Trigger spell missing:", spellId)
				return true
			end
		end
		return false
	end

	local function makeDefaultTrigger(index, code)
		if hasMissingSpellIds(code) then
			ScriptEnv.GetSpellInfo = safeGetSpellInfo
		else
			ScriptEnv.GetSpellInfo = _G.GetSpellInfo
		end
		local func = assert(loadstring(("return %s"):format(code)))
		setfenv(func, ScriptEnv)
		defaults.profile.triggers2[index] = func()
	end

	for k,v in pairs(defaultTriggers) do
		makeDefaultTrigger(k,v)
	end
end

local function getPlayerSpec()
	local spec = GetSpecialization()
	local specId = spec and GetSpecializationInfo(spec) or 0
	return tostring(specId)
end

local function hexColorToTuple(color)
	local num = tonumber(color, 16)
	if not num then
		return 0, 0, 0
	end
	return math.floor(num / 256^2)/255, math.floor((num / 256)%256)/255, (num%256)/255
end

local function checkTriggerEnabled(v)
	if v.disabled then return end

	local specstring = v.spec and v.spec[playerClass]
	if not specstring then return end

	local sets = deserializeSet(specstring)
	local result = sets[getPlayerSpec()]
	del(sets)
	return result
end

local function rebuildEffectiveRegistry()
	module:CancelTimer(periodicCheckTimer)
	periodicCheckTimer = nil

	wipe(effectiveRegistry)

	for _, v in next, db.triggers2 do
		if checkTriggerEnabled(v) then
			effectiveRegistry[#effectiveRegistry+1] = v
			if v.conditions["Check every XX seconds"] and not periodicCheckTimer then
				periodicCheckTimer = module:ScheduleRepeatingTimer(function()
					Parrot:FirePrimaryTriggerCondition("Check every XX seconds")
				end, 0.1)
			end
		end
	end

	LibStub("AceConfigRegistry-3.0"):NotifyChange("Parrot")
end

local updateFuncs = {
	[1] = function()
		-- Cleanup
		db.triggers = nil
		db.dbver = nil

		-- Do the old Parrot conversions
		local function convertPower(t)
			local powerToEnum = {
				MANA = 0,
				RAGE = 1,
				FOCUS = 2,
				ENERGY = 3,
				COMBO_POINTS = 4,
				RUNES = 5,
				RUNIC_POWER = 6,
				SOUL_SHARDS = 7,
				HOLY_POWER = 9,
			}
			for _, v in next, t do
				if type(v.amount) == "number" and v.amount <= 1 then
					v.amount = (v.amount * 100) .. "%"
				else
					v.amount = tostring(v.amount)
				end
				if v.powerType and type(v.powerType) ~= "number" then
					v.powerType = powerToEnum[v.powerType]
				end
			end
		end

		for k, v in next, db.triggers2 do
			if not v.conditions then
				v.conditions = {}
			end
			if v.class and not v.spec then
				v.spec = {}
				for class in next, {(";"):split(v.class)} do
					local specs = specChoices[class]
					if specs then
						v.spec[class] = table.concat(specs, ";")
					end
				end
			end
			v.class = nil
			if v.conditions["Unit power"] then
				convertPower(v.conditions["Unit power"])
			end
			if v.secondaryConditions and v.secondaryConditions["Unit power"] then
				convertPower(v.secondaryConditions["Unit power"])
			end
		end
	end,
}

local function updateDB()
	-- delete user-settings from triggers that are no longer available
	for k, v in next, db.triggers2 do
		if k > 1000 and not defaultTriggers[k] then
			db.triggers2[k] = nil
		end
	end

	if not db.dbver2 then
		db.dbver2 = 0
	end
	for i = db.dbver2 + 1, #updateFuncs do
		updateFuncs[i]()
	end
	db.dbver2 = #updateFuncs
end

function module:OnProfileChanged()
	db = self.db.profile
	updateDB()

	if Parrot.options.args.triggers then
		Parrot.options.args.triggers = nil
		self:OnOptionsCreate()
	end
	rebuildEffectiveRegistry()
end

function module:OnInitialize()
	self.db = Parrot.db:RegisterNamespace("Triggers", defaults)
	db = self.db.profile
	updateDB()

	Parrot_TriggerConditions = Parrot:GetModule("TriggerConditions")
end

local function registerTriggers()
	Parrot:RegisterPrimaryTriggerCondition {
		name = "Check every XX seconds",
		localName = L["Check periodically"],
		defaultParam = 3,
		param = {
			type = "number",
			min = 0, max = 60, step = 0.1, bigStep = 1,
		},
		exclusive = true,
	}

	Parrot:RegisterSecondaryTriggerCondition {
		name = "Trigger cooldown",
		localName = L["Trigger cooldown"],
		defaultParam = 3,
		param = {
			type = "number",
			min = 0, max = 60, step = 0.1, bigStep = 1,
		},
		exclusive = true,
		check = function(param)
			return true
		end,
	}
end

function module:OnEnable()
	if registerTriggers then
		registerTriggers()
		registerTriggers = nil
	end

	self:RegisterEvent("PLAYER_TALENT_UPDATE", rebuildEffectiveRegistry)
	rebuildEffectiveRegistry()
end

-- no weak table required, there are only very few entries
local iconCache = {}
local function getIconPath(icon)
	if not icon then return end

	local path = iconCache[icon]
	if not path then
		local texture = GetSpellTexture(icon)
		if texture then
			path = texture
		else
			texture = GetItemIcon(icon)
			if texture then
				path = texture
			else
				path = false
			end
		end
		iconCache[icon] = path
	end
	return path
end

local function checkPrimaryCondition(condition, arg, check)
	if condition == true then
		return true
	elseif check and type(check) == 'function' then
		local good = check(condition, arg)
		return good
	else
		return condition == arg
	end
end

local function checkSecondaryCondition(name, value)
	return Parrot_TriggerConditions:DoesSecondaryTriggerConditionPass(name, value)
end

local function checkTriggerCooldown(t, value)
	if not cooldowns[t.name] then
		return true
	end
	local now = GetTime()
	return now - cooldowns[t.name] > value
end

local timerCheck = {}
local function performPeriodicCheck(name, param)
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
		return true
	else
		return false
	end
end

local function showTrigger(t)
	cooldowns[t.name] = GetTime()
	local r, g, b = hexColorToTuple(t.color or 'ffffff')
	local icon = getIconPath(t.icon)
	if t.useflash then
		local rf, gf, bf = hexColorToTuple(t.flashcolor or 'ffffff')
		Parrot:Flash(rf,gf,bf)
	end

	Parrot:ShowMessage(t.name, t.scrollArea or "Notification", t.sticky, r, g, b, t.font, t.fontSize, t.outline, icon)

	if t.sound then
		local sound = LibSharedMedia:Fetch('sound', t.sound)
		if sound then
			PlaySoundFile(sound, "Master")
		end
	end
end

function module:OnTriggerCondition(name, arg, uid, check)
	if UnitIsDeadOrGhost("player") then
		return
	end
	-- check all triggers in registry
	for _, t in next, effectiveRegistry do
		local conditions = t.conditions
		-- if trigger has primary conditions
		if conditions and conditions[name] then
			-- assume it does not fit (pessimistic)
			local good = false
			--this can be just a single value or a table of params
			local param = conditions[name]
			if type(param) == 'table' then
				for i, v in next, param do
					-- if one condition matches, the trigger fires
					if checkPrimaryCondition(v, arg, check) then
						good = true
						break
					end
				end
			elseif name == "Check every XX seconds" then
				good = performPeriodicCheck(name, param)
			else
				good = checkPrimaryCondition(param, arg, check)
			end
			if good then
				-- check secondary conditions
				local secondaryConditions = t.secondaryConditions
				if secondaryConditions then
					-- check all conditions associated with the trigger
					for k, v in pairs(secondaryConditions) do
						if k == "Trigger cooldown" then
							good = checkTriggerCooldown(t, v) and good
						elseif type(v) == 'table' and #v > 0 then
							-- if the condition is not exclusive there may be multiple matchers
							for _,cond in next, v do
								if not checkSecondaryCondition(k,cond) then
									good = false
									break
								end
							end
						else
							if not checkSecondaryCondition(k,v) then
								good = false
								break
							end
						end
					end
				end
				-- check a 0.1-seconds cooldown too
				if good and checkTriggerCooldown(t, 0.1) then
					showTrigger(t)
					if uid then
						Parrot:CancelEventsWithUID(uid)
					end
				end
			end
		end -- if conditions
	end -- for ipairs
end

function module:OnOptionsCreate()

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
			return not self:IsEnabled()
		end,
		order = 3,
		args = {
			new = {
				type = 'execute',
				name = L["New trigger"],
				desc = L["Create a new trigger"],
				func = function()
					local t = {
						name = L["New trigger"],
						spec = {
							[playerClass] = table.concat(specChoices[playerClass], ";"),
						},
						conditions = {},
					}
					local registry = db.triggers2
					registry[#registry+1] = t
					makeOption(#registry, t)
					rebuildEffectiveRegistry()
				end,
				disabled = function()
					if not db.triggers2 then
						return true
					end
					for _,v in ipairs(db.triggers2) do
						if v.name == L["New trigger"] then
							return true
						end
					end
					return false
				end
			},
		}
	}
	Parrot:AddOption('triggers', triggers_opt)

	local function getTriggerId(info)
		local i = 0
		while i < #info and not info[#info - i]:match("^%d+$") do
			i = i + 1
		end
		return info[#info-i]
	end

	local function getTriggerTable(info)
		return db.triggers2[tonumber(getTriggerId(info))]
	end

	local function getFontFace(info)
		local t = getTriggerTable(info)
		local font = t.font
		if font == nil then
			return -1
		end
		for i, v in next, Parrot.fontValues do
			if v == font then return i end
		end
		return font
	end
	local function setFontFace(info, value)
		local t = getTriggerTable(info)
		if value == -1 then
			t.font = nil
		else
			t.font = Parrot.fontValues[value]
		end
	end
	local function getFontSize(info)
		return getTriggerTable(info).fontSize
	end
	local function setFontSize(info, value)
		getTriggerTable(info).fontSize = value
	end
	local function getFontSizeInherit(info)
		return getTriggerTable(info).fontSize == nil
	end
	local function setFontSizeInherit(info, value)
		local t = getTriggerTable(info)
		if value then
			t.fontSize = nil
		else
			t.fontSize = 18
		end
	end
	local function getFontOutline(info)
		local outline = getTriggerTable(info).fontOutline
		if outline == nil then
			return L["Inherit"]
		else
			return outline
		end
	end
	local function setFontOutline(info, value)
		if value == L["Inherit"] then
			value = nil
		end
		getTriggerTable(info).fontOutline = value
	end
	local fontOutlineChoices = {
		NONE = L["None"],
		MONOCHROME = L["Monochrome"],
		OUTLINE = L["Thin"],
		["OUTLINE,MONOCHROME"] = L["Thin, Monochrome"],
		THICKOUTLINE = L["Thick"],
		[L["Inherit"]] = L["Inherit"],
	}
	local function getEnabled(info)
		return not getTriggerTable(info).disabled
	end
	local function setEnabled(info, value)
		getTriggerTable(info).disabled = not value
		rebuildEffectiveRegistry()
	end
	local function getScrollArea(info)
		return getTriggerTable(info).scrollArea or "Notification"
	end
	local function setScrollArea(info, value)
		if value == "Notification" then
			value = nil
		end
		getTriggerTable(info).scrollArea = value
	end
	-- not local, declared above
	function remove(info)
		local id = getTriggerId(info)
		db.triggers2[tonumber(id)] = nil
		triggers_opt.args[id] = nil
		rebuildEffectiveRegistry()
	end
	local function getSticky(info)
		return getTriggerTable(info).sticky
	end
	local function setSticky(info, value)
		getTriggerTable(info).sticky = value
	end
	local function getName(info)
		return getTriggerTable(info).name
	end
	local function setName(info, value)
		getTriggerTable(info).name = value
	end

	local function getIcon(info)
		return tostring(getTriggerTable(info).icon or "")
	end
	local function setIcon(info, value)
		if value == '' then
			value = nil
		end
		getTriggerTable(info).icon = tonumber(value) or value
	end

	local function tupleToHexColor(r, g, b)
		return ("%02x%02x%02x"):format(r * 255, g * 255, b * 255)
	end

	local function getColor(info)
		return hexColorToTuple(getTriggerTable(info).color or "ffffff")
	end
	local function setColor(info, r, g, b)
		local color = tupleToHexColor(r, g, b)
		if color == "ffffff" then
			color = nil
		end
		getTriggerTable(info).color = color
	end

	local function getColor2(info)
		return getTriggerTable(info).color
	end
	local function setColor2(info, value)
		if not tonumber(value, 16) then return end
		getTriggerTable(info).color = value
	end

	local function getFlashColor(info)
		return hexColorToTuple(getTriggerTable(info).flashcolor or "ffffff")
	end
	local function setFlashColor(info, r, g, b)
		local color = tupleToHexColor(r, g, b)
		if color == "ffffff" then
			color = nil
		end
		getTriggerTable(info).flashcolor = color
	end

	local function getUseFlash(info)
		return getTriggerTable(info).useflash
	end
	local function setUseFlash(info, value)
		getTriggerTable(info).useflash = value
	end

	local function getSound(info)
		local value = getTriggerTable(info).sound or "None"
		for i, v in next, Parrot.soundValues do
			if v == value then return i end
		end
	end
	local function setSound(info, value)
		local v = Parrot.soundValues[value]
		PlaySoundFile(LibSharedMedia:Fetch("sound", v), "Master")
		if v == "None" then
			v = nil
		end
		getTriggerTable(info).sound = v
	end

	local function test(info)
		local t = getTriggerTable(info)
		local r, g, b = hexColorToTuple(t.color or 'ffffff')
		--TODO
		if t.useflash then
			local rf, gf, bf = hexColorToTuple(t.flashcolor or 'ffffff')
			Parrot:Flash(rf,gf,bf)
		end
		Parrot:ShowMessage(t.name, t.scrollArea or "Notification", t.sticky, r, g, b, t.font, t.fontSize, t.outline, getIconPath(t.icon))
		if t.sound then
			local sound = LibSharedMedia:Fetch('sound', t.sound)
			if sound then
				PlaySoundFile(sound, "Master")
			end
		end
	end

	local LC = _G.LOCALIZED_CLASS_NAMES_MALE
	local classChoices = {
		DRUID = LC["DRUID"],
		ROGUE = LC["ROGUE"],
		SHAMAN = LC["SHAMAN"],
		PALADIN = LC["PALADIN"],
		MAGE = LC["MAGE"],
		WARLOCK = LC["WARLOCK"],
		PRIEST = LC["PRIEST"],
		WARRIOR = LC["WARRIOR"],
		HUNTER = LC["HUNTER"],
		DEATHKNIGHT = LC["DEATHKNIGHT"],
		MONK = LC["MONK"],
		DEMONHUNTER = LC["DEMONHUNTER"],
	}

	local function getConditionValue(info)
		local t, name, field, index, parse = info.arg.t, info.arg.name, info.arg.field,
		info.arg.index, info.arg.parse
		local result
		if not field then
			if index then
				result = t.conditions[name][index]
			else
				result = t.conditions[name]
			end
		else
			if index then
				result = t.conditions[name][index][field]
			else
				result = t.conditions[name][field]
			end
		end
		if parse then
			return parse(result)
		else
			return result
		end
	end
	local function setConditionValue(info, value)
		local t, name, field, index, save = info.arg.t, info.arg.name, info.arg.field,
		info.arg.index, info.arg.save
		if save then
			value = save(value)
		end
		if not field then
			if index then
				t.conditions[name][index] = value
			else
				t.conditions[name] = value
			end -- if index
		else
			if index then
				t.conditions[name][index][field] = value
			else
				t.conditions[name][field] = value
			end -- if index
		end -- if not field
	end -- setConditionValue()

	local function getSecondaryConditionValue(info)
		local t, name, field, index, parse = info.arg.t, info.arg.name, info.arg.field,
		info.arg.index, info.arg.parse
		local result
		if not field then
			if index then
				result = t.secondaryConditions[name][index]
			else
				result = t.secondaryConditions[name]
			end
		else
			if index then
				result = t.secondaryConditions[name][index][field]
			else
				result = t.secondaryConditions[name][field]
			end
		end
		if parse then
			return parse(result)
		else
			return result
		end
	end
	local function setSecondaryConditionValue(info, value)
		local t, name, field, index, save = info.arg.t, info.arg.name, info.arg.field,
		info.arg.index, info.arg.save
		if save then
			value = save(value)
		end
		if not field then
			if index then
				t.secondaryConditions[name][index] = value
			else
				t.secondaryConditions[name] = value
			end -- if index
		else
			if index then
				t.secondaryConditions[name][index][field] = value
			else
				t.secondaryConditions[name][field] = value
			end -- if index
		end -- if not field
	end -- setConditionValue()

	local function donothing()
	end

	local function removePrimaryCondition(info)
		local i = getTriggerId(info)
		local t, name, index = unpack(info.arg)
		local opt = triggers_opt.args[tostring(i)].args.primary
		if index then
			opt.args[name .. index] = del(opt.args[name .. index])
			t.conditions[name][index] = nil
		else
			opt.args[name] = del(opt.args[name])
		end
		-- delete the whole condition-table
		if not index or not next(t.conditions[name]) then
			t.conditions[name] = nil
		end
	end -- removeCondition()

	local function removeSecondaryCondition(info)
		local i = getTriggerId(info)
		local t, name, index = unpack(info.arg)
		local opt = triggers_opt.args[tostring(i)].args.secondary
		if index then
			opt.args[name .. index] = del(opt.args[name .. index])
			t.secondaryConditions[name][index] = nil
		else
			opt.args[name] = del(opt.args[name])
		end
		-- delete the whole condition-table
		if not index or not next(t.secondaryConditions[name]) then
			t.secondaryConditions[name] = nil
		end
	end -- removeCondition()

	local function addCondition(i, t, name, localName, index, primary)
		-- the only stuff that is different about adding primary and secondary conditions
		local opt, param, default
		local set, get
		if primary then
			opt = triggers_opt.args[tostring(i)].args.primary
			param, default = Parrot_TriggerConditions:GetPrimaryConditionParamDetails(name)
			set, get = setConditionValue, getConditionValue
		else
			opt = triggers_opt.args[tostring(i)].args.secondary
			param, default = Parrot_TriggerConditions:GetSecondaryConditionParamDetails(name)
			set, get = setSecondaryConditionValue, getSecondaryConditionValue
		end
		if not localName then
			if t.name then
				Parrot:Print("Trigger \"", t.name, "\" might be broken")
				Parrot:Print("The condition ", name, " was not found")
				Parrot:Print("Try to recreate the Trigger")
			end
			return
		end
		local tmp

		if param and param.type == 'group' then
			tmp = CopyTable(param)
			for k,v in pairs(tmp.args) do
				v.get = get
				v.set = set
				if acetype[v.type] then
					v.type = acetype[v.type]
				end
				v.arg = { t = t, name = name, field = k, index = index, parse = v.parse, save = v.save }
				v.save = nil
				v.parse = nil
			end
		else
			tmp = {
				type = 'group',
				args = {},
			}
			if not param then
				tmp.args.param = {
					type = 'execute',
					name = localName,
					desc = localName,
					func = donothing,
				}
			else
				local param_opt = CopyTable(param)
				tmp.args.param = param_opt
				param_opt.name = localName
				param_opt.desc = localName
				param_opt.get = get
				param_opt.set = set
				param_opt.arg = { t = t, name = name, index = index, parse = param_opt.parse, save = param_opt.save, }
				param_opt.save = nil
				param_opt.parse = nil
				if acetype[param_opt.type] then
					param_opt.type = acetype[param_opt.type]
				end
			end
		end

		tmp.name = localName
		tmp.desc = localName
		tmp.inline = true
		tmp.args.remove = {
			type = 'execute',
			name = L["Remove"],
			desc = L["Remove condition"],
			func = primary and removePrimaryCondition or removeSecondaryCondition,
			arg = {t, name, index,},
			order = -1,
		}
		opt.args[name .. (index or "")] = tmp
		if not param then
			return true
		end
		if default then
			if type(default) == "table" then
				default = CopyTable(default)
			end
			return default
		end
		if type(param.min) == "number" and type(param.max) == "number" then
			return (param.max + param.min) / 2
		end
		if param.type == "group" then
			return {}
		else
			return nil
		end
	end

	local function addPrimaryCondition(i, t, name, localName, index)
		return addCondition(i, t, name, localName, index, true)
	end
	local function newPrimaryCondition(info, name)
		local i = getTriggerId(info)
		local t = info.arg
		local localName = Parrot_TriggerConditions:GetPrimaryConditionChoices()[name]
		if Parrot_TriggerConditions:IsExclusive(name) then
			t.conditions[name] = addPrimaryCondition(i, t, name, localName)
			if name == "Check every XX seconds" then
				if not periodicCheckTimer then
					periodicCheckTimer = self:ScheduleRepeatingTimer(function()
							Parrot:FirePrimaryTriggerCondition("Check every XX seconds")
					end, 0.1)
				end
			end
		else
			local index
			if t.conditions[name] then
				index = #(t.conditions[name]) + 1
			else
				t.conditions[name] = {}
				index = 1
			end
			t.conditions[name][index] = addPrimaryCondition(i, t, name, localName, index)
		end
	end
	local function getAvailablePrimaryConditions(info)
		local t = info.arg
		if not t.conditions then
			return CopyTable(Parrot_TriggerConditions:GetPrimaryConditionChoices())
		end
		local tmp = newList()
		for k,v in pairs(Parrot_TriggerConditions:GetPrimaryConditionChoices()) do
			if not (t.conditions[k] and Parrot_TriggerConditions:IsExclusive(k)) then
				tmp[k] = v
			end
		end
		return tmp
	end

	local function addSecondaryCondition(...)
		return addCondition(...)
	end

	local function newSecondaryCondition(info, name)
		local i = getTriggerId(info)
		local t = info.arg
		local localName = Parrot_TriggerConditions:GetSecondaryConditionChoices()[name]
		if not t.secondaryConditions then
			t.secondaryConditions = {}
		end
		if Parrot_TriggerConditions:SecondaryIsExclusive(name) then
			t.secondaryConditions[name] = addSecondaryCondition(i, t, name, localName)
		else
			local index
			if t.secondaryConditions[name] then
				index = #(t.secondaryConditions[name]) + 1
			else
				t.secondaryConditions[name] = {}
				index = 1
			end
			local tmp = addSecondaryCondition(i, t, name, localName, index)
			t.secondaryConditions[name][index] = tmp
		end
	end
	local function getAvailableSecondaryConditions(info)
		local t = info.arg
		if not t.secondaryConditions then
			return CopyTable(Parrot_TriggerConditions:GetSecondaryConditionChoices())
		end
		local tmp = newList()
		for k,v in pairs(Parrot_TriggerConditions:GetSecondaryConditionChoices()) do
			local kpos = k:gsub("^~", "")
			if Parrot_TriggerConditions:SecondaryIsExclusive(kpos) then
				if not t.secondaryConditions[k] and not t.secondaryConditions["~" .. k]
				and not t.secondaryConditions[kpos] then
					tmp[k] = v
				end
			else
				tmp[k] = v
			end
		end
		return tmp
	end

	local function getClass(info)
		local class = info[#info]
		local t = getTriggerTable(info)
		return t.spec[class] ~= nil
	end

	local function doSetClass(t, class, value)
		if not value then
			t.spec[class] = nil
		else
			t.spec[class] = table.concat(specChoices[class], ";")
		end
		if class == playerClass then
			rebuildEffectiveRegistry()
		end
	end

	local function setClass(info, value)
		local class = info[#info]
		local t = getTriggerTable(info)
		doSetClass(t, class, value)
	end

	local function notIsClass(info)
		local class = info[#info]:gsub("-$", "")
		local t = getTriggerTable(info)
		return t.spec[class] == nil
	end

	local function doGetSpec(t, class, specid)
		local specs = deserializeSet(t.spec[class])
		local result = specs[specid]
		del(specs)
		return result
	end

	local function getSpec(info)
		local specid = info[#info]:gsub("^Spec", "")
		local class = info[#info-1]:gsub("-$", "")
		local t = getTriggerTable(info)
		return doGetSpec(t, class, specid)
	end

	local function setSpec(info, value)
		local specid = info[#info]:gsub("^Spec", "")
		local class = info[#info-1]:gsub("-$", "")
		local t = getTriggerTable(info)
		local specs = deserializeSet(t.spec[class])
		specs[specid] = value or nil
		if not next(specs) then
			t.spec[class] = nil
		else
			t.spec[class] = serializeSet(specs)
		end
		if specid == getPlayerSpec() then
			rebuildEffectiveRegistry()
		end
	end

	local function getColoredName(info)
		local t = getTriggerTable(info)
		if t.spec[playerClass] then
			if not t.disabled and doGetSpec(t, playerClass, getPlayerSpec()) then
				return ("|c0000dd00%s|r"):format(t.name) -- green
			elseif not t.disabled then
				return ("|c01006600%s|r"):format(t.name) -- dim green
			else
				return ("|c02cc1919%s|r"):format(t.name) -- dim red
			end
		end
		return ("|c03888888%s|r"):format(t.name) -- grey
	end

	local function isHiddenForYourClass(info)
		local id = tonumber(getTriggerId(info))
		if id > 1000 then
			-- always show the "Low" triggers incase you screw it up for other classes
			if id == 1008 or id == 1009 or id == 1010 then
				return false
			end
			-- hide default triggers not for your class
			local t = getTriggerTable(info)
			if t.spec and not t.spec[playerClass] then
				return true
			end
		end
		return false
	end

	local function isDefault(info)
		local id = tonumber(getTriggerId(info))
		return id > 1000
	end

	local tsharedopt = {
		output = {
			type = 'input',
			name = L["Output"],
			desc = L["The text that is shown"],
			usage = L["<Text to show>"],
			get = getName,
			set = setName,
			order = 1,
		},
		enabled = {
			type = 'toggle',
			name = L["Enabled"],
			desc = L["Whether the trigger is enabled or not."],
			get = getEnabled,
			set = setEnabled,
			width = "half",
			order = 3,
		},
		remove = {
			type = 'execute',
			name = L["Remove trigger"],
			desc = L["Remove this trigger completely."],
			func = remove,
			disabled = isDefault,
			confirm = true,
			confirmText = L["Are you sure?"],
			order = 4,
		},
		classes = {
			type = 'group',
			name = L["Classes"],
			desc = L["Classes affected by this trigger."],
			order = 7,
			inline = true,
			args = {},
		},
		style = {
			type = 'group',
			name = L["Style"],
			desc = L["Configure what the Trigger should look like"],
			args = {
				icon = {
					type = 'input',
					name = L["Icon"],
					desc = L["The icon that is shown"],--Note: Spells that are not in the Spellbook (i.e. some Talents) can only be identified by SpellId (retrievable at www.wowhead.com, looking at the URL)
					usage = L["<Spell name> or <Item name> or <Path> or <SpellId>"],
					get = getIcon,
					set = setIcon,
					order = 2,
				},
				color = {
					name = L["Color"],
					desc = L["Color of the text for this trigger."],
					type = 'color',
					get = getColor,
					set = setColor,
					order = 5,
				},
				color2 = {
					name = L["Color"],
					desc = L["Color of the text for this trigger."],
					type = 'input',
					get = getColor2,
					set = setColor2,
					order = 6,
				},
				sticky = {
					type = 'toggle',
					name = L["Sticky"],
					desc = L["Whether to show this trigger as a sticky."],
					get = getSticky,
					set = setSticky,
					order = 9,
				},
				scrollArea = {
					type = 'select',
					values = Parrot:GetScrollAreasChoices(),
					name = L["Scroll area"],
					desc = L["Which scroll area to output to."],
					get = getScrollArea,
					set = setScrollArea,
					order = 8,
				},
				sound = {
					type = 'select',
					name = L["Sound"],
					desc = L["What sound to play when the trigger is shown."],
					values = Parrot.soundValues,
					get = getSound,
					set = setSound,
					itemControl = "DDI-Sound",
					order = 4,
				},
				test = {
					type = 'execute',
					-- buttonText = L["Test"],
					name = L["Test"],
					desc = L["Test how the trigger will look and act."],
					func = test,
					order = 1,
					width = 'full',
				},
				useflash = {
					type = 'toggle',
					name = "Use flash",
					desc = L["Flash screen in specified color"],
					get = getUseFlash,
					set = setUseFlash,
					order = 101,
				},
				flashcolor = {
					type = 'color',
					name = "Flash color",
					desc = L["Color in which to flash"],
					get = getFlashColor,
					set = setFlashColor,
					order = 102,
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
							values = Parrot.fontWithInheritValues,
							get = getFontFace,
							set = setFontFace,
							itemControl = "DDI-Font",
							order = 1,
						},
						fontSizeInherit = {
							type = 'toggle',
							name = L["Inherit font size"],
							desc = L["Inherit font size"],
							get = getFontSizeInherit,
							set = setFontSizeInherit,
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
							order = 3,
						},
						fontOutline = {
							type = 'select',
							name = L["Font outline"],
							desc = L["Font outline"],
							get = getFontOutline,
							set = setFontOutline,
							values = fontOutlineChoices,
							order = 4,
						},
					},
				},
			},
		},
	}
	local j = 0
	for class, localized in pairs(classChoices) do
		j = j + 1
		tsharedopt.classes.args[class] = {
			type = 'toggle',
			name = localized,
			desc = localized,
			get = getClass,
			set = setClass,
			order = j * 10,
		}
		tsharedopt.classes.args[class .. "-"] = {
			type = 'group',
			inline = true,
			width = 'half',
			name = localized,
			desc = localized,
			hidden = notIsClass,
			order = j * 10 + 1,
			args = {}
		}
		for i,v in ipairs(specChoices[class]) do
			local _, name, desc = GetSpecializationInfoByID(v)
			tsharedopt.classes.args[class .. "-"].args["Spec" .. v] = {
				type = 'toggle',
				name = name,
				desc = desc,
				get = getSpec,
				set = setSpec,
				hidden = false,
			}
		end
	end

	function makeOption(id, t)
		local opt = {
			type = 'group',
			name = getColoredName,
			desc = t.name,
			hidden = isHiddenForYourClass,
			order = t.name == L["New trigger"] and -110 or -100,
			arg = t,
			args = {
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
							arg = t,
							order = 1,
						},
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
							arg = t,
							order = 1,
						},
					}
				},
			}
		}
		for k,v in pairs(tsharedopt) do
			opt.args[k] = v
		end
		triggers_opt.args[tostring(id)] = opt
		for k,v in pairs(t.conditions) do
			if type(v) == 'table' then
				for i,cond in pairs(v) do
					local localName = Parrot_TriggerConditions:GetPrimaryConditionChoices()[k]
					addPrimaryCondition(id, t, k, localName, i)
				end
			else
				local localName = Parrot_TriggerConditions:GetPrimaryConditionChoices()[k]
				addPrimaryCondition(id, t, k, localName)
			end
		end
		if t.secondaryConditions then
			for k,v in pairs(t.secondaryConditions) do
				local localName = Parrot_TriggerConditions:GetSecondaryConditionChoices()[k]
				if type(v) == 'table' then
					for i in pairs(v) do
						addSecondaryCondition(id, t, k, localName, i)
					end
				else
					addSecondaryCondition(id, t, k, localName)
				end
			end
		end
	end

	for i, t in pairs(db.triggers2) do
		makeOption(i, t)
	end
end
