--[[
    UI Library Demo — ทดสอบทุกฟังก์ชัน
    Repo: https://github.com/armkkk123/ui-

    รันใน Executor:
        loadstring(game:HttpGet("https://raw.githubusercontent.com/armkkk123/ui-/refs/heads/main/Example.lua"))()
    หรือวางไฟล์นี้ใน workspace แล้ว execute ทั้งไฟล์
]]

local LIBRARY_URL = "https://raw.githubusercontent.com/armkkk123/ui-/refs/heads/main/Library.lua"

local Library
do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(LIBRARY_URL))()
    end)
    if ok and type(result) == "table" then
        Library = result
    else
        -- fallback: ถ้ามี Library ใน environment เดียวกัน (รันคู่กับ Library.lua)
        Library = rawget(_G, "Library") or error("[UI Demo] โหลด Library ไม่สำเร็จ: " .. tostring(result))
    end
end

print("[UI Demo] Library v" .. tostring(Library.Version or "?"))

-- ============================================================
-- Theme (ทดสอบ SetTheme)
-- ============================================================
Library:SetTheme({
    Accent      = Color3.fromRGB(0, 175, 255),
    AccentHover = Color3.fromRGB(40, 195, 255),
    Success     = Color3.fromRGB(34, 150, 70),
})

-- ============================================================
-- Window
-- ============================================================
local Window = Library:CreateWindow({
    Title      = "UI Library Demo v" .. tostring(Library.Version or "2"),
    Size       = UDim2.new(0, 560, 0, 400),
    ToggleIcon = "rbxthumb://type=Asset&id=8829255607&w=150&h=150",
})

Library:Notify({
    Title    = "Demo Loaded ✅",
    Content  = "กดแท็บต่างๆ เพื่อลองทุกคอมโพเนนต์",
    Duration = 3,
})

-- ============================================================
-- TAB 1: Controls (Button / Toggle / Slider / Dropdown / Input)
-- ============================================================
local TabControls = Window:CreateTab("Controls")

TabControls:CreateSection("Info")
TabControls:CreateParagraph({
    Title   = "Controls Tab",
    Content = "ปุ่ม, Toggle, Slider, Dropdown, Input — กดเล่นดู callback + notify",
})

local statusLabel = TabControls:CreateLabel("Status: idle")

TabControls:CreateSection("Button")
TabControls:CreateButton({
    Name        = "คลิกฉัน",
    Description = "ทดสอบ CreateButton + Notify",
    Callback    = function()
        statusLabel.Set("Status: Button clicked")
        Library:Notify({
            Title    = "Button",
            Content  = "Callback ทำงานแล้ว",
            Duration = 2,
        })
    end,
})

TabControls:CreateSection("Toggle")
local demoToggle = TabControls:CreateToggle({
    Name        = "Auto Farm",
    Description = "ตัวอย่าง Toggle พร้อม Flag",
    Default     = false,
    Flag        = "Demo_AutoFarm",
    Callback    = function(state)
        statusLabel.Set("Status: Toggle = " .. tostring(state))
        Library:Notify({
            Title    = "Toggle",
            Content  = "Auto Farm: " .. (state and "ON" or "OFF"),
            Duration = 1.5,
        })
    end,
})

TabControls:CreateSection("Slider")
local demoSlider = TabControls:CreateSlider({
    Name      = "Walk Speed",
    Min       = 16,
    Max       = 200,
    Default   = 16,
    Precision = 0,
    Suffix    = " studs",
    Flag      = "Demo_WalkSpeed",
    Callback  = function(value)
        statusLabel.Set("Status: Speed = " .. tostring(value))
    end,
})

TabControls:CreateSection("Dropdown")
local demoDropdown = TabControls:CreateDropdown({
    Name     = "World",
    Options  = { "Lobby", "Forest", "Desert", "Snow", "Volcano" },
    Default  = "Lobby",
    Flag     = "Demo_World",
    Callback = function(selected)
        statusLabel.Set("Status: World = " .. tostring(selected))
        Library:Notify({
            Title    = "Dropdown",
            Content  = "เลือก: " .. tostring(selected),
            Duration = 1.5,
        })
    end,
})

TabControls:CreateButton({
    Name     = "Refresh Dropdown Options",
    Callback = function()
        demoDropdown.Refresh({ "Lobby", "Forest", "Desert", "Snow", "Volcano", "Ocean", "Space" })
        Library:Notify({ Title = "Dropdown", Content = "Refresh() เพิ่ม Ocean + Space", Duration = 2 })
    end,
})

TabControls:CreateSection("Input")
local demoInput = TabControls:CreateInput({
    Name        = "Player Name",
    Default     = "",
    Placeholder = "พิมพ์ชื่อ...",
    Flag        = "Demo_PlayerName",
    Callback    = function(text)
        statusLabel.Set("Status: Name = " .. tostring(text))
    end,
})

TabControls:CreateInput({
    Name        = "Amount (Numeric)",
    Default     = "10",
    Placeholder = "ตัวเลขเท่านั้น",
    Numeric     = true,
    Flag        = "Demo_Amount",
    Callback    = function(value)
        statusLabel.Set("Status: Amount = " .. tostring(value))
    end,
})

-- ============================================================
-- TAB 2: Extra (NumberAdjust / Keybind / ColorPicker / Label)
-- ============================================================
local TabExtra = Window:CreateTab("Extra")

TabExtra:CreateSection("Number Adjust")
local demoAdjust = TabExtra:CreateNumberAdjust({
    Name     = "Unit Count",
    Default  = 1,
    Min      = 1,
    Max      = 50,
    Step     = 1,
    Flag     = "Demo_UnitCount",
    Callback = function(value)
        Library:Notify({
            Title    = "NumberAdjust",
            Content  = "Unit Count = " .. tostring(value),
            Duration = 1.2,
        })
    end,
})

TabExtra:CreateSection("Keybind")
TabExtra:CreateKeybind({
    Name     = "Toggle UI Key",
    Default  = Enum.KeyCode.RightControl,
    Flag     = "Demo_Keybind",
    Callback = function(key)
        Library:Notify({
            Title    = "Keybind Fired",
            Content  = "กด " .. tostring(key.Name),
            Duration = 2,
        })
    end,
})

TabExtra:CreateSection("Color Picker")
local demoColor = TabExtra:CreateColorPicker({
    Name     = "ESP Color",
    Default  = Color3.fromRGB(0, 175, 255),
    Flag     = "Demo_ESPColor",
    Callback = function(color)
        Library:Notify({
            Title    = "ColorPicker",
            Content  = string.format("RGB(%d, %d, %d)", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)),
            Duration = 1.5,
        })
    end,
})

TabExtra:CreateSection("Label Set / Get")
local liveLabel = TabExtra:CreateLabel("Live Label: 0")
TabExtra:CreateButton({
    Name     = "Update Label (Set)",
    Callback = function()
        local n = math.random(1, 999)
        liveLabel.Set("Live Label: " .. n)
        Library:Notify({
            Title   = "Label.GetValue()",
            Content = tostring(liveLabel.GetValue()),
            Duration = 2,
        })
    end,
})

TabExtra:CreateSection("Paragraph")
local demoParagraph = TabExtra:CreateParagraph({
    Title   = "About this library",
    Content = "Custom Executor GUI Library — Section, Label, Button, Toggle, Slider, Dropdown, Input, NumberAdjust, Keybind, ColorPicker, Paragraph + Config Save/Load.",
})

TabExtra:CreateButton({
    Name     = "Update Paragraph Content",
    Callback = function()
        demoParagraph.Set("อัปเดตเนื้อหาตอน " .. os.date("%H:%M:%S"))
        demoParagraph.SetTitle("Paragraph updated")
    end,
})

-- ============================================================
-- TAB 3: Programmatic Set / Flags
-- ============================================================
local TabAPI = Window:CreateTab("API Test")

TabAPI:CreateSection("Element.Set()")
TabAPI:CreateParagraph({
    Title   = "Programmatic API",
    Content = "ทดสอบ Set / GetValue / Flags / Notify queue",
})

TabAPI:CreateButton({
    Name     = "Set Toggle = true",
    Callback = function()
        demoToggle.Set(true)
        statusLabel.Set("Status: Toggle.Set(true)")
    end,
})

TabAPI:CreateButton({
    Name     = "Set Slider = 100",
    Callback = function()
        demoSlider.Set(100)
        statusLabel.Set("Status: Slider.Set(100) → " .. tostring(demoSlider.GetValue()))
    end,
})

TabAPI:CreateButton({
    Name     = "Set Dropdown = Desert",
    Callback = function()
        demoDropdown.Set("Desert")
        statusLabel.Set("Status: Dropdown = " .. tostring(demoDropdown.GetValue()))
    end,
})

TabAPI:CreateButton({
    Name     = "Set Input / Adjust / Color",
    Callback = function()
        demoInput.Set("DemoPlayer")
        demoAdjust.Set(25)
        demoColor.Set(Color3.fromRGB(255, 80, 120))
        Library:Notify({ Title = "Set()", Content = "Input + Adjust + Color อัปเดตแล้ว", Duration = 2 })
    end,
})

TabAPI:CreateSection("Flags Dump")
TabAPI:CreateButton({
    Name     = "Print Library.Flags",
    Callback = function()
        local lines = {}
        for flag, val in pairs(Library.Flags) do
            local shown = val
            if typeof(val) == "Color3" then
                shown = string.format("Color3(%d,%d,%d)", math.floor(val.R * 255), math.floor(val.G * 255), math.floor(val.B * 255))
            elseif typeof(val) == "EnumItem" then
                shown = val.Name
            end
            table.insert(lines, tostring(flag) .. " = " .. tostring(shown))
            print("[Flag]", flag, "=", shown)
        end
        Library:Notify({
            Title    = "Flags",
            Content  = (#lines > 0) and table.concat(lines, " | ") or "(empty)",
            Duration = 4,
        })
    end,
})

TabAPI:CreateButton({
    Name        = "Spam 5 Notifies",
    Description = "ทดสอบ queue (MAX_VISIBLE = 3)",
    Callback    = function()
        for i = 1, 5 do
            Library:Notify({
                Title    = "Notify #" .. i,
                Content  = "คิวแจ้งเตือนทดสอบ",
                Duration = 2,
            })
        end
    end,
})

-- ============================================================
-- TAB 4: Config Save / Load + Destroy
-- ============================================================
local TabConfig = Window:CreateTab("Config")

TabConfig:CreateSection("Save / Load")
TabConfig:CreateParagraph({
    Title   = "Configuration",
    Content = "เซฟ/โหลดค่า Flag ทั้งหมดลงโฟลเดอร์ UILibConfigs (ต้องมี writefile/readfile)",
})

local configNameInput = TabConfig:CreateInput({
    Name        = "Config Name",
    Default     = "demo",
    Placeholder = "ชื่อไฟล์ config",
    Flag        = "Demo_ConfigName",
})

TabConfig:CreateButton({
    Name     = "💾 Save Configuration",
    Callback = function()
        local name = configNameInput.GetValue()
        if name == nil or name == "" then name = "demo" end
        Library:SaveConfiguration(tostring(name))
    end,
})

TabConfig:CreateButton({
    Name     = "📂 Load Configuration",
    Callback = function()
        local name = configNameInput.GetValue()
        if name == nil or name == "" then name = "demo" end
        Library:LoadConfiguration(tostring(name))
        statusLabel.Set("Status: Config loaded")
    end,
})

TabConfig:CreateSection("Cleanup")
TabConfig:CreateButton({
    Name        = "🗑️ Destroy Library",
    Description = "ปิด GUI + ตัด connection ทั้งหมด",
    Callback    = function()
        Library:Notify({ Title = "Bye", Content = "Destroy ใน 1 วินาที...", Duration = 1 })
        task.delay(1, function()
            Library:Destroy()
        end)
    end,
})

print("[UI Demo] Ready — เปิดหน้าต่าง UI Library Demo ได้เลย")
