local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local genv = _G
pcall(function() if getgenv then genv = getgenv() end end)

if genv.__Linoria then
    pcall(function() genv.__Linoria:Unload() end)
end

local Toggles = {}
local Options = {}
genv.Toggles = Toggles
genv.Options = Options
_G.Toggles = Toggles
_G.Options = Options

local V2 = Vector2.new
local RGB = Color3.fromRGB
local Black = Color3.new(0, 0, 0)
local White = Color3.new(1, 1, 1)

local Library = {
    FontColor = RGB(255, 255, 255),
    MainColor = RGB(28, 28, 28),
    BackgroundColor = RGB(20, 20, 20),
    AccentColor = RGB(0, 85, 255),
    AccentColorDark = RGB(0, 57, 170),
    OutlineColor = RGB(50, 50, 50),
    RiskColor = RGB(255, 50, 50),
    Black = Black,
    Font = 1,
    TextSize = 15,
    Toggled = false,
    Unloaded = false,
    ToggleKey = "RightShift",
    ScrollBar = true,
    GroupboxSpacing = 8,
    NotifySide = "Left",
    NotifyPosition = nil,
    NotifyTime = 5,
    KeybindFrame = { Visible = false },
    ToggleKeybind = nil,
    Toggles = Toggles,
    Options = Options,
    KeyPickers = {},
    UnloadCallbacks = {},
    Signals = {},
}
pcall(function()
    local f = Drawing.Fonts
    if f then Library.Font = f.Monospace or f.System or f.UI or 1 end
end)
genv.__Linoria = Library

local function clamp(v, a, b) if v < a then return a end if v > b then return b end return v end
local function lerp(a, b, t) return a + (b - a) * t end

local function toHSV(c)
    local r, g, b = c.R, c.G, c.B
    local mx, mn = math.max(r, g, b), math.min(r, g, b)
    local d = mx - mn
    local h, s, v = 0, (mx == 0 and 0 or d / mx), mx
    if d ~= 0 then
        if mx == r then
            h = ((g - b) / d) % 6
        elseif mx == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
    end
    return h, s, v
end
local function fromHSV(h, s, v)
    h = (h % 1) * 6
    local i = math.floor(h)
    local f = h - i
    local p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
    local r, g, b
    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    else
        r, g, b = v, p, q
    end
    return Color3.new(r, g, b)
end
local function toHex(c)
    return string.format("%02x%02x%02x", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function fromHex(s)
    s = tostring(s or ""):gsub("#", "")
    if #s ~= 6 then return nil end
    local r, g, b = tonumber(s:sub(1, 2), 16), tonumber(s:sub(3, 4), 16), tonumber(s:sub(5, 6), 16)
    if not (r and g and b) then return nil end
    return RGB(r, g, b)
end
local function darker(c)
    local h, s, v = toHSV(c)
    return fromHSV(h, s, v / 1.5)
end
local function lerpColor(a, b, t) return Color3.new(lerp(a.R, b.R, t), lerp(a.G, b.G, t), lerp(a.B, b.B, t)) end

Library.GetDarkerColor = function(self, c) return darker(c) end
Library.ToHex = toHex
Library.FromHex = fromHex
Library.FromHSV = fromHSV
Library.ToHSV = toHSV

function Library:SafeCallback(f, ...)
    if not f then return end
    local ok, err = pcall(f, ...)
    if not ok then
        warn("[Linoria] callback error: " .. tostring(err))
        pcall(function() Library:Notify("Callback error: " .. tostring(err), 4) end)
    end
end

function Library:AttemptSave()
    if Library.SaveManager and Library.SaveManager.AutoSave then
        pcall(function() Library.SaveManager:Save(Library.SaveManager.AutoSave) end)
    end
end

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB
end

local VK, VKName = {}, {}
local function addKey(name, vk) VK[name] = vk; if not VKName[vk] then VKName[vk] = name end end
for i = 1, 26 do addKey(string.char(64 + i), 0x40 + i) end
do
    local nums = { "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine" }
    for i = 0, 9 do addKey(nums[i + 1], 0x30 + i); addKey("Keypad" .. nums[i + 1], 0x60 + i) end
end
for i = 1, 12 do addKey("F" .. i, 0x6F + i) end
do
    local list = {
        { "MB1", 0x01 }, { "MB2", 0x02 }, { "MB3", 0x04 }, { "MB4", 0x05 }, { "MB5", 0x06 },
        { "LeftShift", 0xA0 }, { "RightShift", 0xA1 }, { "LeftControl", 0xA2 }, { "RightControl", 0xA3 },
        { "LeftAlt", 0xA4 }, { "RightAlt", 0xA5 }, { "Space", 0x20 }, { "Tab", 0x09 }, { "Return", 0x0D },
        { "Escape", 0x1B }, { "Backspace", 0x08 }, { "CapsLock", 0x14 }, { "Insert", 0x2D }, { "Delete", 0x2E },
        { "Home", 0x24 }, { "End", 0x23 }, { "PageUp", 0x21 }, { "PageDown", 0x22 },
        { "Left", 0x25 }, { "Up", 0x26 }, { "Right", 0x27 }, { "Down", 0x28 },
        { "Semicolon", 0xBA }, { "Equals", 0xBB }, { "Comma", 0xBC }, { "Minus", 0xBD }, { "Period", 0xBE },
        { "Slash", 0xBF }, { "Backquote", 0xC0 }, { "LeftBracket", 0xDB }, { "BackSlash", 0xDC },
        { "RightBracket", 0xDD }, { "Quote", 0xDE }, { "KeypadMultiply", 0x6A }, { "KeypadPlus", 0x6B },
        { "KeypadMinus", 0x6D }, { "KeypadPeriod", 0x6E }, { "KeypadDivide", 0x6F },
    }
    for _, e in ipairs(list) do addKey(e[1], e[2]) end
end
local KeyAlias = { MouseButton1 = "MB1", MouseButton2 = "MB2", MouseButton3 = "MB3", Enter = "Return",
    Esc = "Escape", Ctrl = "LeftControl", Control = "LeftControl", Shift = "LeftShift", Alt = "LeftAlt",
    LeftCtrl = "LeftControl", RightCtrl = "RightControl", Spacebar = "Space" }
local function keyName(v)
    if v == nil then return "None" end
    if type(v) == "number" then return VKName[v] or "None" end
    v = tostring(v)
    local last = v:match("([^%.]+)$") or v
    if VK[last] then return last end
    if KeyAlias[last] then return KeyAlias[last] end
    if #last == 1 and VK[last:upper()] then return last:upper() end
    if last == "None" or last == "Unknown" then return "None" end
    return last
end
local ScanList = {}
for name, vk in pairs(VK) do ScanList[#ScanList + 1] = vk end

local CharMap = {}
for vk = 0x41, 0x5A do CharMap[vk] = { string.char(vk + 32), string.char(vk) } end
do
    local d = { [0x30] = { "0", ")" }, [0x31] = { "1", "!" }, [0x32] = { "2", "@" }, [0x33] = { "3", "#" },
        [0x34] = { "4", "$" }, [0x35] = { "5", "%" }, [0x36] = { "6", "^" }, [0x37] = { "7", "&" },
        [0x38] = { "8", "*" }, [0x39] = { "9", "(" } }
    for vk, m in pairs(d) do CharMap[vk] = m end
    for i = 0, 9 do CharMap[0x60 + i] = { tostring(i), tostring(i) } end
    CharMap[0x20] = { " ", " " }; CharMap[0xBA] = { ";", ":" }; CharMap[0xBB] = { "=", "+" }; CharMap[0xBC] = { ",", "<" }
    CharMap[0xBD] = { "-", "_" }; CharMap[0xBE] = { ".", ">" }; CharMap[0xBF] = { "/", "?" }; CharMap[0xC0] = { "`", "~" }
    CharMap[0xDB] = { "[", "{" }; CharMap[0xDC] = { "\\", "|" }; CharMap[0xDD] = { "]", "}" }; CharMap[0xDE] = { "'", "\"" }
    CharMap[0x6A] = { "*", "*" }; CharMap[0x6B] = { "+", "+" }; CharMap[0x6D] = { "-", "-" }; CharMap[0x6E] = { ".", "." }
    CharMap[0x6F] = { "/", "/" }
end
local CharScan = {}
for vk in pairs(CharMap) do CharScan[#CharScan + 1] = vk end

local function robloxActive()
    if isrbxactive then
        local ok, v = pcall(isrbxactive)
        if ok then return v end
    end
    return true
end
local function rawKey(vk)
    local ok, v = pcall(iskeypressed, vk)
    return ok and v or false
end
local function mouse1() local ok, v = pcall(ismouse1pressed); return ok and v or false end
local mouse2
do
    if ismouse2pressed then
        mouse2 = function() local ok, v = pcall(ismouse2pressed); return ok and v or false end
    else
        mouse2 = function() return rawKey(0x02) end
    end
end

local Cache, Live = {}, {}
local Frame = 0
local Alpha = 1
local function eq(a, b)
    if a == b then return true end
    local ta = typeof(a)
    if ta ~= typeof(b) then return false end
    if ta == "Color3" then return a.R == b.R and a.G == b.G and a.B == b.B end
    if ta == "Vector2" then return a.X == b.X and a.Y == b.Y end
    return false
end
local Seq = 0
local Dead = false
local function Draw(id, kind, props)
    if Dead then return nil end
    Seq = Seq + 1
    props.ZIndex = (props.ZIndex or 1) * 4000 + Seq
    local c = Cache[id]
    if not c then
        c = { Obj = Drawing.new(kind), P = {} }
        Cache[id] = c
    end
    local obj, P = c.Obj, c.P
    for k, v in pairs(props) do
        if not eq(P[k], v) then obj[k] = v; P[k] = v end
    end
    if not P.Visible then obj.Visible = true; P.Visible = true end
    Live[id] = true
    c.T = Frame
    return obj
end
local function cleanup()
    for id in pairs(Live) do
        local c = Cache[id]
        if c and c.T ~= Frame then
            c.Obj.Visible = false; c.P.Visible = false; Live[id] = nil
        end
    end
    if Frame % 300 == 0 then
        for id, c in pairs(Cache) do
            if Frame - (c.T or 0) > 1200 then
                pcall(function() c.Obj:Remove() end)
                Cache[id] = nil; Live[id] = nil
            end
        end
    end
end
local function removeAll()
    for _, c in pairs(Cache) do pcall(function() c.Obj:Remove() end) end
    Cache = {}; Live = {}
end

local function R(id, x, y, w, h, col, z)
    if w <= 0 or h <= 0 then return end
    Draw(id, "Square", { Filled = true, Color = col, Transparency = Alpha, ZIndex = z,
        Position = V2(math.floor(x), math.floor(y)), Size = V2(math.floor(w), math.floor(h)) })
end
local TW
local function T(id, s, x, y, col, z, center)
    s = tostring(s)
    if center then y = y + Library.TextSize / 2 end
    Draw(id, "Text", { Text = s, Size = Library.TextSize, Font = Library.Font, Color = col, Center = center and true or false,
        Outline = true, Transparency = Alpha, ZIndex = z, Position = V2(math.floor(x), math.floor(y)) })
end
local function Tri(id, a, b, c, col, z, filled)
    Draw(id, "Triangle", { Filled = filled ~= false, Color = col, Transparency = Alpha, ZIndex = z,
        PointA = a, PointB = b, PointC = c })
end
local function Box(id, x, y, w, h, fill, border, z)
    R(id .. "o", x, y, w, h, Black, z)
    R(id .. "b", x + 1, y + 1, w - 2, h - 2, border, z)
    R(id .. "f", x + 2, y + 2, w - 4, h - 4, fill, z)
end

local Measure, MW, MWn = nil, {}, 0
local MeasureFont = nil
TW = function(s)
    s = tostring(s)
    if MeasureFont ~= Library.Font then MW = {}; MWn = 0; MeasureFont = Library.Font end
    local w = MW[s]
    if not w then
        local ok, b = pcall(function()
            if not Measure then Measure = Drawing.new("Text"); Measure.Visible = false end
            Measure.Font = Library.Font
            Measure.Size = 13
            Measure.Text = s
            return Measure.TextBounds
        end)
        w = (ok and b and b.X and b.X > 0) and b.X or (#s * 7)
        if MWn > 4000 then MW = {}; MWn = 0 end
        MW[s] = w; MWn = MWn + 1
    end
    return w * Library.TextSize / 13
end
function Library:GetTextBounds(Text) return TW(Text), Library.TextSize end

local function fitText(s, maxW)
    s = tostring(s)
    if TW(s) <= maxW then return s end
    local n = #s
    while n > 0 and TW(s:sub(1, n) .. "...") > maxW do n = n - 1 end
    return s:sub(1, n) .. "..."
end
local function wrapText(s, maxW)
    local lines = {}
    for para in (tostring(s) .. "\n"):gmatch("(.-)\n") do
        local cur = ""
        for word in para:gmatch("%S+") do
            local try = cur == "" and word or (cur .. " " .. word)
            if TW(try) <= maxW or cur == "" then cur = try else lines[#lines + 1] = cur; cur = word end
        end
        lines[#lines + 1] = cur
    end
    return lines
end

local function getViewport()
    local vw, vh = 1920, 1080
    pcall(function()
        local v = workspace.CurrentCamera.ViewportSize
        if v and v.X > 0 then vw, vh = v.X, v.Y end
    end)
    return vw, vh
end

local M = { x = 0, y = 0, down = false, prev = false, click = false, rdown = false, rprev = false, rclick = false }
local S = {
    click = false, rclick = false, canHover = true,
    ov = nil, drag = nil, focus = nil, listen = nil, tip = nil,
    notifs = {}, wmText = "", wmVisible = false, wmPos = { x = 100, y = 11 },
    kbPos = nil, fade = 0, fadeGoal = 0, last = os.clock(), uid = 0,
}
local Windows = {}

local G = { ts = 15, line = 18, box = 23, lab = 18, row = 22, chk = 13, head = 26, title = 27 }
local LastAccent = nil
local function updateMetrics()
    if Library.AccentColor ~= LastAccent then
        LastAccent = Library.AccentColor
        Library.AccentColorDark = darker(Library.AccentColor)
    end
    local t = Library.TextSize
    G.ts = t; G.line = t + 3; G.box = t + 8; G.lab = t + 3; G.row = t + 7
    G.chk = math.max(13, t - 2); G.head = t + 11; G.title = t + 12
end
local function tyc(y, h) return math.floor(y + (h - G.ts) / 2) end
local function inside(x, y, w, h) return M.x >= x and M.x < x + w and M.y >= y and M.y < y + h end
local function hover(x, y, w, h) return S.canHover and inside(x, y, w, h) end
local function clickIn(x, y, w, h)
    if S.click and hover(x, y, w, h) then S.click = false; return true end
    return false
end
local function rclickIn(x, y, w, h)
    if S.rclick and hover(x, y, w, h) then S.rclick = false; return true end
    return false
end
local function newId() S.uid = S.uid + 1; return "e" .. S.uid .. "." end

local Edge = {}
local EdgeFrame = {}
local function keyEdge(vk)
    if EdgeFrame[vk] == Frame then return Edge[vk] == 2 end
    EdgeFrame[vk] = Frame
    local was = Edge[vk]
    local d
    if vk == 1 then
        d = M.down
    elseif vk == 2 then
        d = M.rdown
    else
        d = rawKey(vk)
    end
    if d then
        Edge[vk] = (was == 1 or was == 2) and 1 or 2
    else
        Edge[vk] = 0
    end
    return Edge[vk] == 2
end
local Rep = {}
local function keyRepeat(vk)
    local d = rawKey(vk)
    local r = Rep[vk]
    local now = os.clock()
    if not d then Rep[vk] = nil; return false end
    if not r then Rep[vk] = now + 0.45; return true end
    if now >= r then Rep[vk] = now + 0.035; return true end
    return false
end

local function keyDown(name)
    local vk = VK[name]
    if not vk then return false end
    if not robloxActive() then return false end
    if vk == 1 then return M.down end
    if vk == 2 then return M.rdown end
    return rawKey(vk)
end


local function blur(commit)
    local f = S.focus
    if not f then return end
    S.focus = nil
    if commit and f.onCommit then
        f.onCommit(f.buf, true)
    elseif f.onLost then
        f.onLost(f.buf)
    end
end
local function focusBox(f)
    if S.focus and S.focus ~= f then blur(false) end
    f.caret = #f.buf
    f.frame = Frame
    S.focus = f
end
local function pollText()
    local f = S.focus
    if not f then return end
    if keyEdge(0x0D) then blur(true); return end
    if keyEdge(0x1B) then blur(false); return end
    local shift = rawKey(0x10) or rawKey(0xA0) or rawKey(0xA1)
    local ctrl = rawKey(0x11) or rawKey(0xA2) or rawKey(0xA3)
    local changed = false
    if keyRepeat(0x25) then f.caret = math.max(0, f.caret - 1) end
    if keyRepeat(0x27) then f.caret = math.min(#f.buf, f.caret + 1) end
    if keyEdge(0x24) then f.caret = 0 end
    if keyEdge(0x23) then f.caret = #f.buf end
    if keyRepeat(0x08) and f.caret > 0 then
        if ctrl then
            f.buf = f.buf:sub(f.caret + 1); f.caret = 0
        else
            f.buf = f.buf:sub(1, f.caret - 1) .. f.buf:sub(f.caret + 1); f.caret = f.caret - 1
        end
        changed = true
    end
    if keyRepeat(0x2E) and f.caret < #f.buf then
        f.buf = f.buf:sub(1, f.caret) .. f.buf:sub(f.caret + 2); changed = true
    end
    if not ctrl then
        for _, vk in ipairs(CharScan) do
            if keyRepeat(vk) then
                local m = CharMap[vk]
                local ch = shift and m[2] or m[1]
                local ok = true
                if f.numeric and not ch:match("[%d%.%-]") then ok = false end
                if f.maxLength and #f.buf >= f.maxLength then ok = false end
                if ok then
                    f.buf = f.buf:sub(1, f.caret) .. ch .. f.buf:sub(f.caret + 1)
                    f.caret = f.caret + 1
                    changed = true
                end
            end
        end
    end
    if changed and f.onType then f.onType(f.buf) end
end

local function drawField(id, f, x, y, w, h, text, placeholder, z)
    local focused = S.focus == f
    Box(id, x, y, w, h, Library.MainColor, focused and Library.AccentColor or Library.OutlineColor, z)
    local maxW = w - 10
    if focused then
        local before = f.buf:sub(1, f.caret)
        local shown, off = f.buf, 0
        if TW(before) > maxW then
            local s = 1
            while s < #before and TW(before:sub(s)) > maxW do s = s + 1 end
            shown = f.buf:sub(s); off = s - 1
        end
        local vis = ""
        for i = 1, #shown do
            if TW(shown:sub(1, i)) > maxW then break end
            vis = shown:sub(1, i)
        end
        T(id .. "t", vis, x + 5, tyc(y, h), Library.FontColor, z + 1)
        if (os.clock() % 1) < 0.55 then
            local cx = x + 5 + TW(f.buf:sub(off + 1, f.caret))
            R(id .. "c", cx, y + 4, 1, h - 8, Library.FontColor, z + 2)
        end
    elseif text == "" and placeholder then
        T(id .. "t", fitText(placeholder, maxW), x + 5, tyc(y, h), RGB(190, 190, 190), z + 1)
    else
        T(id .. "t", fitText(text, maxW), x + 5, tyc(y, h), Library.FontColor, z + 1)
    end
    f.rect = { x, y, w, h }
end

local function closeOverlay() S.ov = nil end
local function openOverlay(o) o.frame = Frame; S.ov = o end

local BaseAddons = {}
local BaseGroupbox = {}

local function attachAddons(obj)
    obj.Addons = obj.Addons or {}
    for k, f in pairs(BaseAddons) do obj[k] = f end
end

function BaseAddons:AddColorPicker(Idx, Info)
    Info = Info or {}
    local Default = Info.Default or White
    local CP = {
        Type = "ColorPicker", Idx = Idx, Title = Info.Title or (self.Text) or "Color",
        Transparency = Info.Transparency, Callback = Info.Callback, uid = newId(),
        Value = Default, Hue = 0, Sat = 0, Vib = 0,
    }
    CP.Hue, CP.Sat, CP.Vib = toHSV(Default)
    function CP:SetHSVFromRGB(c) CP.Hue, CP.Sat, CP.Vib = toHSV(c) end
    function CP:Display()
        CP.Value = fromHSV(CP.Hue, CP.Sat, CP.Vib)
        Library:SafeCallback(CP.Callback, CP.Value)
        Library:SafeCallback(CP.Changed, CP.Value)
    end
    function CP:OnChanged(fn) CP.Changed = fn; fn(CP.Value) end
    function CP:SetValue(HSV, Transparency)
        CP.Hue, CP.Sat, CP.Vib = HSV[1], HSV[2], HSV[3]
        if Transparency ~= nil then CP.Transparency = Transparency end
        CP:Display()
    end
    function CP:SetValueRGB(c, Transparency)
        CP.Hue, CP.Sat, CP.Vib = toHSV(c)
        if Transparency ~= nil then CP.Transparency = Transparency end
        CP:Display()
    end
    function CP:Show() openOverlay({ kind = "color", el = CP }) end
    function CP:Hide() if S.ov and S.ov.el == CP then closeOverlay() end end
    CP.hexField = { buf = "", onCommit = function(b) local c = fromHex(b); if c then CP:SetValueRGB(c) end end }
    CP.rgbField = { buf = "", onCommit = function(b)
        local r, g, bl = b:match("(%d+)%D+(%d+)%D+(%d+)")
        r, g, bl = tonumber(r), tonumber(g), tonumber(bl)
        if r and g and bl then CP:SetValueRGB(RGB(clamp(r, 0, 255), clamp(g, 0, 255), clamp(bl, 0, 255))) end
    end }
    CP.Value = fromHSV(CP.Hue, CP.Sat, CP.Vib)
    table.insert(self.Addons, CP)
    Options[Idx] = CP
    return self
end

function BaseAddons:AddKeyPicker(Idx, Info)
    Info = Info or {}
    local parent = self
    local KP = {
        Type = "KeyPicker", Idx = Idx, Value = keyName(Info.Default or "None"), Toggled = false,
        Mode = Info.Mode or "Toggle", Text = Info.Text or parent.Text or "Keybind", NoUI = Info.NoUI,
        Callback = Info.Callback, ChangedCallback = Info.ChangedCallback,
        SyncToggleState = Info.SyncToggleState or false, Modes = Info.Modes or { "Always", "Toggle", "Hold" },
        Parent = parent, uid = newId(),
    }
    if KP.SyncToggleState then KP.Modes = { "Toggle" }; KP.Mode = "Toggle" end
    function KP:GetState()
        if KP.Mode == "Always" then return true end
        if KP.Mode == "Hold" then
            if KP.Value == "None" then return false end
            if S.focus or S.listen then return false end
            return keyDown(KP.Value)
        end
        return KP.Toggled
    end
    function KP:Update() end
    function KP:SetValue(Data)
        KP.Value = keyName(Data[1])
        if Data[2] then KP.Mode = Data[2] end
    end
    function KP:OnClick(fn) KP.Clicked = fn end
    function KP:OnChanged(fn) KP.Changed = fn; fn(KP.Value) end
    function KP:DoClick()
        if parent.Type == "Toggle" and KP.SyncToggleState then parent:SetValue(not parent.Value) end
        Library:SafeCallback(KP.Callback, KP.Toggled)
        Library:SafeCallback(KP.Clicked, KP.Toggled)
    end
    table.insert(self.Addons, KP)
    table.insert(Library.KeyPickers, KP)
    Options[Idx] = KP
    return self
end

local function addonWidth(a)
    if a.Type == "ColorPicker" then return 28 end
    local s = (S.listen == a) and "..." or a.Value
    return math.max(28, math.floor(TW(s)) + 10)
end
local function addonsWidth(el)
    local w = 0
    for _, a in ipairs(el.Addons or {}) do w = w + addonWidth(a) + 4 end
    return w
end
local function drawAddons(el, right, y, z)
    local addons = el.Addons
    if not addons or #addons == 0 then return end
    local x = right - addonsWidth(el) + 4
    for _, a in ipairs(addons) do
        local w = addonWidth(a)
        local id = a.uid
        if a.Type == "ColorPicker" then
            local ch = G.chk + 1
            R(id .. "o", x, y, w, ch, Black, z)
            R(id .. "b", x + 1, y + 1, w - 2, ch - 2, darker(a.Value), z)
            R(id .. "f", x + 2, y + 2, w - 4, ch - 4, a.Value, z)
            a._x, a._y = x, y
            a._shown = Frame
            if clickIn(x, y, w, ch) then
                if S.ov and S.ov.el == a then closeOverlay() elseif S.justClosed ~= a then openOverlay({ kind = "color", el = a }) end
            end
        else
            local s = a.Value
            if S.listen == a then
                local n = math.floor(os.clock() / 0.4) % 3 + 1
                s = string.rep(".", n)
            end
            local kh = G.ts + 4
            local ky = y + math.floor((G.chk - kh) / 2)
            local hov = hover(x, ky, w, kh)
            Box(id, x, ky, w, kh, Library.BackgroundColor, hov and Library.AccentColor or Library.OutlineColor, z)
            T(id .. "t", s, x + w / 2, tyc(ky, kh), Library.FontColor, z + 1, true)
            a._x, a._y, a._w = x, ky, w
            a._shown = Frame
            if clickIn(x, ky, w, kh) then
                S.listen = a; S.listenFrame = Frame
            elseif rclickIn(x, ky, w, kh) then
                openOverlay({ kind = "mode", el = a })
            end
        end
        x = x + w + 4
    end
end

function BaseGroupbox:AddBlank(Size)
    local el = { kind = "blank", Size = Size or 5, uid = newId() }
    table.insert(self.Elements, el)
    return el
end

function BaseGroupbox:AddLabel(Text, DoesWrap)
    local el = { kind = "label", Type = "Label", Text = tostring(Text or ""), Wrap = DoesWrap, uid = newId() }
    attachAddons(el)
    function el:SetText(t) el.Text = tostring(t); el._wrapW = nil end
    table.insert(self.Elements, el)
    return el
end

function BaseGroupbox:AddDivider()
    local el = { kind = "divider", uid = newId() }
    table.insert(self.Elements, el)
    return el
end

local function buttonParams(a, b)
    if type(a) == "table" then
        return { Text = a.Text or "Button", Func = a.Func or a.Callback, DoubleClick = a.DoubleClick, Tooltip = a.Tooltip }
    end
    return { Text = tostring(a or "Button"), Func = b }
end
function BaseGroupbox:AddButton(...)
    local el = buttonParams(...)
    el.kind = "button"; el.Type = "Button"; el.uid = newId(); el.subs = {}
    local function mk(b)
        function b:AddTooltip(t) b.Tooltip = t; return b end
    end
    mk(el)
    function el:AddButton(...)
        local sb = buttonParams(...)
        sb.uid = newId(); mk(sb)
        table.insert(el.subs, sb)
        return sb
    end
    table.insert(self.Elements, el)
    return el
end

function BaseGroupbox:AddInput(Idx, Info)
    Info = Info or {}
    local el = { kind = "input", Type = "Input", Idx = Idx, Text = Info.Text, Value = tostring(Info.Default or ""),
        Numeric = Info.Numeric, Finished = Info.Finished, Placeholder = Info.Placeholder,
        MaxLength = Info.MaxLength, Callback = Info.Callback, Tooltip = Info.Tooltip, uid = newId() }
    function el:SetValue(t)
        t = tostring(t or "")
        if el.MaxLength and #t > el.MaxLength then t = t:sub(1, el.MaxLength) end
        if el.Numeric and t ~= "" and not tonumber(t) and t ~= "-" and t ~= "." then t = el.Value end
        el.Value = t
        if S.focus == el.field then el.field.buf = t end
        Library:SafeCallback(el.Callback, el.Value)
        Library:SafeCallback(el.Changed, el.Value)
    end
    function el:OnChanged(fn) el.Changed = fn; fn(el.Value) end
    el.field = { buf = "", numeric = el.Numeric, maxLength = el.MaxLength,
        onType = function(b) if not el.Finished then el:SetValue(b) end end,
        onCommit = function(b) el:SetValue(b) end,
        onLost = function(b) if not el.Finished then el:SetValue(b) end end }
    table.insert(self.Elements, el)
    Options[Idx] = el
    return el
end
BaseGroupbox.AddTextbox = BaseGroupbox.AddInput

function BaseGroupbox:AddToggle(Idx, Info)
    Info = Info or {}
    local el = { kind = "toggle", Type = "Toggle", Idx = Idx, Text = Info.Text or Idx, Value = Info.Default or false,
        Tooltip = Info.Tooltip, Callback = Info.Callback, Risk = Info.Risk, uid = newId() }
    attachAddons(el)
    function el:UpdateColors() end
    function el:Display() end
    function el:OnChanged(fn) el.Changed = fn; fn(el.Value) end
    function el:SetValue(b)
        b = not not b
        el.Value = b
        for _, a in ipairs(el.Addons) do
            if a.Type == "KeyPicker" and a.SyncToggleState then a.Toggled = b end
        end
        Library:SafeCallback(el.Callback, el.Value)
        Library:SafeCallback(el.Changed, el.Value)
        Library:UpdateDependencyBoxes()
    end
    function el:SetText(t) el.Text = tostring(t) end
    table.insert(self.Elements, el)
    Toggles[Idx] = el
    return el
end

function BaseGroupbox:AddSlider(Idx, Info)
    Info = Info or {}
    local el = { kind = "slider", Type = "Slider", Idx = Idx, Text = Info.Text or Idx, Min = Info.Min or 0,
        Max = Info.Max or 100, Rounding = Info.Rounding or 0, Value = Info.Default or Info.Min or 0,
        Suffix = Info.Suffix or "", Compact = Info.Compact, HideMax = Info.HideMax,
        Tooltip = Info.Tooltip, Callback = Info.Callback, uid = newId() }
    local function round(v)
        if el.Rounding == 0 then return math.floor(v + 0.5) end
        return tonumber(string.format("%." .. el.Rounding .. "f", v))
    end
    function el:UpdateColors() end
    function el:Display() end
    function el:OnChanged(fn) el.Changed = fn; fn(el.Value) end
    function el:SetValue(v)
        local n = tonumber(v)
        if not n then return end
        n = round(clamp(n, el.Min, el.Max))
        el.Value = n
        Library:SafeCallback(el.Callback, el.Value)
        Library:SafeCallback(el.Changed, el.Value)
    end
    function el:SetMin(v) el.Min = v; el:SetValue(el.Value) end
    function el:SetMax(v) el.Max = v; el:SetValue(el.Value) end
    el._round = round
    el.Value = round(clamp(el.Value, el.Min, el.Max))
    table.insert(self.Elements, el)
    Options[Idx] = el
    return el
end

local function GetPlayersString()
    local list = {}
    pcall(function()
        for _, p in ipairs(Players:GetPlayers()) do list[#list + 1] = p.Name end
    end)
    table.sort(list)
    return list
end
local function GetTeamsString()
    local list = {}
    pcall(function()
        for _, t in ipairs(game:GetService("Teams"):GetChildren()) do list[#list + 1] = t.Name end
    end)
    table.sort(list)
    return list
end

function BaseGroupbox:AddDropdown(Idx, Info)
    Info = Info or {}
    local el = { kind = "dropdown", Type = "Dropdown", Idx = Idx, Text = Info.Text, Values = Info.Values or {},
        Multi = Info.Multi, AllowNull = Info.AllowNull, SpecialType = Info.SpecialType, Tooltip = Info.Tooltip,
        Callback = Info.Callback, uid = newId(), scroll = 0 }
    if el.SpecialType == "Player" then
        el.Values = GetPlayersString(); el.AllowNull = true
    elseif el.SpecialType == "Team" then
        el.Values = GetTeamsString(); el.AllowNull = true
    end
    el.Value = el.Multi and {} or nil
    local function has(v) for _, x in ipairs(el.Values) do if x == v then return true end end return false end
    local def = Info.Default
    if type(def) == "table" and el.Multi then
        for _, v in ipairs(def) do if has(v) then el.Value[v] = true end end
    else
        if type(def) == "string" then
            for i, v in ipairs(el.Values) do if v == def then def = i; break end end
        end
        if type(def) == "number" and el.Values[def] then
            if el.Multi then el.Value[el.Values[def]] = true else el.Value = el.Values[def] end
        end
    end
    function el:GetActiveValues()
        if el.Multi then
            local n = 0
            for _ in pairs(el.Value) do n = n + 1 end
            return n
        end
        return el.Value and 1 or 0
    end
    function el:Display() end
    function el:BuildDropdownList() end
    function el:OnChanged(fn) el.Changed = fn; fn(el.Value) end
    function el:SetValues(vals)
        if vals then el.Values = vals end
        if el.Multi then
            local nv = {}
            for k, on in pairs(el.Value) do if on and has(k) then nv[k] = true end end
            el.Value = nv
        elseif el.Value ~= nil and not has(el.Value) then
            el.Value = nil
        end
    end
    function el:SetValue(v)
        if el.Multi then
            local nv = {}
            for k, on in pairs(type(v) == "table" and v or {}) do
                if type(k) == "number" then
                    if has(on) then nv[on] = true end
                elseif on and has(k) then
                    nv[k] = true
                end
            end
            el.Value = nv
        else
            if v == nil or has(v) then el.Value = v end
        end
        Library:SafeCallback(el.Callback, el.Value)
        Library:SafeCallback(el.Changed, el.Value)
        Library:UpdateDependencyBoxes()
    end
    function el:OpenDropdown() openOverlay({ kind = "dropdown", el = el }) end
    function el:CloseDropdown() if S.ov and S.ov.el == el then closeOverlay() end end
    function el:Refresh()
        if el.SpecialType == "Player" then
            el:SetValues(GetPlayersString())
        elseif el.SpecialType == "Team" then
            el:SetValues(GetTeamsString())
        end
    end
    table.insert(self.Elements, el)
    Options[Idx] = el
    return el
end

local DependencyBoxes = {}
function BaseGroupbox:AddDependencyBox()
    local parent = self
    local box = { kind = "depbox", Elements = {}, Dependencies = {}, uid = newId(), Parent = parent }
    for k, f in pairs(BaseGroupbox) do box[k] = f end
    function box:SetupDependencies(deps) box.Dependencies = deps or {}; Library:UpdateDependencyBoxes() end
    function box:Update() end
    function box:Resize() end
    function box:IsVisible()
        for _, d in ipairs(box.Dependencies) do
            local elem, want = d[1], d[2]
            if elem then
                if elem.Type == "Toggle" then
                    if elem.Value ~= want then return false end
                elseif elem.Type == "Dropdown" then
                    if elem.Multi then
                        if not elem.Value[want] then return false end
                    elseif elem.Value ~= want then
                        return false
                    end
                elseif elem.Value ~= want then
                    return false
                end
            end
        end
        if parent.kind == "depbox" then return parent:IsVisible() end
        return true
    end
    table.insert(self.Elements, box)
    table.insert(DependencyBoxes, box)
    return box
end
function Library:UpdateDependencyBoxes() end

local function labelLines(el, w)
    if el._wrapW ~= w or el._wrapSrc ~= el.Text then
        if el.Wrap then
            el._lines = wrapText(el.Text, w)
        else
            local ls = {}
            for l in (el.Text .. "\n"):gmatch("(.-)\n") do ls[#ls + 1] = l end
            el._lines = ls
        end
        el._wrapW = w; el._wrapSrc = el.Text
    end
    return el._lines
end
local function elHeight(el, w)
    local k = el.kind
    if el.Visible == false then return 0 end
    if k == "toggle" then
        return G.row
    elseif k == "label" then
        return #labelLines(el, w - addonsWidth(el)) * G.line + 5
    elseif k == "button" then
        return G.box + 5
    elseif k == "divider" then
        return 16
    elseif k == "slider" then
        return el.Compact and 19 or (G.lab + 19)
    elseif k == "dropdown" or k == "input" then
        return (el.Text and G.lab or 0) + G.box + 5
    elseif k == "blank" then
        return el.Size
    elseif k == "depbox" then
        if not el:IsVisible() then return 0 end
        local h = 0
        for _, c in ipairs(el.Elements) do h = h + elHeight(c, w) end
        return h
    end
    return 0
end

local function sliderText(el)
    local v = tostring(el.Value) .. el.Suffix
    if el.Compact then return el.Text .. ": " .. v end
    if el.HideMax then return v end
    return v .. "/" .. tostring(el.Max) .. el.Suffix
end

local function dropdownText(el)
    if el.Multi then
        local list = {}
        for _, v in ipairs(el.Values) do if el.Value[v] then list[#list + 1] = v end end
        if #list == 0 then return "--" end
        return table.concat(list, ", ")
    end
    return el.Value and tostring(el.Value) or "--"
end

local drawElements
local function drawEl(el, x, y, w, vt, vb, z)
    local k = el.kind
    local h = elHeight(el, w)
    if h == 0 then return 0 end
    if k == "depbox" then
        drawElements(el.Elements, x, y, w, vt, vb, z)
        return h
    end
    if k == "label" then
        local lines = labelLines(el, w - addonsWidth(el))
        for i, l in ipairs(lines) do
            local ly = y + (i - 1) * G.line
            if ly >= vt and ly + G.ts <= vb then
                T(el.uid .. "t" .. i, l, x, ly, Library.FontColor, z)
            end
        end
        if y >= vt and y + G.chk <= vb then
            drawAddons(el, x + w, y + math.floor((G.ts - G.chk) / 2), z)
        end
        return h
    end
    if y < vt or y + h - 4 > vb then return h end
    local id = el.uid
    local F = Library.FontColor
    if k == "toggle" then
        local aw = addonsWidth(el)
        local c = G.chk
        local hw = math.min(w - aw, c + 6 + TW(el.Text) + 4)
        local hov = hover(x, y, hw, c + 1)
        local border = hov and Library.AccentColor or (el.Value and Library.AccentColorDark or Library.OutlineColor)
        R(id .. "o", x, y, c, c, Black, z)
        R(id .. "b", x + 1, y + 1, c - 2, c - 2, border, z)
        R(id .. "f", x + 2, y + 2, c - 4, c - 4, el.Value and Library.AccentColor or Library.MainColor, z)
        T(id .. "t", el.Text, x + c + 6, tyc(y, c), el.Risk and Library.RiskColor or F, z)
        if hov and el.Tooltip then S.tip = el.Tooltip end
        drawAddons(el, x + w, y, z)
        if clickIn(x, y, hw, c + 1) then el:SetValue(not el.Value); Library:AttemptSave() end
    elseif k == "label" then
        local lines = labelLines(el, w - addonsWidth(el))
        for i, l in ipairs(lines) do T(id .. "t" .. i, l, x, y + (i - 1) * G.line, F, z) end
        drawAddons(el, x + w, y + math.floor((G.ts - G.chk) / 2), z)
    elseif k == "button" then
        local n = 1 + #el.subs
        local bw = math.floor((w - 4 * (n - 1)) / n)
        local list = { el }
        for _, s in ipairs(el.subs) do list[#list + 1] = s end
        for i, b in ipairs(list) do
            local bx = x + (i - 1) * (bw + 4)
            local hov = hover(bx, y, bw, G.box)
            Box(b.uid, bx, y, bw, G.box, Library.MainColor, hov and Library.AccentColor or Library.OutlineColor, z)
            local txt = b.Text
            if b._armed and os.clock() - b._armed < 0.5 then txt = "Are you sure?" else b._armed = nil end
            T(b.uid .. "t", fitText(txt, bw - 6), bx + bw / 2, tyc(y, G.box), b._armed and Library.AccentColor or F, z + 1, true)
            if hov and b.Tooltip then S.tip = b.Tooltip end
            if clickIn(bx, y, bw, G.box) then
                if b.DoubleClick and not b._armed then
                    b._armed = os.clock()
                else
                    b._armed = nil
                    Library:SafeCallback(b.Func)
                end
            end
        end
    elseif k == "divider" then
        R(id .. "o", x, y + 4, w, 5, Black, z)
        R(id .. "b", x + 1, y + 5, w - 2, 3, Library.OutlineColor, z)
        R(id .. "f", x + 2, y + 6, w - 4, 1, Library.MainColor, z)
    elseif k == "slider" then
        local by = y
        if not el.Compact then
            T(id .. "l", el.Text, x, y, F, z)
            by = y + G.lab
        end
        local hov = hover(x, by, w, 14)
        if hov and el.Tooltip then S.tip = el.Tooltip end
        R(id .. "o", x, by, w, 14, Black, z)
        R(id .. "b", x + 1, by + 1, w - 2, 12, hov and Library.AccentColor or Library.OutlineColor, z)
        R(id .. "f", x + 2, by + 2, w - 4, 10, Library.MainColor, z)
        local pct = (el.Max > el.Min) and (el.Value - el.Min) / (el.Max - el.Min) or 0
        local fw = math.floor((w - 4) * clamp(pct, 0, 1))
        if fw > 0 then
            R(id .. "e", x + 2, by + 2, fw, 10, Library.AccentColorDark, z)
            if fw > 2 then R(id .. "a", x + 3, by + 3, fw - 2, 8, Library.AccentColor, z) end
        end
        T(id .. "t", sliderText(el), x + w / 2, tyc(by, 14), F, z + 1, true)
        el._bx, el._bw = x + 2, w - 4
        if clickIn(x, by, w, 14) then S.drag = { kind = "slider", el = el } end
    elseif k == "dropdown" or k == "input" then
        local by = y
        if el.Text then
            T(id .. "l", el.Text, x, y, F, z)
            by = y + G.lab
        end
        local bh = G.box
        local hov = hover(x, by, w, bh)
        if hov and el.Tooltip then S.tip = el.Tooltip end
        if k == "dropdown" then
            local open = S.ov and S.ov.el == el
            Box(id, x, by, w, bh, Library.MainColor, (hov or open) and Library.AccentColor or Library.OutlineColor, z)
            T(id .. "t", fitText(dropdownText(el), w - 24), x + 5, tyc(by, bh), F, z + 1)
            local ax, ay = x + w - 13, by + math.floor(bh / 2) - 2
            Tri(id .. "ar", V2(ax, ay), V2(ax + 7, ay), V2(ax + 3.5, ay + 4), F, z + 1)
            el._bx, el._by, el._bw = x, by, w
            el._shown = Frame
            if clickIn(x, by, w, bh) then
                if open then closeOverlay() elseif S.justClosed ~= el then el:Refresh(); openOverlay({ kind = "dropdown", el = el }) end
            end
        else
            local f = el.field
            drawField(id, f, x, by, w, bh, el.Value, el.Placeholder, z)
            if clickIn(x, by, w, bh) and S.focus ~= f then f.buf = el.Value; focusBox(f) end
        end
    end
    return h
end
drawElements = function(list, x, y, w, vt, vb, z)
    local cy = y
    for _, el in ipairs(list) do
        cy = cy + drawEl(el, x, cy, w, vt, vb, z)
    end
    return cy - y
end
local function listHeight(list, w)
    local h = 0
    for _, el in ipairs(list) do h = h + elHeight(el, w) end
    return h
end

local function RC(id, x, y, w, h, col, z, vt, vb)
    local y2 = math.min(y + h, vb)
    local y1 = math.max(y, vt)
    if y2 <= y1 then return end
    R(id, x, y1, w, y2 - y1, col, z)
end

local function boxHeight(b, w)
    if b.kind == "tabbox" then
        local t = b.Tabs[b.Active]
        return G.head + (t and listHeight(t.Elements, w - 10) or 0)
    end
    return G.head + listHeight(b.Elements, w - 10)
end

local function drawBox(b, x, y, w, vt, vb, z)
    local h = boxHeight(b, w)
    local id = b.uid
    RC(id .. "o", x, y, w, h, Black, z, vt, vb)
    RC(id .. "b", x + 1, y + 1, w - 2, h - 2, Library.OutlineColor, z, vt, vb)
    RC(id .. "f", x + 2, y + 2, w - 4, h - 4, Library.BackgroundColor, z, vt, vb)
    if b.kind == "tabbox" then
        local n = #b.Tabs
        if y >= vt and y + G.head - 4 <= vb then R(id .. "ac", x + 2, y + 2, w - 4, 2, Library.AccentColor, z + 2) end
        if n > 0 and y >= vt and y + G.head - 4 <= vb then
            local tw = (w - 4) / n
            for i, t in ipairs(b.Tabs) do
                local tx = x + 2 + math.floor((i - 1) * tw)
                local tww = math.floor(i * tw) - math.floor((i - 1) * tw)
                local active = b.Active == i
                local hh = G.head - 6
                R(t.uid .. "bg", tx, y + 2, tww, hh, active and Library.BackgroundColor or Library.MainColor, z)
                if not active then R(t.uid .. "ln", tx, y + 2 + hh, tww, 1, Black, z + 1) end
                if i > 1 then R(t.uid .. "sp", tx, y + 2, 1, active and hh or hh + 1, Black, z + 1) end
                T(t.uid .. "t", fitText(t.Name, tww - 4), tx + tww / 2, tyc(y + 4, hh - 2), Library.FontColor, z + 1, true)
                if clickIn(tx, y + 2, tww, hh) then b.Active = i end
            end
        end
        local t = b.Tabs[b.Active]
        if t then drawElements(t.Elements, x + 5, y + G.head, w - 10, vt, vb, z + 1) end
    else
        if y >= vt and y + G.head - 4 <= vb then
            R(id .. "ac", x + 2, y + 2, w - 4, 2, Library.AccentColor, z + 1)
            T(id .. "t", b.Name, x + 6, tyc(y + 4, G.head - 8), Library.FontColor, z + 1)
        end
        drawElements(b.Elements, x + 5, y + G.head, w - 10, vt, vb, z + 1)
    end
    return h
end

function Library:CreateWindow(...)
    local args = { ... }
    local Config = {}
    if type(args[1]) == "table" then Config = args[1] else Config.Title = args[1]; Config.AutoShow = args[2] end
    if type(Config.Title) ~= "string" then Config.Title = "No title" end
    if type(Config.TabPadding) ~= "number" then Config.TabPadding = 0 end
    if type(Config.MenuFadeTime) ~= "number" then Config.MenuFadeTime = 0.2 end
    local W, H = 550, 600
    if type(Config.Size) == "table" then
        W, H = Config.Size[1] or W, Config.Size[2] or H
    elseif typeof(Config.Size) == "Vector2" then
        W, H = Config.Size.X, Config.Size.Y
    elseif typeof(Config.Size) == "UDim2" then
        W, H = Config.Size.X.Offset, Config.Size.Y.Offset
    end
    local X, Y = 175, 50
    if type(Config.Position) == "table" then
        X, Y = Config.Position[1] or X, Config.Position[2] or Y
    elseif typeof(Config.Position) == "Vector2" then
        X, Y = Config.Position.X, Config.Position.Y
    elseif typeof(Config.Position) == "UDim2" then
        X, Y = Config.Position.X.Offset, Config.Position.Y.Offset
    end
    if Config.Center then
        local vw, vh = getViewport()
        X, Y = math.floor((vw - W) / 2), math.floor((vh - H) / 2)
    end
    local Window = { Title = Config.Title, X = X, Y = Y, W = W, H = H, Tabs = {}, TabList = {}, Active = nil,
        TabPadding = Config.TabPadding, uid = newId() }
    Library.MenuFadeTime = Config.MenuFadeTime
    if Config.Theme then Library:SetTheme(Config.Theme) end
    if Config.Font or Config.TextSize then Library:SetFont(Config.Font, Config.TextSize) end
    if Config.ToggleKey then Library.ToggleKey = Config.ToggleKey end
    function Window:SetWindowTitle(t) Window.Title = tostring(t) end
    function Window:SetSize(w, h) Window.W = w; Window.H = h end
    function Window:SetPosition(x, y) Window.X = x; Window.Y = y end
    function Window:Center()
        local vw, vh = getViewport()
        Window.X, Window.Y = math.floor((vw - Window.W) / 2), math.floor((vh - Window.H) / 2)
    end
    function Window:SelectTab(name)
        local t = Window.Tabs[name]
        if t then Window.Active = t end
    end
    function Window:AddTab(Name)
        local Tab = { Name = Name, Window = Window, Boxes = { {}, {} }, Scroll = { 0, 0 }, uid = newId() }
        function Tab:ShowTab() Window.Active = Tab end
        function Tab:HideTab() end
        function Tab:SetLayoutOrder() end
        function Tab:AddGroupbox(Info)
            local Groupbox = { kind = "group", Name = Info.Name or "", Elements = {}, uid = newId(), Tab = Tab }
            for k, f in pairs(BaseGroupbox) do Groupbox[k] = f end
            function Groupbox:Resize() end
            table.insert(Tab.Boxes[Info.Side == 2 and 2 or 1], Groupbox)
            return Groupbox
        end
        function Tab:AddLeftGroupbox(Name) return Tab:AddGroupbox({ Side = 1, Name = Name }) end
        function Tab:AddRightGroupbox(Name) return Tab:AddGroupbox({ Side = 2, Name = Name }) end
        function Tab:AddTabbox(Info)
            local Tabbox = { kind = "tabbox", Name = Info.Name, Tabs = {}, Active = 1, uid = newId() }
            function Tabbox:AddTab(TName)
                local sub = { Name = TName, Elements = {}, uid = newId(), kind = "group" }
                for k, f in pairs(BaseGroupbox) do sub[k] = f end
                function sub:Show() for i, t in ipairs(Tabbox.Tabs) do if t == sub then Tabbox.Active = i end end end
                function sub:Hide() end
                function sub:Resize() end
                table.insert(Tabbox.Tabs, sub)
                return sub
            end
            table.insert(Tab.Boxes[Info.Side == 2 and 2 or 1], Tabbox)
            return Tabbox
        end
        function Tab:AddLeftTabbox(Name) return Tab:AddTabbox({ Name = Name, Side = 1 }) end
        function Tab:AddRightTabbox(Name) return Tab:AddTabbox({ Name = Name, Side = 2 }) end
        Window.Tabs[Name] = Tab
        table.insert(Window.TabList, Tab)
        if not Window.Active then Window.Active = Tab end
        return Tab
    end
    table.insert(Windows, Window)
    if Config.AutoShow then
        Library.Toggled = true; S.fadeGoal = 1; S.fade = 0
    end
    return Window
end

function Library:Toggle()
    Library.Toggled = not Library.Toggled
    S.fadeGoal = Library.Toggled and 1 or 0
    if not Library.Toggled then
        closeOverlay(); blur(false); S.listen = nil; S.drag = nil
    end
end

local function drawWindow(Win)
    local x, y, w, h = Win.X, Win.Y, Win.W, Win.H
    local id = Win.uid
    local z = 2
    R(id .. "o", x, y, w, h, Black, z)
    R(id .. "a", x + 1, y + 1, w - 2, h - 2, Library.AccentColor, z)
    R(id .. "m", x + 2, y + 2, w - 4, h - 4, Library.MainColor, z)
    T(id .. "t", Win.Title, x + 7, tyc(y + 1, G.title - 2), Library.FontColor, z + 1)

    if S.click and hover(x, y, w, G.title) then
        S.click = false
        S.drag = { kind = "win", win = Win, ox = M.x - x, oy = M.y - y }
    end

    local cx, cy, cw, ch = x + 8, y + G.title, w - 16, h - G.title - 8
    R(id .. "co", cx, cy, cw, ch, Library.OutlineColor, z)
    R(id .. "cb", cx + 1, cy + 1, cw - 2, ch - 2, Black, z)
    R(id .. "cf", cx + 2, cy + 2, cw - 4, ch - 4, Library.BackgroundColor, z)

    local tbh = G.ts + 9
    local tx, ty, tw, th = cx + 8, cy + 8 + tbh, cw - 16, ch - 16 - tbh
    R(id .. "tb", tx, ty, tw, th, Library.OutlineColor, z + 1)
    R(id .. "tf", tx + 1, ty + 1, tw - 2, th - 2, Library.MainColor, z + 1)

    local bx = cx + 8
    for _, Tab in ipairs(Win.TabList) do
        local bw = math.floor(TW(Tab.Name)) + 14
        local active = Win.Active == Tab
        local ry = cy + 8
        R(Tab.uid .. "bb", bx, ry, bw, tbh + 1, Library.OutlineColor, z + 2)
        R(Tab.uid .. "bf", bx + 1, ry + 1, bw - 2, active and tbh or tbh - 1, active and Library.MainColor or Library.BackgroundColor, z + 2)
        T(Tab.uid .. "bt", Tab.Name, bx + bw / 2, tyc(ry + 1, tbh - 1), Library.FontColor, z + 3, true)
        if clickIn(bx, cy + 8, bw, tbh + 1) then
            Win.Active = Tab
            closeOverlay()
        end
        bx = bx + bw - 1 + Win.TabPadding
    end

    local Tab = Win.Active
    if not Tab then return end
    local colW = math.floor((tw - 4 - 24) / 2)
    local vt, vb = ty + 8, ty + th - 8
    for side = 1, 2 do
        local colX = (side == 1) and (tx + 8) or (tx + 8 + colW + 8)
        local total = 0
        local gap = Library.GroupboxSpacing
        for _, b in ipairs(Tab.Boxes[side]) do total = total + boxHeight(b, colW) + gap end
        total = math.max(0, total - gap)
        local viewH = vb - vt
        local maxScroll = math.max(0, total - viewH)
        Tab.Scroll[side] = clamp(Tab.Scroll[side], 0, maxScroll)
        if maxScroll > 0 and Library.ScrollBar then
            local trackX = colX + colW + 2
            local thumbH = math.max(20, viewH * viewH / total)
            local thumbY = vt + (Tab.Scroll[side] / maxScroll) * (viewH - thumbH)
            R(id .. "st" .. side, trackX + 1, vt, 2, viewH, Library.BackgroundColor, z + 3)
            R(id .. "sb" .. side, trackX + 1, thumbY, 2, thumbH, Library.AccentColor, z + 3)
            if clickIn(trackX - 2, vt, 7, viewH) then
                S.drag = { kind = "scroll", tab = Tab, side = side, vt = vt, viewH = viewH, thumbH = thumbH, max = maxScroll }
            end
        end
        local yy = vt - Tab.Scroll[side]
        for _, b in ipairs(Tab.Boxes[side]) do
            local bh = drawBox(b, colX, yy, colW, vt, vb, z + 3)
            yy = yy + bh + gap
        end
    end
end

local function drawOverlay()
    local o = S.ov
    if not o then return end
    local el = o.el
    local z = 40
    local F = Library.FontColor
    if el._shown ~= Frame and el._shown ~= Frame - 1 then
        if o.frame ~= Frame then closeOverlay(); return end
    end
    if o.kind == "dropdown" then
        local rows = math.min(8, #el.Values)
        local rh = G.box - 2
        local x, y, w = el._bx, el._by + G.box, el._bw
        local h = rows * rh + 2
        if rows == 0 then h = rh + 2 end
        o.rect = { x, y, w, h }
        Box("ov.dd", x, y, w, h, Library.MainColor, Library.OutlineColor, z)
        local maxScroll = math.max(0, #el.Values - rows)
        el.scroll = clamp(el.scroll, 0, maxScroll)
        for i = 1, rows do
            local v = el.Values[i + el.scroll]
            local ry = y + 1 + (i - 1) * rh
            local sel
            if el.Multi then sel = el.Value[v] else sel = el.Value == v end
            local hov = inside(x + 1, ry, w - 2, rh)
            if hov then R("ov.ddh" .. i, x + 2, ry, w - 4, rh, Library.BackgroundColor, z + 1) end
            if i > 1 then R("ov.ddl" .. i, x + 2, ry, w - 4, 1, Library.OutlineColor, z + 1) end
            T("ov.ddt" .. i, fitText(tostring(v), w - 14), x + 6, tyc(ry, rh), sel and Library.AccentColor or F, z + 2)
            if S.click and hov then
                S.click = false
                if el.Multi then
                    local nv = {}
                    for k2, on in pairs(el.Value) do nv[k2] = on end
                    if nv[v] then nv[v] = nil else nv[v] = true end
                    el:SetValue(nv)
                else
                    if sel then
                        if el.AllowNull then el:SetValue(nil) end
                    else
                        el:SetValue(v)
                    end
                    closeOverlay()
                end
                Library:AttemptSave()
            end
        end
        if rows == 0 then T("ov.dde", "--", x + 6, tyc(y, rh), F, z + 2) end
        if maxScroll > 0 then
            local trackH = h - 4
            local thumbH = math.max(12, trackH * rows / #el.Values)
            local thumbY = y + 2 + (el.scroll / maxScroll) * (trackH - thumbH)
            R("ov.ddsb", x + w - 5, thumbY, 3, thumbH, Library.AccentColor, z + 3)
            if S.click and inside(x + w - 8, y, 8, h) then
                S.click = false
                S.drag = { kind = "ddscroll", el = el, y = y + 2, trackH = trackH, thumbH = thumbH, max = maxScroll }
            end
        end
    elseif o.kind == "mode" then
        local x, y = el._x + el._w + 4, el._y
        local mh = G.ts + 3
        local w, h = 66, #el.Modes * mh + 4
        o.rect = { x, y, w, h }
        Box("ov.md", x, y, w, h, Library.BackgroundColor, Library.OutlineColor, z)
        for i, m in ipairs(el.Modes) do
            local ry = y + 2 + (i - 1) * mh
            T("ov.mdt" .. i, m, x + w / 2, ry, el.Mode == m and Library.AccentColor or F, z + 1, true)
            if S.click and inside(x, ry, w, mh) then
                S.click = false
                el.Mode = m
                closeOverlay()
                Library:AttemptSave()
            end
        end
    elseif o.kind == "color" then
        local vw, vh = getViewport()
        local hasA = el.Transparency ~= nil
        local w, h = 230, (hasA and 277 or 259) + (G.box - 20)
        local x, y = el._x, el._y + 18
        if x + w > vw then x = vw - w - 4 end
        if y + h > vh then y = el._y - h - 4 end
        o.rect = { x, y, w, h }
        Box("ov.cp", x, y, w, h, Library.BackgroundColor, Library.OutlineColor, z)
        R("ov.cpa", x + 2, y + 2, w - 4, 2, Library.AccentColor, z + 1)
        T("ov.cpt", fitText(el.Title, w - 12), x + 6, tyc(y + 4, 20), F, z + 1)
        local sx, sy, ss = x + 6, y + 27, 200
        R("ov.svo", sx - 1, sy - 1, ss + 2, ss + 2, Black, z + 1)
        R("ov.svbase", sx, sy, ss, ss, fromHSV(el.Hue, 1, 1), z + 2)
        local saveA = Alpha
        for i = 0, ss - 1 do
            Alpha = saveA * (1 - (i + 0.5) / ss)
            R("ov.svw" .. i, sx + i, sy, 1, ss, White, z + 2)
        end
        for j = 0, ss - 1 do
            Alpha = saveA * ((j + 0.5) / ss)
            R("ov.svb" .. j, sx, sy + j, ss, 1, Black, z + 2)
        end
        Alpha = saveA
        local cxp = sx + el.Sat * ss
        local cyp = sy + (1 - el.Vib) * ss
        R("ov.svc", cxp - 3, cyp - 3, 6, 6, Black, z + 3)
        R("ov.svc2", cxp - 2, cyp - 2, 4, 4, White, z + 4)
        local hx, hy, hw = sx + ss + 6, sy, 15
        R("ov.huo", hx - 1, hy - 1, hw + 2, ss + 2, Black, z + 1)
        for k = 0, ss - 1 do
            R("ov.hu" .. k, hx, hy + k, hw, 1, fromHSV((k + 0.5) / ss, 1, 1), z + 2)
        end
        R("ov.huc", hx - 1, hy + el.Hue * ss - 1, hw + 2, 3, White, z + 3)
        local fy = sy + ss + 4
        local fw = math.floor((w - 16) / 2)
        if S.focus ~= el.hexField then el.hexField.buf = "#" .. toHex(el.Value) end
        if S.focus ~= el.rgbField then
            el.rgbField.buf = string.format("%d, %d, %d", math.floor(el.Value.R * 255 + 0.5), math.floor(el.Value.G * 255 + 0.5), math.floor(el.Value.B * 255 + 0.5))
        end
        drawField("ov.hex", el.hexField, sx, fy, fw, G.box, el.hexField.buf, nil, z + 1)
        drawField("ov.rgb", el.rgbField, sx + fw + 4, fy, fw, G.box, el.rgbField.buf, nil, z + 1)
        if S.click and inside(sx, fy, fw, G.box) then S.click = false; focusBox(el.hexField) end
        if S.click and inside(sx + fw + 4, fy, fw, G.box) then S.click = false; focusBox(el.rgbField) end
        local ay = fy + G.box + 4
        if hasA then
            local aw = w - 12
            R("ov.alo", sx - 1, ay - 1, aw + 2, 16, Black, z + 1)
            for k = 0, aw - 1 do
                R("ov.al" .. k, sx + k, ay, 1, 14, lerpColor(Library.BackgroundColor, el.Value, (k + 0.5) / aw), z + 2)
            end
            R("ov.alc", sx + (1 - el.Transparency) * aw - 1, ay - 1, 3, 16, White, z + 3)
            o.alpha = { sx, ay, aw }
        end
        o.sv = { sx, sy, ss }
        o.hue = { hx, hy, ss }
        if S.click then
            if inside(sx, sy, ss, ss) then
                S.click = false; S.drag = { kind = "sv", el = el, o = o }
            elseif inside(hx, hy, hw, ss) then
                S.click = false; S.drag = { kind = "hue", el = el, o = o }
            elseif hasA and inside(sx, ay, w - 12, 14) then
                S.click = false; S.drag = { kind = "alpha", el = el, o = o }
            end
        end
    end
end

local function processDrag()
    local d = S.drag
    if not d then return end
    if not M.down then S.drag = nil; Library:AttemptSave(); return end
    if d.kind == "win" then
        d.win.X = M.x - d.ox; d.win.Y = M.y - d.oy
    elseif d.kind == "wm" then
        S.wmPos.x = M.x - d.ox; S.wmPos.y = M.y - d.oy
    elseif d.kind == "kb" then
        S.kbPos = { x = M.x - d.ox, y = M.y - d.oy }
    elseif d.kind == "slider" then
        local el = d.el
        if el._bx then
            local p = clamp((M.x - el._bx) / math.max(1, el._bw), 0, 1)
            local v = el._round(el.Min + (el.Max - el.Min) * p)
            if v ~= el.Value then el:SetValue(v) end
        end
    elseif d.kind == "scroll" then
        local f = clamp((M.y - d.vt - d.thumbH / 2) / math.max(1, d.viewH - d.thumbH), 0, 1)
        d.tab.Scroll[d.side] = f * d.max
    elseif d.kind == "ddscroll" then
        local f = clamp((M.y - d.y - d.thumbH / 2) / math.max(1, d.trackH - d.thumbH), 0, 1)
        d.el.scroll = math.floor(f * d.max + 0.5)
    elseif d.kind == "sv" then
        local r = d.o.sv
        local s = clamp((M.x - r[1]) / r[3], 0, 1)
        local v = 1 - clamp((M.y - r[2]) / r[3], 0, 1)
        if s ~= d.el.Sat or v ~= d.el.Vib then d.el.Sat = s; d.el.Vib = v; d.el:Display() end
    elseif d.kind == "hue" then
        local r = d.o.hue
        local hh = clamp((M.y - r[2]) / r[3], 0, 0.999)
        if hh ~= d.el.Hue then d.el.Hue = hh; d.el:Display() end
    elseif d.kind == "alpha" then
        local r = d.o.alpha
        if r then
            local t = 1 - clamp((M.x - r[1]) / r[3], 0, 1)
            if t ~= d.el.Transparency then d.el.Transparency = t; d.el:Display() end
        end
    end
end

function Library:SetWatermarkVisibility(b) S.wmVisible = b and true or false end
function Library:SetWatermark(t) S.wmText = tostring(t) end
function Library:Notify(Text, Time)
    table.insert(S.notifs, { text = tostring(Text), t0 = os.clock(), dur = Time or Library.NotifyTime, uid = newId() })
end
function Library:SetWatermarkPosition(x, y) S.wmPos = { x = x, y = y } end
function Library:SetKeybindFramePosition(x, y) S.kbPos = { x = x, y = y } end
function Library:SetKeybindFrameVisibility(b) Library.KeybindFrame.Visible = b and true or false end
function Library:SetNotifyPosition(x, y, side)
    Library.NotifyPosition = { x = x, y = y }
    if side then Library.NotifySide = side end
end
function Library:SetTheme(t)
    for _, k in ipairs({ "FontColor", "MainColor", "BackgroundColor", "AccentColor", "OutlineColor", "RiskColor" }) do
        if t[k] then
            local c = t[k]
            if type(c) == "string" then c = fromHex(c) end
            if c then
                Library[k] = c
                if Options[k] and Options[k].Type == "ColorPicker" then Options[k]:SetValueRGB(c) end
            end
        end
    end
end
function Library:SetFont(font, size)
    if type(font) == "string" then
        local ok, f = pcall(function() return Drawing.Fonts[font] end)
        if ok and f then font = f else font = nil end
    end
    if font ~= nil then Library.Font = font end
    if size then Library.TextSize = size end
end
function Library:UpdateColorsUsingRegistry() end

local function drawHud()
    Alpha = 1
    local F = Library.FontColor
    if S.wmVisible and S.wmText ~= "" then
        local x, y = S.wmPos.x, S.wmPos.y
        local w, h = math.floor(TW(S.wmText)) + 14, G.ts + 9
        R("wm.o", x, y, w, h, Black, 60)
        R("wm.a", x + 1, y + 1, w - 2, h - 2, Library.AccentColor, 60)
        R("wm.f", x + 2, y + 2, w - 4, h - 4, Library.MainColor, 60)
        T("wm.t", S.wmText, x + 7, tyc(y, h), F, 61)
        if Library.Toggled and S.click and inside(x, y, w, h) then
            S.click = false
            S.drag = { kind = "wm", ox = M.x - x, oy = M.y - y }
        end
    end
    if Library.KeybindFrame.Visible then
        local vw, vh = getViewport()
        local p = S.kbPos or { x = 10, y = math.floor(vh / 2) }
        local lines = {}
        local mw = 0
        for _, kp in ipairs(Library.KeyPickers) do
            if not kp.NoUI then
                local s = string.format("[%s] %s (%s)", kp.Value, kp.Text, kp.Mode)
                lines[#lines + 1] = { s, kp:GetState() }
                local tw = TW(s)
                if tw > mw then mw = tw end
            end
        end
        local lh = G.ts + 5
        local w, h = math.max(210, mw + 14), G.ts + 12 + #lines * lh
        R("kb.o", p.x, p.y, w, h, Black, 60)
        R("kb.b", p.x + 1, p.y + 1, w - 2, h - 2, Library.OutlineColor, 60)
        R("kb.f", p.x + 2, p.y + 2, w - 4, h - 4, Library.MainColor, 60)
        R("kb.a", p.x + 2, p.y + 2, w - 4, 2, Library.AccentColor, 61)
        T("kb.t", "Keybinds", p.x + w / 2, p.y + 5, F, 61, true)
        for i, l in ipairs(lines) do
            T("kb.l" .. i, l[1], p.x + 6, p.y + G.ts + 9 + (i - 1) * lh, l[2] and Library.AccentColor or F, 61)
        end
        if Library.Toggled and S.click and inside(p.x, p.y, w, G.ts + 8) then
            S.click = false
            S.drag = { kind = "kb", ox = M.x - p.x, oy = M.y - p.y }
        end
    end
    local now = os.clock()
    local vw = getViewport()
    local np = Library.NotifyPosition
    local ny = np and np.y or 40
    local nx = np and np.x or 10
    local right = Library.NotifySide == "Right"
    local keep = {}
    for _, n in ipairs(S.notifs) do
        local age = now - n.t0
        if age < n.dur + 0.4 then
            keep[#keep + 1] = n
            local w, h = math.floor(TW(n.text)) + 18, G.ts + 9
            local slide = 1
            if age < 0.3 then
                slide = age / 0.3
            elseif age > n.dur then
                slide = 1 - (age - n.dur) / 0.4
            end
            slide = clamp(slide, 0, 1)
            slide = 1 - (1 - slide) * (1 - slide)
            local x = math.floor(-w + (w + nx) * slide)
            if right then x = math.floor(vw - (w + nx) * slide) end
            local id = n.uid
            R(id .. "o", x, ny, w, h, Black, 70)
            R(id .. "b", x + 1, ny + 1, w - 2, h - 2, Library.OutlineColor, 70)
            R(id .. "f", x + 2, ny + 2, w - 4, h - 4, Library.MainColor, 70)
            R(id .. "a", x + 2, ny + 2, 3, h - 4, Library.AccentColor, 71)
            T(id .. "t", n.text, x + 10, tyc(ny, h), F, 71)
            ny = ny + math.floor((h + 4) * slide + 0.5)
        end
    end
    S.notifs = keep
end

local function pollKeybinds()
    if S.listen then
        local kp = S.listen
        if Frame - (S.listenFrame or Frame) < 2 then
            for _, vk in ipairs(ScanList) do keyEdge(vk) end
            return
        end
        for _, vk in ipairs(ScanList) do
            if keyEdge(vk) then
                kp.Value = VKName[vk] or "None"
                S.listen = nil
                if vk == 1 then S.click = false end
                if vk == 2 then S.rclick = false end
                Library:SafeCallback(kp.ChangedCallback, kp.Value)
                Library:SafeCallback(kp.Changed, kp.Value)
                Library:AttemptSave()
                return
            end
        end
        return
    end
    if S.focus then return end
    for _, kp in ipairs(Library.KeyPickers) do
        local vk = VK[kp.Value]
        if vk then
            local e = keyEdge(vk)
            if e and kp.Mode == "Toggle" then
                kp.Toggled = not kp.Toggled
                kp:DoClick()
            end
        end
    end
    local tk = Library.ToggleKeybind and Library.ToggleKeybind.Value or Library.ToggleKey
    local tvk = VK[tk]
    if tvk and keyEdge(tvk) then Library:Toggle() end
end

local function drawTooltip()
    local t = S.tip
    if not t then return end
    local w, h = math.floor(TW(t)) + 12, G.ts + 9
    local x, y = M.x + 15, M.y + 12
    R("tip.o", x, y, w, h, Black, 90)
    R("tip.b", x + 1, y + 1, w - 2, h - 2, Library.OutlineColor, 90)
    R("tip.f", x + 2, y + 2, w - 4, h - 4, Library.MainColor, 90)
    T("tip.t", t, x + 6, tyc(y, h), Library.FontColor, 91)
end

local function step()
    Frame = Frame + 1
    Seq = 0
    updateMetrics()
    local now = os.clock()
    local dt = clamp(now - S.last, 0, 0.1)
    S.last = now
    local active = robloxActive()
    M.x, M.y = Mouse.X, Mouse.Y
    M.prev, M.rprev = M.down, M.rdown
    if active then M.down = mouse1(); M.rdown = mouse2() else M.down = false; M.rdown = false end
    M.click = M.down and not M.prev
    M.rclick = M.rdown and not M.rprev
    S.click, S.rclick = M.click, M.rclick
    S.tip = nil
    S.justClosed = nil

    if active then
        pollKeybinds()
        pollText()
    end

    local wantBlock = S.focus ~= nil or S.listen ~= nil
    if wantBlock ~= (S.blocked or false) then
        S.blocked = wantBlock
        if setrobloxinput then pcall(setrobloxinput, not wantBlock) end
    end

    local ft = Library.MenuFadeTime or 0.2
    if S.fade ~= S.fadeGoal then
        if ft <= 0 then
            S.fade = S.fadeGoal
        elseif S.fade < S.fadeGoal then
            S.fade = math.min(S.fadeGoal, S.fade + dt / ft)
        else
            S.fade = math.max(S.fadeGoal, S.fade - dt / ft)
        end
    end

    processDrag()

    local open = Library.Toggled
    if not open then S.click = false; S.rclick = false end

    local ovHit = false
    if S.ov and S.ov.rect then
        local r = S.ov.rect
        ovHit = inside(r[1], r[2], r[3], r[4])
    end
    if S.ov and (S.click or S.rclick) and not ovHit and S.ov.frame ~= Frame then
        S.justClosed = S.ov.el
        closeOverlay()
    end
    local ovClick, ovR = false, false
    if ovHit then ovClick, ovR = S.click, S.rclick; S.click = false; S.rclick = false end

    drawHud()

    if S.fade > 0 then
        Alpha = S.fade
        S.canHover = open and not ovHit and S.drag == nil
        for _, win in ipairs(Windows) do drawWindow(win) end
        Alpha = 1
        if S.ov then
            S.canHover = true
            S.click, S.rclick = ovClick, ovR
            drawOverlay()
        end
        if open then
            drawTooltip()
        end
    end

    if M.click and S.focus and S.focus.frame ~= Frame then
        local r = S.focus.rect
        if not (r and inside(r[1], r[2], r[3], r[4])) then blur(false) end
    end
    cleanup()
end

function Library:OnUnload(cb) table.insert(Library.UnloadCallbacks, cb) end
function Library:GiveSignal(sig) table.insert(Library.Signals, sig) end
function Library:Unload()
    if Library.Unloaded then return end
    Library.Unloaded = true
    Library.Toggled = false
    Dead = true
    S.ov = nil; S.drag = nil; S.focus = nil; S.listen = nil; S.notifs = {}
    for _, c in ipairs(Library.Signals) do pcall(function() c:Disconnect() end) end
    if setrobloxinput then pcall(setrobloxinput, true) end
    S.blocked = false
    removeAll()
    if Measure then pcall(function() Measure:Remove() end); Measure = nil end
    Library.KeyPickers = {}
    for _, cb in ipairs(Library.UnloadCallbacks) do Library:SafeCallback(cb) end
    for k in pairs(Toggles) do Toggles[k] = nil end
    for k in pairs(Options) do Options[k] = nil end
    if genv.__Linoria == Library then genv.__Linoria = nil end
end

do
    local sig = RunService.RenderStepped or RunService.Heartbeat
    local busy = false
    local conn = sig:Connect(function()
        if busy or Library.Unloaded then return end
        busy = true
        local ok, err = pcall(step)
        busy = false
        if Library.Unloaded then removeAll(); return end
        if not ok then warn("[Linoria] " .. tostring(err)) end
    end)
    table.insert(Library.Signals, conn)
end

do
    local last = 0
    local conn = RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - last < 2 then return end
        last = now
        for _, b in pairs(Options) do
            if b.Type == "Dropdown" and b.SpecialType and not (S.ov and S.ov.el == b) then pcall(function() b:Refresh() end) end
        end
    end)
    table.insert(Library.Signals, conn)
end

local ThemeManager = { Folder = "LinoriaLibSettings", Library = Library }
ThemeManager.BuiltInThemes = {
    ["Default"] = { 1, { FontColor = "ffffff", MainColor = "1c1c1c", AccentColor = "0055ff", BackgroundColor = "141414", OutlineColor = "323232" } },
    ["BBot"] = { 2, { FontColor = "ffffff", MainColor = "1e1e1e", AccentColor = "7e48a3", BackgroundColor = "232323", OutlineColor = "141414" } },
    ["Fatality"] = { 3, { FontColor = "ffffff", MainColor = "1e1842", AccentColor = "c50754", BackgroundColor = "191335", OutlineColor = "3c355d" } },
    ["Jester"] = { 4, { FontColor = "ffffff", MainColor = "242424", AccentColor = "db4467", BackgroundColor = "1c1c1c", OutlineColor = "373737" } },
    ["Mint"] = { 5, { FontColor = "ffffff", MainColor = "242424", AccentColor = "3db488", BackgroundColor = "1c1c1c", OutlineColor = "373737" } },
    ["Tokyo Night"] = { 6, { FontColor = "ffffff", MainColor = "191925", AccentColor = "6759b3", BackgroundColor = "16161f", OutlineColor = "323232" } },
    ["Ubuntu"] = { 7, { FontColor = "ffffff", MainColor = "3e3e3e", AccentColor = "e2581e", BackgroundColor = "323232", OutlineColor = "191919" } },
    ["Quartz"] = { 8, { FontColor = "ffffff", MainColor = "232330", AccentColor = "426e87", BackgroundColor = "1d1b26", OutlineColor = "27232f" } },
}
local ThemeFields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
local FontNames = { "UI", "System", "SystemBold", "Monospace", "Pixel", "ProximaSoftBold", "Minecraft", "Fortnite" }
function ThemeManager:SetLibrary(lib) self.Library = lib end
function ThemeManager:SetFolder(f) self.Folder = f; self:BuildFolderTree() end
function ThemeManager:BuildFolderTree()
    local parts = {}
    for p in tostring(self.Folder):gmatch("[^/]+") do
        parts[#parts + 1] = p
        pcall(makefolder, table.concat(parts, "/"))
    end
    pcall(makefolder, self.Folder .. "/themes")
end
function ThemeManager:ApplyTheme(name)
    local data = self.BuiltInThemes[name]
    local colors = data and data[2]
    if not colors then
        local ok, content = pcall(readfile, self.Folder .. "/themes/" .. name .. ".json")
        if ok and content then
            local ok2, dec = pcall(function() return HttpService:JSONDecode(content) end)
            if ok2 then colors = dec end
        end
    end
    if not colors then return end
    for _, f in ipairs(ThemeFields) do
        local c = colors[f] and fromHex(colors[f])
        if c then
            Library[f] = c
            if Options[f] then Options[f]:SetValueRGB(c) end
        end
    end
end
function ThemeManager:ThemeUpdate()
    for _, f in ipairs(ThemeFields) do
        if Options[f] then Library[f] = Options[f].Value end
    end
end
function ThemeManager:GetCustomThemes()
    local out = {}
    local ok, files = pcall(listfiles, self.Folder .. "/themes")
    if ok and files then
        for _, p in ipairs(files) do
            local n = tostring(p):match("([^/\\]+)%.json$")
            if n then out[#out + 1] = n end
        end
    end
    return out
end
function ThemeManager:SaveCustomTheme(name)
    if not name or name:gsub(" ", "") == "" then return Library:Notify("Invalid file name for theme (empty)", 3) end
    local data = {}
    for _, f in ipairs(ThemeFields) do data[f] = toHex(Options[f] and Options[f].Value or Library[f]) end
    self:BuildFolderTree()
    pcall(writefile, self.Folder .. "/themes/" .. name .. ".json", HttpService:JSONEncode(data))
end
function ThemeManager:LoadDefault()
    local theme = "Default"
    local ok, content = pcall(readfile, self.Folder .. "/themes/default.txt")
    if ok and content and content ~= "" then theme = content end
    if Options.ThemeManager_ThemeList and self.BuiltInThemes[theme] then
        Options.ThemeManager_ThemeList:SetValue(theme)
    else
        self:ApplyTheme(theme)
    end
end
function ThemeManager:SaveDefault(theme)
    self:BuildFolderTree()
    pcall(writefile, self.Folder .. "/themes/default.txt", theme)
end
function ThemeManager:CreateThemeManager(groupbox)
    groupbox:AddLabel("Background color"):AddColorPicker("BackgroundColor", { Default = Library.BackgroundColor })
    groupbox:AddLabel("Main color"):AddColorPicker("MainColor", { Default = Library.MainColor })
    groupbox:AddLabel("Accent color"):AddColorPicker("AccentColor", { Default = Library.AccentColor })
    groupbox:AddLabel("Outline color"):AddColorPicker("OutlineColor", { Default = Library.OutlineColor })
    groupbox:AddLabel("Font color"):AddColorPicker("FontColor", { Default = Library.FontColor })
    local names = {}
    for n in pairs(self.BuiltInThemes) do names[#names + 1] = n end
    table.sort(names, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)
    groupbox:AddDivider()
    groupbox:AddDropdown("ThemeManager_ThemeList", { Text = "Theme list", Values = names, Default = 1 })
    groupbox:AddButton("Set as default", function()
        self:SaveDefault(Options.ThemeManager_ThemeList.Value)
        Library:Notify(string.format("Set default theme to %q", tostring(Options.ThemeManager_ThemeList.Value)))
    end)
    Options.ThemeManager_ThemeList:OnChanged(function() self:ApplyTheme(Options.ThemeManager_ThemeList.Value) end)
    local fonts, cur = {}, "UI"
    for _, n in ipairs(FontNames) do
        local ok, f = pcall(function() return Drawing.Fonts[n] end)
        if ok and f ~= nil then
            fonts[#fonts + 1] = n
            if f == Library.Font then cur = n end
        end
    end
    local okf, saved = pcall(readfile, self.Folder .. "/themes/font.txt")
    if okf and saved and table.find(fonts, saved) then cur = saved end
    groupbox:AddDropdown("ThemeManager_Font", { Text = "Font", Values = fonts, Default = cur })
    Options.ThemeManager_Font:OnChanged(function()
        local v = Options.ThemeManager_Font.Value
        if not v then return end
        Library:SetFont(v)
        self:BuildFolderTree()
        pcall(writefile, self.Folder .. "/themes/font.txt", v)
    end)
    Library:SetFont(cur)
    groupbox:AddDivider()
    groupbox:AddInput("ThemeManager_CustomThemeName", { Text = "Custom theme name" })
    groupbox:AddDropdown("ThemeManager_CustomThemeList", { Text = "Custom themes", Values = self:GetCustomThemes(), AllowNull = true, Default = 1 })
    groupbox:AddDivider()
    groupbox:AddButton("Save theme", function()
        self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value)
        Options.ThemeManager_CustomThemeList:SetValues(self:GetCustomThemes())
        Options.ThemeManager_CustomThemeList:SetValue(nil)
    end):AddButton("Load theme", function()
        local v = Options.ThemeManager_CustomThemeList.Value
        if v then self:ApplyTheme(v) end
    end)
    groupbox:AddButton("Refresh list", function()
        Options.ThemeManager_CustomThemeList:SetValues(self:GetCustomThemes())
        Options.ThemeManager_CustomThemeList:SetValue(nil)
    end)
    groupbox:AddButton("Set as default", function()
        local v = Options.ThemeManager_CustomThemeList.Value
        if v and v ~= "" then
            self:SaveDefault(v)
            Library:Notify(string.format("Set default theme to %q", v))
        end
    end)
    self:LoadDefault()
    for _, f in ipairs(ThemeFields) do
        Options[f]:OnChanged(function() self:ThemeUpdate() end)
    end
end
function ThemeManager:ApplyToTab(tab)
    self:CreateThemeManager(tab:AddLeftGroupbox("Themes"))
end
function ThemeManager:ApplyToGroupbox(groupbox)
    self:CreateThemeManager(groupbox)
end

local SaveManager = { Folder = "LinoriaLibSettings", Ignore = {}, Library = Library }
SaveManager.Parser = {
    Toggle = {
        Save = function(idx, o) return { type = "Toggle", idx = idx, value = o.Value } end,
        Load = function(idx, d) if Toggles[idx] then Toggles[idx]:SetValue(d.value) end end,
    },
    Slider = {
        Save = function(idx, o) return { type = "Slider", idx = idx, value = tostring(o.Value) } end,
        Load = function(idx, d) if Options[idx] then Options[idx]:SetValue(d.value) end end,
    },
    Dropdown = {
        Save = function(idx, o) return { type = "Dropdown", idx = idx, value = o.Value, mutli = o.Multi } end,
        Load = function(idx, d) if Options[idx] then Options[idx]:SetValue(d.value) end end,
    },
    ColorPicker = {
        Save = function(idx, o) return { type = "ColorPicker", idx = idx, value = toHex(o.Value), transparency = o.Transparency } end,
        Load = function(idx, d) local c = fromHex(d.value); if Options[idx] and c then Options[idx]:SetValueRGB(c, d.transparency) end end,
    },
    KeyPicker = {
        Save = function(idx, o) return { type = "KeyPicker", idx = idx, mode = o.Mode, key = o.Value } end,
        Load = function(idx, d) if Options[idx] then Options[idx]:SetValue({ d.key, d.mode }) end end,
    },
    Input = {
        Save = function(idx, o) return { type = "Input", idx = idx, text = o.Value } end,
        Load = function(idx, d) if Options[idx] and type(d.text) == "string" then Options[idx]:SetValue(d.text) end end,
    },
}
function SaveManager:SetLibrary(lib) self.Library = lib end
function SaveManager:SetIgnoreIndexes(list) for _, k in ipairs(list) do self.Ignore[k] = true end end
function SaveManager:IgnoreThemeSettings()
    self:SetIgnoreIndexes({ "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor",
        "ThemeManager_ThemeList", "ThemeManager_CustomThemeList", "ThemeManager_CustomThemeName", "ThemeManager_Font" })
end
function SaveManager:SetFolder(f) self.Folder = f; self:BuildFolderTree() end
function SaveManager:BuildFolderTree()
    local parts = {}
    for p in tostring(self.Folder):gmatch("[^/]+") do
        parts[#parts + 1] = p
        pcall(makefolder, table.concat(parts, "/"))
    end
    pcall(makefolder, self.Folder .. "/settings")
end
function SaveManager:Save(name)
    if not name then return false, "no config file is selected" end
    local data = { objects = {} }
    for idx, t in pairs(Toggles) do
        if not self.Ignore[idx] then table.insert(data.objects, self.Parser.Toggle.Save(idx, t)) end
    end
    for idx, o in pairs(Options) do
        if not self.Ignore[idx] and self.Parser[o.Type] then
            table.insert(data.objects, self.Parser[o.Type].Save(idx, o))
        end
    end
    local ok, enc = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok then return false, "failed to encode data" end
    self:BuildFolderTree()
    local wok = pcall(writefile, self.Folder .. "/settings/" .. name .. ".json", enc)
    if not wok then return false, "writefile failed" end
    return true
end
function SaveManager:Load(name)
    if not name then return false, "no config file is selected" end
    local ok, content = pcall(readfile, self.Folder .. "/settings/" .. name .. ".json")
    if not ok or not content then return false, "invalid file" end
    local dok, dec = pcall(function() return HttpService:JSONDecode(content) end)
    if not dok or type(dec) ~= "table" then return false, "decode error" end
    for _, o in ipairs(dec.objects or {}) do
        if self.Parser[o.type] then
            pcall(function() self.Parser[o.type].Load(o.idx, o) end)
        end
    end
    return true
end
function SaveManager:RefreshConfigList()
    local out = {}
    local ok, files = pcall(listfiles, self.Folder .. "/settings")
    if ok and files then
        for _, p in ipairs(files) do
            local n = tostring(p):match("([^/\\]+)%.json$")
            if n then out[#out + 1] = n end
        end
    end
    return out
end
function SaveManager:LoadAutoloadConfig()
    local ok, name = pcall(readfile, self.Folder .. "/settings/autoload.txt")
    if ok and name and name ~= "" then
        local s, err = self:Load(name)
        if not s then return Library:Notify("Failed to load autoload config: " .. tostring(err)) end
        Library:Notify(string.format("Auto loaded config %q", name))
    end
end
function SaveManager:BuildConfigSection(tab)
    local section = tab:AddRightGroupbox("Configuration")
    section:AddInput("SaveManager_ConfigName", { Text = "Config name" })
    section:AddDropdown("SaveManager_ConfigList", { Text = "Config list", Values = self:RefreshConfigList(), AllowNull = true })
    section:AddDivider()
    section:AddButton("Create config", function()
        local name = Options.SaveManager_ConfigName.Value
        if name:gsub(" ", "") == "" then return Library:Notify("Invalid config name (empty)", 2) end
        local s, err = self:Save(name)
        if not s then return Library:Notify("Failed to save config: " .. tostring(err)) end
        Library:Notify(string.format("Created config %q", name))
        Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
        Options.SaveManager_ConfigList:SetValue(nil)
    end):AddButton("Load config", function()
        local name = Options.SaveManager_ConfigList.Value
        local s, err = self:Load(name)
        if not s then return Library:Notify("Failed to load config: " .. tostring(err)) end
        Library:Notify(string.format("Loaded config %q", name))
    end)
    section:AddButton("Overwrite config", function()
        local name = Options.SaveManager_ConfigList.Value
        local s, err = self:Save(name)
        if not s then return Library:Notify("Failed to overwrite config: " .. tostring(err)) end
        Library:Notify(string.format("Overwrote config %q", name))
    end)
    section:AddButton("Refresh list", function()
        Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
        Options.SaveManager_ConfigList:SetValue(nil)
    end)
    section:AddButton("Set as autoload", function()
        local name = Options.SaveManager_ConfigList.Value
        if not name then return end
        self:BuildFolderTree()
        pcall(writefile, self.Folder .. "/settings/autoload.txt", name)
        self.AutoloadLabel:SetText("Current autoload config: " .. name)
        Library:Notify(string.format("Set %q to auto load", name))
    end)
    self.AutoloadLabel = section:AddLabel("Current autoload config: none", true)
    local ok, name = pcall(readfile, self.Folder .. "/settings/autoload.txt")
    if ok and name and name ~= "" then self.AutoloadLabel:SetText("Current autoload config: " .. name) end
    self:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })
end

Library.ThemeManager = ThemeManager
Library.SaveManager = SaveManager
genv.Linoria = Library
return Library
