# Linoria

## Loading
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/ars240/Linoria-UI/main/linoria.lua"))()
local Library = _G.Linoria
local ThemeManager = Library.ThemeManager
local SaveManager = Library.SaveManager
```
`Toggles` and `Options` are in `_G`.
Matcha's `loadstring` doesn't pass back return values, so use `_G.Linoria`.
Text above size 16 looks blocky (Matcha stretches one bitmap font).

## Customizing
Set these before or after `CreateWindow`. Changes show on the next frame.
```lua
Library:SetTheme({
    -- any of these, also readable as Library.AccentColor etc
    -- Library.AccentColorDark (borders of checked toggles / slider fills) follows AccentColor automatically
    AccentColor = Color3.fromRGB(255, 50, 50), -- Color3 or "ff3232"
    MainColor = "1c1c1c",
    BackgroundColor = "141414",
    OutlineColor = "323232",
    FontColor = "ffffff",
    RiskColor = "ff3232",
})
Library:SetFont("Monospace", 15) -- UI, System, SystemBold, Monospace, Pixel, ProximaSoftBold, Minecraft, Fortnite

Library.ToggleKey = "RightShift"   -- menu key when ToggleKeybind is not set
Library.ScrollBar = true
Library.GroupboxSpacing = 8
Library.NotifyTime = 5
Library.MenuFadeTime = 0.2

Library:SetWatermarkPosition(100, 11)
Library:SetKeybindFramePosition(10, 400)
Library:SetKeybindFrameVisibility(true)
Library:SetNotifyPosition(10, 40, "Left") -- side: "Left" / "Right"
```

## Window
```lua
local Window = Library:CreateWindow({
    Title = 'Example menu',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2,
    Size = { 550, 600 },          -- optional (also Vector2)
    Position = { 175, 50 },       -- optional (also Vector2)
    Theme = { AccentColor = "0055ff" }, -- optional, same as SetTheme
    Font = "Monospace",           -- optional
    TextSize = 15,                -- optional
    ToggleKey = "RightShift",     -- optional
})

Window:SetWindowTitle('New title')
Window:SetSize(600, 650)
Window:SetPosition(100, 100)
Window:Center()
Window:SelectTab('Main')
```

## Tabs
```lua
local Tab = Window:AddTab('Main')
local Left = Tab:AddLeftGroupbox('Groupbox')
local Right = Tab:AddRightGroupbox('Groupbox')
```

## Tabboxes
```lua
local TabBox = Tab:AddRightTabbox() -- or AddLeftTabbox
local Tab1 = TabBox:AddTab('Tab 1')
local Tab2 = TabBox:AddTab('Tab 2')
Tab2:Show()
```

## Toggle
```lua
Left:AddToggle('MyToggle', {
    Text = 'This is a toggle',
    Default = false,
    Tooltip = 'This is a tooltip',
    Risk = false, -- red text
    Callback = function(Value) end
})

Toggles.MyToggle.Value
Toggles.MyToggle:SetValue(true)
Toggles.MyToggle:SetText('New text')
Toggles.MyToggle:OnChanged(function(Value) end)
```
`OnChanged` runs once right away with the current value (all elements).

## Button
```lua
local Button = Left:AddButton({
    Text = 'Button',
    Func = function() end,
    DoubleClick = false,
    Tooltip = 'This is the main button'
})
Button:AddButton({ Text = 'Sub button', Func = function() end, DoubleClick = true })

Left:AddButton('Button', function() end)
```

## Label
```lua
local Label = Left:AddLabel('This is a label')
Left:AddLabel('This label\nwraps its text', true)
Label:SetText('New text')
```

## Divider / Blank
```lua
Left:AddDivider()
Left:AddBlank(10)
```

## Slider
```lua
Left:AddSlider('MySlider', {
    Text = 'This is my slider!',
    Default = 0,
    Min = 0,
    Max = 5,
    Rounding = 1,
    Suffix = '',
    Compact = false,
    HideMax = false,
    Tooltip = 'This is a tooltip',
    Callback = function(Value) end
})

Options.MySlider.Value
Options.MySlider:SetValue(3)
Options.MySlider:SetMin(0)
Options.MySlider:SetMax(10)
Options.MySlider:OnChanged(function(Value) end)
```

## Input
```lua
Left:AddInput('MyTextbox', {
    Default = 'My textbox!',
    Numeric = false,
    Finished = false, -- only calls back on enter
    Text = 'This is a textbox',
    Tooltip = 'This is a tooltip',
    Placeholder = 'Placeholder text',
    MaxLength = 50,
    Callback = function(Value) end
})

Options.MyTextbox.Value
Options.MyTextbox:SetValue('text')
Options.MyTextbox:OnChanged(function(Value) end)
```

## Dropdown
```lua
Left:AddDropdown('MyDropdown', {
    Values = { 'This', 'is', 'a', 'dropdown' },
    Default = 1, -- index or string
    Multi = false,
    AllowNull = false,
    Text = 'A dropdown',
    Tooltip = 'This is a tooltip',
    Callback = function(Value) end
})

Left:AddDropdown('MyPlayerDropdown', { SpecialType = 'Player', Text = 'A player dropdown' }) -- or 'Team'

Options.MyDropdown.Value          -- string, multi: { [value] = true }
Options.MyDropdown:SetValue('This')
Options.MyMultiDropdown:SetValue({ This = true, is = true })
Options.MyDropdown:SetValues({ 'a', 'b' })
Options.MyDropdown:GetActiveValues()
Options.MyDropdown:OpenDropdown()
Options.MyDropdown:CloseDropdown()
Options.MyPlayerDropdown:Refresh() -- Player / Team lists also refresh every 2s
Options.MyDropdown:OnChanged(function(Value) end)
```

## Color picker
```lua
Left:AddLabel('Color'):AddColorPicker('ColorPicker', {
    Default = Color3.new(0, 1, 0),
    Title = 'Some color',
    Transparency = 0, -- nil to disable
    Callback = function(Value) end
})

Options.ColorPicker.Value
Options.ColorPicker.Transparency
Options.ColorPicker:SetValueRGB(Color3.fromRGB(0, 255, 140))
Options.ColorPicker:SetValue({ h, s, v }, transparency)
Options.ColorPicker:Show()
Options.ColorPicker:Hide()
Options.ColorPicker:OnChanged(function(Value) end)
```

## Keybind
```lua
Left:AddLabel('Keybind'):AddKeyPicker('KeyPicker', {
    Default = 'MB2', -- key name, MB1 / MB2
    SyncToggleState = false,
    Mode = 'Toggle', -- Always, Toggle, Hold
    Text = 'Auto lockpick safes',
    NoUI = false,
    Callback = function(Value) end,
    ChangedCallback = function(New) end
})

Options.KeyPicker.Value
Options.KeyPicker.Mode
Options.KeyPicker:GetState()
Options.KeyPicker:SetValue({ 'MB2', 'Toggle' })
Options.KeyPicker:OnClick(function() end)
Options.KeyPicker:OnChanged(function() end)
```
Color pickers and keybinds also go on toggles: `Left:AddToggle(...):AddKeyPicker(...)`.
`SyncToggleState = true` (on a toggle) forces Toggle mode and keeps the keybind and toggle in sync.
Click the key box to rebind, right click it to pick the mode.

## Dependency box
```lua
local Depbox = Right:AddDependencyBox()
Depbox:AddToggle('DepboxToggle', { Text = 'Sub toggle' })
Depbox:SetupDependencies({
    { Toggles.ControlToggle, true }
})
```

## Library
```lua
Library:Notify('Hello', 5)
Library:SetWatermarkVisibility(true)
Library:SetWatermark('text')
Library.KeybindFrame.Visible = true
Library.ToggleKeybind = Options.MenuKeybind
Library:Toggle()
Library.Toggled
Library.Unloaded
Library:OnUnload(function() end)
Library:Unload()
```
`Unload` removes every drawing and connection, runs `OnUnload` callbacks, then clears `Toggles` and `Options`.
Your own loops keep running: stop them in `OnUnload` or check `Library.Unloaded`.
Elements only draw when fully inside the scroll area; labels draw line by line.

## ThemeManager / SaveManager
```lua
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('MyScriptHub')
SaveManager:SetFolder('MyScriptHub/specific-game')
SaveManager:BuildConfigSection(Tab)
ThemeManager:ApplyToTab(Tab)
SaveManager:LoadAutoloadConfig()
```
Built-in themes: Default, BBot, Fatality, Jester, Mint, Tokyo Night, Ubuntu, Quartz.

## Key names
`A`-`Z`, `Zero`-`Nine`, `F1`-`F12`, `KeypadZero`-`KeypadNine`, `LeftShift`, `RightShift`, `LeftControl`, `RightControl`, `LeftAlt`, `RightAlt`, `Space`, `Tab`, `Return`, `Escape`, `Backspace`, `CapsLock`, `Insert`, `Delete`, `Home`, `End`, `PageUp`, `PageDown`, `Left`, `Up`, `Right`, `Down`, `MB1`, `MB2`, `MB3`, `MB4`, `MB5`
