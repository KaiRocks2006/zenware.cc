local this = {}

local Window = nil
local Library = nil



function this.Load(Context)
	Window = Context.Window
	Library = Context.Library

	local Tabs = {
		Main = Window:AddTab('Visuals'),
		Visuals = Window:AddTab('Visuals'),
		['UI Settings'] = Window:AddTab('UI Settings'),
	}

	local Sections = {
		Visuals = {
			Player = Tabs.Visuals:AddLeftGroupbox('Player'),
			NPC = Tabs.Visuals:AddLeftGroupbox('NPC'),
			World = Tabs.Visuals:AddRightGroupbox('World'),
		}
	}
end

return this