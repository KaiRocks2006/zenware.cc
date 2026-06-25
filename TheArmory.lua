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

function this.GetCrateRarity(Crate)
    if not this.IsCrateLoaded(Crate) then
        return nil
    end

    local mesh = Crate:FindFirstChild("Mesh")
    if not mesh then
        return nil
    end

    local part = mesh:FindFirstChild("updated_Cube.039", true)
    if not part then
        return nil
    end

    local color = part.Color
    local threshold = 0.05

    local rarities = {
        Common    = Color3.fromRGB(128,128,128),
        Uncommon  = Color3.fromRGB(82,177,65),
        Rare      = Color3.fromRGB(0,98,255),
        Epic      = Color3.fromRGB(228,121,255),
    }

    for rarity, c in pairs(rarities) do
        if math.abs(c.R - color.R) < threshold
        and math.abs(c.G - color.G) < threshold
        and math.abs(c.B - color.B) < threshold then
            return rarity
        end
    end

    -- Unknown color. Don't assume Legendary yet.
    return nil
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
			ExtractionPoints = {},
		},
		Player = {
			Color = Color3.new(1, 0, 0),
			Enabled = false,
			Flags = {
				Name = false,
				Health = false,
			}
		},
		Crates = {
			Enabled = false,
			Colors = {
				Common    = Color3.fromRGB(122, 122, 122),
				Uncommon  = Color3.fromRGB(0, 255, 55),
				Rare      = Color3.fromRGB(0, 38, 255),
				Epic      = Color3.fromRGB(179, 0, 255),
				Legendary = Color3.fromRGB(255, 255, 0),
			},
			Flags = {
				Common    = true,
				Uncommon  = true,
				Rare      = true,
				Epic      = true,
				Legendary = true,
			},
			-- Keyed by Instance -> Highlight
			Highlights = {},
		},
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
	this.LogicThread = task.spawn(this.Logic)
	this.RenderThread = game:GetService("RunService").RenderStepped:Connect(this.Render)
	this.Library.UnloadCallback = this.Shutdown
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
			-- Extraction ESP
			ExtractESP = this.Tabs.Visuals.Sections.World:AddToggle({
				Name = "Extract ESP",
				Callback = function(v)
					this.Vars.ESP.Extraction.Enabled = v
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
					for _, hl in pairs(this.Vars.ESP.Extraction.ExtractionPoints) do
						hl.FillColor    = new
						hl.OutlineColor = new
					end
				end
			}),

			-- Crate ESP
			CrateESP = this.Tabs.Visuals.Sections.World:AddToggle({
				Name = "Crate ESP",
				Callback = function(v)
					this.Vars.ESP.Crates.Enabled = v
					for crate, hl in pairs(this.Vars.ESP.Crates.Highlights) do
						local rarity = this.GetCrateRarity(crate)
						hl.Enabled = v and rarity ~= nil and this.Vars.ESP.Crates.Flags[rarity] == true
					end
				end
			}),

			-- Per-rarity toggles
			CrateCommon = this.Tabs.Visuals.Sections.World:AddToggle({
				Name = "Common Crates",
				Value = true,
				Callback = function(v)
					this.Vars.ESP.Crates.Flags.Common = v
					this.UpdateCrateHighlights()
				end
			}),
			CrateUncommon = this.Tabs.Visuals.Sections.World:AddToggle({
				Name = "Uncommon Crates",
				Value = true,
				Callback = function(v)
					this.Vars.ESP.Crates.Flags.Uncommon = v
					this.UpdateCrateHighlights()
				end
			}),
			CrateRare = this.Tabs.Visuals.Sections.World:AddToggle({
				Name = "Rare Crates",
				Value = true,
				Callback = function(v)
					this.Vars.ESP.Crates.Flags.Rare = v
					this.UpdateCrateHighlights()
				end
			}),
			CrateEpic = this.Tabs.Visuals.Sections.World:AddToggle({
				Name = "Epic Crates",
				Value = true,
				Callback = function(v)
					this.Vars.ESP.Crates.Flags.Epic = v
					this.UpdateCrateHighlights()
				end
			}),
			CrateLegendary = this.Tabs.Visuals.Sections.World:AddToggle({
				Name = "Legendary Crates",
				Value = true,
				Callback = function(v)
					this.Vars.ESP.Crates.Flags.Legendary = v
					this.UpdateCrateHighlights()
				end
			}),

			-- Per-rarity color pickers
			CrateCommonColor = this.Tabs.Visuals.Sections.World:AddColorpicker({
				Name = "Common Color",
				Value = this.Vars.ESP.Crates.Colors.Common,
				Callback = function(new)
					this.Vars.ESP.Crates.Colors.Common = new
					this.UpdateCrateHighlightColors("Common")
				end
			}),
			CrateUncommonColor = this.Tabs.Visuals.Sections.World:AddColorpicker({
				Name = "Uncommon Color",
				Value = this.Vars.ESP.Crates.Colors.Uncommon,
				Callback = function(new)
					this.Vars.ESP.Crates.Colors.Uncommon = new
					this.UpdateCrateHighlightColors("Uncommon")
				end
			}),
			CrateRareColor = this.Tabs.Visuals.Sections.World:AddColorpicker({
				Name = "Rare Color",
				Value = this.Vars.ESP.Crates.Colors.Rare,
				Callback = function(new)
					this.Vars.ESP.Crates.Colors.Rare = new
					this.UpdateCrateHighlightColors("Rare")
				end
			}),
			CrateEpicColor = this.Tabs.Visuals.Sections.World:AddColorpicker({
				Name = "Epic Color",
				Value = this.Vars.ESP.Crates.Colors.Epic,
				Callback = function(new)
					this.Vars.ESP.Crates.Colors.Epic = new
					this.UpdateCrateHighlightColors("Epic")
				end
			}),
			CrateLegendaryColor = this.Tabs.Visuals.Sections.World:AddColorpicker({
				Name = "Legendary Color",
				Value = this.Vars.ESP.Crates.Colors.Legendary,
				Callback = function(new)
					this.Vars.ESP.Crates.Colors.Legendary = new
					this.UpdateCrateHighlightColors("Legendary")
				end
			}),
		},
	}
end

-- Updates Enabled state on all crate highlights based on current flags
function this.UpdateCrateHighlights()
	for crate, hl in pairs(this.Vars.ESP.Crates.Highlights) do
		local rarity = this.GetCrateRarity(crate)
		hl.Enabled = this.Vars.ESP.Crates.Enabled
			and rarity ~= nil
			and this.Vars.ESP.Crates.Flags[rarity] == true
	end
end

-- Updates color on all highlights of a specific rarity
function this.UpdateCrateHighlightColors(rarity)
	local color = this.Vars.ESP.Crates.Colors[rarity]
	for crate, hl in pairs(this.Vars.ESP.Crates.Highlights) do
		if this.GetCrateRarity(crate) == rarity then
			hl.FillColor    = color
			hl.OutlineColor = color
		end
	end
end

local EXTRACTION_NAMES = {
	["Extraction Point"]    = true,
	["Extraction Point Z2"] = true,
}

function this.Logic()
	if not this.Interactables then return end
	while task.wait(1) do
		-- Extraction points
		for _, Interactable in this.Interactables:GetChildren() do
			if EXTRACTION_NAMES[Interactable.Name] and this.Vars.ESP.Extraction.ExtractionPoints[Interactable] == nil then
				local hl = Instance.new("Highlight")
				hl.Adornee             = Interactable
				hl.FillColor           = this.Vars.ESP.Extraction.Color
				hl.FillTransparency    = 0.75
				hl.OutlineColor        = this.Vars.ESP.Extraction.Color
				hl.OutlineTransparency = 0
				hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
				hl.Name                = "ExtractHL"
				hl.Enabled             = this.Vars.ESP.Extraction.Enabled
				hl.Parent              = Interactable
				this.Vars.ESP.Extraction.ExtractionPoints[Interactable] = hl
			end
		end

		-- Crates
		if this.Crates then
			for _, Crate in this.Crates:GetChildren() do
				if this.Vars.ESP.Crates.Highlights[Crate] == nil then
					-- Wait until the crate is loaded before creating the highlight
					if not this.IsCrateLoaded(Crate) then continue end

					local rarity = this.GetCrateRarity(Crate)
					if rarity == nil then continue end

					local color = this.Vars.ESP.Crates.Colors[rarity] or Color3.new(1, 1, 1)

					local hl = Instance.new("Highlight")
					hl.Adornee             = Crate
					hl.FillColor           = color
					hl.FillTransparency    = 0.5
					hl.OutlineColor        = color
					hl.OutlineTransparency = 0
					hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
					hl.Name                = "CrateHL"
					hl.Enabled             = this.Vars.ESP.Crates.Enabled and this.Vars.ESP.Crates.Flags[rarity] == true
					hl.Parent              = Crate
					this.Vars.ESP.Crates.Highlights[Crate] = hl
				end
			end
		end
	end
end

function this.Render(dt)
end

function this.Shutdown()
	this.RenderThread:Disconnect()
	task.cancel(this.LogicThread)
	for _, hl in pairs(this.Vars.ESP.Extraction.ExtractionPoints) do
		hl:Destroy()
	end
	this.Vars.ESP.Extraction.ExtractionPoints = {}
	for _, hl in pairs(this.Vars.ESP.Crates.Highlights) do
		hl:Destroy()
	end
	this.Vars.ESP.Crates.Highlights = {}
end

return this