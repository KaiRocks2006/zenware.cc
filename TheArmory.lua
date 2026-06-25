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
			Enabled = false,
			Flags = {
				Extracting = {
					Enabled = false,
					PlayerName = "",
				}
			},
			-- Keyed by Instance -> Highlight
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

	this.Tabs.Aim.Tab     = W:CreateTab({ Name = "Aim" })
	this.Tabs.Visuals.Tab = W:CreateTab({ Name = "Visuals" })
	this.Tabs.Player.Tab  = W:CreateTab({ Name = "Player" })

	this.Tabs.Visuals.Sections = {
		Player = this.Tabs.Visuals.Tab:CreateSection({ Name = "Player", Side = "Left"  }),
		World  = this.Tabs.Visuals.Tab:CreateSection({ Name = "World",  Side = "Right" }),
		Flags  = this.Tabs.Visuals.Tab:CreateSection({ Name = "Flags",  Side = "Right" }),
	}

	this.Tabs.Visuals.Values = {
		World = {
			ExtractESP = this.Tabs.Visuals.Sections.World:AddToggle({
				Name = "Extract ESP",
				Callback = function(v)
					this.Vars.ESP.Extraction.Enabled = v
					-- Iterate by pairs since keys are Instances, not integers
					for _, hl in pairs(this.Vars.ESP.Extraction.ExtractionPoints) do
						hl.Enabled = v
					end
				end
			}),
			ExtractESPColor = this.Tabs.Visuals.Sections.World:AddColorpicker({
				Name = "Extract Color",
				Value = this.Vars.ESP.Extraction.Color,
				Callback = function(new, old)
					this.Vars.ESP.Extraction.Color = new
					-- Update color on all existing highlights
					for _, hl in pairs(this.Vars.ESP.Extraction.ExtractionPoints) do
						hl.FillColor    = new
						hl.OutlineColor = new
					end
				end
			}),
		},
	}
end

local EXTRACTION_NAMES = {
	["Extraction Point"]    = true,
	["Extraction Point Z2"] = true,
}

function this.Logic()
	if not this.Interactables then return end

	for _, Interactable in this.Interactables:GetChildren() do
		-- Fixed operator precedence: wrap the name check in parentheses
		if EXTRACTION_NAMES[Interactable.Name] and this.Vars.ESP.Extraction.ExtractionPoints[Interactable] == nil then
			local hl = Instance.new("Highlight")
			hl.Adornee           = Interactable
			hl.FillColor         = this.Vars.ESP.Extraction.Color
			hl.FillTransparency  = 0.75
			hl.OutlineColor      = this.Vars.ESP.Extraction.Color
			hl.OutlineTransparency = 0
			hl.DepthMode         = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Name              = "ExtractHL"
			-- Respect current toggle state when creating
			hl.Enabled           = this.Vars.ESP.Extraction.Enabled
			hl.Parent            = Interactable
			this.Vars.ESP.Extraction.ExtractionPoints[Interactable] = hl
		end
	end
end

function this.Render()
end

return this