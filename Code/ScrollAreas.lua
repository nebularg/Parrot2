local Parrot = Parrot
local Parrot_ScrollAreas = Parrot:NewModule("ScrollAreas", "LibRockTimer-1.0")

local L = LibStub("AceLocale-3.0"):GetLocale("Parrot_ScrollAreas")

local scrollAreas

local choices = {}

Parrot_ScrollAreas.db = Parrot:GetDatabaseNamespace("ScrollAreas")

function Parrot_ScrollAreas:OnEnable()
	if not self.db.profile.areas then
		self.db.profile.areas = {
			["Notification"] = {
				animationStyle = "Straight",
				direction = "UP;CENTER",
				stickyAnimationStyle = "Pow",
				stickyDirection = "UP;CENTER",
				size = 150,
				xOffset = 0,
				yOffset = 175,
			},
			["Incoming"] = {
				animationStyle = "Parabola",
				direction = "DOWN;LEFT",
				stickyAnimationStyle = "Pow",
				stickyDirection = "DOWN;RIGHT",
				size = 260,
				xOffset = -60,
				yOffset = -30,
				iconSide = "RIGHT",
			},
			["Outgoing"] = {
				animationStyle = "Parabola",
				direction = "DOWN;RIGHT",
				stickyAnimationStyle = "Pow",
				stickyDirection = "DOWN;LEFT",
				size = 260,
				xOffset = 60,
				yOffset = -30,
			},
		}
	end	
	scrollAreas = self.db.profile.areas
	for k, v in pairs(scrollAreas) do
		if k == "Notification" or k == "Incoming" or k == "Outgoing" then
			choices[k] = L[k]
		else
			choices[k] = k
		end
	end
end

local setConfigMode
function Parrot_ScrollAreas:OnDisable()
	if setConfigMode then
		setConfigMode(false)
	end
end

--[[----------------------------------------------------------------------------------
Notes:
	Turn on/off the config mode boxes.
Arguments:
	boolean - whether to turn on.
Example:
	Parrot:SetConfigMode(true)
	-- or
	Parrot:SetConfigMode(false)
------------------------------------------------------------------------------------]]
function Parrot:SetConfigMode(state)
	if type(state) ~= "boolean" then
		error(("Bad argument #2 to `SetConfigMode'. Expected %q, got %q."):format("boolean", type(state)), 2)
	end
	setConfigMode(state)
end

local offsetBoxes
local function hideAllOffsetBoxes()
	if not offsetBoxes then
		return
	end
	for k,v in pairs(offsetBoxes) do
		v:Hide()
	end
	Parrot_ScrollAreas:RemoveTimer("Parrot_ScrollAreas-configModeMessages")
end
local function showOffsetBox(k)
	if not offsetBoxes then
		offsetBoxes = {}
	end
	local offsetBox = offsetBoxes[k]
	local name = k
	if name == "Notification" or name == "Incoming" or name == "Outgoing" then
		name = L[name]
	end
	if not offsetBox then
		offsetBox = CreateFrame("Button", "Parrot_ScrollAreas_OffsetBox_" .. k, UIParent)
		local midPoint = CreateFrame("Frame", "Parrot_ScrollAreas_OffsetBox_" .. k .. "_Midpoint", offsetBox)
		offsetBox.midPoint = midPoint
		midPoint:SetWidth(1)
		midPoint:SetHeight(1)
		offsetBoxes[k] = offsetBox
		offsetBox:SetPoint("CENTER", midPoint, "CENTER")
		offsetBox:SetWidth(300)
		offsetBox:SetHeight(100)
		offsetBox:SetFrameStrata("MEDIUM")
		
		local bg = offsetBox:CreateTexture("Parrot_ScrollAreas_OffsetBox_" .. k .. "_Background", "BACKGROUND")
		bg:SetTexture(0.7, 0.4, 0, 0.5) -- orange
		bg:SetAllPoints(offsetBox)
		
		local text = offsetBox:CreateFontString("Parrot_ScrollAreas_Offset_" .. k .. "_BoxText", "ARTWORK", "GameFontHighlight")
		offsetBox.text = text
		text:SetText(L["Click and drag to the position you want."])
		text:SetPoint("CENTER")
		local topText = offsetBox:CreateFontString("Parrot_ScrollAreas_Offset_" .. k .. "_BoxTopText", "ARTWORK", "GameFontHighlight")
		offsetBox.topText = topText
		topText:SetText(L["Scroll area: %s"]:format(name))
		topText:SetPoint("BOTTOM", offsetBox, "TOP", 0, 5)
		local bottomText = offsetBox:CreateFontString("Parrot_ScrollAreas_Offset_" .. k .. "_BoxBottomText", "ARTWORK", "GameFontHighlight")
		offsetBox.bottomText = bottomText
		bottomText:SetPoint("TOP", offsetBox, "BOTTOM", 0, -5)
		
		offsetBox:SetScript("OnDragStart", function(this)
			midPoint:StartMoving()
			this.moving = true
		end)
		
		offsetBox:SetScript("OnDragStop", function(this)
			this:GetScript("OnUpdate")(this)
			this.moving = nil
			midPoint:StopMovingOrSizing()
		end)
		
		offsetBox:SetScript("OnUpdate", function(this)
			if this.moving then
				local x, y = this:GetCenter()
				x = x - GetScreenWidth()/2
				y = y - GetScreenHeight()/2
				scrollAreas[k].xOffset = x
				scrollAreas[k].yOffset = y
				this.bottomText:SetText(L["Position: %d, %d"]:format(x, y))
			end
		end)
		
		offsetBox:SetMovable(true)
		offsetBox:RegisterForDrag("LeftButton")
		midPoint:SetMovable(true)
		midPoint:RegisterForDrag("LeftButton")
		offsetBox:Hide()
		
		midPoint:SetClampedToScreen(true)
	end

	offsetBox:Show()
	
	local offsetX, offsetY = scrollAreas[k].xOffset, scrollAreas[k].yOffset
	offsetBox.midPoint:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
	offsetBox.bottomText:SetText(L["Position: %d, %d"]:format(offsetX, offsetY))
end

local alphabet = {
	"Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf",
	"Hotel", "India", "Juliet", "Kilo", "Mike", "November", "Oscar",
	"Papa", "Quebec", "Romeo", "Sierra", "Tango", "Uniform", "Victor",
	"Whiskey", "X-ray", "Yankee", "Zulu",
}
local currentAlphabet = 1
local currentColor = 0
local function test(kind, k)
	local h = currentColor / 60
	local i = math.floor(h)
	local f = h - i
	local color
	local r, g, b
	if i == 0 then
		r, g, b = 1, f, 0
	elseif i == 1 then
		r, g, b = 1-f, 1, 0
	elseif i == 2 then
		r, g, b = 0, 1, f
	elseif i == 3 then
		r, g, b = 0, 1-f, 1
	elseif i == 4 then
		r, g, b = f, 0, 1
	else -- 5
		r, g, b = 1, 0, 1-f
	end
	Parrot:GetModule("Display"):ShowMessage(alphabet[currentAlphabet], k, kind == "sticky", r, g, b, nil, nil, nil, "Interface\\Icons\\INV_Misc_QuestionMark")
	currentAlphabet = (currentAlphabet%(#alphabet)) + 1
	currentColor = (currentColor + 10) % 360
end


local num = 0
local function configModeMessages()
	num = num%2 + 1
	for k in pairs(scrollAreas) do
		test("normal", k)
	end
	if num == 2 then
		for k in pairs(scrollAreas) do
			test("sticky", k)
		end
	end
end

local configMode = false

function setConfigMode(value)
	configMode = value
	if not value then
		hideAllOffsetBoxes()
	else
		for k in pairs(scrollAreas) do
			showOffsetBox(k)
		end
		Parrot_ScrollAreas:AddRepeatingTimer("Parrot_ScrollAreas-configModeMessages", 1, configModeMessages)
		configModeMessages()
	end
end

-- #NODOC
function Parrot_ScrollAreas:HasScrollArea(name)
	return not not scrollAreas[name]
end

-- #NODOC
function Parrot_ScrollAreas:GetScrollArea(name)
	return scrollAreas[name]
end

-- #NODOC
function Parrot_ScrollAreas:GetRandomScrollArea()
	local i = 0
	for k, v in pairs(scrollAreas) do
		i = i + 1
	end
	local num = math.random(1, i)
	i = 0
	for k, v in pairs(scrollAreas) do
		i = i + 1
		if i == num then
			return k, v
		end
	end
	return
end

--[[----------------------------------------------------------------------------------
Notes:
	This is to be used for LibRockConfig-1.0 tables.
Returns:
	table - A choices table for LibRockConfig-1.0 tables.
Example:
	{
		type = 'text',
		name = "Scroll area",
		desc = "Scroll area to use in Parrot.",
		choices = Parrot:GetScrollAreasChoices(),
		get = getScrollArea,
		set = setScrollArea,
	}
------------------------------------------------------------------------------------]]
function Parrot_ScrollAreas:GetScrollAreasChoices()
	return choices
end
Parrot.GetScrollAreasChoices = Parrot_ScrollAreas.GetScrollAreasChoices

function Parrot_ScrollAreas:OnOptionsCreate()
	local scrollAreas_opt
	local function getName(name)
		if name == "Notification" or name == "Incoming" or name == "Outgoing" then
			name = L[name]
		end
		return name
	end
	local function setName(old, new)
		if old == new or scrollAreas[new] then
			return
		end
		local shouldConfig = configMode
		if shouldConfig then
			setConfigMode(false)
		end
		local v = scrollAreas[old]
		scrollAreas[old] = nil
		scrollAreas[new] = v
		local opt = scrollAreas_opt.args[tostring(v)]
		local name = new
		if name == "Notification" or name == "Incoming" or name == "Outgoing" then
			name = L[name]
		end
		choices[old] = nil
		choices[new] = name
		if new == L["New scroll area"] then
			opt.order = -110
		else
			opt.order = -100
		end
		opt.name = name
		opt.args.name.passValue = new
		opt.args.remove.passValue = new
		opt.args.size.passValue = new
		opt.args.test.args.normal.passValue2 = new
		opt.args.test.args.sticky.passValue2 = new
		opt.args.direction.args.normal.passValue2 = new
		opt.args.direction.args.sticky.passValue2 = new
		opt.args.animationStyle.args.normal.passValue2 = new
		opt.args.animationStyle.args.sticky.passValue2 = new
		opt.args.speed.args.normal.passValue2 = new
		opt.args.speed.args.sticky.passValue2 = new
		opt.args.icon.passValue = new
		opt.args.positionX.passValue = new
		opt.args.positionY.passValue = new
		opt.args.font.args.fontface.passValue2 = new
		opt.args.font.args.fontSizeInherit.passValue2 = new
		opt.args.font.args.fontSize.passValue2 = new
		opt.args.font.args.fontOutline.passValue2 = new
		opt.args.font.args.stickyfontface.passValue2 = new
		opt.args.font.args.stickyfontSizeInherit.passValue2 = new
		opt.args.font.args.stickyfontSize.passValue2 = new
		opt.args.font.args.stickyfontOutline.passValue2 = new
		if shouldConfig then
			setConfigMode(true)
		end
	end
	local function getFontFace(kind, k)
		local font = scrollAreas[k][kind == "normal" and "font" or "stickyFont"]
		if font == nil then
			return L["Inherit"]
		else
			return font
		end
	end
	local function setFontFace(kind, k, value)
		if value == L["Inherit"] then
			value = nil
		end
		scrollAreas[k][kind == "normal" and "font" or "stickyFont"] = value
		if not configMode then
			test(kind, k)
		end
	end
	local function getFontSize(kind, k)
		return scrollAreas[k][kind == "normal" and "fontSize" or "stickyFontSize"]
	end
	local function setFontSize(kind, k, value)
		scrollAreas[k][kind == "normal" and "fontSize" or "stickyFontSize"] = value
		if not configMode then
			test(kind, k)
		end
	end
	local function getFontSizeInherit(kind, k)
		return scrollAreas[k][kind == "normal" and "fontSize" or "stickyFontSize"] == nil
	end
	local function setFontSizeInherit(kind, k, value)
		if value then
			scrollAreas[k][kind == "normal" and "fontSize" or "stickyFontSize"] = nil
		else
			scrollAreas[k][kind == "normal" and "fontSize" or "stickyFontSize"] = 18
		end
		if not configMode then
			test(kind, k)
		end
	end
	local function getFontOutline(kind, k)
		local outline = scrollAreas[k][kind == "normal" and "fontOutline" or "stickyFontOutline"]
		if outline == nil then
			return L["Inherit"]
		else
			return outline
		end
	end
	local function setFontOutline(kind, k, value)
		if value == L["Inherit"] then
			value = nil
		end
		scrollAreas[k][kind == "normal" and "fontOutline" or "stickyFontOutline"] = value
		if not configMode then
			test(kind, k)
		end
	end
	local fontOutlineChoices = {
		NONE = L["None"],
		OUTLINE = L["Thin"],
		THICKOUTLINE = L["Thick"],
		[L["Inherit"]] = L["Inherit"],
	}
	local function getAnimationStyle(kind, k)
		return scrollAreas[k][kind == "normal" and "animationStyle" or "stickyAnimationStyle"]
	end
	local function setAnimationStyle(kind, k, value)
		scrollAreas[k][kind == "normal" and "animationStyle" or "stickyAnimationStyle"] = value
		local opt = scrollAreas_opt.args[tostring(scrollAreas[k])]
		local choices = Parrot:GetModule("AnimationStyles"):GetAnimationStyleDirectionChoices(value)
		opt.args.direction.args[kind].choices = choices
		if not choices[scrollAreas[k][kind == "normal" and "direction" or "stickyDirection"]] then
			scrollAreas[k][kind == "normal" and "direction" or "stickyDirection"] = Parrot:GetModule("AnimationStyles"):GetAnimationStyleDefaultDirection(value)
		end
		if not configMode then
			test(kind, k)
			test(kind, k)
			test(kind, k)
		end
	end
	local function getSpeed(kind, k)
		return scrollAreas[k][kind == "normal" and "speed" or "stickySpeed"] or 3
	end
	local function setSpeed(kind, k, value)
		if value == 3 then
			value = nil
		end
		scrollAreas[k][kind == "normal" and "speed" or "stickySpeed"] = value
		if not configMode then
			test(kind, k)
		end
	end
	local function getDirection(kind, k)
		return scrollAreas[k][kind == "normal" and "direction" or "stickyDirection"] or Parrot:GetModule("AnimationStyles"):GetAnimationStyleDefaultDirection(scrollAreas[k][kind == "normal" and "animationStyle" or "stickyAnimationStyle"])
	end
	local function setDirection(kind, k, value)
		if value == Parrot:GetModule("AnimationStyles"):GetAnimationStyleDefaultDirection(scrollAreas[k][kind == "normal" and "animationStyle" or "stickyAnimationStyle"]) then
			value = nil
		end
		scrollAreas[k][kind == "normal" and "direction" or "stickyDirection"] = value
		if not configMode then
			test(kind, k)
			test(kind, k)
			test(kind, k)
		end
	end
	local function directionDisabled(kind, k)
		return not Parrot:GetModule("AnimationStyles"):GetAnimationStyleDirectionChoices(scrollAreas[k][kind == "normal" and "animationStyle" or "stickyAnimationStyle"])
	end
	local function getPositionX(k)
		return scrollAreas[k].xOffset
	end
	local function setPositionX(k, value)
		if value > 0 then
			if value > GetScreenWidth()/2 then
				value = GetScreenWidth()/2
			end
		else
			if value < -GetScreenWidth()/2 then
				value = -GetScreenWidth()/2
			end
		end
		scrollAreas[k].xOffset = value
		if not configMode then
			test("normal", k)
			test("sticky", k)
		end
	end
	local function getPositionY(k)
		return scrollAreas[k].yOffset
	end
	local function setPositionY(k, value)
		if value > 0 then
			if value > GetScreenHeight()/2 then
				value = GetScreenHeight()/2
			end
		else
			if value < -GetScreenHeight()/2 then
				value = -GetScreenHeight()/2
			end
		end
		scrollAreas[k].yOffset = value
		if not configMode then
			test("normal", k)
			test("sticky", k)
		end
	end
	local function getSize(k)
		return scrollAreas[k].size
	end
	local function setSize(k, value)
		scrollAreas[k].size = value
		if not configMode then
			test("normal", k)
			test("sticky", k)
		end
	end
	local function remove(k)
		local shouldConfig = configMode
		if shouldConfig then
			setConfigMode(false)
		end
		scrollAreas_opt.args[tostring(scrollAreas[k])] = nil
		scrollAreas[k] = nil
		choices[k] = nil
		if shouldConfig then
			setConfigMode(true)
		end
	end
	local function disableRemove(k)
		return not next(scrollAreas, next(scrollAreas))
	end
	local function getIconSide(k)
		return scrollAreas[k].iconSide or "LEFT"
	end
	local function setIconSide(k, value)
		if value == "LEFT" then
			value = nil
		end
		scrollAreas[k].iconSide = value
		if not configMode then
			test("normal", k)
			test("sticky", k)
		end
	end
	local iconSideChoices = {
		LEFT = L["Left"],
		RIGHT = L["Right"],
		CENTER = L["Center of screen"],
		EDGE = L["Edge of screen"],
		DISABLE = L["Disable"],
	}
	local function makeOption(k)
		local SharedMedia = Rock("LibSharedMedia-3.0")
		local v = scrollAreas[k]
		local name = k
		if name == "Notification" or name == "Incoming" or name == "Outgoing" then
			name = L[name]
		end
		local opt = {
			type = 'group',
			name = name,
			desc = L["Options for this scroll area."],
			args = {
				name = {
					type = 'string',
					name = L["Name"],
					desc = L["Name of the scroll area."],
					get = getName,
					set = setName,
					usage = L["<Name>"],
					passValue = k,
					order = 1,
				},
				remove = {
					type = 'execute',
					name = L["Remove"],
					desc = L["Remove this scroll area."],
					func = remove,
					disabled = disableRemove,
					passValue = k,
					order = -1,
					confirmText = L["Are you sure?"],
					buttonText = L["Remove"],
				},
				icon = {
					type = 'choice',
					name = L["Icon side"],
					desc = L["Set the icon side for this scroll area or whether to disable icons entirely."],
					get = getIconSide,
					set = setIconSide,
					choices = iconSideChoices,
					passValue = k,
				},
				test = {
					type = 'group',
					groupType = 'inline',
					name = L["Test"],
					desc = L["Send a test message through this scroll area."],
					args = {
						normal = {
							type = 'execute',
							name = L["Normal"],
							buttonText = L["Send"],
							desc = L["Send a normal test message."],
							func = test,
							passValue = "normal",
							passValue2 = k,
						},
						sticky = {
							type = 'execute',
							name = L["Sticky"],
							buttonText = L["Send"],
							desc = L["Send a sticky test message."],
							func = test,
							passValue = "sticky",
							passValue2 = k,
						},
					},
					disabled = function() return configMode end
				},
				direction = {
					type = 'group',
					groupType = 'inline',
					name = L["Direction"],
					desc = L["Which direction the animations should follow."],
					args = {
						normal = {
							type = 'choice',
							name = L["Normal"],
							desc = L["Direction for normal texts."],
							get = getDirection,
							set = setDirection,
							disabled = directionDisabled,
							choices = Parrot:GetModule("AnimationStyles"):GetAnimationStyleDirectionChoices(scrollAreas[k].animationStyle) or {},
							passValue = "normal",
							passValue2 = k,
						},
						sticky = {
							type = 'choice',
							name = L["Sticky"],
							desc = L["Direction for sticky texts."],
							get = getDirection,
							set = setDirection,
							disabled = directionDisabled,
							choices = Parrot:GetModule("AnimationStyles"):GetAnimationStyleDirectionChoices(scrollAreas[k].stickyAnimationStyle) or {},
							passValue = "sticky",
							passValue2 = k,
						},
					}
				},
				animationStyle = {
					type = 'group',
					groupType = 'inline',
					name = L["Animation style"],
					desc = L["Which animation style to use."],
					args = {
						normal = {
							type = 'choice',
							name = L["Normal"],
							desc = L["Animation style for normal texts."],
							get = getAnimationStyle,
							set = setAnimationStyle,
							choices = Parrot:GetModule("AnimationStyles"):GetAnimationStylesChoices(),
							passValue = "normal",
							passValue2 = k,
						},
						sticky = {
							type = 'choice',
							name = L["Sticky"],
							desc = L["Animation style for sticky texts."],
							get = getAnimationStyle,
							set = setAnimationStyle,
							choices = Parrot:GetModule("AnimationStyles"):GetAnimationStylesChoices(),
							passValue = "sticky",
							passValue2 = k,
						},
					}
				},
				positionX = {
					type = 'number',
					name = L["Position: horizontal"],
					desc = L["The position of the box across the screen"],
					get = getPositionX,
					set = setPositionX,
					min = math.floor(-GetScreenWidth()/GetScreenHeight()*768 / 0.64 / 2 / 10) * 10,
					max = math.ceil(GetScreenWidth()/GetScreenHeight()*768 / 0.64 / 2 / 10) * 10,
					step = 1,
					bigStep = 10,
					passValue = k,
				},
				positionY = {
					type = 'number',
					name = L["Position: vertical"],
					desc = L["The position of the box up-and-down the screen"],
					get = getPositionY,
					set = setPositionY,
					min = math.floor(-768 / 0.64 / 2 / 10) * 10,
					max = math.ceil(768 / 0.64 / 2 / 10) * 10,
					step = 1,
					bigStep = 10,
					passValue = k,
				},
				size = {
					type = 'number',
					name = L["Size"],
					desc = L["How large of an area to scroll."],
					get = getSize,
					set = setSize,
					min = 50,
					max = 800,
					step = 1,
					bigStep = 10,
					passValue = k,
				},
				speed = {
					type = 'group',
					groupType = 'inline',
					name = L["Scrolling speed"],
					desc = L["How fast the text scrolls by."],
					args = {
						normal = {
							type = 'number',
							name = L["Normal"],
							desc = L["Seconds for the text to complete the whole cycle, i.e. larger numbers means slower."],
							min = 1,
							max = 20,
							step = 0.1,
							bigStep = 1,
							get = getSpeed,
							set = setSpeed,
							passValue = "normal",
							passValue2 = k,
						},
						sticky = {
							type = 'number',
							name = L["Sticky"],
							desc = L["Seconds for the text to complete the whole cycle, i.e. larger numbers means slower."],
							min = 1,
							max = 20,
							step = 0.1,
							bigStep = 1,
							get = getSpeed,
							set = setSpeed,
							passValue = "sticky",
							passValue2 = k,
						},
					}
				},
				font = {
					type = 'group',
					groupType = 'inline',
					name = L["Custom font"],
					desc = L["Custom font"],
					args = {
						fontface = {
							type = 'choice',
							name = L["Normal font face"],
							desc = L["Normal font face"],
							choices = Parrot.inheritFontChoices,
							choiceFonts = SharedMedia:HashTable('font'),
							get = getFontFace,
							set = setFontFace,
							passValue = "normal",
							passValue2 = k,
							order = 1,
						},
						fontSizeInherit = {
							type = 'boolean',
							name = L["Normal inherit font size"],
							desc = L["Normal inherit font size"],
							get = getFontSizeInherit,
							set = setFontSizeInherit,
							passValue = "normal",
							passValue2 = k,
							order = 2,
						},
						fontSize = {
							type = 'number',
							name = L["Normal font size"],
							desc = L["Normal font size"],
							min = 12,
							max = 30,
							step = 1,
							get = getFontSize,
							set = setFontSize,
							disabled = getFontSizeInherit,
							passValue = "normal",
							passValue2 = k,
							order = 3,
						},
						fontOutline = {
							type = 'choice',
							name = L["Normal font outline"],
							desc = L["Normal font outline"],
							get = getFontOutline,
							set = setFontOutline,
							choices = fontOutlineChoices,
							passValue = "normal",
							passValue2 = k,
							order = 4,
						},
						stickyfontface = {
							type = 'choice',
							name = L["Sticky font face"],
							desc = L["Sticky font face"],
							choices = Parrot.inheritFontChoices,
							choiceFonts = SharedMedia:HashTable('font'),
							get = getFontFace,
							set = setFontFace,
							passValue = "sticky",
							passValue2 = k,
							order = 5,
						},
						stickyfontSizeInherit = {
							type = 'boolean',
							name = L["Sticky inherit font size"],
							desc = L["Sticky inherit font size"],
							get = getFontSizeInherit,
							set = setFontSizeInherit,
							passValue = "sticky",
							passValue2 = k,
							order = 6,
						},
						stickyfontSize = {
							type = 'number',
							name = L["Sticky font size"],
							desc = L["Sticky font size"],
							min = 12,
							max = 30,
							step = 1,
							get = getFontSize,
							set = setFontSize,
							disabled = getFontSizeInherit,
							passValue = "sticky",
							passValue2 = k,
							order = 7,
						},
						stickyfontOutline = {
							type = 'choice',
							name = L["Sticky font outline"],
							desc = L["Sticky font outline"],
							get = getFontOutline,
							set = setFontOutline,
							choices = fontOutlineChoices,
							passValue = "sticky",
							passValue2 = k,
							order = 8,
						},
					}
				}
			},
			order = -100,
		}
		scrollAreas_opt.args[tostring(v)] = opt
	end
	
	scrollAreas_opt = {
		type = 'group',
		name = L["Scroll areas"],
		desc = L["Options regarding scroll areas."],
		disabled = function()
			return not self:IsActive()
		end,
		args = {
			config = {
				type = 'boolean',
				name = L["Configuration mode"],
				desc = L["Enter configuration mode, allowing you to move around the scroll areas and see them in action."],
				get = function()
					return configMode
				end,
				set = setConfigMode
			},
			new = {
				type = 'execute',
				name = L["New scroll area"],
				buttonText = L["Create"],
				desc = L["Add a new scroll area."],
				func = function()
					local shouldConfig = configMode
					if shouldConfig then
						setConfigMode(false)
					end
					scrollAreas[L["New scroll area"]] = {
						animationStyle = "Straight",
						direction = Parrot:GetModule("AnimationStyles"):GetAnimationStyleDefaultDirection("Straight"),
						stickyAnimationStyle = "Pow",
						direction = Parrot:GetModule("AnimationStyles"):GetAnimationStyleDefaultDirection("Pow"),
						size = 150,
						xOffset = 0,
						yOffset = 0,
					}
					makeOption(L["New scroll area"])
					scrollAreas_opt.args[tostring(scrollAreas[L["New scroll area"]])].order = -110
					if shouldConfig then
						setConfigMode(true)
					end
				end,
				disabled = function()
					return scrollAreas[L["New scroll area"]]
				end
			}
		},
	}
	Parrot:AddOption('scrollAreas', scrollAreas_opt)
	scrollAreas = self.db.profile.areas
	for k, v in pairs(scrollAreas) do
		makeOption(k)
		if k == L["New scroll area"] then
			scrollAreas_opt.args[tostring(v)].order = -110
		end
	end
end
