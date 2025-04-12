--[[
    ESP Controller
    Handles rendering of player ESP (wallhack)
]]

local ESPController = {}

-- Check if we're in Roblox environment
local isRobloxEnvironment = (typeof ~= nil and typeof(Color3) == "table")

-- Configuration
ESPController.Enabled = false
ESPController.ShowBoxes = true
ESPController.ShowNames = true
ESPController.ShowDistance = true
ESPController.ShowHealth = true
ESPController.ShowTracers = true
ESPController.TeamCheck = true  -- Don't show ESP for teammates
ESPController.TeamColor = false -- Use team colors
ESPController.TextSize = 14
ESPController.BoxThickness = 1
ESPController.TracerThickness = 1
ESPController.TracerOrigin = "Bottom" -- "Bottom", "Top", "Center"

-- Initialize Roblox-specific properties only if in Roblox environment
if isRobloxEnvironment and Color3 and typeof(Color3.fromRGB) == "function" then
    ESPController.BoxColor = Color3.fromRGB(255, 0, 0)
    ESPController.TextColor = Color3.fromRGB(255, 255, 255)
    ESPController.TracerColor = Color3.fromRGB(255, 255, 0)
else
    -- Mock values for standalone Lua
    ESPController.BoxColor = {R=255, G=0, B=0}
    ESPController.TextColor = {R=255, G=255, B=255}
    ESPController.TracerColor = {R=255, G=255, B=0}
end

-- Private variables
local runService = nil
local players = nil
local camera = nil
local connections = {}
local espObjects = {}
local main = nil
local playerDetection = nil

-- Initialize the controller
function ESPController:Initialize(mainController, detectionController)
    main = mainController
    playerDetection = detectionController
    
    -- Initialize Roblox services if available
    if isRobloxEnvironment and game then
        -- Try to get services
        local success, result = pcall(function()
            runService = game:GetService("RunService")
            players = game:GetService("Players")
            camera = workspace.CurrentCamera
            return true
        end)
        
        if not success then
            print("ESPController: Failed to get Roblox services - " .. tostring(result))
        end
    else
        -- Mock services for standalone Lua
        print("ESPController: Using mock services for standalone Lua")
        runService = {
            RenderStepped = {
                Connect = function() return { Connected = true, Disconnect = function() end } end
            }
        }
        players = {
            LocalPlayer = { Team = nil },
            PlayerAdded = {
                Connect = function() return { Connected = true, Disconnect = function() end } end
            },
            PlayerRemoving = {
                Connect = function() return { Connected = true, Disconnect = function() end } end
            },
            GetPlayers = function() return {} end -- Empty player list in demo mode
        }
        camera = {
            ViewportSize = { X = 800, Y = 600 },
            WorldToViewportPoint = function(self, pos) return { X = 400, Y = 300, Z = 10 } end,
            CFrame = {
                Position = { X = 0, Y = 0, Z = 0 }
            }
        }
    end
    
    return self
end

-- Enable ESP
function ESPController:Enable()
    if self.Enabled then return end
    
    self.Enabled = true
    
    -- Create ESP objects for all current players
    for _, player in pairs(players:GetPlayers()) do
        if player ~= players.LocalPlayer then
            self:CreateESPForPlayer(player)
        end
    end
    
    -- Connect player joining/leaving
    table.insert(connections, players.PlayerAdded:Connect(function(player)
        self:CreateESPForPlayer(player)
    end))
    
    table.insert(connections, players.PlayerRemoving:Connect(function(player)
        self:RemoveESPForPlayer(player)
    end))
    
    -- Connect update
    table.insert(connections, runService.RenderStepped:Connect(function()
        self:Update()
    end))
    
    print("ESP enabled")
end

-- Disable ESP
function ESPController:Disable()
    if not self.Enabled then return end
    
    self.Enabled = false
    
    -- Remove all ESP objects
    for player, objects in pairs(espObjects) do
        self:ClearESPObjects(objects)
    end
    espObjects = {}
    
    -- Disconnect all events
    for _, connection in ipairs(connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    connections = {}
    
    print("ESP disabled")
end

-- Create ESP objects for a player
function ESPController:CreateESPForPlayer(player)
    if espObjects[player] then
        self:RemoveESPForPlayer(player)
    end
    
    local esp = { Player = player }
    
    -- Create Drawing objects if available, or use mock objects
    if isRobloxEnvironment and typeof(Drawing) == "table" then
        -- Real Roblox Drawing API
        esp.Box = Drawing.new("Square")
        esp.Name = Drawing.new("Text")
        esp.Distance = Drawing.new("Text")
        esp.Health = Drawing.new("Text")
        esp.Tracer = Drawing.new("Line")
        
        -- Box setup
        esp.Box.Visible = false
        esp.Box.Color = self.BoxColor
        esp.Box.Thickness = self.BoxThickness
        esp.Box.Filled = false
        esp.Box.Transparency = 1
        
        -- Name setup
        esp.Name.Visible = false
        esp.Name.Color = self.TextColor
        esp.Name.Size = self.TextSize
        esp.Name.Center = true
        esp.Name.Outline = true
        esp.Name.OutlineColor = isRobloxEnvironment and Color3.new(0, 0, 0) or {R=0, G=0, B=0}
        esp.Name.Font = 2 -- UI default
        
        -- Distance setup
        esp.Distance.Visible = false
        esp.Distance.Color = self.TextColor
        esp.Distance.Size = self.TextSize
        esp.Distance.Center = true
        esp.Distance.Outline = true
        esp.Distance.OutlineColor = isRobloxEnvironment and Color3.new(0, 0, 0) or {R=0, G=0, B=0}
        esp.Distance.Font = 2 -- UI default
        
        -- Health setup
        esp.Health.Visible = false
        esp.Health.Color = self.TextColor
        esp.Health.Size = self.TextSize
        esp.Health.Center = true
        esp.Health.Outline = true
        esp.Health.OutlineColor = isRobloxEnvironment and Color3.new(0, 0, 0) or {R=0, G=0, B=0}
        esp.Health.Font = 2 -- UI default
        
        -- Tracer setup
        esp.Tracer.Visible = false
        esp.Tracer.Color = self.TracerColor
        esp.Tracer.Thickness = self.TracerThickness
        esp.Tracer.Transparency = 1
    else
        -- Mock objects for standalone Lua
        local createMockDrawingObject = function(objectType)
            return {
                Visible = false,
                Color = self.BoxColor,
                Thickness = 1,
                Transparency = 1,
                Size = self.TextSize,
                Center = true,
                Outline = true,
                OutlineColor = {R=0, G=0, B=0},
                Font = 2,
                Text = "",
                From = {X=0, Y=0},
                To = {X=0, Y=0},
                Position = {X=0, Y=0},
                SizeObj = {X=0, Y=0},
                Remove = function() end
            }
        end
        
        print("ESPController: Using mock Drawing objects for standalone Lua")
        esp.Box = createMockDrawingObject("Square")
        esp.Name = createMockDrawingObject("Text")
        esp.Distance = createMockDrawingObject("Text")
        esp.Health = createMockDrawingObject("Text")
        esp.Tracer = createMockDrawingObject("Line")
    end
    
    espObjects[player] = esp
end

-- Remove ESP for a player
function ESPController:RemoveESPForPlayer(player)
    local esp = espObjects[player]
    if esp then
        self:ClearESPObjects(esp)
        espObjects[player] = nil
    end
end

-- Clear ESP objects
function ESPController:ClearESPObjects(objects)
    for _, object in pairs(objects) do
        if typeof(object) == "table" and object.Remove then
            object:Remove()
        end
    end
end

-- Update ESP
function ESPController:Update()
    if not self.Enabled or not main.Enabled then
        -- Hide all ESP
        for _, esp in pairs(espObjects) do
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.Distance.Visible = false
            esp.Health.Visible = false
            esp.Tracer.Visible = false
        end
        return
    end
    
    -- Update ESP for all players
    for player, esp in pairs(espObjects) do
        self:UpdateESPForPlayer(player, esp)
    end
end

-- Update ESP for a player
function ESPController:UpdateESPForPlayer(player, esp)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") then
        esp.Box.Visible = false
        esp.Name.Visible = false
        esp.Distance.Visible = false
        esp.Health.Visible = false
        esp.Tracer.Visible = false
        return
    end
    
    -- Check if player is on the team
    if self.TeamCheck and player.Team == players.LocalPlayer.Team then
        esp.Box.Visible = false
        esp.Name.Visible = false
        esp.Distance.Visible = false
        esp.Health.Visible = false
        esp.Tracer.Visible = false
        return
    end
    
    -- Get character info
    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    local head = character:FindFirstChild("Head")
    
    if not humanoidRootPart or not humanoid then return end
    
    -- Check if player is on screen
    local rootPos, rootOnScreen = camera:WorldToViewportPoint(humanoidRootPart.Position)
    
    if not rootOnScreen then
        esp.Box.Visible = false
        esp.Name.Visible = false
        esp.Distance.Visible = false
        esp.Health.Visible = false
        esp.Tracer.Visible = false
        return
    end
    
    -- Determine box size based on character size
    -- Mock Vector3 functions if not in Roblox
    local vect3_add = function(a, b)
        if typeof(a) == "Vector3" and typeof(b) == "Vector3" then
            return a + b -- Real Roblox Vector3 addition
        else
            return {
                X = (a.X or a.x or 0) + (b.X or b.x or 0),
                Y = (a.Y or a.y or 0) + (b.Y or b.y or 0),
                Z = (a.Z or a.z or 0) + (b.Z or b.z or 0)
            }
        end
    end
    
    local vect3_sub = function(a, b)
        if typeof(a) == "Vector3" and typeof(b) == "Vector3" then
            return a - b -- Real Roblox Vector3 subtraction
        else
            return {
                X = (a.X or a.x or 0) - (b.X or b.x or 0),
                Y = (a.Y or a.y or 0) - (b.Y or b.y or 0),
                Z = (a.Z or a.z or 0) - (b.Z or b.z or 0)
            }
        end
    end
    
    -- Create Vector3 based on environment
    local Vector3_create = function(x, y, z)
        if isRobloxEnvironment and typeof(Vector3) == "table" and typeof(Vector3.new) == "function" then
            return Vector3.new(x, y, z)
        else
            return {X = x, Y = y, Z = z}
        end
    end
    
    -- Create Vector2 based on environment
    local Vector2_create = function(x, y)
        if isRobloxEnvironment and typeof(Vector2) == "table" and typeof(Vector2.new) == "function" then
            return Vector2.new(x, y)
        else
            return {X = x, Y = y}
        end
    end
    
    local topPos = camera:WorldToViewportPoint(vect3_add(humanoidRootPart.Position, Vector3_create(0, 3, 0)))
    local bottomPos = camera:WorldToViewportPoint(vect3_sub(humanoidRootPart.Position, Vector3_create(0, 3, 0)))
    
    local boxSize = Vector2_create(
        math.abs(topPos.Y - bottomPos.Y) / 2,
        math.abs(topPos.Y - bottomPos.Y)
    )
    
    local boxPosition = Vector2_create(
        rootPos.X - boxSize.X / 2,
        rootPos.Y - boxSize.Y / 2
    )
    
    -- Calculate distance
    local distance = (humanoidRootPart.Position - camera.CFrame.Position).Magnitude
    distance = math.floor(distance)
    
    -- Determine color
    local color = self.BoxColor
    if self.TeamColor and player.Team then
        color = player.Team.TeamColor.Color
    end
    
    -- Update ESP elements
    
    -- Box
    esp.Box.Size = boxSize
    esp.Box.Position = boxPosition
    esp.Box.Visible = self.ShowBoxes
    esp.Box.Color = color
    
    -- Name
    esp.Name.Text = player.Name
    esp.Name.Position = Vector2_create(boxPosition.X + boxSize.X / 2, boxPosition.Y - 16)
    esp.Name.Visible = self.ShowNames
    esp.Name.Color = color
    
    -- Distance
    esp.Distance.Text = distance .. "m"
    esp.Distance.Position = Vector2_create(boxPosition.X + boxSize.X / 2, boxPosition.Y + boxSize.Y + 2)
    esp.Distance.Visible = self.ShowDistance
    
    -- Health
    local healthPercentage = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    local healthColor
    if isRobloxEnvironment and typeof(Color3) == "table" and typeof(Color3.fromRGB) == "function" then
        healthColor = Color3.fromRGB(
            255 * (1 - healthPercentage),
            255 * healthPercentage,
            0
        )
    else
        healthColor = {
            R = 255 * (1 - healthPercentage),
            G = 255 * healthPercentage,
            B = 0
        }
    end
    
    esp.Health.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
    esp.Health.Position = Vector2_create(boxPosition.X + boxSize.X / 2, boxPosition.Y + boxSize.Y + (self.ShowDistance and 16 or 2))
    esp.Health.Visible = self.ShowHealth
    esp.Health.Color = healthColor
    
    -- Tracer
    local tracerStart
    if self.TracerOrigin == "Bottom" then
        tracerStart = Vector2_create(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
    elseif self.TracerOrigin == "Top" then
        tracerStart = Vector2_create(camera.ViewportSize.X / 2, 0)
    else -- Center
        tracerStart = Vector2_create(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    end
    
    esp.Tracer.From = tracerStart
    esp.Tracer.To = Vector2_create(rootPos.X, rootPos.Y)
    esp.Tracer.Visible = self.ShowTracers
    esp.Tracer.Color = color
end

-- Toggle box ESP
function ESPController:ToggleBoxes(enabled)
    self.ShowBoxes = enabled
end

-- Toggle name ESP
function ESPController:ToggleNames(enabled)
    self.ShowNames = enabled
end

-- Toggle distance ESP
function ESPController:ToggleDistance(enabled)
    self.ShowDistance = enabled
end

-- Toggle health ESP
function ESPController:ToggleHealth(enabled)
    self.ShowHealth = enabled
end

-- Toggle tracer ESP
function ESPController:ToggleTracers(enabled)
    self.ShowTracers = enabled
end

-- Toggle team check
function ESPController:ToggleTeamCheck(enabled)
    self.TeamCheck = enabled
end

-- Toggle team color
function ESPController:ToggleTeamColor(enabled)
    self.TeamColor = enabled
end

-- Cleanup
function ESPController:Cleanup()
    self:Disable()
end

return ESPController
