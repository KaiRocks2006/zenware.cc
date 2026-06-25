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
		local charsFolder = Workspace:FindFirstChild("Characters")
		if charsFolder then
			for _, team in ipairs({"Terrorists", "Counter-Terrorists"}) do
				local folder = charsFolder:FindFirstChild(team)
				if folder then
					for _, char in folder:GetChildren() do
						if char ~= Local.Player.Character then
							chars[#chars + 1] = char
						end
					end
				end
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

	local function DrawBox(box, c, hum, rp, head, color)
		local headUp = head.CFrame.UpVector
		local headTop = head.Position + headUp * (head.Size.Y * 0.5)
		local rootUp = rp.CFrame.UpVector
		local footPos = rp.Position - rootUp * (rp.Size.Y * 0.5 + hum.HipHeight)

		local top = c:WorldToViewportPoint(headTop)
		local bottom = c:WorldToViewportPoint(footPos)
		local height = math.abs(bottom.Y - top.Y)
		local width = height * 0.55
		local cx = (top.X + bottom.X) / 2
		local cy = (top.Y + bottom.Y) / 2

		box.Thickness = 1
		box.Filled = false
		box.Transparency = 1
		box.Position = Vector2.new(cx - width / 2, cy - height / 2)
		box.Size = Vector2.new(width, height)
		box.Color = color
		box.Visible = true
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

	local DiagnosticTick = 0

	Context.Library.signals[#Context.Library.signals + 1] = RunService.RenderStepped:Connect(function()
		local ok, err = pcall(function()
			PurgeDead()

			if not Values.Esp.GlobalEnabled then
				for _, set in pairs(Drawings) do
					HideSet(set)
				end
				return
			end

			local c = Local.Camera()
			if not c then return end

			local mid = c.ViewportSize.X / 2
			local bot = c.ViewportSize.Y

			local boxColor = Fields.Esp.BoxesColor:Get()
			local tracerColor = Fields.Esp.TracersColor:Get()

			local characters = GetAliveCharacters()

			for _, character in ipairs(characters) do
				local hum, rp, head = GetParts(character)
				if not hum then
					if Drawings[character] then HideSet(Drawings[character]) end
				else
					local pos, onScreen = c:WorldToViewportPoint(rp.Position)
					if not onScreen then
						if Drawings[character] then HideSet(Drawings[character]) end
					else
						local set = GetSet(character)
						set.Tracer.To = Vector2.new(pos.X, pos.Y)

						if Values.Esp.TracersEnabled then
							DrawTracer(set, Vector2.new(mid, bot), tracerColor)
						else
							set.Tracer.Visible = false
						end

						if Values.Esp.BoxesEnabled then
							DrawBox(set.Box, c, hum, rp, head, boxColor)
						else
							set.Box.Visible = false
						end
					end
				end
			end

			DiagnosticTick = DiagnosticTick + 1
			if DiagnosticTick % 120 == 0 then
				warn("zenware bloxstrike: " .. #Players:GetPlayers() .. " players, " .. #characters .. " chars")
				for _, character in ipairs(characters) do
					local hum, rp, head = GetParts(character)
					warn("  " .. character.Name .. " hum=" .. tostring(hum ~= nil) .. " rp=" .. tostring(rp ~= nil) .. " head=" .. tostring(head ~= nil))
				end
			end
		end)
		if not ok then
			warn("zenware bloxstrike RenderStepped error: " .. tostring(err))
			warn(debug.traceback())
		end
	end)
end
