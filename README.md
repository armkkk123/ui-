<p align="center">
  <img src="https://img.shields.io/badge/Roblox-Executor%20UI-0A0A0A?style=for-the-badge&logo=roblox&logoColor=white" alt="Roblox" />
  <img src="https://img.shields.io/badge/Luau-Compatible-00A2FF?style=for-the-badge" alt="Luau" />
  <img src="https://img.shields.io/badge/Version-1.0-2EA043?style=for-the-badge" alt="Version" />
  <img src="https://img.shields.io/github/license/armkkk123/ui-?style=for-the-badge" alt="License" />
</p>

<h1 align="center">ui-</h1>

<p align="center">
  <b>A modern, production-ready GUI library for Roblox executors.</b><br/>
  Clean layout · Live themes · Config flags · Built for scripts that ship.
</p>

<p align="center">
  <a href="#-quick-start"><b>Quick Start</b></a> ·
  <a href="#-features"><b>Features</b></a> ·
  <a href="#-api-reference"><b>API</b></a> ·
  <a href="#-settings-panel"><b>Settings</b></a> ·
  <a href="https://github.com/armkkk123/ui-"><b>Repository</b></a>
</p>

---

## Why ui-?

Most executor UIs feel dated or fragile. **ui-** focuses on what actually matters when you distribute a script:

- Consistent visual language across tabs and controls  
- Theme + keybind controls users can change without editing code  
- Flag-based config save/load for real AFK / farm scripts  
- Obfuscated distribution build for public loadstrings  

---

## Features

| Area | What you get |
|------|----------------|
| **Layout** | Responsive window sizing for PC, tablet, and mobile |
| **Motion** | Smooth tweens, card hover, minimize ↔ floating toggle |
| **Theming** | Live accent / surface colors with HSV color pickers |
| **Controls** | Button, Toggle, Slider, Dropdown, Input, Number Adjust, Keybind, Color Picker, Paragraph |
| **Settings** | In-window gear panel: GUI toggle keybind + theme + reset |
| **Config** | Save / load element flags to executor filesystem |
| **DX** | Dot APIs (`.Set`, `.Refresh`) and English-facing UI strings |

---

## Quick Start

### Production (recommended)

Load the obfuscated library from GitHub:

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/armkkk123/ui-/refs/heads/main/Library.obfuscated.lua"
))()
```

### Minimal window

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/armkkk123/ui-/refs/heads/main/Library.obfuscated.lua"
))()

local Window = Library:CreateWindow({
    Title      = "My Script",
    ToggleIcon = "rbxthumb://type=Asset&id=8829255607&w=150&h=150",
})

local Tab = Window:CreateTab("Main")

Tab:CreateToggle({
    Name     = "Auto Farm",
    Default  = false,
    Flag     = "AutoFarm",
    Callback = function(state)
        -- your logic
    end,
})

Library:Notify({
    Title    = "Ready",
    Content  = "UI loaded successfully",
    Duration = 3,
})
```

### Full component demo

If `Example.lua` is available in your local tree:

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/armkkk123/ui-/refs/heads/main/Example.lua"
))()
```

> Prefer the **obfuscated** build for public scripts. Keep the cleartext `Library.lua` for development only.

---

## Settings Panel

Open the **gear icon** (top-right, next to minimize):

| Control | Default | Description |
|---------|---------|-------------|
| Toggle GUI keybind | `RightControl` | Show / hide the entire UI |
| Theme color pickers | Built-in palette | Accent, backgrounds, text, strokes |
| Reset Theme | — | Restore factory colors instantly |

Theme changes apply **live** — no reload required.

```lua
Library:SetTheme({ Accent = Color3.fromRGB(255, 100, 100) })
Library:ResetTheme()
```

---

## API Reference

### Library

```lua
Library:CreateWindow({
    Title      = "Window Title",
    ToggleIcon = "rbxassetid://0", -- optional floating icon
})

Library:Notify({ Title = "Title", Content = "Message", Duration = 3 })
Library:SetTheme({ Accent = Color3.fromRGB(78, 161, 255) })
Library:ResetTheme()
Library:SaveConfiguration("config_name")
Library:LoadConfiguration("config_name")
Library:Destroy()
```

### Tabs & sections

```lua
local Tab = Window:CreateTab("Tab Name")
Tab:CreateSection("Section Name")
```

### Components

```lua
local Label = Tab:CreateLabel("Text")

local Button = Tab:CreateButton({
    Name        = "Button Name",
    Description = "Optional helper text", -- optional
    Callback    = function() end,
})

local Toggle = Tab:CreateToggle({
    Name     = "Toggle Name",
    Default  = false,
    Flag     = "ToggleFlag",
    Callback = function(state) end,
})

local Slider = Tab:CreateSlider({
    Name      = "Slider Name",
    Min       = 0,
    Max       = 100,
    Default   = 50,
    Precision = 0,
    Flag      = "SliderFlag",
    Callback  = function(value) end,
})

local Dropdown = Tab:CreateDropdown({
    Name     = "Dropdown Name",
    Options  = { "Option 1", "Option 2" },
    Default  = "Option 1",
    Flag     = "DropdownFlag",
    Callback = function(selected) end,
})

local Input = Tab:CreateInput({
    Name        = "Input Name",
    Default     = "",
    Placeholder = "Type here...",
    Flag        = "InputFlag",
    Callback    = function(text) end,
})

local Adjuster = Tab:CreateNumberAdjust({
    Name     = "Adjuster Name",
    Default  = 1,
    Min      = 1,
    Max      = 10,
    Flag     = "AdjusterFlag",
    Callback = function(value) end,
})

local Keybind = Tab:CreateKeybind({
    Name     = "Keybind Name",
    Default  = Enum.KeyCode.E,
    Flag     = "KeybindFlag",
    Callback = function(key) end,
})

local ColorPicker = Tab:CreateColorPicker({
    Name     = "Color Picker Name",
    Default  = Color3.fromRGB(255, 255, 255),
    Flag     = "ColorFlag",
    Callback = function(color) end,
})

Tab:CreateParagraph({
    Title   = "Title",
    Content = "Long-form helper text goes here.",
})
```

### Updating elements at runtime

Use **dot** calls (not colon):

```lua
Toggle.Set(true)
Slider.Set(75)
Label.Set("New Text")
Dropdown.Refresh({ "New Option 1", "New Option 2" })
Dropdown.Set("New Option 1")
Input.Set("https://discord.com/api/webhooks/...")
```

---

## Distribution

| File | Use for |
|------|---------|
| [`Library.obfuscated.lua`](https://raw.githubusercontent.com/armkkk123/ui-/refs/heads/main/Library.obfuscated.lua) | Public loadstrings / released scripts |
| `Library.lua` (local) | Editing, debugging, contributing |

Raw URL (obfuscated):

```text
https://raw.githubusercontent.com/armkkk123/ui-/refs/heads/main/Library.obfuscated.lua
```

---

## Best Practices

1. **One window per script** — call `Library:Destroy()` (or re-exec) before creating another.  
2. **Always set `Flag`** on toggles / sliders / dropdowns you want persisted.  
3. **Keep callbacks light** — spawn long work with `task.spawn` so the UI stays responsive.  
4. **Ship obfuscated** — load `Library.obfuscated.lua` in production entrypoints.  

---

## Compatibility

- Roblox Luau (executor environments)  
- Requires standard executor APIs used by modern hubs (`HttpGet`, filesystem for config when available)  

---

## Links

- Repository: [github.com/armkkk123/ui-](https://github.com/armkkk123/ui-)  
- Obfuscated library: [Library.obfuscated.lua](https://github.com/armkkk123/ui-/blob/main/Library.obfuscated.lua)  

---

<p align="center">
  <sub>Built for Roblox executor scripts · ui-</sub>
</p>
