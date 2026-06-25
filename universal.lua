local this = {}

--[[

	Reference Context:
	Context = {
		["Window"] = Window, -- PepsiLib Window
		["Players"] = Players,
		["Workspace"] = Workspace,
		["RunService"] = RunService,
		["HttpService"] = HttpService,
		["Library"] = Library,
	}

]]--

this.Window = nil
this.Library = nil
this.Tabs = {}
this.Services = {}
this.Variables = {
	ESPMasterToggle = false,
	SkeletonToggle = false,
}

this.Drawings = {}
this._RenderThread = nil
this._LogicThread = nil

local _localId = nil
local _camera = nil

-- Bone definitions per rig type
local R6_BONES = {
	{ "Head",        "Torso"        },
	{ "Torso",       "Left Arm"     },
	{ "Torso",       "Right Arm"    },
	{ "Torso",       "Left Leg"     },
	{ "Torso",       "Right Leg"    },
}

local R15_BONES = {
	{ "Head",           "UpperTorso"    },
	{ "UpperTorso",     "LowerTorso"    },
	{ "UpperTorso",     "LeftUpperArm"  },
	{ "LeftUpperArm",   "LeftLowerArm"  },
	{ "LeftLowerArm",   "LeftHand"      },
	{ "UpperTorso",     "RightUpperArm" },
	{ "RightUpperArm",  "RightLowerArm" },
	{ "RightLowerArm",  "RightHand"     },
	{ "LowerTorso",     "LeftUpperLeg"  },
	{ "LeftUpperLeg",   "LeftLowerLeg"  },
	{ "LeftLowerLeg",   "LeftFoot"      },
	{ "LowerTorso",     "RightUpperLeg" },
	{ "RightUpperLeg",  "RightLowerLeg" },
	{ "RightLowerLeg",  "RightFoot"     },
}

function this.Start(context)
	this.Window = context.Window
	this.Library = context.Library
	this.Services = {
		Players = context.Players,
		Workspace = context.Workspace,
		RunService = context.RunService,
		HttpService = context.HttpService,
	}

	_localId = this.Services.Players.LocalPlayer.UserId
	_camera = this.Services.Workspace.CurrentCamera

	this.Services.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		_camera = this.Services.Workspace.CurrentCamera
	end)

	this.InitTabs(this.Window)
	this.Library.UnloadCallback = this.Shutdown
	this.StartThreads()

	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "zenware.cc",
		Text = "Loaded Universal",
		Duration = 5
	})
end

function this.InitTabs(w)
	this.Tabs.Aim = {
		Tab = w:CreateTab({ Name = "Aim" }),
		Sections = {},
		Fields = {}
	}
	this.Tabs.Visuals = {
		Tab = w:CreateTab({ Name = "Visuals" }),
		Sections = {},
		Fields = {}
	}
	this.Tabs.Exploits = {
		Tab = w:CreateTab({ Name = "Exploits" }),
		Sections = {},
		Fields = {}
	}
	this.Tabs.World = {
		Tab = w:CreateTab({ Name = "World" }),
		Sections = {},
		Fields = {}
	}
	this.InitSections(this.Tabs)
end

function this.InitSections(t)
	t.Aim.Sections["Toggles"]    = t.Aim.Tab:CreateSection({ Name = "Toggles",    Side = "Left"  })
	t.Aim.Sections["Prediction"] = t.Aim.Tab:CreateSection({ Name = "Prediction", Side = "Right" })
	t.Aim.Sections["Precision"]  = t.Aim.Tab:CreateSection({ Name = "Precision",  Side = "Right" })

	t.Visuals.Sections["Toggles"] = t.Visuals.Tab:CreateSection({ Name = "Toggles", Side = "Left" })

	this.InitFields(t)
end

function this.InitFields(t)
	t.Visuals.Fields["MasterToggle"] = t.Visuals.Sections.Toggles:AddToggle({
		Name = "Master",
		Callback = function(v)
			this.Variables.ESPMasterToggle = v
		end
	})
	t.Visuals.Fields["SkeletonToggle"] = t.Visuals.Sections.Toggles:AddToggle({
		Name = "Skeleton",
		Callback = function(v)
			this.Variables.SkeletonToggle = v
		end
	})
end

--[[
	PlayerList = {
		[UserId] = {
			Character (Model | nil),
			CharacterName (string | nil),
			HumanoidRootPart (BasePart | nil),
			RigType ("R6" | "R15" | nil),
			Limbs ({ [partName] = BasePart }),
			CharacterAdded (Connection),
			CharacterRemoving (Connection)
		}
	}
]]--
this.PlayerList = {}

this.PlayerConnected = nil
this.PlayerRemoving = nil

local function GetOrCreateDrawings(UserId, boneCount)
	local d = this.Drawings[UserId]

	if not d.Box then
		local box = Drawing.new("Square")
		box.Thickness = 1
		box.Visible = false
		d.Box = box
	end

	if not d.Texts.Name then
		local t = Drawing.new("Text")
		t.Size = 12
		t.Color = Color3.new(1, 1, 1)
		t.Center = true
		t.Visible = false
		d.Texts.Name = t
	end

	-- Ensure enough bone lines exist
	while #d.Lines < boneCount do
		local l = Drawing.new("Line")
		l.Thickness = 1
		l.Color = Color3.new(1, 1, 1)
		l.Visible = false
		d.Lines[#d.Lines + 1] = l
	end

	return d
end

local function SetDrawingsVisible(UserId, visible)
	local d = this.Drawings[UserId]
	if not d then return end
	if d.Box and d.Box.Visible ~= visible then
		d.Box.Visible = visible
	end
	for _, text in pairs(d.Texts) do
		if text.Visible ~= visible then
			text.Visible = visible
		end
	end
	for _, line in ipairs(d.Lines) do
		if line.Visible ~= visible then
			line.Visible = visible
		end
	end
end

local function SetSkeletonVisible(UserId, visible)
	local d = this.Drawings[UserId]
	if not d then return end
	for _, line in ipairs(d.Lines) do
		if line.Visible ~= visible then
			line.Visible = visible
		end
	end
end

local function UpdateSkeleton(id, s, d)
	local bones = s.RigType == "R6" and R6_BONES or R15_BONES
	local limbs = s.Limbs

	for i, bone in ipairs(bones) do
		local partA = limbs[bone[1]]
		local partB = limbs[bone[2]]
		local line  = d.Lines[i]
		if not line then continue end

		if partA == nil or partB == nil then
			if line.Visible then line.Visible = false end
			continue
		end

		local posA, onA = _camera:WorldToViewportPoint(partA.Position)
		local posB, onB = _camera:WorldToViewportPoint(partB.Position)

		if not onA or not onB then
			if line.Visible then line.Visible = false end
			continue
		end

		local from = Vector2.new(posA.X, posA.Y)
		local to   = Vector2.new(posB.X, posB.Y)

		if line.From ~= from then line.From = from end
		if line.To   ~= to   then line.To   = to   end
		if not line.Visible   then line.Visible = true end
	end

	-- Hide any extra lines beyond current bone count
	for i = #bones + 1, #d.Lines do
		if d.Lines[i].Visible then d.Lines[i].Visible = false end
	end
end

local function HandleEsp()
	local showSkeleton = this.Variables.SkeletonToggle

	for id, s in pairs(this.PlayerList) do
		if id == _localId or s.HumanoidRootPart == nil then
			SetDrawingsVisible(id, false)
			continue
		end

		local pos, onscreen = _camera:WorldToViewportPoint(s.HumanoidRootPart.Position)
		if not onscreen then
			SetDrawingsVisible(id, false)
			continue
		end

		local boneCount = s.RigType == "R6" and #R6_BONES or #R15_BONES
		local d = GetOrCreateDrawings(id, boneCount)

		-- Name label
		local nameLabel = d.Texts.Name
		local newPos = Vector2.new(pos.X, pos.Y)
		if nameLabel.Position ~= newPos then nameLabel.Position = newPos end
		if nameLabel.Text ~= s.CharacterName then nameLabel.Text = s.CharacterName end
		if not nameLabel.Visible then nameLabel.Visible = true end

		-- Skeleton
		if showSkeleton and s.RigType ~= nil then
			UpdateSkeleton(id, s, d)
		else
			SetSkeletonVisible(id, false)
		end
	end
end

local function ResolveRig(Character)
	-- R15 has LowerTorso, R6 has Torso
	if Character:FindFirstChild("LowerTorso") then
		return "R15"
	elseif Character:FindFirstChild("Torso") then
		return "R6"
	end
	return nil
end

local function ResolveLimbs(Character, rigType)
	local limbs = {}
	local parts = rigType == "R6" and {
		"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"
	} or {
		"Head", "UpperTorso", "LowerTorso",
		"LeftUpperArm", "LeftLowerArm", "LeftHand",
		"RightUpperArm", "RightLowerArm", "RightHand",
		"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
		"RightUpperLeg", "RightLowerLeg", "RightFoot",
	}
	for _, name in ipairs(parts) do
		limbs[name] = Character:FindFirstChild(name)
	end
	return limbs
end

local function OnCharacterAdded(player, PlayerStruct, Character)
	PlayerStruct.Character = Character
	PlayerStruct.CharacterName = Character.Name
	PlayerStruct.HumanoidRootPart = nil
	PlayerStruct.RigType = nil
	PlayerStruct.Limbs = {}

	local hrp = Character:FindFirstChild("HumanoidRootPart")
		or Character:WaitForChild("HumanoidRootPart", 10)
	if not hrp then return end

	local rigType = ResolveRig(Character)
	PlayerStruct.HumanoidRootPart = hrp
	PlayerStruct.RigType = rigType
	PlayerStruct.Limbs = rigType and ResolveLimbs(Character, rigType) or {}
end

local function OnCharacterRemoving(PlayerStruct)
	PlayerStruct.Character = nil
	PlayerStruct.CharacterName = nil
	PlayerStruct.HumanoidRootPart = nil
	PlayerStruct.RigType = nil
	PlayerStruct.Limbs = {}
end

function this.PopulatePlayer(player)
	local PlayerStruct = {
		Character = nil,
		CharacterName = nil,
		HumanoidRootPart = nil,
		RigType = nil,
		Limbs = {},
	}

	local c = player.CharacterAdded:Connect(function(Character)
		OnCharacterAdded(player, PlayerStruct, Character)
	end)
	local uc = player.CharacterRemoving:Connect(function()
		OnCharacterRemoving(PlayerStruct)
	end)
	PlayerStruct.CharacterAdded = c
	PlayerStruct.CharacterRemoving = uc

	if player.Character then
		task.spawn(OnCharacterAdded, player, PlayerStruct, player.Character)
	end

	this.Drawings[player.UserId] = {
		Box = nil,
		Lines = {},
		Texts = {}
	}
	this.PlayerList[player.UserId] = PlayerStruct
end

function this.CleanupPlayer(player)
	if this.Drawings[player.UserId] then
		if this.Drawings[player.UserId].Box then
			this.Drawings[player.UserId].Box:Remove()
		end
		for _, d in pairs(this.Drawings[player.UserId].Texts) do
			d:Remove()
		end
		for _, d in ipairs(this.Drawings[player.UserId].Lines) do
			d:Remove()
		end
		this.Drawings[player.UserId] = nil
	end
	if this.PlayerList[player.UserId] then
		this.PlayerList[player.UserId].CharacterAdded:Disconnect()
		this.PlayerList[player.UserId].CharacterRemoving:Disconnect()
		this.PlayerList[player.UserId] = nil
	end
end

function this.StartThreads()
	for _, player in this.Services.Players:GetPlayers() do
		this.PopulatePlayer(player)
	end
	this.PlayerConnected = this.Services.Players.PlayerAdded:Connect(this.PopulatePlayer)
	this.PlayerRemoving  = this.Services.Players.PlayerRemoving:Connect(this.CleanupPlayer)

	this._RenderThread = this.Services.RunService.RenderStepped:Connect(function(dt)
		if this.Variables.ESPMasterToggle then
			HandleEsp()
		else
			for id, _ in pairs(this.PlayerList) do
				SetDrawingsVisible(id, false)
			end
		end
	end)

	this._LogicThread = task.spawn(function()
		while task.wait() do

		end
	end)
end

function this.Shutdown()
	for userId, _ in this.PlayerList do
		this.PlayerList[userId].CharacterAdded:Disconnect()
		this.PlayerList[userId].CharacterRemoving:Disconnect()
	end
	this.PlayerList = {}
	this.PlayerConnected:Disconnect()
	this.PlayerRemoving:Disconnect()
	this._RenderThread:Disconnect()
	task.cancel(this._LogicThread)
end

return this