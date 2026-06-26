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

-- Helper function to get character parts for R6
local function GetCharacterParts(Character)
	if not Character then return nil end
	
	local parts = {}
	
	-- R6 uses these part names directly
	parts.Head = Character:FindFirstChild("Head")
	parts.Torso = Character:FindFirstChild("Torso") -- R6 uses just "Torso"
	parts.LeftArm = Character:FindFirstChild("LeftArm")
	parts.RightArm = Character:FindFirstChild("RightArm")
	parts.LeftLeg = Character:FindFirstChild("LeftLeg")
	parts.RightLeg = Character:FindFirstChild("RightLeg")
	
	-- These don't exist in R6, but keep for compatibility
	parts.UpperTorso = parts.Torso
	parts.LowerTorso = nil
	parts.LeftForearm = nil
	parts.RightForearm = nil
	parts.LeftLowerLeg = nil
	parts.RightLowerLeg = nil
	
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
				-- R6 skeleton connections
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
		if not this.Values.Visuals.Player.Master then return end
		if not this.Values.Visuals.Player.Skeleton.Enabled then return end

		local cam = Workspace.CurrentCamera
		if not cam then return end

		for _, ps in pairs(this.PlayerList) do
			local char = ps.Character
			if not char then continue end

			local parts = GetCharacterParts(char)
			
			-- Check if we have the minimum required parts for R6
			if not parts.Head or not parts.Torso then
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

			-- Get all part positions for R6
			local headPos, headOnScreen = WorldToScreen(parts.Head)
			local torsoPos, torsoOnScreen = WorldToScreen(parts.Torso)
			local lArmPos, lArmOnScreen = WorldToScreen(parts.LeftArm)
			local rArmPos, rArmOnScreen = WorldToScreen(parts.RightArm)
			local lLegPos, lLegOnScreen = WorldToScreen(parts.LeftLeg)
			local rLegPos, rLegOnScreen = WorldToScreen(parts.RightLeg)

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

			-- Debug: Print which parts are found
			-- print(string.format("Parts found - Head: %s, Torso: %s, LArm: %s, RArm: %s, LLeg: %s, RLeg: %s", 
			-- 	parts.Head and "Yes" or "No",
			-- 	parts.Torso and "Yes" or "No",
			-- 	parts.LeftArm and "Yes" or "No",
			-- 	parts.RightArm and "Yes" or "No",
			-- 	parts.LeftLeg and "Yes" or "No",
			-- 	parts.RightLeg and "Yes" or "No"))

			-- Update all bone connections for R6
			UpdateBone(bones.HeadToTorso, headPos, torsoPos, headOnScreen and headPos ~= nil)
			UpdateBone(bones.TorsoToLArm, torsoPos, lArmPos, lArmOnScreen and lArmPos ~= nil)
			UpdateBone(bones.TorsoToRArm, torsoPos, rArmPos, rArmOnScreen and rArmPos ~= nil)
			UpdateBone(bones.TorsoToLLeg, torsoPos, lLegPos, lLegOnScreen and lLegPos ~= nil)
			UpdateBone(bones.TorsoToRLeg, torsoPos, rLegPos, rLegOnScreen and rLegPos ~= nil)
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