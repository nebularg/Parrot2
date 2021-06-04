local _, ns = ...
local Parrot = ns.addon
if not Parrot then return end

local module = Parrot:NewModule("Cooldowns", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Parrot")

local newList, del = Parrot.newList, Parrot.del

local db = nil
local defaults = {
	profile = {
		threshold = 12,
		filters = {},
	}
}

local spells = {}
local spellGroups = {}
local spellCooldowns = {}
local itemCooldowns = {}

-- do
-- 	local function addGroup(name, ...)
-- 		for i=1, select("#", ...) do
-- 			local id = select(i, ...)
-- 			local spell = GetSpellInfo(id)
-- 			if spell then
-- 				spellGroups[spell] = name
-- 			else
-- 				print("Parrot: Cooldown spell missing:", id)
-- 			end
-- 		end
-- 	end
-- 	addGroup(L["Strikes"], 17364, 73899) -- Stormstrike, Primal Strike
-- end

function module:OnProfileChanged()
	db = self.db.profile
end

function module:OnInitialize()
	self.db = Parrot.db:RegisterNamespace("Cooldowns", defaults)
	db = self.db.profile
end

function module:OnEnable()
	self:RegisterEvent("BAG_UPDATE_COOLDOWN", "CheckItems")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "CheckItems")
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN", "CheckSpells")
	self:RegisterEvent("SPELLS_CHANGED", "ResetSpells")
end

function module:CheckItems()
	for i = 1, 19 do
		local link = GetInventoryItemLink("player", i)
		if link then
			local start, duration = GetInventoryItemCooldown("player", i)
			local oldLink = itemCooldowns[i]
			if oldLink then
				if start == 0 then -- cooldown expired
					if oldLink == link then
						local name = GetItemInfo(link)
						Parrot:FirePrimaryTriggerCondition("Item cooldown ready", name)

						--local info = newList(name, texture)
						--Parrot:TriggerCombatEvent("Notification", "Skill cooldown finish", info)
						--info = del(info)
					end
					itemCooldowns[i] = nil
				end
			elseif start > 0 then -- cooldown started
				itemCooldowns[i] = link
				local remaining = duration - (GetTime() - start) + 0.1
				self:ScheduleTimer("CheckItems", remaining)
			end
		end
	end
end

function module:ResetSpells(e)
	wipe(spells)
	wipe(spellCooldowns)
	-- cache spells from our current spec plus racials
	for tab = 1, 2 do
		local _, _, offset, numSlots = GetSpellTabInfo(tab)
		for slot = 1, numSlots do
			local index = offset + slot
			local spellName, subSpellName = GetSpellBookItemName(index, "spell")
			if tab > 1 or subSpellName == "Racial" then -- damn Blizzard for not having a "Racial" global string
				spells[spellName] = true
				local start, duration = GetSpellCooldown(index, "spell")
				if start and start > 0 and duration > db.threshold and not db.filters[spellName] then
					spellCooldowns[spellName] = start
				end
			end
		end
	end
end

function module:CheckSpells(e)
	local expired = newList()
	for spellName in next, spells do
		local start, duration = GetSpellCooldown(spellName)
		if spellCooldowns[spellName] and (start == 0 or spellCooldowns[spellName] == start) then
			if start == 0 then
				expired[spellName] = true
				spellCooldowns[spellName] = nil
			end
		elseif start and start > 0 and duration > db.threshold and not db.filters[spellName] then
			spellCooldowns[spellName] = start
			local remaining = duration - (GetTime() - start) + 0.1
			self:ScheduleTimer("CheckSpells", remaining)
			-- can probably improve this to schedule checking the single spell
			-- that triggered the cooldown, but then I would have to move the
			-- "tree reset" logic here, which would be run more frequently
		end
	end

	if next(expired) then
		local count = 0
		for spellName in next, expired do
			Parrot:FirePrimaryTriggerCondition("Spell ready", spellName)
			if not spellGroups[spellName] then
				count = count + 1
			end
		end

		if count > 4 then -- don't spam if something reset a bunch of spells
			local name, texture = GetSpellTabInfo(2)
			if name then
				local info = newList(L["%s Tree"]:format(name), texture)
				Parrot:TriggerCombatEvent("Notification", "Skill cooldown finish", info)
				info = del(info)
			end
		else
			local groupTriggered = newList()
			for spellName in next, expired do
				local group = spellGroups[spellName]
				if not group then -- normal cooldown finish
					local texture = GetSpellTexture(spellName)
					local info = newList(spellName, texture)
					Parrot:TriggerCombatEvent("Notification", "Skill cooldown finish", info)
					info = del(info)
				elseif not groupTriggered[group] then -- shared cooldown finish
					groupTriggered[group] = true
					local info = newList(spellName)
					Parrot:TriggerCombatEvent("Notification", "Skill cooldown finish", info)
					info = del(info)
				end
			end
			groupTriggered = del(groupTriggered)
		end
	end
	del(expired)
end


Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Cooldowns"],
	name = "Skill cooldown finish",
	localName = L["Skill cooldown finish"],
	defaultTag = L["[[Spell] ready!]"],
	tagTranslations = {
		Spell = 1,
		Icon = 2,
	},
	tagTranslationsHelp = {
		Spell = L["The name of the spell or ability which is ready to be used."],
	},
	color = "ffffff",
	sticky = false,
}

local function parseSpell(arg)
	return arg and tostring(arg) or ""
end
local function saveSpell(arg)
	return tonumber(arg) or arg
end

Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Cooldowns"],
	name = "Spell ready",
	localName = L["Spell ready"],
	param = {
		type = "string",
		usage = L["<Spell name>"],
		save = saveSpell,
		parse = parseSpell,
	},
}

Parrot:RegisterPrimaryTriggerCondition {
	subCategory = L["Cooldowns"],
	name = "Item cooldown ready",
	localName = L["Item cooldown ready"],
	param = {
		type = "string",
		usage = L["<Item name>"],
	},
}

Parrot:RegisterSecondaryTriggerCondition {
	subCategory = L["Cooldowns"],
	name = "Spell ready",
	localName = L["Spell ready"],
	param = {
		type = "string",
		usage = L["<Spell name>"],
		save = saveSpell,
		parse = parseSpell,
	},
	check = function(param)
		return GetSpellCooldown(param) == 0
	end,
}

Parrot:RegisterSecondaryTriggerCondition {
	subCategory = L["Cooldowns"],
	name = "Spell usable",
	localName = L["Spell usable"],
	param = {
		type = "string",
		usage = L["<Spell name>"],
		save = saveSpell,
		parse = parseSpell,
	},
	check = function(param)
		return IsUsableSpell(param)
	end,
}

function module:OnOptionsCreate()
	local options = {
		type = "group",
		name = L["Cooldowns"],
		--desc = L["Cooldowns"],
		args = {
			threshold = {
				name = L["Threshold"],
				desc = L["Minimum time the cooldown must have (in seconds)"],
				type = "range",
				min = 1.5, max = 360, step = 0.5, bigStep = 10,
				get = function() return db.threshold end,
				set = function(info, value) db.threshold = value end,
				order = 1,
			},
		},
		order = 100,
	}

	local function addFilter(spellName)
		if options.args[spellName] then return end
		db.filters[spellName] = true

		local button = {
			type = "execute",
			name = spellName,
			desc = L["Click to remove"],
			func = function(info)
				local key = info[#info]
				options.args[key] = nil
				db.filters[key] = nil
				module:ResetSpells()
				GameTooltip:Hide()
			end,
		}
		options.args[spellName] = button
	end

	options.args.newFilter = {
		type = "input",
		name = L["Ignore"],
		desc = L["Ignore Cooldown"],
		get = false,
		set = function(info, value)
			addFilter(value)
			module:ResetSpells()
		end,
		order = 2,
	}

	for spellName in next, db.filters do
		addFilter(spellName)
	end

	Parrot:AddOption("cooldowns", options)
end
