Sections.Aim.Settings.TargetPartDropdown = Sections.Aim.Settings.GroupBox:AddDropdown('TargetPart', {
    Values = { 'Head', 'Torso', 'HumanoidRootPart' },  -- Required: table of string values
    Default = 1,  -- Index of the default value (1-based)
    Multi = false,  -- Single selection only
    Text = 'Target Part',
    Tooltip = 'Select which body part to aim at',
    Callback = function(Value)
        this.Values.Aim.TargetPart = Value
    end
})