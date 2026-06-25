local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local function DeserializeString(string)
    local json = string
    return HttpService:JSONDecode(json)
end

local function GetCharacters()
    local cs = {}
    local CharacterFolder = Workspace:FindFirstChild("Characters") or nil
    if CharacterFolder == nil then
        error("Hey, the game seems to be hiding the Characters folder from executors")
    end

    local T = CharacterFolder:FindFirstChild("Terrorists")
    local CT = CharacterFolder:FindFirstChild("Counter-Terrorists")
    if CT == nil or T == nil then
        error("One or both of the team folders are nil")
    end

    for _, v in CT:GetChildren() do
        table.insert(cs, v)
    end
    for _, v in T:GetChildren() do
        table.insert(cs, v)
    end
    return cs
end

local PlayerFlags = {
    -- All players
    Armor = "Armor",
    Team = "Team",
    HasDefuser = "HasDefuseKit",
    HasRescuer = "HasRescueKit",
    IsClimbing = "IsClimbing",
    MinIncome = "MinimumNextRoundIncome",
    Money = "Money",
    Ping = "Ping",
    CurrentEquipped = "CurrentEquipped", -- Only if alive
    -- Others only
    IsCrouched = "IsCrouching",
    -- Local only
    CrouchCamOffset = "CrouchCameraOffset",   -- 0, -1.4,  0
    DefaultCamOffset = "DefaultCameraOffset", -- 0, -0.15, 0
}

local Weapon = {}
Weapon.__index = Weapon

function Weapon:HasAmmo()
    if self.Capacity ~= nil and self.Rounds ~= nil then return true else return false end
end

function Weapon:GetName()
    return self.Name or "Unknown"
end

function Weapon:GetSkin()
    return self.Skin or "Unknown"
end

function Weapon.new(weaponTable)
    local self = weaponTable
    setmetatable(self, Weapon)
    return self
end

local function doStuff(Character : Model)
    print(Character.Name)
    local Player = Players:GetPlayerFromCharacter(Character)
    print("  Player Instance: " .. tostring(Player))
    print("  Team: " .. Player:GetAttribute(PlayerFlags.Team))
    local Armor = DeserializeString(Player:GetAttribute(PlayerFlags.Armor))
    print("  Health: " .. Armor.Health)
    local HK = "Kevlar + Helmet"
    local K = "Kevlar"
    print("  ShieldFlags: " .. if Armor.Type == HK then "HK" elseif Armor.Type == K then "K" else "Unknown")
    local CurrentEquipped = Player:GetAttribute(PlayerFlags.CurrentEquipped)
    if CurrentEquipped then
        local t = DeserializeString(CurrentEquipped)
		local weapon = Weapon.new(t)
        print("  " .. weapon:GetName())
    end
end

for _, v in ipairs(GetCharacters()) do
    doStuff(v)
end