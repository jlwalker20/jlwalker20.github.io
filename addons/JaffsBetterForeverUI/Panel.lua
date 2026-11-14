-- Jaff's Better Forever UI: the panel
-- Our own window (no Blizzard templates, not on Blizzard's Esc list: both
-- caused trouble in controller mode before). Mouse: click anything.
-- Gamepad (when Blizzard's gamepad mode is on): D-pad up/down to pick an
-- option, left/right or A to change it, LB/RB to switch tabs, B to close.

local ADDON, ns = ...
local J = ns.J

local FONT = "Fonts\\FRIZQT__.TTF"
local COLORS = {
    bg     = { 0.07, 0.07, 0.08, 0.96 },
    edge   = { 0.35, 0.35, 0.37, 1 },
    side   = { 0.10, 0.10, 0.11, 1 },
    sel    = { 0.85, 0.70, 0.25, 0.25 },   -- gamepad / hover highlight
    tabOn  = { 0.85, 0.70, 0.25, 0.35 },
    text   = { 0.92, 0.92, 0.92 },
    dim    = { 0.62, 0.62, 0.62 },
    gold   = { 1.00, 0.82, 0.20 },
    sec    = { 0.55, 0.75, 1.00 },
}

local function Say(m) print("|cffe0b84aJaff's UI:|r " .. m) end
local function InCombat() return InCombatLockdown and InCombatLockdown() end

-- gamepad layout and controls are parked for now (finished at the end)
local GAMEPAD_READY = false

local function GamepadMode()
    if not GAMEPAD_READY then return false end
    if C_GamePad and C_GamePad.IsEnabled then
        local ok, v = pcall(C_GamePad.IsEnabled); if ok and v then return true end
    end
    if GetCVarBool then local ok, v = pcall(GetCVarBool, "GamePadEnable"); if ok and v then return true end end
    if GetCVar then local ok, v = pcall(GetCVar, "GamePadEnable"); if ok and v == "1" then return true end end
    return false
end

-- sizes for each input style
local STYLE = {
    mouse   = { w = 760, h = 500, side = 210, row = 28, font = 12, title = 15, tab = 24 },
    gamepad = { w = 900, h = 580, side = 240, row = 38, font = 15, title = 18, tab = 30 },
}

-- ---------------------------------------------------------------- small helpers
local function Fill(parent, layer, c)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
    return t
end

local function Edge(f, c)
    for _, pts in ipairs({ { "TOPLEFT", "TOPRIGHT", nil, 1 }, { "BOTTOMLEFT", "BOTTOMRIGHT", nil, 1 },
                           { "TOPLEFT", "BOTTOMLEFT", 1, nil }, { "TOPRIGHT", "BOTTOMRIGHT", 1, nil } }) do
        local t = f:CreateTexture(nil, "BORDER")
        t:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
        t:SetPoint(pts[1]); t:SetPoint(pts[2])
        if pts[3] then t:SetWidth(pts[3]) end
        if pts[4] then t:SetHeight(pts[4]) end
    end
end

local function Text(parent, size, c, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT, size, "")
    fs:SetTextColor(c[1], c[2], c[3])
    fs:SetJustifyH(justify or "LEFT")
    return fs
end

-- ---------------------------------------------------------------- state
local P = {}          -- the window and its parts
local style           -- STYLE.mouse or STYLE.gamepad
local tabs = {}       -- flat list: { name, section, def, notes, version }
local tabIndex = 1
local rows = {}       -- current tab's selectable rows (option tables)
local sel = 1         -- selected row (gamepad)
local scroll = 0
local needsReload = false
local sideScroll = 0

-- ---------------------------------------------------------------- building the window
local function Build()
    if P.frame then return end
    local f = CreateFrame("Frame", "JaffsUIPanel", UIParent)
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    Fill(f, "BACKGROUND", COLORS.bg):SetAllPoints()
    Edge(f, COLORS.edge)
    P.frame = f

    P.title = Text(f, 15, COLORS.gold)
    P.title:SetText("Jaff's Better Forever UI")

    -- close button (our own)
    local close = CreateFrame("Button", nil, f)
    close:SetSize(22, 22)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
    close.t = Text(close, 16, COLORS.dim, "CENTER"); close.t:SetAllPoints(); close.t:SetText("x")
    close:SetScript("OnClick", function() f:Hide() end)
    close:SetScript("OnEnter", function(s) s.t:SetTextColor(1, 1, 1) end)
    close:SetScript("OnLeave", function(s) s.t:SetTextColor(COLORS.dim[1], COLORS.dim[2], COLORS.dim[3]) end)

    -- left: tab list
    P.side = CreateFrame("Frame", nil, f)
    Fill(P.side, "BACKGROUND", COLORS.side):SetAllPoints()
    P.tabButtons, P.secLabels = {}, {}

    -- right: content
    P.content = CreateFrame("Frame", nil, f)
    P.head = Text(P.content, 16, COLORS.gold)
    P.notes = Text(P.content, 12, COLORS.dim)
    P.notes:SetWordWrap(true)
    P.rowFrames = {}
    P.content:EnableMouseWheel(true)
    P.content:SetScript("OnMouseWheel", function(_, d)
        scroll = math.max(0, scroll - d)
        ns.Refresh()
    end)

    -- footer
    P.hint = Text(f, 11, COLORS.dim)
    P.reload = CreateFrame("Button", nil, f)
    P.reload:SetSize(170, 22)
    P.reloadBg = Fill(P.reload, "BACKGROUND", { 0.20, 0.20, 0.22, 1 }); P.reloadBg:SetAllPoints()
    Edge(P.reload, COLORS.edge)
    P.reload.t = Text(P.reload, 12, { 1, 1, 1 }, "CENTER"); P.reload.t:SetAllPoints()
    P.reload:SetScript("OnClick", function() if ReloadUI then ReloadUI() end end)

    -- gamepad input (only while open, only out of combat)
    f:SetScript("OnGamePadButtonDown", function(_, button) ns.Pad(button) end)
    f:SetScript("OnShow", function() ns.CapturePad(true) end)
    f:SetScript("OnHide", function() ns.CapturePad(false) end)
end

function ns.CapturePad(on)
    local f = P.frame
    if not (f and f.EnableGamePadButton) then return end
    if on and not GamepadMode() then on = false end
    if InCombat() then return end
    pcall(f.EnableGamePadButton, f, on and true or false)
    if f.SetPropagateGamePadInput then pcall(f.SetPropagateGamePadInput, f, not on) end
end

-- ---------------------------------------------------------------- tab buttons
local function TabButton(i)
    local b = P.tabButtons[i]
    if b then return b end
    b = CreateFrame("Button", nil, P.side)
    b.bg = Fill(b, "BACKGROUND", COLORS.tabOn); b.bg:SetAllPoints(); b.bg:Hide()
    b.hl = Fill(b, "BORDER", COLORS.sel); b.hl:SetAllPoints(); b.hl:Hide()
    b.t = Text(b, 12, COLORS.text)
    b.t:SetPoint("LEFT", b, "LEFT", 14, 0)
    b:SetScript("OnEnter", function(s) s.hl:Show() end)
    b:SetScript("OnLeave", function(s) s.hl:Hide() end)
    b:SetScript("OnClick", function(s) tabIndex = s.index; sel = 1; scroll = 0; ns.Refresh() end)
    P.tabButtons[i] = b
    return b
end

local function SecLabel(i)
    local l = P.secLabels[i]
    if l then return l end
    l = Text(P.side, 11, COLORS.sec)
    P.secLabels[i] = l
    return l
end

-- ---------------------------------------------------------------- option rows
local function RowFrame(i)
    local r = P.rowFrames[i]
    if r then return r end
    r = CreateFrame("Button", nil, P.content)
    r.hl = Fill(r, "BACKGROUND", COLORS.sel); r.hl:SetAllPoints(); r.hl:Hide()
    r.label = Text(r, 12, COLORS.text)
    r.value = Text(r, 12, COLORS.gold, "CENTER")
    r.left = CreateFrame("Button", nil, r); r.left.t = Text(r.left, 14, COLORS.text, "CENTER"); r.left.t:SetAllPoints(); r.left.t:SetText("<")
    r.right = CreateFrame("Button", nil, r); r.right.t = Text(r.right, 14, COLORS.text, "CENTER"); r.right.t:SetAllPoints(); r.right.t:SetText(">")
    r.box = CreateFrame("Frame", nil, r)
    Edge(r.box, COLORS.edge)
    r.check = Fill(r.box, "ARTWORK", COLORS.gold)
    r.check:SetPoint("TOPLEFT", r.box, "TOPLEFT", 3, -3); r.check:SetPoint("BOTTOMRIGHT", r.box, "BOTTOMRIGHT", -3, 3)
    r.btn = CreateFrame("Frame", nil, r)
    Fill(r.btn, "BACKGROUND", { 0.20, 0.20, 0.22, 1 }):SetAllPoints()
    Edge(r.btn, COLORS.edge)
    r.btnText = Text(r.btn, 12, COLORS.text, "CENTER"); r.btnText:SetAllPoints()
    r:SetScript("OnEnter", function(s)
        if s.opt and s.opt.type ~= "header" and s.opt.type ~= "note" then s.hl:Show() end
        if s.opt and s.opt.desc and GameTooltip then
            GameTooltip:SetOwner(s, "ANCHOR_RIGHT"); GameTooltip:SetText(s.opt.label or "", 1, 0.82, 0.2)
            GameTooltip:AddLine(s.opt.desc, 0.9, 0.9, 0.9, true); GameTooltip:Show()
        end
    end)
    r:SetScript("OnLeave", function(s) if s.index ~= sel or not GamepadMode() then s.hl:Hide() end; if GameTooltip then GameTooltip:Hide() end end)
    r:SetScript("OnClick", function(s) if s.index then sel = s.index end; ns.Activate(s.opt, 0) end)
    r.left:SetScript("OnClick", function() ns.Activate(r.opt, -1) end)
    r.right:SetScript("OnClick", function() ns.Activate(r.opt, 1) end)
    P.rowFrames[i] = r
    return r
end

local function Selectable(o) return o and o.type ~= "header" and o.type ~= "note" end

local function Get(o)
    if not o.get then return nil end
    local ok, v = pcall(o.get); if ok then return v end
end

local function ChoiceIndex(o, v)
    for i, c in ipairs(o.choices or {}) do if c[1] == v then return i end end
    return 1
end

local function ValueText(o)
    local v = Get(o)
    if o.type == "slider" then
        if type(v) ~= "number" then return "?" end
        if o.format then return o.format:format(v) end
        return (o.step and o.step < 1) and ("%.2f"):format(v) or tostring(math.floor(v + 0.5))
    elseif o.type == "choice" then
        local c = o.choices and o.choices[ChoiceIndex(o, v)]
        return c and c[2] or tostring(v)
    end
    return ""
end

-- change an option: dir 0 = A / click, -1 / 1 = left / right
function ns.Activate(o, dir)
    if not Selectable(o) then return end
    local changed = false
    if o.type == "toggle" then
        if dir == 0 or dir ~= nil then pcall(o.set, not Get(o)); changed = true end
    elseif o.type == "slider" then
        local v = Get(o) or o.min
        local step = o.step or 1
        local d = (dir == 0) and 1 or dir
        v = v + d * step
        if dir == 0 and v > o.max then v = o.min end         -- A wraps around
        v = math.max(o.min, math.min(o.max, v))
        v = math.floor(v / step + 0.5) * step
        pcall(o.set, v); changed = true
    elseif o.type == "choice" then
        local n = #(o.choices or {})
        if n > 0 then
            local i = ChoiceIndex(o, Get(o)) + ((dir == 0) and 1 or dir)
            if i > n then i = 1 elseif i < 1 then i = n end
            pcall(o.set, o.choices[i][1]); changed = true
        end
    elseif o.type == "button" then
        if dir == 0 and o.func then pcall(o.func) end
    end
    if changed and o.reload then needsReload = true end
    ns.Refresh()
end

-- ---------------------------------------------------------------- layout
function ns.Refresh()
    local f = P.frame
    if not (f and f:IsShown()) then return end
    local pad = GamepadMode()
    style = pad and STYLE.gamepad or STYLE.mouse
    f:SetSize(style.w, style.h)
    P.title:SetFont(FONT, style.title, ""); P.title:ClearAllPoints(); P.title:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -12)

    -- tabs
    tabs = {}
    local groups = J:Tabs()
    for _, g in ipairs(groups) do for _, t in ipairs(g.tabs) do t.section = g.section; tabs[#tabs + 1] = t end end
    if tabIndex > #tabs then tabIndex = 1 end

    local top = 44
    P.side:ClearAllPoints()
    P.side:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -top)
    P.side:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 34)
    P.side:SetWidth(style.side)
    for _, b in ipairs(P.tabButtons) do b:Hide() end
    for _, l in ipairs(P.secLabels) do l:Hide() end
    -- the list: section labels and tabs, scrolled so the chosen tab is visible
    local entries = {}
    local lastSec
    for i, t in ipairs(tabs) do
        if t.section ~= lastSec then lastSec = t.section; entries[#entries + 1] = { sec = t.section } end
        entries[#entries + 1] = { tab = i }
    end
    local sideH = style.h - top - 34 - 8
    local fit = math.max(1, math.floor(sideH / style.tab))
    local selEntry = 1
    for k, e in ipairs(entries) do if e.tab == tabIndex then selEntry = k end end
    if selEntry - sideScroll > fit then sideScroll = selEntry - fit end
    if selEntry <= sideScroll then sideScroll = math.max(0, selEntry - 2) end
    sideScroll = math.max(0, math.min(sideScroll, #entries - fit))
    local y, nb, ns2 = -6, 0, 0
    for k = sideScroll + 1, math.min(#entries, sideScroll + fit) do
        local e = entries[k]
        if e.sec then
            ns2 = ns2 + 1
            local l = SecLabel(ns2)
            l:SetFont(FONT, style.font - 1, ""); l:SetText(e.sec:upper())
            l:ClearAllPoints(); l:SetPoint("TOPLEFT", P.side, "TOPLEFT", 10, y - math.floor(style.tab * 0.35)); l:Show()
        else
            local t = tabs[e.tab]
            nb = nb + 1
            local b = TabButton(nb)
            b.index = e.tab
            b:SetSize(style.side - 2, style.tab)
            b:ClearAllPoints(); b:SetPoint("TOPLEFT", P.side, "TOPLEFT", 1, y)
            b.t:SetFont(FONT, style.font, "")
            b.t:SetWidth(style.side - 24); b.t:SetWordWrap(false)
            b.t:SetText(t.name)
            -- addons without panel options are shown dimmer (the right side explains)
            local c = (t.def and t.loaded) and COLORS.text or COLORS.dim
            b.t:SetTextColor(c[1], c[2], c[3])
            if e.tab == tabIndex then b.bg:Show() else b.bg:Hide() end
            b:Show()
        end
        y = y - style.tab
    end
    P.sideMore = P.sideMore or Text(P.side, 11, COLORS.dim, "CENTER")
    P.sideMore:ClearAllPoints(); P.sideMore:SetPoint("BOTTOM", P.side, "BOTTOM", 0, 2)
    P.sideMore:SetText((sideScroll + fit < #entries) and "more below" or ((sideScroll > 0) and "more above" or ""))
    if not P.sideWheel then
        P.sideWheel = true
        P.side:EnableMouseWheel(true)
        P.side:SetScript("OnMouseWheel", function(_, d)
            -- the wheel over the tab list moves through the tabs
            tabIndex = math.max(1, math.min(#tabs, tabIndex - d)); sel, scroll = 1, 0
            ns.Refresh()
        end)
    end

    -- content
    P.content:ClearAllPoints()
    P.content:SetPoint("TOPLEFT", P.side, "TOPRIGHT", 14, 0)
    P.content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 34)
    for _, r in ipairs(P.rowFrames) do r:Hide() end
    local t = tabs[tabIndex]
    rows = {}
    if not t then
        P.head:SetText("None of the package's addons are installed")
        P.notes:SetText("Install them from walkerwagoner.com/addons.")
    else
        P.head:SetFont(FONT, style.title, "")
        P.head:SetText(t.name .. (t.version and ("  |cff999999v" .. t.version .. "|r") or ""))
        P.notes:SetFont(FONT, style.font - 1, "")
        P.notes:SetText(t.notes or "")
        -- every tab starts with the addon's own on/off switch
        rows[#rows + 1] = { type = "toggle", label = "Addon enabled", reload = true,
            desc = "Switches the whole addon on or off for this character, like the AddOns list. Takes effect after a reload.",
            get = function() return J:IsEnabled(t.loadedAs) end,
            set = function(v) J:SetEnabled(t.loadedAs, v) end }
        if not t.loaded then
            rows[#rows + 1] = { type = "note", text = "This addon is switched off, so its settings aren't available. Turn it on above and reload." }
        elseif t.def and type(t.def.options) == "table" then
            for _, o in ipairs(t.def.options) do rows[#rows + 1] = o end
        else
            rows[#rows + 1] = { type = "note", text = "This addon doesn't have options in the panel yet. They're coming in a later update; for now its settings are at the top of its .lua file." }
        end
    end
    P.head:ClearAllPoints(); P.head:SetPoint("TOPLEFT", P.content, "TOPLEFT", 0, 0)
    P.notes:ClearAllPoints(); P.notes:SetPoint("TOPLEFT", P.head, "BOTTOMLEFT", 0, -4)
    P.notes:SetWidth(style.w - style.side - 44)
    P.head:SetWidth(style.w - style.side - 44); P.head:SetWordWrap(false)

    -- keep the selection on a selectable row
    if #rows > 0 then
        if sel > #rows then sel = #rows end
        if sel < 1 then sel = 1 end
        if not Selectable(rows[sel]) then
            for i = sel, #rows do if Selectable(rows[i]) then sel = i; break end end
        end
    end
    local noteH = (P.notes.GetStringHeight and P.notes:GetStringHeight()) or 18
    if type(noteH) ~= "number" or noteH <= 0 then noteH = 18 end
    local listTop = style.title + 14 + ((t and t.notes) and noteH or 0)
    local avail = style.h - top - 34 - listTop - 10
    local per = math.max(1, math.floor(avail / style.row))
    if sel - scroll > per then scroll = sel - per end
    if sel <= scroll then scroll = math.max(0, sel - 1) end
    scroll = math.min(scroll, math.max(0, #rows - per))
    local cw = style.w - style.side - 30
    for i = 1, per do
        local idx = i + scroll
        local o = rows[idx]
        if not o then break end
        local r = RowFrame(i)
        r.opt, r.index = o, idx
        r:SetSize(cw, style.row)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", P.content, "TOPLEFT", 0, -listTop - (i - 1) * style.row)
        for _, w in ipairs({ r.left, r.right, r.box, r.btn, r.value }) do w:Hide() end
        r.label:SetFont(FONT, style.font, ""); r.value:SetFont(FONT, style.font, "")
        r.label:ClearAllPoints(); r.label:SetPoint("LEFT", r, "LEFT", 8, 0); r.label:SetWidth(cw - 200)
        r.label:SetWordWrap(o.type == "note")
        local c = (o.type == "header") and COLORS.sec or ((o.type == "note") and COLORS.dim or COLORS.text)
        r.label:SetTextColor(c[1], c[2], c[3])
        if o.type == "header" then
            r.label:SetText((o.label or ""):upper())
        elseif o.type == "note" then
            r.label:SetText(o.text or ""); r.label:SetWidth(cw - 16)
        else
            r.label:SetText((o.label or "") .. (o.reload and "  |cff999999(reload)|r" or ""))
        end
        local bw = style.row - 10
        if o.type == "toggle" then
            r.box:SetSize(bw - 6, bw - 6); r.box:ClearAllPoints(); r.box:SetPoint("RIGHT", r, "RIGHT", -12, 0); r.box:Show()
            if Get(o) then r.check:Show() else r.check:Hide() end
        elseif o.type == "slider" or o.type == "choice" then
            r.right:SetSize(bw, bw); r.right:ClearAllPoints(); r.right:SetPoint("RIGHT", r, "RIGHT", -6, 0); r.right:Show()
            r.value:SetWidth(130); r.value:ClearAllPoints(); r.value:SetPoint("RIGHT", r.right, "LEFT", -2, 0); r.value:Show()
            r.value:SetText(ValueText(o))
            r.left:SetSize(bw, bw); r.left:ClearAllPoints(); r.left:SetPoint("RIGHT", r.value, "LEFT", -2, 0); r.left:Show()
        elseif o.type == "button" then
            r.btn:SetSize(160, bw); r.btn:ClearAllPoints(); r.btn:SetPoint("RIGHT", r, "RIGHT", -6, 0); r.btn:Show()
            r.btnText:SetFont(FONT, style.font, ""); r.btnText:SetText(o.button or o.label or "Go")
        end
        if pad and idx == sel and Selectable(o) then r.hl:Show() else r.hl:Hide() end
        r:Show()
    end

    -- footer
    P.hint:SetFont(FONT, style.font - 1, "")
    P.hint:ClearAllPoints(); P.hint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 11)
    if pad then
        P.hint:SetText("D-pad: choose   Left/Right or A: change   LB / RB: tabs   B: close")
    else
        P.hint:SetText("Click to change   Mouse wheel: scroll   /jaffs to open or close")
    end
    P.reload:ClearAllPoints(); P.reload:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 7)
    P.reload.t:SetFont(FONT, style.font - 1, "")
    if needsReload then
        P.reload:SetSize(pad and 220 or 180, 24)
        P.reload.t:SetText(pad and "X: Reload now to apply" or "Reload now to apply")
        P.reloadBg:SetColorTexture(0.45, 0.18, 0.10, 1)
    else
        P.reload:SetSize(pad and 120 or 90, 24)
        P.reload.t:SetText(pad and "X: Reload" or "Reload")
        P.reloadBg:SetColorTexture(0.20, 0.20, 0.22, 1)
    end
    P.reload:Show()
    P.hint:SetWidth(style.w - (needsReload and 260 or 160))
    P.hint:SetWordWrap(false)
end

-- ---------------------------------------------------------------- gamepad
function ns.Pad(button)
    if button == "PAD2" or button == "PADBACK" then P.frame:Hide(); return end
    if button == "PADLSHOULDER" or button == "PADRSHOULDER" then
        if #tabs > 0 then
            tabIndex = tabIndex + (button == "PADRSHOULDER" and 1 or -1)
            if tabIndex > #tabs then tabIndex = 1 elseif tabIndex < 1 then tabIndex = #tabs end
            sel, scroll = 1, 0
        end
    elseif button == "PADDUP" or button == "PADDDOWN" then
        local d = (button == "PADDDOWN") and 1 or -1
        local i = sel
        for _ = 1, #rows do
            i = i + d
            if i > #rows then i = 1 elseif i < 1 then i = #rows end
            if Selectable(rows[i]) then sel = i; break end
        end
    elseif button == "PADDLEFT" then ns.Activate(rows[sel], -1); return
    elseif button == "PADDRIGHT" then ns.Activate(rows[sel], 1); return
    elseif button == "PAD1" then ns.Activate(rows[sel], 0); return
    elseif button == "PAD3" and ReloadUI then ReloadUI(); return
    end
    ns.Refresh()
end

-- ---------------------------------------------------------------- open / close
function JaffsUI_Toggle()
    Build()
    local f = P.frame
    if f:IsShown() then f:Hide(); return end
    f:ClearAllPoints(); f:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    f:Show()
    ns.Refresh()
    if InCombat() and GamepadMode() then Say("opened in combat: the controller can't steer the panel until combat ends") end
end
J.Toggle = JaffsUI_Toggle
J.OnRegister = function() if P.frame and P.frame:IsShown() then ns.Refresh() end end

-- gamepad steering can't be switched on in combat: catch up afterwards
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if P.frame and P.frame:IsShown() then ns.CapturePad(true) end
        return
    end
    -- one macro (slots are often full)
    if InCombat() or not (GetMacroIndexByName and CreateMacro and GetNumMacros) then return end
    pcall(function()
        local idx = GetMacroIndexByName("Jaffs UI")
        if not (idx and idx > 0) and GetNumMacros() < (MAX_ACCOUNT_MACROS or 36) then
            CreateMacro("Jaffs UI", "INV_Misc_Gear_01", "/jaffs", nil)
        end
    end)
end)

SLASH_JAFFSUI1 = "/jaffs"
SlashCmdList["JAFFSUI"] = function(msg)
    msg = (msg or ""):lower()
    if msg:find("debug") then
        local n, wired = 0, 0
        for _, g in ipairs(J:Tabs()) do for _, t in ipairs(g.tabs) do n = n + 1; if t.def then wired = wired + 1 end end end
        Say(("%d package addons installed, %d with options; input: %s; minimap addon button: %s"):format(n, wired,
            GamepadMode() and "gamepad" or "mouse", (AddonCompartmentFrame and "found") or "not on this client"))
        return
    end
    JaffsUI_Toggle()
end
