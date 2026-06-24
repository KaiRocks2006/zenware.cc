return function(Context)
	local Players = Context.Players
	local Workspace = Context.Workspace
	local RunService = Context.RunService
	local Fields = Context.Fields
	local Values = Context.Values
	local Drawing = Drawing

	local Local = {
		Player = Players.LocalPlayer,
		Camera = function()
			return Workspace.CurrentCamera
		end,
	}

	local Drawings = {}

	local function GetAliveCharacters()
		local chars = {}
		for _, player in Players:GetPlayers() do
			local c = player.Character
			if c then
				chars[#chars + 1] = c
			end
		end
		return chars
	end

	local function GetParts(character)
		local hum = character:FindFirstChild("Humanoid")
		local rp = character:FindFirstChild("HumanoidRootPart")
		local head = character:FindFirstChild("Head") or character:FindFirstChild("UpperTorso")
		if hum and rp and head then
			return hum, rp, head
		end
	end

	local function GetSet(character)
		local set = Drawings[character]
		if set then
			return set
		end
		set = {
			Tracer = Drawing.new("Line"),
			Box = Drawing.new("Square"),
		}
		Drawings[character] = set
		return set
	end

	local function HideSet(set)
		for _, d in pairs(set) do
			d.Visible = false
		end
	end

	local function PurgeDead()
		for char, set in pairs(Drawings) do
			if not char.Parent then
				for _, d in pairs(set) do
					d:Remove()
				end
				Drawings[char] = nil
			end
		end
	end

	local function DestroyAll()
		for _, set in pairs(Drawings) do
			for _, d in pairs(set) do
				pcall(function()
					d:Remove()
				end)
			end
		end
		Drawings = {}
	end

	local function DrawBox(set, character, humanoid, rootpart, head, color)
		local headUp = head.CFrame.UpVector
		local headTop = head.Position + headUp * (head.Size.Y * 0.5)
		local rootUp = rootpart.CFrame.UpVector
		local footPos = rootpart.Position - rootUp * (rootpart.Size.Y * 0.5 + humanoid.HipHeight)
		local c = Local.Camera()

		local top = c:WorldToViewportPoint(headTop)
		local bottom = c:WorldToViewportPoint(footPos)
		local height = math.abs(bottom.Y - top.Y)
		local width = height * 0.55
		local cx = (top.X + bottom.X) / 2
		local cy = (top.Y + bottom.Y) / 2

		set.Box.Thickness = 1
		set.Box.Filled = false
		set.Box.Transparency = 1
		set.Box.Position = Vector2.new(cx - width / 2, cy - height / 2)
		set.Box.Size = Vector2.new(width, height)
		set.Box.Color = color
		set.Box.Visible = true
	end

	local function DrawTracer(set, origin, color)
		set.Tracer.From = origin
		set.Tracer.Color = color
		set.Tracer.Visible = true
	end

	local prev = Context.Library.UnloadCallback
	Context.Library.UnloadCallback = function(...)
		DestroyAll()
		if prev then
			prev(...)
		end
	end

	Context.Library.signals[#Context.Library.signals + 1] = RunService.RenderStepped:Connect(function()
		PurgeDead()

		if not Values.Esp.GlobalEnabled then
			for _, set in pairs(Drawings) do
				HideSet(set)
			end
			return
		end

		local boxColor = Fields.Esp.BoxesColor:Get()
		local tracerColor = Fields.Esp.TracersColor:Get()
		local c = Local.Camera()
		local mid = c.ViewportSize.X / 2
		local bot = c.ViewportSize.Y

		for _, character in ipairs(GetAliveCharacters()) do
			local hum, rp, head = GetParts(character)
			if not hum then
				if Drawings[character] then
					HideSet(Drawings[character])
				end
				continue
			end

			local pos, onScreen = c:WorldToViewportPoint(rp.Position)
			if not onScreen then
				if Drawings[character] then
					HideSet(Drawings[character])
				end
				continue
			end

			local set = GetSet(character)
			set.Tracer.To = Vector2.new(pos.X, pos.Y)

			if Values.Esp.TracersEnabled then
				DrawTracer(set, Vector2.new(mid, bot), tracerColor)
			else
				set.Tracer.Visible = false
			end

			if Values.Esp.BoxesEnabled then
				DrawBox(set, character, hum, rp, head, boxColor)
			else
				set.Box.Visible = false
			end
		end
	end)
end
