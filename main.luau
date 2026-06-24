local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/Stratxgy/PepsiUI/refs/heads/main/pepsi.lua'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Values = {
    Aim = { GlobalEnabled = false },
    Esp = {
        GlobalEnabled = false,
        BoxesEnabled = false,
        TracersEnabled = false,
    }
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

local Tabs = {
    Aim = Window:CreateTab({ Name = "Aim" }),
    Esp = Window:CreateTab({ Name = "Esp" }),
}

local Sections = {
    Aim = {},
    Esp = {
        General = Tabs.Esp:CreateSection({ Name = "General", Side = "Left" })
    }
}

local Fields = {
    Aim = {},
    Esp = {
        GlobalEnabled = Sections.Esp.General:AddToggle({
            Name = "Global", Side = "Left",
            Callback = function(v) Values.Esp.GlobalEnabled = v end
        }),
        BoxesEnabled = Sections.Esp.General:AddToggle({
            Name = "Boxes", Side = "Left",
            Callback = function(v) Values.Esp.BoxesEnabled = v end
        }),
        BoxesColor = Sections.Esp.General:AddColorpicker({
            Name = "Box Color", Value = Color3.new(1, 1, 1)
        }),
        TracersEnabled = Sections.Esp.General:AddToggle({
            Name = "Tracers", Side = "Left",
            Callback = function(v) Values.Esp.TracersEnabled = v end
        }),
        TracersColor = Sections.Esp.General:AddColorpicker({
            Name = "Tracer Color", Value = Color3.new(1, 1, 1)
        })
    }
}

local Context = {
    Library = Library,
    Window = Window,
    Tabs = Tabs,
    Sections = Sections,
    Fields = Fields,
    Values = Values,
    Players = Players,
    Workspace = Workspace,
    RunService = RunService,
}

local BaseURL = "https://raw.githubusercontent.com/zenware/zenware.cc/main/"

local GameScripts = {
    [114234929420007] = "bloxstrike",
}

local scriptName = GameScripts[game.PlaceId] or "universal"
local loader = loadstring(game:HttpGet(BaseURL .. "loader.lua"))()
loader(BaseURL, scriptName, Context)
