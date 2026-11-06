-- TargetClassColors 0.3
-- 0.2: brighter class colors (LIGHTEN and GLOW settings below)
-- 0.3: the bright layer stays inside the bar (same box and shape as the fill)
-- When your target (or focus) is a player, their health bar on the target
-- frame turns their class color. NPCs keep Blizzard's normal colors.
--
-- Safety: it only changes colors. It hooks nothing on Blizzard's frames,
-- doesn't touch anything you click or the gamepad UI, and simply re-checks
-- the color a few times a second while you have a player targeted (in case
-- Blizzard repaints the bar).

local CONFIG = {
    COLOR_HEALTH = true,   -- class-color the health bar
    COLOR_NAME = false,    -- also class-color the name text
    UNITS = { "target", "focus" },
    -- brightness: the bar art is greyed before the class color goes on, which
    -- makes it look dim. LIGHTEN mixes the color toward white (0-1) and GLOW
    -- adds a bright layer of the same color over the filled part (0-1).
    LIGHTEN = 0.15,
    GLOW = 0.35,
}

local FRAME_OF = { target = "TargetFrame", focus = "FocusFrame" }

local function IsSecret(v) return issecretvalue and issecretvalue(v) end

local function Walk(root, ...)
    local cur = root
    for i = 1, select("#", ...) do
        if type(cur) ~= "table" then return nil end
        cur = cur[select(i, ...)]
    end
    return cur
end

local function HealthBar(unit)
    local fname = FRAME_OF[unit]
    local f = _G[fname]
    return _G[fname .. "HealthBar"]
        or Walk(f, "healthbar")
        or Walk(f, "TargetFrameContent", "TargetFrameContentMain", "HealthBarsContainer", "HealthBar")
        or Walk(f, "TargetFrameContent", "TargetFrameContentMain", "HealthBar")
end

local function NameText(unit)
    local fname = FRAME_OF[unit]
    local f = _G[fname]
    return Walk(f, "name") or _G[fname .. "TextureFrameName"]
        or Walk(f, "TargetFrameContent", "TargetFrameContentMain", "Name")
end

local function ClassColor(unit)
    local okp, isPlayer = pcall(UnitIsPlayer, unit)
    if not okp or IsSecret(isPlayer) or not isPlayer then return nil end
    local okc, _, class = pcall(UnitClass, unit)
    if not okc or class == nil or IsSecret(class) then return nil end
    local c = (C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(class))
        or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
    if not c then return nil end
    return c.r, c.g, c.b
end

local original = {} -- object -> { r, g, b } before we first colored it
local colored = {}  -- object -> true while it shows a class color

local function Close(a, b) return a and b and math.abs(a - b) < 0.01 end

-- our own bright layer over the bar's filled part (made once, out of combat)
local glows = {}
local function GlowFor(bar)
    if glows[bar] then return glows[bar] end
    if (InCombatLockdown and InCombatLockdown()) or CONFIG.GLOW <= 0 then return nil end
    local fill = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
    if not fill then return nil end
    local holder = CreateFrame("Frame", nil, bar)        -- ours; follows the bar
    holder:SetAllPoints(bar)
    holder:EnableMouse(false)
    local t = holder:CreateTexture(nil, "ARTWORK")
    -- inside the bar's own box, ending where the health fill ends
    t:SetPoint("TOPLEFT", bar, "TOPLEFT")
    t:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT")
    t:SetPoint("RIGHT", fill, "RIGHT")
    -- and cut to the same shape as the fill (the bar's rounded/clipped ends)
    if fill.GetNumMaskTextures and t.AddMaskTexture then
        for i = 1, (fill:GetNumMaskTextures() or 0) do
            local m = fill:GetMaskTexture(i)
            if m then pcall(t.AddMaskTexture, t, m) end
        end
    end
    t:SetColorTexture(1, 1, 1, 1)
    t:SetBlendMode("ADD")
    t:Hide()
    glows[bar] = t
    return t
end

local function Lighten(v) return v + (1 - v) * CONFIG.LIGHTEN end

local function PaintBar(bar, r, g, b)
    r, g, b = Lighten(r), Lighten(g), Lighten(b)
    local glow = GlowFor(bar)
    if glow then
        glow:SetVertexColor(r, g, b, CONFIG.GLOW)
        glow:Show()
    end
    if not original[bar] then original[bar] = { bar:GetStatusBarColor() } end
    if bar.SetStatusBarDesaturated then pcall(bar.SetStatusBarDesaturated, bar, true) end
    local cr, cg, cb = bar:GetStatusBarColor()
    if not (Close(cr, r) and Close(cg, g) and Close(cb, b)) then bar:SetStatusBarColor(r, g, b) end
    colored[bar] = true
end

local function RestoreBar(bar)
    if glows[bar] then glows[bar]:Hide() end
    if not colored[bar] then return end
    colored[bar] = nil
    if bar.SetStatusBarDesaturated then pcall(bar.SetStatusBarDesaturated, bar, false) end
    local o = original[bar]
    if o and o[1] then bar:SetStatusBarColor(o[1], o[2], o[3]) end
end

local function PaintName(fs, r, g, b)
    if not original[fs] then original[fs] = { fs:GetTextColor() } end
    fs:SetTextColor(r, g, b)
    colored[fs] = true
end

local function RestoreName(fs)
    if not colored[fs] then return end
    colored[fs] = nil
    local o = original[fs]
    if o and o[1] then fs:SetTextColor(o[1], o[2], o[3]) end
end

local anyPlayer = false

local function Apply(unit)
    local r, g, b = ClassColor(unit)
    local bar = CONFIG.COLOR_HEALTH and HealthBar(unit)
    local name = CONFIG.COLOR_NAME and NameText(unit)
    if r then
        anyPlayer = true
        if bar and bar.SetStatusBarColor then pcall(PaintBar, bar, r, g, b) end
        if name and name.SetTextColor then pcall(PaintName, name, r, g, b) end
    else
        if bar then pcall(RestoreBar, bar) end
        if name then pcall(RestoreName, name) end
    end
end

local ticker = CreateFrame("Frame")
local function Update()
    anyPlayer = false
    for _, unit in ipairs(CONFIG.UNITS) do
        if _G[FRAME_OF[unit]] then Apply(unit) end
    end
    if anyPlayer then
        local acc = 0
        ticker:SetScript("OnUpdate", function(_, e)
            acc = acc + e
            if acc < 0.25 then return end
            acc = 0
            Update()
        end)
    else
        ticker:SetScript("OnUpdate", nil)
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("PLAYER_FOCUS_CHANGED")
events:RegisterEvent("UNIT_FACTION")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then
        for _, unit in ipairs(CONFIG.UNITS) do
            local bar = HealthBar(unit)
            if bar then pcall(GlowFor, bar) end
        end
    end
    -- one frame later, after Blizzard has drawn the new target
    C_Timer.After(0, function() pcall(Update) end)
end)
