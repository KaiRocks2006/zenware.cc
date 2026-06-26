local this = {}

function this.Load(Context)
	local Tabs = {
		Main = Context.Window:AddTab('Visuals'),
		Visuals = Context.Window:AddTab('Visuals'),
		['UI Settings'] = Context.Window:AddTab('UI Settings'),
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