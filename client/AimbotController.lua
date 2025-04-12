--[[
    Aimbot Controller
    Handles target acquisition and aiming logic
]]

local AimbotController = {}

-- Check if we're in Roblox environment
local isRobloxEnvironment = (typeof ~= nil and typeof(Enum) == "table")

-- Configuration
AimbotController.Enabled = false
AimbotController.FOV = 14.0         -- Target FOV limit
AimbotController.Smoothness = 0.1   -- Aim smoothness (lower = faster)
AimbotController.TargetPart = "Head"
AimbotController.MultiBone = false  -- Target multiple bones
AimbotController.Bones = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}
AimbotController.VisualizeTargetFOV = true

-- Initialize Roblox-specific properties only if in Roblox environment
if isRobloxEnvironment and Enum and Enum.UserInputType then
    AimbotController.Button = Enum.UserInputType.MouseButton2  -- Right mouse button
    AimbotController.FOVColor = Color3.fromRGB(255, 255, 255)
    AimbotController.FOVTransparency = 0.7
else
    -- Mock values for standalone Lua
    AimbotController.Button = "MouseButton2"
    AimbotController.FOVColor = {R=255, G=255, B=255}
    AimbotController.FOVTransparency = 0.7
end

-- Private variables
local runService = nil
local userInputService = nil
local players = nil
local camera = nil
local connections = {}
local isAiming = false
local currentTarget = nil
local targetBone = nil
local main = nil
local playerDetection = nil

-- Initialize services more safely in Initialize function

-- Initialize the controller
function AimbotController:Initialize(mainController, detectionController)
    main = mainController
    playerDetection = detectionController
    
    -- Initialize Roblox services if available
    if isRobloxEnvironment and game then
        -- Try to get services
        local success, result = pcall(function()
            runService = game:GetService("RunService")
            userInputService = game:GetService("UserInputService")
            players = game:GetService("Players")
            camera = workspace.CurrentCamera
            return true
        end)
        
        if not success then
            print("AimbotController: Failed to get Roblox services - " .. tostring(result))
        end
    else
        -- Mock services for standalone Lua
        print("AimbotController: Using mock services for standalone Lua")
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
            }
        }
        players = {}
        camera = {
            ViewportSize = { X = 800, Y = 600 },
            WorldToScreenPoint = function(self, pos) return { X = 400, Y = 300, Z = 10 } end,
            CFrame = {
                Position = { X = 0, Y = 0, Z = 0 },
                Lerp = function(self, target, alpha) return self end
            }
        }
    end
    
    -- Create FOV circle for visualization
    self:CreateFOVCircle()
    
    return self
end

-- Create FOV circle
function AimbotController:CreateFOVCircle()
    if isRobloxEnvironment and typeof(Drawing) == "table" then
        -- Real Roblox Drawing API
        self.FOVCircle = Drawing.new("Circle")
        self.FOVCircle.Visible = false
        self.FOVCircle.Radius = self.FOV * 10
        self.FOVCircle.Color = self.FOVColor
        self.FOVCircle.Thickness = 1
        self.FOVCircle.Transparency = self.FOVTransparency
        self.FOVCircle.NumSides = 36
        self.FOVCircle.Filled = false
    else
        -- Mock implementation for standalone Lua
        print("AimbotController: Using mock FOV circle for standalone Lua")
        self.FOVCircle = {
            Visible = false,
            Radius = self.FOV * 10,
            Color = self.FOVColor,
            Thickness = 1,
            Transparency = self.FOVTransparency,
            NumSides = 36,
            Filled = false,
            Position = { X = 400, Y = 300 },
            Remove = function() end
        }
    end
end

-- Update FOV circle
function AimbotController:UpdateFOVCircle()
    if self.FOVCircle then
        self.FOVCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        self.FOVCircle.Radius = self.FOV * 10
        self.FOVCircle.Visible = self.Enabled and self.VisualizeTargetFOV
    end
end

-- Enable the aimbot
function AimbotController:Enable()
    if self.Enabled then return end
    
    self.Enabled = true
    
    -- Update FOV circle
    self:UpdateFOVCircle()
    
    -- Connect input events
    table.insert(connections, userInputService.InputBegan:Connect(function(input)
        if input.UserInputType == self.Button then
            isAiming = true
        end
    end))
    
    table.insert(connections, userInputService.InputEnded:Connect(function(input)
        if input.UserInputType == self.Button then
            isAiming = false
            currentTarget = nil
            targetBone = nil
        end
    end))
    
    -- Connect update
    table.insert(connections, runService.RenderStepped:Connect(function(deltaTime)
        self:Update(deltaTime)
    end))
    
    print("Aimbot enabled")
end

-- Disable the aimbot
function AimbotController:Disable()
    if not self.Enabled then return end
    
    self.Enabled = false
    
    -- Update FOV circle
    if self.FOVCircle then
        self.FOVCircle.Visible = false
    end
    
    -- Disconnect all events
    for _, connection in ipairs(connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    connections = {}
    
    isAiming = false
    currentTarget = nil
    targetBone = nil
    
    print("Aimbot disabled")
end

-- Check if player is within FOV
function AimbotController:IsInFOV(player, part)
    local screenPoint = camera:WorldToScreenPoint(part.Position)
    local vector = Vector2.new(screenPoint.X - camera.ViewportSize.X / 2, screenPoint.Y - camera.ViewportSize.Y / 2)
    return vector.Magnitude <= self.FOV * 10
end

-- Get the best target
function AimbotController:GetBestTarget()
    local bestTarget = nil
    local bestBone = nil
    local closestDistance = self.FOV * 10
    
    local targets = playerDetection:GetTargets()
    
    for _, target in pairs(targets) do
        if self.MultiBone then
            -- Check multiple bones and find the best one
            for _, boneName in ipairs(self.Bones) do
                local part = target.Character:FindFirstChild(boneName)
                if part then
                    local screenPoint = camera:WorldToScreenPoint(part.Position)
                    
                    -- Check if part is visible on screen
                    if screenPoint.Z > 0 then
                        local vector = Vector2.new(screenPoint.X - camera.ViewportSize.X / 2, screenPoint.Y - camera.ViewportSize.Y / 2)
                        local distance = vector.Magnitude
                        
                        if distance < closestDistance then
                            closestDistance = distance
                            bestTarget = target
                            bestBone = part
                        end
                    end
                end
            end
        else
            -- Just check the target part (usually head)
            local part = target.Character:FindFirstChild(self.TargetPart)
            if part then
                local screenPoint = camera:WorldToScreenPoint(part.Position)
                
                -- Check if part is visible on screen
                if screenPoint.Z > 0 then
                    local vector = Vector2.new(screenPoint.X - camera.ViewportSize.X / 2, screenPoint.Y - camera.ViewportSize.Y / 2)
                    local distance = vector.Magnitude
                    
                    if distance < closestDistance then
                        closestDistance = distance
                        bestTarget = target
                        bestBone = part
                    end
                end
            end
        end
    end
    
    return bestTarget, bestBone
end

-- Aim at a target
function AimbotController:AimAt(target, bone, deltaTime)
    if not target or not bone or not target.Character then return end
    
    local aimPosition = bone.Position
    
    -- Calculate aim direction
    local aimDirection = (aimPosition - camera.CFrame.Position).Unit
    local targetCFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + aimDirection)
    
    -- Apply smoothing
    local smoothFactor = math.clamp(self.Smoothness * 10 * deltaTime, 0, 1)
    camera.CFrame = camera.CFrame:Lerp(targetCFrame, smoothFactor)
end

-- Main update loop
function AimbotController:Update(deltaTime)
    if not self.Enabled or not main.Enabled then return end
    
    -- Update FOV circle position
    self:UpdateFOVCircle()
    
    -- If not actively aiming, keep scanning for best target but don't aim
    if not isAiming then
        currentTarget, targetBone = self:GetBestTarget()
        return
    end
    
    -- Use existing target or find a new one
    if not currentTarget or not targetBone then
        currentTarget, targetBone = self:GetBestTarget()
    end
    
    -- Aim at the target
    if currentTarget and targetBone then
        self:AimAt(currentTarget, targetBone, deltaTime)
    end
end

-- Set FOV
function AimbotController:SetFOV(value)
    self.FOV = value
    self:UpdateFOVCircle()
end

-- Set smoothness
function AimbotController:SetSmoothness(value)
    self.Smoothness = value
end

-- Toggle multi-bone targeting
function AimbotController:ToggleMultiBone(enabled)
    self.MultiBone = enabled
end

-- Set target part
function AimbotController:SetTargetPart(part)
    self.TargetPart = part
end

-- Cleanup
function AimbotController:Cleanup()
    self:Disable()
    
    if self.FOVCircle then
        self.FOVCircle:Remove()
        self.FOVCircle = nil
    end
end

return AimbotController
