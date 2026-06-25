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

function this.Start(context)
	this.Window = context.Window
	this.Library = context.Library
	this.Services = {
		Players = context.Players,
		Workspace = context.Workspace,
		RunService = context.RunService,
		HttpService = context.HttpService,
	}

	this.InitTabs(this.Window)
	this.Library.UnloadCallback = this.Shutdown
	this.StartThreads()
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
			CharacterAdded (Connection),
			CharacterRemoving (Connection)
		}
	}
]]--
this.PlayerList = {}

this.PlayerConnected = nil
this.PlayerRemoving = nil

-- Creates drawings for a player if they don't exist yet, returns them
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
	if d.Box then d.Box.Visible = visible end
	for _, text in pairs(d.Texts) do
		text.Visible = visible
	end
	for _, line in ipairs(d.Lines) do
		line.Visible = visible
	end
end

local function HandleEsp()
	local localId = this.Services.Players.LocalPlayer.UserId
	local camera = this.Services.Workspace.CurrentCamera

	for id, s in pairs(this.PlayerList) do
		if id == localId or s.Character == nil then
			SetDrawingsVisible(id, false)
			continue
		end

		local HumanoidRootPart = s.Character:FindFirstChild("HumanoidRootPart")
		if HumanoidRootPart == nil then
			SetDrawingsVisible(id, false)
			continue
		end

		local pos, onscreen = camera:WorldToViewportPoint(HumanoidRootPart.Position)
		if not onscreen then
			SetDrawingsVisible(id, false)
			continue
		end

		local d = GetOrCreateDrawings(id)

		-- Update name label
		local nameLabel = d.Texts.Name
		nameLabel.Text = s.Character.Name
		nameLabel.Position = Vector2.new(pos.X, pos.Y)
		nameLabel.Visible = true
	end
end

function this.PopulatePlayer(player)
	local PlayerStruct = {}
	PlayerStruct["Character"] = player.Character
	local c = player.CharacterAdded:Connect(function(Character)
		PlayerStruct["Character"] = Character
	end)
	local uc = player.CharacterRemoving:Connect(function()
		PlayerStruct["Character"] = nil
	end)
	PlayerStruct["CharacterAdded"] = c
	PlayerStruct["CharacterRemoving"] = uc
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

	-- For rendering
	this._RenderThread = this.Services.RunService.RenderStepped:Connect(function(dt)
		if this.Variables.ESPMasterToggle then
			HandleEsp()
		else
			-- Hide all drawings when ESP is toggled off
			for id, _ in pairs(this.PlayerList) do
				SetDrawingsVisible(id, false)
			end
		end
	end)

	-- For handling main logic
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