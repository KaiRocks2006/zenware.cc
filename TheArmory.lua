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
			Skeleton = {
				Enabled = false,
				Color = Color3.new(1, 1, 1),
				Thickness = 1,
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

-- Helper function to get character parts for R6 with debug
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
	
	-- Debug: Print what parts were found
	--[[
	print(string.format("Character %s parts found:", Character.Name))
	print(string.format("  Head: %s", parts.Head and "Yes" or "No"))
	print(string.format("  Torso: %s", parts.Torso and "Yes" or "No"))
	print(string.format("  LeftArm: %s", parts.LeftArm and "Yes" or "No"))
	print(string.format("  RightArm: %s", parts.RightArm and "Yes" or "No"))
	print(string.format("  LeftLeg: %s", parts.LeftLeg and "Yes" or "No"))
	print(string.format("  RightLeg: %s", parts.RightLeg and "Yes" or "No"))
	--]]
	
	return parts
end

-- Helper function to hide all bones for a player
local function HideAllBones(ps)
	if not ps or not ps.Drawings then return end
	for _, bone in pairs(ps.Drawings.Bones) do
		bone.Visible = false
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
			if not Value then
				for _, ps in pairs(this.PlayerList) do
					HideAllBones(ps)
				end
			end
		end
	})

	Sections.Visuals.Player.SkeletonToggle = Sections.Visuals.Player.GroupBox:AddToggle('SkeletonToggle', {
		Text = 'Skeletons',
		Default = false,
		Tooltip = 'Toggles skeleton ESP',
		Callback = function(Value) 
			this.Values.Visuals.Player.Skeleton.Enabled = Value
			if not Value then
				for _, ps in pairs(this.PlayerList) do
					HideAllBones(ps)
				end
			end
		end
	})

	Sections.Visuals.Player.SkeletonColor = Sections.Visuals.Player.GroupBox:AddLabel('Color'):AddColorPicker('ColorPicker', {
		Default = this.Values.Visuals.Player.Skeleton.Color,
		Title = 'Skeleton Color',
		Transparency = 0,
		Callback = function(Value)
			this.Values.Visuals.Player.Skeleton.Color = Value
		end
	})

	this.StartThreads()
end

local function CreatePlayerEntry(player)
	if this.PlayerList[player.UserId] then return end

	this.PlayerList[player.UserId] = {
		Player = player,
		Character = nil,
		Drawings = {
			Box = Drawing.new("Square"),
			Tracer = Drawing.new("Line"),
			Bones = {
				HeadToTorso = Drawing.new("Line"),
				TorsoToLArm = Drawing.new("Line"),
				TorsoToRArm = Drawing.new("Line"),
				TorsoToLLeg = Drawing.new("Line"),
				TorsoToRLeg = Drawing.new("Line"),
			},
			Texts = {},
		}
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

			for _, bone in pairs(data.Drawings.Bones) do
				bone:Remove()
			end

			for _, txt in pairs(data.Drawings.Texts) do
				txt:Remove()
			end

			data.Drawings.Box:Remove()
			data.Drawings.Tracer:Remove()

			this.PlayerList[player.UserId] = nil
		end)
	end)

	Zenware.Render = RunService.RenderStepped:Connect(function()
		if not this.Values.Visuals.Player.Master or not this.Values.Visuals.Player.Skeleton.Enabled then
			for _, ps in pairs(this.PlayerList) do
				HideAllBones(ps)
			end
			return
		end

		local cam = Workspace.CurrentCamera
		if not cam then 
			for _, ps in pairs(this.PlayerList) do
				HideAllBones(ps)
			end
			return 
		end

		for _, ps in pairs(this.PlayerList) do
			local char = ps.Character
			if not char then 
				HideAllBones(ps)
				continue 
			end

			local parts = GetCharacterParts(char)
			
			if not parts.Head or not parts.Torso then
				HideAllBones(ps)
				continue
			end

			local function WorldToScreen(part)
				if not part then return nil, false end
				local pos, onScreen = cam:WorldToViewportPoint(part.Position)
				return Vector2.new(pos.X, pos.Y), onScreen
			end

			local headPos, headOnScreen = WorldToScreen(parts.Head)
			local torsoPos, torsoOnScreen = WorldToScreen(parts.Torso)
			
			-- Handle limbs that might be nil
			local lArmPos, lArmOnScreen = false, false
			local rArmPos, rArmOnScreen = false, false
			local lLegPos, lLegOnScreen = false, false
			local rLegPos, rLegOnScreen = false, false
			
			if parts.LeftArm then
				lArmPos, lArmOnScreen = WorldToScreen(parts.LeftArm)
			end
			
			if parts.RightArm then
				rArmPos, rArmOnScreen = WorldToScreen(parts.RightArm)
			end
			
			if parts.LeftLeg then
				lLegPos, lLegOnScreen = WorldToScreen(parts.LeftLeg)
			end
			
			if parts.RightLeg then
				rLegPos, rLegOnScreen = WorldToScreen(parts.RightLeg)
			end

			if not torsoOnScreen or not torsoPos then
				HideAllBones(ps)
				continue
			end

			local bones = ps.Drawings.Bones
			local cfg = this.Values.Visuals.Player.Skeleton
			local thickness = cfg.Thickness or 1

			local function UpdateBone(line, from, to, visible)
				if not line then return end
				if visible and from and to then
					line.Visible = true
					line.From = from
					line.To = to
					line.Color = cfg.Color
					line.Thickness = thickness
				else
					line.Visible = false
				end
			end

			-- Update all bone connections
			UpdateBone(bones.HeadToTorso, headPos, torsoPos, headOnScreen)
			UpdateBone(bones.TorsoToLArm, torsoPos, lArmPos, lArmOnScreen and lArmPos ~= nil)
			UpdateBone(bones.TorsoToRArm, torsoPos, rArmPos, rArmOnScreen and rArmPos ~= nil)
			UpdateBone(bones.TorsoToLLeg, torsoPos, lLegPos, lLegOnScreen and lLegPos ~= nil)
			UpdateBone(bones.TorsoToRLeg, torsoPos, rLegPos, rLegOnScreen and rLegPos ~= nil)
			
			-- Debug: Check if limb lines are being set
			--[[
			if lArmPos then
				print(string.format("Left Arm visible: %s, Position: %s", lArmOnScreen, tostring(lArmPos)))
			else
				print("Left Arm not found!")
			end
			--]]
		end
	end)
end

function this.Unload()
	for _, ps in pairs(this.PlayerList) do
		if ps.Drawings then
			for _, bone in pairs(ps.Drawings.Bones) do
				bone:Remove()
			end

			for _, txt in pairs(ps.Drawings.Texts) do
				txt:Remove()
			end

			if ps.Drawings.Box then ps.Drawings.Box:Remove() end
			if ps.Drawings.Tracer then ps.Drawings.Tracer:Remove() end
		end
	end

	table.clear(this.PlayerList)
end

return this