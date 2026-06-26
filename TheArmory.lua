local this = {}

function this.Load(Context)
	local Tabs = {
		Main = Context.Window:AddTab('Main'),
		Visuals = Context.Window:AddTab('Visuals'),
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