-- TargetCastBarPlus 0.7
-- 0.7: border slice 4 (the art is only ~11px tall, so 8 overlapped)
-- 0.6: border drawn 9-slice (corners and edges keep their size) instead of stretched
-- 0.5: font size 10 to suit the shorter target bar
-- 0.4: fixed font identical to CastBarPlus, re-applied if Blizzard swaps it
-- 0.3: name and timer copy your own cast bar's look exactly (font, size, outline, shadow, color)
-- 0.2: nameplate font at one size for name and timer; spell icon centered on the bar
-- Your target's and focus's cast bars, reshaped like CastBarPlus does yours:
--   * taller (TARGET_HEIGHT below)
--   * the spell name drawn inside the bar, centered
--   * a cast timer inside the bar, on its right edge (Blizzard gives these
--     bars none, so this addon adds one)
--   * the spell icon stays where Blizzard puts it
--
-- Safety: bars are resized only out of combat; the text labels are moved
-- inside them (allowed any time) and put back whenever Blizzard re-lays the
-- bar out. Nothing of Blizzard's is replaced; every step is wrapped.
-- The game may hide other units' cast timing from addons in combat; then
-- the timer stays blank instead of showing wrong numbers.
--
-- Macro (created for you):  TCB Debug   lists what it found on the cast bars

local CONFIG = {
    TARGET_HEIGHT = 18,     -- target / focus cast bar height (Blizzard's is about 10); nil = leave it alone
    -- one fixed font for spell names and timers (the same in CastBarPlus and TargetCastBarPlus)
    FONT_FILE = "Fonts\\FRIZQT__.TTF",  -- Friz Quadrata, WoW's standard font
    FONT_SIZE = 10,         -- size of the spell name and the timer (CastBarPlus uses 12 on its taller bar)
    FONT_OUTLINE = "",      -- "" = plain (with a drop shadow), or "OUTLINE" / "THICKOUTLINE"
    TIMER_PAD = 6,          -- gap between the timer and the bar's right edge
    NAME_ROOM = 44,         -- space kept free on each side of the name (for the timer)
    ICON_GAP = 4,           -- gap between the spell icon and the bar (used only if Blizzard's can't be read)
    HIDE_NAME_BOX = true,   -- hide the dark box Blizzard draws under the bar for the name
    -- the border: instead of stretching the whole picture, keep its corners and
    -- edges at their real size and stretch only the middle (9-slice)
    BORDER_SLICE = 4,       -- size of the kept corners/edges, in the art's pixels (try 3-5); nil = Blizzard's stretching
}

local function IsSecret(v) return issecretvalue and issecretvalue(v) end
local function Say(m) print("|cff9999ffTargetCastBarPlus:|r " .. m) end

-- the cast bars we restyle: yours, your target's and your focus's (icons stay as they are)
local BARS = {
    { unit = "target", names = { "TargetFrameSpellBar" }, height = "TARGET_HEIGHT" },
    { unit = "focus",  names = { "FocusFrameSpellBar" },  height = "TARGET_HEIGHT" },
}

local function BarOf(def)
    for _, n in ipairs(def.names) do
        local f = _G[n]
        if type(f) == "table" and f.GetObjectType then return f end
    end
end

local function NameText(bar)
    return rawget(bar, "Text") or _G[(bar:GetName() or "") .. "Text"]
end

-- Blizzard's timer, if this bar has one; otherwise our own
local ownTimers = {}   -- bar -> { fs = our timer, unit = unit }
local function TimerText(bar, unit)
    local t = rawget(bar, "CastTimeText") or rawget(bar, "Timer") or rawget(bar, "TimerText")
    if t and t.SetPoint then return t, false end
    local o = ownTimers[bar]
    if not o then
        local fs = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetJustifyH("RIGHT")
        o = { fs = fs, unit = unit }
        ownTimers[bar] = o
    end
    return o.fs, true
end

local function CastBarFixInstalled()
    local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    local ok, v = pcall(loaded, "CastBarFix")
    return ok and v
end

local function UseFont(fs)
    local ok, curFile, curSize, curFlags = pcall(fs.GetFont, fs)
    if ok and curFile == CONFIG.FONT_FILE and math.abs((curSize or 0) - CONFIG.FONT_SIZE) < 0.1
        and (curFlags or "") == CONFIG.FONT_OUTLINE then return end
    if not fs:SetFont(CONFIG.FONT_FILE, CONFIG.FONT_SIZE, CONFIG.FONT_OUTLINE) then
        fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", CONFIG.FONT_SIZE, CONFIG.FONT_OUTLINE)
    end
    if CONFIG.FONT_OUTLINE == "" then
        pcall(function() fs:SetShadowOffset(1, -1); fs:SetShadowColor(0, 0, 0, 1) end)
    end
end

local iconGap = {}   -- icon -> gap to the bar (Blizzard's, read once)
local sliced = {}     -- border textures already set to 9-slice
local placing = false
local function PlaceBar(def)
    local bar = BarOf(def)
    if not bar then return end
    -- height (out of combat only; your bar's size is left to CastBarFix if that's installed)
    local h = CONFIG[def.height]
    local sizeOwner = false
    if h and not sizeOwner and not (InCombatLockdown and InCombatLockdown()) then
        if math.abs((bar:GetHeight() or 0) - h) > 0.5 then pcall(bar.SetHeight, bar, h) end
    end
    -- the spell name, centered inside the bar
    local name = NameText(bar)
    if name then
        pcall(function()
            name:ClearAllPoints()
            name:SetPoint("LEFT", bar, "LEFT", CONFIG.NAME_ROOM, 0)
            name:SetPoint("RIGHT", bar, "RIGHT", -CONFIG.NAME_ROOM, 0)
            name:SetJustifyH("CENTER")
            name:SetDrawLayer("OVERLAY", 7)
            name:SetWordWrap(false)
            UseFont(name)
        end)
    end
    -- the timer, on the right edge inside the bar
    local timer = TimerText(bar, def.unit)
    if timer then
        pcall(function()
            timer:ClearAllPoints()
            timer:SetPoint("RIGHT", bar, "RIGHT", -CONFIG.TIMER_PAD, 0)
            timer:SetJustifyH("RIGHT")
            timer:SetDrawLayer("OVERLAY", 7)
            UseFont(timer)
        end)
    end
    -- the spell icon: keep Blizzard's size, but center it on the (taller) bar
    local icon = rawget(bar, "Icon")
    if icon and icon.SetPoint then
        pcall(function()
            -- keep Blizzard's sideways gap the first time we see it
            if iconGap[icon] == nil then
                local point, _, relPoint, x = icon:GetPoint(1)
                if type(x) == "number" and point and point:find("RIGHT") and relPoint and relPoint:find("LEFT") then
                    iconGap[icon] = -x
                else
                    iconGap[icon] = CONFIG.ICON_GAP or 4
                end
            end
            icon:ClearAllPoints()
            icon:SetPoint("RIGHT", bar, "LEFT", -iconGap[icon], 0)
        end)
    end
    -- the border (and the "can't interrupt" shield border): 9-slice instead of stretch
    if CONFIG.BORDER_SLICE then
        for _, key in ipairs({ "Border", "BorderShield" }) do
            local b = rawget(bar, key) or _G[(bar:GetName() or "") .. key]
            if b and b.SetTextureSliceMargins then   -- re-applied each time: Blizzard may reset the art
                local m = CONFIG.BORDER_SLICE
                if pcall(b.SetTextureSliceMargins, b, m, m, m, m) then
                    if b.SetTextureSliceMode then
                        pcall(b.SetTextureSliceMode, b, (Enum and Enum.UITextureSliceMode and Enum.UITextureSliceMode.Stretched) or 0)
                    end
                    sliced[b] = true
                end
            end
        end
    end
    -- the dark box Blizzard draws under the bar to hold the name
    if CONFIG.HIDE_NAME_BOX then
        local box = rawget(bar, "TextBorder")
        if box and box.SetAlpha then pcall(box.SetAlpha, box, 0) end
    end
end

local function Place()
    if placing then return end
    placing = true
    for _, def in ipairs(BARS) do pcall(PlaceBar, def) end
    placing = false
end

-- our own timer (bars without Blizzard's): time left, 1 decimal. For other
-- units the game may hide cast timing from addons in combat; then it stays blank.
local function UpdateOwnTimer(o)
    local now = GetTime() * 1000
    local endMs
    local ok, _, _, _, _, e = pcall(UnitCastingInfo, o.unit)
    if ok and e and not IsSecret(e) then endMs = e end
    if not endMs then
        local okC, _, _, _, _, ec = pcall(UnitChannelInfo, o.unit)
        if okC and ec and not IsSecret(ec) then endMs = ec end
    end
    if endMs and endMs > now then
        o.fs:SetFormattedText("%.1f", (endMs - now) / 1000)
    else
        o.fs:SetText("")
    end
end

-- re-place the labels whenever Blizzard may have put them back
local hooked = {}
local function Hook()
    for _, def in ipairs(BARS) do
        local bar = BarOf(def)
        if bar and not hooked[bar] then
            hooked[bar] = true
            if type(bar.SetLook) == "function" then
                pcall(hooksecurefunc, bar, "SetLook", function() pcall(Place) end)
            end
            bar:HookScript("OnShow", function() pcall(Place) end)
            bar:HookScript("OnUpdate", function(self)
                local o = ownTimers[self]
                if o then pcall(UpdateOwnTimer, o) end
                -- Blizzard sometimes swaps the font back mid-session: put ours back
                local n = NameText(self)
                if n then pcall(UseFont, n) end
                local t = TimerText(self, def.unit)
                if t then pcall(UseFont, t) end
            end)
        end
    end
end

local events = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "EDIT_MODE_LAYOUTS_UPDATED",
                     "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED",
                     "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START" }) do
    pcall(events.RegisterEvent, events, e)
end
events:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        if unit ~= "target" and unit ~= "focus" then return end
    end
    pcall(Hook)
    pcall(Place)
end)

---------------------------------------------------------------- debug macro
SLASH_TARGETCASTBARPLUS1 = "/tcb"
SlashCmdList["TARGETCASTBARPLUS"] = function()
    for _, def in ipairs(BARS) do
        local bar = BarOf(def)
        if not bar then
            Say(def.unit .. " cast bar: not found")
        else
            local _, own = TimerText(bar, def.unit)
            Say(("%s cast bar: %s, %dx%d%s; name %s, timer %s, name box %s"):format(def.unit, bar:GetName() or "?",
                bar:GetWidth() or 0, bar:GetHeight() or 0,
                "",
                NameText(bar) and "found" or "NOT found", own and "ours" or "Blizzard's",
                rawget(bar, "TextBorder") and "found" or "none"))
            local b = rawget(bar, "Border") or _G[(bar:GetName() or "") .. "Border"]
            if b then
                local okA, atlas = pcall(function() return b:GetAtlas() end)
                local okT, file = pcall(function() return b:GetTexture() end)
                local okS, w, h = pcall(function() return b:GetSize() end)
                Say(("  border: %s, %dx%d, 9-slice %s"):format(
                    (okA and atlas) or ("file " .. tostring(okT and file or "?")),
                    okS and w or 0, okS and h or 0,
                    sliced[b] and "on" or (b.SetTextureSliceMargins and "off" or "not supported by this client")))
            else
                Say("  border: not found")
            end
        end
    end
end

local made = false
local mf = CreateFrame("Frame")
mf:RegisterEvent("PLAYER_ENTERING_WORLD")
mf:RegisterEvent("PLAYER_REGEN_ENABLED")
mf:SetScript("OnEvent", function()
    if made or (InCombatLockdown and InCombatLockdown()) then return end
    made = true
    if not (GetMacroIndexByName and CreateMacro and GetNumMacros) then return end
    pcall(function()
        local idx = GetMacroIndexByName("TCB Debug")
        if not (idx and idx > 0) and GetNumMacros() < (MAX_ACCOUNT_MACROS or 36) then
            if not pcall(CreateMacro, "TCB Debug", "Spell_Fire_FlameBolt", "/tcb", nil) then
                pcall(CreateMacro, "TCB Debug", "INV_MISC_QUESTIONMARK", "/tcb", nil)
            end
        end
    end)
end)
