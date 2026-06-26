local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local this = {}

this.Values = {
	Aim = {
		Enabled = false,
		Silent = false,
		AimKey = "MouseButton2",
		Smoothness = 0.3,
		FOV = 100,
		TargetPart = "Head",
		VisibleCheck = true,
		TeamCheck = false,
	},
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
this.AimbotTarget = nil
this.AimKeyDown = false

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

-- Aimbot functions
local function IsValidTarget(player)
	if not player then return false end
	if player == Players.LocalPlayer then return false end
	
	local character = player.Character
	if not character then return false end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	
	if this.Values.Aim.TeamCheck then
		local localPlayer = Players.LocalPlayer
		if localPlayer.Team and player.Team == localPlayer.Team then
			return false
		end
	end
	
	return true
end

local function GetTargetPart(character)
	local partName = this.Values.Aim.TargetPart
	local part = character:FindFirstChild(partName)
	
	if not part then
		part = character:FindFirstChild("Head")
	end
	
	if not part then
		part = character:FindFirstChild("HumanoidRootPart")
	end
	
	return part
end

local function IsVisible(part)
	if not part then return false end
	
	local origin = Workspace.CurrentCamera.CFrame.Position
	local direction = (part.Position - origin).Unit * (part.Position - origin).Magnitude
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {Players.LocalPlayer.Character}
	
	local result = Workspace:Raycast(origin, direction, raycastParams)
	
	if not result then return true end
	
	local targetCharacter = part.Parent
	if targetCharacter and result.Instance:IsDescendantOf(targetCharacter) then
		return true
	end
	
	return false
end

local function GetClosestPlayer()
	local localPlayer = Players.LocalPlayer
	local camera = Workspace.CurrentCamera
	if not camera then return nil end
	
	local closestPlayer = nil
	local closestDistance = this.Values.Aim.FOV or 999
	
	local mousePosition = UserInputService:GetMouseLocation()
	local screenCenter = Vector2.new(mousePosition.X, mousePosition.Y)
	
	for _, player in pairs(Players:GetPlayers()) do
		if not IsValidTarget(player) then continue end
		
		local character = player.Character
		if not character then continue end
		
		local targetPart = GetTargetPart(character)
		if not targetPart then continue end
		
		if this.Values.Aim.VisibleCheck and not IsVisible(targetPart) then
			continue
		end
		
		local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
		if not onScreen then continue end
		
		local screenPos2D = Vector2.new(screenPos.X, screenPos.Y)
		local distance = (screenPos2D - screenCenter).Magnitude
		
		if distance < closestDistance then
			closestDistance = distance
			closestPlayer = player
		end
	end
	
	return closestPlayer
end

local function GetTargetScreenPosition()
	local target = GetClosestPlayer()
	if not target then return nil end
	
	local character = target.Character
	if not character then return nil end
	
	local targetPart = GetTargetPart(character)
	if not targetPart then return nil end
	
	local camera = Workspace.CurrentCamera
	if not camera then return nil end
	
	local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
	if not onScreen then return nil end
	
	return Vector2.new(screenPos.X, screenPos.Y), target
end

-- Main aimbot function using mousemoveabs
local function DoAimbot()
	if not this.Values.Aim.Enabled then
		this.AimbotTarget = nil
		return
	end
	
	-- Only aim when the aim key is held down
	if not this.AimKeyDown then
		return
	end
	
	local targetScreenPos, target = GetTargetScreenPosition()
	if not targetScreenPos or not target then
		this.AimbotTarget = nil
		return
	end
	
	this.AimbotTarget = target
	
	-- Get current mouse position
	local currentMousePos = UserInputService:GetMouseLocation()
	local targetX = targetScreenPos.X
	local targetY = targetScreenPos.Y
	
	-- Apply smoothing if enabled
	local smoothness = this.Values.Aim.Smoothness or 0.3
	if smoothness < 1 then
		-- Calculate the difference and apply smoothing
		local diffX = targetX - currentMousePos.X
		local diffY = targetY - currentMousePos.Y
		
		-- Apply smoothing factor
		targetX = currentMousePos.X + (diffX * smoothness)
		targetY = currentMousePos.Y + (diffY * smoothness)
	end
	
	-- Move the mouse to the target position
	mousemoveabs(targetX, targetY)
end

-- Silent aim (overrides mouse location)
local function SetupSilentAim()
	local originalGetMouseLocation = UserInputService.GetMouseLocation
	
	UserInputService.GetMouseLocation = function(self)
		if not this.Values.Aim.Enabled or not this.Values.Aim.Silent then
			return originalGetMouseLocation(self)
		end
		
		-- Only apply silent aim when aim key is held
		if not this.AimKeyDown then
			return originalGetMouseLocation(self)
		end
		
		local targetScreenPos, _ = GetTargetScreenPosition()
		if not targetScreenPos then
			return originalGetMouseLocation(self)
		end
		
		-- Return the target's screen position
		return Vector2.new(targetScreenPos.X, targetScreenPos.Y)
	end
end

-- Setup input handling for aim key
local function SetupAimKey()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		local aimKey = this.Values.Aim.AimKey
		local keyPressed = false
		
		-- Check if the input matches our aim key
		if input.UserInputType == Enum.UserInputType[aimKey] then
			keyPressed = true
		elseif input.KeyCode == Enum.KeyCode[aimKey] then
			keyPressed = true
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 and aimKey == "MouseButton1" then
			keyPressed = true
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 and aimKey == "MouseButton2" then
			keyPressed = true
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 and aimKey == "MouseButton3" then
			keyPressed = true
		end
		
		if keyPressed then
			this.AimKeyDown = true
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		local aimKey = this.Values.Aim.AimKey
		local keyReleased = false
		
		if input.UserInputType == Enum.UserInputType[aimKey] then
			keyReleased = true
		elseif input.KeyCode == Enum.KeyCode[aimKey] then
			keyReleased = true
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 and aimKey == "MouseButton1" then
			keyReleased = true
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 and aimKey == "MouseButton2" then
			keyReleased = true
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 and aimKey == "MouseButton3" then
			keyReleased = true
		end
		
		if keyReleased then
			this.AimKeyDown = false
			this.AimbotTarget = nil
		end
	end)
end

function this.Load(Context)
	local Tabs = {
		Aim = Context.Window:AddTab('Aim'),
		Visuals = Context.Window:AddTab('Visuals'),
	}

	local Sections = {
		Aim = {
			Main = {
				GroupBox = Tabs.Aim:AddLeftGroupbox('Main'),
			},
			Settings = {
				GroupBox = Tabs.Aim:AddRightGroupbox('Settings'),
			},
		},
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

	-- Visuals
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

	-- Aimbot
	Sections.Aim.Main.AimbotToggle = Sections.Aim.Main.GroupBox:AddToggle('AimbotToggle', {
		Text = 'Aimbot',
		Default = false,
		Tooltip = 'Toggles aimbot',
		Callback = function(Value)
			this.Values.Aim.Enabled = Value
			if not Value then
				this.AimbotTarget = nil
				this.AimKeyDown = false
			end
		end
	})

	Sections.Aim.Main.SilentAimToggle = Sections.Aim.Main.GroupBox:AddToggle('SilentAimToggle', {
		Text = 'Silent Aim',
		Default = false,
		Tooltip = 'Aim without moving the camera (mouse movement only)',
		Callback = function(Value)
			this.Values.Aim.Silent = Value
			if Value then
				SetupSilentAim()
			else
				UserInputService.GetMouseLocation = nil
			end
		end
	})

	-- Aim Key Label and KeyPicker
	local aimKeyLabel = Sections.Aim.Main.GroupBox:AddLabel('Aim Key')
	local aimKeyPicker = aimKeyLabel:AddKeyPicker('AimKeyPicker', {
		Default = 'MouseButton2',
		Text = 'Aim Key',
		NoUI = false,
		Callback = function(Value)
			this.Values.Aim.AimKey = Value
		end,
		ChangedCallback = function(New)
			this.Values.Aim.AimKey = New
		end
	})

	Sections.Aim.Settings.SmoothnessSlider = Sections.Aim.Settings.GroupBox:AddSlider('Smoothness', {
		Text = 'Smoothness',
		Default = 0.3,
		Min = 0.05,
		Max = 1,
		Rounding = 2,
		Callback = function(Value)
			this.Values.Aim.Smoothness = Value
		end
	})

	Sections.Aim.Settings.FOVSlider = Sections.Aim.Settings.GroupBox:AddSlider('FOV', {
		Text = 'FOV',
		Default = 100,
		Min = 10,
		Max = 500,
		Rounding = 0,
		Callback = function(Value)
			this.Values.Aim.FOV = Value
		end
	})

	-- Dropdown for target part
	Sections.Aim.Settings.TargetPartDropdown = Sections.Aim.Settings.GroupBox:AddDropdown('TargetPart', {
		Values = { 'Head', 'Torso', 'HumanoidRootPart' },
		Default = 1,
		Multi = false,
		Text = 'Target Part',
		Tooltip = 'Select which body part to aim at',
		Callback = function(Value)
			this.Values.Aim.TargetPart = Value
		end
	})

	Sections.Aim.Settings.VisibleCheckToggle = Sections.Aim.Settings.GroupBox:AddToggle('VisibleCheck', {
		Text = 'Visible Check',
		Default = true,
		Tooltip = 'Only target visible players',
		Callback = function(Value)
			this.Values.Aim.VisibleCheck = Value
		end
	})

	Sections.Aim.Settings.TeamCheckToggle = Sections.Aim.Settings.GroupBox:AddToggle('TeamCheck', {
		Text = 'Team Check',
		Default = false,
		Tooltip = 'Don\'t target teammates',
		Callback = function(Value)
			this.Values.Aim.TeamCheck = Value
		end
	})

	-- Setup aim key input handling
	SetupAimKey()
	
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

			RemoveHighlights(data)
			
			if this.AimbotTarget == player then
				this.AimbotTarget = nil
			end
			
			this.PlayerList[player.UserId] = nil
		end)
	end)

	Zenware.Render = RunService.RenderStepped:Connect(function()
		UpdateAllHighlights()
		
		-- Run aimbot
		DoAimbot()
	end)
end

function this.Unload()
	for _, ps in pairs(this.PlayerList) do
		if ps.Highlights then
			RemoveHighlights(ps)
		end
	end

	table.clear(this.PlayerList)
	this.AimbotTarget = nil
	this.AimKeyDown = false
	
	UserInputService.GetMouseLocation = nil
end

return this