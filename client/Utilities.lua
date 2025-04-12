--[[
    Utilities
    Contains utility functions for the entire system
]]

local Utilities = {}

-- Get the distance between two Vector3 positions
function Utilities.GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

-- Get the direction vector from a position to another
function Utilities.GetDirection(from, to)
    return (to - from).Unit
end

-- Clamp a value between min and max
function Utilities.Clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

-- Lerp between two values
function Utilities.Lerp(a, b, t)
    return a + (b - a) * t
end

-- Lerp between two CFrames
function Utilities.LerpCFrame(a, b, t)
    return a:Lerp(b, t)
end

-- Check if a ray intersects a part
function Utilities.RayIntersectsPart(origin, direction, part)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Whitelist
    params.FilterDescendantsInstances = {part}
    
    local result = workspace:Raycast(origin, direction, params)
    
    return result ~= nil
end

-- Check if a point is on screen
function Utilities.IsPointOnScreen(point)
    local camera = workspace.CurrentCamera
    local vector, onScreen = camera:WorldToScreenPoint(point)
    
    return onScreen and vector.Z > 0
end

-- Get FOV between camera direction and target position
function Utilities.GetFOV(targetPos)
    local camera = workspace.CurrentCamera
    local cameraDirection = camera.CFrame.LookVector
    local targetDirection = (targetPos - camera.CFrame.Position).Unit
    
    local dot = cameraDirection:Dot(targetDirection)
    local angle = math.acos(dot)
    
    return math.deg(angle)
end

-- Create a delay without yielding the script
function Utilities.Delay(seconds, callback)
    local startTime = tick()
    
    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        if tick() - startTime >= seconds then
            connection:Disconnect()
            callback()
        end
    end)
    
    return connection
end

-- Parse a string input into a key code
function Utilities.ParseKeyCode(keyString)
    for _, keyCode in pairs(Enum.KeyCode:GetEnumItems()) do
        if keyCode.Name:lower() == keyString:lower() then
            return keyCode
        end
    end
    
    return nil
end

-- Format a number to a specific number of decimal places
function Utilities.FormatNumber(number, decimalPlaces)
    decimalPlaces = decimalPlaces or 0
    local multiplier = 10 ^ decimalPlaces
    
    return math.floor(number * multiplier + 0.5) / multiplier
end

-- Check if a table contains a value
function Utilities.TableContains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    
    return false
end

-- Get visible parts of a character
function Utilities.GetVisibleCharacterParts(character, originPosition)
    local visibleParts = {}
    local camera = workspace.CurrentCamera
    
    if not character then return visibleParts end
    
    local parts = character:GetChildren()
    for _, part in pairs(parts) do
        if part:IsA("BasePart") then
            local direction = (part.Position - originPosition).Unit
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            raycastParams.FilterDescendantsInstances = {camera, game.Players.LocalPlayer.Character}
            
            local raycastResult = workspace:Raycast(originPosition, direction * 10000, raycastParams)
            
            if raycastResult and raycastResult.Instance and raycastResult.Instance:IsDescendantOf(character) then
                table.insert(visibleParts, part)
            end
        end
    end
    
    return visibleParts
end

-- Damping function for smoother camera movement
function Utilities.Damp(a, b, smoothing, dt)
    return Utilities.Lerp(a, b, 1 - math.exp(-smoothing * dt))
end

return Utilities
