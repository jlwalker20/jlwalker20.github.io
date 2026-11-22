-- ManaRegen 0.4 (test)
-- 0.4: casts that cost no mana (wand, fishing, gathering, crafting, items) no longer start the five-second rule
-- 0.3: last-tick line removed: just regen and the five-second rule
-- 0.2: hidden numbers in combat read just "Combat"
-- A small movable readout:
--   Regen  12.5 /s       what you're regenerating right now (casting rate while the
--                        five-second rule is on, full rate once it's over)
--   5-sec rule  3.1      counting down after you spend mana, or "full regen"
-- The rate comes from the game (GetManaRegen).
-- Move it: Edit Mode unlocks it, or /mr unlock (drag), or /mr up|down|left|right.

local CONFIG = {
    UNIT        = "sec",   -- "sec" per second, "mp5" per 5 seconds, "tick" per 2-second tick
    SHOW_FSR    = true,    -- the five-second rule line
    SHOW_BOTH   = false,   -- also show the other rate in brackets (casting / full)
    HIDE_FULL   = false,   -- hide the readout while your mana is full
    FONT        = "Fonts\\FRIZQT__.TTF",
    FONT_SIZE   = 12,
    NUDGE       = 5,
}

local ADDON = ...
local DB
local function Say(m) print("|cff4fd8c4ManaRegen:|r " .. m) end
local function Secret(v) return issecretvalue and issecretvalue(v) end
local function Num(v) if type(v) == "number" and not Secret(v) then return v end end
local function InCombat() return InCombatLockdown and InCombatLockdown() end

-- ---------------------------------------------------------------- frame
local box = CreateFrame("Frame", "ManaRegenFrame", UIParent)
box:SetSize(150, 50)
box:SetMovable(true)
box:SetClampedToScreen(true)
box:RegisterForDrag("LeftButton")
box.bg = box:CreateTexture(nil, "BACKGROUND")
box.bg:SetAllPoints()
box.bg:SetColorTexture(0.05, 0.05, 0.06, 0.55)
box.lines = {}
for i = 1, 2 do
    local fs = box:CreateFontString(nil, "OVERLAY")
    fs:SetJustifyH("LEFT")
    box.lines[i] = fs
end
box.outline = box:CreateTexture(nil, "BORDER")
box.outline:SetPoint("TOPLEFT", box, "TOPLEFT", -3, 3)
box.outline:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", 3, -3)
box.outline:SetColorTexture(0.31, 0.85, 0.77, 0.35)
box.outline:Hide()

local function LoadPosition()
    box:ClearAllPoints()
    box:SetPoint("CENTER", UIParent, "CENTER", (DB and DB.x) or 260, (DB and DB.y) or -180)
end
local function SavePosition()
    if not DB then return end
    local x, y = box:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if x and ux then DB.x, DB.y = x - ux, y - uy end
end
box:SetScript("OnDragStart", function(self) if self.unlocked then self:StartMoving() end end)
box:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePosition(); LoadPosition() end)

local function SetUnlocked(on)
    box.unlocked = on and true or false
    box:EnableMouse(box.unlocked)
    if box.unlocked then box.outline:Show() else box.outline:Hide() end
end

local function Layout()
    local size = CONFIG.FONT_SIZE
    local y = -5
    local shown = 0
    for i, fs in ipairs(box.lines) do
        fs:SetFont(CONFIG.FONT, size, "OUTLINE")
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", box, "TOPLEFT", 7, y)
        local on = (i == 1) or (i == 2 and CONFIG.SHOW_FSR)
        if on then fs:Show(); y = y - (size + 4); shown = shown + 1 else fs:Hide() end
    end
    box:SetSize(math.max(150, size * 12), shown * (size + 4) + 10)
end

-- ---------------------------------------------------------------- state
local lastMana            -- last mana we could read
local fsrUntil = 0        -- five-second rule ends at
local debugCasts = false  -- /mr debug
local hiddenNote          -- why numbers can't be shown, if any

local function Mana()
    local okP, v = pcall(UnitPower, "player", 0)
    local okM, m = pcall(UnitPowerMax, "player", 0)
    return okP and Num(v), okM and Num(m)
end

local function Rates()
    if not GetManaRegen then return end
    local ok, base, casting = pcall(GetManaRegen)
    if not ok then return end
    return Num(base), Num(casting)
end

local function Scale(v)
    if not v then return nil end
    if CONFIG.UNIT == "mp5" then return v * 5, "/5s" end
    if CONFIG.UNIT == "tick" then return v * 2, "/tick" end
    return v, "/s"
end

local function Fmt(v)
    if v >= 100 then return ("%d"):format(math.floor(v + 0.5)) end
    if v >= 10 then return ("%.1f"):format(v) end
    return ("%.2f"):format(v)
end

-- ---------------------------------------------------------------- watching mana
local function OnPower()
    local cur, max = Mana()
    if not cur then hiddenNote = "mana hidden by the game right now"; return end
    if lastMana then
        if cur < lastMana then
            fsrUntil = GetTime() + 5            -- spent mana: five-second rule starts
            if debugCasts then Say(("mana dropped %d -> %d: 5-sec rule"):format(lastMana, cur)) end
        end
    end
    lastMana = cur
end

-- ---------------------------------------------------------------- which casts cost mana
-- Used when the game hides your mana and a cast is the only clue. The spell's own cost is
-- checked first; if that can't be read either, free actions are recognised by name.
local FREE_NAMES = { "Shoot", "Auto Shot", "Throw", "Attack", "Fishing", "Hearthstone", "Herb Gathering",
    "Mining", "Skinning", "Disenchant", "Opening", "Find Herbs", "Find Minerals", "Find Treasure",
    "Food", "Drink", "Refreshment", "Smelting", "Prospecting", "Basic Campfire", "Cooking", "First Aid" }
local function SpellName(id)
    if C_Spell and C_Spell.GetSpellName then local ok, n = pcall(C_Spell.GetSpellName, id); if ok and type(n) == "string" and not Secret(n) then return n end end
    if GetSpellInfo then local ok, n = pcall(GetSpellInfo, id); if ok and type(n) == "string" and not Secret(n) then return n end end
end

-- true = costs mana, false = free, nil = can't tell
local function CostsMana(id)
    local fn = (C_Spell and C_Spell.GetSpellPowerCost) or GetSpellPowerCost
    if not fn or type(id) ~= "number" or Secret(id) then return nil end
    local ok, costs = pcall(fn, id)
    if not ok or type(costs) ~= "table" or Secret(costs) then return nil end
    local sawAny = false
    for _, c in ipairs(costs) do
        sawAny = true
        local t, n, pct = c.type, c.cost, c.costPercent
        if (t == 0 or c.name == "MANA") and ((Num(n) or 0) > 0 or (Num(pct) or 0) > 0) then return true end
    end
    return false   -- no costs listed, or none in mana
end

local function FreeByName(name)
    if not name then return false end
    for _, f in ipairs(FREE_NAMES) do if name:find(f, 1, true) then return true end end
    return false
end

local function OnCast(id)
    local readable = Mana() ~= nil
    local costs = CostsMana(id)
    local name = SpellName(id)
    local reset
    if readable then reset = false                       -- mana drop does the work
    elseif costs ~= nil then reset = costs
    else reset = not FreeByName(name) end
    if reset then fsrUntil = GetTime() + 5 end
    if debugCasts then
        Say(("%s (%s): mana %s, costs mana %s -> %s"):format(name or "?", tostring(id),
            readable and "readable" or "hidden", costs == nil and "unknown" or (costs and "yes" or "no"),
            readable and "watching mana" or (reset and "5-sec rule" or "ignored")))
    end
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "UNIT_POWER_FREQUENT", "UNIT_POWER_UPDATE",
                     "UNIT_SPELLCAST_SUCCEEDED", "UNIT_DISPLAYPOWER" }) do pcall(ev.RegisterEvent, ev, e) end
ev:SetScript("OnEvent", function(_, event, a1, a2, ...)
    if event == "ADDON_LOADED" then
        if a1 == ADDON then
            ManaRegenDB = ManaRegenDB or {}
            DB = ManaRegenDB
            DB.cfg = DB.cfg or {}
            for k, v in pairs(DB.cfg) do if CONFIG[k] ~= nil then CONFIG[k] = v end end
            LoadPosition(); Layout()
        end
        return
    end
    if event == "UNIT_POWER_FREQUENT" or event == "UNIT_POWER_UPDATE" then
        if a1 == "player" and (a2 == nil or a2 == "MANA") then pcall(OnPower) end
        return
    end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- args: unit, castGUID, spellID
        if a1 == "player" then local id = ...; pcall(OnCast, id) end
        return
    end
    lastMana = nil; pcall(OnPower)
end)

-- ---------------------------------------------------------------- the readout
local acc = 0
box:SetScript("OnUpdate", function(_, el)
    acc = acc + el
    if acc < 0.1 then return end
    acc = 0
    local _, max = Mana()
    local okM, rawMax = pcall(UnitPowerMax, "player", 0)
    local hasMana = (max and max > 0) or (okM and Secret(rawMax))
    if not hasMana and not box.unlocked then box:SetAlpha(0); return end
    local cur = Mana()
    if CONFIG.HIDE_FULL and cur and max and cur >= max and not box.unlocked then box:SetAlpha(0); return end
    box:SetAlpha(1)

    local now = GetTime()
    local inFSR = now < fsrUntil
    local base, casting = Rates()
    local L1
    if base then
        local v, unit = Scale(inFSR and casting or base)
        L1 = ("|cff4fd8c4Regen|r  %s %s"):format(Fmt(v), unit)
        if CONFIG.SHOW_BOTH then
            local o = Scale(inFSR and base or casting)
            L1 = L1 .. ("  |cff888888(%s %s)|r"):format(Fmt(o), inFSR and "full" or "casting")
        end
    else
        L1 = "|cff4fd8c4Regen|r  " .. (GetManaRegen and "Combat" or "not on this client")
    end
    box.lines[1]:SetText(L1)
    if inFSR then
        box.lines[2]:SetText(("|cff4fd8c45-sec rule|r  |cffffd24d%.1f|r"):format(fsrUntil - now))
    else
        box.lines[2]:SetText("|cff4fd8c45-sec rule|r  |cff88ff88full regen|r")
    end
end)

-- Edit Mode opens -> unlock; closes -> lock
C_Timer.After(1, function()
    local em = _G.EditModeManagerFrame
    if em and em.HookScript then
        em:HookScript("OnShow", function() SetUnlocked(true) end)
        em:HookScript("OnHide", function() SetUnlocked(false) end)
    end
end)

-- ---------------------------------------------------------------- commands
SLASH_MANAREGEN1 = "/mr"
SlashCmdList["MANAREGEN"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", "")
    if msg == "unlock" or msg == "lock" or msg == "move" then
        SetUnlocked(not box.unlocked)
        Say(box.unlocked and "unlocked: drag it (or /mr up|down|left|right), then /mr unlock again" or "locked")
        return
    end
    for dir, d in pairs({ up = { 0, 1 }, down = { 0, -1 }, left = { -1, 0 }, right = { 1, 0 } }) do
        if msg == dir and DB then
            DB.x = (DB.x or 260) + d[1] * CONFIG.NUDGE; DB.y = (DB.y or -180) + d[2] * CONFIG.NUDGE
            LoadPosition(); return
        end
    end
    if msg == "debug" then debugCasts = not debugCasts; Say("cast report " .. (debugCasts and "on: cast things and watch chat" or "off")); return end
    if msg == "reset" then if DB then DB.x, DB.y = nil, nil end; LoadPosition(); Say("position reset"); return end
    local base, casting = Rates()
    Say(("full %s/s, casting %s/s; %s; GetManaRegen %s"):format(base and Fmt(base) or "?", casting and Fmt(casting) or "?",
        hiddenNote or "mana readable", GetManaRegen and "found" or "missing"))
    Say("/mr unlock, /mr up|down|left|right, /mr reset, /mr debug")
end

-- ---------------------------------------------------------------- options for Jaff's Better Forever UI
local DEFAULTS = {}
for k, v in pairs(CONFIG) do DEFAULTS[k] = v end
local function Opt(t, key)
    t.get = function() return CONFIG[key] end
    t.set = function(v) CONFIG[key] = v; if DB then DB.cfg[key] = v end; Layout() end
    return t
end
local def = { addon = "ManaRegen", options = {
    { type = "toggle", label = "Unlocked (move it)", get = function() return box.unlocked end, set = function(v) SetUnlocked(v) end },
    { type = "button", label = "Nudge up", button = "Up", func = function() SlashCmdList["MANAREGEN"]("up") end },
    { type = "button", label = "Nudge down", button = "Down", func = function() SlashCmdList["MANAREGEN"]("down") end },
    { type = "button", label = "Nudge left", button = "Left", func = function() SlashCmdList["MANAREGEN"]("left") end },
    { type = "button", label = "Nudge right", button = "Right", func = function() SlashCmdList["MANAREGEN"]("right") end },
    { type = "button", label = "Position", button = "Reset", func = function() SlashCmdList["MANAREGEN"]("reset") end },
    { type = "header", label = "What it shows" },
    Opt({ type = "choice", label = "Regen shown", choices = { { "sec", "Per second" }, { "mp5", "Per 5 seconds (MP5)" }, { "tick", "Per tick (2 s)" } } }, "UNIT"),
    Opt({ type = "toggle", label = "Also show the other rate", desc = "Casting rate while at full regen, and the other way round." }, "SHOW_BOTH"),
    Opt({ type = "toggle", label = "Five-second rule line" }, "SHOW_FSR"),
    Opt({ type = "toggle", label = "Hide while mana is full" }, "HIDE_FULL"),
    Opt({ type = "slider", label = "Text size", min = 8, max = 20, step = 1 }, "FONT_SIZE"),
    { type = "button", label = "Defaults", button = "Reset to defaults",
      func = function() for k, v in pairs(DEFAULTS) do CONFIG[k] = v end; if DB then DB.cfg = {} end; Layout() end },
} }
if JaffsUI and JaffsUI.Register then JaffsUI:Register(def)
else JaffsUI_Queue = JaffsUI_Queue or {}; table.insert(JaffsUI_Queue, def) end
