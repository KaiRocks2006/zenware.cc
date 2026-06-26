local this = {}

local Window = nil
local Library = nil

local Tabs = {
	Visuals = nil
}

local SubTabs = {
	Visuals = {
		TabBox = nil,
		Player = nil,
		NPC = nil,
		World = nil,
	}
}

function this.Start(Context)
	Window = Context.Window
	Library = Context.Library

	Tabs.Visuals = Window:AddTab('Visuals')
	SubTabs.Visuals.TabBox = Tabs.Visuals:AddTabbox()
	SubTabs.Visuals.Player = SubTabs.Visuals.TabBox:AddTab('Player')
	SubTabs.Visuals.NPC = SubTabs.Visuals.TabBox:AddTab('NPC')
	SubTabs.Visuals.World = SubTabs.Visuals.TabBox:AddTab('World')
end

return this