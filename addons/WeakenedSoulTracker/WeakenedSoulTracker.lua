-- WeakenedSoulTracker 0.6 (test)
-- 0.6: names in class color
-- 0.5: /ws help
-- 0.4: three named spots (position + grow direction each), switch with /ws spot
-- 0.3: /ws grow switches between growing right and growing left
-- 0.2: no black corners: tighter portrait crop, thin edge instead of a black backing; SHAPE option
-- One cooldown-style icon per player you shield: their portrait, a cooldown
-- sweep and a countdown until Weakened Soul wears off and you can shield
-- them again. The icons sit in a bar you can move (it unlocks with Edit Mode,
-- or /ws unlock; on gamepad use the nudge macros).
--
-- How it knows: it watches YOUR Power Word: Shield casts (who it was cast on)
-- and starts a timer. It does not need to read auras, because Forever hides
-- aura details from addons in combat. When the aura CAN be read (out of combat)
-- the timer is corrected to the real time left.
--
-- Macros (made if you have free account slots):
--   WS Unlock  /ws unlock   show the bar's outline so you can drag / nudge it
--   WS Test    /ws test     three sample icons for 15 seconds

local CONFIG = {
    SHIELD_NAMES  = { "Power Word: Shield" },   -- the spell that causes it
    DEBUFF_NAME   = "Weakened Soul",
    DURATION      = 15,       -- seconds, used until the real time can be read [Classic value]
    ICON_SIZE     = 38,
    SPACING       = 5,
    GROW          = "RIGHT",  -- "RIGHT", "LEFT", "UP" or "DOWN"
    ICON_STYLE    = "portrait",   -- "portrait" (their face) or "class" (class icon)
    SHAPE         = "square", -- "square" or "round" (round fits portraits perfectly)
    PORTRAIT_CROP = 0.17,     -- how much of the round portrait's edge to cut (square shape)
    BORDER        = true,     -- thin dark edge around square icons
    SHOW_NAME     = true,     -- short name under each icon
    CLASS_COLOR   = true,     -- color the name by the player's class
    NAME_LENGTH   = 6,
    FONT          = "Fonts\\FRIZQT__.TTF",
    NUDGE         = 5,        -- pixels per nudge macro press
}

local ADDON = ...
local DB
local function Say(m) print("|cff9999ffWeakenedSoul:|r " .. m) end
local function Secret(v) return issecretvalue and issecretvalue(v) end
local function Str(v) return type(v) == "string" and not Secret(v) and v or nil end

-- ---------------------------------------------------------------- the bar
local bar = CreateFrame("Frame", "WeakenedSoulTrackerBar", UIParent)
bar:SetSize(CONFIG.ICON_SIZE, CONFIG.ICON_SIZE)
bar:SetMovable(true)
bar:SetClampedToScreen(true)
bar:RegisterForDrag("LeftButton")

-- the Edit-Mode style outline, shown only while unlocked
bar.box = CreateFrame("Frame", nil, bar)
bar.box:SetPoint("TOPLEFT", bar, "TOPLEFT", -4, 4)
bar.box:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 4, -4)
bar.box.bg = bar.box:CreateTexture(nil, "BACKGROUND")
bar.box.bg:SetAllPoints()
bar.box.bg:SetColorTexture(0.25, 0.55, 1, 0.25)
bar.box.edge = {}
for i, pts in ipairs({ { "TOPLEFT", "TOPRIGHT", nil, 2 }, { "BOTTOMLEFT", "BOTTOMRIGHT", nil, 2 },
                       { "TOPLEFT", "BOTTOMLEFT", 2, nil }, { "TOPRIGHT", "BOTTOMRIGHT", 2, nil } }) do
    local t = bar.box:CreateTexture(nil, "BORDER")
    t:SetColorTexture(0.35, 0.7, 1, 0.9)
    t:SetPoint(pts[1]); t:SetPoint(pts[2])
    if pts[3] then t:SetWidth(pts[3]) end
    if pts[4] then t:SetHeight(pts[4]) end
    bar.box.edge[i] = t
end
bar.box.label = bar.box:CreateFontString(nil, "OVERLAY")
bar.box.label:SetFont(CONFIG.FONT, 11, "OUTLINE")
bar.box.label:SetPoint("BOTTOM", bar.box, "TOP", 0, 2)
bar.box.label:SetText("Weakened Soul")
bar.box:Hide()

-- three saved spots, each with its own position and grow direction
local DEFAULT_SPOTS = { "Solo", "Party", "Raid" }
local function S()
    if not DB then return {} end
    DB.spots = DB.spots or {}
    for i = 1, 3 do
        DB.spots[i] = DB.spots[i] or { name = DEFAULT_SPOTS[i] }
    end
    if DB.x and not DB.spots[1].x then   -- carry over the old single position
        DB.spots[1].x, DB.spots[1].y, DB.spots[1].grow = DB.x, DB.y, DB.grow
    end
    DB.x, DB.y, DB.grow = nil, nil, nil
    local a = DB.active
    if a ~= 1 and a ~= 2 and a ~= 3 then DB.active = 1 end
    return DB.spots[DB.active]
end

local function SavePosition()
    if not DB then return end
    local x, y = bar:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if x and ux then local sp = S(); sp.x, sp.y = x - ux, y - uy end
end

local function LoadPosition()
    bar:ClearAllPoints()
    local sp = S()
    bar:SetPoint("CENTER", UIParent, "CENTER", sp.x or 0, sp.y or -150)
end

bar:SetScript("OnDragStart", function(self) if self.unlocked then self:StartMoving() end end)
bar:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePosition(); LoadPosition() end)

local function SetUnlocked(on)
    bar.unlocked = on and true or false
    if DB then bar.box.label:SetText("Weakened Soul: " .. (S().name or "?")) end
    bar:EnableMouse(bar.unlocked)
    if bar.unlocked then bar.box:Show() else bar.box:Hide() end
end

-- ---------------------------------------------------------------- icons
local icons, pool = {}, {}     -- icons: list of active { key=name, ... }

local function MakeIcon()
    local b = CreateFrame("Frame", nil, bar)
    b:SetSize(CONFIG.ICON_SIZE, CONFIG.ICON_SIZE)
    b.tex = b:CreateTexture(nil, "ARTWORK")
    b.tex:SetAllPoints(b)
    b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    b.cd:SetAllPoints(b)
    if b.cd.SetHideCountdownNumbers then b.cd:SetHideCountdownNumbers(true) end   -- we draw our own
    if b.cd.SetDrawEdge then b.cd:SetDrawEdge(false) end
    if CONFIG.SHAPE == "round" then
        -- a round mask on the picture, and a round sweep to match
        local okM, mask = pcall(b.CreateMaskTexture, b)
        if okM and mask then
            mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            mask:SetAllPoints(b)
            pcall(b.tex.AddMaskTexture, b.tex, mask)
        end
        if b.cd.SetSwipeTexture then pcall(b.cd.SetSwipeTexture, b.cd, "Interface\\CharacterFrame\\TempPortraitAlphaMask") end
    elseif CONFIG.BORDER then
        -- four thin edges (no filled backing, so nothing shows in the corners)
        for _, pts in ipairs({ { "TOPLEFT", "TOPRIGHT", nil, 1 }, { "BOTTOMLEFT", "BOTTOMRIGHT", nil, 1 },
                               { "TOPLEFT", "BOTTOMLEFT", 1, nil }, { "TOPRIGHT", "BOTTOMRIGHT", 1, nil } }) do
            local t = b:CreateTexture(nil, "OVERLAY")
            t:SetColorTexture(0, 0, 0, 0.85)
            t:SetPoint(pts[1]); t:SetPoint(pts[2])
            if pts[3] then t:SetWidth(pts[3]) end
            if pts[4] then t:SetHeight(pts[4]) end
        end
    end
    b.time = b.cd:CreateFontString(nil, "OVERLAY")
    b.time:SetFont(CONFIG.FONT, math.floor(CONFIG.ICON_SIZE * 0.42), "OUTLINE")
    b.time:SetPoint("CENTER", b, "CENTER", 0, 0)
    b.name = b:CreateFontString(nil, "OVERLAY")
    b.name:SetFont(CONFIG.FONT, 10, "OUTLINE")
    b.name:SetPoint("TOP", b, "BOTTOM", 0, -1)
    return b
end

local function UnitFor(name)
    if not name then return nil end
    local list = { "player", "target", "focus", "mouseover" }
    for i = 1, 4 do list[#list + 1] = "party" .. i end
    for i = 1, 40 do list[#list + 1] = "raid" .. i end
    for _, u in ipairs(list) do
        if UnitExists and UnitExists(u) then
            local ok, n = pcall(UnitName, u)
            if ok and Str(n) == name then return u end
        end
    end
end

local CLASS_ICONS = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"

local function SetFace(b, name)
    local u = UnitFor(name)
    b.tex:SetTexCoord(0, 1, 0, 1)
    if u and CONFIG.ICON_STYLE == "portrait" and SetPortraitTexture then
        if pcall(SetPortraitTexture, b.tex, u) then
            -- the portrait is round: for a square icon, cut in far enough that its
            -- corners are inside the circle (no dark corners)
            local c = (CONFIG.SHAPE == "round") and 0.02 or CONFIG.PORTRAIT_CROP
            b.tex:SetTexCoord(c, 1 - c, c, 1 - c)
            return
        end
    end
    local class
    if u then local ok, _, c = pcall(UnitClass, u); class = ok and Str(c) or nil end
    local tc = class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    if tc then
        b.tex:SetTexture(CLASS_ICONS); b.tex:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
    else
        b.tex:SetTexture("Interface\\Icons\\Spell_Holy_AshesToAshes")   -- Weakened Soul's own icon
        b.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)                        -- trim the icon's own frame
    end
end

local function Grow()
    local g = DB and S().grow
    if g == "RIGHT" or g == "LEFT" or g == "UP" or g == "DOWN" then return g end
    return CONFIG.GROW
end

local function Layout()
    table.sort(icons, function(a, b) return a.expires < b.expires end)
    local step = CONFIG.ICON_SIZE + CONFIG.SPACING + ((CONFIG.SHOW_NAME and (Grow() == "UP" or Grow() == "DOWN")) and 12 or 0)
    for i, e in ipairs(icons) do
        local b = e.frame
        b:ClearAllPoints()
        local k = i - 1
        if Grow() == "LEFT" then b:SetPoint("RIGHT", bar, "RIGHT", -k * step, 0)
        elseif Grow() == "UP" then b:SetPoint("BOTTOM", bar, "BOTTOM", 0, k * step)
        elseif Grow() == "DOWN" then b:SetPoint("TOP", bar, "TOP", 0, -k * step)
        else b:SetPoint("LEFT", bar, "LEFT", k * step, 0) end
        b:Show()
    end
end

local function Remove(i)
    local e = table.remove(icons, i)
    if e then e.frame:Hide(); pool[#pool + 1] = e.frame end
end

local function Start(name, duration, expires)
    if not name then return end
    local now = GetTime()
    duration = duration or CONFIG.DURATION
    expires = expires or (now + duration)
    local e
    for _, x in ipairs(icons) do if x.key == name then e = x end end
    if not e then
        local b = table.remove(pool) or MakeIcon()
        e = { key = name, frame = b }
        icons[#icons + 1] = e
    end
    e.expires, e.duration = expires, duration
    SetFace(e.frame, name)
    e.frame.name:SetText(CONFIG.SHOW_NAME and name:sub(1, CONFIG.NAME_LENGTH) or "")
    -- class color (remembered, in case they leave the group before it ends)
    local u = UnitFor(name)
    if u then local ok, _, c = pcall(UnitClass, u); if ok and Str(c) then e.class = c end end
    local col = CONFIG.CLASS_COLOR and e.class and ((C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(e.class))
        or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[e.class]))
    if col then e.frame.name:SetTextColor(col.r, col.g, col.b) else e.frame.name:SetTextColor(1, 1, 1) end
    e.frame.cd:SetCooldown(expires - duration, duration)
    Layout()
end

-- countdown text + removal
local tick = 0
bar:SetScript("OnUpdate", function(_, el)
    tick = tick + el
    if tick < 0.1 then return end
    tick = 0
    local now, changed = GetTime(), false
    for i = #icons, 1, -1 do
        local left = icons[i].expires - now
        if left <= 0 then Remove(i); changed = true
        else icons[i].frame.time:SetText(left >= 10 and tostring(math.floor(left + 0.5)) or ("%.1f"):format(left)) end
    end
    if changed then Layout() end
end)

-- ---------------------------------------------------------------- reading the real debuff (when allowed)
local function ReadDebuff(unit)
    if not (unit and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return end
    for i = 1, 40 do
        local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HARMFUL")
        if not ok then return end
        local okN, isNil = pcall(function() return a == nil end)
        if not okN or isNil or Secret(a) then return end
        local okF, n, dur, exp = pcall(function() return a.name, a.duration, a.expirationTime end)
        if okF and Str(n) == CONFIG.DEBUFF_NAME and not Secret(dur) and not Secret(exp)
           and type(dur) == "number" and type(exp) == "number" and dur > 0 then
            return dur, exp
        end
    end
end

local function Correct(name)
    local u = UnitFor(name)
    local dur, exp = ReadDebuff(u)
    if dur then
        Start(name, dur, exp)
        if DB then DB.lastRead = dur end
        CONFIG.DURATION = dur
        return true
    end
end

-- ---------------------------------------------------------------- your casts
local pendingTarget = {}    -- castGUID -> target name
local lastNote = "no shield cast seen yet"

local function IsShield(spellID)
    if spellID == nil or Secret(spellID) then return nil end
    local name
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
        name = ok and info and Str(info.name)
    end
    if not name and GetSpellInfo then
        local ok, n = pcall(GetSpellInfo, spellID)
        name = ok and Str(n)
    end
    if not name then return nil end
    for _, s in ipairs(CONFIG.SHIELD_NAMES) do if name == s then return true end end
    return false
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED",
                     "UNIT_AURA", "PLAYER_REGEN_ENABLED" }) do pcall(ev.RegisterEvent, ev, e) end
ev:SetScript("OnEvent", function(_, event, a1, a2, a3, a4)
    if event == "ADDON_LOADED" then
        if a1 == ADDON then
            WeakenedSoulTrackerDB = WeakenedSoulTrackerDB or {}
            DB = WeakenedSoulTrackerDB
            if DB.lastRead then CONFIG.DURATION = DB.lastRead end   -- learned from a real read
            LoadPosition()
        end
        return
    end
    if event == "UNIT_SPELLCAST_SENT" then
        -- unit, target name, castGUID, spellID
        if a1 ~= "player" then return end
        if IsShield(a4) == false then return end
        local guid = (not Secret(a3)) and a3 or nil
        local target = Str(a2)
        if target == "" or target == nil then
            -- no name given: self-cast or a gamepad / soft target cast
            local ok, n = pcall(UnitName, "target")
            target = (ok and Str(n)) or nil
            if not target or (UnitCanAssist and not select(2, pcall(UnitCanAssist, "player", "target"))) then
                local okP, me = pcall(UnitName, "player"); target = okP and Str(me) or nil
            end
        end
        if guid then pendingTarget[guid] = target end
        lastNote = "shield sent at " .. tostring(target)
        return
    end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- unit, castGUID, spellID
        if a1 ~= "player" then return end
        local shield = IsShield(a3)
        if shield == false then return end
        local guid = (not Secret(a2)) and a2 or nil
        local target = guid and pendingTarget[guid]
        if guid then pendingTarget[guid] = nil end
        if shield == nil and not target then lastNote = "a cast's spell was hidden by the game"; return end
        if not target then lastNote = "shield landed, but the game hid who it was on"; return end
        Start(target)
        lastNote = "shield landed on " .. target .. " (" .. (shield and "spell read" or "spell hidden, matched by cast") .. ")"
        C_Timer.After(0.3, function() Correct(target) end)
        return
    end
    if event == "UNIT_AURA" or event == "PLAYER_REGEN_ENABLED" then
        -- out of combat the real time left can be read: tidy up
        if InCombatLockdown and InCombatLockdown() then return end
        for _, e in ipairs(icons) do if not e.test then pcall(Correct, e.key) end end
    end
end)

-- Edit Mode opens -> unlock; closes -> lock
local function HookEditMode()
    local em = _G.EditModeManagerFrame
    if em and em.HookScript and not bar.emHooked then
        bar.emHooked = true
        em:HookScript("OnShow", function() SetUnlocked(true) end)
        em:HookScript("OnHide", function() SetUnlocked(false) end)
    end
end
C_Timer.After(1, HookEditMode)

-- ---------------------------------------------------------------- commands
local HELP = {
    "/ws               status: spot, icons, last cast seen",
    "/ws help          this list",
    "/ws unlock        unlock / lock the bar to drag it (Edit Mode does this too)",
    "/ws up | down | left | right   nudge the bar 5 pixels",
    "/ws reset         put the bar back near the middle",
    "/ws grow          icons grow to the right / to the left",
    "/ws spot          switch to the next saved spot (1 > 2 > 3)",
    "/ws spot 2        jump to spot 2",
    "/ws spots         list the three spots (> = in use)",
    "/ws name <name>   rename the spot you're on",
    "/ws test          three sample icons",
    "/ws clear         remove all icons",
}

SLASH_WEAKENEDSOULTRACKER1 = "/ws"
SlashCmdList["WEAKENEDSOULTRACKER"] = function(raw)
    local msg = (raw or ""):lower():gsub("^%s+", "")
    if msg:find("unlock") or msg == "lock" or msg == "move" then
        SetUnlocked(not bar.unlocked)
        Say(bar.unlocked and "unlocked: drag the blue box (or use the nudge macros), then /ws unlock again" or "locked")
        return
    end
    for dir, d in pairs({ up = { 0, 1 }, down = { 0, -1 }, left = { -1, 0 }, right = { 1, 0 } }) do
        if msg == dir then
            if not DB then return end
            local sp = S()
            sp.x = (sp.x or 0) + d[1] * CONFIG.NUDGE; sp.y = (sp.y or -150) + d[2] * CONFIG.NUDGE
            LoadPosition()
            return
        end
    end
    if msg:find("^help") or msg == "?" then
        for _, l in ipairs(HELP) do Say(l) end
        return
    end
    if msg:find("grow") then
        if not DB then return end
        local sp = S()
        sp.grow = (Grow() == "LEFT") and "RIGHT" or "LEFT"
        Layout()
        Say(sp.name .. ": " .. (sp.grow == "LEFT" and "icons grow to the left (first icon on the right)" or "icons grow to the right (first icon on the left)"))
        return
    end
    if msg:find("reset") then if DB then local sp = S(); sp.x, sp.y = 0, -150 end; LoadPosition(); Say("position reset"); return end
    if msg:find("^name") then
        if not DB then return end
        local new = (raw or ""):match("^%s*%S+%s+(.+)$")
        if not new or new == "" then Say("usage: /ws name Raid Left"); return end
        S().name = new:sub(1, 24)
        if bar.unlocked then SetUnlocked(true) end
        Say(("spot %d is now called %s"):format(DB.active, S().name))
        return
    end
    if msg:find("^spots") or msg:find("^list") then
        S()
        for i = 1, 3 do
            local sp = DB.spots[i]
            Say(("%s%d. %s (%s)"):format(i == DB.active and "> " or "  ", i, sp.name, (sp.grow or CONFIG.GROW):lower()))
        end
        return
    end
    if msg:find("^spot") then
        if not DB then return end
        local n = tonumber(msg:match("%d"))
        S()
        DB.active = (n and n >= 1 and n <= 3) and n or (DB.active % 3) + 1
        LoadPosition(); Layout()
        if bar.unlocked then SetUnlocked(true) end
        Say(("spot %d: %s"):format(DB.active, S().name))
        return
    end
    if msg:find("test") then
        local okP, me = pcall(UnitName, "player")
        local names = { Str(me) or "You", "Tank", "Healer" }
        for i, n in ipairs(names) do
            Start(n, CONFIG.DURATION, GetTime() + CONFIG.DURATION - (i - 1) * 4)
            for _, e in ipairs(icons) do if e.key == n then e.test = true end end
        end
        Say("three sample icons")
        return
    end
    if msg:find("clear") then for i = #icons, 1, -1 do Remove(i) end; Say("cleared"); return end
    Say(("debug: spot %d (%s); %d active; growing %s; duration %ss%s; last cast: %s; %s"):format(DB and DB.active or 1, DB and S().name or "?", #icons, Grow():lower(), tostring(CONFIG.DURATION),
        (DB and DB.lastRead) and " (read from the real debuff)" or " (default)", lastNote,
        bar.unlocked and "unlocked" or "locked"))
    Say("type /ws help for the list of commands")
end

local made = false
local mf = CreateFrame("Frame")
mf:RegisterEvent("PLAYER_ENTERING_WORLD")
mf:SetScript("OnEvent", function()
    HookEditMode()
    if made or (InCombatLockdown and InCombatLockdown()) then return end
    made = true
    if not (GetMacroIndexByName and CreateMacro and GetNumMacros) then return end
    pcall(function()
        for _, mk in ipairs({ { "WS Unlock", "/ws unlock" }, { "WS Test", "/ws test" } }) do
            local idx = GetMacroIndexByName(mk[1])
            if not (idx and idx > 0) and GetNumMacros() < (MAX_ACCOUNT_MACROS or 36) then
                pcall(CreateMacro, mk[1], "INV_MISC_QUESTIONMARK", mk[2], nil)
            end
        end
    end)
end)
