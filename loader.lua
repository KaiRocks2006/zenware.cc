return function(baseURL, scriptName, context)
    local ok, result = pcall(game.HttpGet, game, baseURL .. scriptName .. ".lua")
    if not ok then
        return warn("zenware: failed to fetch " .. scriptName .. ".lua — " .. tostring(result))
    end

    local fn, err = loadstring(result)
    if not fn then
        return warn("zenware: failed to compile " .. scriptName .. ".lua — " .. tostring(err))
    end

    local success, runtimeErr = pcall(fn, context)
    if not success then
        warn("zenware: " .. scriptName .. ".lua error — " .. tostring(runtimeErr))
    end
end
