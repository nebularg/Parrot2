local Parrot = Parrot

local mod = Parrot:NewModule("Loot")

local L = LibStub("AceLocale-3.0"):GetLocale("Parrot_Loot")
local Deformat = AceLibrary("Deformat-2.0")

local debug = Parrot.debug

mod.currentHonor = 0
mod.currentXP = 0

local YOU_LOOT_MONEY = _G.YOU_LOOT_MONEY
local LOOT_MONEY_SPLIT = _G.LOOT_MONEY_SPLIT
local LOOT_ITEM_SELF_MULTIPLE = _G.LOOT_ITEM_SELF_MULTIPLE
local LOOT_ITEM_SELF = _G.LOOT_ITEM_SELF
local LOOT_ITEM_CREATED_SELF = _G.LOOT_ITEM_CREATED_SELF

local GOLD_AMOUNT = _G.GOLD_AMOUNT
local SILVER_AMOUNT = _G.SILVER_AMOUNT
local COPPER_AMOUNT = _G.COPPER_AMOUNT

function mod:OnEnable()
	mod.currentHonor = GetHonorCurrency()
	mod.currentXP = UnitXP("player")
end

function mod:CHAT_MSG_LOOT(_, eventName, chatmsg)

	-- check for multiple-item-loot
	local itemLink, amount = Deformat(chatmsg, LOOT_ITEM_SELF_MULTIPLE)
	if not itemLink then
		-- check for single-itemloot
		itemLink = Deformat(chatmsg, LOOT_ITEM_SELF)
	end

	-- if something has been looted
	if itemLink then

		if not amount then
			amount = 1
		end

		local info = newList()
		info.itemLink = itemLink
		info.amount = amount
		self:TriggerCombatEvent("Notification", "Loot items", info)
	elseif playerClass == "WARLOCK" then
		-- check for soul shard-create
		itemLink = Deformat(chatmsg, LOOT_ITEM_CREATED_SELF)
		itemName = GetItemInfo(6265)
		if itemLink and itemName and itemLink:match(".*" .. itemName .. ".*") then
			local info = newList()
			info.itemName = itemName
			info.itemLink = itemLink
			self:TriggerCombatEvent("Notification", "Soul shard gains", info)
		end
	end

end

local function parse_CHAT_MSG_LOOT(chatmsg)
	-- check for multiple-item-loot
	local itemLink, amount = Deformat(chatmsg, LOOT_ITEM_SELF_MULTIPLE)
	if not itemLink then
		itemLink, amount = Deformat(chatmsg, LOOT_ITEM_PUSHED_SELF_MULTIPLE)
	end
--	if not itemLink then
--		itemLink, amount = Deformat(chatmsg, LOOT_ITEM_CREATED_SELF_MULTIPLE)
--	end

	-- check for single-itemloot
	if not itemLink then
		itemLink = Deformat(chatmsg, LOOT_ITEM_SELF)
	end
	if not itemLink then
		itemLink, amount = Deformat(chatmsg, LOOT_ITEM_PUSHED_SELF)
	end
--	if not itemLink then
--		itemLink, amount = Deformat(chatmsg, LOOT_ITEM_CREATED_SELF)
--	end

	-- if something has been looted
	if itemLink then
		if not amount then
			amount = 1
		end
		return {
			itemLink = itemLink,
			amount = amount,
		}
	end
end

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Loot"],
	name = "Loot items",
	localName = L["Loot items"],
	defaultTag = L["Loot [Name] +[Amount]([Total])"],
	tagTranslations = {
		Name = function(info)
			local name, _, rarity = GetItemInfo(info.itemLink or info.itemName)
			local color = ITEM_QUALITY_COLORS[rarity]
			if color then
				return color.hex .. name .. "|r"
			else
				return name
			end
		end,
		Amount = "amount",
		Total = function(info)
			local oldTotal = GetItemCount(info.itemLink or info.itemName)
			return oldTotal + info.amount
		end,
		Icon = function(info)
			local itemLink = info.itemLink
			if itemLink then
				local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemLink)
				return texture
			end
		end,
	},
	tagTranslationHelp = {
		Name = L["The name of the item."],
		Amount = L["The amount of items looted."],
		Total = L["The total amount of items in inventory."],
	},
	blizzardEvents = {
		["CHAT_MSG_LOOT"] = {
			-- check = nocheck,
			parse = parse_CHAT_MSG_LOOT,
		},
	},
	color = "ffffff", -- white
}

local function utf8trunc(text, num)
	local len = 0
	local i = 1
	local text_len = #text
	while len < num and i <= text_len do
		len = len + 1
		local b = text:byte(i)
		if b <= 127 then
			i = i + 1
		elseif b <= 223 then
			i = i + 2
		elseif b <= 239 then
			i = i + 3
		else
			i = i + 4
		end
	end
	return text:sub(1, i-1)
end

local GOLD_AMOUNT_inv = GOLD_AMOUNT:gsub("%%d", "%%d+")
local SILVER_AMOUNT_inv = SILVER_AMOUNT:gsub("%%d", "%%d+")
local COPPER_AMOUNT_inv = COPPER_AMOUNT:gsub("%%d", "%%d+")


local GOLD_ABBR = GOLD_AMOUNT:sub(4,4)
local SILVER_ABBR = SILVER_AMOUNT:sub(4,4)
local COPPER_ABBR = COPPER_AMOUNT:sub(4,4)
if GOLD_ABBR:len() == 1 then
	GOLD_ABBR = GOLD_ABBR:lower()
end
if SILVER_ABBR:len() == 1 then
	SILVER_ABBR = SILVER_ABBR:lower()
end
if COPPER_ABBR:len() == 1 then
	COPPER_ABBR = COPPER_ABBR:lower()
end

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Loot"],
	name = "Loot money",
	localName = L["Loot money"],
	defaultTag = L["Loot +[Amount]"],
	parserEvent = {
		eventType = "Create",
		sourceID = "player",
		itemName = false,
		isCreated = false,
	},
	tagTranslations = {
		Amount = function(info)
			local value = info.amount
			if value >= 10000 then
				return ("%d|cffffd700%s|r%d|cffc7c7cf%s|r%d|cffeda55f%s|r"):format(value/10000, GOLD_ABBR, (value/100)%100, SILVER_ABBR, value%100, COPPER_ABBR)
			elseif value >= 100 then
				return ("%d|cffc7c7cf%s|r%d|cffeda55f%s|r"):format(value/100, SILVER_ABBR, value%100, COPPER_ABBR)
			else
				return ("%d|cffeda55f%s|r"):format(value, COPPER_ABBR)
			end
		end,
--		Icon = function()
--			return ""
--		end
	},
	tagTranslationHelp = {
		Amount = L["The amount of gold looted."],
	},
	color = "ffffff", -- white
	blizzardEvents = {
		["CHAT_MSG_MONEY"] = {
			parse = function(chatmsg)
					local moneystring = Deformat(chatmsg, LOOT_MONEY_SPLIT) or Deformat(chatmsg, YOU_LOOT_MONEY)
					if moneystring then
						local gold = (Deformat(chatmsg:match(GOLD_AMOUNT_inv) or "", GOLD_AMOUNT)) or 0
						local silver = (Deformat(chatmsg:match(SILVER_AMOUNT_inv) or "", SILVER_AMOUNT)) or 0
						local copper = (Deformat(chatmsg:match(COPPER_AMOUNT_inv) or "", COPPER_AMOUNT)) or 0
						return {
							amount = 10000*gold + 100 * silver + copper
						}
					end
				end,
		}
	}
}

