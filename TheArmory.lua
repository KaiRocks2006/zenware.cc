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

local Groupboxes = {
	Player = {},
	NPC = {},
	World = {}
}

function this.Start(Context)
	Window = Context.Window
	Library = Context.Library

	-- Main tab
	Tabs.Visuals = Window:AddTab('Visuals')

	-- Subtabs
	SubTabs.Visuals.TabBox = Tabs.Visuals:AddRightTabbox()

	SubTabs.Visuals.Player = SubTabs.Visuals.TabBox:AddTab('Player')
	SubTabs.Visuals.NPC = SubTabs.Visuals.TabBox:AddTab('NPC')
	SubTabs.Visuals.World = SubTabs.Visuals.TabBox:AddTab('World')

	----------------------------------------------------------------
	-- PLAYER
	----------------------------------------------------------------

	Groupboxes.Player.Main =
		SubTabs.Visuals.Player:AddLeftGroupbox('Player ESP')

	Groupboxes.Player.Flags =
		SubTabs.Visuals.Player:AddRightGroupbox('Flags')

	Groupboxes.Player.Main:AddToggle('PlayerESP', {
		Text = 'Enable',
		Default = false
	})

	Groupboxes.Player.Main:AddToggle('PlayerBox', {
		Text = 'Boxes',
		Default = true
	})

	Groupboxes.Player.Main:AddToggle('PlayerSkeleton', {
		Text = 'Skeleton',
		Default = false
	})

	Groupboxes.Player.Main:AddToggle('PlayerTracers', {
		Text = 'Tracers',
		Default = false
	})

	Groupboxes.Player.Main:AddToggle('PlayerChams', {
		Text = 'Chams',
		Default = false
	})

	Groupboxes.Player.Flags:AddToggle('PlayerNames', {
		Text = 'Names',
		Default = true
	})

	Groupboxes.Player.Flags:AddToggle('PlayerDistance', {
		Text = 'Distance',
		Default = true
	})

	Groupboxes.Player.Flags:AddToggle('PlayerHealth', {
		Text = 'Health',
		Default = true
	})

	----------------------------------------------------------------
	-- NPC
	----------------------------------------------------------------

	Groupboxes.NPC.Main =
		SubTabs.Visuals.NPC:AddLeftGroupbox('NPC ESP')

	Groupboxes.NPC.Main:AddToggle('NPCESP', {
		Text = 'Enable',
		Default = false
	})

	Groupboxes.NPC.Main:AddToggle('NPCBoxes', {
		Text = 'Boxes',
		Default = true
	})

	Groupboxes.NPC.Main:AddToggle('NPCSkeleton', {
		Text = 'Skeleton',
		Default = false
	})

	Groupboxes.NPC.Main:AddToggle('NPCTracers', {
		Text = 'Tracers',
		Default = false
	})

	Groupboxes.NPC.Main:AddToggle('TargetDummyESP', {
		Text = 'Target Dummies',
		Default = true
	})

	----------------------------------------------------------------
	-- WORLD
	----------------------------------------------------------------

	Groupboxes.World.Main =
		SubTabs.Visuals.World:AddLeftGroupbox('World ESP')

	Groupboxes.World.Crates =
		SubTabs.Visuals.World:AddRightGroupbox('Crates')

	Groupboxes.World.Main:AddToggle('ExtractionESP', {
		Text = 'Extraction ESP',
		Default = false
	})

	Groupboxes.World.Main:AddToggle('ItemESP', {
		Text = 'Item ESP',
		Default = false
	})

	Groupboxes.World.Crates:AddToggle('CrateESP', {
		Text = 'Crate ESP',
		Default = false
	})

	Groupboxes.World.Crates:AddToggle('CommonCrates', {
		Text = 'Common',
		Default = true
	})

	Groupboxes.World.Crates:AddToggle('UncommonCrates', {
		Text = 'Uncommon',
		Default = true
	})

	Groupboxes.World.Crates:AddToggle('RareCrates', {
		Text = 'Rare',
		Default = true
	})

	Groupboxes.World.Crates:AddToggle('EpicCrates', {
		Text = 'Epic',
		Default = true
	})

	Groupboxes.World.Crates:AddToggle('LegendaryCrates', {
		Text = 'Legendary',
		Default = true
	})
end

function this.Shutdown()

end

return this