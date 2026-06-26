local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local this = {}

this.Values = {
	Aim = {},
	Visuals = {
		Player = {
			Master = false,
			Box = false,
			Chams = {
				Enabled = false,
				Color = Color3.new(1, 1, 1),
			},
			Flags = {
				Name = false,
				Health = false,
				Crouching = false,
			},
		}
	}
}

this.PlayerList = {}

-- Helper function to remove highlights from a player
local function RemoveHighlights(ps)
	if not ps or not ps.Highlights then return end
	for _, highlight in pairs(ps.Highlights) do
		if highlight then
			highlight:Destroy()
		end
	end
	ps.Highlights = {}
end

-- Helper function to create a highlight on a character
local function CreateHighlight(character, color)
	if not character then return nil end
	
	local highlight = Instance.new("Highlight")
	highlight.Parent = character
	highlight.Adornee = character
	highlight.FillColor = color
	highlight.FillTransparency = 0.5
	highlight.OutlineColor = color
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	
	-- Set visibility based on current settings
	local masterEnabled = this.Values.Visuals.Player.Master
	local chamsEnabled = this.Values.Visuals.Player.Chams.Enabled
	highlight.Enabled = masterEnabled and chamsEnabled
	
	return highlight
end

-- Helper function to update highlight colors
local function UpdateHighlightColor(highlight, color)
	if not highlight then return end
	highlight.FillColor = color
	highlight.OutlineColor = color
end

-- Helper function to update highlight visibility for all players
local function UpdateAllHighlights()
	local masterEnabled = this.Values.Visuals.Player.Master
	local chamsEnabled = this.Values.Visuals.Player.Chams.Enabled
	local shouldRender = masterEnabled and chamsEnabled
	local color = this.Values.Visuals.Player.Chams.Color
	
	for _, ps in pairs(this.PlayerList) do
		local highlight = ps.Highlights and ps.Highlights.Main
		if highlight then
			highlight.Enabled = shouldRender
			if shouldRender then
				UpdateHighlightColor(highlight, color)
			end
		elseif shouldRender and ps.Character then
			-- Create highlight if it doesn't exist and should render
			local newHighlight = CreateHighlight(ps.Character, color)
			if newHighlight then
				if not ps.Highlights then
					ps.Highlights = {}
				end
				ps.Highlights.Main = newHighlight
			end
		end
	end
end

function this.Load(Context)
	local Tabs = {
		Aim = Context.Window:AddTab('Aim'),
		Visuals = Context.Window:AddTab('Visuals'),
	}

	local Sections = {
		Aim = {},
		Visuals = {
			Player = {
				GroupBox = Tabs.Visuals:AddLeftGroupbox('Player'),
			},
			NPC = {
				Groupbox = Tabs.Visuals:AddLeftGroupbox('NPC'),
			},
			World = {
				Groupbox = Tabs.Visuals:AddRightGroupbox('World'),
			},
		},
	}

	Sections.Visuals.Player.MasterSwitch = Sections.Visuals.Player.GroupBox:AddToggle('MasterSwitch', {
		Text = 'Master',
		Default = false,
		Tooltip = 'Master switch for player ESP',
		Callback = function(Value) 
			this.Values.Visuals.Player.Master = Value
			UpdateAllHighlights()
		end
	})

	Sections.Visuals.Player.ChamsToggle = Sections.Visuals.Player.GroupBox:AddToggle('ChamsToggle', {
		Text = 'Chams',
		Default = false,
		Tooltip = 'Toggles chams using Highlights',
		Callback = function(Value) 
			this.Values.Visuals.Player.Chams.Enabled = Value
			UpdateAllHighlights()
		end
	})

	Sections.Visuals.Player.ChamsColor = Sections.Visuals.Player.GroupBox:AddLabel('Color'):AddColorPicker('ColorPicker', {
		Default = this.Values.Visuals.Player.Chams.Color,
		Title = 'Chams Color',
		Transparency = 0,
		Callback = function(Value)
			this.Values.Visuals.Player.Chams.Color = Value
			UpdateAllHighlights()
		end
	})

	this.StartThreads()
end

local function CreatePlayerEntry(player)
	if this.PlayerList[player.UserId] then return end

	this.PlayerList[player.UserId] = {
		Player = player,
		Character = nil,
		Highlights = {},
	}
end

function this.StartThreads()
	Zenware.Logic = task.spawn(function()
		for _, v in Players:GetPlayers() do
			CreatePlayerEntry(v)
			local char = v.Character
			if char then
				this.PlayerList[v.UserId].Character = char
				-- Create highlight for existing character if enabled
				if this.Values.Visuals.Player.Master and this.Values.Visuals.Player.Chams.Enabled then
					local highlight = CreateHighlight(char, this.Values.Visuals.Player.Chams.Color)
					if highlight then
						this.PlayerList[v.UserId].Highlights.Main = highlight
					end
				end
			end
		end

		Players.PlayerAdded:Connect(function(player)
			CreatePlayerEntry(player)

			player.CharacterAdded:Connect(function(char)
				if this.PlayerList[player.UserId] then
					this.PlayerList[player.UserId].Character = char
					
					-- Automatically create highlight for new character if enabled
					if this.Values.Visuals.Player.Master and this.Values.Visuals.Player.Chams.Enabled then
						local highlight = CreateHighlight(char, this.Values.Visuals.Player.Chams.Color)
						if highlight then
							if not this.PlayerList[player.UserId].Highlights then
								this.PlayerList[player.UserId].Highlights = {}
							end
							this.PlayerList[player.UserId].Highlights.Main = highlight
						end
					end
				end
			end)
		end)

		Players.PlayerRemoving:Connect(function(player)
			local data = this.PlayerList[player.UserId]
			if not data then return end

			-- Remove all highlights
			RemoveHighlights(data)
			
			this.PlayerList[player.UserId] = nil
		end)
	end)

	-- No need for RenderStepped anymore since we handle everything in events
	-- But keep it as a backup to ensure highlights are updated
	Zenware.Render = RunService.RenderStepped:Connect(function()
		-- UpdateAllHighlights is called from events, but we can still call it here
		-- for safety in case something was missed
		UpdateAllHighlights()
	end)
end

function this.Unload()
	for _, ps in pairs(this.PlayerList) do
		if ps.Highlights then
			RemoveHighlights(ps)
		end
	end

	table.clear(this.PlayerList)
end

return this