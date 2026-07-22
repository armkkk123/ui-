-- ============================================================
-- [1] SERVICES & CORE DECLARATION
-- ============================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ป้องกัน Gui ซ้ำซ้อน หากมีเวอร์ชันเดิมรันอยู่ให้ลบออกก่อน
local UI_NAME = "CustomExecutorGuiLib"
local existingGui = CoreGui:FindFirstChild(UI_NAME) or (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild(UI_NAME))
if existingGui then
    existingGui:Destroy()
end

-- ============================================================
-- [2] LIBRARY INITIALIZATION & THEME CONFIG
-- ============================================================
local Library = {
    Flags = {},
    Elements = {},
    Unloaded = false,
    ConfigFolder = "UI_Configs",
    Theme = {
        MainBg = Color3.fromRGB(12, 12, 15),
        TopBarBg = Color3.fromRGB(18, 18, 22),
        SideBarBg = Color3.fromRGB(8, 8, 10),
        CardBg = Color3.fromRGB(18, 18, 24),
        InputBg = Color3.fromRGB(25, 25, 30),
        Accent = Color3.fromRGB(50, 150, 250),
        AccentDark = Color3.fromRGB(35, 110, 190),
        Success = Color3.fromRGB(34, 140, 60),
        SuccessHover = Color3.fromRGB(45, 170, 75),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(180, 180, 190),
        TextSub = Color3.fromRGB(130, 130, 135),
        Stroke = Color3.fromRGB(40, 40, 45),
        StrokeLight = Color3.fromRGB(60, 60, 70),
        ToggleOff = Color3.fromRGB(50, 50, 55),
    }
}

-- ============================================================
-- [3] HELPER FUNCTIONS (Instance Creator & Dragging)
-- ============================================================
do
    -- สร้าง Instance พร้อมกำหนด Property
    function Library:Create(className, properties)
        local instance = Instance.new(className)
        for property, value in pairs(properties) do
            instance[property] = value
        end
        return instance
    end

    -- ระบบ Dragging (รองรับทั้ง Mouse และ Touch)
    function Library:MakeDraggable(guiObject, targetObject)
        targetObject = targetObject or guiObject
        local dragStart, startPos
        local dragging = false
        
        guiObject.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = targetObject.Position
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                targetObject.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end
end

-- ============================================================
-- [4] SCREEN GUI, NOTIFICATION & CONFIG SYSTEM
-- ============================================================
local ScreenGui = Library:Create("ScreenGui", {
    Name = UI_NAME,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

-- Safe parent fallback (CoreGui -> LocalPlayer.PlayerGui)
local parentSuccess = pcall(function() ScreenGui.Parent = CoreGui end)
if not parentSuccess then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

Library.ScreenGui = ScreenGui

-- Notification System (Rayfield:Notify())
function Library:Notify(data)
    local title = data.Title or "Notification"
    local content = data.Content or ""
    local duration = data.Duration or 3
    
    task.spawn(function()
        local container = ScreenGui:FindFirstChild("NotifyContainer")
        if not container then
            container = Library:Create("Frame", {
                Name = "NotifyContainer",
                Size = UDim2.new(0, 280, 1, -40),
                Position = UDim2.new(1, -290, 0, 20),
                BackgroundTransparency = 1,
                Parent = ScreenGui
            })
            Library:Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 8),
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Parent = container
            })
        end
        
        local note = Library:Create("Frame", {
            Size = UDim2.new(1, 0, 0, 60),
            BackgroundColor3 = Color3.fromRGB(20, 20, 25),
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            Parent = container
        })
        Library:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = note})
        Library:Create("UIStroke", {
            Color = Library.Theme.Accent,
            Thickness = 1.2,
            Parent = note
        })
        
        Library:Create("TextLabel", {
            Size = UDim2.new(1, -20, 0, 20),
            Position = UDim2.new(0, 10, 0, 5),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = Library.Theme.Text,
            Text = title,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = note
        })
        
        Library:Create("TextLabel", {
            Size = UDim2.new(1, -20, 1, -28),
            Position = UDim2.new(0, 10, 0, 23),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = Library.Theme.TextDim,
            Text = content,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = note
        })
        
        -- Animation In
        note.Position = UDim2.new(1.2, 0, 0, 0)
        TweenService:Create(note, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
        
        task.wait(duration)
        
        -- Animation Out
        local tweenOut = TweenService:Create(note, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(1.2, 0, 0, 0)})
        tweenOut:Play()
        tweenOut.Completed:Connect(function()
            note:Destroy()
        end)
    end)
end

-- Configuration Auto-Save / Load (Rayfield:SaveConfiguration / LoadConfiguration)
function Library:SaveConfiguration(fileName)
    fileName = (fileName or "default") .. ".json"
    pcall(function()
        if writefile then
            -- Automatically handles config folder
            if isfolder and not isfolder(Library.ConfigFolder) then makefolder(Library.ConfigFolder) end
            
            local dataToSave = {}
            for flag, val in pairs(Library.Flags) do
                if typeof(val) == "Color3" then
                    dataToSave[flag] = {R = val.R, G = val.G, B = val.B, Type = "Color3"}
                elseif typeof(val) == "EnumItem" then
                    dataToSave[flag] = {Name = val.Name, EnumType = tostring(val.EnumType), Type = "Enum"}
                else
                    dataToSave[flag] = val
                end
            end
            
            writefile(Library.ConfigFolder .. "/" .. fileName, HttpService:JSONEncode(dataToSave))
            Library:Notify({Title = "Config Saved 💾", Content = "Saved settings to " .. fileName, Duration = 2.5})
        end
    end)
end

function Library:LoadConfiguration(fileName)
    fileName = (fileName or "default") .. ".json"
    pcall(function()
        if isfile and isfile(Library.ConfigFolder .. "/" .. fileName) then
            local raw = readfile(Library.ConfigFolder .. "/" .. fileName)
            local decoded = HttpService:JSONDecode(raw)
            if decoded then
                for flag, data in pairs(decoded) do
                    local elem = Library.Elements[flag]
                    if elem and elem.Set then
                        if type(data) == "table" and data.Type == "Color3" then
                            elem.Set(Color3.new(data.R, data.G, data.B))
                        elseif type(data) == "table" and data.Type == "Enum" then
                            local keyEnum = Enum.KeyCode[data.Name]
                            if keyEnum then elem.Set(keyEnum) end
                        else
                            elem.Set(data)
                        end
                    end
                end
                Library:Notify({Title = "Config Loaded 📂", Content = "Loaded settings from " .. fileName, Duration = 2.5})
            end
        end
    end)
end

-- ============================================================
-- [5] WINDOW BUILDER (MainFrame, TopBar, SideBar)
-- ============================================================
function Library:CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "EXECUTOR HUB"
    local windowSize = config.Size or UDim2.new(0, 540, 0, 360)
    local toggleIcon = config.ToggleIcon or "rbxthumb://type=Asset&id=8829255607&w=150&h=150"

    -- Floating Open Button (ปุ่มเปิด-ปิด UI วงกลม ลอยหน้าจอ)
    local openBtn = Library:Create("Frame", {
        Name = "OpenBtn",
        Size = UDim2.new(0, 42, 0, 42),
        Position = UDim2.new(0.05, 0, 0.15, 0),
        BackgroundColor3 = Library.Theme.TopBarBg,
        BorderSizePixel = 0,
        Active = true,
        Parent = ScreenGui
    })
    Library:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = openBtn})
    Library:Create("UIStroke", {Color = Library.Theme.StrokeLight, Thickness = 1.5, Parent = openBtn})

    local openIcon = Library:Create("ImageLabel", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(0.5, -14, 0.5, -14),
        BackgroundTransparency = 1,
        Image = toggleIcon,
        Parent = openBtn
    })

    local openClickBtn = Library:Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 2,
        Parent = openBtn
    })
    Library:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = openClickBtn})
    Library:MakeDraggable(openClickBtn, openBtn)

    -- Main UI Frame
    local MainFrame = Library:Create("Frame", {
        Name = "MainFrame",
        Size = windowSize,
        Position = UDim2.new(0.5, -windowSize.X.Offset / 2, 0.5, -windowSize.Y.Offset / 2),
        BackgroundColor3 = Library.Theme.MainBg,
        BorderSizePixel = 0,
        Visible = true,
        Parent = ScreenGui
    })
    Library:Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = MainFrame})
    Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1.5, Parent = MainFrame})

    -- TopBar
    local TopBar = Library:Create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Library.Theme.TopBarBg,
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    Library:Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = TopBar})
    
    -- ปกปิดมุมล่างของ TopBar ไม่ให้ UICorner ม้วนเข้าด้านใน
    Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = Library.Theme.TopBarBg,
        BorderSizePixel = 0,
        Parent = TopBar
    })
    Library:MakeDraggable(TopBar, MainFrame)

    Library:Create("TextLabel", {
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Library.Theme.Text,
        Text = windowTitle,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar
    })

    local CloseBtn = Library:Create("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -31, 0.5, -13),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Library.Theme.TextDim,
        Text = "X",
        Parent = TopBar
    })
    CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80) end)
    CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = Library.Theme.TextDim end)
    CloseBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
    end)

    -- Toggle Window Visibility เมื่อคลิกที่ OpenBtn (ลากตำแหน่งได้โดยไม่เด้งปิด)
    local clickStartPos = nil
    openClickBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            clickStartPos = input.Position
        end
    end)

    openClickBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if clickStartPos and (input.Position - clickStartPos).Magnitude < 10 then
                MainFrame.Visible = not MainFrame.Visible
            end
        end
    end)

    -- Left Navigation Sidebar Menu
    local LeftMenu = Library:Create("Frame", {
        Name = "LeftMenu",
        Size = UDim2.new(0, 135, 1, -46),
        Position = UDim2.new(0, 6, 0, 41),
        BackgroundColor3 = Library.Theme.SideBarBg,
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    Library:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = LeftMenu})
    Library:Create("UIStroke", {Color = Color3.fromRGB(25, 25, 28), Thickness = 1, Parent = LeftMenu})

    Library:Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = LeftMenu
    })
    Library:Create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = LeftMenu
    })

    -- Main Content Display Area
    local ContentArea = Library:Create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -154, 1, -46),
        Position = UDim2.new(0, 147, 0, 41),
        BackgroundTransparency = 1,
        Parent = MainFrame
    })

    -- Window Object Definition
    local Window = {
        Tabs = {},
        ActiveTab = nil
    }

    -- ============================================================
    -- [6] TAB CREATION SYSTEM
    -- ============================================================
    function Window:CreateTab(tabName)
        local TabPage = Library:Create("ScrollingFrame", {
            Name = tabName .. "Page",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Library.Theme.StrokeLight,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            Parent = ContentArea
        })

        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = TabPage
        })
        Library:Create("UIPadding", {
            PaddingTop = UDim.new(0, 2),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 8),
            Parent = TabPage
        })

        -- Tab Sidebar Button
        local TabBtn = Library:Create("TextButton", {
            Name = tabName .. "Btn",
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Color3.fromRGB(15, 15, 18),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = Library.Theme.TextSub,
            Text = tabName,
            BorderSizePixel = 0,
            Parent = LeftMenu
        })
        Library:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = TabBtn})
        local stroke = Library:Create("UIStroke", {
            Color = Color3.fromRGB(22, 22, 25),
            Thickness = 1,
            Parent = TabBtn
        })

        local Tab = {
            Page = TabPage,
            Button = TabBtn,
            Stroke = stroke
        }

        -- ฟังก์ชันเปลี่ยน Tab
        local function SelectTab()
            for _, t in ipairs(Window.Tabs) do
                t.Page.Visible = false
                t.Button.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
                t.Button.Font = Enum.Font.Gotham
                t.Button.TextColor3 = Library.Theme.TextSub
                t.Stroke.Color = Color3.fromRGB(22, 22, 25)
            end

            TabPage.Visible = true
            TabBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            TabBtn.Font = Enum.Font.GothamBold
            TabBtn.TextColor3 = Library.Theme.Text
            stroke.Color = Library.Theme.StrokeLight
            Window.ActiveTab = Tab
        end

        TabBtn.MouseButton1Click:Connect(SelectTab)

        -- หากเป็น Tab แรก ให้เลือกอัตโนมัติ
        if #Window.Tabs == 0 then
            SelectTab()
        end

        table.insert(Window.Tabs, Tab)

        -- ============================================================
        -- [7] COMPONENT BUILDERS (Rayfield Equivalent Set)
        -- ============================================================
        do
            -- 7.1 Section Header (Tab:CreateSection)
            function Tab:CreateSection(text)
                local frame = Library:Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundTransparency = 1,
                    Parent = TabPage
                })
                Library:Create("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextColor3 = Library.Theme.Accent,
                    Text = text:upper(),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = frame
                })
                return frame
            end

            -- 7.2 Label (Tab:CreateLabel)
            function Tab:CreateLabel(options)
                local text = type(options) == "table" and (options.Name or options.Text) or tostring(options)
                local container = Library:Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = Library.Theme.CardBg,
                    BorderSizePixel = 0,
                    Parent = TabPage
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = container})
                Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1, Parent = container})

                local label = Library:Create("TextLabel", {
                    Size = UDim2.new(1, -16, 1, 0),
                    Position = UDim2.new(0, 8, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = Library.Theme.TextDim,
                    Text = text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = container
                })

                local elem = {
                    Set = function(newText)
                        label.Text = tostring(newText)
                    end
                }
                return elem
            end

            -- 7.3 Toggle Switch (Tab:CreateToggle)
            function Tab:CreateToggle(options)
                options = options or {}
                local labelText = options.Name or "Toggle"
                local defaultValue = options.Default or false
                local flag = options.Flag
                local callback = options.Callback or function() end

                local container = Library:Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    Parent = TabPage
                })

                Library:Create("TextLabel", {
                    Size = UDim2.new(1, -60, 1, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Library.Theme.TextDim,
                    Text = labelText,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = container
                })

                local switch = Library:Create("TextButton", {
                    Size = UDim2.new(0, 42, 0, 20),
                    Position = UDim2.new(1, -42, 0.5, -10),
                    BackgroundColor3 = defaultValue and Library.Theme.Accent or Library.Theme.ToggleOff,
                    Text = "",
                    BorderSizePixel = 0,
                    Parent = container
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = switch})

                local knob = Library:Create("Frame", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = defaultValue and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                    BackgroundColor3 = Library.Theme.Text,
                    BorderSizePixel = 0,
                    Parent = switch
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = knob})

                local active = defaultValue
                if flag then Library.Flags[flag] = active end

                local function SetState(state, fireCallback)
                    active = state
                    if flag then Library.Flags[flag] = active end
                    local targetPos = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                    local targetColor = state and Library.Theme.Accent or Library.Theme.ToggleOff

                    TweenService:Create(knob, TweenInfo.new(0.2), {Position = targetPos}):Play()
                    TweenService:Create(switch, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()

                    if fireCallback ~= false then
                        pcall(callback, active)
                    end
                end

                switch.MouseButton1Click:Connect(function()
                    SetState(not active, true)
                end)

                local elem = {
                    Set = SetState,
                    GetValue = function() return active end
                }
                if flag then Library.Elements[flag] = elem end
                return elem
            end

            -- 7.4 Button (Tab:CreateButton)
            function Tab:CreateButton(options)
                options = options or {}
                local text = options.Name or "Button"
                local callback = options.Callback or function() end

                local container = Library:Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    Parent = TabPage
                })

                local btn = Library:Create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Library.Theme.Success,
                    BorderSizePixel = 0,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    TextColor3 = Library.Theme.Text,
                    Text = text,
                    Parent = container
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = btn})

                btn.MouseEnter:Connect(function()
                    btn.BackgroundColor3 = Library.Theme.SuccessHover
                end)
                btn.MouseLeave:Connect(function()
                    btn.BackgroundColor3 = Library.Theme.Success
                end)

                btn.MouseButton1Click:Connect(function()
                    pcall(callback)
                end)

                local elem = {
                    Set = function(newText)
                        btn.Text = tostring(newText)
                    end
                }
                return elem
            end

            -- 7.5 Draggable Slider (Tab:CreateSlider)
            function Tab:CreateSlider(options)
                options = options or {}
                local labelText = options.Name or "Slider"
                local minVal = options.Min or 0
                local maxVal = options.Max or 100
                local defaultValue = options.Default or minVal
                local precision = options.Precision or 0
                local flag = options.Flag
                local callback = options.Callback or function() end

                local container = Library:Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 44),
                    BackgroundTransparency = 1,
                    Parent = TabPage
                })

                Library:Create("TextLabel", {
                    Size = UDim2.new(1, -60, 0, 20),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Library.Theme.TextDim,
                    Text = labelText,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = container
                })

                local valLabel = Library:Create("TextLabel", {
                    Size = UDim2.new(0, 50, 0, 20),
                    Position = UDim2.new(1, -50, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    TextColor3 = Library.Theme.Text,
                    Text = tostring(defaultValue),
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = container
                })

                local barBg = Library:Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 10),
                    Position = UDim2.new(0, 0, 0, 24),
                    BackgroundColor3 = Library.Theme.InputBg,
                    BorderSizePixel = 0,
                    Parent = container
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = barBg})
                Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1, Parent = barBg})

                local barFill = Library:Create("Frame", {
                    Size = UDim2.new((defaultValue - minVal) / (maxVal - minVal), 0, 1, 0),
                    BackgroundColor3 = Library.Theme.Accent,
                    BorderSizePixel = 0,
                    Parent = barBg
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = barFill})

                local currentValue = defaultValue
                if flag then Library.Flags[flag] = currentValue end

                local function UpdateSlider(inputPos)
                    local relativeX = math.clamp((inputPos.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                    local rawValue = minVal + (maxVal - minVal) * relativeX
                    local mult = 10 ^ precision
                    currentValue = math.floor(rawValue * mult + 0.5) / mult
                    
                    barFill.Size = UDim2.new(relativeX, 0, 1, 0)
                    valLabel.Text = tostring(currentValue)
                    if flag then Library.Flags[flag] = currentValue end
                    pcall(callback, currentValue)
                end

                local dragging = false
                barBg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        UpdateSlider(input.Position)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        UpdateSlider(input.Position)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)

                local elem = {
                    Set = function(newVal)
                        newVal = math.clamp(newVal, minVal, maxVal)
                        currentValue = newVal
                        local rel = (newVal - minVal) / (maxVal - minVal)
                        barFill.Size = UDim2.new(rel, 0, 1, 0)
                        valLabel.Text = tostring(currentValue)
                        if flag then Library.Flags[flag] = currentValue end
                        pcall(callback, currentValue)
                    end,
                    GetValue = function() return currentValue end
                }
                if flag then Library.Elements[flag] = elem end
                return elem
            end

            -- 7.6 Dropdown Menu (Tab:CreateDropdown with Dropdown:Refresh)
            function Tab:CreateDropdown(options)
                options = options or {}
                local labelText = options.Name or "Dropdown"
                local optionList = options.Options or {}
                local defaultVal = options.Default or optionList[1] or ""
                local flag = options.Flag
                local callback = options.Callback or function() end

                local container = Library:Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 36),
                    BackgroundTransparency = 1,
                    ClipsDescendants = true,
                    Parent = TabPage
                })

                local mainBtn = Library:Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundColor3 = Library.Theme.InputBg,
                    BorderSizePixel = 0,
                    Text = "",
                    Parent = container
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = mainBtn})
                Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1, Parent = mainBtn})

                Library:Create("TextLabel", {
                    Size = UDim2.new(0.4, 0, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Library.Theme.TextDim,
                    Text = labelText,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = mainBtn
                })

                local selectedLabel = Library:Create("TextLabel", {
                    Size = UDim2.new(0.55, -20, 1, 0),
                    Position = UDim2.new(0.45, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextColor3 = Library.Theme.Accent,
                    Text = tostring(defaultVal),
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = mainBtn
                })

                local arrow = Library:Create("TextLabel", {
                    Size = UDim2.new(0, 20, 1, 0),
                    Position = UDim2.new(1, -22, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    TextColor3 = Library.Theme.TextSub,
                    Text = "▼",
                    Parent = mainBtn
                })

                local listFrame = Library:Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 0, 36),
                    BackgroundColor3 = Library.Theme.CardBg,
                    BorderSizePixel = 0,
                    Parent = container
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = listFrame})
                Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1, Parent = listFrame})

                local listLayout = Library:Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 3),
                    Parent = listFrame
                })
                Library:Create("UIPadding", {
                    PaddingTop = UDim.new(0, 4),
                    PaddingBottom = UDim.new(0, 4),
                    PaddingLeft = UDim.new(0, 4),
                    PaddingRight = UDim.new(0, 4),
                    Parent = listFrame
                })

                local open = false
                local selected = defaultVal
                if flag then Library.Flags[flag] = selected end

                local function PopulateOptions(newList)
                    for _, child in ipairs(listFrame:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end

                    for _, opt in ipairs(newList) do
                        local itemBtn = Library:Create("TextButton", {
                            Size = UDim2.new(1, 0, 0, 24),
                            BackgroundColor3 = (opt == selected) and Library.Theme.AccentDark or Color3.fromRGB(20, 20, 26),
                            Font = Enum.Font.Gotham,
                            TextSize = 11,
                            TextColor3 = Library.Theme.Text,
                            Text = tostring(opt),
                            BorderSizePixel = 0,
                            Parent = listFrame
                        })
                        Library:Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = itemBtn})

                        itemBtn.MouseButton1Click:Connect(function()
                            selected = opt
                            selectedLabel.Text = tostring(selected)
                            if flag then Library.Flags[flag] = selected end
                            
                            open = false
                            arrow.Text = "▼"
                            TweenService:Create(container, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 36)}):Play()
                            
                            pcall(callback, selected)
                        end)
                    end

                    local totalH = #newList * 27 + 8
                    listFrame.Size = UDim2.new(1, 0, 0, totalH)
                end

                PopulateOptions(optionList)

                mainBtn.MouseButton1Click:Connect(function()
                    open = not open
                    arrow.Text = open and "▲" or "▼"
                    local targetH = open and (36 + listFrame.Size.Y.Offset + 4) or 36
                    TweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, targetH)}):Play()
                end)

                local elem = {
                    Set = function(val)
                        selected = val
                        selectedLabel.Text = tostring(selected)
                        if flag then Library.Flags[flag] = selected end
                        PopulateOptions(optionList)
                        pcall(callback, selected)
                    end,
                    Refresh = function(newList)
                        optionList = newList
                        PopulateOptions(newList)
                    end,
                    GetValue = function() return selected end
                }
                if flag then Library.Elements[flag] = elem end
                return elem
            end

            -- 7.7 Keybind Button (Tab:CreateKeybind)
            function Tab:CreateKeybind(options)
                options = options or {}
                local labelText = options.Name or "Keybind"
                local defaultKey = options.Default or Enum.KeyCode.E
                local flag = options.Flag
                local callback = options.Callback or function() end

                local container = Library:Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    Parent = TabPage
                })

                Library:Create("TextLabel", {
                    Size = UDim2.new(1, -110, 1, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Library.Theme.TextDim,
                    Text = labelText,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = container
                })

                local currentKey = defaultKey
                if flag then Library.Flags[flag] = currentKey end

                local keyBtn = Library:Create("TextButton", {
                    Size = UDim2.new(0, 90, 0, 24),
                    Position = UDim2.new(1, -90, 0.5, -12),
                    BackgroundColor3 = Library.Theme.InputBg,
                    BorderSizePixel = 0,
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextColor3 = Library.Theme.Accent,
                    Text = currentKey.Name,
                    Parent = container
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = keyBtn})
                Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1, Parent = keyBtn})

                local binding = false
                keyBtn.MouseButton1Click:Connect(function()
                    binding = true
                    keyBtn.Text = "Press key..."
                    keyBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
                end)

                UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if binding and input.UserInputType == Enum.UserInputType.Keyboard then
                        binding = false
                        currentKey = input.KeyCode
                        keyBtn.Text = currentKey.Name
                        keyBtn.TextColor3 = Library.Theme.Accent
                        if flag then Library.Flags[flag] = currentKey end
                    elseif not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
                        pcall(callback, currentKey)
                    end
                end)

                local elem = {
                    Set = function(keyEnum)
                        currentKey = keyEnum
                        keyBtn.Text = currentKey.Name
                        if flag then Library.Flags[flag] = currentKey end
                    end,
                    GetValue = function() return currentKey end
                }
                if flag then Library.Elements[flag] = elem end
                return elem
            end

            -- 7.8 Color Picker (Tab:CreateColorPicker)
            function Tab:CreateColorPicker(options)
                options = options or {}
                local labelText = options.Name or "Color Picker"
                local defaultColor = options.Default or Color3.fromRGB(255, 255, 255)
                local flag = options.Flag
                local callback = options.Callback or function() end

                local container = Library:Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    Parent = TabPage
                })

                Library:Create("TextLabel", {
                    Size = UDim2.new(1, -60, 1, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Library.Theme.TextDim,
                    Text = labelText,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = container
                })

                local colorBox = Library:Create("TextButton", {
                    Size = UDim2.new(0, 42, 0, 20),
                    Position = UDim2.new(1, -42, 0.5, -10),
                    BackgroundColor3 = defaultColor,
                    Text = "",
                    BorderSizePixel = 0,
                    Parent = container
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = colorBox})
                Library:Create("UIStroke", {Color = Library.Theme.StrokeLight, Thickness = 1, Parent = colorBox})

                local currentColor = defaultColor
                if flag then Library.Flags[flag] = currentColor end

                -- Preset colors palette
                local presetColors = {
                    Color3.fromRGB(255, 60, 60),
                    Color3.fromRGB(60, 255, 100),
                    Color3.fromRGB(50, 150, 250),
                    Color3.fromRGB(255, 200, 50),
                    Color3.fromRGB(200, 80, 255),
                    Color3.fromRGB(255, 255, 255)
                }
                local colorIdx = 1

                colorBox.MouseButton1Click:Connect(function()
                    colorIdx = (colorIdx % #presetColors) + 1
                    currentColor = presetColors[colorIdx]
                    colorBox.BackgroundColor3 = currentColor
                    if flag then Library.Flags[flag] = currentColor end
                    pcall(callback, currentColor)
                end)

                local elem = {
                    Set = function(col)
                        currentColor = col
                        colorBox.BackgroundColor3 = currentColor
                        if flag then Library.Flags[flag] = currentColor end
                        pcall(callback, currentColor)
                    end,
                    GetValue = function() return currentColor end
                }
                if flag then Library.Elements[flag] = elem end
                return elem
            end

            -- 7.9 Input Box (Tab:CreateInput)
            function Tab:CreateInput(options)
                options = options or {}
                local labelText = options.Name or "Input"
                local defaultValue = options.Default or ""
                local placeholder = options.Placeholder or "Enter value..."
                local flag = options.Flag
                local callback = options.Callback or function() end

                local container = Library:Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    Parent = TabPage
                })

                Library:Create("TextLabel", {
                    Size = UDim2.new(1, -110, 1, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Library.Theme.TextDim,
                    Text = labelText,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = container
                })

                local box = Library:Create("TextBox", {
                    Size = UDim2.new(0, 100, 0, 24),
                    Position = UDim2.new(1, -100, 0.5, -12),
                    BackgroundColor3 = Library.Theme.InputBg,
                    BorderSizePixel = 0,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = Library.Theme.Text,
                    PlaceholderColor3 = Color3.fromRGB(110, 110, 115),
                    PlaceholderText = placeholder,
                    Text = tostring(defaultValue),
                    ClearTextOnFocus = false,
                    Parent = container
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = box})
                Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1, Parent = box})

                if flag then Library.Flags[flag] = defaultValue end

                box.FocusLost:Connect(function(enterPressed)
                    local val = box.Text
                    if flag then Library.Flags[flag] = val end
                    pcall(callback, val)
                end)

                local elem = {
                    Set = function(val)
                        box.Text = tostring(val)
                        if flag then Library.Flags[flag] = val end
                        pcall(callback, val)
                    end
                }
                if flag then Library.Elements[flag] = elem end
                return elem
            end

            -- 7.10 Paragraph (Tab:CreateParagraph)
            function Tab:CreateParagraph(options)
                options = options or {}
                local title = options.Title or "Info"
                local content = options.Content or ""

                local frame = Library:Create("Frame", {
                    Size = UDim2.new(1, 0, 0, 50),
                    BackgroundColor3 = Library.Theme.CardBg,
                    BorderSizePixel = 0,
                    Parent = TabPage
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = frame})
                Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1, Parent = frame})

                Library:Create("TextLabel", {
                    Size = UDim2.new(1, -16, 0, 18),
                    Position = UDim2.new(0, 8, 0, 4),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    TextColor3 = Library.Theme.Text,
                    Text = title,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = frame
                })

                local descLabel = Library:Create("TextLabel", {
                    Size = UDim2.new(1, -16, 1, -24),
                    Position = UDim2.new(0, 8, 0, 22),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = Library.Theme.TextSub,
                    Text = content,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    Parent = frame
                })

                return descLabel
            end
        end

        return Tab
    end

    return Window
end

-- ============================================================
-- [8] CLEANUP / UNLOAD SYSTEM
-- ============================================================
function Library:Destroy()
    if Library.ScreenGui then
        Library.ScreenGui:Destroy()
        Library.Unloaded = true
    end
end

return Library
