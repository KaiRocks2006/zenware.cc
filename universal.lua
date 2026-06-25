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

local function GetBox(UserId)
	if this.Drawings[UserId].Box then
		return this.Drawings[UserId].Box
	else
		local box = Drawing.new("Square")
		box.Thickness = 1
		box.Visible = false
		this.Drawings[UserId].Box = box
		return box
	end
end

local function NewText(UserId, Text, Size, Position, Color, Center)
	local t = Drawing.new("Text")
	t.Text = Text
	t.Size = Size
	t.Position = Position
	t.Color = Color
	t.Center = Center or false
	table.insert(this.Drawings[UserId].Texts, t)
	return t
end

local function NewLine(UserId, From, To, Thickness, Color)
	local l = Drawing.new("Line")
	l.From = From
	l.To = To
	l.Thickness = Thickness
	l.Color = Color
	table.insert(this.Drawings[UserId].Lines, l)
	return l
end

local function HandleEsp()
	for id, s in pairs(this.PlayerList) do
		if s.Character == nil or id == this.Services.Players.LocalPlayer.UserId then continue end
		local HumanoidRootPart = s.Character:FindFirstChild("HumanoidRootPart")
		if HumanoidRootPart == nil then continue end
		local box = GetBox(id)
		local pos, onscreen = this.Services.Workspace.CurrentCamera:WorldToViewportPoint(HumanoidRootPart.Position)
		if onscreen then
			NewText(id, s.Character.Name, 12, Vector2.new(pos.X, pos.Y), Color3.new(1, 1, 1), true)
		end
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
		for _, d in this.Drawings[player.UserId].Lines do
			d:Remove()
		end
		for _, d in this.Drawings[player.UserId].Texts do
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

function this.CleanDrawings()
	for id, _ in pairs(this.PlayerList) do
		if this.Drawings[id] then
			for _, d in this.Drawings[id].Lines do
				d:Remove()
			end
			table.clear(this.Drawings[id].Lines)
			for _, d in this.Drawings[id].Texts do
				d:Remove()
			end
			table.clear(this.Drawings[id].Texts)
		end
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
		this.CleanDrawings()
		if this.Variables.ESPMasterToggle then HandleEsp() end
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