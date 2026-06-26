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

local function GetCharacterParts(Character : Model)
	if Character and Character.HumanoidRootPart then
		local Parts = {
			Head = Character.Head,
			Torso = Character.Torso,
			LeftLeg = Character.LeftLeg,
			RightLeg = Character.RightLeg,
			LeftArm = Character.LeftArm,
			RightArm = Character.RightArm,
		}
		return Parts
	end
	return nil
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

		for _, ps in pairs(this.PlayerList) do
			local char = ps.Character
			if not char then continue end

			local head = char:FindFirstChild("Head")
			local torso = char:FindFirstChild("Torso")
			local larm = char:FindFirstChild("LeftArm")
			local rarm = char:FindFirstChild("RightArm")
			local lleg = char:FindFirstChild("LeftLeg")
			local rleg = char:FindFirstChild("RightLeg")

			if not (head and torso and larm and rarm and lleg and rleg) then
				continue
			end

			local function W2S(part)
				local pos, vis = cam:WorldToViewportPoint(part.Position)
				return Vector2.new(pos.X, pos.Y), vis
			end

			local head2d, headVis = W2S(head)
			local torso2d, torsoVis = W2S(torso)
			local larm2d, _ = W2S(larm)
			local rarm2d, _ = W2S(rarm)
			local lleg2d, _ = W2S(lleg)
			local rleg2d, _ = W2S(rleg)

			local _, onScreen = cam:WorldToViewportPoint(torso.Position)

			if not onScreen then
				for _, bone in pairs(ps.Drawings.Bones) do
					bone.Visible = false
				end
				continue
			end

			local bones = ps.Drawings.Bones
			local cfg = this.Values.Visuals.Player.Skeleton

			local function SetLine(line, from, to)
				line.Visible = true
				line.From = from
				line.To = to
				line.Color = cfg.Color
				line.Thickness = cfg.Thickness
			end

			SetLine(bones.HeadToTorso, head2d, torso2d)
			SetLine(bones.TorsoToLArm, torso2d, larm2d)
			SetLine(bones.TorsoToRArm, torso2d, rarm2d)
			SetLine(bones.TorsoToLLeg, torso2d, lleg2d)
			SetLine(bones.TorsoToRLeg, torso2d, rleg2d)
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