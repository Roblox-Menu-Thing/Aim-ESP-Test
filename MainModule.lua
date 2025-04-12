--[[
    Syfer-eng Roblox Edition
    Main Module Script
    
    This script serves as the entry point for the game enhancement tool.
    It initializes all controllers and manages the global state.
]]

local SyferMain = {}

-- Determine if we're running in Roblox or standalone Lua
local isRobloxEnvironment = (typeof ~= nil) and (script ~= nil)
local scriptPath = ""

if isRobloxEnvironment and script then
    scriptPath = script.client
else
    scriptPath = "client"
    -- Create stub for print in standalone mode
    if not print then
        print = function(msg) io.write(msg.."\n") end
    end
    -- Create stubs for Roblox-specific functions
    if not typeof then typeof = type end
end

-- Import controllers
local AimbotController = isRobloxEnvironment and require(scriptPath.AimbotController) or require(scriptPath..".AimbotController")
local ESPController = isRobloxEnvironment and require(scriptPath.ESPController) or require(scriptPath..".ESPController")
local TriggerController = isRobloxEnvironment and require(scriptPath.TriggerController) or require(scriptPath..".TriggerController")
local UIController = isRobloxEnvironment and require(scriptPath.UIController) or require(scriptPath..".UIController")
local PlayerDetection = isRobloxEnvironment and require(scriptPath.PlayerDetection) or require(scriptPath..".PlayerDetection")
local ConfigController = isRobloxEnvironment and require(scriptPath.ConfigController) or require(scriptPath..".ConfigController")
local Utilities = isRobloxEnvironment and require(scriptPath.Utilities) or require(scriptPath..".Utilities")

-- Core variables
SyferMain.Enabled = false
SyferMain.Connections = {}
SyferMain.LocalPlayer = nil

-- Create mock Roblox environment for demo mode
if not isRobloxEnvironment then
    -- Mock Roblox services and classes
    game = {
        GetService = function(self, serviceName)
            return {
                Heartbeat = { Connect = function() return { Disconnect = function() end } end },
                RenderStepped = { Connect = function() return { Disconnect = function() end } end },
                IsClient = function() return true end,
                CurrentCamera = { 
                    ViewportSize = { X = 1920, Y = 1080 },
                    CFrame = { Position = Vector3.new(0, 0, 0) }
                }
            }
        end,
        Players = {
            LocalPlayer = { 
                Character = {},
                PlayerGui = {},
                UserId = 1
            },
            GetPlayers = function() return {} end
        }
    }
    
    -- Mock Vector types
    if not Vector2 then
        Vector2 = {
            new = function(x, y) return {X = x, Y = y, Magnitude = math.sqrt(x*x + y*y)} end
        }
    end
    
    if not Vector3 then
        Vector3 = {
            new = function(x, y, z) return {X = x, Y = y, Z = z, Magnitude = math.sqrt(x*x + y*y + z*z), Unit = {X=0, Y=0, Z=1}} end
        }
    end
    
    -- Mock Enum
    Enum = {
        KeyCode = { RightShift = "RightShift" },
        UserInputType = { MouseButton2 = "MouseButton2" }
    }

    -- Mock Drawing
    Drawing = {
        new = function() 
            return {
                Visible = false,
                Remove = function() end
            }
        end
    }
    
    workspace = {
        CurrentCamera = {
            ViewportSize = { X = 1920, Y = 1080 },
            WorldToScreenPoint = function() return Vector2.new(960, 540), true end,
            CFrame = { 
                Position = Vector3.new(0, 0, 0),
                LookVector = Vector3.new(0, 0, 1)
            }
        }
    }
    
    SyferMain.RunService = game:GetService("RunService")
    SyferMain.UserInputService = game:GetService("UserInputService") 
    SyferMain.Players = game.Players
else
    SyferMain.RunService = game:GetService("RunService")
    SyferMain.UserInputService = game:GetService("UserInputService")
    SyferMain.Players = game:GetService("Players")
end

-- Initialize the module
function SyferMain:Initialize()
    if isRobloxEnvironment then
        self.LocalPlayer = self.Players.LocalPlayer
        
        if not self.LocalPlayer then
            self.LocalPlayer = self.Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        end
    else
        self.LocalPlayer = self.Players.LocalPlayer
    end
    
    -- Initialize all controllers
    print("Initializing Config Controller...")
    ConfigController:Initialize()
    
    print("Initializing Player Detection...")
    PlayerDetection:Initialize(self)
    
    print("Initializing Aimbot Controller...")
    AimbotController:Initialize(self, PlayerDetection)
    
    print("Initializing ESP Controller...")
    ESPController:Initialize(self, PlayerDetection)
    
    print("Initializing Trigger Controller...")
    TriggerController:Initialize(self, PlayerDetection, AimbotController)
    
    print("Initializing UI Controller...")
    UIController:Initialize(self, {
        AimbotController = AimbotController,
        ESPController = ESPController,
        TriggerController = TriggerController,
        ConfigController = ConfigController
    })
    
    -- Load saved config
    ConfigController:LoadConfig()
    
    -- Setup global hotkeys
    self:SetupHotkeys()
    
    print("Syfer-eng Roblox Edition initialized successfully")
    self.Enabled = true
    
    return self
end

-- Toggle the entire system on/off
function SyferMain:Toggle()
    self.Enabled = not self.Enabled
    
    if self.Enabled then
        AimbotController:Enable()
        ESPController:Enable()
        TriggerController:Enable()
    else
        AimbotController:Disable()
        ESPController:Disable()
        TriggerController:Disable()
    end
    
    if isRobloxEnvironment then
        UIController:UpdateMainToggle(self.Enabled)
        ConfigController:SaveConfig()
    else
        print("System toggled: " .. (self.Enabled and "ON" or "OFF"))
    end
end

-- Setup global hotkeys
function SyferMain:SetupHotkeys()
    if isRobloxEnvironment then
        table.insert(self.Connections, self.UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            -- Main toggle hotkey (Right Shift)
            if input.KeyCode == Enum.KeyCode.RightShift then
                self:Toggle()
            end
        end))
    else
        print("Hotkeys set up (Demo mode: not functional in standalone Lua)")
    end
end

-- Cleanup function
function SyferMain:Cleanup()
    if isRobloxEnvironment then
        -- Disconnect all connections
        for _, connection in ipairs(self.Connections) do
            if connection.Connected then
                connection:Disconnect()
            end
        end
    end
    
    -- Cleanup all controllers
    AimbotController:Cleanup()
    ESPController:Cleanup()
    TriggerController:Cleanup()
    UIController:Cleanup()
    
    -- Save config before exit
    if isRobloxEnvironment then
        ConfigController:SaveConfig()
    end
    
    self.Enabled = false
    print("Syfer-eng Roblox Edition cleaned up")
end

-- Handle different execution environments
if isRobloxEnvironment then
    -- Run as a LocalScript if in PlayerScripts
    if SyferMain.RunService:IsClient() and script.Parent == game.Players.LocalPlayer.PlayerScripts then
        SyferMain:Initialize()
        
        -- Setup cleanup on script removal
        script.AncestryChanged:Connect(function()
            if not script:IsDescendantOf(game) then
                SyferMain:Cleanup()
            end
        end)
    end
else
    -- Run in standalone mode for demo
    print("Running in standalone demo mode...")
    SyferMain:Initialize()
    print("\nThis demo simulates the Syfer-eng Roblox Edition.")
    print("In a real Roblox environment, you would see a full UI and functionality.")
    print("Aimbot, ESP, and TriggerBot controllers have been initialized.")
    print("\nDemo version for educational purposes only.")
    -- Toggle once to demonstrate
    SyferMain:Toggle()
end

return SyferMain
