local Helpers = {}

function Helpers.WorldToScreen(point: Vector3)
    return game:GetService("Workspace").CurrentCamera:WorldToViewportPoint(point)
end

return Helpers