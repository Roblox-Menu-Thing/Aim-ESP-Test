--[[
    UI Controller
    Handles the user interface for the cheat
]]

local UIController = {}

-- Check if we're in Roblox environment
local isRobloxEnvironment = (typeof ~= nil and Instance ~= nil)

-- Create mock Instance class if we're not in Roblox
if not isRobloxEnvironment then
    Instance = {
        new = function(className)
            local mockInstance = {
                Name = "",
                ClassName = className,
                Parent = nil,
                Position = {X = {Scale = 0, Offset = 0}, Y = {Scale = 0, Offset = 0}},
                Size = {X = {Scale = 0, Offset = 0}, Y = {Scale = 0, Offset = 0}},
                BackgroundColor3 = {R = 1, G = 1, B = 1},
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                Visible = true,
                Enabled = true,
                ZIndex = 1,
                Text = "",
                TextColor3 = {R = 0, G = 0, B = 0},
                TextSize = 14,
                CornerRadius = {Scale = 0, Offset = 0},
                Active = false,
                Draggable = false,
                LayoutOrder = 0,
                
                -- Methods
                FindFirstChild = function(self, name)
                    return nil
                end,
                
                FindFirstChildOfClass = function(self, className)
                    return nil
                end,
                
                IsA = function(self, className)
                    return self.ClassName == className
                end,
                
                IsDescendantOf = function(self, ancestor)
                    return false
                end,
                
                GetDescendants = function(self)
                    return {}
                end,
                
                -- Event functions that return mock connections
                MouseButton1Click = {
                    Connect = function(self, callback)
                        return {Connected = true, Disconnect = function() end}
                    end
                },
                
                InputBegan = {
                    Connect = function(self, callback)
                        return {Connected = true, Disconnect = function() end}
                    end
                },
                
                -- Functions for positioning
                TweenPosition = function(self, position, easingDirection, easingStyle, duration, override, callback)
                    self.Position = position
                    if callback then callback() end
                    return {
                        Play = function() end
                    }
                end
            }
            return mockInstance
        end
    }
    
    print("UIController: Created mock Instance implementation for standalone Lua")
    
    -- Mock Color3 if it doesn't exist
    if not Color3 then
        Color3 = {
            fromRGB = function(r, g, b)
                return {R = r/255, G = g/255, B = b/255}
            end,
            
            new = function(r, g, b)
                return {R = r, G = g, B = b}
            end
        }
        print("UIController: Created mock Color3 implementation for standalone Lua")
    end
    
    -- Mock Enum if it doesn't exist
    if not Enum then
        Enum = {
            Font = {
                SourceSans = 0,
                SourceSansBold = 1
            },
            TextXAlignment = {
                Left = 0,
                Center = 1,
                Right = 2
            },
            HorizontalAlignment = {
                Center = 1
            },
            ZIndexBehavior = {
                Sibling = 0
            },
            SortOrder = {
                LayoutOrder = 0
            },
            ScrollingDirection = {
                X = 0,
                Y = 1,
                XY = 2
            },
            AutomaticSize = {
                None = 0,
                X = 1,
                Y = 2,
                XY = 3
            },
            KeyCode = {
                RightAlt = 308
            }
        }
        print("UIController: Created mock Enum implementation for standalone Lua")
    end
    
    -- Mock UDim and UDim2 if they don't exist
    if not UDim then
        UDim = {
            new = function(scale, offset)
                return {Scale = scale, Offset = offset}
            end
        }
        print("UIController: Created mock UDim implementation for standalone Lua")
    end
    
    if not UDim2 then
        UDim2 = {
            new = function(xScale, xOffset, yScale, yOffset)
                return {
                    X = {Scale = xScale, Offset = xOffset},
                    Y = {Scale = yScale, Offset = yOffset}
                }
            end
        }
        print("UIController: Created mock UDim2 implementation for standalone Lua")
    end
    
    -- Mock game service object
    if not game then
        game = {
            GetService = function(self, serviceName)
                if serviceName == "CoreGui" then
                    return {}
                elseif serviceName == "Players" then
                    return {
                        LocalPlayer = {
                            PlayerGui = {},
                            WaitForChild = function(_, name) return {} end
                        }
                    }
                elseif serviceName == "UserInputService" then
                    return {
                        InputBegan = {
                            Connect = function(_, callback)
                                return {Connected = true, Disconnect = function() end}
                            end
                        }
                    }
                end
                return {}
            end,
            
            Players = {
                LocalPlayer = {
                    PlayerGui = {},
                    WaitForChild = function(_, name) return {} end
                }
            }
        }
        print("UIController: Created mock game service for standalone Lua")
    end
end

-- Helper function to safely set Roblox properties
local function safeSetProperty(instance, property, enumType, enumValue)
    pcall(function()
        if Enum and Enum[enumType] and Enum[enumType][enumValue] then
            instance[property] = Enum[enumType][enumValue]
        end
    end)
end

-- Mock UDim2 for standalone Lua
local UDim2_new
if isRobloxEnvironment and UDim2 and typeof(UDim2.new) == "function" then
    UDim2_new = UDim2.new
else
    UDim2_new = function(xScale, xOffset, yScale, yOffset)
        return {
            Scale = {X = xScale, Y = yScale},
            Offset = {X = xOffset, Y = yOffset},
            X = {Scale = xScale, Offset = xOffset},
            Y = {Scale = yScale, Offset = yOffset}
        }
    end
end

-- Mock Color3 for standalone Lua
local Color3_fromRGB
if isRobloxEnvironment and Color3 and typeof(Color3.fromRGB) == "function" then
    Color3_fromRGB = Color3.fromRGB
else
    Color3_fromRGB = function(r, g, b)
        return {R = r/255, G = g/255, B = b/255}
    end
end

-- Constants using our safe functions
local GUI_SIZE = UDim2_new(0, 300, 0, 400)
local MAIN_COLOR = Color3_fromRGB(45, 45, 45)
local ACCENT_COLOR = Color3_fromRGB(35, 35, 35)
local TEXT_COLOR = Color3_fromRGB(255, 255, 255)
local HIGHLIGHT_COLOR = Color3_fromRGB(44, 120, 220)
local TOGGLE_ON_COLOR = Color3_fromRGB(0, 180, 60)
local TOGGLE_OFF_COLOR = Color3_fromRGB(180, 0, 60)

-- Private variables
local screenGui = nil
local mainFrame = nil
local controllers = {}
local currentTab = nil
local tabs = {}
local main = nil
local connections = {}

-- Initialize the controller
function UIController:Initialize(mainController, controllersTable)
    main = mainController
    controllers = controllersTable
    
    -- Create the UI
    self:CreateUI()
    
    return self
end

-- Create the UI
function UIController:CreateUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SyferUI"
    screenGui.ResetOnSpawn = false
    
    -- Handle different environments - set ZIndexBehavior with a pcall to catch errors
    pcall(function()
        if Enum and Enum.ZIndexBehavior and Enum.ZIndexBehavior.Sibling then
            screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        end
    end)
    
    screenGui.DisplayOrder = 999
    
    -- Try to use CoreGui (less detectable)
    local success, error = pcall(function()
        screenGui.Parent = game:GetService("CoreGui")
    end)
    
    if not success then
        screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Create main frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = GUI_SIZE
    mainFrame.Position = UDim2.new(0.8, -GUI_SIZE.X.Offset, 0.5, -GUI_SIZE.Y.Offset/2)
    mainFrame.BackgroundColor3 = MAIN_COLOR
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    -- Add rounded corners
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 5)
    uiCorner.Parent = mainFrame
    
    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = ACCENT_COLOR
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 5)
    titleCorner.Parent = titleBar
    
    -- Fix corners for title bar
    local bottomFrame = Instance.new("Frame")
    bottomFrame.Name = "BottomFrame"
    bottomFrame.Size = UDim2.new(1, 0, 0, 15)
    bottomFrame.Position = UDim2.new(0, 0, 1, -15)
    bottomFrame.BackgroundColor3 = ACCENT_COLOR
    bottomFrame.BorderSizePixel = 0
    bottomFrame.ZIndex = 0
    bottomFrame.Parent = titleBar
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, -60, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.TextColor3 = TEXT_COLOR
    titleText.TextSize = 16
    
    -- Handle Font in different environments
    pcall(function()
        if Enum and Enum.Font and Enum.Font.SourceSansBold then
            titleText.Font = Enum.Font.SourceSansBold
        end
    end)
    
    titleText.Text = "Syfer-eng Roblox Edition"
    
    -- Handle TextXAlignment in different environments
    pcall(function()
        if Enum and Enum.TextXAlignment and Enum.TextXAlignment.Left then
            titleText.TextXAlignment = Enum.TextXAlignment.Left
        end
    end)
    
    titleText.Parent = titleBar
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 24, 0, 24)
    closeButton.Position = UDim2.new(1, -27, 0, 3)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 18
    
    -- Safely set font
    safeSetProperty(closeButton, "Font", "Font", "SourceSansBold")
    
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    -- Minimize button
    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Name = "MinimizeButton"
    minimizeButton.Size = UDim2.new(0, 24, 0, 24)
    minimizeButton.Position = UDim2.new(1, -54, 0, 3)
    minimizeButton.BackgroundColor3 = Color3.fromRGB(230, 180, 40)
    minimizeButton.BorderSizePixel = 0
    minimizeButton.Text = "–"
    minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimizeButton.TextSize = 18
    
    -- Safely set font
    safeSetProperty(minimizeButton, "Font", "Font", "SourceSansBold")
    
    minimizeButton.Parent = titleBar
    
    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 4)
    minimizeCorner.Parent = minimizeButton
    
    -- Tab container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(0, 80, 1, -30)
    tabContainer.Position = UDim2.new(0, 0, 0, 30)
    tabContainer.BackgroundColor3 = ACCENT_COLOR
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = mainFrame
    
    local tabContainerCorner = Instance.new("UICorner")
    tabContainerCorner.CornerRadius = UDim.new(0, 5)
    tabContainerCorner.Parent = tabContainer
    
    -- Fix corners for tab container
    local rightFrame = Instance.new("Frame")
    rightFrame.Name = "RightFrame"
    rightFrame.Size = UDim2.new(0, 15, 1, 0)
    rightFrame.Position = UDim2.new(1, -15, 0, 0)
    rightFrame.BackgroundColor3 = ACCENT_COLOR
    rightFrame.BorderSizePixel = 0
    rightFrame.ZIndex = 0
    rightFrame.Parent = tabContainer
    
    -- Content frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -90, 1, -40)
    contentFrame.Position = UDim2.new(0, 85, 0, 35)
    contentFrame.BackgroundColor3 = MAIN_COLOR
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = mainFrame
    
    -- Create tabs
    self:CreateTabs(tabContainer, contentFrame)
    
    -- Connect events
    closeButton.MouseButton1Click:Connect(function()
        screenGui.Enabled = false
    end)
    
    minimizeButton.MouseButton1Click:Connect(function()
        if contentFrame.Visible then
            contentFrame.Visible = false
            tabContainer.Visible = false
            mainFrame.Size = UDim2.new(0, 300, 0, 30)
        else
            contentFrame.Visible = true
            tabContainer.Visible = true
            mainFrame.Size = GUI_SIZE
        end
    end)
    
    -- Make hotkey to toggle UI visibility (Right Alt) with safe InputBegan connection
    pcall(function()
        local UserInputService = game:GetService("UserInputService")
        if UserInputService and UserInputService.InputBegan then
            local connection = UserInputService.InputBegan:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.RightAlt then
                    screenGui.Enabled = not screenGui.Enabled
                end
            end)
            table.insert(connections, connection)
        end
    end)
end

-- Create tabs
function UIController:CreateTabs(tabContainer, contentFrame)
    -- Create tab buttons
    local tabButtons = {
        {name = "Aimbot", icon = "🎯"},
        {name = "Visuals", icon = "👁️"},
        {name = "Trigger", icon = "🔫"},
        {name = "Settings", icon = "⚙️"}
    }
    
    for i, tabInfo in ipairs(tabButtons) do
        -- Tab button
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabInfo.name .. "Tab"
        tabButton.Size = UDim2.new(1, -10, 0, 40)
        tabButton.Position = UDim2.new(0, 5, 0, 5 + (i-1) * 45)
        tabButton.BackgroundColor3 = MAIN_COLOR
        tabButton.BorderSizePixel = 0
        tabButton.Text = tabInfo.icon .. " " .. tabInfo.name
        tabButton.TextColor3 = TEXT_COLOR
        tabButton.TextSize = 14
        
        -- Safely set font
        safeSetProperty(tabButton, "Font", "Font", "SourceSansBold")
        
        tabButton.Parent = tabContainer
        
        local tabButtonCorner = Instance.new("UICorner")
        tabButtonCorner.CornerRadius = UDim.new(0, 5)
        tabButtonCorner.Parent = tabButton
        
        -- Tab content
        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Name = tabInfo.name .. "Content"
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.BorderSizePixel = 0
        tabContent.ScrollBarThickness = 4
        tabContent.Visible = false
        tabContent.Parent = contentFrame
        
        -- Safely set ScrollingDirection
        pcall(function()
            if Enum and Enum.ScrollingDirection and Enum.ScrollingDirection.Y then
                tabContent.ScrollingDirection = Enum.ScrollingDirection.Y
            end
        end)
        
        -- Safely set AutomaticCanvasSize
        pcall(function()
            if Enum and Enum.AutomaticSize and Enum.AutomaticSize.Y then
                tabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
            end
        end)
        
        -- Add padding
        local tabPadding = Instance.new("UIPadding")
        tabPadding.PaddingLeft = UDim.new(0, 10)
        tabPadding.PaddingRight = UDim.new(0, 10)
        tabPadding.PaddingTop = UDim.new(0, 10)
        tabPadding.PaddingBottom = UDim.new(0, 10)
        tabPadding.Parent = tabContent
        
        -- Add layout
        local tabLayout = Instance.new("UIListLayout")
        tabLayout.Padding = UDim.new(0, 10)
        
        -- Safely set HorizontalAlignment
        pcall(function()
            if Enum and Enum.HorizontalAlignment and Enum.HorizontalAlignment.Center then
                tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            end
        end)
        
        -- Safely set SortOrder
        pcall(function()
            if Enum and Enum.SortOrder and Enum.SortOrder.LayoutOrder then
                tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
            end
        end)
        
        tabLayout.Parent = tabContent
        
        -- Store tab info
        tabs[tabInfo.name] = {
            button = tabButton,
            content = tabContent
        }
        
        -- Button click handler
        tabButton.MouseButton1Click:Connect(function()
            self:SelectTab(tabInfo.name)
        end)
    end
    
    -- Fill tab content
    self:FillAimbotTab(tabs.Aimbot.content)
    self:FillVisualsTab(tabs.Visuals.content)
    self:FillTriggerTab(tabs.Trigger.content)
    self:FillSettingsTab(tabs.Settings.content)
    
    -- Select first tab by default
    self:SelectTab("Aimbot")
end

-- Select a tab
function UIController:SelectTab(tabName)
    -- Hide all content frames
    for name, tab in pairs(tabs) do
        tab.content.Visible = false
        tab.button.BackgroundColor3 = MAIN_COLOR
    end
    
    -- Show selected tab
    tabs[tabName].content.Visible = true
    tabs[tabName].button.BackgroundColor3 = HIGHLIGHT_COLOR
    
    currentTab = tabName
end

-- Create a section
function UIController:CreateSection(parent, title)
    local section = Instance.new("Frame")
    section.Name = title .. "Section"
    section.Size = UDim2.new(1, 0, 0, 30)
    section.BackgroundColor3 = ACCENT_COLOR
    section.BorderSizePixel = 0
    
    -- Safely set AutomaticSize
    pcall(function()
        if Enum and Enum.AutomaticSize and Enum.AutomaticSize.Y then
            section.AutomaticSize = Enum.AutomaticSize.Y
        end
    end)
    
    section.Parent = parent
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, 5)
    sectionCorner.Parent = section
    
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Name = "Title"
    sectionTitle.Size = UDim2.new(1, -20, 0, 30)
    sectionTitle.Position = UDim2.new(0, 10, 0, 0)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.TextColor3 = TEXT_COLOR
    sectionTitle.TextSize = 14
    
    -- Safely set font
    safeSetProperty(sectionTitle, "Font", "Font", "SourceSansBold")
    
    sectionTitle.Text = title
    
    -- Safely set text alignment
    safeSetProperty(sectionTitle, "TextXAlignment", "TextXAlignment", "Left")
    
    sectionTitle.Parent = section
    
    local sectionContent = Instance.new("Frame")
    sectionContent.Name = "Content"
    sectionContent.Size = UDim2.new(1, -20, 0, 0)
    sectionContent.Position = UDim2.new(0, 10, 0, 30)
    sectionContent.BackgroundTransparency = 1
    sectionContent.BorderSizePixel = 0
    
    -- Safely set AutomaticSize
    pcall(function()
        if Enum and Enum.AutomaticSize and Enum.AutomaticSize.Y then
            sectionContent.AutomaticSize = Enum.AutomaticSize.Y
        end
    end)
    
    sectionContent.Parent = section
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 8)
    
    -- Safely set HorizontalAlignment
    pcall(function()
        if Enum and Enum.HorizontalAlignment and Enum.HorizontalAlignment.Center then
            contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        end
    end)
    
    -- Safely set SortOrder
    pcall(function()
        if Enum and Enum.SortOrder and Enum.SortOrder.LayoutOrder then
            contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        end
    end)
    
    contentLayout.Parent = sectionContent
    
    -- Add padding at the bottom
    local paddingFrame = Instance.new("Frame")
    paddingFrame.Name = "Padding"
    paddingFrame.Size = UDim2.new(1, 0, 0, 5)
    paddingFrame.BackgroundTransparency = 1
    paddingFrame.LayoutOrder = 999
    paddingFrame.Parent = sectionContent
    
    return sectionContent
end

-- Create a toggle
function UIController:CreateToggle(parent, text, value, callback)
    local toggle = Instance.new("Frame")
    toggle.Name = text .. "Toggle"
    toggle.Size = UDim2.new(1, 0, 0, 30)
    toggle.BackgroundTransparency = 1
    toggle.Parent = parent
    
    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Name = "Label"
    toggleLabel.Size = UDim2.new(1, -50, 1, 0)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.TextColor3 = TEXT_COLOR
    toggleLabel.TextSize = 14
    
    -- Safely set font
    safeSetProperty(toggleLabel, "Font", "Font", "SourceSans")
    
    toggleLabel.Text = text
    
    -- Safely set text alignment
    safeSetProperty(toggleLabel, "TextXAlignment", "TextXAlignment", "Left")
    
    toggleLabel.Parent = toggle
    
    local toggleButton = Instance.new("Frame")
    toggleButton.Name = "Button"
    toggleButton.Size = UDim2.new(0, 40, 0, 20)
    toggleButton.Position = UDim2.new(1, -40, 0.5, -10)
    toggleButton.BackgroundColor3 = value and TOGGLE_ON_COLOR or TOGGLE_OFF_COLOR
    toggleButton.BorderSizePixel = 0
    toggleButton.Parent = toggle
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 10)
    toggleCorner.Parent = toggleButton
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Name = "Circle"
    toggleCircle.Size = UDim2.new(0, 16, 0, 16)
    toggleCircle.Position = UDim2.new(value and 0.6 or 0.1, 0, 0.5, -8)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleCircle.BorderSizePixel = 0
    toggleCircle.Parent = toggleButton
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = toggleCircle
    
    -- Make the entire toggle clickable
    local button = Instance.new("TextButton")
    button.Name = "ClickRegion"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = toggle
    
    -- Set current state
    local state = value
    
    -- Handle click
    button.MouseButton1Click:Connect(function()
        state = not state
        
        toggleButton.BackgroundColor3 = state and TOGGLE_ON_COLOR or TOGGLE_OFF_COLOR
        toggleCircle:TweenPosition(
            UDim2.new(state and 0.6 or 0.1, 0, 0.5, -8),
            Enum.EasingDirection.InOut,
            Enum.EasingStyle.Quart,
            0.2,
            true
        )
        
        callback(state)
    end)
    
    return {
        Set = function(newValue)
            state = newValue
            toggleButton.BackgroundColor3 = state and TOGGLE_ON_COLOR or TOGGLE_OFF_COLOR
            toggleCircle.Position = UDim2.new(state and 0.6 or 0.1, 0, 0.5, -8)
        end,
        Get = function()
            return state
        end
    }
end

-- Create a slider
function UIController:CreateSlider(parent, text, min, max, value, decimal, callback)
    local slider = Instance.new("Frame")
    slider.Name = text .. "Slider"
    slider.Size = UDim2.new(1, 0, 0, 50)
    slider.BackgroundTransparency = 1
    slider.Parent = parent
    
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Name = "Label"
    sliderLabel.Size = UDim2.new(1, 0, 0, 20)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.TextColor3 = TEXT_COLOR
    sliderLabel.TextSize = 14
    
    -- Safely set font
    safeSetProperty(sliderLabel, "Font", "Font", "SourceSans")
    
    sliderLabel.Text = text
    
    -- Safely set text alignment
    safeSetProperty(sliderLabel, "TextXAlignment", "TextXAlignment", "Left")
    
    sliderLabel.Parent = slider
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(0, 40, 0, 20)
    valueLabel.Position = UDim2.new(1, -40, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = TEXT_COLOR
    valueLabel.TextSize = 14
    
    -- Safely set font
    safeSetProperty(valueLabel, "Font", "Font", "SourceSans")
    
    valueLabel.Text = tostring(value)
    
    -- Safely set text alignment
    safeSetProperty(valueLabel, "TextXAlignment", "TextXAlignment", "Right")
    
    valueLabel.Parent = slider
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Name = "Background"
    sliderBg.Size = UDim2.new(1, 0, 0, 8)
    sliderBg.Position = UDim2.new(0, 0, 0.5, 4)
    sliderBg.BackgroundColor3 = ACCENT_COLOR
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = slider
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 4)
    bgCorner.Parent = sliderBg
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "Fill"
    sliderFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = HIGHLIGHT_COLOR
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = sliderFill
    
    local sliderCircle = Instance.new("Frame")
    sliderCircle.Name = "Circle"
    sliderCircle.Size = UDim2.new(0, 14, 0, 14)
    sliderCircle.Position = UDim2.new((value - min) / (max - min), -7, 0.5, -7)
    sliderCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderCircle.BorderSizePixel = 0
    sliderCircle.Parent = sliderBg
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = sliderCircle
    
    -- Make the slider interactive
    local button = Instance.new("TextButton")
    button.Name = "ClickRegion"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = slider
    
    -- Current value
    local currentValue = value
    
    -- Update function
    local function updateSlider(mouseX)
        local relativePos = math.clamp((mouseX - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local newValue = min + ((max - min) * relativePos)
        
        -- Round to decimal places if specified
        if decimal then
            newValue = math.floor(newValue * 10^decimal + 0.5) / 10^decimal
        else
            newValue = math.floor(newValue)
        end
        
        -- Clamp value to min/max
        newValue = math.clamp(newValue, min, max)
        
        -- Update UI
        sliderFill.Size = UDim2.new(relativePos, 0, 1, 0)
        sliderCircle.Position = UDim2.new(relativePos, -7, 0.5, -7)
        valueLabel.Text = tostring(newValue)
        
        -- Only fire callback if value changed
        if newValue ~= currentValue then
            currentValue = newValue
            callback(newValue)
        end
    end
    
    -- Handle mouse events
    local mouseDown = false
    
    -- Safely connect to MouseButton1Down
    pcall(function()
        if button.MouseButton1Down then
            button.MouseButton1Down:Connect(function()
                mouseDown = true
                updateSlider(game:GetService("UserInputService"):GetMouseLocation().X)
            end)
        end
    end)
    
    -- Safely connect to InputEnded
    pcall(function()
        local UserInputService = game:GetService("UserInputService")
        if UserInputService and UserInputService.InputEnded then
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    mouseDown = false
                end
            end)
        end
    end)
    
    -- Safely connect to InputChanged
    pcall(function() 
        local UserInputService = game:GetService("UserInputService")
        if UserInputService and UserInputService.InputChanged then
            UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement and mouseDown then
                    updateSlider(input.Position.X)
                end
            end)
        end
    end)
    
    return {
        Set = function(newValue)
            newValue = math.clamp(newValue, min, max)
            currentValue = newValue
            local relativePos = (newValue - min) / (max - min)
            sliderFill.Size = UDim2.new(relativePos, 0, 1, 0)
            sliderCircle.Position = UDim2.new(relativePos, -7, 0.5, -7)
            valueLabel.Text = tostring(newValue)
        end,
        Get = function()
            return currentValue
        end
    }
end

-- Create a button
function UIController:CreateButton(parent, text, callback)
    local button = Instance.new("Frame")
    button.Name = text .. "Button"
    button.Size = UDim2.new(1, 0, 0, 30)
    button.BackgroundTransparency = 1
    button.Parent = parent
    
    local buttonFrame = Instance.new("TextButton")
    buttonFrame.Name = "Button"
    buttonFrame.Size = UDim2.new(1, 0, 1, 0)
    buttonFrame.BackgroundColor3 = HIGHLIGHT_COLOR
    buttonFrame.BorderSizePixel = 0
    buttonFrame.Text = text
    buttonFrame.TextColor3 = TEXT_COLOR
    buttonFrame.TextSize = 14
    
    -- Safely set font
    safeSetProperty(buttonFrame, "Font", "Font", "SourceSansBold")
    
    buttonFrame.AutoButtonColor = true
    buttonFrame.Parent = button
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 5)
    buttonCorner.Parent = buttonFrame
    
    -- Handle click
    buttonFrame.MouseButton1Click:Connect(callback)
    
    return buttonFrame
end

-- Create a dropdown
function UIController:CreateDropdown(parent, text, options, callback)
    local dropdown = Instance.new("Frame")
    dropdown.Name = text .. "Dropdown"
    dropdown.Size = UDim2.new(1, 0, 0, 30)
    dropdown.BackgroundTransparency = 1
    dropdown.Parent = parent
    
    local dropdownLabel = Instance.new("TextLabel")
    dropdownLabel.Name = "Label"
    dropdownLabel.Size = UDim2.new(1, 0, 0, 20)
    dropdownLabel.BackgroundTransparency = 1
    dropdownLabel.TextColor3 = TEXT_COLOR
    dropdownLabel.TextSize = 14
    
    -- Safely set font
    safeSetProperty(dropdownLabel, "Font", "Font", "SourceSans")
    
    dropdownLabel.Text = text
    
    -- Safely set text alignment
    safeSetProperty(dropdownLabel, "TextXAlignment", "TextXAlignment", "Left")
    
    dropdownLabel.Parent = dropdown
    
    local dropdownButton = Instance.new("TextButton")
    dropdownButton.Name = "Button"
    dropdownButton.Size = UDim2.new(1, 0, 0, 30)
    dropdownButton.Position = UDim2.new(0, 0, 0, 20)
    dropdownButton.BackgroundColor3 = ACCENT_COLOR
    dropdownButton.BorderSizePixel = 0
    dropdownButton.Text = options[1]
    dropdownButton.TextColor3 = TEXT_COLOR
    dropdownButton.TextSize = 14
    
    -- Safely set font
    safeSetProperty(dropdownButton, "Font", "Font", "SourceSans")
    
    dropdownButton.Parent = dropdown
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 5)
    buttonCorner.Parent = dropdownButton
    
    local dropdownIcon = Instance.new("TextLabel")
    dropdownIcon.Name = "Icon"
    dropdownIcon.Size = UDim2.new(0, 20, 0, 20)
    dropdownIcon.Position = UDim2.new(1, -25, 0, 5)
    dropdownIcon.BackgroundTransparency = 1
    dropdownIcon.TextColor3 = TEXT_COLOR
    dropdownIcon.TextSize = 14
    
    -- Safely set font
    safeSetProperty(dropdownIcon, "Font", "Font", "SourceSansBold")
    
    dropdownIcon.Text = "▼"
    dropdownIcon.Parent = dropdownButton
    
    local dropdownContent = Instance.new("Frame")
    dropdownContent.Name = "Content"
    dropdownContent.Size = UDim2.new(1, 0, 0, #options * 30)
    dropdownContent.Position = UDim2.new(0, 0, 0, 50)
    dropdownContent.BackgroundColor3 = ACCENT_COLOR
    dropdownContent.BorderSizePixel = 0
    dropdownContent.Visible = false
    dropdownContent.ZIndex = 10
    dropdownContent.Parent = dropdown
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 5)
    contentCorner.Parent = dropdownContent
    
    -- Create options
    for i, option in ipairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Name = "Option" .. i
        optionButton.Size = UDim2.new(1, 0, 0, 30)
        optionButton.Position = UDim2.new(0, 0, 0, (i-1) * 30)
        optionButton.BackgroundColor3 = ACCENT_COLOR
        optionButton.BackgroundTransparency = 0.5
        optionButton.BorderSizePixel = 0
        optionButton.Text = option
        optionButton.TextColor3 = TEXT_COLOR
        optionButton.TextSize = 14
        
        -- Safely set font
        safeSetProperty(optionButton, "Font", "Font", "SourceSans")
        
        optionButton.ZIndex = 11
        optionButton.Parent = dropdownContent
        
        -- Handle option click
        optionButton.MouseButton1Click:Connect(function()
            dropdownButton.Text = option
            dropdownContent.Visible = false
            callback(option)
        end)
        
        -- Hover effect with safe connections
        pcall(function()
            if optionButton.MouseEnter then
                optionButton.MouseEnter:Connect(function()
                    optionButton.BackgroundTransparency = 0.2
                end)
            end
            
            if optionButton.MouseLeave then
                optionButton.MouseLeave:Connect(function()
                    optionButton.BackgroundTransparency = 0.5
                end)
            end
        end)
    end
    
    -- Toggle dropdown
    local isOpen = false
    
    -- Safely connect to MouseButton1Click
    pcall(function() 
        if dropdownButton.MouseButton1Click then
            dropdownButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                dropdownContent.Visible = isOpen
                dropdownIcon.Text = isOpen and "▲" or "▼"
            end)
        end
    end)
    
    -- Close when clicked elsewhere
    pcall(function()
        local UserInputService = game:GetService("UserInputService")
        if UserInputService and UserInputService.InputBegan then
            UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and isOpen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local dropdownPos = dropdownContent.AbsolutePosition
                    local dropdownSize = dropdownContent.AbsoluteSize
                    
                    if mousePos.X < dropdownPos.X or 
                       mousePos.Y < dropdownPos.Y or 
                       mousePos.X > dropdownPos.X + dropdownSize.X or 
                       mousePos.Y > dropdownPos.Y + dropdownSize.Y then
                        if not (mousePos.X >= dropdownButton.AbsolutePosition.X and
                               mousePos.Y >= dropdownButton.AbsolutePosition.Y and
                               mousePos.X <= dropdownButton.AbsolutePosition.X + dropdownButton.AbsoluteSize.X and
                               mousePos.Y <= dropdownButton.AbsolutePosition.Y + dropdownButton.AbsoluteSize.Y) then
                            isOpen = false
                            dropdownContent.Visible = false
                            dropdownIcon.Text = "▼"
                        end
                    end
                end
            end)
        end
    end)
    
    -- Set dropdown size correctly
    dropdown.Size = UDim2.new(1, 0, 0, 50)
    
    return {
        Set = function(option)
            if table.find(options, option) then
                dropdownButton.Text = option
                callback(option)
            end
        end,
        Get = function()
            return dropdownButton.Text
        end
    }
end

-- Fill aimbot tab
function UIController:FillAimbotTab(parent)
    local aimbotSection = self:CreateSection(parent, "Aimbot Settings")
    
    -- Aimbot toggle
    local aimbotToggle = self:CreateToggle(aimbotSection, "Enable Aimbot", controllers.AimbotController.Enabled, function(value)
        if value then
            controllers.AimbotController:Enable()
        else
            controllers.AimbotController:Disable()
        end
        
        controllers.ConfigController:SaveConfig()
    end)
    
    -- FOV slider
    local fovSlider = self:CreateSlider(aimbotSection, "FOV", 5, 180, controllers.AimbotController.FOV, 1, function(value)
        controllers.AimbotController:SetFOV(value)
        controllers.ConfigController:SaveConfig()
    end)
    
    -- Smoothness slider
    local smoothSlider = self:CreateSlider(aimbotSection, "Smoothness", 0.01, 1, controllers.AimbotController.Smoothness, 2, function(value)
        controllers.AimbotController:SetSmoothness(value)
        controllers.ConfigController:SaveConfig()
    end)
    
    -- Target part dropdown
    local partOptions = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}
    local targetPartDropdown = self:CreateDropdown(aimbotSection, "Target Part", partOptions, function(value)
        controllers.AimbotController:SetTargetPart(value)
        controllers.ConfigController:SaveConfig()
    end)
    
    -- Multi-bone targeting
    local multiBoneToggle = self:CreateToggle(aimbotSection, "Multi-Bone Targeting", controllers.AimbotController.MultiBone, function(value)
        controllers.AimbotController:ToggleMultiBone(value)
        controllers.ConfigController:SaveConfig()
    end)
    
    -- Show FOV circle
    local showFovToggle = self:CreateToggle(aimbotSection, "Show FOV Circle", controllers.AimbotController.VisualizeTargetFOV, function(value)
        controllers.AimbotController.VisualizeTargetFOV = value
        controllers.ConfigController:SaveConfig()
    end)
end

-- Fill visuals tab
function UIController:FillVisualsTab(parent)
    local espSection = self:CreateSection(parent, "ESP Settings")
    
    -- ESP toggle
    local espToggle = self:CreateToggle(espSection, "Enable ESP", controllers.ESPController.Enabled, function(value)
        if value then
            controllers.ESPController:Enable()
        else
            controllers.ESPController:Disable()
        end
        
        controllers.ConfigController:SaveConfig()
    end)
    
    -- Boxes toggle
    local boxesToggle = self:CreateToggle(espSection, "Show Boxes", controllers.ESPController.ShowBoxes, function(value)
        controllers.ESPController:ToggleBoxes(value)
        controllers.ConfigController:SaveConfig()
    end)
    
    -- Names toggle
    local namesToggle = self:CreateToggle(espSection, "Show Names", controllers.ESPController.ShowNames, function(value)
        controllers.ESPController:ToggleNames(value)
        controllers.ConfigController:SaveConfig()
    end)
    
    -- Distance toggle
    local distanceToggle = self:CreateToggle(espSection, "Show Distance", controllers.ESPController.ShowDistance, function(value)
        controllers.ESPController:ToggleDistance(value)
        controllers.ConfigController:SaveConfig()
    end)
    
    -- Health toggle
    local healthToggle = self:CreateToggle(espSection, "Show Health", controllers.ESPController.ShowHealth, function(value)
        controllers.ESPController:ToggleHealth(value)
        controllers.ConfigController:SaveConfig()
    end)
    
    -- Tracers toggle
    local tracersToggle = self:CreateToggle(espSection, "Show Tracers", controllers.ESPController.ShowTracers, function(value)
        controllers.ESPController:ToggleTracers(value)
        controllers.ConfigController:SaveConfig()
    end)
    
    -- Team check toggle
    local teamCheckToggle = self:CreateToggle(espSection, "Team Check", controllers.ESPController.TeamCheck, function(value)
        controllers.ESPController:ToggleTeamCheck(value)
        controllers.ConfigController:SaveConfig()
    end)
    
    -- Team color toggle
    local teamColorToggle = self:CreateToggle(espSection, "Use Team Colors", controllers.ESPController.TeamColor, function(value)
        controllers.ESPController:ToggleTeamColor(value)
        controllers.ConfigController:SaveConfig()
    end)
    
    -- Tracer origin dropdown
    local originOptions = {"Bottom", "Top", "Center"}
    local tracerOriginDropdown = self:CreateDropdown(espSection, "Tracer Origin", originOptions, function(value)
        controllers.ESPController.TracerOrigin = value
        controllers.ConfigController:SaveConfig()
    end)
end

-- Fill trigger tab
function UIController:FillTriggerTab(parent)
    local triggerSection = self:CreateSection(parent, "Triggerbot Settings")
    
    -- Triggerbot toggle
    local triggerToggle = self:CreateToggle(triggerSection, "Enable Triggerbot", controllers.TriggerController.Enabled, function(value)
        if value then
            controllers.TriggerController:Enable()
        else
            controllers.TriggerController:Disable()
        end
        
        controllers.ConfigController:SaveConfig()
    end)
    
    -- Delay slider
    local delaySlider = self:CreateSlider(triggerSection, "Delay (ms)", 0, 500, controllers.TriggerController.Delay, 0, function(value)
        controllers.TriggerController:SetDelay(value)
        controllers.ConfigController:SaveConfig()
    end)
    
    -- Interval slider
    local intervalSlider = self:CreateSlider(triggerSection, "Interval (ms)", 0, 500, controllers.TriggerController.Interval, 0, function(value)
        controllers.TriggerController:SetInterval(value)
        controllers.ConfigController:SaveConfig()
    end)
    
    -- Team check toggle
    local teamCheckToggle = self:CreateToggle(triggerSection, "Team Check", controllers.TriggerController.TeamCheck, function(value)
        controllers.TriggerController:ToggleTeamCheck(value)
        controllers.ConfigController:SaveConfig()
    end)
end

-- Fill settings tab
function UIController:FillSettingsTab(parent)
    local configSection = self:CreateSection(parent, "Configuration")
    
    -- Save button
    self:CreateButton(configSection, "Save Configuration", function()
        controllers.ConfigController:SaveConfig()
    end)
    
    -- Load button
    self:CreateButton(configSection, "Load Configuration", function()
        controllers.ConfigController:LoadConfig()
        
        -- Update UI to reflect loaded settings
        self:UpdateUIFromConfig()
    end)
    
    -- Reset button
    self:CreateButton(configSection, "Reset to Defaults", function()
        controllers.ConfigController:ResetConfig()
        
        -- Update UI to reflect reset settings
        self:UpdateUIFromConfig()
    end)
    
    local aboutSection = self:CreateSection(parent, "About")
    
    -- About info
    local aboutInfo = Instance.new("TextLabel")
    aboutInfo.Name = "AboutInfo"
    aboutInfo.Size = UDim2.new(1, 0, 0, 80)
    aboutInfo.BackgroundTransparency = 1
    aboutInfo.TextColor3 = TEXT_COLOR
    aboutInfo.TextSize = 14
    
    -- Safely set font
    safeSetProperty(aboutInfo, "Font", "Font", "SourceSans")
    
    aboutInfo.Text = "Syfer-eng Roblox Edition\nVersion 1.0\n\nHotkeys:\nRight Alt - Toggle UI\nRight Shift - Toggle All Features"
    
    -- Safely set text alignment
    safeSetProperty(aboutInfo, "TextXAlignment", "TextXAlignment", "Left")
    safeSetProperty(aboutInfo, "TextYAlignment", "TextYAlignment", "Top")
    
    aboutInfo.Parent = aboutSection
end

-- Update UI based on current config
function UIController:UpdateUIFromConfig()
    -- This would need to get all UI elements and update them
    -- For a full implementation, we would need to store references to all UI elements
    
    -- For now, just refresh tabs
    self:SelectTab(currentTab)
end

-- Update main toggle state
function UIController:UpdateMainToggle(enabled)
    -- Update UI to reflect main toggle state
    -- In a real implementation, this would update the main toggle button
end

-- Cleanup
function UIController:Cleanup()
    -- Remove all connections
    for _, connection in ipairs(connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    
    -- Remove the UI
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
    end
end

return UIController
