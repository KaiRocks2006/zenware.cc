local Repo = "https://raw.githubusercontent.com/KaiRocks2006/zenware.cc/refs/heads/main/"
local Library = loadstring(game:HttpGet(Repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(Repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(Repo .. 'addons/SaveManager.lua'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local PlaceIds = {
    [13253735473] = "TridentSurvival",
    [115209351507608] = "TheArmory"
}

local Window = Library:CreateWindow({
    Title = 'zenware.cc',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Context = {
    Window = Window,
    Library = Library,
    Players = Players,
    Workspace = Workspace,
    RunService = RunService,
    HttpService = HttpService,
    SaveManager = SaveManager,
    ThemeManager = ThemeManager,
}

local DetectedGame = ""
DetectedGame = PlaceIds[game.PlaceId] or "universal"

local Module = loadstring(game:HttpGet(Repo .. DetectedGame .. ".lua"))()
Module.Load(Context)
local SettingsTab = Window:AddTab("UI Settings")
local MenuGroup = SettingsTab:AddLeftGroupbox('Menu')

-- I set NoUI so it does not show up in the keybinds menu
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })
Library.ToggleKeybind = Options.MenuKeybind -- Allows you to have a custom keybind for the menu

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('zenware.cc')
SaveManager:SetFolder('zenware.cc/' .. DetectedGame)

SaveManager:BuildConfigSection(SettingsTab)

ThemeManager:ApplyToTab(SettingsTab)