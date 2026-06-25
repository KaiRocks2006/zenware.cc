local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/Stratxgy/PepsiUI/refs/heads/main/pepsi.lua'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local IsBloxStrike = game.PlaceId == 114234929420007

local PlaceIds = {
    [114234929420007] = "BloxStrike",
    [13253735473] = "TridentSurvival",
    [112757576021097] = "DefuseDevision",
    [7336302630] = "ProjectDelta",
    [115209351507608] = "TheArmory"
}

local Window = Library:CreateWindow({
    Name = "zenware.cc",
    Themeable = {
        Name = "Settings",
        Image = "nil",
        Info = "Script by zenware team",
        Credit = false
    },
    Background = "",
    Theme = [[{"__Designer.Background.UseBackgroundImage":false}]]
})

local Context = {
    ["Window"] = Window,
    ["Players"] = Players,
    ["Workspace"] = Workspace,
    ["RunService"] = RunService,
    ["HttpService"] = HttpService,
}

local BaseUrl = "https://raw.githubusercontent.com/KaiRocks2006/zenware.cc/refs/heads/main/"
local DetectedGame = ""
DetectedGame = PlaceIds[game.PlaceId] or "universal"

local Module = loadstring(game:HttpGet(BaseUrl .. DetectedGame .. ".lua"))()
Module.Start(Context)