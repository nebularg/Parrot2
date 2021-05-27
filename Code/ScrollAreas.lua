local _, ns = ...
local Parrot = ns.addon
local module = Parrot:NewModule("ScrollAreas", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Parrot")

local Parrot_AnimationStyles = Parrot:GetModule("AnimationStyles")

local db = nil
local defaults = {
	profile = {
		areas = {},
		dbver = 0,
	}
}

local setConfigMode
local scrollAreas

local choices = {}
local rebuildChoices do
	local localizedNames = {
		["Incoming"] = L["Incoming"],
		["Outgoing"] = L["Outgoing"],
		["Notification"] = L["Notification"],
	}
	function rebuildChoices()
		wipe(choices)
		for k, v in next, scrollAreas do
			choices[k] = localizedNames[k] or k
		end
	end
end

local updateFuncs = {
	[1] = function()
		-- Copy the defaults into the db
		local function merge(dst, src)
			for k, v in next, src do
				if not dst[k] then
					if type(v) == "table" then
						dst[k] = CopyTable(v)
					else
						dst[k] = v
					end
				elseif type(v) == "table" then
					if type(dst[k]) ~= "table" then
						dst[k] = {}
					end
					merge(dst[k], v)
				end
			end
		end

		local defaultScrollAreas = {
			["Notification"] = {
				animationStyle = "Straight",
				direction = "UP;CENTER",
				stickyAnimationStyle = "Pow",
				stickyDirection = "UP;CENTER",
				size = 150,
				xOffset = 0,
				yOffset = 175,
				iconSide = "LEFT",
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
				iconSide = "LEFT",
			},
		}
		merge(db.areas, defaultScrollAreas)
	end,
	[2] = function()
		-- Translating the names was a mistake! x_x
		if db.areas[L["Incoming"]] and L["Incoming"] ~= "Incoming" then
			db.areas["Incoming"] = db.areas[L["Incoming"]]
			db.areas[L["Incoming"]] = nil
		end
		if db.areas[L["Outgoing"]] and L["Outgoing"] ~= "Outgoing" then
			db.areas["Outgoing"] = db.areas[L["Outgoing"]]
			db.areas[L["Outgoing"]] = nil
		end
		if db.areas[L["Notification"]] and L["Notification"] ~= "Notification" then
			db.areas["Notification"] = db.areas[L["Notification"]]
			db.areas[L["Notification"]] = nil
		end
	end,
}

local function updateDB()
	if not db.dbver then
		db.dbver = 0
	end
	for i = db.dbver + 1, #updateFuncs do
		updateFuncs[i]()
	end
	db.dbver = #updateFuncs
end

function module:OnProfileChanged()
	setConfigMode(false)
	db = self.db.profile
	updateDB()
	scrollAreas = db.areas

	if Parrot.options.args.scrollAreas then
		Parrot.options.args.scrollAreas = nil
		self:OnOptionsCreate()
	end
	rebuildChoices()
end

function module:OnInitialize()
	self.db = Parrot.db:RegisterNamespace("ScrollAreas", defaults)
	self:OnProfileChanged()
end

function module:OnEnable()
	setConfigMode(false)
end

function module:OnDisable()
	setConfigMode(false)
end

-- Register ConfigMode callback (http://wowpedia.org/ConfigMode)
-- luacheck: globals CONFIGMODE_CALLBACKS
CONFIGMODE_CALLBACKS = CONFIGMODE_CALLBACKS or {}
CONFIGMODE_CALLBACKS["Parrot"] = function(state)
	setConfigMode(state == "ON")
end

function Parrot:SetConfigMode(state)
	if type(state) ~= "boolean" then
		error(("Bad argument #2 to `SetConfigMode'. Expected %q, got %q."):format("boolean", type(state)), 2)
	end
	setConfigMode(state)
end

local configModeTimer
local offsetBoxes
local function hideAllOffsetBoxes()
	if not offsetBoxes then
		return
	end
	for k,v in next, offsetBoxes do
		v:Hide()
	end
	module:CancelTimer(configModeTimer)
end

local function showOffsetBox(k)
	if not offsetBoxes then
		offsetBoxes = {}
	end
	local offsetBox = offsetBoxes[k]
	if not offsetBox then
		offsetBox = CreateFrame("Button", "ParrotScrollAreasOffsetBox" .. k, UIParent)
		local midPoint = CreateFrame("Frame", "$parentMidPoint", offsetBox)
		offsetBox.midPoint = midPoint
		midPoint:SetWidth(1)
		midPoint:SetHeight(1)
		offsetBoxes[k] = offsetBox
		offsetBox:SetPoint("CENTER", midPoint, "CENTER")
		offsetBox:SetWidth(300)
		offsetBox:SetHeight(100)
		offsetBox:SetFrameStrata("MEDIUM")

		local bg = offsetBox:CreateTexture("$parentBackground", "BACKGROUND")
		bg:SetColorTexture(0.7, 0.4, 0, 0.5) -- orange
		bg:SetAllPoints(offsetBox)

		local text = offsetBox:CreateFontString("$parentText", "ARTWORK", "GameFontHighlight")
		offsetBox.text = text
		text:SetText(L["Click and drag to the position you want."])
		text:SetPoint("CENTER")
		local topText = offsetBox:CreateFontString("$parentTopText", "ARTWORK", "GameFontHighlight")
		offsetBox.topText = topText
		topText:SetText(L["Scroll area: %s"]:format(k))
		topText:SetPoint("BOTTOM", offsetBox, "TOP", 0, 5)
		local bottomText = offsetBox:CreateFontString("$parentBottomText", "ARTWORK", "GameFontHighlight")
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
	offsetBox.midPoint:ClearAllPoints()
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
	Parrot:ShowMessage(alphabet[currentAlphabet], k, kind == "sticky", r, g, b, nil, nil, nil, "Interface\\Icons\\INV_Misc_QuestionMark")
	currentAlphabet = (currentAlphabet % #alphabet) + 1
	currentColor = (currentColor + 10) % 360
end

local configModeMessages
do
	local num = 0
	function configModeMessages()
		num = num % 2 + 1
		for k in next, scrollAreas do
			test("normal", k)
		end
		if num == 2 then
			for k in next, scrollAreas do
				test("sticky", k)
			end
		end
	end
end

local configMode = false
function setConfigMode(value)
	configMode = value
	if not value then
		hideAllOffsetBoxes()
	else
		for k in next, scrollAreas do
			showOffsetBox(k)
		end
		configModeTimer = module:ScheduleRepeatingTimer(configModeMessages, 1)
		configModeMessages()
	end
end

function module:HasScrollArea(name)
	return not not scrollAreas[name]
end

function module:GetScrollArea(name)
	return scrollAreas[name]
end

function module:GetRandomScrollArea()
	local i = 0
	for k, v in next, scrollAreas do
		i = i + 1
	end
	local num = math.random(1, i)
	i = 0
	for k, v in next, scrollAreas do
		i = i + 1
		if i == num then
			return k, v
		end
	end
	return
end

function module:GetScrollAreasChoices()
	return choices
end
Parrot.GetScrollAreasChoices = module.GetScrollAreasChoices

function module:OnOptionsCreate()
	local scrollAreas_opt
	local function getName(info)
		local name = info.arg
		return name
	end
	local function setName(info, new)
		local old = info.arg
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
		choices[old] = nil
		choices[new] = new
		if new == L["New scroll area"] then
			opt.order = -110
		else
			opt.order = -100
		end
		opt.name = new
		opt.args.name.arg = new
		opt.args.remove.arg = new
		opt.args.size.arg = new
		opt.args.test.args.normal.arg[2] = new
		opt.args.test.args.sticky.arg[2] = new
		opt.args.direction.args.normal.arg[2] = new
		opt.args.direction.args.sticky.arg[2] = new
		opt.args.animationStyle.args.normal.arg[2] = new
		opt.args.animationStyle.args.sticky.arg[2] = new
		opt.args.speed.args.normal.arg[2] = new
		opt.args.speed.args.sticky.arg[2] = new
		opt.args.icon.arg = new
		opt.args.positionX.arg = new
		opt.args.positionY.arg = new
		opt.args.font.args.fontface.arg[2] = new
		opt.args.font.args.fontSizeInherit.arg[2] = new
		opt.args.font.args.fontSize.arg[2] = new
		opt.args.font.args.fontOutline.arg[2] = new
		opt.args.font.args.fontShadow.arg[2] = new
		opt.args.font.args.stickyfontface.arg[2] = new
		opt.args.font.args.stickyfontSizeInherit.arg[2] = new
		opt.args.font.args.stickyfontSize.arg[2] = new
		opt.args.font.args.stickyfontOutline.arg[2] = new
		opt.args.font.args.stickyfontShadow.arg[2] = new
		if shouldConfig then
			setConfigMode(true)
		end
		rebuildChoices()
	end
	local function getFontFace(info)
		local kind, k = info.arg[1], info.arg[2]
		local font = scrollAreas[k][kind == "normal" and "font" or "stickyFont"]
		if font == nil then
			return -1
		end
		for i, v in next, Parrot.fontValues do
			if v == font then return i end
		end
	end
	local function setFontFace(info, value)
		local kind, k = info.arg[1], info.arg[2]
		if value == -1 then
			scrollAreas[k][kind == "normal" and "font" or "stickyFont"] = nil
		else
			scrollAreas[k][kind == "normal" and "font" or "stickyFont"] = Parrot.fontValues[value]
		end
		if not configMode then
			test(kind, k)
		end
	end
	local function getFontSize(info)
		local kind, k = info.arg[1], info.arg[2]
		return scrollAreas[k][kind == "normal" and "fontSize" or "stickyFontSize"]
	end
	local function setFontSize(info, value)
		local kind, k = info.arg[1], info.arg[2]
		scrollAreas[k][kind == "normal" and "fontSize" or "stickyFontSize"] = value
		if not configMode then
			test(kind, k)
		end
	end
	local function getFontSizeInherit(info)
		local kind, k = info.arg[1], info.arg[2]
		return scrollAreas[k][kind == "normal" and "fontSize" or "stickyFontSize"] == nil
	end
	local function setFontSizeInherit(info, value)
		local kind, k = info.arg[1], info.arg[2]
		if value then
			scrollAreas[k][kind == "normal" and "fontSize" or "stickyFontSize"] = nil
		else
			scrollAreas[k][kind == "normal" and "fontSize" or "stickyFontSize"] = 18
		end
		if not configMode then
			test(kind, k)
		end
	end
	local function getFontOutline(info)
		local kind, k = info.arg[1], info.arg[2]
		local outline = scrollAreas[k][kind == "normal" and "fontOutline" or "stickyFontOutline"]
		if outline == nil then
			return L["Inherit"]
		else
			return outline
		end
	end
	local function setFontOutline(info, value)
		local kind, k = info.arg[1], info.arg[2]
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
		MONOCHROME = L["Monochrome"],
		OUTLINE = L["Thin"],
		["OUTLINE,MONOCHROME"] = L["Thin, Monochrome"],
		THICKOUTLINE = L["Thick"],
		[L["Inherit"]] = L["Inherit"],
	}
	local function getFontShadow(info)
		local kind, k = info.arg[1], info.arg[2]
		local value = scrollAreas[k][kind == "normal" and "fontShadow" or "stickyFontShadow"]
		if value == nil then
			return L["Inherit"]
		else
			return tostring(value)
		end
	end
	local function setFontShadow(info, value)
		local kind, k = info.arg[1], info.arg[2]
		if value == L["Inherit"] then
			value = nil
		else
			value = value == "true"
		end
		scrollAreas[k][kind == "normal" and "fontShadow" or "stickyFontShadow"] = value
		if not configMode then
			test(kind, k)
		end
	end
	local fontShadowChoices = {
		["false"] = DISABLE,
		["true"] = ENABLE,
		[L["Inherit"]] = L["Inherit"],
	}
	local function getAnimationStyle(info)
		local kind, k = info.arg[1], info.arg[2]
		return scrollAreas[k][kind == "normal" and "animationStyle" or "stickyAnimationStyle"]
	end
	local function setAnimationStyle(info, value)
		local kind, k = info.arg[1], info.arg[2]
		scrollAreas[k][kind == "normal" and "animationStyle" or "stickyAnimationStyle"] = value
		local opt = scrollAreas_opt.args[tostring(scrollAreas[k])]
		local directionValues = Parrot_AnimationStyles:GetAnimationStyleDirectionChoices(value)
		opt.args.direction.args[kind].values = directionValues
		if not directionValues[scrollAreas[k][kind == "normal" and "direction" or "stickyDirection"]] then
			scrollAreas[k][kind == "normal" and "direction" or "stickyDirection"] = Parrot_AnimationStyles:GetAnimationStyleDefaultDirection(value)
		end
		if not configMode then
			test(kind, k)
			test(kind, k)
			test(kind, k)
		end
	end
	local function getSpeed(info)
		local kind, k = info.arg[1], info.arg[2]
		return scrollAreas[k][kind == "normal" and "speed" or "stickySpeed"] or 3
	end
	local function setSpeed(info, value)
		local kind, k = info.arg[1], info.arg[2]
		if value == 3 then
			value = nil
		end
		scrollAreas[k][kind == "normal" and "speed" or "stickySpeed"] = value
		if not configMode then
			test(kind, k)
		end
	end
	local function getDirection(info)
		local kind, k = info.arg[1], info.arg[2]
		return scrollAreas[k][kind == "normal" and "direction" or "stickyDirection"] or Parrot_AnimationStyles:GetAnimationStyleDefaultDirection(scrollAreas[k][kind == "normal" and "animationStyle" or "stickyAnimationStyle"])
	end
	local function setDirection(info, value)
		local kind, k = info.arg[1], info.arg[2]
		if value == Parrot_AnimationStyles:GetAnimationStyleDefaultDirection(scrollAreas[k][kind == "normal" and "animationStyle" or "stickyAnimationStyle"]) then
			value = nil
		end
		scrollAreas[k][kind == "normal" and "direction" or "stickyDirection"] = value
		if not configMode then
			test(kind, k)
			test(kind, k)
			test(kind, k)
		end
	end
	local function directionDisabled(info)
		local kind, k = info.arg[1], info.arg[2]
		return not Parrot_AnimationStyles:GetAnimationStyleDirectionChoices(scrollAreas[k][kind == "normal" and "animationStyle" or "stickyAnimationStyle"])
	end
	local function getPositionX(info)
		return scrollAreas[info.arg].xOffset
	end
	local function setPositionX(info, value)
		local k = info.arg
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
	local function getPositionY(info)
		return scrollAreas[info.arg].yOffset
	end
	local function setPositionY(info, value)
		local k = info.arg
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
	local function getSize(info)
		return scrollAreas[info.arg].size
	end
	local function setSize(info, value)
		local k = info.arg
		scrollAreas[k].size = value
		if not configMode then
			test("normal", k)
			test("sticky", k)
		end
	end
	local function remove(info)
		local k = info.arg
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
	local function disableRemove(info)
		return not next(scrollAreas, next(scrollAreas))
	end
	local iconSideChoices = {
		LEFT = L["Left"],
		RIGHT = L["Right"],
		-- CENTER = L["Center of screen"],
		-- EDGE = L["Edge of screen"],
		DISABLE = L["Disable"],
	}
	local function getIconSide(info)
		local value = scrollAreas[info.arg].iconSide
		return iconSideChoices[value] and value or "LEFT"
	end
	local function setIconSide(info, value)
		local k = info.arg
		scrollAreas[k].iconSide = value
		if not configMode then
			test("normal", k)
			test("sticky", k)
		end
	end

	local function makeOption(k)
		local v = scrollAreas[k]
		local opt = {
			type = 'group',
			name = choices[k],
			desc = L["Options for this scroll area."],
			args = {
				name = {
					type = 'input',
					name = L["Name"],
					desc = L["Name of the scroll area."],
					get = getName,
					set = setName,
					usage = L["<Name>"],
					arg = k,
					order = 1,
				},
				remove = {
					type = 'execute',
					name = L["Remove"],
					desc = L["Remove this scroll area."],
					func = remove,
					disabled = disableRemove,
					arg = k,
					order = -1,
					confirm = true,
					confirmText = L["Are you sure?"],
				},
				icon = {
					type = 'select',
					name = L["Icon side"],
					desc = L["Set the icon side for this scroll area or whether to disable icons entirely."],
					get = getIconSide,
					set = setIconSide,
					values = iconSideChoices,
					arg = k,
				},
				test = {
					type = 'group',
					inline = true,
					name = L["Test"],
					desc = L["Send a test message through this scroll area."],
					args = {
						normal = {
							type = 'execute',
							name = L["Normal"],
							desc = L["Send a normal test message."],
							func = function(info) test(info.arg[1], info.arg[2]) end,
							arg = {"normal", k},
						},
						sticky = {
							type = 'execute',
							name = L["Sticky"],
							desc = L["Send a sticky test message."],
							func = function(info) test(info.arg[1], info.arg[2]) end,
							arg = {"sticky", k},
						},
					},
					disabled = function() return configMode end
				},
				direction = {
					type = 'group',
					inline = true,
					name = L["Direction"],
					desc = L["Which direction the animations should follow."],
					args = {
						normal = {
							type = 'select',
							name = L["Normal"],
							desc = L["Direction for normal texts."],
							get = getDirection,
							set = setDirection,
							disabled = directionDisabled,
							values = Parrot_AnimationStyles:GetAnimationStyleDirectionChoices(scrollAreas[k].animationStyle) or {},
							arg = {"normal", k},
						},
						sticky = {
							type = 'select',
							name = L["Sticky"],
							desc = L["Direction for sticky texts."],
							get = getDirection,
							set = setDirection,
							disabled = directionDisabled,
							values = Parrot_AnimationStyles:GetAnimationStyleDirectionChoices(scrollAreas[k].stickyAnimationStyle) or {},
							arg = {"sticky", k},
						},
					}
				},
				animationStyle = {
					type = 'group',
					inline = true,
					name = L["Animation style"],
					desc = L["Which animation style to use."],
					args = {
						normal = {
							type = 'select',
							name = L["Normal"],
							desc = L["Animation style for normal texts."],
							get = getAnimationStyle,
							set = setAnimationStyle,
							values = Parrot_AnimationStyles:GetAnimationStylesChoices(),
							arg = {"normal", k},
						},
						sticky = {
							type = 'select',
							name = L["Sticky"],
							desc = L["Animation style for sticky texts."],
							get = getAnimationStyle,
							set = setAnimationStyle,
							values = Parrot_AnimationStyles:GetAnimationStylesChoices(),
							arg = {"sticky", k},
						},
					}
				},
				positionX = {
					type = 'range',
					name = L["Position: horizontal"],
					desc = L["The position of the box across the screen"],
					get = getPositionX,
					set = setPositionX,
					min = math.floor(-GetScreenWidth()/GetScreenHeight()*768 / 0.64 / 2 / 10) * 10,
					max = math.ceil(GetScreenWidth()/GetScreenHeight()*768 / 0.64 / 2 / 10) * 10,
					step = 1,
					bigStep = 10,
					arg = k,
				},
				positionY = {
					type = 'range',
					name = L["Position: vertical"],
					desc = L["The position of the box up-and-down the screen"],
					get = getPositionY,
					set = setPositionY,
					min = math.floor(-768 / 0.64 / 2 / 10) * 10,
					max = math.ceil(768 / 0.64 / 2 / 10) * 10,
					step = 1,
					bigStep = 10,
					arg = k,
				},
				size = {
					type = 'range',
					name = L["Size"],
					desc = L["How large of an area to scroll."],
					get = getSize,
					set = setSize,
					min = 50,
					max = 800,
					step = 1,
					bigStep = 10,
					arg = k,
				},
				speed = {
					type = 'group',
					inline = true,
					name = L["Scrolling speed"],
					desc = L["How fast the text scrolls by."],
					args = {
						normal = {
							type = 'range',
							name = L["Normal"],
							desc = L["Seconds for the text to complete the whole cycle, i.e. larger numbers means slower."],
							min = 1,
							max = 20,
							step = 0.1,
							bigStep = 1,
							get = getSpeed,
							set = setSpeed,
							arg = {"normal", k},
						},
						sticky = {
							type = 'range',
							name = L["Sticky"],
							desc = L["Seconds for the text to complete the whole cycle, i.e. larger numbers means slower."],
							min = 1,
							max = 20,
							step = 0.1,
							bigStep = 1,
							get = getSpeed,
							set = setSpeed,
							arg = {"sticky", k},
						},
					}
				},
				font = {
					type = 'group',
					inline = true,
					name = L["Custom font"],
					args = {
						fontface = {
							type = 'select',
							name = L["Normal font face"],
							values = Parrot.fontWithInheritValues,
							get = getFontFace,
							set = setFontFace,
							itemControl = "DDI-Font",
							arg = {"normal", k},
							order = 1,
						},
						fontSizeInherit = {
							type = 'toggle',
							name = L["Normal inherit font size"],
							get = getFontSizeInherit,
							set = setFontSizeInherit,
							arg = {"normal", k},
							order = 2,
						},
						fontSize = {
							type = 'range',
							name = L["Normal font size"],
							min = 12,
							max = 30,
							step = 1,
							get = getFontSize,
							set = setFontSize,
							disabled = getFontSizeInherit,
							arg = {"normal", k},
							order = 3,
						},
						fontOutline = {
							type = 'select',
							name = L["Normal font outline"],
							get = getFontOutline,
							set = setFontOutline,
							values = fontOutlineChoices,
							arg = {"normal", k},
							order = 4,
						},
						fontShadow = {
							type = 'select',
							name = L["Normal font shadow"],
							get = getFontShadow,
							set = setFontShadow,
							values = fontShadowChoices,
							arg = {"normal", k},
							order = 5,
						},
						sep = {
							type = "description",
							name = "",
							order = 6,
						},
						stickyfontface = {
							type = 'select',
							name = L["Sticky font face"],
							values = Parrot.fontWithInheritValues,
							get = getFontFace,
							set = setFontFace,
							itemControl = "DDI-Font",
							arg = {"sticky", k},
							order = 7,
						},
						stickyfontSizeInherit = {
							type = 'toggle',
							name = L["Sticky inherit font size"],
							get = getFontSizeInherit,
							set = setFontSizeInherit,
							arg = {"sticky", k},
							order = 8,
						},
						stickyfontSize = {
							type = 'range',
							name = L["Sticky font size"],
							min = 12,
							max = 30,
							step = 1,
							get = getFontSize,
							set = setFontSize,
							disabled = getFontSizeInherit,
							arg = {"sticky", k},
							order = 9,
						},
						stickyfontOutline = {
							type = 'select',
							name = L["Sticky font outline"],
							get = getFontOutline,
							set = setFontOutline,
							values = fontOutlineChoices,
							arg = {"sticky", k},
							order = 10,
						},
						stickyfontShadow = {
							type = 'select',
							name = L["Sticky font shadow"],
							get = getFontShadow,
							set = setFontShadow,
							values = fontShadowChoices,
							arg = {"sticky", k},
							order = 11,
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
			return not self:IsEnabled()
		end,
		order = 5,
		args = {
			config = {
				type = 'toggle',
				name = L["Configuration mode"],
				desc = L["Enter configuration mode, allowing you to move around the scroll areas and see them in action."],
				get = function()
					return configMode
				end,
				set = function(info, value) setConfigMode(value) end,
			},
			new = {
				type = 'execute',
				name = L["New scroll area"],
				desc = L["Add a new scroll area."],
				func = function()
					local shouldConfig = configMode
					if shouldConfig then
						setConfigMode(false)
					end
					scrollAreas[L["New scroll area"]] = {
						animationStyle = "Straight",
						direction = Parrot_AnimationStyles:GetAnimationStyleDefaultDirection("Straight"),
						stickyAnimationStyle = "Pow",
						stickyDirection = Parrot_AnimationStyles:GetAnimationStyleDefaultDirection("Pow"),
						size = 150,
						xOffset = 0,
						yOffset = 0,
					}
					rebuildChoices()
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

	for k, v in next, scrollAreas do
		makeOption(k)
		if k == L["New scroll area"] then
			scrollAreas_opt.args[tostring(v)].order = -110
		end
	end
end
