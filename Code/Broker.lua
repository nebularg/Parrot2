local Parrot = _G.Parrot
local L = LibStub("AceLocale-3.0"):GetLocale("Parrot")

local ldbdata = {
	type = "launcher",
	icon = "Interface\\Icons\\Spell_Nature_ForceOfNature",
	OnClick = function(_, button)
		if button == "LeftButton" then
			Parrot:ShowConfig()
		end
	end,
	label = L["Parrot"],
}

LibStub("LibDataBroker-1.1"):NewDataObject("Parrot", ldbdata)
