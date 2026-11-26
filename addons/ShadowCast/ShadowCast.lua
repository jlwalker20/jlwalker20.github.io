-- ShadowCast 0.2 (test)
-- 0.2: the layer follows the button's own rounded icon shape; a darker, bluer purple
-- Priests only. While you're in Shadowform, a dark blue-purple layer sits over the healing spells on
-- your action bars, so they stand out as the ones the form won't let you use.
-- The layer is our own texture on each button; nothing about the button itself is changed.

local ADDON = ...
local CONFIG = {
    COLOR = { 0.20, 0.06, 0.46 },   -- dark blue-purple
    INSET = 2,                      -- pixels in from the icon's edge when the button has no mask
    ALPHA = 0.55,
    SPELLS = { "Lesser Heal", "Heal", "Greater Heal", "Flash Heal", "Renew", "Prayer of Healing",
               "Binding Heal", "Circle of Healing", "Prayer of Mending", "Penance", "Desperate Prayer",
               "Holy Nova", "Lightwell", "Resurrection" },
    FORM_NAME = "Shadowform",
}
local DB
local function Say(m) print("|cffa070ffShadowCast:|r " .. m) end
local function Secret(v) return issecretvalue and issecretvalue(v) end
local function Str(v) if type(v) == "string" and not Secret(v) then return v end end
local function Num(v) if type(v) == "number" and not Secret(v) then return v end end

local okC, _, cls = pcall(UnitClass, "player")
if not (okC and cls == "PRIEST") then return end

local healSet = {}
local function RebuildSet() healSet = {}; for _, n in ipairs(CONFIG.SPELLS) do healSet[n] = true end end
RebuildSet()

-- ---------------------------------------------------------------- the buttons
local BAR_NAMES = { "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton",
                    "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button" }
local function Buttons()
    local list, seen = {}, {}
    local function add(b) if type(b) == "table" and not seen[b] and b.GetObjectType then seen[b] = true; list[#list + 1] = b end end
    if ActionBarButtonEventsFrame and type(ActionBarButtonEventsFrame.frames) == "table" then
        for _, b in pairs(ActionBarButtonEventsFrame.frames) do add(b) end
    end
    for _, base in ipairs(BAR_NAMES) do for i = 1, 12 do add(_G[base .. i]) end end
    return list
end

local layers = {}   -- button -> texture
local function Layer(b)
    local t = layers[b]
    if t then return t end
    local icon = b.icon or b.Icon or (b.GetName and b:GetName() and _G[b:GetName() .. "Icon"])
    local ok, tex = pcall(b.CreateTexture, b, nil, "OVERLAY", nil, 6)
    if not ok or not tex then return nil end
    -- the button's own icon mask gives the rounded shape; without one, pull in from the edges
    local mask = b.IconMask or (b.GetName and b:GetName() and _G[b:GetName() .. "IconMask"])
    local masked = false
    if mask and tex.AddMaskTexture then masked = pcall(tex.AddMaskTexture, tex, mask) end
    local i = masked and 0 or CONFIG.INSET
    local anchor = icon or b
    tex:SetPoint("TOPLEFT", anchor, "TOPLEFT", i, -i)
    tex:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -i, i)
    tex:SetColorTexture(CONFIG.COLOR[1], CONFIG.COLOR[2], CONFIG.COLOR[3], 1)
    tex:SetAlpha(0)
    layers[b] = tex
    return tex
end

local function SlotOf(b)
    local s = b.action
    if Num(s) then return s end
    if b.GetAttribute then local ok, a = pcall(b.GetAttribute, b, "action"); if ok and Num(a) then return a end end
    if b.CalculateAction then local ok, a = pcall(b.CalculateAction, b); if ok and Num(a) then return a end end
end

local function SpellOnSlot(slot)
    if not (slot and GetActionInfo) then return nil end
    local ok, kind, id = pcall(GetActionInfo, slot)
    if not ok or Secret(kind) or Secret(id) then return nil end
    if kind == "spell" and Num(id) then
        if C_Spell and C_Spell.GetSpellName then local o, n = pcall(C_Spell.GetSpellName, id); if o and Str(n) then return n end end
        if GetSpellInfo then local o, n = pcall(GetSpellInfo, id); if o and Str(n) then return n end end
    elseif kind == "macro" and GetActionText then
        -- a macro: use the spell it casts if the game says
        if GetMacroSpell and Num(id) then
            local o, sid = pcall(GetMacroSpell, id)
            if o and Num(sid) and C_Spell and C_Spell.GetSpellName then local o2, n = pcall(C_Spell.GetSpellName, sid); if o2 then return Str(n) end end
        end
    end
end

-- ---------------------------------------------------------------- the form
local inForm = false
local function ReadForm()
    -- Shadowform is a shapeshift form for priests
    if GetShapeshiftForm then
        local ok, f = pcall(GetShapeshiftForm)
        if ok and Num(f) then
            if f == 0 then return false end
            if GetShapeshiftFormInfo then
                local o, _, active, _, spellID = pcall(GetShapeshiftFormInfo, f)
                if o and Num(spellID) and C_Spell and C_Spell.GetSpellName then
                    local o2, n = pcall(C_Spell.GetSpellName, spellID)
                    if o2 and Str(n) then return n == CONFIG.FORM_NAME end
                end
            end
            return true
        end
    end
    -- or as a buff
    if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName then
        local ok, a = pcall(C_UnitAuras.GetAuraDataBySpellName, "player", CONFIG.FORM_NAME, "HELPFUL")
        if ok and not Secret(a) then return a ~= nil end
    end
    return inForm   -- can't tell: keep what we had
end

local shown = 0
local function Refresh()
    inForm = ReadForm()
    shown = 0
    for _, b in ipairs(Buttons()) do
        local name = SpellOnSlot(SlotOf(b))
        local want = inForm and name and healSet[name]
        local t = layers[b] or Layer(b)   -- made for every button up front, not only mid-fight
        if t then
            t:SetColorTexture(CONFIG.COLOR[1], CONFIG.COLOR[2], CONFIG.COLOR[3], 1)
            t:SetAlpha(want and CONFIG.ALPHA or 0)
            if want then shown = shown + 1 end
        end
    end
end

-- ---------------------------------------------------------------- events
local pending = false
local function Soon()
    if pending then return end
    pending = true
    C_Timer.After(0.05, function() pending = false; pcall(Refresh) end)
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_FORMS",
                     "ACTIONBAR_SLOT_CHANGED", "ACTIONBAR_PAGE_CHANGED", "UPDATE_BONUS_ACTIONBAR", "ACTIONBAR_UPDATE_STATE",
                     "SPELLS_CHANGED", "PLAYER_REGEN_ENABLED" }) do pcall(ev.RegisterEvent, ev, e) end
pcall(ev.RegisterUnitEvent, ev, "UNIT_AURA", "player")
ev:SetScript("OnEvent", function(_, event, a1)
    if event == "ADDON_LOADED" then
        if a1 == ADDON then
            ShadowCastDB = ShadowCastDB or {}
            DB = ShadowCastDB
            if type(DB.alpha) == "number" then CONFIG.ALPHA = DB.alpha end
        end
        return
    end
    Soon()
end)
-- buttons that change their own spell (paging, drag and drop)
if ActionButton_Update then hooksecurefunc("ActionButton_Update", Soon) end

-- ---------------------------------------------------------------- commands and options
SLASH_SHADOWCAST1 = "/sc"
SlashCmdList["SHADOWCAST"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", "")
    local n = tonumber(msg:match("^alpha%s+([%d%.]+)"))
    if n then CONFIG.ALPHA = math.max(0.1, math.min(1, n > 1 and n / 100 or n)); if DB then DB.alpha = CONFIG.ALPHA end; Refresh(); Say(("layer strength %d%%"):format(CONFIG.ALPHA * 100)); return end
    if msg == "help" then Say("/sc  status;  /sc alpha 55  layer strength (10-100)"); return end
    Refresh()
    Say(("Shadowform: %s; %d buttons checked; %d covered"):format(inForm and "on" or "off", #Buttons(), shown))
end

local def = { addon = "ShadowCast", options = {
    { type = "note", label = "While you're in Shadowform, healing spells on your action bars get a dark blue-purple layer." },
    { type = "slider", label = "Layer strength", min = 0.1, max = 1, step = 0.05, format = "%.2f",
      get = function() return CONFIG.ALPHA end,
      set = function(v) CONFIG.ALPHA = v; if DB then DB.alpha = v end; pcall(Refresh) end },
} }
if JaffsUI and JaffsUI.Register then JaffsUI:Register(def)
else JaffsUI_Queue = JaffsUI_Queue or {}; table.insert(JaffsUI_Queue, def) end
