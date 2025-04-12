--[[
    Config Controller
    Handles saving and loading configuration
]]

local ConfigController = {}

-- Private variables
local dataStoreService = game:GetService("DataStoreService")
local httpService = game:GetService("HttpService")
local config = {}
local configStore = nil
local configKey = "SyferConfig_"
local controllers = {}

-- Check if we're in Roblox environment
local isRobloxEnvironment = (typeof ~= nil)

-- Create warn function if it doesn't exist (for standalone mode)
if not warn then
    warn = function(msg)
        print("WARNING: " .. msg)
    end
end

-- Initialize the controller
function ConfigController:Initialize()
    -- Try to get DataStore (may not work in all environments)
    local success, result = pcall(function()
        return dataStoreService:GetDataStore("SyferConfigStore")
    end)
    
    if success then
        configStore = result
    else
        warn("DataStore not available: " .. tostring(result))
    end
    
    return self
end

-- Set controllers
function ConfigController:SetControllers(controllersTable)
    controllers = controllersTable
end

-- Save config
function ConfigController:SaveConfig()
    if not controllers.AimbotController or not controllers.ESPController or not controllers.TriggerController then
        warn("Cannot save config: controllers not set")
        return
    end
    
    -- Create config object
    local configData = {
        aimbot = {
            enabled = controllers.AimbotController.Enabled,
            fov = controllers.AimbotController.FOV,
            smoothness = controllers.AimbotController.Smoothness,
            targetPart = controllers.AimbotController.TargetPart,
            multiBone = controllers.AimbotController.MultiBone,
            visualizeFOV = controllers.AimbotController.VisualizeTargetFOV
        },
        esp = {
            enabled = controllers.ESPController.Enabled,
            showBoxes = controllers.ESPController.ShowBoxes,
            showNames = controllers.ESPController.ShowNames,
            showDistance = controllers.ESPController.ShowDistance,
            showHealth = controllers.ESPController.ShowHealth,
            showTracers = controllers.ESPController.ShowTracers,
            teamCheck = controllers.ESPController.TeamCheck,
            teamColor = controllers.ESPController.TeamColor,
            tracerOrigin = controllers.ESPController.TracerOrigin
        },
        trigger = {
            enabled = controllers.TriggerController.Enabled,
            delay = controllers.TriggerController.Delay,
            interval = controllers.TriggerController.Interval,
            teamCheck = controllers.TriggerController.TeamCheck
        }
    }
    
    -- Save to local storage
    self:SaveLocal(configData)
    
    -- Try to save to DataStore
    self:SaveToDataStore(configData)
    
    print("Configuration saved")
end

-- Save to local storage
function ConfigController:SaveLocal(configData)
    -- Convert to JSON
    local jsonData = httpService:JSONEncode(configData)
    
    -- Save with writefile (if available)
    local success, error = pcall(function()
        writefile("syfer_config.json", jsonData)
    end)
    
    if not success then
        -- Fallback to local variable
        config = configData
    end
end

-- Save to DataStore
function ConfigController:SaveToDataStore(configData)
    if not configStore then return end
    
    -- Get player ID for config key
    local playerId = game.Players.LocalPlayer.UserId
    local key = configKey .. tostring(playerId)
    
    -- Convert to JSON
    local jsonData = httpService:JSONEncode(configData)
    
    -- Try to save
    local success, error = pcall(function()
        configStore:SetAsync(key, jsonData)
    end)
    
    if not success then
        warn("Failed to save to DataStore: " .. tostring(error))
    end
end

-- Load config
function ConfigController:LoadConfig()
    -- Try to load from local storage first
    local configData = self:LoadLocal()
    
    -- If that fails, try DataStore
    if not configData then
        configData = self:LoadFromDataStore()
    end
    
    -- If we have config data, apply it
    if configData then
        self:ApplyConfig(configData)
        print("Configuration loaded")
    else
        print("No saved configuration found, using defaults")
    end
end

-- Load from local storage
function ConfigController:LoadLocal()
    -- Try to load with readfile (if available)
    local success, result = pcall(function()
        return readfile("syfer_config.json")
    end)
    
    if success then
        -- Parse JSON
        local success2, configData = pcall(function()
            return httpService:JSONDecode(result)
        end)
        
        if success2 then
            return configData
        end
    end
    
    -- Fallback to local variable
    if next(config) ~= nil then
        return config
    end
    
    return nil
end

-- Load from DataStore
function ConfigController:LoadFromDataStore()
    if not configStore then return nil end
    
    -- Get player ID for config key
    local playerId = game.Players.LocalPlayer.UserId
    local key = configKey .. tostring(playerId)
    
    -- Try to load
    local success, result = pcall(function()
        return configStore:GetAsync(key)
    end)
    
    if success and result then
        -- Parse JSON
        local success2, configData = pcall(function()
            return httpService:JSONDecode(result)
        end)
        
        if success2 then
            return configData
        end
    end
    
    return nil
end

-- Apply config
function ConfigController:ApplyConfig(configData)
    if not controllers.AimbotController or not controllers.ESPController or not controllers.TriggerController then
        warn("Cannot apply config: controllers not set")
        return
    end
    
    -- Apply Aimbot settings
    if configData.aimbot then
        if configData.aimbot.enabled then
            controllers.AimbotController:Enable()
        else
            controllers.AimbotController:Disable()
        end
        
        controllers.AimbotController:SetFOV(configData.aimbot.fov or 14.0)
        controllers.AimbotController:SetSmoothness(configData.aimbot.smoothness or 0.1)
        controllers.AimbotController:SetTargetPart(configData.aimbot.targetPart or "Head")
        controllers.AimbotController:ToggleMultiBone(configData.aimbot.multiBone or false)
        controllers.AimbotController.VisualizeTargetFOV = configData.aimbot.visualizeFOV or true
    end
    
    -- Apply ESP settings
    if configData.esp then
        if configData.esp.enabled then
            controllers.ESPController:Enable()
        else
            controllers.ESPController:Disable()
        end
        
        controllers.ESPController:ToggleBoxes(configData.esp.showBoxes or true)
        controllers.ESPController:ToggleNames(configData.esp.showNames or true)
        controllers.ESPController:ToggleDistance(configData.esp.showDistance or true)
        controllers.ESPController:ToggleHealth(configData.esp.showHealth or true)
        controllers.ESPController:ToggleTracers(configData.esp.showTracers or true)
        controllers.ESPController:ToggleTeamCheck(configData.esp.teamCheck or true)
        controllers.ESPController:ToggleTeamColor(configData.esp.teamColor or false)
        controllers.ESPController.TracerOrigin = configData.esp.tracerOrigin or "Bottom"
    end
    
    -- Apply Trigger settings
    if configData.trigger then
        if configData.trigger.enabled then
            controllers.TriggerController:Enable()
        else
            controllers.TriggerController:Disable()
        end
        
        controllers.TriggerController:SetDelay(configData.trigger.delay or 50)
        controllers.TriggerController:SetInterval(configData.trigger.interval or 50)
        controllers.TriggerController:ToggleTeamCheck(configData.trigger.teamCheck or true)
    end
end

-- Reset config to defaults
function ConfigController:ResetConfig()
    if not controllers.AimbotController or not controllers.ESPController or not controllers.TriggerController then
        warn("Cannot reset config: controllers not set")
        return
    end
    
    -- Reset Aimbot settings
    controllers.AimbotController:Disable()
    controllers.AimbotController:SetFOV(14.0)
    controllers.AimbotController:SetSmoothness(0.1)
    controllers.AimbotController:SetTargetPart("Head")
    controllers.AimbotController:ToggleMultiBone(false)
    controllers.AimbotController.VisualizeTargetFOV = true
    
    -- Reset ESP settings
    controllers.ESPController:Disable()
    controllers.ESPController:ToggleBoxes(true)
    controllers.ESPController:ToggleNames(true)
    controllers.ESPController:ToggleDistance(true)
    controllers.ESPController:ToggleHealth(true)
    controllers.ESPController:ToggleTracers(true)
    controllers.ESPController:ToggleTeamCheck(true)
    controllers.ESPController:ToggleTeamColor(false)
    controllers.ESPController.TracerOrigin = "Bottom"
    
    -- Reset Trigger settings
    controllers.TriggerController:Disable()
    controllers.TriggerController:SetDelay(50)
    controllers.TriggerController:SetInterval(50)
    controllers.TriggerController:ToggleTeamCheck(true)
    
    print("Configuration reset to defaults")
    
    -- Save the reset config
    self:SaveConfig()
end

return ConfigController
