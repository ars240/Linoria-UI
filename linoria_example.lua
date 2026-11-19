loadstring(game:HttpGet("https://raw.githubusercontent.com/ars240/Linoria-UI/main/linoria.lua"))()
local Library = _G.Linoria
local ThemeManager = Library.ThemeManager
local SaveManager = Library.SaveManager

local Window = Library:CreateWindow({
    Title = 'Example Hub | v1.0',
    Center = true,
    AutoShow = true,
    TabPadding = 0,
    MenuFadeTime = 0.2
})

local Tabs = {
    Legit = Window:AddTab('Legit'),
    Visuals = Window:AddTab('Visuals'),
    Misc = Window:AddTab('Misc'),
    Settings = Window:AddTab('Settings'),
}

local AimAssist = Tabs.Legit:AddLeftGroupbox('Aim Assist')
AimAssist:AddToggle('AimEnabled', { Text = 'Enabled', Default = false, Tooltip = 'Turns aim assist on' })
    :AddKeyPicker('AimKey', { Default = 'MB2', Mode = 'Hold', Text = 'Aim assist' })
AimAssist:AddSlider('AimFOV', { Text = 'FOV', Default = 105, Min = 0, Max = 360, Rounding = 0, Suffix = ' deg' })
AimAssist:AddSlider('AimSmooth', { Text = 'Smoothing', Default = 3, Min = 0, Max = 100, Rounding = 0, Suffix = '%' })
AimAssist:AddDropdown('AimHitbox', { Text = 'Hitbox', Values = { 'Head', 'Torso', 'Closest' }, Default = 1 })
AimAssist:AddDivider()
AimAssist:AddToggle('AimDrawFOV', { Text = 'Draw FOV' })
    :AddColorPicker('AimFOVColor', { Default = Color3.fromRGB(255, 255, 255), Title = 'FOV color' })
AimAssist:AddSlider('AimFOVSides', { Text = 'Num sides', Default = 48, Min = 3, Max = 64, Rounding = 0 })

local Checks = Tabs.Legit:AddLeftGroupbox('Checks')
Checks:AddToggle('CheckTeam', { Text = 'Team check', Default = true })
Checks:AddToggle('CheckWall', { Text = 'Wall check', Default = true })
Checks:AddToggle('CheckAlive', { Text = 'Alive check', Default = true })

local Redirect = Tabs.Legit:AddRightGroupbox('Bullet Redirection')
Redirect:AddToggle('SilentEnabled', { Text = 'Enabled', Risk = true, Tooltip = 'Risky feature' })
Redirect:AddSlider('SilentFOV', { Text = 'Silent aim FOV', Default = 105, Min = 0, Max = 360, Rounding = 0, Suffix = ' deg' })
Redirect:AddSlider('SilentChance', { Text = 'Hit chance', Default = 100, Min = 0, Max = 100, Rounding = 0, Suffix = '%' })
Redirect:AddDropdown('SilentMode', { Text = 'Redirection mode', Values = { 'Raycast', 'Mouse.Hit', 'P Mode' }, Default = 3 })

local Trigger = Tabs.Legit:AddRightTabbox()
local TriggerMain = Trigger:AddTab('Trigger bot')
TriggerMain:AddToggle('TriggerEnabled', { Text = 'Enabled' })
    :AddKeyPicker('TriggerKey', { Default = 'E', Mode = 'Toggle', Text = 'Trigger bot', SyncToggleState = true })
TriggerMain:AddSlider('TriggerDelay', { Text = 'Delay', Default = 50, Min = 0, Max = 500, Rounding = 0, Suffix = 'ms' })
local Recoil = Trigger:AddTab('Recoil')
Recoil:AddToggle('RecoilEnabled', { Text = 'Enabled' })
Recoil:AddSlider('RecoilModel', { Text = 'Model kick', Default = 100, Min = 0, Max = 100, Rounding = 0, Suffix = '%' })
Recoil:AddSlider('RecoilCamera', { Text = 'Camera kick', Default = 100, Min = 0, Max = 100, Rounding = 0, Suffix = '%' })

local Esp = Tabs.Visuals:AddLeftGroupbox('ESP')
Esp:AddToggle('EspEnabled', { Text = 'Enabled' })
    :AddKeyPicker('EspKey', { Default = 'F2', Mode = 'Toggle', Text = 'ESP', SyncToggleState = true })
local EspOptions = Esp:AddDependencyBox()
EspOptions:AddToggle('EspBox', { Text = 'Boxes', Default = true })
    :AddColorPicker('EspBoxColor', { Default = Color3.fromRGB(255, 50, 50) })
EspOptions:AddToggle('EspName', { Text = 'Names', Default = true })
    :AddColorPicker('EspNameColor', { Default = Color3.fromRGB(255, 255, 255) })
EspOptions:AddToggle('EspHealth', { Text = 'Health bar' })
EspOptions:AddToggle('EspTracer', { Text = 'Tracers' })
    :AddColorPicker('EspTracerColor', { Default = Color3.fromRGB(0, 170, 255), Transparency = 0 })
EspOptions:AddDropdown('EspTracerFrom', { Text = 'Tracer origin', Values = { 'Bottom', 'Center', 'Mouse' }, Default = 1 })
EspOptions:AddSlider('EspDistance', { Text = 'Max distance', Default = 1000, Min = 50, Max = 5000, Rounding = 0, Suffix = ' studs' })
EspOptions:SetupDependencies({ { Toggles.EspEnabled, true } })

local World = Tabs.Visuals:AddRightGroupbox('World')
World:AddToggle('Fullbright', { Text = 'Fullbright' })
World:AddSlider('FieldOfView', { Text = 'Field of view', Default = 70, Min = 30, Max = 120, Rounding = 0 })
World:AddLabel('Ambient'):AddColorPicker('AmbientColor', { Default = Color3.fromRGB(128, 128, 128) })
World:AddDropdown('Skybox', { Text = 'Skybox', Values = { 'Default', 'Night', 'Space', 'Sunset' }, Default = 1 })

local Movement = Tabs.Misc:AddLeftGroupbox('Movement')
Movement:AddToggle('SpeedEnabled', { Text = 'Speed' })
    :AddKeyPicker('SpeedKey', { Default = 'C', Mode = 'Toggle', Text = 'Speed', SyncToggleState = true })
Movement:AddSlider('SpeedValue', { Text = 'Walk speed', Default = 16, Min = 16, Max = 200, Rounding = 0, Compact = true })
Movement:AddToggle('InfJump', { Text = 'Infinite jump' })
Movement:AddToggle('Noclip', { Text = 'Noclip', Risk = true })
    :AddKeyPicker('NoclipKey', { Default = 'V', Mode = 'Toggle', Text = 'Noclip', SyncToggleState = true })

local PlayerBox = Tabs.Misc:AddRightGroupbox('Players')
PlayerBox:AddDropdown('TargetPlayer', { SpecialType = 'Player', Text = 'Target' })
PlayerBox:AddButton({ Text = 'Teleport', Func = function() end, Tooltip = 'Teleport to target' })
    :AddButton({ Text = 'Spectate', Func = function() end })
PlayerBox:AddDropdown('IgnoredPlayers', { Text = 'Ignored', Values = { 'Friends', 'Teammates', 'Admins' }, Multi = true, Default = 1 })

local Server = Tabs.Misc:AddRightGroupbox('Server')
Server:AddInput('JobId', { Text = 'Job id', Placeholder = 'paste job id', Finished = true })
Server:AddButton({ Text = 'Join', Func = function() end })
    :AddButton({ Text = 'Rejoin', Func = function() end, DoubleClick = true, Tooltip = 'Double click' })
Server:AddButton({ Text = 'Server hop', Func = function() end })

local Info = Tabs.Misc:AddLeftGroupbox('Info')
Info:AddLabel('Example Hub is a UI demo.\nNothing here does anything.', true)

local Menu = Tabs.Settings:AddLeftGroupbox('Menu')
Menu:AddButton('Unload', function() Library:Unload() end)
Menu:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'F1', NoUI = true, Text = 'Menu keybind' })
Menu:AddToggle('ShowKeybinds', { Text = 'Keybind list', Default = true })
Menu:AddToggle('ShowWatermark', { Text = 'Watermark', Default = true })

Library.ToggleKeybind = Options.MenuKeybind
Toggles.ShowKeybinds:OnChanged(function(v) Library.KeybindFrame.Visible = v end)
Toggles.ShowWatermark:OnChanged(function(v) Library:SetWatermarkVisibility(v) end)

local FrameTimer, FrameCounter, FPS = tick(), 0, 60
local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter = FrameCounter + 1
    if tick() - FrameTimer >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end
    Library:SetWatermark(('Example Hub | %s fps'):format(FPS))
end)

Library:OnUnload(function()
    WatermarkConnection:Disconnect()
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('ExampleHub')
SaveManager:SetFolder('ExampleHub/configs')
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Library:Notify('Example Hub loaded', 4)
