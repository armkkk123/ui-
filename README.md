# ui-

Custom Executor GUI Library for Roblox — [GitHub](https://github.com/armkkk123/ui-)

## Quick Demo (ทดสอบทุกฟังก์ชัน)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/armkkk123/ui-/refs/heads/main/Example.lua"))()
```

## Loading the Library

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/armkkk123/ui-/refs/heads/main/Library.lua"))()
```

## Window API

```lua
local Window = Library:CreateWindow({
    Title = "Window Title",
    Size = UDim2.new(0, 540, 0, 360),
    ToggleIcon = "rbxthumb://type=Asset&id=8829255607&w=150&h=150"
})

Library:Notify({
    Title = "Title",
    Content = "Message",
    Duration = 3
})

Library:Destroy()
```

## Config API

```lua
Library:SaveConfiguration("config_name")
Library:LoadConfiguration("config_name")
```

## Tab API

```lua
local Tab = Window:CreateTab("Tab Name")
```

## Component API

```lua
Tab:CreateSection("Section Name")

local Label = Tab:CreateLabel("Text")

local Button = Tab:CreateButton({
    Name = "Button Name",
    Callback = function() end
})

local Toggle = Tab:CreateToggle({
    Name = "Toggle Name",
    Default = false,
    Flag = "ToggleFlag",
    Callback = function(state) end
})

local Slider = Tab:CreateSlider({
    Name = "Slider Name",
    Min = 0,
    Max = 100,
    Default = 50,
    Precision = 0,
    Flag = "SliderFlag",
    Callback = function(value) end
})

local Dropdown = Tab:CreateDropdown({
    Name = "Dropdown Name",
    Options = {"Option 1", "Option 2"},
    Default = "Option 1",
    Flag = "DropdownFlag",
    Callback = function(selected) end
})

local Input = Tab:CreateInput({
    Name = "Input Name",
    Default = "",
    Placeholder = "Placeholder text",
    Flag = "InputFlag",
    Callback = function(text) end
})

local Adjuster = Tab:CreateNumberAdjust({
    Name = "Adjuster Name",
    Default = 1,
    Min = 1,
    Max = 10,
    Flag = "AdjusterFlag",
    Callback = function(value) end
})

local Keybind = Tab:CreateKeybind({
    Name = "Keybind Name",
    Default = Enum.KeyCode.E,
    Flag = "KeybindFlag",
    Callback = function(key) end
})

local ColorPicker = Tab:CreateColorPicker({
    Name = "Color Picker Name",
    Default = Color3.fromRGB(255, 255, 255),
    Flag = "ColorFlag",
    Callback = function(color) end
})

Tab:CreateParagraph({
    Title = "Title",
    Content = "Content"
})
```

## Updating Elements Programmatically

```lua
-- Set new values
Toggle.Set(true)
Slider.Set(75)
Label.Set("New Text")

-- Refresh dropdown options
Dropdown.Refresh({"New Option 1", "New Option 2"})
```
