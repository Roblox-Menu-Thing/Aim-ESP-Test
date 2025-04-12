--[[
    Trigger Controller
    Handles automatic shooting when aiming at enemies
]]

local TriggerController = {}

-- Check if we're in Roblox environment
local isRobloxEnvironment = (typeof ~= nil and typeof(Enum) == "table")

-- Configuration
TriggerController.Enabled = false
TriggerController.Delay = 50        -- Delay in ms before trigger fires
TriggerController.Interval = 50     -- Interval in ms between shots
TriggerController.TeamCheck = true  -- Don't trigger on teammates

-- Initialize Roblox-specific properties only if in Roblox environment
if isRobloxEnvironment and Enum and Enum.KeyCode then
    TriggerController.Button = Enum.KeyCode.LeftControl  -- Left Control key
else
    -- Mock values for standalone Lua
    TriggerController.Button = "LeftControl"
end

-- Private variables
local runService = nil
local userInputService = nil
local players = nil
local camera = nil
local virtualInputManager = nil
local connections = {}
local isActive = false
local lastTriggerTime = 0
local isShooting = false
local main = nil
local playerDetection = nil
local aimbot = nil

-- Initialize the controller
function TriggerController:Initialize(mainController, detectionController, aimbotController)
    main = mainController
    playerDetection = detectionController
    aimbot = aimbotController
    
    -- Initialize Roblox services if available
    if isRobloxEnvironment and game then
        -- Try to get services
        local success, result = pcall(function()
            runService = game:GetService("RunService")
            userInputService = game:GetService("UserInputService")
            players = game:GetService("Players")
            camera = workspace.CurrentCamera
            virtualInputManager = game:GetService("VirtualInputManager")
            return true
        end)
        
        if not success then
            print("TriggerController: Failed to get Roblox services - " .. tostring(result))
        end
    else
        -- Mock services for standalone Lua
        print("TriggerController: Using mock services for standalone Lua")
        runService = {
            RenderStepped = {
                Connect = function() return { Connected = true, Disconnect = function() end } end
            }
        }
        userInputService = {
            InputBegan = {
                Connect = function() return { Connected = true, Disconnect = function() end } end
            },
            InputEnded = {
                Connect = function() return { Connected = true, Disconnect = function() end } end
            },
            GetMouseLocation = function() return { X = 400, Y = 300 } end
        }
        players = {
            LocalPlayer = { Team = nil, Character = {} }
        }
        camera = {
            ViewportSize = { X = 800, Y = 600 },
            ViewportPointToRay = function(self, x, y) 
                return { 
                    Origin = { X = 0, Y = 0, Z = 0 },
                    Direction = { X = 0, Y = 0, Z = 1 }
                }
            end,
            CFrame = {
                Position = { X = 0, Y = 0, Z = 0 }
            }
        }
        -- Mock virtual input manager for mouse clicks
        virtualInputManager = {
            SendMouseButtonEvent = function() end
        }
    end
    
    return self
end

-- Enable trigger bot
function TriggerController:Enable()
    if self.Enabled then return end
    
    self.Enabled = true
    
    -- Connect input events
    table.insert(connections, userInputService.InputBegan:Connect(function(input)
        if input.KeyCode == self.Button then
            isActive = true
        end
    end))
    
    table.insert(connections, userInputService.InputEnded:Connect(function(input)
        if input.KeyCode == self.Button then
            isActive = false
            self:StopShooting()
        end
    end))
    
    -- Connect update
    table.insert(connections, runService.RenderStepped:Connect(function()
        self:Update()
    end))
    
    print("Trigger bot enabled")
end

-- Disable trigger bot
function TriggerController:Disable()
    if not self.Enabled then return end
    
    self.Enabled = false
    
    -- Disconnect all events
    for _, connection in ipairs(connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    connections = {}
    
    isActive = false
    self:StopShooting()
    
    print("Trigger bot disabled")
end

-- Check if cursor is over an enemy
function TriggerController:IsCursorOverEnemy()
    -- In standalone Lua mode, always return false
    if not isRobloxEnvironment then
        print("TriggerController: IsCursorOverEnemy not supported in standalone Lua")
        return false
    end
    
    -- Get mouse position
    local mouseLocation = userInputService:GetMouseLocation()
    local unitRay = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
    
    -- Create raycast parameters
    local success, raycastResult = pcall(function()
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {players.LocalPlayer.Character}
        
        return workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
    end)
    
    if not success or not raycastResult then
        return false
    end
    
    -- Check if we hit a character
    if raycastResult.Instance then
        local hitCharacter = raycastResult.Instance:FindFirstAncestorOfClass("Model")
        
        if hitCharacter then
            local hitPlayer = players:GetPlayerFromCharacter(hitCharacter)
            
            if hitPlayer and hitPlayer ~= players.LocalPlayer then
                -- Team check
                if self.TeamCheck and hitPlayer.Team == players.LocalPlayer.Team then
                    return false
                end
                
                return true
            end
        end
    end
    
    return false
end

-- Start shooting
function TriggerController:StartShooting()
    if isShooting then return end
    
    isShooting = true
    
    -- Simulate mouse click
    mouse1Down()
    
    -- Schedule release after interval
    if isRobloxEnvironment and task and task.delay then
        task.delay(self.Interval / 1000, function()
            self:StopShooting()
        end)
    else
        -- Basic timeout implementation for standalone Lua
        print("TriggerController: Using setTimeout fallback for standalone Lua")
        -- In standalone Lua, just call stop immediately (no async)
        self:StopShooting()
    end
    
    lastTriggerTime = isRobloxEnvironment and (tick() * 1000) or os.time() * 1000
end

-- Stop shooting
function TriggerController:StopShooting()
    if not isShooting then return end
    
    isShooting = false
    
    -- Simulate mouse release
    mouse1Up()
end

-- Simulate mouse down
function mouse1Down()
    if isRobloxEnvironment and virtualInputManager then
        virtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    else
        print("TriggerController: Mouse click simulation not supported in standalone Lua")
    end
end

-- Simulate mouse up
function mouse1Up()
    if isRobloxEnvironment and virtualInputManager then
        virtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    else
        print("TriggerController: Mouse click simulation not supported in standalone Lua")
    end
end

-- Main update loop
function TriggerController:Update()
    if not self.Enabled or not main.Enabled or not isActive or isShooting then return end
    
    -- Check if we should trigger
    if self:IsCursorOverEnemy() then
        local currentTime = isRobloxEnvironment and (tick() * 1000) or (os.time() * 1000)
        
        -- Apply delay before shooting
        if currentTime - lastTriggerTime >= self.Delay then
            self:StartShooting()
        end
    end
end

-- Set delay
function TriggerController:SetDelay(value)
    self.Delay = value
end

-- Set interval
function TriggerController:SetInterval(value)
    self.Interval = value
end

-- Toggle team check
function TriggerController:ToggleTeamCheck(enabled)
    self.TeamCheck = enabled
end

-- Cleanup
function TriggerController:Cleanup()
    self:Disable()
end

return TriggerController
