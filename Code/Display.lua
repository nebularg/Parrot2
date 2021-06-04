local _, ns = ...
local Parrot = ns.addon
if not Parrot then return end

local module = Parrot:NewModule("Display")
local L = LibStub("AceLocale-3.0"):GetLocale("Parrot")

local Parrot_AnimationStyles
local Parrot_Suppressions
local Parrot_ScrollAreas

local LibSharedMedia = LibStub("LibSharedMedia-3.0")
local DEFAULT_FONT_NAME = LibSharedMedia:GetDefault("font")

local newList, del = Parrot.newList, Parrot.del

local ParrotFrame = CreateFrame("Frame", "ParrotFrame", UIParent)
ParrotFrame:Hide()
ParrotFrame:SetFrameStrata("HIGH")
ParrotFrame:SetToplevel(true)
ParrotFrame:SetPoint("CENTER")
ParrotFrame:SetWidth(0.0001)
ParrotFrame:SetHeight(0.0001)
local Display_Update

local db
local defaults = {
	profile = {
		alpha = 1,
		iconAlpha = 1,
		iconsEnabled = true,
		font = DEFAULT_FONT_NAME, --"Friz Quadrata TT",
		fontSize = 18,
		fontOutline = "THICKOUTLINE",
		fontShadow = true,
		stickyFont = DEFAULT_FONT_NAME, --"Friz Quadrata TT",
		stickyFontSize = 26,
		stickyFontOutline = "THICKOUTLINE",
		stickyFontShadow = true,
	},
}

function module:OnProfileChanged()
	db = self.db.profile
end

function module:OnInitialize()
	self.db = Parrot.db:RegisterNamespace("Display", defaults)
	db = self.db.profile

	Parrot_AnimationStyles = Parrot:GetModule("AnimationStyles")
	Parrot_Suppressions = Parrot:GetModule("Suppressions")
	Parrot_ScrollAreas = Parrot:GetModule("ScrollAreas")
end

local function setOption(info, value)
	local name = info[#info]
	db[name] = value
end
local function getOption(info)
	local name = info[#info]
	return db[name]
end

local function getFontFace(info)
	local font = db[info[#info]]
	if font == nil then
		return -1
	end
	for i, v in next, Parrot.fontValues do
		if v == font then return i end
	end
	return font
end
local function setFontFace(info, value)
	if value == -1 then
		db[info[#info]] = nil
	else
		db[info[#info]] = Parrot.fontValues[value]
	end
end

function module:OnOptionsCreate()
	local outlineChoices = {
		NONE = L["None"],
		MONOCHROME = L["Monochrome"],
		OUTLINE = L["Thin"],
		["OUTLINE,MONOCHROME"] = L["Thin, Monochrome"],
		THICKOUTLINE = L["Thick"],
	}

	Parrot.options.args.general.args.alpha = {
		type = "range",
		name = L["Text transparency"],
		desc = L["How opaque/transparent the text should be."],
		min = 0.25,
		max = 1,
		step = 0.01,
		bigStep = 0.05,
		isPercent = true,
		get = getOption,
		set = setOption,
		order = 1,
	}
	Parrot.options.args.general.args.iconAlpha = {
		type = "range",
		name = L["Icon transparency"],
		desc = L["How opaque/transparent icons should be."],
		min = 0.25,
		max = 1,
		step = 0.01,
		bigStep = 0.05,
		isPercent = true,
		get = getOption,
		set = setOption,
		order = 2,
	}
	Parrot.options.args.general.args.iconsEnabled = {
		type = "toggle",
		name = L["Enable icons"],
		desc = L["Set whether icons should be enabled or disabled altogether."],
		get = getOption,
		set = setOption,
		order = 3,
	}
	Parrot.options.args.general.args.font = {
		type = "group",
		inline = true,
		name = "", -- L["Master font settings"],
		get = getOption,
		set = setOption,
		order = 4,
		args = {
			font = {
				type = "select",
				name = L["Normal font face"],
				values = Parrot.fontValues,
				get = getFontFace,
				set = setFontFace,
				itemControl = "DDI-Font",
			},
			fontSize = {
				type = "range",
				name = L["Normal font size"],
				min = 6,
				max = 32,
				step = 1,
			},
			fontOutline = {
				type = "select",
				name = L["Normal font outline"],
				values = outlineChoices,
			},
			fontShadow = {
				type = "toggle",
				name = L["Normal font shadow"],
			},
			stickyFont = {
				type = "select",
				name = L["Sticky font face"],
				values = Parrot.fontValues,
				get = getFontFace,
				set = setFontFace,
				itemControl = "DDI-Font",
			},
			stickyFontSize = {
				type = "range",
				name = L["Sticky font size"],
				min = 6,
				max = 32,
				step = 1,
			},
			stickyFontOutline = {
				type = "select",
				name = L["Sticky font outline"],
				values = outlineChoices,
			},
			stickyFontShadow = {
				type = "toggle",
				name = L["Sticky font shadow"],
			},
		}
	}
end

local freeFrames = {}
local wildFrames = {}
local frame_num = 0
local frameIDs = {}
local freeTextures = {}
local texture_num = 0
local freeFontStrings = {}
local fontString_num = 0

--[[----------------------------------------------------------------------------------
Arguments:
	string - the text you wish to show.
	[optional] string - the scroll area to show in. Default: "Notification"
	[optional] boolean - whether to show in the sticky-style, e.g. crits. Default: false
	[optional] number - [0, 1] the red part of the color. Default: 1
	[optional] number - [0, 1] the green part of the color. Default: 1
	[optional] number - [0, 1] the blue part of the color. Default: 1
	[optional] string - the font to use (as determined by SharedMedia-1.0). Defaults to the scroll area's setting.
	[optional] number - the font size to use. Defaults to the scroll area's setting.
	[optional] string - the font outline to use. Defaults to the scroll area's setting.
	[optional] string - the icon texture to show alongside the message.
Notes:
	* See :GetScrollAreasValidate() for a validation list of scroll areas.
	* Messages are suppressed if the user has set a specific suppression matching the text.
Example:
	Parrot:ShowMessage("Hello, world!", "Notification", false, 0.5, 0.5, 1)
------------------------------------------------------------------------------------]]
function module:ShowMessage(text, area, sticky, r, g, b, font, fontSize, outline, icon)
	if not module:IsEnabled() then return end
	if Parrot_Suppressions:ShouldSuppress(text) then return end

	if not Parrot_ScrollAreas:HasScrollArea(area) then
		if Parrot_ScrollAreas:HasScrollArea("Notification") then
			area = "Notification"
		else
			area = Parrot_ScrollAreas:GetRandomScrollArea()
			if not area then
				return
			end
		end
	end

	local scrollArea = Parrot_ScrollAreas:GetScrollArea(area)
	local shadow = nil
	if not sticky then
		if not font then
			font = scrollArea.font or db.font
		end
		if not fontSize then
			fontSize = scrollArea.fontSize or db.fontSize
		end
		if not outline then
			outline = scrollArea.fontOutline or db.fontOutline
		end
		shadow = scrollArea.fontShadow
		if shadow == nil then
			shadow = db.fontShadow
		end
	else
		if not font then
			font = scrollArea.stickyFont or db.stickyFont
		end
		if not fontSize then
			fontSize = scrollArea.stickyFontSize or db.stickyFontSize
		end
		if not outline then
			outline = scrollArea.stickyFontOutline or db.stickyFontOutline
		end
		shadow = scrollArea.stickyFontShadow
		if shadow == nil then
			shadow = db.stickyFontShadow
		end
	end
	if outline == "NONE" then
		outline = ""
	end

	local frame = next(freeFrames)
	if frame then
		frame:ClearAllPoints()
		freeFrames[frame] = nil
	else
		frame_num = frame_num + 1
		frame = CreateFrame("Frame", "ParrotFrameFrame" .. frame_num, ParrotFrame)
	end

	local fs = next(freeFontStrings)
	if fs then
		fs:ClearAllPoints()
		freeFontStrings[fs] = nil
		fs:SetParent(frame)
	else
		fontString_num = fontString_num + 1
		fs = frame:CreateFontString("ParrotFrameFontString" .. fontString_num, "ARTWORK", "SystemFont_Shadow_Small")
	end
	fs:SetFont(LibSharedMedia:Fetch("font", font), fontSize, outline)
	if shadow then
		fs:SetShadowColor(0, 0, 0, 1)
	else
		fs:SetShadowColor(0, 0, 0, 0)
	end
	frame.fs = fs

	local texture
	if icon and db.iconsEnabled and scrollArea.iconSide ~= "DISABLE" then
		if type(icon) == "number" or icon ~= "Interface\\Icons\\Temp" then
			texture = next(freeTextures)
			if texture then
				texture:Show()
				texture:ClearAllPoints()
				freeTextures[texture] = nil
				texture:SetParent(frame)
			else
				texture_num = texture_num + 1
				texture = frame:CreateTexture("ParrotFrameTexture" .. texture_num, "OVERLAY")
			end
			texture:SetTexture(icon)
			texture:SetTexCoord(0.07, 0.93, 0.07, 0.93) -- zoom the icon
			texture:SetWidth(fontSize)
			texture:SetHeight(fontSize)
			frame.icon = texture
		end
	end

	if texture then
		if scrollArea.iconSide == "RIGHT" then
			texture:SetPoint("LEFT", fs, "RIGHT", 3, 0)
			fs:SetPoint("LEFT", frame, "LEFT")
		else -- scrollArea.iconSide == "LEFT"
			texture:SetPoint("RIGHT", fs, "LEFT", -3, 0)
			fs:SetPoint("RIGHT", frame, "RIGHT")
		end
	else
		fs:SetPoint("LEFT", frame, "LEFT")
	end

	if r and g and b then
		fs:SetTextColor(r, g, b)
	else
		fs:SetTextColor(1, 1, 1)
	end
	fs:SetText(text)
	frame.start = GetTime()
	frame.scrollArea = scrollArea
	frame.sticky = sticky

	if sticky then
		frame:SetFrameLevel(1)
	else
		frame:SetFrameLevel(0)
	end

	local animationStyle
	if sticky then
		animationStyle = scrollArea.stickyAnimationStyle
	else
		animationStyle = scrollArea.animationStyle
	end
	local aniStyle = Parrot_AnimationStyles:GetAnimationStyle(animationStyle)
	if not next(wildFrames) then
		ParrotFrame:Show()
	end
	local wildFrames_scrollArea = wildFrames[scrollArea]
	if not wildFrames_scrollArea then
		wildFrames_scrollArea = newList()
		wildFrames[scrollArea] = wildFrames_scrollArea
	end
	local wildFrames_scrollArea_aniStyle = wildFrames_scrollArea[aniStyle]
	if not wildFrames_scrollArea_aniStyle then
		wildFrames_scrollArea_aniStyle = newList()
		wildFrames_scrollArea[aniStyle] = wildFrames_scrollArea_aniStyle
	end
	wildFrames_scrollArea_aniStyle.length = scrollArea[sticky and "stickySpeed" or "speed"] or 3
	local frameIDs_scrollArea = frameIDs[scrollArea]
	if not frameIDs_scrollArea then
		frameIDs_scrollArea = newList()
		frameIDs[scrollArea] = frameIDs_scrollArea
	end
	local frameIDs_scrollArea_aniStyle = frameIDs_scrollArea[aniStyle]
	if not frameIDs_scrollArea_aniStyle then
		frameIDs_scrollArea_aniStyle = 1
	else
		frameIDs_scrollArea_aniStyle = frameIDs_scrollArea_aniStyle + 1
	end
	frameIDs_scrollArea[aniStyle] = frameIDs_scrollArea_aniStyle
	frame.id = frameIDs_scrollArea_aniStyle

	table.insert(wildFrames_scrollArea_aniStyle, 1, frame)
	fs:Show()
	frame:Show()
	frame.font, frame.fontSize, frame.fontOutline = fs:GetFont()
	local init = aniStyle.init
	if init then
		init(frame, scrollArea.xOffset, scrollArea.yOffset, scrollArea.size, scrollArea[sticky and "stickyDirection" or "direction"] or aniStyle.defaultDirection, frameIDs_scrollArea_aniStyle)
	end
	fs:SetAlpha(db.alpha)
	if texture then
		texture:SetAlpha(db.iconAlpha)
	end
	Display_Update()
end
Parrot.ShowMessage = module.ShowMessage

local function isOverlapping(alpha, bravo)
	if alpha:GetLeft() <= bravo:GetRight() and bravo:GetLeft() <= alpha:GetRight() and alpha:GetBottom() <= bravo:GetTop() and bravo:GetBottom() <= alpha:GetTop() then
		return true
	end
end

function Display_Update()
	local now = GetTime()
	for scrollArea, u in next, wildFrames do
		for animationStyle, t in next, u do
			local t_len = #t
			local lastFrame = newList()
			for i, frame in ipairs(t) do
				local start, length = frame.start, t.length
				if start + length <= now then
					for j = i, t_len do
						local f = t[j]
						local cleanup = animationStyle.cleanup
						if cleanup then
							cleanup(f, scrollArea.xOffset, scrollArea.yOffset, scrollArea.size, scrollArea[f.sticky and "stickyDirection" or "direction"] or animationStyle.defaultDirection, f.id)
						end
						f:Hide()
						t[j] = nil
						freeFrames[f] = true
						local fs = f.fs
						fs:Hide()
						fs:SetParent(ParrotFrame)
						freeFontStrings[fs] = true
						local icon = f.icon
						f.icon = nil
						if icon then
							freeTextures[icon] = true
							icon:Hide()
							icon:SetTexture(nil)
							icon:ClearAllPoints()
							icon:SetParent(ParrotFrame)
						end
					end
					break
				end
				local percent = (now - start) / length
				if percent >= 0.8 then
					local alpha = (1-percent) * 5
					frame.fs:SetAlpha(alpha * db.alpha)
					if frame.icon then
						frame.icon:SetAlpha(alpha * db.iconAlpha)
					end
				end

				frame:ClearAllPoints()
				animationStyle.func(frame, scrollArea.xOffset, scrollArea.yOffset, scrollArea.size, percent, scrollArea[frame.sticky and "stickyDirection" or "direction"] or animationStyle.defaultDirection, i, t_len, frame.id)
				frame:SetWidth(frame.fs:GetWidth() + (frame.icon and (frame.icon:GetWidth() + 3) or 0))
				frame:SetHeight(math.max(frame.fs:GetHeight(), frame.icon and frame.icon:GetHeight() or 0))

				if animationStyle.overlap then
					for h = #lastFrame, 1, -1 do
						if isOverlapping(lastFrame[h], frame) then
							local minimum = percent
							local maximum = 1
							local current = (percent + maximum) / 2
							while maximum - minimum > 0.01 do
								animationStyle.func(frame, scrollArea.xOffset, scrollArea.yOffset, scrollArea.size, current, scrollArea[frame.sticky and "stickyDirection" or "direction"] or animationStyle.defaultDirection, i, t_len, frame.id)
								frame:SetWidth(frame.fs:GetWidth() + (frame.icon and (frame.icon:GetWidth() + 3) or 0))
								frame:SetHeight(math.max(frame.fs:GetHeight(), frame.icon and frame.icon:GetHeight() or 0))
								if isOverlapping(lastFrame[h], frame) then
									minimum = current
								else
									maximum = current
								end
								current = (maximum + minimum) / 2
							end
							current = current + 0.01
							frame.start = -current * length + now
							animationStyle.func(frame, scrollArea.xOffset, scrollArea.yOffset, scrollArea.size, current, scrollArea[frame.sticky and "stickyDirection" or "direction"] or animationStyle.defaultDirection, i, t_len, frame.id)
							frame:SetWidth(frame.fs:GetWidth() + (frame.icon and (frame.icon:GetWidth() + 3) or 0))
							frame:SetHeight(math.max(frame.fs:GetHeight(), frame.icon and frame.icon:GetHeight() or 0))
							for j = i+1, t_len do
								local v = t[j]
								if v.start > frame.start then
									v.start = frame.start
								end
							end
						end
					end
				end
				lastFrame[#lastFrame+1] = frame
			end
			lastFrame = del(lastFrame)
			if not t[1] then
				u[animationStyle] = del(t)
			end
		end
		if not next(u) then
			wildFrames[scrollArea] = del(u)
		end
	end
	if not next(wildFrames) then
		ParrotFrame:Hide()
	end
end
ParrotFrame:SetScript("OnUpdate", Display_Update)

local flasher = nil
local function makeflasher()
	flasher = CreateFrame("Frame", "ParrotFlash", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	flasher:SetFrameStrata("BACKGROUND")
	flasher:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",})
	flasher:SetAllPoints( UIParent)
	flasher:SetScript("OnShow", function (self)
		self.elapsed = 0
		self:SetAlpha(0)
	end)
	flasher:SetScript("OnUpdate", function (self, elapsed)
		elapsed = self.elapsed + elapsed
		if elapsed >= 1 then
			self:Hide()
			self:SetAlpha(0)
			return
		end
		local alpha = 1 - math.abs(elapsed - 0.5)
		self:SetAlpha(alpha * 0.7)
		self.elapsed = elapsed
	end)
	flasher:Hide()
end

function module:Flash(r, g, b)
	if not flasher then makeflasher() end
	flasher:SetBackdropColor(r, g, b, 255)
	flasher:Show()
end
Parrot.Flash = module.Flash
