local this = {}

local Window = nil
local Library = nil

local Tabs = {
	Visuals = nil
}

local Sections = {
	Visuals = {
		Player = nil,
		NPC = nil,
		World = nil,
	}
}

function this.Load(Context)
	Window = Context.Window
	Library = Context.Library

	Tabs.Visuals = Window:AddTab('Visuals')
	Sections.Visuals.Player = Tabs.Visuals:AddLeftGroupbox('Player')
	Sections.Visuals.NPC = Tabs.Visuals:AddLeftGroupbox('NPC')
	Sections.Visuals.World = Tabs.Visuals:AddRightGroupbox('World')
end

return this