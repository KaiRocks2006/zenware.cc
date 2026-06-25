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
	ESPMasterToggle = false
}

--[[
	{
		[UserId] = {
			Box (Drawing Object),
			Lines { (Drawing Object) },
			Texts { (Drawing Object) },
		}
	}
]]--
this.Drawings = {}

this._RenderThread = nil
this._LogicThread = nil

-- Cached values to avoid repeated lookups in the render loop
local _localId = nil
local _camera = nil

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

	-- Keep camera reference up to date if it changes
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
	-- Aim
	t.Aim.Sections["Toggles"] = t.Aim.Tab:CreateSection({ Name = "Toggles", Side = "Left" })
	t.Aim.Sections["Prediction"] = t.Aim.Tab:CreateSection({ Name = "Prediction", Side = "Right" })
	t.Aim.Sections["Precision"] = t.Aim.Tab:CreateSection({ Name = "Precision", Side = "Right" })

	-- Visuals
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
end

--[[
	PlayerList is a table with the following format:

	PlayerList = {
		[UserId] = {
			Character (Model | nil),
			CharacterName (string | nil), -- cached to avoid indexing every frame
			HumanoidRootPart (BasePart | nil), -- cached to avoid FindFirstChild every frame
			CharacterAdded (Connection),
			CharacterRemoving (Connection)
		}
	}
]]--
this.PlayerList = {}

this.PlayerConnected = nil
this.PlayerRemoving = nil

local function GetOrCreateDrawings(UserId)
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

local function HandleEsp()
	for id, s in pairs(this.PlayerList) do
		-- Skip local player and players without a character or root part
		if id == _localId or s.HumanoidRootPart == nil then
			SetDrawingsVisible(id, false)
			continue
		end

		local pos, onscreen = _camera:WorldToViewportPoint(s.HumanoidRootPart.Position)
		if not onscreen then
			SetDrawingsVisible(id, false)
			continue
		end

		local d = GetOrCreateDrawings(id)
		local nameLabel = d.Texts.Name
		local newPos = Vector2.new(pos.X, pos.Y)

		if nameLabel.Position ~= newPos then
			nameLabel.Position = newPos
		end
		-- Use cached name to avoid indexing Character every frame
		if nameLabel.Text ~= s.CharacterName then
			nameLabel.Text = s.CharacterName
		end
		if not nameLabel.Visible then
			nameLabel.Visible = true
		end
	end
end

local function OnCharacterAdded(player, PlayerStruct, Character)
	PlayerStruct.Character = Character
	PlayerStruct.CharacterName = Character.Name
	-- Wait for HumanoidRootPart to exist, then cache it
	local hrp = Character:FindFirstChild("HumanoidRootPart")
		or Character:WaitForChild("HumanoidRootPart", 10)
	PlayerStruct.HumanoidRootPart = hrp
end

local function OnCharacterRemoving(PlayerStruct)
	PlayerStruct.Character = nil
	PlayerStruct.CharacterName = nil
	PlayerStruct.HumanoidRootPart = nil
end

function this.PopulatePlayer(player)
	local PlayerStruct = {}
	PlayerStruct.Character = nil
	PlayerStruct.CharacterName = nil
	PlayerStruct.HumanoidRootPart = nil

	local c = player.CharacterAdded:Connect(function(Character)
		OnCharacterAdded(player, PlayerStruct, Character)
	end)
	local uc = player.CharacterRemoving:Connect(function()
		OnCharacterRemoving(PlayerStruct)
	end)
	PlayerStruct.CharacterAdded = c
	PlayerStruct.CharacterRemoving = uc

	-- Handle already-spawned character
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
	this.PlayerRemoving = this.Services.Players.PlayerRemoving:Connect(this.CleanupPlayer)

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