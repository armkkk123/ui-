--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║            CUSTOM EXECUTOR GUI LIBRARY v2.0                  ║
    ║         Production-grade UI Library for Roblox               ║
    ╚══════════════════════════════════════════════════════════════╝
    
    API Reference:
        Library:CreateWindow(config)
        Library:Notify(data)
        Library:Destroy()
        Library:SetTheme(themeTable)
        Library:SaveConfiguration(name)
        Library:LoadConfiguration(name)
        
        Window:CreateTab(name, icon)
        Tab:CreateSection(text)
        Tab:CreateLabel(text)
        Tab:CreateButton(options)
        Tab:CreateToggle(options)
        Tab:CreateSlider(options)
        Tab:CreateDropdown(options)
        Tab:CreateInput(options)
        Tab:CreateNumberAdjust(options)
        Tab:CreateKeybind(options)
        Tab:CreateColorPicker(options)
        Tab:CreateParagraph(options)
        
        Element.Set(value)
        Element.GetValue()
        Dropdown.Refresh(newList)
]]

-- ============================================================
-- [1] SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- [2] LIBRARY CORE
-- ============================================================
local Library = {
    Version     = "2.0.0",
    Flags       = {},
    Elements    = {},
    Connections = {},
    Unloaded    = false,
    ConfigFolder = "UILibConfigs",

    Theme = {
        MainBg        = Color3.fromRGB(14, 14, 19),
        TopBarBg      = Color3.fromRGB(20, 20, 28),
        SideBarBg     = Color3.fromRGB(10, 10, 14),
        CardBg        = Color3.fromRGB(22, 22, 30),
        InputBg       = Color3.fromRGB(28, 28, 38),
        DropdownBg    = Color3.fromRGB(18, 18, 25),
        Accent        = Color3.fromRGB(0, 175, 255),
        AccentDark    = Color3.fromRGB(0, 115, 210),
        AccentHover   = Color3.fromRGB(40, 195, 255),
        Success       = Color3.fromRGB(34, 150, 70),
        SuccessHover  = Color3.fromRGB(45, 180, 85),
        Danger        = Color3.fromRGB(220, 65, 65),
        Text          = Color3.fromRGB(245, 245, 250),
        TextDim       = Color3.fromRGB(180, 180, 195),
        TextSub       = Color3.fromRGB(120, 120, 130),
        Stroke        = Color3.fromRGB(42, 42, 54),
        StrokeLight   = Color3.fromRGB(65, 65, 82),
        ToggleOff     = Color3.fromRGB(50, 50, 62),
        NotifyBg      = Color3.fromRGB(22, 22, 32),
    }
}

-- ============================================================
-- [3] UTILITIES
-- ============================================================
do
    -- Safe Instance creator
    function Library:Create(className, props)
        local ok, inst = pcall(Instance.new, className)
        if not ok then return nil end
        for k, v in pairs(props) do
            pcall(function() inst[k] = v end)
        end
        return inst
    end

    -- Track connections for cleanup
    function Library:Connect(signal, fn)
        local conn = signal:Connect(fn)
        table.insert(Library.Connections, conn)
        return conn
    end

    -- Tween shortcut
    function Library:Tween(inst, props, t, style, dir)
        t = t or 0.2
        style = style or Enum.EasingStyle.Quart
        dir   = dir   or Enum.EasingDirection.Out
        return TweenService:Create(inst, TweenInfo.new(t, style, dir), props)
    end

    -- Override theme colors
    function Library:SetTheme(themeOverride)
        for k, v in pairs(themeOverride) do
            if Library.Theme[k] ~= nil then
                Library.Theme[k] = v
            end
        end
    end

    -- Draggable (with screen-clamping)
    function Library:MakeDraggable(handle, target)
        local dragging, dragStart, startPos = false, nil, nil

        local function onInputBegan(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging   = true
                dragStart  = input.Position
                startPos   = target.Position
            end
        end

        local function onInputChanged(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end

            local delta = input.Position - dragStart
            local newX  = startPos.X.Offset + delta.X
            local newY  = startPos.Y.Offset + delta.Y

            -- Clamp to screen bounds
            local vp    = workspace.CurrentCamera.ViewportSize
            local sizeX = target.Size.X.Offset
            local sizeY = target.Size.Y.Offset
            newX = math.clamp(newX, 0, vp.X - sizeX)
            newY = math.clamp(newY, 0, vp.Y - sizeY)

            target.Position = UDim2.new(0, newX, 0, newY)
        end

        local function onInputEnded(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end

        handle.InputBegan:Connect(onInputBegan)
        Library:Connect(UserInputService.InputChanged, onInputChanged)
        Library:Connect(UserInputService.InputEnded,   onInputEnded)
    end

    -- Card hover lighting animation helper
    function Library:AddCardHover(container, stroke)
        if not container or not stroke then return end
        container.MouseEnter:Connect(function()
            Library:Tween(stroke, {Color = Library.Theme.StrokeLight}, 0.15):Play()
            Library:Tween(container, {BackgroundColor3 = Color3.fromRGB(26, 26, 36)}, 0.15):Play()
        end)
        container.MouseLeave:Connect(function()
            Library:Tween(stroke, {Color = Library.Theme.Stroke}, 0.15):Play()
            Library:Tween(container, {BackgroundColor3 = Library.Theme.CardBg}, 0.15):Play()
        end)
    end
end

-- ============================================================
-- [4] SCREEN GUI
-- ============================================================
local UI_NAME = "CustomGuiLib_v2"

-- Remove existing GUI if loaded before
local existing = CoreGui:FindFirstChild(UI_NAME)
if existing then existing:Destroy() end
if LocalPlayer and LocalPlayer.PlayerGui:FindFirstChild(UI_NAME) then
    LocalPlayer.PlayerGui:FindFirstChild(UI_NAME):Destroy()
end

local ScreenGui = Library:Create("ScreenGui", {
    Name            = UI_NAME,
    ResetOnSpawn    = false,
    ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset  = true,
})

local parentOk = pcall(function() ScreenGui.Parent = CoreGui end)
if not parentOk then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

Library.ScreenGui = ScreenGui

-- ============================================================
-- [5] NOTIFICATION SYSTEM
-- ============================================================
do
    local notifyQueue   = {}
    local notifyVisible = 0
    local MAX_VISIBLE   = 3

    local notifyContainer = Library:Create("Frame", {
        Name                = "NotifyContainer",
        Size                = UDim2.new(0, 290, 1, -20),
        Position            = UDim2.new(1, -300, 0, 10),
        BackgroundTransparency = 1,
        Parent              = ScreenGui,
    })
    Library:Create("UIListLayout", {
        SortOrder           = Enum.SortOrder.LayoutOrder,
        VerticalAlignment   = Enum.VerticalAlignment.Bottom,
        Padding             = UDim.new(0, 6),
        Parent              = notifyContainer,
    })

    local function ShowNotify(data)
        local title    = tostring(data.Title    or "Notification")
        local content  = tostring(data.Content  or "")
        local duration = tonumber(data.Duration) or 3

        local note = Library:Create("Frame", {
            Size                = UDim2.new(1, 0, 0, 64),
            BackgroundColor3    = Library.Theme.NotifyBg,
            BackgroundTransparency = 0.08,
            BorderSizePixel     = 0,
            ClipsDescendants    = true,
            Parent              = notifyContainer,
        })
        Library:Create("UICorner",  {CornerRadius = UDim.new(0, 8), Parent = note})
        Library:Create("UIStroke",  {Color = Library.Theme.Accent, Thickness = 1.2, Parent = note})

        -- Accent bar on left
        Library:Create("Frame", {
            Size             = UDim2.new(0, 3, 1, 0),
            BackgroundColor3 = Library.Theme.Accent,
            BorderSizePixel  = 0,
            Parent           = note,
        })

        Library:Create("TextLabel", {
            Size                = UDim2.new(1, -20, 0, 22),
            Position            = UDim2.new(0, 12, 0, 6),
            BackgroundTransparency = 1,
            Font                = Enum.Font.GothamBold,
            TextSize            = 13,
            TextColor3          = Library.Theme.Text,
            Text                = title,
            TextXAlignment      = Enum.TextXAlignment.Left,
            TextTruncate        = Enum.TextTruncate.AtEnd,
            Parent              = note,
        })
        Library:Create("TextLabel", {
            Size                = UDim2.new(1, -20, 0, 30),
            Position            = UDim2.new(0, 12, 0, 28),
            BackgroundTransparency = 1,
            Font                = Enum.Font.Gotham,
            TextSize            = 11,
            TextColor3          = Library.Theme.TextDim,
            Text                = content,
            TextWrapped         = true,
            TextXAlignment      = Enum.TextXAlignment.Left,
            TextYAlignment      = Enum.TextYAlignment.Top,
            Parent              = note,
        })

        -- Slide in
        note.Position = UDim2.new(1.1, 0, 0, 0)
        Library:Tween(note, {Position = UDim2.new(0, 0, 0, 0)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
        notifyVisible = notifyVisible + 1

        task.delay(duration, function()
            Library:Tween(note, {Position = UDim2.new(1.1, 0, 0, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In):Play()
            task.wait(0.35)
            note:Destroy()
            notifyVisible = notifyVisible - 1

            -- Process queue
            if #notifyQueue > 0 and notifyVisible < MAX_VISIBLE then
                local next = table.remove(notifyQueue, 1)
                ShowNotify(next)
            end
        end)
    end

    function Library:Notify(data)
        if notifyVisible >= MAX_VISIBLE then
            table.insert(notifyQueue, data)
        else
            ShowNotify(data)
        end
    end
end

-- ============================================================
-- [6] CONFIGURATION SAVE / LOAD
-- ============================================================
do
    function Library:SaveConfiguration(name)
        name = (name or "default") .. ".json"
        local ok, err = pcall(function()
            assert(writefile, "writefile not supported by this executor")

            if isfolder and not isfolder(Library.ConfigFolder) then
                makefolder(Library.ConfigFolder)
            end

            local saveData = {}
            for flag, val in pairs(Library.Flags) do
                local t = typeof(val)
                if t == "Color3" then
                    saveData[flag] = {_type = "Color3", R = val.R, G = val.G, B = val.B}
                elseif t == "EnumItem" then
                    saveData[flag] = {_type = "Enum", Name = val.Name, EnumType = tostring(val.EnumType)}
                else
                    saveData[flag] = val
                end
            end

            writefile(Library.ConfigFolder .. "/" .. name, HttpService:JSONEncode(saveData))
        end)

        if ok then
            Library:Notify({Title = "Config Saved 💾", Content = name, Duration = 2.5})
        else
            Library:Notify({Title = "Save Failed ⚠️", Content = tostring(err), Duration = 3})
        end
    end

    function Library:LoadConfiguration(name)
        name = (name or "default") .. ".json"
        local ok, err = pcall(function()
            assert(isfile, "isfile not supported by this executor")
            assert(isfile(Library.ConfigFolder .. "/" .. name), "Config file not found: " .. name)

            local raw     = readfile(Library.ConfigFolder .. "/" .. name)
            local decoded = HttpService:JSONDecode(raw)
            assert(type(decoded) == "table", "Invalid config format")

            for flag, data in pairs(decoded) do
                local elem = Library.Elements[flag]
                if elem and elem.Set then
                    if type(data) == "table" and data._type == "Color3" then
                        pcall(elem.Set, Color3.new(data.R, data.G, data.B))
                    elseif type(data) == "table" and data._type == "Enum" then
                        local enumVal = pcall(function() return Enum.KeyCode[data.Name] end)
                        if enumVal then pcall(elem.Set, Enum.KeyCode[data.Name]) end
                    else
                        pcall(elem.Set, data)
                    end
                end
            end
        end)

        if ok then
            Library:Notify({Title = "Config Loaded 📂", Content = name, Duration = 2.5})
        else
            Library:Notify({Title = "Load Failed ⚠️", Content = tostring(err), Duration = 3})
        end
    end
end

-- ============================================================
-- [7] WINDOW BUILDER
-- ============================================================
function Library:CreateWindow(config)
    config = config or {}

    local windowTitle  = config.Title      or "Custom Hub"
    -- Auto-responsive window size calculation for Mobile & Tablet viewports
    local vp           = workspace.CurrentCamera.ViewportSize
    local targetWidth  = math.min(windowSize.X.Offset, math.max(300, vp.X - 24))
    local targetHeight = math.min(windowSize.Y.Offset, math.max(260, vp.Y - 24))
    local finalSize    = UDim2.new(0, targetWidth, 0, targetHeight)

    local startX       = math.max(10, (vp.X - targetWidth) / 2)
    local startY       = math.max(10, (vp.Y - targetHeight) / 2)

    -- ── Floating Toggle Button ────────────────────────────────
    local openBtn = Library:Create("Frame", {
        Name             = "OpenBtn",
        Size             = UDim2.new(0, 46, 0, 46),
        Position         = UDim2.new(0, 20, 0.15, 0),
        BackgroundColor3 = Library.Theme.TopBarBg,
        BorderSizePixel  = 0,
        Active           = true,
        Parent           = ScreenGui,
    })
    Library:Create("UICorner",  {CornerRadius = UDim.new(1, 0), Parent = openBtn})
    Library:Create("UIStroke",  {Color = Library.Theme.StrokeLight, Thickness = 1.5, Parent = openBtn})
    Library:Create("ImageLabel", {
        Size                   = UDim2.new(0, 30, 0, 30),
        Position               = UDim2.new(0.5, -15, 0.5, -15),
        BackgroundTransparency = 1,
        Image                  = toggleIcon,
        Parent                 = openBtn,
    })

    local openClickBtn = Library:Create("TextButton", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                   = "",
        ZIndex                 = 2,
        Parent                 = openBtn,
    })
    Library:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = openClickBtn})
    Library:MakeDraggable(openClickBtn, openBtn)

    -- ── Main Frame ────────────────────────────────────────────
    local MainFrame = Library:Create("Frame", {
        Name             = "MainFrame",
        Size             = finalSize,
        Position         = UDim2.new(0, startX, 0, startY),
        BackgroundColor3 = Library.Theme.MainBg,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        Parent           = ScreenGui,
    })
    Library:Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = MainFrame})
    Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1.5, Parent = MainFrame})

    -- Glowing top accent gradient line
    local topGradientLine = Library:Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel  = 0,
        ZIndex           = 10,
        Parent           = MainFrame,
    })
    Library:Create("UIGradient", {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 190, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 90, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 190, 255)),
        },
        Parent = topGradientLine,
    })

    -- ── TopBar ────────────────────────────────────────────────
    local TopBar = Library:Create("Frame", {
        Name             = "TopBar",
        Size             = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Library.Theme.TopBarBg,
        BorderSizePixel  = 0,
        ZIndex           = 2,
        Parent           = MainFrame,
    })
    Library:Create("UICorner", {CornerRadius = UDim.new(0, 10), Parent = TopBar})
    -- Cover bottom-round corners of TopBar
    Library:Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 10),
        Position         = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = Library.Theme.TopBarBg,
        BorderSizePixel  = 0,
        ZIndex           = 2,
        Parent           = TopBar,
    })

    Library:MakeDraggable(TopBar, MainFrame)

    -- Logo accent dot
    Library:Create("Frame", {
        Size             = UDim2.new(0, 6, 0, 6),
        Position         = UDim2.new(0, 12, 0.5, -3),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 3,
        Parent           = TopBar,
    })
    Library:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = TopBar:FindFirstChildWhichIsA("Frame")})

    Library:Create("TextLabel", {
        Size               = UDim2.new(1, -60, 1, 0),
        Position           = UDim2.new(0, 26, 0, 0),
        BackgroundTransparency = 1,
        Font               = Enum.Font.GothamBold,
        TextSize           = 13,
        TextColor3         = Library.Theme.Text,
        Text               = windowTitle,
        TextXAlignment     = Enum.TextXAlignment.Left,
        ZIndex             = 3,
        Parent             = TopBar,
    })

    -- Close button
    local CloseBtn = Library:Create("TextButton", {
        Size               = UDim2.new(0, 28, 0, 28),
        Position           = UDim2.new(1, -34, 0.5, -14),
        BackgroundColor3   = Library.Theme.Danger,
        BackgroundTransparency = 1,
        Font               = Enum.Font.GothamBold,
        TextSize           = 14,
        TextColor3         = Library.Theme.TextSub,
        Text               = "✕",
        ZIndex             = 4,
        Parent             = TopBar,
    })
    Library:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = CloseBtn})

    CloseBtn.MouseEnter:Connect(function()
        CloseBtn.BackgroundTransparency = 0
        CloseBtn.TextColor3 = Library.Theme.Text
    end)
    CloseBtn.MouseLeave:Connect(function()
        CloseBtn.BackgroundTransparency = 1
        CloseBtn.TextColor3 = Library.Theme.TextSub
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
    end)

    -- Toggle visibility via OpenBtn (distinguish click vs drag)
    local clickStart
    openClickBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            clickStart = i.Position
        end
    end)
    openClickBtn.InputEnded:Connect(function(i)
        if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            if clickStart and (i.Position - clickStart).Magnitude < 8 then
                MainFrame.Visible = not MainFrame.Visible
            end
        end
    end)

    -- ── Sidebar ───────────────────────────────────────────────
    local SideBar = Library:Create("Frame", {
        Name             = "SideBar",
        Size             = UDim2.new(0, 140, 1, -48),
        Position         = UDim2.new(0, 6, 0, 43),
        BackgroundColor3 = Library.Theme.SideBarBg,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        Parent           = MainFrame,
    })
    Library:Create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = SideBar})
    Library:Create("UIStroke", {Color = Color3.fromRGB(22, 22, 28), Thickness = 1, Parent = SideBar})

    local SideScroll = Library:Create("ScrollingFrame", {
        Size                  = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 3,
        ScrollBarImageColor3   = Library.Theme.StrokeLight,
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        Parent                 = SideBar,
    })
    Library:Create("UIListLayout", {
        Padding        = UDim.new(0, 4),
        SortOrder      = Enum.SortOrder.LayoutOrder,
        Parent         = SideScroll,
    })
    Library:Create("UIPadding", {
        PaddingTop    = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft   = UDim.new(0, 6),
        PaddingRight  = UDim.new(0, 6),
        Parent        = SideScroll,
    })

    -- ── Content Area ──────────────────────────────────────────
    local ContentArea = Library:Create("Frame", {
        Name             = "ContentArea",
        Size             = UDim2.new(1, -158, 1, -48),
        Position         = UDim2.new(0, 152, 0, 43),
        BackgroundTransparency = 1,
        Parent           = MainFrame,
    })

    -- ── Window Object ─────────────────────────────────────────
    local Window = {Tabs = {}, ActiveTab = nil}

    -- ============================================================
    -- [8] TAB BUILDER
    -- ============================================================
    function Window:CreateTab(tabName, tabIcon)
        tabName = tabName or "Tab"

        -- Content page (scrollable)
        local TabPage = Library:Create("ScrollingFrame", {
            Name                   = tabName .. "_Page",
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            ScrollBarThickness     = 4,
            ScrollBarImageColor3   = Library.Theme.StrokeLight,
            CanvasSize             = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize    = Enum.AutomaticSize.Y,
            Visible                = false,
            Parent                 = ContentArea,
        })
        Library:Create("UIListLayout", {
            Padding       = UDim.new(0, 7),
            SortOrder     = Enum.SortOrder.LayoutOrder,
            Parent        = TabPage,
        })
        Library:Create("UIPadding", {
            PaddingTop    = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 12),
            PaddingLeft   = UDim.new(0, 4),
            PaddingRight  = UDim.new(0, 10),
            Parent        = TabPage,
        })

        -- Sidebar Tab Button
        local TabBtn = Library:Create("TextButton", {
            Name             = tabName .. "_Btn",
            Size             = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Color3.fromRGB(14, 14, 18),
            Font             = Enum.Font.Gotham,
            TextSize         = 11,
            TextColor3       = Library.Theme.TextSub,
            Text             = (tabIcon and tabIcon .. "  " or "") .. tabName,
            BorderSizePixel  = 0,
            Parent           = SideScroll,
        })
        Library:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = TabBtn})
        local tabStroke = Library:Create("UIStroke", {
            Color     = Color3.fromRGB(20, 20, 24),
            Thickness = 1,
            Parent    = TabBtn,
        })

        -- Accent indicator bar (left edge)
        local tabAccent = Library:Create("Frame", {
            Size             = UDim2.new(0, 3, 0.6, 0),
            Position         = UDim2.new(0, 0, 0.2, 0),
            BackgroundColor3 = Library.Theme.Accent,
            BorderSizePixel  = 0,
            Visible          = false,
            Parent           = TabBtn,
        })
        Library:Create("UICorner", {CornerRadius = UDim.new(0, 2), Parent = tabAccent})

        local Tab = {Page = TabPage, Button = TabBtn}

        local function SelectTab()
            for _, t in ipairs(Window.Tabs) do
                t.Page.Visible = false
                Library:Tween(t.Button, {BackgroundColor3 = Color3.fromRGB(14, 14, 18)}, 0.15):Play()
                t.Button.Font = Enum.Font.Gotham
                t.Button.TextColor3 = Library.Theme.TextSub
                tabStroke.Color = Color3.fromRGB(20, 20, 24)
                -- Hide accent on all tabs
                local acc = t.Button:FindFirstChild("Frame")
                if acc then acc.Visible = false end
            end

            TabPage.Visible = true
            Library:Tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(22, 22, 30)}, 0.15):Play()
            TabBtn.Font = Enum.Font.GothamBold
            TabBtn.TextColor3 = Library.Theme.Text
            tabStroke.Color = Library.Theme.StrokeLight
            tabAccent.Visible = true
            Window.ActiveTab = Tab
        end

        TabBtn.MouseButton1Click:Connect(SelectTab)
        TabBtn.MouseEnter:Connect(function()
            if Window.ActiveTab ~= Tab then
                Library:Tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(18, 18, 24)}, 0.1):Play()
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if Window.ActiveTab ~= Tab then
                Library:Tween(TabBtn, {BackgroundColor3 = Color3.fromRGB(14, 14, 18)}, 0.1):Play()
            end
        end)

        if #Window.Tabs == 0 then SelectTab() end
        table.insert(Window.Tabs, Tab)

        -- ============================================================
        -- [9] COMPONENT BUILDERS
        -- ============================================================
        do
            -- ── Section ──────────────────────────────────────────────
            function Tab:CreateSection(text)
                local frame = Library:Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    Parent           = TabPage,
                })
                -- Separator line
                Library:Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 1),
                    Position         = UDim2.new(0, 0, 1, -1),
                    BackgroundColor3 = Library.Theme.Stroke,
                    BorderSizePixel  = 0,
                    Parent           = frame,
                })
                Library:Create("TextLabel", {
                    Size               = UDim2.new(1, 0, 1, -4),
                    BackgroundTransparency = 1,
                    Font               = Enum.Font.GothamBold,
                    TextSize           = 10,
                    TextColor3         = Library.Theme.Accent,
                    Text               = string.upper(text),
                    TextXAlignment     = Enum.TextXAlignment.Left,
                    Parent             = frame,
                })
                return frame
            end

            -- ── Label ─────────────────────────────────────────────────
            function Tab:CreateLabel(textOrOpts)
                local text = type(textOrOpts) == "table" and (textOrOpts.Name or textOrOpts.Text or "") or tostring(textOrOpts)

                local frame = Library:Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Library.Theme.CardBg,
                    BorderSizePixel  = 0,
                    Parent           = TabPage,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = frame})
                local stroke = Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1, Parent = frame})
                Library:AddCardHover(frame, stroke)

                local lbl = Library:Create("TextLabel", {
                    Size               = UDim2.new(1, -14, 1, 0),
                    Position           = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Font               = Enum.Font.Gotham,
                    TextSize           = 11,
                    TextColor3         = Library.Theme.TextDim,
                    Text               = text,
                    TextXAlignment     = Enum.TextXAlignment.Left,
                    TextTruncate       = Enum.TextTruncate.AtEnd,
                    Parent             = frame,
                })

                return {
                    Set = function(v) lbl.Text = tostring(v) end,
                    GetValue = function() return lbl.Text end,
                }
            end

            -- ── Button ────────────────────────────────────────────────
            function Tab:CreateButton(options)
                options = options or {}
                local text     = options.Name or "Button"
                local callback = options.Callback or function() end
                local desc     = options.Description

                local container = Library:Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, desc and 46 or 34),
                    BackgroundTransparency = 1,
                    Parent           = TabPage,
                })

                local btn = Library:Create("TextButton", {
                    Size             = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Library.Theme.Success,
                    BorderSizePixel  = 0,
                    Font             = Enum.Font.GothamBold,
                    TextSize         = 12,
                    TextColor3       = Library.Theme.Text,
                    Text             = text,
                    Parent           = container,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = btn})

                if desc then
                    btn.Size = UDim2.new(1, 0, 0, 28)
                    Library:Create("TextLabel", {
                        Size               = UDim2.new(1, -10, 0, 16),
                        Position           = UDim2.new(0, 5, 0, 28),
                        BackgroundTransparency = 1,
                        Font               = Enum.Font.Gotham,
                        TextSize           = 10,
                        TextColor3         = Library.Theme.TextSub,
                        Text               = desc,
                        TextXAlignment     = Enum.TextXAlignment.Left,
                        TextTruncate       = Enum.TextTruncate.AtEnd,
                        Parent             = container,
                    })
                end

                btn.MouseEnter:Connect(function()    Library:Tween(btn, {BackgroundColor3 = Library.Theme.SuccessHover}, 0.15):Play() end)
                btn.MouseLeave:Connect(function()    Library:Tween(btn, {BackgroundColor3 = Library.Theme.Success}, 0.15):Play() end)
                btn.MouseButton1Down:Connect(function()
                    Library:Tween(btn, {BackgroundColor3 = Library.Theme.AccentDark, Size = UDim2.new(1, -4, 1, -4), Position = UDim2.new(0, 2, 0, 2)}, 0.06):Play()
                end)
                btn.MouseButton1Up:Connect(function()
                    Library:Tween(btn, {BackgroundColor3 = Library.Theme.SuccessHover, Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)}, 0.1):Play()
                end)
                btn.MouseButton1Click:Connect(function() pcall(callback) end)

                return {
                    Set = function(v) btn.Text = tostring(v) end,
                }
            end

            -- ── Toggle ────────────────────────────────────────────────
            function Tab:CreateToggle(options)
                options = options or {}
                local labelText = options.Name or "Toggle"
                local default   = options.Default  or false
                local flag      = options.Flag
                local callback  = options.Callback or function() end
                local desc      = options.Description

                local container = Library:Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, desc and 46 or 34),
                    BackgroundColor3 = Library.Theme.CardBg,
                    BorderSizePixel  = 0,
                    Parent           = TabPage,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = container})
                local containerStroke = Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1, Parent = container})
                Library:AddCardHover(container, containerStroke)

                Library:Create("TextLabel", {
                    Size               = UDim2.new(1, -64, 0, 22),
                    Position           = UDim2.new(0, 10, 0, desc and 4 or 6),
                    BackgroundTransparency = 1,
                    Font               = Enum.Font.GothamSemibold,
                    TextSize           = 12,
                    TextColor3         = Library.Theme.TextDim,
                    Text               = labelText,
                    TextXAlignment     = Enum.TextXAlignment.Left,
                    Parent             = container,
                })

                if desc then
                    Library:Create("TextLabel", {
                        Size               = UDim2.new(1, -64, 0, 14),
                        Position           = UDim2.new(0, 10, 0, 26),
                        BackgroundTransparency = 1,
                        Font               = Enum.Font.Gotham,
                        TextSize           = 10,
                        TextColor3         = Library.Theme.TextSub,
                        Text               = desc,
                        TextXAlignment     = Enum.TextXAlignment.Left,
                        TextTruncate       = Enum.TextTruncate.AtEnd,
                        Parent             = container,
                    })
                end

                local switch = Library:Create("TextButton", {
                    Size             = UDim2.new(0, 44, 0, 22),
                    Position         = UDim2.new(1, -52, 0.5, -11),
                    BackgroundColor3 = default and Library.Theme.Accent or Library.Theme.ToggleOff,
                    Text             = "",
                    BorderSizePixel  = 0,
                    Parent           = container,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 11), Parent = switch})

                local knob = Library:Create("Frame", {
                    Size             = UDim2.new(0, 18, 0, 18),
                    Position         = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel  = 0,
                    Parent           = switch,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = knob})

                local active = default
                if flag then Library.Flags[flag] = active end

                local function SetState(state, fire)
                    active = state
                    if flag then Library.Flags[flag] = active end
                    local targetPos   = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
                    local targetColor = state and Library.Theme.Accent or Library.Theme.ToggleOff

                    -- Knob squeeze animation
                    Library:Tween(knob, {Size = UDim2.new(0, 14, 0, 18)}, 0.07):Play()
                    task.delay(0.07, function()
                        Library:Tween(knob, {Size = UDim2.new(0, 18, 0, 18), Position = targetPos}, 0.2, Enum.EasingStyle.Back):Play()
                    end)
                    Library:Tween(switch, {BackgroundColor3 = targetColor}, 0.2):Play()

                    if fire ~= false then pcall(callback, active) end
                end

                switch.MouseEnter:Connect(function()
                    if not active then Library:Tween(switch, {BackgroundColor3 = Color3.fromRGB(60, 60, 72)}, 0.12):Play() end
                end)
                switch.MouseLeave:Connect(function()
                    if not active then Library:Tween(switch, {BackgroundColor3 = Library.Theme.ToggleOff}, 0.12):Play() end
                end)
                switch.MouseButton1Click:Connect(function() SetState(not active, true) end)

                local elem = {
                    Set      = SetState,
                    GetValue = function() return active end,
                }
                if flag then Library.Elements[flag] = elem end
                return elem
            end

            -- ── Slider ────────────────────────────────────────────────
            function Tab:CreateSlider(options)
                options = options or {}
                local labelText = options.Name      or "Slider"
                local minVal    = options.Min       or 0
                local maxVal    = options.Max       or 100
                local default   = options.Default   or minVal
                local precision = options.Precision or 0
                local suffix    = options.Suffix    or ""
                local flag      = options.Flag
                local callback  = options.Callback  or function() end

                default = math.clamp(default, minVal, maxVal)

                local container = Library:Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 50),
                    BackgroundColor3 = Library.Theme.CardBg,
                    BorderSizePixel  = 0,
                    Parent           = TabPage,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = container})
                local containerStroke = Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1, Parent = container})
                Library:AddCardHover(container, containerStroke)

                Library:Create("TextLabel", {
                    Size               = UDim2.new(1, -80, 0, 22),
                    Position           = UDim2.new(0, 10, 0, 4),
                    BackgroundTransparency = 1,
                    Font               = Enum.Font.GothamSemibold,
                    TextSize           = 12,
                    TextColor3         = Library.Theme.TextDim,
                    Text               = labelText,
                    TextXAlignment     = Enum.TextXAlignment.Left,
                    Parent             = container,
                })

                local valLabel = Library:Create("TextLabel", {
                    Size               = UDim2.new(0, 70, 0, 22),
                    Position           = UDim2.new(1, -78, 0, 4),
                    BackgroundTransparency = 1,
                    Font               = Enum.Font.GothamBold,
                    TextSize           = 12,
                    TextColor3         = Library.Theme.Text,
                    Text               = tostring(default) .. suffix,
                    TextXAlignment     = Enum.TextXAlignment.Right,
                    Parent             = container,
                })

                local barBg = Library:Create("Frame", {
                    Size             = UDim2.new(1, -20, 0, 8),
                    Position         = UDim2.new(0, 10, 0, 32),
                    BackgroundColor3 = Library.Theme.InputBg,
                    BorderSizePixel  = 0,
                    Parent           = container,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = barBg})
                Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1, Parent = barBg})

                local rel0 = (default - minVal) / (maxVal - minVal)
                local barFill = Library:Create("Frame", {
                    Size             = UDim2.new(rel0, 0, 1, 0),
                    BackgroundColor3 = Library.Theme.Accent,
                    BorderSizePixel  = 0,
                    Parent           = barBg,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = barFill})
                Library:Create("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Library.Theme.Accent),
                        ColorSequenceKeypoint.new(1, Library.Theme.AccentHover),
                    },
                    Parent = barFill,
                })

                -- Knob handle
                local knob = Library:Create("Frame", {
                    Size             = UDim2.new(0, 14, 0, 14),
                    Position         = UDim2.new(rel0, -7, 0.5, -7),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel  = 0,
                    ZIndex           = 3,
                    Parent           = barBg,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = knob})

                local currentValue = default
                if flag then Library.Flags[flag] = currentValue end

                local function UpdateSlider(pos)
                    local relX = math.clamp((pos.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                    local raw  = minVal + (maxVal - minVal) * relX
                    local mult = 10 ^ precision
                    currentValue = math.floor(raw * mult + 0.5) / mult

                    barFill.Size     = UDim2.new(relX, 0, 1, 0)
                    knob.Position    = UDim2.new(relX, -7, 0.5, -7)
                    valLabel.Text    = tostring(currentValue) .. suffix
                    if flag then Library.Flags[flag] = currentValue end
                    pcall(callback, currentValue)
                end

                local dragging = false
                barBg.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        Library:Tween(knob, {Size = UDim2.new(0, 16, 0, 16)}, 0.08):Play()
                        UpdateSlider(i.Position)
                    end
                end)
                Library:Connect(UserInputService.InputChanged, function(i)
                    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                        UpdateSlider(i.Position)
                    end
                end)
                Library:Connect(UserInputService.InputEnded, function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                        Library:Tween(knob, {Size = UDim2.new(0, 14, 0, 14)}, 0.08):Play()
                    end
                end)

                local elem = {
                    Set = function(v)
                        v = math.clamp(v, minVal, maxVal)
                        local r = (v - minVal) / (maxVal - minVal)
                        currentValue = v
                        barFill.Size  = UDim2.new(r, 0, 1, 0)
                        knob.Position = UDim2.new(r, -7, 0.5, -7)
                        valLabel.Text = tostring(v) .. suffix
                        if flag then Library.Flags[flag] = v end
                        pcall(callback, v)
                    end,
                    GetValue = function() return currentValue end,
                }
                if flag then Library.Elements[flag] = elem end
                return elem
            end

            -- ── Dropdown ──────────────────────────────────────────────
            function Tab:CreateDropdown(options)
                options = options or {}
                local labelText = options.Name     or "Dropdown"
                local optList   = options.Options  or {}
                local default   = options.Default  or optList[1] or ""
                local flag      = options.Flag
                local callback  = options.Callback or function() end
                local maxHeight = options.MaxHeight or 160  -- max dropdown list height

                local container = Library:Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 36),
                    BackgroundTransparency = 1,
                    ClipsDescendants = false,
                    ZIndex           = 10,
                    Parent           = TabPage,
                })

                local mainBg = Library:Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = Library.Theme.InputBg,
                    BorderSizePixel  = 0,
                    ZIndex           = 10,
                    Parent           = container,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = mainBg})
                local ddStroke = Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1, Parent = mainBg})

                Library:Create("TextLabel", {
                    Size               = UDim2.new(0.45, 0, 1, 0),
                    Position           = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Font               = Enum.Font.GothamSemibold,
                    TextSize           = 12,
                    TextColor3         = Library.Theme.TextDim,
                    Text               = labelText,
                    TextXAlignment     = Enum.TextXAlignment.Left,
                    ZIndex             = 11,
                    Parent             = mainBg,
                })

                local selectedLbl = Library:Create("TextLabel", {
                    Size               = UDim2.new(0.5, -24, 1, 0),
                    Position           = UDim2.new(0.45, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Font               = Enum.Font.GothamBold,
                    TextSize           = 11,
                    TextColor3         = Library.Theme.Accent,
                    Text               = tostring(default),
                    TextXAlignment     = Enum.TextXAlignment.Right,
                    TextTruncate       = Enum.TextTruncate.AtEnd,
                    ZIndex             = 11,
                    Parent             = mainBg,
                })

                local arrow = Library:Create("TextLabel", {
                    Size               = UDim2.new(0, 22, 1, 0),
                    Position           = UDim2.new(1, -24, 0, 0),
                    BackgroundTransparency = 1,
                    Font               = Enum.Font.GothamBold,
                    TextSize           = 11,
                    TextColor3         = Library.Theme.TextSub,
                    Text               = "▼",
                    ZIndex             = 11,
                    Parent             = mainBg,
                })

                -- Dropdown list panel
                local listPanel = Library:Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 0),
                    Position         = UDim2.new(0, 0, 0, 38),
                    BackgroundColor3 = Library.Theme.DropdownBg,
                    BorderSizePixel  = 0,
                    ClipsDescendants = true,
                    ZIndex           = 20,
                    Visible          = false,
                    Parent           = container,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = listPanel})
                Library:Create("UIStroke", {Color = Library.Theme.StrokeLight, Thickness = 1, Parent = listPanel})

                local listScroll = Library:Create("ScrollingFrame", {
                    Size                   = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    ScrollBarThickness     = 3,
                    ScrollBarImageColor3   = Library.Theme.StrokeLight,
                    CanvasSize             = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize    = Enum.AutomaticSize.Y,
                    ZIndex                 = 20,
                    Parent                 = listPanel,
                })
                Library:Create("UIListLayout", {
                    Padding   = UDim.new(0, 2),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent    = listScroll,
                })
                Library:Create("UIPadding", {
                    PaddingTop    = UDim.new(0, 4),
                    PaddingBottom = UDim.new(0, 4),
                    PaddingLeft   = UDim.new(0, 4),
                    PaddingRight  = UDim.new(0, 4),
                    Parent        = listScroll,
                })

                local open     = false
                local selected = default
                if flag then Library.Flags[flag] = selected end

                local function CloseDropdown()
                    open = false
                    arrow.Text = "▼"
                    Library:Tween(ddStroke, {Color = Library.Theme.Stroke}, 0.15):Play()
                    Library:Tween(listPanel, {Size = UDim2.new(1, 0, 0, 0)}, 0.2, Enum.EasingStyle.Quart):Play()
                    Library:Tween(container, {Size = UDim2.new(1, 0, 0, 36)}, 0.2, Enum.EasingStyle.Quart):Play()
                    task.delay(0.22, function() listPanel.Visible = false end)
                end

                local function PopulateOptions(list)
                    for _, c in ipairs(listScroll:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end

                    for _, opt in ipairs(list) do
                        local isSel = (opt == selected)
                        local item = Library:Create("TextButton", {
                            Size             = UDim2.new(1, 0, 0, 28),
                            BackgroundColor3 = isSel and Library.Theme.AccentDark or Color3.fromRGB(22, 22, 30),
                            Text             = "",
                            BorderSizePixel  = 0,
                            ZIndex           = 21,
                            Parent           = listScroll,
                        })
                        Library:Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = item})

                        Library:Create("TextLabel", {
                            Size               = UDim2.new(1, -34, 1, 0),
                            Position           = UDim2.new(0, 10, 0, 0),
                            BackgroundTransparency = 1,
                            Font               = isSel and Enum.Font.GothamBold or Enum.Font.Gotham,
                            TextSize           = 11,
                            TextColor3         = isSel and Library.Theme.Text or Library.Theme.TextDim,
                            Text               = tostring(opt),
                            TextXAlignment     = Enum.TextXAlignment.Left,
                            ZIndex             = 22,
                            Parent             = item,
                        })

                        if isSel then
                            Library:Create("TextLabel", {
                                Size               = UDim2.new(0, 22, 1, 0),
                                Position           = UDim2.new(1, -24, 0, 0),
                                BackgroundTransparency = 1,
                                Font               = Enum.Font.GothamBold,
                                TextSize           = 12,
                                TextColor3         = Library.Theme.Text,
                                Text               = "✓",
                                ZIndex             = 22,
                                Parent             = item,
                            })
                        end

                        item.MouseEnter:Connect(function()
                            if opt ~= selected then
                                Library:Tween(item, {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}, 0.1):Play()
                            end
                        end)
                        item.MouseLeave:Connect(function()
                            if opt ~= selected then
                                Library:Tween(item, {BackgroundColor3 = Color3.fromRGB(22, 22, 30)}, 0.1):Play()
                            end
                        end)

                        item.MouseButton1Click:Connect(function()
                            selected = opt
                            selectedLbl.Text = tostring(selected)
                            if flag then Library.Flags[flag] = selected end
                            PopulateOptions(list)
                            CloseDropdown()
                            pcall(callback, selected)
                        end)
                    end

                    local itemH = math.min(#list * 30 + 8, maxHeight)
                    listPanel.Size = UDim2.new(1, 0, 0, open and itemH or 0)
                end

                PopulateOptions(optList)

                mainBg.InputBegan:Connect(function(i)
                    if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    open = not open
                    arrow.Text = open and "▲" or "▼"
                    Library:Tween(ddStroke, {Color = open and Library.Theme.Accent or Library.Theme.Stroke}, 0.15):Play()

                    if open then
                        listPanel.Visible = true
                        local targetH = math.min(#optList * 30 + 8, maxHeight)
                        listPanel.Size = UDim2.new(1, 0, 0, 0)
                        Library:Tween(listPanel, {Size = UDim2.new(1, 0, 0, targetH)}, 0.25, Enum.EasingStyle.Quart):Play()
                        Library:Tween(container, {Size = UDim2.new(1, 0, 0, 36 + targetH + 4)}, 0.25, Enum.EasingStyle.Quart):Play()
                    else
                        CloseDropdown()
                    end
                end)

                local elem = {
                    Set = function(v)
                        selected = v
                        selectedLbl.Text = tostring(selected)
                        if flag then Library.Flags[flag] = selected end
                        PopulateOptions(optList)
                        pcall(callback, selected)
                    end,
                    Refresh = function(newList)
                        optList = newList
                        selected = newList[1] or ""
                        selectedLbl.Text = tostring(selected)
                        if flag then Library.Flags[flag] = selected end
                        PopulateOptions(newList)
                    end,
                    GetValue = function() return selected end,
                }
                if flag then Library.Elements[flag] = elem end
                return elem
            end

            -- ── Input ─────────────────────────────────────────────────
            function Tab:CreateInput(options)
                options = options or {}
                local labelText  = options.Name        or "Input"
                local default    = options.Default     or ""
                local placeholder = options.Placeholder or "Type here..."
                local numeric    = options.Numeric     or false
                local flag       = options.Flag
                local callback   = options.Callback    or function() end

                local container = Library:Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = Library.Theme.CardBg,
                    BorderSizePixel  = 0,
                    Parent           = TabPage,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = container})
                Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1, Parent = container})

                Library:Create("TextLabel", {
                    Size               = UDim2.new(0.45, 0, 1, 0),
                    Position           = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Font               = Enum.Font.GothamSemibold,
                    TextSize           = 12,
                    TextColor3         = Library.Theme.TextDim,
                    Text               = labelText,
                    TextXAlignment     = Enum.TextXAlignment.Left,
                    Parent             = container,
                })

                local inputStroke = Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1})

                local box = Library:Create("TextBox", {
                    Size                   = UDim2.new(0.5, -4, 0, 24),
                    Position               = UDim2.new(0.5, 0, 0.5, -12),
                    BackgroundColor3       = Library.Theme.InputBg,
                    BorderSizePixel        = 0,
                    Font                   = Enum.Font.Gotham,
                    TextSize               = 11,
                    TextColor3             = Library.Theme.Text,
                    PlaceholderColor3      = Color3.fromRGB(90, 90, 100),
                    PlaceholderText        = placeholder,
                    Text                   = tostring(default),
                    ClearTextOnFocus       = false,
                    Parent                 = container,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = box})
                inputStroke.Parent = box

                -- Numeric filter
                if numeric then
                    box:GetPropertyChangedSignal("Text"):Connect(function()
                        local filtered = box.Text:gsub("[^%d%.%-]", "")
                        if filtered ~= box.Text then box.Text = filtered end
                    end)
                end

                box.Focused:Connect(function()
                    Library:Tween(inputStroke, {Color = Library.Theme.Accent, Thickness = 1.5}, 0.15):Play()
                end)
                box.FocusLost:Connect(function()
                    Library:Tween(inputStroke, {Color = Library.Theme.Stroke, Thickness = 1}, 0.15):Play()
                    local v = numeric and tonumber(box.Text) or box.Text
                    if flag then Library.Flags[flag] = v end
                    pcall(callback, v)
                end)

                if flag then Library.Flags[flag] = default end

                local elem = {
                    Set = function(v)
                        box.Text = tostring(v)
                        local val = numeric and (tonumber(v) or v) or v
                        if flag then Library.Flags[flag] = val end
                        pcall(callback, val)
                    end,
                    GetValue = function() return numeric and (tonumber(box.Text) or box.Text) or box.Text end,
                }
                if flag then Library.Elements[flag] = elem end
                return elem
            end

            -- ── Number Adjuster ───────────────────────────────────────
            function Tab:CreateNumberAdjust(options)
                options = options or {}
                local labelText = options.Name     or "Adjuster"
                local default   = options.Default  or 1
                local minVal    = options.Min      or 1
                local maxVal    = options.Max      or 100
                local step      = options.Step     or 1
                local flag      = options.Flag
                local callback  = options.Callback or function() end

                local container = Library:Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = Library.Theme.CardBg,
                    BorderSizePixel  = 0,
                    Parent           = TabPage,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = container})
                local stroke = Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1, Parent = container})
                Library:AddCardHover(container, stroke)

                Library:Create("TextLabel", {
                    Size               = UDim2.new(1, -130, 1, 0),
                    Position           = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Font               = Enum.Font.GothamSemibold,
                    TextSize           = 12,
                    TextColor3         = Library.Theme.TextDim,
                    Text               = labelText,
                    TextXAlignment     = Enum.TextXAlignment.Left,
                    Parent             = container,
                })

                local val = math.clamp(default, minVal, maxVal)
                if flag then Library.Flags[flag] = val end

                local valLbl = Library:Create("TextLabel", {
                    Size               = UDim2.new(0, 46, 0, 24),
                    Position           = UDim2.new(1, -86, 0.5, -12),
                    BackgroundTransparency = 1,
                    Font               = Enum.Font.GothamBold,
                    TextSize           = 12,
                    TextColor3         = Library.Theme.Text,
                    Text               = tostring(val),
                    Parent             = container,
                })

                local function Update(newVal)
                    val = math.clamp(newVal, minVal, maxVal)
                    valLbl.Text = tostring(val)
                    if flag then Library.Flags[flag] = val end
                    pcall(callback, val)
                end

                local function MakeBtn(txt, pos, delta)
                    local btn = Library:Create("TextButton", {
                        Size             = UDim2.new(0, 26, 0, 26),
                        Position         = pos,
                        BackgroundColor3 = Library.Theme.InputBg,
                        Font             = Enum.Font.GothamBold,
                        TextSize         = 14,
                        TextColor3       = Library.Theme.Text,
                        Text             = txt,
                        BorderSizePixel  = 0,
                        Parent           = container,
                    })
                    Library:Create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = btn})
                    Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1, Parent = btn})

                    btn.MouseButton1Down:Connect(function()
                        Library:Tween(btn, {BackgroundColor3 = Library.Theme.AccentDark}, 0.06):Play()
                    end)
                    local function resetColor()
                        Library:Tween(btn, {BackgroundColor3 = Library.Theme.InputBg}, 0.12):Play()
                    end
                    btn.MouseButton1Up:Connect(resetColor)
                    btn.MouseLeave:Connect(resetColor)

                    btn.MouseButton1Click:Connect(function() Update(val + delta) end)

                    -- Hold-to-repeat
                    local holding = false
                    btn.MouseButton1Down:Connect(function()
                        holding = true
                        task.delay(0.5, function()
                            while holding do
                                Update(val + delta)
                                task.wait(0.09)
                            end
                        end)
                    end)
                    btn.MouseButton1Up:Connect(function() holding = false end)
                    btn.MouseLeave:Connect(function() holding = false end)
                end

                MakeBtn("−", UDim2.new(1, -60, 0.5, -13), -step)
                MakeBtn("+", UDim2.new(1, -30, 0.5, -13), step)

                local elem = {
                    Set      = function(v) Update(v) end,
                    GetValue = function() return val end,
                }
                if flag then Library.Elements[flag] = elem end
                return elem
            end

            -- ── Keybind ───────────────────────────────────────────────
            function Tab:CreateKeybind(options)
                options = options or {}
                local labelText = options.Name     or "Keybind"
                local default   = options.Default  or Enum.KeyCode.Unknown
                local flag      = options.Flag
                local callback  = options.Callback or function() end

                local container = Library:Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = Library.Theme.CardBg,
                    BorderSizePixel  = 0,
                    Parent           = TabPage,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = container})
                Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1, Parent = container})

                Library:Create("TextLabel", {
                    Size               = UDim2.new(1, -120, 1, 0),
                    Position           = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Font               = Enum.Font.GothamSemibold,
                    TextSize           = 12,
                    TextColor3         = Library.Theme.TextDim,
                    Text               = labelText,
                    TextXAlignment     = Enum.TextXAlignment.Left,
                    Parent             = container,
                })

                local currentKey = default
                if flag then Library.Flags[flag] = currentKey end

                local kbStroke = Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1})
                local keyBtn = Library:Create("TextButton", {
                    Size             = UDim2.new(0, 100, 0, 24),
                    Position         = UDim2.new(1, -108, 0.5, -12),
                    BackgroundColor3 = Library.Theme.InputBg,
                    Font             = Enum.Font.GothamBold,
                    TextSize         = 11,
                    TextColor3       = Library.Theme.Accent,
                    Text             = "[" .. currentKey.Name .. "]",
                    BorderSizePixel  = 0,
                    Parent           = container,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = keyBtn})
                kbStroke.Parent = keyBtn

                local binding = false

                keyBtn.MouseButton1Click:Connect(function()
                    binding = true
                    keyBtn.Text = "[ ... ]"
                    keyBtn.TextColor3 = Color3.fromRGB(255, 210, 50)
                    Library:Tween(kbStroke, {Color = Color3.fromRGB(255, 210, 50)}, 0.15):Play()
                end)

                Library:Connect(UserInputService.InputBegan, function(input, gp)
                    if binding then
                        if input.KeyCode == Enum.KeyCode.Escape then
                            -- Cancel binding
                            binding = false
                            keyBtn.Text = "[" .. currentKey.Name .. "]"
                            keyBtn.TextColor3 = Library.Theme.Accent
                            Library:Tween(kbStroke, {Color = Library.Theme.Stroke}, 0.15):Play()
                        elseif input.UserInputType == Enum.UserInputType.Keyboard then
                            binding = false
                            currentKey = input.KeyCode
                            keyBtn.Text = "[" .. currentKey.Name .. "]"
                            keyBtn.TextColor3 = Library.Theme.Accent
                            Library:Tween(kbStroke, {Color = Library.Theme.Stroke}, 0.15):Play()
                            if flag then Library.Flags[flag] = currentKey end
                        end
                    elseif not gp and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
                        pcall(callback, currentKey)
                    end
                end)

                local elem = {
                    Set = function(k)
                        currentKey = k
                        keyBtn.Text = "[" .. currentKey.Name .. "]"
                        if flag then Library.Flags[flag] = currentKey end
                    end,
                    GetValue = function() return currentKey end,
                }
                if flag then Library.Elements[flag] = elem end
                return elem
            end

            -- ── Color Picker (RGB Sliders) ─────────────────────────────
            function Tab:CreateColorPicker(options)
                options = options or {}
                local labelText   = options.Name     or "Color Picker"
                local default     = options.Default  or Color3.fromRGB(255, 60, 60)
                local flag        = options.Flag
                local callback    = options.Callback or function() end

                local r, g, b = math.round(default.R * 255), math.round(default.G * 255), math.round(default.B * 255)

                local container = Library:Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 34),
                    BackgroundColor3 = Library.Theme.CardBg,
                    BorderSizePixel  = 0,
                    ClipsDescendants = true,
                    Parent           = TabPage,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = container})
                Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1, Parent = container})

                Library:Create("TextLabel", {
                    Size               = UDim2.new(1, -60, 0, 34),
                    Position           = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Font               = Enum.Font.GothamSemibold,
                    TextSize           = 12,
                    TextColor3         = Library.Theme.TextDim,
                    Text               = labelText,
                    TextXAlignment     = Enum.TextXAlignment.Left,
                    Parent             = container,
                })

                -- Preview swatch + expand button
                local swatch = Library:Create("TextButton", {
                    Size             = UDim2.new(0, 38, 0, 22),
                    Position         = UDim2.new(1, -46, 0.5, -11),
                    BackgroundColor3 = default,
                    Text             = "",
                    BorderSizePixel  = 0,
                    Parent           = container,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = swatch})
                Library:Create("UIStroke", {Color = Library.Theme.StrokeLight, Thickness = 1, Parent = swatch})

                -- RGB sliders panel (hidden by default)
                local panel = Library:Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 90),
                    Position         = UDim2.new(0, 0, 0, 34),
                    BackgroundTransparency = 1,
                    Parent           = container,
                })
                Library:Create("UIPadding", {
                    PaddingLeft  = UDim.new(0, 10),
                    PaddingRight = UDim.new(0, 10),
                    Parent       = panel,
                })
                Library:Create("UIListLayout", {
                    Padding   = UDim.new(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent    = panel,
                })

                local currentColor = default
                if flag then Library.Flags[flag] = currentColor end

                local function UpdateColor()
                    currentColor = Color3.fromRGB(r, g, b)
                    Library:Tween(swatch, {BackgroundColor3 = currentColor}, 0.12):Play()
                    if flag then Library.Flags[flag] = currentColor end
                    pcall(callback, currentColor)
                end

                local function MakeRGBSlider(lbl, colorChar, getVal, setVal, accentColor)
                    local row = Library:Create("Frame", {
                        Size             = UDim2.new(1, 0, 0, 22),
                        BackgroundTransparency = 1,
                        Parent           = panel,
                    })

                    Library:Create("TextLabel", {
                        Size               = UDim2.new(0, 14, 1, 0),
                        BackgroundTransparency = 1,
                        Font               = Enum.Font.GothamBold,
                        TextSize           = 10,
                        TextColor3         = accentColor,
                        Text               = lbl,
                        Parent             = row,
                    })

                    local track = Library:Create("Frame", {
                        Size             = UDim2.new(1, -52, 0, 6),
                        Position         = UDim2.new(0, 18, 0.5, -3),
                        BackgroundColor3 = Library.Theme.InputBg,
                        BorderSizePixel  = 0,
                        Parent           = row,
                    })
                    Library:Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = track})

                    local fill = Library:Create("Frame", {
                        Size             = UDim2.new(getVal() / 255, 0, 1, 0),
                        BackgroundColor3 = accentColor,
                        BorderSizePixel  = 0,
                        Parent           = track,
                    })
                    Library:Create("UICorner", {CornerRadius = UDim.new(0, 3), Parent = fill})

                    local knob = Library:Create("Frame", {
                        Size             = UDim2.new(0, 10, 0, 10),
                        Position         = UDim2.new(getVal() / 255, -5, 0.5, -5),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BorderSizePixel  = 0,
                        ZIndex           = 2,
                        Parent           = track,
                    })
                    Library:Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = knob})

                    local valLbl = Library:Create("TextLabel", {
                        Size               = UDim2.new(0, 30, 1, 0),
                        Position           = UDim2.new(1, -30, 0, 0),
                        BackgroundTransparency = 1,
                        Font               = Enum.Font.GothamBold,
                        TextSize           = 10,
                        TextColor3         = Library.Theme.TextDim,
                        Text               = tostring(getVal()),
                        Parent             = row,
                    })

                    local function UpdateTrack(pos)
                        local relX = math.clamp((pos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                        local newVal = math.round(relX * 255)
                        setVal(newVal)
                        fill.Size  = UDim2.new(relX, 0, 1, 0)
                        knob.Position = UDim2.new(relX, -5, 0.5, -5)
                        valLbl.Text = tostring(newVal)
                        UpdateColor()
                    end

                    local drag = false
                    track.InputBegan:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                            drag = true
                            UpdateTrack(i.Position)
                        end
                    end)
                    Library:Connect(UserInputService.InputChanged, function(i)
                        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                            UpdateTrack(i.Position)
                        end
                    end)
                    Library:Connect(UserInputService.InputEnded, function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                            drag = false
                        end
                    end)

                    return fill, knob, valLbl
                end

                local rFill, rKnob, rLbl = MakeRGBSlider("R", "r", function() return r end, function(v) r = v end, Color3.fromRGB(255, 80, 80))
                local gFill, gKnob, gLbl = MakeRGBSlider("G", "g", function() return g end, function(v) g = v end, Color3.fromRGB(80, 200, 80))
                local bFill, bKnob, bLbl = MakeRGBSlider("B", "b", function() return b end, function(v) b = v end, Color3.fromRGB(80, 140, 255))

                local expanded = false
                swatch.MouseButton1Click:Connect(function()
                    expanded = not expanded
                    local targetH = expanded and 124 or 34
                    Library:Tween(container, {Size = UDim2.new(1, 0, 0, targetH)}, 0.25, Enum.EasingStyle.Quart):Play()
                end)

                local function RefreshTracks()
                    local function update(fill, knob, lbl, val)
                        local rel = val / 255
                        fill.Size     = UDim2.new(rel, 0, 1, 0)
                        knob.Position = UDim2.new(rel, -5, 0.5, -5)
                        lbl.Text      = tostring(val)
                    end
                    update(rFill, rKnob, rLbl, r)
                    update(gFill, gKnob, gLbl, g)
                    update(bFill, bKnob, bLbl, b)
                end

                local elem = {
                    Set = function(col)
                        r = math.round(col.R * 255)
                        g = math.round(col.G * 255)
                        b = math.round(col.B * 255)
                        RefreshTracks()
                        UpdateColor()
                    end,
                    GetValue = function() return currentColor end,
                }
                if flag then Library.Elements[flag] = elem end
                return elem
            end

            -- ── Paragraph ─────────────────────────────────────────────
            function Tab:CreateParagraph(options)
                options = options or {}
                local title   = options.Title   or "Info"
                local content = options.Content or ""

                local frame = Library:Create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 0),
                    AutomaticSize    = Enum.AutomaticSize.Y,
                    BackgroundColor3 = Library.Theme.CardBg,
                    BorderSizePixel  = 0,
                    ClipsDescendants = false,
                    Parent           = TabPage,
                })
                Library:Create("UICorner", {CornerRadius = UDim.new(0, 7), Parent = frame})
                local stroke = Library:Create("UIStroke", {Color = Library.Theme.Stroke, Thickness = 1, Parent = frame})
                Library:AddCardHover(frame, stroke)
                Library:Create("UIPadding", {
                    PaddingTop    = UDim.new(0, 8),
                    PaddingBottom = UDim.new(0, 8),
                    PaddingLeft   = UDim.new(0, 10),
                    PaddingRight  = UDim.new(0, 10),
                    Parent        = frame,
                })
                Library:Create("UIListLayout", {
                    Padding   = UDim.new(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent    = frame,
                })

                Library:Create("TextLabel", {
                    Size               = UDim2.new(1, 0, 0, 16),
                    AutomaticSize      = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Font               = Enum.Font.GothamBold,
                    TextSize           = 12,
                    TextColor3         = Library.Theme.Text,
                    Text               = title,
                    TextXAlignment     = Enum.TextXAlignment.Left,
                    TextWrapped        = true,
                    Parent             = frame,
                })

                local descLbl = Library:Create("TextLabel", {
                    Size               = UDim2.new(1, 0, 0, 0),
                    AutomaticSize      = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Font               = Enum.Font.Gotham,
                    TextSize           = 11,
                    TextColor3         = Library.Theme.TextSub,
                    Text               = content,
                    TextWrapped        = true,
                    TextXAlignment     = Enum.TextXAlignment.Left,
                    TextYAlignment     = Enum.TextYAlignment.Top,
                    Parent             = frame,
                })

                return {
                    Set = function(newContent) descLbl.Text = tostring(newContent) end,
                    SetTitle = function(newTitle)
                        local titleLbl = frame:FindFirstChildWhichIsA("TextLabel")
                        if titleLbl then titleLbl.Text = newTitle end
                    end,
                }
            end
        end -- do

        return Tab
    end -- CreateTab

    return Window
end -- CreateWindow

-- ============================================================
-- [10] DESTROY / CLEANUP
-- ============================================================
function Library:Destroy()
    for _, conn in ipairs(Library.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Library.Connections = {}

    if Library.ScreenGui then
        Library.ScreenGui:Destroy()
    end

    Library.Unloaded = true
end

return Library
