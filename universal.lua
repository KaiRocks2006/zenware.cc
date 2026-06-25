local this = {}

--[[

	Reference Context:
	Context = {
		["Window"] = Window, -- PepsiLib Window
		["Players"] = Players,
		["Workspace"] = Workspace,
		["RunService"] = RunService,
		["HttpService"] = HttpService,
	}

]]--

this.Window = nil
this.Tabs = {}
this.Services = {}
this.Variables = {}

--[[
	{
		[UserId] = {
			Box (Drawing Object),
			Lines { (Drawing Object) },
			Texts { (Drawing Object) },
		}
	}
]]--
this.Drawings = {
	
}

this._RenderThread = nil
this._LogicThread = nil

function this.Start(context)
	this.Window = context.Window
	this.Services = {
		Players = context.Players,
		Workspace = context.Workspace,
		RunService = context.RunService,
		HttpService = context.HttpService,
	}
	this.InitTabs(this.Window)
end

function this.InitTabs(w)
	this.Tabs = {
		Aim = {
			Tab = w:CreateTab({ Name = "Aim" }),
			Sections = {}
		},
		Visuals = {
			Tab = w:CreateTab({ Name = "Visuals" }),
			Sections = {}
		},
		Exploits = {
			Tab = w:CreateTab({ Name = "Exploits" }),
			Sections = {}
		},
		World = {
			Tab = w:CreateTab({ Name = "World" }),
			Sections = {}
		},
	}
	this.InitSections(this.Tabs)
end

function this.InitSections(t)
	t.Aim.Sections["Toggles"] = t.Aim.Tab:CreateSection({ Name = "Toggles", Side = "Left" })
	t.Aim.Sections["Prediction"] = t.Aim.Tab:CreateSection({ Name = "Prediction", Side = "Right" })
	t.Aim.Sections["Precision"] = t.Aim.Tab:CreateSection({ Name = "Precision", Side = "Right" })
	this.InitFields(t)
end

function this.InitFields(t)
	-- Initialize elements of sections
	this.StartThreads()
end

--[[
	PlayerList is a table with the following format:

	PlayerList = {
		[UserId] = {
			Character (Model | nil),
			CharacterAdded (Connection), -- If these are ever nil while the UserId is populated, we have a serious issue
			CharacterRemoving (Connection)
		}
	}
]]--
this.PlayerList = {}

this.PlayerConnected = nil
this.PlayerRemoving = nil

function this.PopulatePlayer(player)
	local PlayerStruct = {}
	PlayerStruct["Character"] = player.Character
	local c = player.CharacterAdded:Connect(function(Character)
		PlayerStruct["Character"] = Character
	end)
	local uc = player.CharacterRemoving:Connect(function(Character)
		PlayerStruct["Character"] = nil
	end)
	PlayerStruct["CharacterAdded"] = c
	PlayerStruct["CharacterRemoving"] = uc
	this.PlayerList[player.UserId] = PlayerStruct
end

function this.CleanupPlayer(player)
	if this.Drawings[player.UserId] then
		this.Drawings[player.UserId].Box:Remove()
		for _, d in this.Drawings[player.UserId].Lines do
			d:Remove()
		end
		for _, d in this.Drawings[player.UserId].Texts do
			d:Remove()
		end
		this.Drawings[player.UserId] = nil
	end
	this.PlayerList[player.UserId].CharacterAdded:Disconnect()
	this.PlayerList[player.UserId].CharacterRemoving:Disconnect()
end

function this.StartThreads()
	for _, player in this.Services.Players:GetPlayers() do
		this.PopulatePlayer(player)
	end
	this.PlayerConnected = this.Services.Players.PlayerAdded:Connect(this.PopulatePlayer)
	this.PlayerRemoving = this.Services.Players.PlayerRemoving:Connect(this.CleanupPlayer)

	-- For rendering
	this._RenderThread = this.Services.RunService.RenderStepped:Connect(function(dt)

	end)

	-- For handling main logic
	this._LogicThread = task.spawn(function()

	end)
end

function this.Shutdown()
	for userId, _ in this.PlayerList do
		this.PlayerList[userId].CharacterAdded:Disconnect()
		this.PlayerList[userId].CharacterRemoving:Disconnect()
  	end
	this.PlayerConnected:Disconnect()
	this.PlayerRemoving:Disconnect()
end

return this