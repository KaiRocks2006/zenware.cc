return function(Context)
	local Players = Context.Players
	local Workspace = Context.Workspace
	local RunService = Context.RunService
	local Fields = Context.Fields
	local Values = Context.Values
	local Drawing = Drawing
	local HttpService = game:GetService("HttpService")

	local Local = {
		Player = Players.LocalPlayer,
		Camera = function()
			return Workspace.CurrentCamera
		end,
	}

	local Drawings = {}
	local PlayerCache = {}

	local function FetchPlayerData(character)
		local cached = PlayerCache[character]
		if cached then
			return cached
		end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		local data = { Player = player }
		local armorStr = player:GetAttribute("Armor")
		if armorStr then
			local ok, armor = pcall(HttpService.JSONDecode, HttpService, armorStr)
			if ok and armor then
				data.Health = armor.Health
				data.ArmorType = armor.Type
			end
		end
		local weaponStr = player:GetAttribute("CurrentEquipped")
		if weaponStr then
			local ok, weapon = pcall(HttpService.JSONDecode, HttpService, weaponStr)
			if ok and weapon then
				data.WeaponName = weapon.Name
				data.WeaponSkin = weapon.Skin
			end
		end
		data.Team = player:GetAttribute("Team")
		data.Money = player:GetAttribute("Money")
		PlayerCache[character] = data
		return data
	end

	local function ClearPlayerCache()
		for char in pairs(PlayerCache) do
			if not char.Parent then
				PlayerCache[char] = nil
			end
		end
	end

	local BloxValues = {
		ShowHealth = true,
		ShowWeapon = true,
		ShowArmor = true,
	}

	local BloxSection = Context.Tabs.Esp:CreateSection({ Name = "BloxStrike", Side = "Right" })
	BloxSection:AddToggle({ Name = "Health", Side = "Right", Value = true, Callback = function(v) BloxValues.ShowHealth = v end })
	BloxSection:AddToggle({ Name = "Weapon", Side = "Right", Value = true, Callback = function(v) BloxValues.ShowWeapon = v end })
	BloxSection:AddToggle({ Name = "Armor", Side = "Right", Value = true, Callback = function(v) BloxValues.ShowArmor = v end })

	local function GetAliveCharacters()
		local chars = {}
		local charsFolder = Workspace:FindFirstChild("Characters")
		if charsFolder then
			for _, team in ipairs({ "Terrorists", "Counter-Terrorists" }) do
				local folder = charsFolder:FindFirstChild(team)
				if folder then
					for _, char in folder:GetChildren() do
						if char:FindFirstChild("Humanoid") then
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
			Name = Drawing.new("Text"),
			Health = Drawing.new("Text"),
			Weapon = Drawing.new("Text"),
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
				PlayerCache[char] = nil
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
		PlayerCache = {}
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
		return cx - width / 2, cy - height / 2, width, height
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

	local TeamColors = {
		Terrorists = Color3.fromRGB(220, 60, 60),
		CounterTerrorists = Color3.fromRGB(60, 120, 220),
	}

	local function TeamColor(team)
		if team == "Terrorists" then
			return TeamColors.Terrorists
		elseif team == "Counter-Terrorists" then
			return TeamColors.CounterTerrorists
		end
		return Color3.new(1, 1, 1)
	end

	Context.Library.signals[#Context.Library.signals + 1] = RunService.RenderStepped:Connect(function()
		local ok, err = pcall(function()
			PurgeDead()
			ClearPlayerCache()

			if not Values.Esp.GlobalEnabled then
				for _, set in pairs(Drawings) do
					HideSet(set)
				end
				return
			end

			local c = Local.Camera()
			if not c then
				return
			end

			local mid = c.ViewportSize.X / 2
			local bot = c.ViewportSize.Y
			local characters = GetAliveCharacters()

			for _, character in ipairs(characters) do
				local hum, rp, head = GetParts(character)
				if not hum then
					if Drawings[character] then
						HideSet(Drawings[character])
					end
				else
					local pos, onScreen = c:WorldToViewportPoint(rp.Position)
					if not onScreen then
						if Drawings[character] then
							HideSet(Drawings[character])
						end
					else
						local set = GetSet(character)
						local pdata = FetchPlayerData(character)
						local tcolor = pdata and TeamColor(pdata.Team) or Color3.new(1, 1, 1)

						set.Tracer.To = Vector2.new(pos.X, pos.Y)

						if Values.Esp.TracersEnabled then
							DrawTracer(set, Vector2.new(mid, bot), tcolor)
						else
							set.Tracer.Visible = false
						end

						if Values.Esp.BoxesEnabled then
							local bx, by, bw, bh = DrawBox(set.Box, c, hum, rp, head, tcolor)

							set.Name.Font = 3
							set.Health.Font = 3
							set.Weapon.Font = 3

							if pdata then
								set.Name.Text = character.Name
								set.Name.Position = Vector2.new(bx + bw / 2, by - 16)
								set.Name.Color = tcolor
								set.Name.Size = 13
								set.Name.Center = true
								set.Name.Outline = true
								set.Name.Visible = true

								if BloxValues.ShowHealth and pdata.Health then
									local hpColor = pdata.Health > 50 and Color3.fromRGB(80, 220, 80) or Color3.fromRGB(220, 80, 80)
									local hpText = "HP: " .. math.floor(pdata.Health)
									if BloxValues.ShowArmor and pdata.ArmorType then
										local icon = pdata.ArmorType == "Kevlar + Helmet" and "HK" or "K"
										hpText = hpText .. " [" .. icon .. "]"
									end
									set.Health.Text = hpText
									set.Health.Position = Vector2.new(bx + bw / 2, by + bh + 2)
									set.Health.Color = hpColor
									set.Health.Size = 12
									set.Health.Center = true
									set.Health.Outline = true
									set.Health.Visible = true
								else
									set.Health.Visible = false
								end

								if BloxValues.ShowWeapon and pdata.WeaponName then
									set.Weapon.Text = pdata.WeaponName
									set.Weapon.Position = Vector2.new(bx + bw / 2, by + bh + 16)
									set.Weapon.Color = Color3.fromRGB(200, 200, 200)
									set.Weapon.Size = 11
									set.Weapon.Center = true
									set.Weapon.Outline = true
									set.Weapon.Visible = true
								else
									set.Weapon.Visible = false
								end
							else
								set.Name.Text = character.Name
								set.Name.Position = Vector2.new(bx + bw / 2, by - 16)
								set.Name.Color = tcolor
								set.Name.Size = 13
								set.Name.Center = true
								set.Name.Outline = true
								set.Name.Visible = true
								set.Health.Visible = false
								set.Weapon.Visible = false
							end
						else
							set.Box.Visible = false
							set.Name.Visible = false
							set.Health.Visible = false
							set.Weapon.Visible = false
						end
					end
				end
			end
		end)
		if not ok then
			warn("zenware bloxstrike error: " .. tostring(err))
		end
	end)
end
