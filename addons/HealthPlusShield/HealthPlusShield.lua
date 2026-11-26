-- HealthPlusShield 0.6 (test)
-- 0.6: Arial Narrow by default (copying the frame's font picked up the wrong one)
-- 0.5: Arial Narrow (the bar text's own font) when the frame's font can't be copied; font choice
-- 0.4: sits on the frame's own right-hand number directly; safer font copy; /hps shows what it did
-- 0.3: hides the frame's own right-hand number (ours replaces it; the 100% stays) and copies the
--      font from that right-hand text
-- 0.2: sits at the right end of the bar and leaves the frame's own text (100%) alone; uses the
--      frame's own font; with hidden numbers it uses the game's own "blank when zero" helpers
-- Shows on the right of your player frame's health bar:   2,072 + 427
-- (your health, plus every absorb on you: Power Word: Shield, Divine Aegis and the like).
-- The game gives one total for absorbs, so shields can't be split by spell.
--
-- If the game hides the numbers in combat, it still tries to show them (the game can print a
-- hidden number even though addons can't do maths on it). /hps says which way it's working.

local ADDON = ...
local CONFIG = {
    SHOW_MAX     = false,     -- 2,072 / 3,000 + 427
    SHOW_ZERO    = false,     -- show "+ 0" with no shield (it always shows when the numbers are hidden)
    FONT         = "Fonts\\ARIALN.TTF",   -- the bar text's own font
    FONT_SIZE    = 0,         -- 0 = same size as the frame's own text
    OUTLINE      = "",        -- "" = same outline as the frame's own text
    SHIELD_COLOR = "99ddff",  -- the "+ 427" part
    X = 0, Y = 0,             -- nudge from where the frame's own right-hand number sits
}
local DB
local function Say(m) print("|cff99ddffHealthPlusShield:|r " .. m) end
local function Secret(v) return issecretvalue and issecretvalue(v) end
local function Num(v) if type(v) == "number" and not Secret(v) then return v end end

-- ---------------------------------------------------------------- finding the bar and its text
local function Path(root, ...)
    local f = root
    for _, k in ipairs({ ... }) do if type(f) ~= "table" then return nil end; f = f[k] end
    return f
end

local function HealthBar()
    if PlayerFrame_GetHealthBar then local ok, b = pcall(PlayerFrame_GetHealthBar); if ok and b then return b end end
    return Path(PlayerFrame, "PlayerFrameContent", "PlayerFrameContentMain", "HealthBarsContainer", "HealthBar")
        or Path(PlayerFrame, "PlayerFrameContent", "PlayerFrameContentMain", "HealthBar")
        or PlayerFrameHealthBar or (PlayerFrame and PlayerFrame.healthbar)
end

local function BlizzTexts(bar)
    local list, seen = {}, {}
    local function add(t) if type(t) == "table" and not seen[t] and t.SetAlpha then seen[t] = true; list[#list + 1] = t end end
    if bar then for _, k in ipairs({ "TextString", "LeftText", "RightText" }) do add(bar[k]) end end
    local box = bar and bar.GetParent and bar:GetParent()
    if box then for _, k in ipairs({ "HealthBarText", "LeftText", "RightText", "TextString" }) do add(box[k]) end end
    for _, g in ipairs({ "PlayerFrameHealthBarText", "PlayerFrameHealthBarTextLeft", "PlayerFrameHealthBarTextRight" }) do add(_G[g]) end
    return list
end

-- the frame's own right-hand number is replaced by ours: keep it invisible (alpha only)
local hidden, busy = {}, false
local function Hide(t)
    if hidden[t] then return end
    hidden[t] = true
    pcall(t.SetAlpha, t, 0)
    hooksecurefunc(t, "SetAlpha", function(s, a)
        if busy or not hidden[s] then return end
        if Secret(a) or a ~= 0 then busy = true; pcall(s.SetAlpha, s, 0); busy = false end
    end)
end
local function RightText(b)
    if not b then return nil end
    local t = b.RightText
    if type(t) ~= "table" then t = _G.PlayerFrameHealthBarTextRight end
    return type(t) == "table" and t.SetAlpha and t or nil
end

-- ---------------------------------------------------------------- our text
local holder = CreateFrame("Frame", "HealthPlusShieldText", UIParent)
holder:SetSize(1, 1)
holder:SetFrameStrata("MEDIUM")
local fs = holder:CreateFontString(nil, "OVERLAY")
fs:SetPoint("RIGHT")
fs:SetJustifyH("RIGHT")

local mode = "starting"
local diag = { anchor = "?", font = "?" }
local bar

local function Commas(n)
    local s = tostring(math.floor(n + 0.5))
    local k
    repeat s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2") until k == 0
    return s
end

local function Place()
    bar = bar or HealthBar()
    if not bar then return false end
    holder:ClearAllPoints()
    local rtA = RightText(bar)
    if not (rtA and pcall(holder.SetPoint, holder, "RIGHT", rtA, "RIGHT", CONFIG.X, CONFIG.Y)) then
        holder:ClearAllPoints()
        holder:SetPoint("RIGHT", bar, "RIGHT", -2 + CONFIG.X, CONFIG.Y)
        diag.anchor = "bar's right end"
    else
        diag.anchor = "the frame's right-hand number"
    end
    local okB, bs = pcall(bar.GetEffectiveScale, bar)
    local okU, us = pcall(UIParent.GetEffectiveScale, UIParent)
    if okB and okU and Num(bs) and Num(us) and us > 0 then holder:SetScale(bs / us) end
    local okL, lvl = pcall(bar.GetFrameLevel, bar)
    if okL and Num(lvl) then holder:SetFrameLevel(lvl + 20) end
    -- the frame's own health text sets the font
    local font, size, flags
    local src = { RightText(bar) }
    for _, t in ipairs(BlizzTexts(bar)) do src[#src + 1] = t end
    local rt = RightText(bar)
    for _, t in ipairs(src) do
        local ok, f, sz, fl = pcall(t.GetFont, t)
        if ok and type(f) == "string" then font, size, flags = f, sz, fl; break end
    end
    if not font and TextStatusBarText then local ok, f, sz, fl = pcall(TextStatusBarText.GetFont, TextStatusBarText); if ok then font, size, flags = f, sz, fl end end
    if type(font) ~= "string" or Secret(font) or font == "" then font = "Fonts\\ARIALN.TTF" end
    if CONFIG.FONT and CONFIG.FONT ~= "auto" then font = CONFIG.FONT else font = "Fonts\\ARIALN.TTF" end
    if type(flags) ~= "string" or Secret(flags) then flags = nil end
    size = (CONFIG.FONT_SIZE and CONFIG.FONT_SIZE > 0) and CONFIG.FONT_SIZE or Num(size) or 10
    flags = (CONFIG.OUTLINE ~= "" and CONFIG.OUTLINE) or flags or ""
    if not pcall(fs.SetFont, fs, font, size, flags) then pcall(fs.SetFont, fs, "Fonts\\ARIALN.TTF", size, "") end
    diag.font = ("%s %s %s"):format(tostring(font):match("([^\\/]+)$") or "?", tostring(size), flags == "" and "plain" or tostring(flags))
    if rt then
        Hide(rt)
        local okC, r, g, b2 = pcall(rt.GetTextColor, rt)
        if okC and Num(r) and Num(g) and Num(b2) and (r + g + b2) > 0.3 then fs:SetTextColor(r, g, b2) else fs:SetTextColor(1, 1, 1) end
        local okS, sx, sy = pcall(rt.GetShadowOffset, rt)
        if okS and Num(sx) and Num(sy) then fs:SetShadowOffset(sx, sy) end
        local okSC, sr, sg, sb, sa = pcall(rt.GetShadowColor, rt)
        if okSC and Num(sr) and Num(sg) and Num(sb) then fs:SetShadowColor(sr, sg, sb, Num(sa) or 1) end
    end
    return true
end

local function Update()
    if not bar then local ok, r = pcall(Place); if not (ok and r) then mode = "no player health bar found"; return end end
    local okH, h = pcall(UnitHealth, "player")
    local okM, m = pcall(UnitHealthMax, "player")
    local okA, a = false, nil
    if UnitGetTotalAbsorbs then okA, a = pcall(UnitGetTotalAbsorbs, "player") end
    if not okH then mode = "health not readable"; fs:SetText(""); return end
    local c = "|cff" .. CONFIG.SHIELD_COLOR

    -- 1) plain numbers: we can format and leave out "+ 0"
    if Num(h) and (not okA or a == nil or Num(a)) and (not CONFIG.SHOW_MAX or Num(m)) then
        local t = Commas(h)
        if CONFIG.SHOW_MAX and Num(m) then t = t .. " / " .. Commas(m) end
        local ab = okA and Num(a) or 0
        if ab > 0 or (CONFIG.SHOW_ZERO and okA and a ~= nil) then t = t .. " " .. c .. "+ " .. Commas(ab) .. "|r" end
        fs:SetText(t)
        mode = UnitGetTotalAbsorbs and "numbers readable" or "numbers readable (this client gives no shield amount)"
        return
    end

    -- 2) hidden numbers: let the game print them (commas if its formatter accepts them)
    local function Fmt(v)
        if BreakUpLargeNumbers then local ok, s = pcall(BreakUpLargeNumbers, v); if ok and s ~= nil then return s end end
        return v
    end
    local hs, ms, as = Fmt(h), Fmt(m), (okA and a ~= nil) and Fmt(a) or nil
    local ok
    -- the game's helpers for hidden numbers: blank when zero, and wrap only if not blank
    local SU = C_StringUtil
    if as ~= nil and not CONFIG.SHOW_ZERO and SU and SU.TruncateWhenZero and SU.WrapString then
        local okT, t = pcall(SU.TruncateWhenZero, a)
        local okW, w = false, nil
        if okT then okW, w = pcall(SU.WrapString, t, " " .. c .. "+ ", "|r") end
        if okW and w ~= nil then
            if CONFIG.SHOW_MAX then ok = pcall(fs.SetFormattedText, fs, "%s / %s%s", hs, ms, w)
            else ok = pcall(fs.SetFormattedText, fs, "%s%s", hs, w) end
            if ok then mode = "numbers hidden, shown by the game (no \"+ 0\")"; return end
        end
    end
    if as ~= nil then
        if CONFIG.SHOW_MAX then ok = pcall(fs.SetFormattedText, fs, "%s / %s " .. c .. "+ %s|r", hs, ms, as)
        else ok = pcall(fs.SetFormattedText, fs, "%s " .. c .. "+ %s|r", hs, as) end
    else
        ok = pcall(fs.SetFormattedText, fs, "%s", hs)
    end
    if ok then mode = "numbers hidden, shown by the game (\"+ 0\" can't be hidden)"; return end
    -- 3) can't show it
    fs:SetText("")
    mode = "numbers hidden and can't be shown"
end

-- ---------------------------------------------------------------- events
local ev = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "UNIT_HEALTH", "UNIT_MAXHEALTH",
                     "UNIT_ABSORB_AMOUNT_CHANGED", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "UI_SCALE_CHANGED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, a1)
    if event == "ADDON_LOADED" then
        if a1 == ADDON then
            HealthPlusShieldDB = HealthPlusShieldDB or {}
            DB = HealthPlusShieldDB
            DB.cfg = DB.cfg or {}
            if DB.cfg.FONT == "auto" then DB.cfg.FONT = nil end
            for k, v in pairs(DB.cfg) do if CONFIG[k] ~= nil then CONFIG[k] = v end end
        end
        return
    end
    if (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_ABSORB_AMOUNT_CHANGED") and a1 ~= "player" then return end
    if event == "PLAYER_ENTERING_WORLD" or event == "UI_SCALE_CHANGED" then pcall(Place) end
    pcall(Update)
end)
-- a slow backup refresh (also follows the frame if Edit Mode resizes it)
local acc = 0
holder:SetScript("OnUpdate", function(_, el)
    acc = acc + el
    if acc < 0.25 then return end
    acc = 0
    if bar then
        local okB, bs = pcall(bar.GetEffectiveScale, bar)
        local okU, us = pcall(UIParent.GetEffectiveScale, UIParent)
        if okB and okU and Num(bs) and Num(us) and us > 0 and math.abs(holder:GetScale() - bs / us) > 0.001 then holder:SetScale(bs / us) end
    end
    pcall(Update)
end)

-- ---------------------------------------------------------------- commands
local function Set(k, v) CONFIG[k] = v; if DB then DB.cfg[k] = v end; pcall(Place); pcall(Update) end
SLASH_HEALTHPLUSSHIELD1 = "/hps"
SlashCmdList["HEALTHPLUSSHIELD"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", "")
    if msg == "max" then Set("SHOW_MAX", not CONFIG.SHOW_MAX); Say("max health " .. (CONFIG.SHOW_MAX and "shown" or "hidden")); return end
    if msg == "zero" then Set("SHOW_ZERO", not CONFIG.SHOW_ZERO); Say("\"+ 0\" " .. (CONFIG.SHOW_ZERO and "shown" or "hidden")); return end
    local n = tonumber(msg:match("^size%s+(%d+)"))
    if n then Set("FONT_SIZE", n == 0 and 0 or math.max(8, math.min(24, n))); Say(CONFIG.FONT_SIZE == 0 and "size: same as the frame" or ("size " .. CONFIG.FONT_SIZE)); return end
    for dir, d in pairs({ up = { 0, 1 }, down = { 0, -1 }, left = { -1, 0 }, right = { 1, 0 } }) do
        if msg == dir then Set("X", CONFIG.X + d[1]); Set("Y", CONFIG.Y + d[2]); return end
    end
    if msg == "help" then
        Say("/hps  status;  /hps max  show max health;  /hps zero  show \"+ 0\";  /hps size 13")
        Say("/hps up|down|left|right  nudge the text 1 pixel")
        return
    end
    local found = bar and "found" or "not found"
    Say(("health bar %s; %s"):format(found, mode))
    local okT, txt = pcall(fs.GetText, fs)
    Say(("on %s; font %s; text %s; shown %s"):format(diag.anchor, diag.font,
        (okT and type(txt) == "string" and not Secret(txt)) and ("\"" .. txt:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") .. "\"") or "(hidden value)",
        tostring(holder:IsVisible())))
    Say("type /hps help for the commands")
end

-- ---------------------------------------------------------------- options for Jaff's Better Forever UI
local function Opt(t, key) t.get = function() return CONFIG[key] end; t.set = function(v) Set(key, v) end; return t end
local def = { addon = "HealthPlusShield", options = {
    { type = "note", label = "Your player frame's health text as health + shields (Power Word: Shield, Divine Aegis and other absorbs together)." },
    Opt({ type = "toggle", label = "Show max health (2,072 / 3,000 + 427)" }, "SHOW_MAX"),
    Opt({ type = "toggle", label = "Show \"+ 0\" with no shield" }, "SHOW_ZERO"),
    Opt({ type = "choice", label = "Font", choices = { { "Fonts\\ARIALN.TTF", "Arial Narrow (default)" },
        { "Fonts\\FRIZQT__.TTF", "Friz Quadrata (WoW)" }, { "Fonts\\skurri.ttf", "Skurri" }, { "Fonts\\MORPHEUS.ttf", "Morpheus" } } }, "FONT"),
    Opt({ type = "slider", label = "Text size (0 = same as the frame)", min = 0, max = 24, step = 1 }, "FONT_SIZE"),
    Opt({ type = "choice", label = "Outline", choices = { { "", "Same as the frame" }, { "OUTLINE", "Outline" }, { "THICKOUTLINE", "Thick" } } }, "OUTLINE"),
    Opt({ type = "choice", label = "Shield colour", choices = { { "99ddff", "Light blue" }, { "ffffff", "White" }, { "ffd24d", "Gold" } } }, "SHIELD_COLOR"),
} }
if JaffsUI and JaffsUI.Register then JaffsUI:Register(def)
else JaffsUI_Queue = JaffsUI_Queue or {}; table.insert(JaffsUI_Queue, def) end
