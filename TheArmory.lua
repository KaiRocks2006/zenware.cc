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

-- Helper function to get character parts for R6
local function GetCharacterParts(Character)
	if not Character then return nil end
	
	local parts = {}
	
	-- R6 uses these part names directly
	parts.Head = Character:FindFirstChild("Head")
	parts.Torso = Character:FindFirstChild("Torso")
	parts.LeftArm = Character:FindFirstChild("LeftArm")
	parts.RightArm = Character:FindFirstChild("RightArm")
	parts.LeftLeg = Character:FindFirstChild("LeftLeg")
	parts.RightLeg = Character:FindFirstChild("RightLeg")
	
	return parts
end

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

-- Helper function to create or update highlights for a player
local function UpdateHighlights(ps, color, enabled)
	if not ps then return end
	
	-- Remove existing highlights if disabled or no character
	if not enabled or not ps.Character then
		RemoveHighlights(ps)
		return
	end
	
	local parts = GetCharacterParts(ps.Character)
	if not parts or not parts.Torso then
		RemoveHighlights(ps)
		return
	end
	
	-- Initialize highlights table if needed
	if not ps.Highlights then
		ps.Highlights = {}
	end
	
	-- Create highlights for each part
	local partNames = {"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}
	
	for _, name in ipairs(partNames) do
		local part = parts[name]
		if part then
			-- Check if highlight already exists for this part
			local highlight = ps.Highlights[name]
			if not highlight or highlight.Parent ~= ps.Character then
				-- Remove old highlight if it exists
				if highlight then
					highlight:Destroy()
				end
				-- Create new highlight as child of character
				highlight = Instance.new("Highlight")
				highlight.Parent = ps.Character
				highlight.Adornee = part
				highlight.FillColor = color
				highlight.FillTransparency = 0.5
				highlight.OutlineColor = color
				highlight.OutlineTransparency = 0
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				ps.Highlights[name] = highlight
			else
				-- Update existing highlight
				highlight.Adornee = part
				highlight.FillColor = color
				highlight.OutlineColor = color
			end
		end
	end
	
	-- Remove highlights for parts that no longer exist
	for name, highlight in pairs(ps.Highlights) do
		if not parts[name] or not highlight.Parent then
			highlight:Destroy()
			ps.Highlights[name] = nil
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
			-- Update highlights when master is toggled
			if not Value then
				for _, ps in pairs(this.PlayerList) do
					RemoveHighlights(ps)
				end
			end
		end
	})

	Sections.Visuals.Player.ChamsToggle = Sections.Visuals.Player.GroupBox:AddToggle('ChamsToggle', {
		Text = 'Chams',
		Default = false,
		Tooltip = 'Toggles chams using Highlights',
		Callback = function(Value) 
			this.Values.Visuals.Player.Chams.Enabled = Value
			if not Value then
				for _, ps in pairs(this.PlayerList) do
					RemoveHighlights(ps)
				end
			end
		end
	})

	Sections.Visuals.Player.ChamsColor = Sections.Visuals.Player.GroupBox:AddLabel('Color'):AddColorPicker('ColorPicker', {
		Default = this.Values.Visuals.Player.Chams.Color,
		Title = 'Chams Color',
		Transparency = 0,
		Callback = function(Value)
			this.Values.Visuals.Player.Chams.Color = Value
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
			this.PlayerList[v.UserId].Character = v.Character
		end

		Players.PlayerAdded:Connect(function(player)
			CreatePlayerEntry(player)

			player.CharacterAdded:Connect(function(char)
				if this.PlayerList[player.UserId] then
					this.PlayerList[player.UserId].Character = char
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

	Zenware.Render = RunService.RenderStepped:Connect(function()
		local masterEnabled = this.Values.Visuals.Player.Master
		local chamsEnabled = this.Values.Visuals.Player.Chams.Enabled
		local color = this.Values.Visuals.Player.Chams.Color
		
		-- Check if toggles are enabled
		local shouldRender = masterEnabled and chamsEnabled
		
		for _, ps in pairs(this.PlayerList) do
			if shouldRender then
				-- Update highlights for this player
				UpdateHighlights(ps, color, true)
			else
				-- Remove highlights if toggles are disabled
				RemoveHighlights(ps)
			end
		end
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