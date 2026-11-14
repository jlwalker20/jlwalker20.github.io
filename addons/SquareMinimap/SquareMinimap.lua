-- SquareMinimap 0.6 (test)
-- 0.6: /sqm frames lists the minimap's buttons; /sqm sun <number> picks the sun/moon
-- 0.5: sun-button move turned off (it was moving the calendar button)
-- 0.4: border outside DarkIronUI's reach (no flicker), edges/corners on separate layers;
--      sun button fixed at the top-right corner over the border; zoom buttons hug the border
-- 0.3: zoom buttons sit side by side under the bottom-right of the border
-- 0.2: Diamond metal / Dialog edge first; window-frame metal smaller; the sun
--      (day/night) button can be dragged anywhere around the map and clicked
-- Makes the minimap square and swaps the round ring for a square border built
-- from Blizzard's own metal frame pieces (corners stay sharp, edges stretch).
-- The border is tinted gray to match DarkIronUI.
--
-- Several border styles are tried; the ones whose art exists on this client
-- can be cycled with /sqm style. /sqm probe lists which exist.
--
-- Macros (made if you have free account slots):
--   SQM Style   /sqm style   next border style
--   SQM Debug   /sqm debug   what it found and hid

local CONFIG = {
    TINT       = { 0.55, 0.55, 0.55 },   -- gray, like DarkIronUI
    DESATURATE = true,
    SCALE      = 0.5,     -- size of the corner pieces (1 = Blizzard's full size)
    INSET      = 2,       -- how far the border overlaps the map edge
    HIDE_ROUND = true,    -- hide the round ring art
    NORTH      = true,    -- keep the north arrow, moved to the top of the square
    NORTH_Y    = 2,       -- how far above the top edge its center sits
    ZOOM       = true,    -- move the zoom buttons under the map, bottom right, side by side
    ZOOM_GAP   = 2,       -- space between the two buttons
    ZOOM_Y     = 3,       -- up/down from the border's outer bottom edge (+ = overlap it)
    ZOOM_X     = 0,       -- nudge sideways
    SUN        = false,   -- (off: on Forever this moved the calendar button, not the sun/moon)
    SUN_X      = -2, SUN_Y = -2,   -- nudge it from the corner (pixels)
}

-- border styles: atlas pieces (corners + edges), or a classic backdrop edge file
local STYLES = {
    { key = "diamond", label = "Diamond metal",
      corners = { "UI-Frame-DiamondMetal-CornerTopLeft", "UI-Frame-DiamondMetal-CornerTopRight",
                  "UI-Frame-DiamondMetal-CornerBottomLeft", "UI-Frame-DiamondMetal-CornerBottomRight" },
      edges = { "_UI-Frame-DiamondMetal-EdgeTop", "_UI-Frame-DiamondMetal-EdgeBottom",
                "!UI-Frame-DiamondMetal-EdgeLeft", "!UI-Frame-DiamondMetal-EdgeRight" } },
    { key = "dialog", label = "Dialog box edge", file = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24 },
    { key = "thin", label = "Thin tooltip edge", file = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 14 },
    { key = "generic", label = "Generic metal",
      corners = { "UI-Frame-GenericMetal-Corner", "UI-Frame-GenericMetal-Corner",
                  "UI-Frame-GenericMetal-Corner", "UI-Frame-GenericMetal-Corner" },
      flip = true,
      edges = { "_UI-Frame-GenericMetal-EdgeTop", "_UI-Frame-GenericMetal-EdgeBottom",
                "!UI-Frame-GenericMetal-EdgeLeft", "!UI-Frame-GenericMetal-EdgeRight" } },
    { key = "metal", label = "Metal (window frame)", scale = 0.3,
      corners = { "UI-Frame-Metal-CornerTopLeft", "UI-Frame-Metal-CornerTopRight",
                  "UI-Frame-Metal-CornerBottomLeft", "UI-Frame-Metal-CornerBottomRight" },
      edges = { "_UI-Frame-Metal-EdgeTop", "_UI-Frame-Metal-EdgeBottom",
                "!UI-Frame-Metal-EdgeLeft", "!UI-Frame-Metal-EdgeRight" } },
}

local DB
local function Say(m) print("|cff9999ffSquareMinimap:|r " .. m) end
local function Secret(v) return issecretvalue and issecretvalue(v) end

local function AtlasInfo(name)
    if not (C_Texture and C_Texture.GetAtlasInfo) then return nil end
    local ok, info = pcall(C_Texture.GetAtlasInfo, name)
    if ok and info then return info end
end

local function StyleExists(s)
    if s.file then return true end
    for _, n in ipairs(s.corners) do if not AtlasInfo(n) then return false end end
    for _, n in ipairs(s.edges) do if not AtlasInfo(n) then return false end end
    return true
end

local function Available()
    local list = {}
    for _, s in ipairs(STYLES) do if StyleExists(s) then list[#list + 1] = s end end
    return list
end

-- ---------------------------------------------------------------- the border frame
local border
local function Tint(t)
    if CONFIG.DESATURATE and t.SetDesaturated then t:SetDesaturated(true) end
    t:SetVertexColor(CONFIG.TINT[1], CONFIG.TINT[2], CONFIG.TINT[3])
end

local function ClearBorder()
    if not border then return end
    for _, t in ipairs(border.pieces or {}) do t:Hide() end
    border.pieces = {}
    if border.SetBackdrop then border:SetBackdrop(nil) end
end

local function BuildBorder(style)
    if not border then
        -- kept OUTSIDE the minimap cluster: DarkIronUI re-tints minimap art on its
        -- own schedule, and two addons tinting the same pieces made them flicker.
        -- We tint it gray ourselves.
        border = CreateFrame("Frame", "SquareMinimapBorder", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
        border:SetFrameStrata(Minimap:GetFrameStrata())
        border:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 5)
        -- the border isn't part of the map any more, so follow the map's visibility
        if not border.followHooked and Minimap.HookScript then
            border.followHooked = true
            Minimap:HookScript("OnShow", function() if not (DB and DB.round) then border:Show() end end)
            Minimap:HookScript("OnHide", function() border:Hide() end)
        end
        if Minimap.IsShown and not Minimap:IsShown() then border:Hide() end
    end
    ClearBorder()
    local inset = CONFIG.INSET
    border:ClearAllPoints()
    if style.file then
        local e = style.edgeSize
        border.outer = e / 2 - inset
        border:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -e / 2 + inset, e / 2 - inset)
        border:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", e / 2 - inset, -e / 2 + inset)
        if border.SetBackdrop then
            border:SetBackdrop({ edgeFile = style.file, edgeSize = e })
            border:SetBackdropBorderColor(CONFIG.TINT[1], CONFIG.TINT[2], CONFIG.TINT[3])
        end
        return
    end
    border:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)
    local pieces = {}
    local function Piece(atlas)
        local t = border:CreateTexture(nil, "OVERLAY")
        t:SetAtlas(atlas)
        Tint(t)
        pieces[#pieces + 1] = t
        return t
    end
    -- corners: Blizzard's size scaled, pulled out so they sit over the map's corners
    local cs = {}
    for i, n in ipairs(style.corners) do
        local info = AtlasInfo(n) or { width = 32, height = 32 }
        local sc = style.scale or CONFIG.SCALE
        local w, h = (info.width or 32) * sc, (info.height or 32) * sc
        local t = Piece(n)
        t:SetSize(w, h)
        cs[i] = { t = t, w = w, h = h }
    end
    local o = CONFIG.INSET
    local tl, tr, bl, br = cs[1], cs[2], cs[3], cs[4]
    border.outer = math.max(bl.h, br.h) / 2 - o
    tl.t:SetPoint("TOPLEFT", border, "TOPLEFT", -tl.w / 2 + o, tl.h / 2 - o)
    tr.t:SetPoint("TOPRIGHT", border, "TOPRIGHT", tr.w / 2 - o, tr.h / 2 - o)
    bl.t:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", -bl.w / 2 + o, -bl.h / 2 + o)
    br.t:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", br.w / 2 - o, -br.h / 2 + o)
    if style.flip then
        -- one corner piece drawn four ways (top-left art)
        tr.t:SetTexCoord(1, 0, 0, 1); bl.t:SetTexCoord(0, 1, 1, 0); br.t:SetTexCoord(1, 0, 1, 0)
    end
    -- edges between the corners, stretched along their length
    local top, bottom, left, right = Piece(style.edges[1]), Piece(style.edges[2]), Piece(style.edges[3]), Piece(style.edges[4])
    local ti, li = AtlasInfo(style.edges[1]) or {}, AtlasInfo(style.edges[3]) or {}
    local sc = style.scale or CONFIG.SCALE
    local eh = (ti.height or 16) * sc
    local ew = (li.width or 16) * sc
    top:SetPoint("TOPLEFT", tl.t, "TOPRIGHT"); top:SetPoint("TOPRIGHT", tr.t, "TOPLEFT"); top:SetHeight(eh)
    bottom:SetPoint("BOTTOMLEFT", bl.t, "BOTTOMRIGHT"); bottom:SetPoint("BOTTOMRIGHT", br.t, "BOTTOMLEFT"); bottom:SetHeight(eh)
    left:SetPoint("TOPLEFT", tl.t, "BOTTOMLEFT"); left:SetPoint("BOTTOMLEFT", bl.t, "TOPLEFT"); left:SetWidth(ew)
    right:SetPoint("TOPRIGHT", tr.t, "BOTTOMRIGHT"); right:SetPoint("BOTTOMRIGHT", br.t, "TOPRIGHT"); right:SetWidth(ew)
    -- each piece on its own layer so overlapping pieces never fight (flicker)
    top:SetDrawLayer("OVERLAY", 1); bottom:SetDrawLayer("OVERLAY", 1)
    left:SetDrawLayer("OVERLAY", 2); right:SetDrawLayer("OVERLAY", 2)
    for _, c in ipairs(cs) do c.t:SetDrawLayer("OVERLAY", 4) end
    border.pieces = pieces
end

-- ---------------------------------------------------------------- hiding the round ring
local hidden, hiddenNames = {}, {}
local function LooksRound(r)
    local okA, a = pcall(function() return r.GetAtlas and r:GetAtlas() end)
    a = (okA and type(a) == "string" and not Secret(a)) and a:lower() or ""
    local okT, f = pcall(function() return r.GetTexture and r:GetTexture() end)
    f = (okT and type(f) == "string" and not Secret(f)) and f:lower() or ""
    local okN, n = pcall(function() return r.GetName and r:GetName() end)
    n = (okN and type(n) == "string") and n:lower() or ""
    -- never the north arrow
    if a:find("north") or f:find("north") or n:find("north") then return false end
    return a:find("minimap%-frame") or a:find("minimap%-border") or a:find("minimap%-compass")
        or f:find("minimapborder") or f:find("minimap%-border") or f:find("ui%-minimap%-border")
        or n:find("minimapborder") or n:find("minimapcompass") or n == "minimapbackdrop"
end

local function HideRound(on)
    local roots = { MinimapCluster, Minimap, MinimapBackdrop }
    for _, name in ipairs({ "MinimapBorder", "MinimapBorderTop", "MinimapCompassTexture" }) do
        local r = _G[name]
        if r and r.SetAlpha then
            if on then pcall(r.SetAlpha, r, 0); hidden[r] = true; hiddenNames[name] = true
            elseif hidden[r] then pcall(r.SetAlpha, r, 1); hidden[r] = nil end
        end
    end
    for _, root in ipairs(roots) do
        if root and root.GetRegions then
            for _, r in ipairs({ root:GetRegions() }) do
                if r.GetObjectType and r:GetObjectType() == "Texture" and r ~= (border and border) then
                    if on and LooksRound(r) then
                        pcall(r.SetAlpha, r, 0); hidden[r] = true
                        hiddenNames[(r.GetName and r:GetName()) or ((r.GetAtlas and r:GetAtlas()) or "texture")] = true
                    elseif not on and hidden[r] then pcall(r.SetAlpha, r, 1); hidden[r] = nil end
                end
            end
        end
    end
end

-- ---------------------------------------------------------------- north arrow
-- Blizzard's own arrow if it's a separate piece (MinimapNorthTag); otherwise
-- our copy of the same art. Either way it sits centered on the top edge.
local northNote = "not set"
local ownNorth
local function PlaceNorth(show)
    local tag = _G.MinimapNorthTag
    if tag and tag.SetPoint and not (tag.IsForbidden and tag:IsForbidden()) then
        if show then
            pcall(function()
                tag:ClearAllPoints()
                tag:SetPoint("CENTER", Minimap, "TOP", 0, CONFIG.NORTH_Y)
                if tag.SetDrawLayer then tag:SetDrawLayer("OVERLAY", 7) end
                tag:SetAlpha(1)
            end)
            hidden[tag] = nil
            northNote = "Blizzard's arrow (MinimapNorthTag), moved to the top edge"
        end
        if ownNorth then ownNorth:Hide() end
        return
    end
    if not show then if ownNorth then ownNorth:Hide() end; return end
    if not ownNorth then
        ownNorth = (border or Minimap):CreateTexture(nil, "OVERLAY", nil, 7)
        ownNorth:SetTexture("Interface\\Minimap\\MinimapNorthTag")
        ownNorth:SetSize(16, 16)
    end
    ownNorth:ClearAllPoints()
    ownNorth:SetPoint("CENTER", Minimap, "TOP", 0, CONFIG.NORTH_Y)
    ownNorth:Show()
    northNote = "our copy of the north arrow (no separate Blizzard arrow found)"
end

-- ---------------------------------------------------------------- the sun (day / night) button
-- Sits on the top-right corner, drawn over the border (like Blizzard's sits
-- over the round ring). If it has no click action, clicking opens the calendar.
local sunNote = "not found"
local lookup = {}   -- last /sqm frames list: number -> frame
local function Sun()
    if DB and DB.sunPick then
        local f = DB.sunPick.name and _G[DB.sunPick.name]
        if not f and DB.sunPick.path then
            -- found by parent key: "MinimapCluster.Foo" or "Minimap.Bar.Baz"
            local cur
            for part in DB.sunPick.path:gmatch("[^%.]+") do cur = (cur == nil) and _G[part] or (type(cur) == "table" and rawget(cur, part) or nil) end
            f = cur
        end
        if type(f) == "table" then return f end
    end
    local s = _G.GameTimeFrame
    if s then return s end
    if MinimapCluster and MinimapCluster.GetChildren then
        for _, c in ipairs({ MinimapCluster:GetChildren() }) do
            local n = c.GetName and c:GetName()
            if type(n) == "string" and (n:find("GameTime") or n:find("Calendar")) then return c end
        end
    end
end

local placingSun = false
local function PlaceSun()
    local sun = Sun()
    if not (sun and sun.SetPoint) or (sun.IsForbidden and sun:IsForbidden()) then sunNote = "not found"; return end
    placingSun = true
    pcall(function()
        sun:ClearAllPoints()
        sun:SetPoint("CENTER", Minimap, "TOPRIGHT", CONFIG.SUN_X, CONFIG.SUN_Y)
        -- over the border
        if border then
            if sun.SetFrameStrata then sun:SetFrameStrata(border:GetFrameStrata()) end
            if sun.SetFrameLevel then sun:SetFrameLevel(border:GetFrameLevel() + 5) end
        end
    end)
    placingSun = false
    local n = (sun.GetName and sun:GetName()) or "sun button"
    if not sun.sqmHooked then
        sun.sqmHooked = true
        hooksecurefunc(sun, "SetPoint", function()
            if not placingSun and (CONFIG.SUN or (DB and DB.sunPick)) and not (DB and DB.round) then C_Timer.After(0, PlaceSun) end
        end)
        if sun.GetScript and not sun:GetScript("OnClick") and sun.SetScript then
            pcall(function()
                if sun.RegisterForClicks then sun:RegisterForClicks("LeftButtonUp") end
                sun:SetScript("OnClick", function()
                    if ToggleCalendar then ToggleCalendar() elseif TimeManager_Toggle then TimeManager_Toggle() end
                end)
            end)
            sun.sqmClick = true
        end
    end
    sunNote = n .. " on the top-right corner" .. (sun.sqmClick and "; click opens the calendar / clock" or "")
end

-- ---------------------------------------------------------------- zoom buttons
local zoomNote = "not found"
local function ZoomButtons()
    local zin = _G.MinimapZoomIn or (Minimap and rawget(Minimap, "ZoomIn"))
    local zout = _G.MinimapZoomOut or (Minimap and rawget(Minimap, "ZoomOut"))
    return zin, zout
end

local placingZoom = false
local function PlaceZoom()
    local zin, zout = ZoomButtons()
    if not (zin and zout and zin.SetPoint and zout.SetPoint) then zoomNote = "not found"; return end
    -- below the outside of the border, right-aligned:  [ - ][ + ]
    local pad = (border and border:IsShown() and border.outer) or 0
    placingZoom = true
    pcall(function()
        zin:ClearAllPoints()
        zin:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", CONFIG.ZOOM_X, CONFIG.ZOOM_Y - pad)
        zout:ClearAllPoints()
        zout:SetPoint("RIGHT", zin, "LEFT", -CONFIG.ZOOM_GAP, 0)
        -- flat: undo any rotation Blizzard gave them for the round ring
        for _, b in ipairs({ zin, zout }) do
            if b.SetRotation then pcall(b.SetRotation, b, 0) end
            for _, r in ipairs({ b:GetRegions() }) do
                if r.SetRotation then pcall(r.SetRotation, r, 0) end
            end
        end
    end)
    placingZoom = false
    zoomNote = ("moved under the map (%s / %s)"):format((zin.GetName and zin:GetName()) or "ZoomIn", (zout.GetName and zout:GetName()) or "ZoomOut")
    -- Blizzard may put them back (zoom changes, Edit Mode): put them right back
    for _, b in ipairs({ zin, zout }) do
        if not b.sqmHooked then
            b.sqmHooked = true
            hooksecurefunc(b, "SetPoint", function()
                if not placingZoom and CONFIG.ZOOM and not (DB and DB.round) then C_Timer.After(0, PlaceZoom) end
            end)
        end
    end
end

-- ---------------------------------------------------------------- apply
local function CurrentStyle()
    local avail = Available()
    if #avail == 0 then return nil end
    for _, s in ipairs(avail) do if DB and s.key == DB.style then return s end end
    return avail[1]
end

local function Apply()
    if not Minimap then return end
    if DB and DB.round then
        pcall(Minimap.SetMaskTexture, Minimap, "Textures\\MinimapMask")
        GetMinimapShape = function() return "ROUND" end
        ClearBorder(); if border then border:Hide() end
        HideRound(false)
        PlaceNorth(false)
        return
    end
    pcall(Minimap.SetMaskTexture, Minimap, "Interface\\Buttons\\WHITE8X8")
    -- other addons (and the button placement) ask this to know the shape
    GetMinimapShape = function() return "SQUARE" end
    if CONFIG.HIDE_ROUND then HideRound(true) end
    local s = CurrentStyle()
    if s then
        BuildBorder(s); border:Show()
        border:SetFrameStrata(Minimap:GetFrameStrata())
        border:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 5)
        -- the border isn't part of the map any more, so follow the map's visibility
        if not border.followHooked and Minimap.HookScript then
            border.followHooked = true
            Minimap:HookScript("OnShow", function() if not (DB and DB.round) then border:Show() end end)
            Minimap:HookScript("OnHide", function() border:Hide() end)
        end
        if Minimap.IsShown and not Minimap:IsShown() then border:Hide() end
    end
    if CONFIG.NORTH then PlaceNorth(true) end
    if CONFIG.SUN or (DB and DB.sunPick) then PlaceSun() end
    if CONFIG.ZOOM then PlaceZoom() end
end

local ADDON = ...
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(_, event, a1)
    if event == "ADDON_LOADED" then
        if a1 == ADDON then SquareMinimapDB = SquareMinimapDB or {}; DB = SquareMinimapDB end
        return
    end
    pcall(Apply)
    -- Blizzard sometimes re-shows the ring art a moment after login
    C_Timer.After(2, function() pcall(Apply) end)
end)

SLASH_SQUAREMINIMAP1 = "/sqm"
SlashCmdList["SQUAREMINIMAP"] = function(msg)
    msg = (msg or ""):lower()
    if not DB then return end
    if msg:find("style") then
        local avail = Available()
        if #avail == 0 then Say("no border art found on this client"); return end
        local cur, idx = CurrentStyle(), 1
        for i, s in ipairs(avail) do if s == cur then idx = i end end
        DB.style = avail[idx % #avail + 1].key
        Apply()
        Say(("border: %s (%d of %d)"):format(CurrentStyle().label, (idx % #avail) + 1, #avail))
        return
    end
    if msg:find("probe") then
        for _, s in ipairs(STYLES) do
            if s.file then Say(("  %s: file border (always available)"):format(s.label))
            else
                local missing = {}
                for _, n in ipairs(s.corners) do if not AtlasInfo(n) then missing[#missing + 1] = n end end
                for _, n in ipairs(s.edges) do if not AtlasInfo(n) then missing[#missing + 1] = n end end
                Say(("  %s: %s"):format(s.label, #missing == 0 and "available" or (("not on this client (%d of %d pieces missing)"):format(#missing, #s.corners + #s.edges))))
            end
        end
        return
    end
    if msg:find("^frames") then
        -- every frame on or around the minimap, numbered, with where it sits
        for k in pairs(lookup) do lookup[k] = nil end
        local seen, n = {}, 0
        local mx, my = Minimap:GetCenter()
        local function keyOf(parent, child)
            for k, v in pairs(parent) do if v == child and type(k) == "string" then return k end end
        end
        local function walk(fr, path, depth)
            if depth > 2 or not fr.GetChildren then return end
            for _, c in ipairs({ fr:GetChildren() }) do
                if type(c) == "table" and not seen[c] and c ~= border then
                    seen[c] = true
                    local name = c.GetName and c:GetName()
                    local key = keyOf(fr, c)
                    local label = name or (key and (path .. "." .. key)) or (path .. ".?")
                    local okS, shown = pcall(c.IsShown, c)
                    local cx, cy
                    if c.GetCenter then local okC, a, b = pcall(c.GetCenter, c); if okC then cx, cy = a, b end end
                    if Secret(cx) or Secret(cy) then cx, cy = nil, nil end
                    local where = (cx and cy and mx) and ("%+.0f,%+.0f"):format(cx - mx, cy - my) or "?"
                    local art = ""
                    if c.GetRegions then
                        for _, r in ipairs({ c:GetRegions() }) do
                            local okA, a = pcall(function() return r.GetAtlas and r:GetAtlas() end)
                            local okT, t = pcall(function() return r.GetTexture and r:GetTexture() end)
                            a = okA and type(a) == "string" and not Secret(a) and a or nil
                            t = okT and type(t) == "string" and not Secret(t) and t or nil
                            if a or t then art = " art " .. (a or t:gsub("^.*\\", "")); break end
                        end
                    end
                    if okS and shown then
                        n = n + 1
                        lookup[n] = { frame = c, name = name, path = (not name and key) and (path .. "." .. key) or nil }
                        Say(("%d. %s  at %s%s"):format(n, label, where, art))
                    end
                    walk(c, name or (key and (path .. "." .. key)) or path, depth + 1)
                end
            end
        end
        if MinimapCluster then walk(MinimapCluster, "MinimapCluster", 0) end
        walk(Minimap, "Minimap", 0)
        Say("positions are from the map's center (+x right, +y up). Pick the sun/moon with /sqm sun <number>")
        return
    end
    if msg:find("^sun") then
        local arg = msg:match("^sun%s+(%S+)")
        if arg == "off" or arg == nil then
            DB.sunPick = nil
            Say("sun/moon left in Blizzard's spot (/reload to put it back)")
            return
        end
        local e = lookup[tonumber(arg) or -1]
        if not e then Say("run /sqm frames first, then /sqm sun <number from that list>"); return end
        DB.sunPick = { name = e.name, path = e.path }
        Apply()
        Say("using " .. (e.name or e.path or "that frame") .. " as the sun/moon: top-right corner, over the border")
        return
    end
    if msg:find("round") then
        DB.round = not DB.round; Apply()
        Say(DB.round and "round minimap (as Blizzard)" or "square minimap")
        return
    end
    if msg:find("help") then
        Say("/sqm style   next border style"); Say("/sqm probe   which border art exists")
        Say("/sqm round   square / round");   Say("/sqm debug   what it found and hid")
        Say("/sqm frames  list the buttons on / around the map (numbered)")
        Say("/sqm sun 3   put frame 3 from that list on the top-right corner;  /sqm sun off  stop")
        return
    end
    local names = {}
    for n in pairs(hiddenNames) do names[#names + 1] = tostring(n) end
    local s = CurrentStyle()
    Say(("debug: %s; border %s; hid: %s"):format(DB.round and "round" or "square", s and s.label or "none available",
        #names > 0 and table.concat(names, ", ") or "nothing"))
    Say("  north: " .. northNote)
    Say("  zoom buttons: " .. zoomNote)
    Say("  sun button: " .. sunNote)
    Say("type /sqm help for commands")
end

local made = false
local mf = CreateFrame("Frame")
mf:RegisterEvent("PLAYER_ENTERING_WORLD")
mf:SetScript("OnEvent", function()
    if made or (InCombatLockdown and InCombatLockdown()) then return end
    made = true
    if not (GetMacroIndexByName and CreateMacro and GetNumMacros) then return end
    pcall(function()
        for _, mk in ipairs({ { "SQM Style", "/sqm style" }, { "SQM Debug", "/sqm debug" } }) do
            local idx = GetMacroIndexByName(mk[1])
            if not (idx and idx > 0) and GetNumMacros() < (MAX_ACCOUNT_MACROS or 36) then
                pcall(CreateMacro, mk[1], "INV_MISC_QUESTIONMARK", mk[2], nil)
            end
        end
    end)
end)
