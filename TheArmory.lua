local this = {}

this.Library = nil
this.Window = nil
this.Workspace = game:GetService("Workspace")
this.Interactables = this.Workspace:WaitForChild("Interactible", 5)
this.Crates = this.Workspace:WaitForChild("SpawnedCrates", 5)
this.Items = this.Workspace:WaitForChild("SpawnedItems", 5)
this.Entities = this.Workspace:WaitForChild("Entities", 5)

function this.IsCrateLoaded(Crate)
    return Crate:FindFirstChild("Root") and true or false
end

this.Vars = {
    ESP = {
        Extraction = {
            Color = Color3.new(0, 1, 0),
            Flags = {
                Extracting = {
                    Enabled = false,
                    PlayerName = "",
                }
            },
            ExtractionPoints = {},
        }
    }
}

this.Tabs = {
    Aim = {
        Tab = nil,
        Sections = {},
        Values = {}
    },
    Visuals = {
        Tab = nil,
        Sections = {},
        Values = {}
    },
    Player = {
        Tab = nil,
        Sections = {},
        Values = {}
    },
}

function this.Start(Context)
    this.Library = Context.Library
    this.Window = Context.Window
    this.Initialize()
end

function this.Initialize()
    local W = this.Window
    this.Tabs.Aim.Tab = W:CreateTab({ Name = "Aim" })
    this.Tabs.Visuals.Tab = W:CreateTab({ Name = "Visuals" })
    this.Tabs.Player.Tab = W:CreateTab({ Name = "Player" })

    -- Visuals
    this.Tabs.Visuals.Sections = {
        Player = this.Tabs.Visuals.Tab:CreateSection({ Name = "Player", Side = "Left" }),
        World = this.Tabs.Visuals.Tab:CreateSection({ Name = "World", Side = "Right" }),
        Flags = this.Tabs.Visuals.Tab:CreateSection({ Name = "Flags", Side = "Right" }),
    }

    this.Tabs.Visuals.Values = {
        World = {
            ExtractESP = this.Tabs.Visuals.Sections.World:AddToggle({
                Name = "Extract ESP",
                Callback = function(v)
                    for _, HL : Highlight in ipairs(this.Vars.ESP.Extraction.ExtractionPoints) do
                        HL.Enabled = v
                    end
                end
            }),
            ExtractESPColor = this.Tabs.Visuals.Sections.World:AddColorpicker({
                Name = "Extract Color",
                Value = this.Vars.ESP.Extraction.Color,
                Callback = function(new, old) this.Vars.ESP.Extraction.Color = new end
            })
        },
    }
end

function this.Logic()
    for _, Interactable in this.Interactables:GetChildren() do
        if Interactable.Name == "Extraction Point" or Interactable.Name == "Extraction Point Z2" and this.Vars.ESP.Extraction.ExtractionPoints[Interactable] == nil then
            local hl = Instance.new("Highlight", Interactable) -- Parent the highlight to the point

            hl.Adornee = Interactable
            hl.FillColor = this.Vars.ESP.Extraction.Color
            hl.FillTransparency = 0.75
            hl.OutlineColor = this.Vars.ESP.Extraction.Color
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

            hl.Name = "ExtractHL"

            this.Vars.ESP.Extraction.ExtractionPoints[Interactable] = hl
        end
    end
end

function this.Render()
end

return this