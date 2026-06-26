local Repo = "https://raw.githubusercontent.com/KaiRocks2006/zenware.cc/refs/heads/main/"
local Library = loadstring(game:HttpGet(Repo .. 'Library.lua'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local PlaceIds = {
    [13253735473] = "TridentSurvival",
    [115209351507608] = "TheArmory"
}

local Context = {
    Library = Library,
    Players = Players,
    Workspace = Workspace,
    RunService = RunService,
    HttpService = HttpService,
}

local DetectedGame = ""
DetectedGame = PlaceIds[game.PlaceId] or "universal"

Context.Window = Library:CreateWindow({
    Title = 'zenware.cc - ' .. DetectedGame,
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Module = loadstring(game:HttpGet(Repo .. DetectedGame .. ".lua"))()
Module.Load(Context)