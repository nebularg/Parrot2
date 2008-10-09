local VERSION = tonumber(("$Revision: 340 $"):match("%d+"))

local Parrot = Parrot
if Parrot.revision < VERSION then
	Parrot.version = "r" .. VERSION
	Parrot.revision = VERSION
	Parrot.date = ("$Date: 2008-05-15 00:14:30 +0200 (Thu, 15 May 2008) $"):match("%d%d%d%d%-%d%d%-%d%d")
end

local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Parrot_Loot")

Parrot:RegisterCombatEvent{
	category = "Notification",
	subCategory = L["Loot"],
	name = "Loot items",
	localName = L["Loot items"],
	defaultTag = L["Loot [Name] +[Amount]([Total])"],
	parserEvent = {
		eventType = "Create",
		sourceID = "player",
		itemName_not = false,
		isCreated = false,
		itemRarity_gt = 0,
	},
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

local GOLD_ABBR = _G.GOLD_AMOUNT:sub(4,4)
local SILVER_ABBR = _G.SILVER_AMOUNT:sub(4,4)
local COPPER_ABBR = _G.COPPER_AMOUNT:sub(4,4)
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
}
