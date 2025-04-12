--[[
    Player Detection
    Handles detection and filtering of valid targets
]]

local PlayerDetection = {}

-- Configuration
PlayerDetection.TeamCheck = true  -- Don't target teammates
PlayerDetection.VisibilityCheck = true -- Check if player is visible
PlayerDetection.IgnoreInvisible = true -- Ignore players with Transparency

-- Check if we're in Roblox environment
local isRobloxEnvironment = (typeof ~= nil and game ~= nil)

-- Private variables
local runService, players, camera, workspace
local connections = {}
local main = nil
local validTargets = {}
local raycastParams

-- Initialize game services based on environment
if isRobloxEnvironment and game and typeof(game.GetService) == "function" then
    -- Use actual Roblox services
    runService = game:GetService("RunService")
    players = game:GetService("Players")
    if workspace and workspace.CurrentCamera then
        camera = workspace.CurrentCamera
    end
else
    -- Create mock objects for standalone Lua
    game = {
        GetService = function(self, serviceName)
            if serviceName == "RunService" then
                return {
                    Heartbeat = {
                        Connect = function(_, callback)
                            -- Call the callback once immediately to simulate a heartbeat
                            pcall(callback)
                            return {Connected = true, Disconnect = function() end}
                        end
                    }
                }
            elseif serviceName == "Players" then
                return {
                    LocalPlayer = {
                        Character = {},
                        Team = "MockTeam1"
                    },
                    GetPlayers = function()
                        return {} -- Return empty array in standalone mode
                    end
                }
            end
            return {}
        end
    }
    
    -- Create global workspace if it doesn't exist
    if not workspace then
        workspace = {
            CurrentCamera = {
                CFrame = {
                    Position = {x=0, y=0, z=0},
                }
            },
            Raycast = function() return nil end
        }
        print("PlayerDetection: Created mock workspace for standalone Lua")
    end
    
    -- Get services from our mock game object
    runService = game:GetService("RunService")
    players = game:GetService("Players")
    camera = workspace.CurrentCamera
    
    -- Print debug message for standalone mode
    print("Running in standalone Lua mode with mock Roblox objects")
end

-- Create raycast params based on environment
if isRobloxEnvironment and typeof(RaycastParams) == "table" and typeof(RaycastParams.new) == "function" then
    raycastParams = RaycastParams.new()
else
    -- Mock version for standalone mode
    raycastParams = {
        FilterType = "Blacklist",
        FilterDescendantsInstances = {}
    }
end

-- Initialize the controller
function PlayerDetection:Initialize(mainController)
    main = mainController
    
    -- Set up raycast parameters differently depending on environment
    -- Use pcall to catch any errors when accessing Enum
    local success = pcall(function()
        if Enum and Enum.RaycastFilterType and Enum.RaycastFilterType.Blacklist then
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            print("Using Roblox RaycastFilterType: Blacklist")
        end
    end)
    
    if not success then
        -- Fallback for standalone mode
        raycastParams.FilterType = "Blacklist"
        print("Using standalone mode filter type: Blacklist")
    end
    
    -- Start detection loop
    self:StartDetection()
    
    return self
end

-- Start player detection
function PlayerDetection:StartDetection()
    -- Make sure runService and Heartbeat exist before connecting
    local success, connection = pcall(function()
        if runService and runService.Heartbeat then
            return runService.Heartbeat:Connect(function()
                self:UpdateTargets()
            end)
        else
            print("PlayerDetection: No Heartbeat available, using standalone mode")
            -- In standalone mode, just update targets once
            self:UpdateTargets()
            -- Return a dummy connection object
            return {Connected = true, Disconnect = function() end}
        end
    end)
    
    if success and connection then
        table.insert(connections, connection)
    end
    
    print("PlayerDetection: Detection started")
end

-- Check if a player is alive
function PlayerDetection:IsAlive(player)
    if not player or not player.Character then return false end
    
    -- In Lua standalone mode, we either mock these or return basic values
    if not isRobloxEnvironment then
        return true -- Always return alive in standalone mode for simplicity
    end
    
    -- Use pcall for all Roblox-specific operations to catch any errors
    local success, result = pcall(function()
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then 
            return false 
        end
        return true
    end)
    
    return success and result or false
end

-- Check if a player is visible
function PlayerDetection:IsVisible(player)
    if not self.VisibilityCheck then return true end
    if not player or not player.Character then return false end
    
    -- In Lua standalone mode, always return true
    if not isRobloxEnvironment then
        return true
    end
    
    -- Use pcall for all Roblox-specific operations
    local success, result = pcall(function()
        local character = player.Character
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        
        if not humanoidRootPart or not head then 
            return false 
        end
        
        -- Check if either head or HRP is visible
        local originParts = {head, humanoidRootPart}
        
        for _, originPart in ipairs(originParts) do
            -- Update raycast params to exclude current player's character
            raycastParams.FilterDescendantsInstances = {players.LocalPlayer.Character}
            
            -- Safely handle Vector3 operations
            local targetPos = originPart.Position
            local cameraPos = camera.CFrame.Position
            
            -- Create direction vector and ensure it has a Unit property/method
            local direction
            if typeof(targetPos) == "Vector3" and typeof(cameraPos) == "Vector3" then
                direction = (targetPos - cameraPos).Unit
            else
                -- Mock direction in case we don't have proper Vector3
                direction = {x=0, y=0, z=1, Unit=1}
            end
            
            local ray = workspace:Raycast(cameraPos, direction * 1000, raycastParams)
            
            -- If we don't hit anything or we hit the target player, they're visible
            if not ray or (ray.Instance and ray.Instance:IsDescendantOf(character)) then
                return true
            end
        end
        
        return false
    end)
    
    return success and result or true -- Default to visible on error
end

-- Check if a player should be ignored due to transparency
function PlayerDetection:ShouldIgnore(player)
    if not self.IgnoreInvisible then return false end
    if not player or not player.Character then return true end
    
    -- In Lua standalone mode, always return false (don't ignore)
    if not isRobloxEnvironment then
        return false
    end
    
    -- Use pcall for all Roblox-specific operations
    local success, result = pcall(function()
        local character = player.Character
        
        -- Check for invisibility
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Transparency >= 0.9 then
                return true
            end
        end
        
        return false
    end)
    
    return success and result or false -- Default to not ignore on error
end

-- Update valid targets
function PlayerDetection:UpdateTargets()
    validTargets = {}
    
    if not main.Enabled or not players.LocalPlayer then return end
    
    -- Exclude player's own character from raycast
    if players.LocalPlayer.Character then
        raycastParams.FilterDescendantsInstances = {players.LocalPlayer.Character}
    end
    
    -- Find valid targets
    for _, player in ipairs(players:GetPlayers()) do
        -- Skip local player and various checks using if/else instead of continue
        if player ~= players.LocalPlayer then
            if self:IsAlive(player) then
                if not (self.TeamCheck and player.Team == players.LocalPlayer.Team) then
                    if not self:ShouldIgnore(player) then
                        if self:IsVisible(player) then
                            -- Player is a valid target
                            table.insert(validTargets, player)
                        end
                    end
                end
            end
        end
    end
end

-- Get valid targets
function PlayerDetection:GetTargets()
    return validTargets
end

-- Toggle team check
function PlayerDetection:ToggleTeamCheck(enabled)
    self.TeamCheck = enabled
end

-- Toggle visibility check
function PlayerDetection:ToggleVisibilityCheck(enabled)
    self.VisibilityCheck = enabled
end

-- Cleanup
function PlayerDetection:Cleanup()
    -- Disconnect all events
    for _, connection in ipairs(connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    connections = {}
    
    validTargets = {}
end

return PlayerDetection
