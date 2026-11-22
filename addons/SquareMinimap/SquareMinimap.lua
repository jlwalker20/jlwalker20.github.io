-- SquareMinimap 0.10 (test)
-- 0.10: the edge-file borders (Dialog, Thin) overlap the map more by default, closing the gap
-- 0.9: border scaled to match the map (it lives outside the map's cluster since 0.4,
--      which left a 1-2 px gap when the minimap is scaled)
-- 0.8: hides the round quest-area glow ring (the area outline stays)
-- 0.7: settings changeable in Jaff's Better Forever UI (/jaffs)
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
    HIDE_BLOB_RING = true, -- hide the round glow ring shown when you're inside a quest area
                           -- (the quest area's own outline on the map stays)
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
    { key = "dialog", label = "Dialog box edge", file = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24, inset = 6 },
    { key = "thin", label = "Thin tooltip edge", file = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 14, inset = 4 },
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
local MatchScale
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
        MatchScale()
        -- the border isn't part of the map any more, so follow the map's visibility
        if not border.followHooked and Minimap.HookScript then
            border.followHooked = true
            Minimap:HookScript("OnShow", function() if not (DB and DB.round) then border:Show() end end)
            Minimap:HookScript("OnHide", function() border:Hide() end)
        end
        if Minimap.IsShown and not Minimap:IsShown() then border:Hide() end
    end
    ClearBorder()
    -- each style's art has its own transparent margin; the panel's "Border overlap"
    -- (saved as INSET) overrides the style's own default
    local inset = (DB and DB.cfg and DB.cfg.INSET) or style.inset or CONFIG.INSET
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
    local o = inset
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

-- ---------------------------------------------------------------- quest-area glow ring
-- The engine draws a round glow ring at the map's edge while you stand in a
-- quest / task / dig-site area. These calls switch just the ring off.
local ringNote = "not checked"
local function BlobRings(hide)
    local done, missing = {}, {}
    local calls = {
        { "SetQuestBlobRingAlpha", 0, 1 }, { "SetQuestBlobRingScalar", 0, 1 },
        { "SetTaskBlobRingAlpha", 0, 1 },  { "SetTaskBlobRingScalar", 0, 1 },
        { "SetArchBlobRingAlpha", 0, 1 },  { "SetArchBlobRingScalar", 0, 1 },
    }
    for _, c in ipairs(calls) do
        local f = Minimap[c[1]]
        if type(f) == "function" then
            if pcall(f, Minimap, hide and c[2] or c[3]) then done[#done + 1] = c[1] end
        else missing[#missing + 1] = c[1] end
    end
    ringNote = (#done > 0) and ((hide and "hidden" or "shown") .. " (" .. #done .. " settings)")
        or "no ring settings on this client"
end

-- ---------------------------------------------------------------- scale
-- The border hangs off UIParent (so DarkIronUI leaves it alone), but the map
-- may be drawn at a different scale (the minimap cluster's own scale). Give the
-- border the map's scale so its pieces line up with the map's edges exactly.
MatchScale = function()
    if not (border and Minimap and Minimap.GetEffectiveScale and UIParent and UIParent.GetEffectiveScale) then return end
    local okM, ms = pcall(Minimap.GetEffectiveScale, Minimap)
    local okU, us = pcall(UIParent.GetEffectiveScale, UIParent)
    if okM and okU and type(ms) == "number" and type(us) == "number" and us > 0 then
        local want = ms / us
        if math.abs((border:GetScale() or 1) - want) > 0.001 then border:SetScale(want) end
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
        BlobRings(false)
        return
    end
    pcall(Minimap.SetMaskTexture, Minimap, "Interface\\Buttons\\WHITE8X8")
    -- other addons (and the button placement) ask this to know the shape
    GetMinimapShape = function() return "SQUARE" end
    if CONFIG.HIDE_ROUND then HideRound(true) end
    local s = CurrentStyle()
    if s then
        BuildBorder(s); border:Show()
        MatchScale()
        if not border.scaleHooked then
            border.scaleHooked = true
            for _, f in ipairs({ MinimapCluster, Minimap }) do
                if f and f.SetScale then hooksecurefunc(f, "SetScale", function() C_Timer.After(0, MatchScale) end) end
            end
        end
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
    BlobRings(CONFIG.HIDE_BLOB_RING)
end

local ADDON = ...
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
pcall(ev.RegisterEvent, ev, "UI_SCALE_CHANGED")
pcall(ev.RegisterEvent, ev, "DISPLAY_SIZE_CHANGED")
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
    Say("  quest-area glow ring: " .. ringNote)
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

-- ---------------------------------------------------------------- options for Jaff's Better Forever UI
local JDEFAULTS = {}
for k, v in pairs(CONFIG) do if type(v) ~= "table" then JDEFAULTS[k] = v end end
local JDB
local function JChanged() pcall(Apply) end
local jlf = CreateFrame("Frame")
jlf:RegisterEvent("ADDON_LOADED")
jlf:SetScript("OnEvent", function(_, _, n)
    if n ~= "SquareMinimap" then return end
    SquareMinimapDB = SquareMinimapDB or {}
    SquareMinimapDB.cfg = SquareMinimapDB.cfg or {}
    JDB = SquareMinimapDB.cfg
    for k, v in pairs(JDB) do if JDEFAULTS[k] ~= nil then CONFIG[k] = v end end
    if type(JDB.tint) == "number" then CONFIG.TINT = { JDB.tint, JDB.tint, JDB.tint } end
end)
local function Opt(t, key)
    t.get = function() return CONFIG[key] end
    t.set = function(v) CONFIG[key] = v; if JDB then JDB[key] = v end; JChanged() end
    return t
end
local function JReset() for k, v in pairs(JDEFAULTS) do CONFIG[k] = v; if JDB then JDB[k] = nil end end; CONFIG.TINT = { 0.55, 0.55, 0.55 }; if JDB then JDB.tint = nil end; JChanged() end
local OUTLINES = { { "", "Plain (shadow)" }, { "OUTLINE", "Outline" }, { "THICKOUTLINE", "Thick outline" } }
local def = { addon = "SquareMinimap", options = {
    { type = "toggle", label = "Square map", desc = "Off goes back to Blizzard's round map.",
      get = function() return not (DB and DB.round) end, set = function(v) if DB then DB.round = not v end; pcall(Apply) end },
    { type = "choice", label = "Border", desc = "Only styles whose art exists on this client.",
      choices = (function()
          local list = {}
          for _, st in ipairs(STYLES) do list[#list + 1] = { st.key, st.label } end
          return list
      end)(),
      get = function() local st = CurrentStyle(); return st and st.key end,
      set = function(v)
          for _, st in ipairs(Available()) do if st.key == v then DB.style = v; pcall(Apply); return end end
          -- not on this client: skip to the next one that is
          local avail = Available()
          if #avail > 0 then
              local keys = {}; for i, st in ipairs(STYLES) do keys[st.key] = i end
              local want = keys[v] or 1
              for i = 0, #STYLES - 1 do
                  local k = STYLES[((want - 1 + i) % #STYLES) + 1].key
                  for _, st in ipairs(avail) do if st.key == k then DB.style = k; pcall(Apply); return end end
              end
          end
      end },
    Opt({ type = "slider", label = "Corner size", min = 0.2, max = 1, step = 0.05, format = "%.2f" }, "SCALE"),
    { type = "slider", label = "Border overlap", desc = "How far the border reaches over the map's edge. Raise it if there's a gap.", min = -4, max = 14, step = 1,
      get = function() local st = CurrentStyle(); return (JDB and JDB.INSET) or (st and st.inset) or CONFIG.INSET end,
      set = function(v) CONFIG.INSET = v; if JDB then JDB.INSET = v end; JChanged() end },
    { type = "slider", label = "Border gray", desc = "0 is black, 1 is white.", min = 0.1, max = 1, step = 0.05, format = "%.2f",
      get = function() return CONFIG.TINT[1] end,
      set = function(v) CONFIG.TINT = { v, v, v }; if JDB then JDB.tint = v end; JChanged() end },
    Opt({ type = "toggle", label = "Keep the north arrow" }, "NORTH"),
    Opt({ type = "toggle", label = "Hide the quest-area glow ring", desc = "The round glow at the edge while you're inside a quest area. The area's outline on the map stays." }, "HIDE_BLOB_RING"),
    { type = "header", label = "Zoom buttons" },
    Opt({ type = "toggle", label = "Move them under the map", reload = true }, "ZOOM"),
    Opt({ type = "slider", label = "Up / down", min = -20, max = 20, step = 1 }, "ZOOM_Y"),
    Opt({ type = "slider", label = "Sideways", min = -40, max = 40, step = 1 }, "ZOOM_X"),
    Opt({ type = "slider", label = "Gap between them", min = 0, max = 12, step = 1 }, "ZOOM_GAP"),
    { type = "button", label = "Defaults", button = "Reset to defaults", func = JReset },
} }
if JaffsUI and JaffsUI.Register then JaffsUI:Register(def)
else JaffsUI_Queue = JaffsUI_Queue or {}; table.insert(JaffsUI_Queue, def) end
