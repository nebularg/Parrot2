local Parrot, self = Parrot, Parrot

local ldbdata = {
	type = "launcher", 
	icon = "Interface\\Icons\\Spell_Nature_ForceOfNature", 
	OnClick = function(_, msg)
			if msg == "LeftButton" then
				self:OpenConfigMenu()
--			elseif msg == "RightButton" then
			end
		end,
	label = "Parrot",
}

self.obj = LibStub("LibDataBroker-1.1"):NewDataObject("Parrot", ldbdata)
