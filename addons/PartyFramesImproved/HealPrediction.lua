-- PartyFramesImproved: incoming heals and shields
-- A bar that starts where the member's health ends and shows heals on the
-- way to them. It is allowed to run past the frame's right edge (up to one
-- frame width), so overhealing shows too. Shields go after it.
--
-- Needs the game to give addons incoming-heal numbers (UnitGetIncomingHeals)
-- and, for shield amounts, UnitGetTotalAbsorbs. If those don't exist on this
-- client the bars simply never show; /pfi debug says which ones exist.
-- Without an absorb amount, a small shield icon marks Power Word: Shield.
--
-- Our own bars, laid over Blizzard's; made out of combat. Numbers are passed
-- to the bar as-is (no maths on them), so hidden combat values still draw.

local ADDON, ns = ...

local CONFIG = {
    HEAL_COLOR   = { 0.0, 0.9, 0.4, 0.55 },
    SHIELD_COLOR = { 1.0, 1.0, 1.0, 0.55 },
    SHIELD_ICON  = true,      -- icon at the health end when PW:S is up (no absorb API)
    SHIELD_NAMES = { "Power Word: Shield" },
    -- bar look: nil = copy the health bar's own texture (falls back to flat)
    TEXTURE      = nil,
}

local FLAT = "Interface\\Buttons\\WHITE8X8"

local DB
local function Say(m) print("|cff9999ffPFI:|r " .. m) end
local function Secret(v) return issecretvalue and issecretvalue(v) end
local function InCombat() return InCombatLockdown and InCombatLockdown() end
local HAS_HEALS   = type(UnitGetIncomingHeals) == "function"
local HAS_ABSORBS = type(UnitGetTotalAbsorbs) == "function"

local bars = {}
local STRATA = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG" }

local function HealthBar(f)
    local hb = rawget(f, "healthBar")
    if type(hb) == "table" and hb.GetStatusBarTexture and not (hb.IsForbidden and hb:IsForbidden()) then return hb end
end

local function BarTexture(hb)
    if CONFIG.TEXTURE then return CONFIG.TEXTURE end
    local fill = hb.GetStatusBarTexture and hb:GetStatusBarTexture()
    if fill and fill.GetTexture then
        local ok, t = pcall(fill.GetTexture, fill)
        if ok and t ~= nil and not Secret(t) then return t end
    end
    return FLAT
end

local function MakeBar(parent, anchorTex, color, strata)
    local b = CreateFrame("StatusBar", nil, UIParent)
    b:SetFrameStrata(strata)
    b:SetStatusBarTexture(BarTexture(parent))
    b:SetStatusBarColor(color[1], color[2], color[3], color[4])
    b:SetPoint("TOPLEFT", anchorTex, "TOPRIGHT", 0, 0)
    b:SetPoint("BOTTOMLEFT", anchorTex, "BOTTOMRIGHT", 0, 0)
    b:SetWidth(parent:GetWidth())   -- same scale as the health bar: one full bar of room
    b:SetMinMaxValues(0, 1); b:SetValue(0)
    b:Hide()
    return b
end

local function Make(f, hb)
    local okS, st = pcall(f.GetFrameStrata, f)
    local strata = "MEDIUM"
    if okS then for i, n in ipairs(STRATA) do if n == st then strata = STRATA[math.min(i + 1, #STRATA)] end end end
    local fill = hb:GetStatusBarTexture()
    if not fill then return end
    local set = {}
    set.heal = MakeBar(hb, fill, CONFIG.HEAL_COLOR, strata)
    set.shield = MakeBar(hb, set.heal:GetStatusBarTexture(), CONFIG.SHIELD_COLOR, strata)
    set.icon = set.heal:CreateTexture(nil, "OVERLAY")
    set.icon:SetTexture("Interface\\Icons\\Spell_Holy_PowerWordShield")
    set.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    set.icon:SetSize(12, 12)
    set.icon:SetPoint("CENTER", fill, "RIGHT", 0, 0)
    set.icon:Hide()
    set.hb = hb
    return set
end

local function HasShieldAura(unit)
    for i = 1, 40 do
        local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
        if not ok or not a then return false end
        local n = a.name
        if n ~= nil and not Secret(n) then
            for _, w in ipairs(CONFIG.SHIELD_NAMES) do if n == w then return true end end
        end
    end
    return false
end

local lastNote = {}

local function UpdateFrame(f)
    if f.IsForbidden and f:IsForbidden() then return end
    local set = bars[f]
    if not set then
        if InCombat() then return end
        local hb = HealthBar(f)
        if not hb then return end
        set = Make(f, hb); if not set then return end
        bars[f] = set
    end
    local unit = f.displayedUnit or f.unit
    local on = type(unit) == "string" and not Secret(unit) and f:IsVisible() and not (DB and DB.off)
    if not on then set.heal:Hide(); set.shield:Hide(); set.icon:Hide(); return end
    if not InCombat() then pcall(set.heal.SetWidth, set.heal, set.hb:GetWidth()); pcall(set.shield.SetWidth, set.shield, set.hb:GetWidth()) end

    local okM, maxHP = pcall(UnitHealthMax, unit)
    if HAS_HEALS and okM and maxHP ~= nil then
        local okI, inc = pcall(UnitGetIncomingHeals, unit)
        if okI and inc ~= nil then
            pcall(set.heal.SetMinMaxValues, set.heal, 0, maxHP)
            pcall(set.heal.SetValue, set.heal, inc)
            set.heal:Show()
            lastNote[f] = Secret(inc) and "incoming (hidden number, drawn)" or ("incoming " .. tostring(inc))
        else set.heal:Hide(); lastNote[f] = "no incoming value" end
    else
        set.heal:Hide(); lastNote[f] = HAS_HEALS and "no max health" or "no heal API"
    end
    -- the shield bar starts where the heal bar's fill ends, so it needs the heal bar running
    if HAS_ABSORBS and okM and maxHP ~= nil then
        if not set.heal:IsShown() then pcall(set.heal.SetMinMaxValues, set.heal, 0, 1); pcall(set.heal.SetValue, set.heal, 0); set.heal:Show() end
        local okA, ab = pcall(UnitGetTotalAbsorbs, unit)
        if okA and ab ~= nil then
            pcall(set.shield.SetMinMaxValues, set.shield, 0, maxHP)
            pcall(set.shield.SetValue, set.shield, ab)
            set.shield:Show()
        else set.shield:Hide() end
        set.icon:Hide()
    else
        set.shield:Hide()
        local show = CONFIG.SHIELD_ICON and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex and HasShieldAura(unit)
        if show then
            if not set.heal:IsShown() then pcall(set.heal.SetValue, set.heal, 0); set.heal:Show() end
            set.icon:Show()
        else set.icon:Hide() end
    end
end

local function UpdateAll()
    if not ns.Frames then return end
    for _, f in ipairs(ns.Frames()) do pcall(UpdateFrame, f) end
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "PLAYER_REGEN_ENABLED",
                     "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_HEAL_PREDICTION", "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_AURA" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then DB = ns.Section("heals") end
        return
    end
    UpdateAll()
end)
C_Timer.NewTicker(0.25, UpdateAll)

ns.HealsCmd = function(msg)
    if not DB then return end
    if msg == "debug" then
        Say(("heals: incoming-heal API %s, absorb API %s%s"):format(HAS_HEALS and "yes" or "NO",
            HAS_ABSORBS and "yes" or "no (shield icon instead)", DB.off and ", turned OFF" or ""))
        for f, set in pairs(bars) do
            local unit = f.displayedUnit or f.unit
            if type(unit) == "string" and f:IsVisible() then
                Say(("  %s: %s%s"):format(unit, lastNote[f] or "-", set.icon:IsShown() and ", shield icon" or ""))
            end
        end
        return
    end
    DB.off = not DB.off; UpdateAll()
    Say(DB.off and "heal bars off" or "heal bars on")
end
