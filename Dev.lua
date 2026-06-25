local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/Stratxgy/PepsiUI/refs/heads/main/pepsi.lua'))()
local Drawing = Drawing

local Values = {
    Aimbot = false,
    AimKeybind = "None",
    TargetMode = "Crosshair",
    AimPart = "Head",
    Smoothness = 0,
    FOV = 90,
    ShowFOV = false,
    AimTeamCheck = true,
    Wallcheck = true,
    BoxESP = false,
    Tracers = false,
    SkeletonESP = false,
    TeamCheck = false,
    SelectedFlags = {},
    BoxColor = Color3.new(1, 1, 1),
    SkeletonColor = Color3.new(1, 1, 1),
    CrouchBugValue = 0,
    ESPFlags = {
        "Name", "Armor", "Health", "HeldGun",
        "Scoped", "Crouched", "Climbing", "HasKit", "Team"
    }
}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local function GetCharacters()
    local cs = {}
    local CharacterFolder = Workspace:FindFirstChild("Characters")
    if CharacterFolder == nil then
        error("Hey, the game seems to be hiding the Characters folder from executors")
    end
    local T = CharacterFolder:FindFirstChild("Terrorists")
    local CT = CharacterFolder:FindFirstChild("Counter-Terrorists")
    if CT == nil or T == nil then
        error("One or both of the team folders are nil")
    end
    for _, v in CT:GetChildren() do table.insert(cs, v) end
    for _, v in T:GetChildren() do table.insert(cs, v) end
    return cs
end

local PlayerFlags = {
    Armor = "Armor", Team = "Team", HasDefuser = "HasDefuseKit",
    HasRescuer = "HasRescueKit", IsClimbing = "IsClimbing",
    MinIncome = "MinimumNextRoundIncome", Money = "Money", Ping = "Ping",
    CurrentEquipped = "CurrentEquipped", IsCrouched = "IsCrouching",
    CrouchCamOffset = "CrouchCameraOffset", DefaultCamOffset = "DefaultCameraOffset",
}

local BloxStrike = {}
BloxStrike.Weapon = {}
BloxStrike.Weapon.__index = BloxStrike.Weapon
function BloxStrike.Weapon:HasAmmo() return self.Capacity ~= nil and self.Rounds ~= nil end
function BloxStrike.Weapon:GetName() return self.Name or "Unknown" end
function BloxStrike.Weapon:GetSkin() return self.Skin or "Unknown" end
function BloxStrike.Weapon.new(weaponTable)
    local self = weaponTable or {}
    setmetatable(self, BloxStrike.Weapon)
    return self
end

local UserInputService = game:GetService("UserInputService")

local Window = Library:CreateWindow({
    Name = "zenware.cc",
    Themeable = { Name = "Settings", Image = "nil", Info = "Script by zenware team", Credit = false },
    Background = "",
    Theme = [[{"__Designer.Background.UseBackgroundImage":false}]]
})

local Tabs = {
    Aim      = Window:CreateTab({ Name = "Aim"      }),
    Visuals  = Window:CreateTab({ Name = "Visuals"  }),
    Movement = Window:CreateTab({ Name = "Movement" }),
}

local Sections = {
    Aim = {
        Left  = Tabs.Aim:CreateSection({ Name = "Aimbot",   Side = "Left"  }),
        Right = Tabs.Aim:CreateSection({ Name = "Settings", Side = "Right" }),
    },
    Visuals = {
        Left  = Tabs.Visuals:CreateSection({ Name = "ESP",    Side = "Left"  }),
        Right = Tabs.Visuals:CreateSection({ Name = "Colors", Side = "Right" }),
    },
    Movement = {
        Left = Tabs.Movement:CreateSection({ Name = "Bugs", Side = "Left" }),
    }
}

local Fields = {
    Aim = {
        Left = {
            Enabled = Sections.Aim.Left:AddToggle({
                Name = "Aimbot",
                Callback = function(v) Values.Aimbot = v end
            }),
            TargetMode = Sections.Aim.Left:AddDropdown({
                Name = "Target Mode",
                List = { "Crosshair", "Distance" },
                Callback = function(v) Values.TargetMode = v end
            }),
            AimPart = Sections.Aim.Left:AddDropdown({
                Name = "Aim Part",
                List = { "Head", "HumanoidRootPart" },
                Callback = function(v) Values.AimPart = v end
            }),
            Keybind = Sections.Aim.Left:AddDropdown({
                Name = "Keybind",
                List = { "None", "Left Alt", "Right Click" },
                Callback = function(v) Values.AimKeybind = v end
            }),
        },
        Right = {
            Smoothness = Sections.Aim.Right:AddSlider({
                Name = "Smoothness",
                Min = 0, Max = 1, Pre = 0.01, Default = 0,
                Callback = function(v) Values.Smoothness = v end
            }),
            FOV = Sections.Aim.Right:AddSlider({
                Name = "FOV",
                Min = 1, Max = 180, Pre = 1, Default = 90,
                Callback = function(v) Values.FOV = v end
            }),
            ShowFOV = Sections.Aim.Right:AddToggle({
                Name = "Show FOV",
                Value = false,
                Callback = function(v) Values.ShowFOV = v end
            }),
            TeamCheck = Sections.Aim.Right:AddToggle({
                Name = "Team Check",
                Value = true,
                Callback = function(v) Values.AimTeamCheck = v end
            }),
            Wallcheck = Sections.Aim.Right:AddToggle({
                Name = "Wallcheck",
                Value = true,
                Callback = function(v) Values.Wallcheck = v end
            }),
        }
    },
    Visuals = {
        Left = {
            BoxESP = Sections.Visuals.Left:AddToggle({
                Name = "Box ESP", Side = "Left",
                Callback = function(v) Values.BoxESP = v end
            }),
            SkeletonESP = Sections.Visuals.Left:AddToggle({
                Name = "Skeleton ESP", Side = "Left",
                Callback = function(v) Values.SkeletonESP = v end
            }),
            TeamCheck = Sections.Visuals.Left:AddToggle({
                Name = "Team Check", Side = "Left",
                Callback = function(v) Values.TeamCheck = v end
            }),
            Flags = Sections.Visuals.Left:AddDropdown({
                Name = "Flags",
                List = Values.ESPFlags,
                MultiSelect = true,
                Callback = function(v) Values.SelectedFlags = v end
            }),
        },
        Right = {
            BoxColor = Sections.Visuals.Right:AddColorpicker({
                Name = "Box Color",
                Default = Color3.new(1, 1, 1),
                Callback = function(v) Values.BoxColor = v end
            }),
            SkeletonColor = Sections.Visuals.Right:AddColorpicker({
                Name = "Skeleton Color",
                Default = Color3.new(1, 1, 1),
                Callback = function(v) Values.SkeletonColor = v end
            }),
        }
    },
    Movement = {
        Left = {
            CrouchBug = Sections.Movement.Left:AddSlider({
                Name = "CrouchBug",
                Min = -20,
                Max = 20,
                Default = -1.4,
                Decimals = 1,
                Callback = function(v)
                    Values.CrouchBugValue = v
                    LocalPlayer:SetAttribute("CrouchCameraOffset", Vector3.new(0, v, 0))
                end
            }),
        }
    }
}

local BoneConnections = {
    {"Head",          "UpperTorso"},
    {"UpperTorso",    "LowerTorso"},
    {"UpperTorso",    "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"UpperTorso",    "LeftUpperArm"},
    {"LeftUpperArm",  "LeftLowerArm"},
    {"LeftLowerArm",  "LeftHand"},
    {"LowerTorso",    "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
    {"LowerTorso",    "LeftUpperLeg"},
    {"LeftUpperLeg",  "LeftLowerLeg"},
    {"LeftLowerLeg",  "LeftFoot"},
}

local TeamColors = {
    ["Counter-Terrorists"] = Color3.new(0.2, 0.5, 1),
    ["Terrorists"]         = Color3.new(1, 0.3, 0.3),
}

local function GetTeamFolder(char)
    local CharacterFolder = Workspace:FindFirstChild("Characters")
    if not CharacterFolder then return nil end
    for _, folder in ipairs(CharacterFolder:GetChildren()) do
        if folder:FindFirstChild(char.Name) then
            return folder.Name
        end
    end
    return nil
end

local function GetESPColor(char, baseColor)
    if not Values.TeamCheck then return baseColor end
    local teamName = GetTeamFolder(char)
    return TeamColors[teamName] or baseColor
end

local function IsLocalTeam(char)
    local localChar = LocalPlayer and LocalPlayer.Character
    if not localChar then return false end
    local localTeam  = GetTeamFolder(localChar)
    local targetTeam = GetTeamFolder(char)
    return localTeam ~= nil and localTeam == targetTeam
end

local function GetHealthColor(pct)
    if pct > 0.5 then
        return Color3.new(1 - (pct - 0.5) * 2, 1, 0)
    else
        return Color3.new(1, pct * 2, 0)
    end
end

local function RelPivot(pivot, size)
    local half = size * 0.5
    return {
        pivot * Vector3.new(-half.X, -half.Y, -half.Z),
        pivot * Vector3.new( half.X, -half.Y, -half.Z),
        pivot * Vector3.new(-half.X,  half.Y, -half.Z),
        pivot * Vector3.new( half.X,  half.Y, -half.Z),
        pivot * Vector3.new(-half.X, -half.Y,  half.Z),
        pivot * Vector3.new( half.X, -half.Y,  half.Z),
        pivot * Vector3.new(-half.X,  half.Y,  half.Z),
        pivot * Vector3.new( half.X,  half.Y,  half.Z),
    }
end

local function minMaxCorners(corners)
    local min = Vector2.new(math.huge, math.huge)
    local max = Vector2.new(-math.huge, -math.huge)
    local cam = Workspace.CurrentCamera
    if not cam then return nil, nil end
    for _, corner in pairs(corners) do
        local pos, onScreen = cam:WorldToViewportPoint(corner)
        if onScreen then
            min = Vector2.new(math.min(min.X, pos.X), math.min(min.Y, pos.Y))
            max = Vector2.new(math.max(max.X, pos.X), math.max(max.Y, pos.Y))
        end
    end
    return min, max
end

local function WorldToScreen(pos)
    local cam = Workspace.CurrentCamera
    if not cam then return nil, false end
    local screenPos, onScreen = cam:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

local function FlagEnabled(flag)
    if type(Values.SelectedFlags) == "table" then
        for _, v in pairs(Values.SelectedFlags) do
            if v == flag then return true end
        end
    end
    return false
end

local function GetAttr(player, key)
    local ok, val = pcall(function() return player:GetAttribute(key) end)
    if ok then
        if key == "CurrentEquipped" or key == "Armor" then
            local dok, decoded = pcall(function() return HttpService:JSONDecode(val) end)
            return dok and decoded or val
        end
        return val
    end
    return nil
end

-- ─── Drawing cache ────────────────────────────────────────────────────────────

local Drawings = {}

local function GetDrawingEntry(name)
    if not Drawings[name] then
        Drawings[name] = { Box = nil, Bones = {}, Labels = {}, NameLabel = nil, HealthBarBG = nil, HealthBarFill = nil }
    end
    return Drawings[name]
end

local function GetBox(name)
    local entry = GetDrawingEntry(name)
    if not entry.Box then
        local box = Drawing.new("Square")
        box.Thickness = 1
        box.Filled = false
        entry.Box = box
    end
    return entry.Box
end

local function GetBones(name)
    local entry = GetDrawingEntry(name)
    if #entry.Bones == 0 then
        for i = 1, #BoneConnections do
            local line = Drawing.new("Line")
            line.Thickness = 1
            line.Visible = false
            entry.Bones[i] = line
        end
    end
    return entry.Bones
end

local function GetNameLabel(name)
    local entry = GetDrawingEntry(name)
    if not entry.NameLabel then
        local lbl = Drawing.new("Text")
        lbl.Size = 13
        lbl.Center = true
        lbl.Outline = true
        lbl.OutlineColor = Color3.new(0, 0, 0)
        lbl.Color = Color3.new(1, 1, 1)
        lbl.Visible = false
        entry.NameLabel = lbl
    end
    return entry.NameLabel
end

local function GetHealthBar(name)
    local entry = GetDrawingEntry(name)
    if not entry.HealthBarBG then
        local bg = Drawing.new("Square")
        bg.Thickness = 1
        bg.Filled = true
        bg.Color = Color3.new(0, 0, 0)
        bg.Visible = false
        entry.HealthBarBG = bg
    end
    if not entry.HealthBarFill then
        local fill = Drawing.new("Square")
        fill.Thickness = 1
        fill.Filled = true
        fill.Visible = false
        entry.HealthBarFill = fill
    end
    return entry.HealthBarBG, entry.HealthBarFill
end

local function GetLabels(name, count)
    local entry = GetDrawingEntry(name)
    while #entry.Labels < count do
        local lbl = Drawing.new("Text")
        lbl.Size = 12
        lbl.Center = false
        lbl.Outline = true
        lbl.OutlineColor = Color3.new(0, 0, 0)
        lbl.Color = Color3.new(1, 1, 1)
        lbl.Visible = false
        table.insert(entry.Labels, lbl)
    end
    return entry.Labels
end

local function HideAllDrawings()
    for _, d in pairs(Drawings) do
        if d.Box           then d.Box.Visible           = false end
        if d.NameLabel     then d.NameLabel.Visible      = false end
        if d.HealthBarBG   then d.HealthBarBG.Visible    = false end
        if d.HealthBarFill then d.HealthBarFill.Visible  = false end
        for _, line in pairs(d.Bones)  do line.Visible = false end
        for _, lbl  in pairs(d.Labels) do lbl.Visible  = false end
    end
end

local function BuildFlagLines(char, player)
    local lines = {}

    if FlagEnabled("Team") then
        local teamName = GetTeamFolder(char)
        if teamName then
            table.insert(lines, "Team: " .. teamName)
        end
    end

    if FlagEnabled("Armor") then
        local armor = player and GetAttr(player, "Armor")
        if armor ~= nil and type(armor) == "table" then
            local label = armor.Type == "Kevlar + Helmet" and "HK"
                       or armor.Type == "Kevlar"           and "K"
                       or "None"
            table.insert(lines, "Armor: " .. label)
        end
    end

    if FlagEnabled("HeldGun") then
        local equipped = player and GetAttr(player, "CurrentEquipped")
        if equipped and type(equipped) == "table" and equipped.Name and equipped.Name ~= "" then
            table.insert(lines, "Gun: " .. tostring(equipped.Name))
        end
    end

    if FlagEnabled("Scoped") then
        local scoped = player and GetAttr(player, "IsSniperScoped")
        if scoped then table.insert(lines, "[Scoped]") end
    end

    if FlagEnabled("Crouched") then
        local crouched = player and GetAttr(player, "IsCrouching")
        if crouched then table.insert(lines, "[Crouched]") end
    end

    if FlagEnabled("Climbing") then
        local climbing = player and GetAttr(player, "IsClimbing")
        if climbing then table.insert(lines, "[Climbing]") end
    end

    if FlagEnabled("HasKit") then
        local hasDefuse = player and GetAttr(player, "HasDefuseKit")
        local hasRescue = player and GetAttr(player, "HasRescueKit")
        if hasDefuse then table.insert(lines, "[Defuse Kit]") end
        if hasRescue then table.insert(lines, "[Rescue Kit]") end
    end

    return lines
end

-- ─── Render loop ──────────────────────────────────────────────────────────────

local BAR_WIDTH = 4
local BAR_GAP   = 3
local FLAG_GAP  = 4

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1; FOVCircle.NumSides = 64; FOVCircle.Filled = false; FOVCircle.Transparency = 1; FOVCircle.Color = Color3.fromRGB(255, 255, 255)

local function GetFOVRadius(cam)
    local fovRad = math.rad(Values.FOV / 2)
    return math.tan(fovRad) * cam.ViewportSize.Y / math.tan(math.rad(cam.FieldOfView / 2))
end

local function IsTargetVisible(char, aimPart)
    if not Values.Wallcheck then return true end
    local cam = Workspace.CurrentCamera
    local part = char:FindFirstChild(aimPart) or char:FindFirstChild("HumanoidRootPart")
    if not part then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { char, cam }
    local result = Workspace:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, params)
    return not result
end

RunService.RenderStepped:Connect(function(dt)
    HideAllDrawings()

    local cam = Workspace.CurrentCamera
    if not cam then return end

    -- ── Aimbot ──

    local aimOk, aimErr = pcall(function()
        local keyActive = Values.AimKeybind == "None"
            or Values.AimKeybind == "Left Alt"    and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
            or Values.AimKeybind == "Right Click" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

        if Values.Aimbot then
            if Values.ShowFOV then
                local radius = GetFOVRadius(cam)
                FOVCircle.Position = cam.ViewportSize / 2
                FOVCircle.Radius = radius
                FOVCircle.Visible = keyActive
            else
                FOVCircle.Visible = false
            end

            if keyActive then
                local localPlayer = Players.LocalPlayer
                if localPlayer then
                    local bestTarget, bestScore
                    local fovRadius = GetFOVRadius(cam)
                    local center = cam.ViewportSize / 2
                    local aimPart = Values.AimPart

                    for _, char in GetCharacters() do
                        local player = Players:GetPlayerFromCharacter(char)
                        if not player or player == localPlayer then continue end
                        if Values.AimTeamCheck then
                            local team = player:GetAttribute("Team")
                            local myTeam = localPlayer:GetAttribute("Team")
                            if team and myTeam and team == myTeam then continue end
                        end

                        local hum = char:FindFirstChild("Humanoid")
                        if not hum or hum.Health <= 0 then continue end

                        local part = char:FindFirstChild(aimPart) or char:FindFirstChild("HumanoidRootPart")
                        if not part then continue end

                        local pos, onScreen = cam:WorldToViewportPoint(part.Position)
                        if not onScreen then continue end

                        local screenPos = Vector2.new(pos.X, pos.Y)
                        if (screenPos - center).Magnitude > fovRadius then continue end

                        if not IsTargetVisible(char, aimPart) then continue end

                        local score = (screenPos - center).Magnitude
                        if not bestScore or score < bestScore then
                            bestScore = score
                            bestTarget = char
                        end
                    end

                    if bestTarget then
                        local part = bestTarget:FindFirstChild(aimPart) or bestTarget:FindFirstChild("HumanoidRootPart")
                        if part then
                            local pos = cam:WorldToViewportPoint(part.Position)
                            local targetScreen = Vector2.new(pos.X, pos.Y)
                            local offset = targetScreen - center
                            local smooth = Values.Smoothness
                            if smooth > 0 then
                                offset = offset * (1 - smooth)
                            end
                            localPlayer:GetMouse():mousemoverel(offset.X, offset.Y)
                        end
                    end
                end
            end
        else
            FOVCircle.Visible = false
        end
    end)
    if not aimOk then
        warn("zenware aimbot error: " .. tostring(aimErr))
    end

    -- ── ESP ──

    for _, char in GetCharacters() do
        if typeof(char) ~= "Instance" then continue end
        if not char:IsA("Model") then continue end

        local player = Players:GetPlayerFromCharacter(char)
        if player == Players.LocalPlayer then continue end
        if Values.TeamCheck and IsLocalTeam(char) then continue end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local charName  = char.Name
        local boxMin, boxMax
        local boxColor  = GetESPColor(char, Values.BoxColor)
        local skelColor = GetESPColor(char, Values.SkeletonColor)

        local size  = char:GetExtentsSize()
        local pivot = hrp.CFrame
        local min, max = minMaxCorners(RelPivot(pivot, size))

        if min and max then
            boxMin, boxMax = min, max

            if Values.BoxESP then
                local box = GetBox(charName)
                box.Position = min
                box.Size     = max - min
                box.Color    = boxColor
                box.Visible  = true
            end
        end

        if Values.SkeletonESP then
            local bones = GetBones(charName)
            for i, connection in ipairs(BoneConnections) do
                local partA = char:FindFirstChild(connection[1])
                local partB = char:FindFirstChild(connection[2])
                local line  = bones[i]
                if partA and partB then
                    local posA, onA = WorldToScreen(partA.Position)
                    local posB, onB = WorldToScreen(partB.Position)
                    if onA and onB then
                        line.From    = posA
                        line.To      = posB
                        line.Color   = skelColor
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    line.Visible = false
                end
            end
        end

        if not boxMin or not boxMax then continue end

        local boxHeight = boxMax.Y - boxMin.Y

        if FlagEnabled("Name") then
            local nameLbl    = GetNameLabel(charName)
            nameLbl.Text     = player and player.DisplayName or char.Name
            nameLbl.Position = Vector2.new((boxMin.X + boxMax.X) * 0.5, boxMin.Y - 15)
            nameLbl.Visible  = true
        end

        if FlagEnabled("Health") then
            local armorData = player and GetAttr(player, "Armor")
            local hum       = char:FindFirstChildOfClass("Humanoid")

            local hp, maxHp = 100, 100
            if armorData and type(armorData) == "table" and armorData.Health then
                hp    = armorData.Health
                maxHp = armorData.MaxHealth or 100
            elseif hum then
                hp    = hum.Health
                maxHp = hum.MaxHealth
            end

            local pct        = math.clamp(hp / math.max(maxHp, 1), 0, 1)
            local barX       = boxMin.X - BAR_GAP - BAR_WIDTH
            local fillHeight = math.max(1, boxHeight * pct)

            local bg, fill = GetHealthBar(charName)

            bg.Position = Vector2.new(barX, boxMin.Y)
            bg.Size     = Vector2.new(BAR_WIDTH, boxHeight)
            bg.Visible  = true

            fill.Position = Vector2.new(barX, boxMax.Y - fillHeight)
            fill.Size     = Vector2.new(BAR_WIDTH, fillHeight)
            fill.Color    = GetHealthColor(pct)
            fill.Visible  = true
        end

        local flagLines = BuildFlagLines(char, player)
        if #flagLines > 0 then
            local labels     = GetLabels(charName, #flagLines)
            local lineHeight = 14
            local labelX     = boxMax.X + FLAG_GAP

            for i, text in ipairs(flagLines) do
                local lbl    = labels[i]
                lbl.Text     = text
                lbl.Position = Vector2.new(labelX, boxMin.Y + (i - 1) * lineHeight)
                lbl.Visible  = true
            end
        end

    end
end)