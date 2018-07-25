local _, ns = ...
local Parrot = ns.addon
local L = LibStub("AceLocale-3.0"):GetLocale("Parrot")

local newDict = Parrot.newDict
local Deformat = Parrot.Deformat

local LOOT_ITEM_SELF = _G.LOOT_ITEM_SELF
local LOOT_ITEM_SELF_MULTIPLE = _G.LOOT_ITEM_SELF_MULTIPLE
local LOOT_ITEM_PUSHED_SELF = _G.LOOT_ITEM_PUSHED_SELF
local LOOT_ITEM_PUSHED_SELF_MULTIPLE = _G.LOOT_ITEM_PUSHED_SELF_MULTIPLE
local LOOT_ITEM_CREATED_SELF = _G.LOOT_ITEM_CREATED_SELF
local LOOT_ITEM_CREATED_SELF_MULTIPLE = _G.LOOT_ITEM_CREATED_SELF_MULTIPLE
local LOOT_ITEM_REFUND = _G.LOOT_ITEM_REFUND
local LOOT_ITEM_REFUND_MULTIPLE = _G.LOOT_ITEM_REFUND_MULTIPLE
local ITEM_QUALITY_COLORS = _G.ITEM_QUALITY_COLORS

local function parse_CHAT_MSG_LOOT(chatmsg)
	-- check for multiple
	local itemLink, amount = Deformat(chatmsg, LOOT_ITEM_SELF_MULTIPLE)
	if not itemLink then
		itemLink, amount = Deformat(chatmsg, LOOT_ITEM_PUSHED_SELF_MULTIPLE)
	end
	if not itemLink then
		itemLink, amount = Deformat(chatmsg, LOOT_ITEM_CREATED_SELF_MULTIPLE)
	end
	if not itemLink then
		itemLink, amount = Deformat(chatmsg, LOOT_ITEM_REFUND_MULTIPLE)
	end

	-- check for single
	if not itemLink then
		itemLink = Deformat(chatmsg, LOOT_ITEM_SELF)
	end
	if not itemLink then
		itemLink = Deformat(chatmsg, LOOT_ITEM_PUSHED_SELF)
	end
	if not itemLink then
		itemLink = Deformat(chatmsg, LOOT_ITEM_CREATED_SELF)
	end
	if not itemLink then
		itemLink = Deformat(chatmsg, LOOT_ITEM_REFUND)
	end

	-- if something has been looted
	if itemLink then
		if not amount then
			amount = 1
		end
		local name, _, quality, _, _, _, _, _, _, texture = GetItemInfo(itemLink)
		local color = ITEM_QUALITY_COLORS[quality]
		if color then
			name = ("%s%s|r"):format(color.hex, name)
		end

		return newDict(
			"name", name,
			"amount", amount,
			"total", GetItemCount(itemLink) + amount,
			"icon", texture
		)
	end
end

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Loot"],
	name = "Loot items",
	localName = L["Loot items"],
	defaultTag = L["Loot [Name] +[Amount]([Total])"],
	tagTranslations = {
		Name = "name",
		Amount = "amount",
		Total = "total",
		Icon = "icon",
	},
	tagTranslationsHelp = {
		Name = L["The name of the item."],
		Amount = L["The amount of items looted."],
		Total = L["The total amount of items in inventory."],
	},
	events = {
		CHAT_MSG_LOOT = { parse = parse_CHAT_MSG_LOOT, },
	},
	color = "ffffff", -- white
}


local moneyStrings = {
	_G.LOOT_MONEY_SPLIT,
	_G.LOOT_MONEY_SPLIT_GUILD,
	_G.YOU_LOOT_MONEY,
	_G.YOU_LOOT_MONEY_GUILD,
	_G.LOOT_MONEY_REFUND,
}
local GOLD_AMOUNT_inv = _G.GOLD_AMOUNT:gsub("%%d", "(%1+)")
local SILVER_AMOUNT_inv = _G.SILVER_AMOUNT:gsub("%%d", "(%1+)")
local COPPER_AMOUNT_inv = _G.COPPER_AMOUNT:gsub("%%d", "(%1+)")
local GOLD_AMOUNT_SYMBOL = _G.GOLD_AMOUNT_SYMBOL
local SILVER_AMOUNT_SYMBOL = _G.SILVER_AMOUNT_SYMBOL
local COPPER_AMOUNT_SYMBOL = _G.COPPER_AMOUNT_SYMBOL

local function parse_CHAT_MSG_MONEY(chatmsg)
	for _, moneyString in ipairs(moneyStrings) do
		local amount = Deformat(chatmsg, moneyString)
		if amount then
			local gold = chatmsg:match(GOLD_AMOUNT_inv) or 0
			local silver = chatmsg:match(SILVER_AMOUNT_inv) or 0
			local copper = chatmsg:match(COPPER_AMOUNT_inv) or 0
			return newDict(
				"amount", 10000 * gold + 100 * silver + copper
			)
		end
	end
end

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Loot"],
	name = "Loot money",
	localName = L["Loot money"],
	defaultTag = L["Loot +[Amount]"],
	tagTranslations = {
		Amount = function(info)
			local value = info.amount
			if value >= 10000 then
				local gold = value / 10000
				local silver = (value / 100) % 100
				local copper = value % 100
				return ("%d|cffffd700%s|r%d|cffc7c7cf%s|r%d|cffeda55f%s|r"):format(gold, GOLD_AMOUNT_SYMBOL, silver, SILVER_AMOUNT_SYMBOL, copper, COPPER_AMOUNT_SYMBOL)
			elseif value >= 100 then
				local silver = value / 100
				local copper = value % 100
				return ("%d|cffc7c7cf%s|r%d|cffeda55f%s|r"):format(silver, SILVER_AMOUNT_SYMBOL, copper, COPPER_AMOUNT_SYMBOL)
			else
				return ("%d|cffeda55f%s|r"):format(value, COPPER_AMOUNT_SYMBOL)
			end
		end,
	},
	tagTranslationsHelp = {
		Amount = L["The amount of gold looted."],
	},
	events = {
		CHAT_MSG_MONEY = { parse = parse_CHAT_MSG_MONEY, },
	},
	color = "ffffff", -- white
}

