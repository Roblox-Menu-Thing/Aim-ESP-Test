--[[
    Syfer-eng Roblox Edition - Demo Interface
    This script provides a simple console-based demonstration of the Syfer-eng functionality
]]

print([[
=============================================================
          SYFER-ENG ROBLOX EDITION - DEMO INTERFACE
=============================================================
This is a demonstration of Syfer-eng, a Roblox Lua-based game
enhancement tool with aimbot, ESP, and triggerbot functionality
featuring a clean, intuitive UI.

In an actual Roblox game, the tool would provide:
- Aimbot with customizable FOV, smoothness, and target selection
- ESP wallhack with player boxes, names, health bars, and tracers
- Triggerbot with customizable delay and team check
- Persistent configuration system
=============================================================
]])

-- Load the main module
local SyferMain = require("MainModule")

-- Simple demo menu system
local function showMenu()
    print("\nSYFER-ENG DEMO MENU:")
    print("1. Toggle Aimbot")
    print("2. Toggle ESP")
    print("3. Toggle Triggerbot")
    print("4. Toggle All Features")
    print("5. Show Feature Status")
    print("6. Exit Demo")
    print("\nEnter selection (1-6): ")
end

-- Controllers (get references from the main module)
local AimbotController = package.loaded["client.AimbotController"]
local ESPController = package.loaded["client.ESPController"]
local TriggerController = package.loaded["client.TriggerController"]

-- Main demo loop
local running = true
while running do
    showMenu()
    local choice = io.read()
    
    if choice == "1" then
        AimbotController.Enabled = not AimbotController.Enabled
        print("Aimbot " .. (AimbotController.Enabled and "ENABLED" or "DISABLED"))
    elseif choice == "2" then
        ESPController.Enabled = not ESPController.Enabled
        print("ESP " .. (ESPController.Enabled and "ENABLED" or "DISABLED"))
    elseif choice == "3" then
        TriggerController.Enabled = not TriggerController.Enabled
        print("Triggerbot " .. (TriggerController.Enabled and "ENABLED" or "DISABLED"))
    elseif choice == "4" then
        SyferMain:Toggle()
    elseif choice == "5" then
        print("\nFEATURE STATUS:")
        print("Master Switch: " .. (SyferMain.Enabled and "ON" or "OFF"))
        print("Aimbot: " .. (AimbotController.Enabled and "ON" or "OFF"))
        print("ESP: " .. (ESPController.Enabled and "ON" or "OFF"))
        print("Triggerbot: " .. (TriggerController.Enabled and "ON" or "OFF"))
    elseif choice == "6" then
        running = false
        print("Exiting demo...")
    else
        print("Invalid selection! Please enter a number from 1-6.")
    end
end

-- Clean up before exit
SyferMain:Cleanup()
print("Thank you for trying the Syfer-eng Demo!")