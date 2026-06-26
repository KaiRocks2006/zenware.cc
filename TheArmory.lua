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
	Sections.Visuals.Player = Sections.Visuals:AddGroupbox('Player')
	Sections.Visuals.NPC = Sections.Visuals:AddGroupbox('NPC')
	Sections.Visuals.World = Sections.Visuals:AddGroupbox('World')
end

return this