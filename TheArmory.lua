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

-- Helper function to get character parts with both modern and legacy naming
local function GetCharacterParts(Character)
	if not Character then return nil end
	
	local parts = {}
	
	-- Try modern naming first
	parts.Head = Character:FindFirstChild("Head")
	parts.UpperTorso = Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso")
	parts.LowerTorso = Character:FindFirstChild("LowerTorso") or Character:FindFirstChild("Torso")
	parts.LeftArm = Character:FindFirstChild("LeftUpperArm") or Character:FindFirstChild("LeftArm")
	parts.RightArm = Character:FindFirstChild("RightUpperArm") or Character:FindFirstChild("RightArm")
	parts.LeftLeg = Character:FindFirstChild("LeftUpperLeg") or Character:FindFirstChild("LeftLeg")
	parts.RightLeg = Character:FindFirstChild("RightUpperLeg") or Character:FindFirstChild("RightLeg")
	
	-- Additional limb parts for more detailed skeleton
	parts.LeftForearm = Character:FindFirstChild("LeftLowerArm")
	parts.RightForearm = Character:FindFirstChild("RightLowerArm")
	parts.LeftLowerLeg = Character:FindFirstChild("LeftLowerLeg")
	parts.RightLowerLeg = Character:FindFirstChild("RightLowerLeg")
	
	return parts
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
		Callback = function(Value) this.Values.Visuals.Player.Master = Value end
	})

	Sections.Visuals.Player.SkeletonToggle = Sections.Visuals.Player.GroupBox:AddToggle('SkeletonToggle', {
		Text = 'Skeletons',
		Default = false,
		Tooltip = 'Toggles skeleton ESP',
		Callback = function(Value) this.Values.Visuals.Player.Skeleton.Enabled = Value end
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
				-- Main skeleton connections
				HeadToTorso = Drawing.new("Line"),
				TorsoToLArm = Drawing.new("Line"),
				TorsoToRArm = Drawing.new("Line"),
				TorsoToLLeg = Drawing.new("Line"),
				TorsoToRLeg = Drawing.new("Line"),
				-- Additional connections for better skeleton
				TorsoToLowerTorso = Drawing.new("Line"),
				LArmToLForearm = Drawing.new("Line"),
				RArmToRForearm = Drawing.new("Line"),
				LLegToLLowerLeg = Drawing.new("Line"),
				RLegToRLowerLeg = Drawing.new("Line"),
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
		if not this.Values.Visuals.Player.Master then return end
		if not this.Values.Visuals.Player.Skeleton.Enabled then return end

		local cam = Workspace.CurrentCamera
		if not cam then return end

		for _, ps in pairs(this.PlayerList) do
			local char = ps.Character
			if not char then continue end

			local parts = GetCharacterParts(char)
			
			-- Check if we have the minimum required parts
			if not parts.Head or not parts.UpperTorso then
				-- Hide all bones if character isn't fully loaded
				for _, bone in pairs(ps.Drawings.Bones) do
					bone.Visible = false
				end
				continue
			end

			local function WorldToScreen(part)
				if not part then return nil, false end
				local pos, onScreen = cam:WorldToViewportPoint(part.Position)
				return Vector2.new(pos.X, pos.Y), onScreen
			end

			-- Get all part positions
			local headPos, headOnScreen = WorldToScreen(parts.Head)
			local torsoPos, torsoOnScreen = WorldToScreen(parts.UpperTorso)
			local lowerTorsoPos = parts.LowerTorso and WorldToScreen(parts.LowerTorso) or nil
			local lArmPos = parts.LeftArm and WorldToScreen(parts.LeftArm) or nil
			local rArmPos = parts.RightArm and WorldToScreen(parts.RightArm) or nil
			local lLegPos = parts.LeftLeg and WorldToScreen(parts.LeftLeg) or nil
			local rLegPos = parts.RightLeg and WorldToScreen(parts.RightLeg) or nil
			local lForearmPos = parts.LeftForearm and WorldToScreen(parts.LeftForearm) or nil
			local rForearmPos = parts.RightForearm and WorldToScreen(parts.RightForearm) or nil
			local lLowerLegPos = parts.LeftLowerLeg and WorldToScreen(parts.LeftLowerLeg) or nil
			local rLowerLegPos = parts.RightLowerLeg and WorldToScreen(parts.RightLowerLeg) or nil

			-- Hide all bones if torso isn't on screen
			if not torsoOnScreen or not torsoPos then
				for _, bone in pairs(ps.Drawings.Bones) do
					bone.Visible = false
				end
				continue
			end

			local bones = ps.Drawings.Bones
			local cfg = this.Values.Visuals.Player.Skeleton
			local thickness = cfg.Thickness or 1

			-- Helper function to update a bone line
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
			UpdateBone(bones.HeadToTorso, headPos, torsoPos, headOnScreen and headPos ~= nil)
			UpdateBone(bones.TorsoToLArm, torsoPos, lArmPos, lArmPos ~= nil)
			UpdateBone(bones.TorsoToRArm, torsoPos, rArmPos, rArmPos ~= nil)
			UpdateBone(bones.TorsoToLLeg, torsoPos, lLegPos, lLegPos ~= nil)
			UpdateBone(bones.TorsoToRLeg, torsoPos, rLegPos, rLegPos ~= nil)
			
			-- Update additional bones if they exist
			if lowerTorsoPos then
				UpdateBone(bones.TorsoToLowerTorso, torsoPos, lowerTorsoPos, true)
			else
				bones.TorsoToLowerTorso.Visible = false
			end
			
			if lForearmPos then
				UpdateBone(bones.LArmToLForearm, lArmPos, lForearmPos, lArmPos ~= nil)
			else
				bones.LArmToLForearm.Visible = false
			end
			
			if rForearmPos then
				UpdateBone(bones.RArmToRForearm, rArmPos, rForearmPos, rArmPos ~= nil)
			else
				bones.RArmToRForearm.Visible = false
			end
			
			if lLowerLegPos then
				UpdateBone(bones.LLegToLLowerLeg, lLegPos, lLowerLegPos, lLegPos ~= nil)
			else
				bones.LLegToLLowerLeg.Visible = false
			end
			
			if rLowerLegPos then
				UpdateBone(bones.RLegToRLowerLeg, rLegPos, rLowerLegPos, rLegPos ~= nil)
			else
				bones.RLegToRLowerLeg.Visible = false
			end
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