-- DarkIronUI_UnitFrames 1.3 (formerly FlatUnitFrames)

-- run once even if both DarkIronUI and DarkIronUI_UnitFrames are installed
if _G.DarkIronUI_UnitFrames_Running then return end
_G.DarkIronUI_UnitFrames_Running = true
-- The GamepadDarkMode 0.7 look for the Player, Target and Focus frames
-- (the target-of-target frame too): frame borders and the portrait ring are
-- redrawn flat in light grey with a thin darker outline, cut to exactly the
-- same shapes as Blizzard's art (which is faded out underneath), and
-- background pieces are greyed and dimmed.
--
-- Left completely alone: health/power bars (so TargetClassColors still
-- works), the portrait picture, names and text, status/threat glows, combat
-- flashes, elite/rare dragons, and leader/PvP/rest icons.
--
-- Safety (same rules as GamepadDarkMode): only artwork color/visibility is
-- changed, plus our own small overlay frames; Blizzard's frames and buttons
-- are never changed and nothing of Blizzard's is hooked. Searches only run
-- out of combat; a once-a-second re-check keeps the look in place.
--
-- 0.12: the resting flash is also found by name (status/glow/flash/pulse/
-- rest art) and by Blizzard animations that are playing on it.
--
-- 0.11: the resting flash is found by behavior, not name: while you rest,
-- player-frame art that is tinted yellow or blinking is made see-through.
--
-- 0.10: names and the target/focus level number stay in the default font
-- (names keep the size bump; other text uses the chat font). The target's
-- PvP flag/border is lifted above its level circle. While you are resting,
-- the yellow rest glow/flash on the player frame is hidden (the ZZZ stays,
-- and the red combat glow is untouched).
--
-- 0.9: name text is NAME_SIZE_BONUS sizes larger, and the dragon now sits
-- just under the resting "ZZZ" animation so the ZZZ shows on top of it.
--
-- 0.8: faction art (Horde/Alliance PvP symbol) keeps its own colors, and the
-- frames' text uses the chat font (same size and outline as before).
--
-- 0.7: the level number must be one that is actually ON SCREEN. Blizzard's
-- old PlayerLevelText can exist without being shown, which fooled 0.5/0.6.
-- It now searches every visible text that reads as your level, inside a
-- "Player..." frame (never target/focus/party/raid/nameplates), and looks
-- for the circle among the art around THAT text.
--
-- 0.6: the "circle under the number" test now works in screen coordinates
-- (number and art can sit at different UI scales) and allows art up to
-- 72px. UFF Debug lists the art closest to the level number.
--
-- 0.5: finds the player level number more reliably (by name, or by its
-- text with color codes stripped) and hides the circle behind it by
-- position (any small texture sitting under the number), since Forever's
-- circle art isn't named "level".
--
-- 0.4: default style is now "dark": Blizzard's own frame art keeps all its
-- detail and bevels and is just recolored from gold/brown to dark grey
-- (STYLE = "flat" brings back the flat redraw). The player frame's level
-- circle and number are hidden (target/focus keep theirs). Dragon 3px lower.
--
-- 0.3: darker to match how GamepadDarkMode reads on screen (fill 0.40 with a
-- darker edge), the flat overlay now sits UNDER the health/power bars so it
-- can't tint them, and the elite dragon sits 5px lower.
--
-- 0.2: adds an elite dragon border to YOUR player frame, in the matching
-- dark grey. It reuses Blizzard's elite art from the target frame, mirrored
-- to face the other way, on a small overlay of our own.
--
-- Macros (created for you):
--   UFF Toggle   turn the look on/off (off restores Blizzard's art exactly)
--   UFF Debug    list the artwork it found and what it did with each piece
--   UFF Elite Left / Right / Up / Down   nudge the elite border 2px (saved)


-- timing probe (DarkIronUI's Perf.lua; a no-op without it)
local function M(what, fn, ...)
    local m = DarkIronUI_Measure
    if m then return m("UnitFrames", what, fn, ...) end
    return fn(...)
end

local CONFIG = {
    STYLE = "dark",       -- "dark" = recolor Blizzard's art, "flat" = flat redraw
    HIDE_PLAYER_LEVEL = true,
    USE_CHAT_FONT = true,   -- frame text in the chat font instead of the default UI font
    NAME_SIZE_BONUS = 2,    -- name text this many sizes larger
    HIDE_REST_GLOW = false, -- true = also hide the yellow resting flash (it already sits behind the dragon)
    PVP_OVER_LEVEL = true,  -- target/focus: PvP flag drawn above the level circle
    LEVEL_CIRCLE_MAX = 72,  -- largest art (px) treated as the circle behind the level number
    FILL_COLOR = { 0.40, 0.40, 0.40, 1 },    -- flat fill (the grey GamepadDarkMode shows)
    BORDER_COLOR = { 0.22, 0.22, 0.22, 1 },  -- thin darker outline
    BORDER_SIZE = 1.5,
    -- drawn flat: frame borders and the portrait ring
    RING_ART = { "portraiton", "portraitoff", "frame", "border", "ring", "rim", "edge", "trim", "vehicle" },
    -- greyed and dimmed: background pieces
    SLOT_ART = { "background", "backplate", "bg", "base", "plate" },
    EMPTY_DARKNESS = 0.45, -- background pieces
    DARKNESS = 0.55,       -- frame art in "dark" style (after greying out the gold)
    DESATURATE = true,
    ICON_CROP = 0,         -- not used for unit frames
    FRAME_ART = { "portraiton", "portraitoff", "frame", "border", "ring", "rim", "edge", "trim", "vehicle",
                  "background", "backplate", "bg", "base", "plate" },
    -- never touch artwork whose name contains any of these
    NEVER = { "horde", "alliance", "faction", "honor", "bar-", "type", "embellish", "group", "bar-health", "bar-mana", "bar-power", "bar-rage", "bar-energy", "healthbar", "manabar", "powerbar",
              "status", "glow", "flash", "threat", "combat", "rest", "pvp", "prestige", "leader", "guide",
              "elite", "rare", "boss", "dragon", "icon", "name", "highlight", "role", "sheen", "spark",
              "absorb", "heal", "prediction", "attack", "lt", "rt", "lb", "rb" },
    SCOPE = { "PlayerFrame", "TargetFrame", "FocusFrame" },
    -- elite dragon on the player frame
    PLAYER_ELITE = true,
    ELITE_COLOR = { 0.40, 0.40, 0.40, 1 },   -- matches the outline grey
    ELITE_ATLASES = {                        -- first one that exists is used
        "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold-Winged",
        "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold",
        "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver",
    },
    ELITE_X = -10, ELITE_Y = -2,              -- offset from the portrait's center
    ELITE_SCALE = 1.0,  -- frame name chain must include one of these
    BARS = {},             -- (no extra requirement)
}

local DB
local touched = {}  -- texture -> { kind="frame"|"icon", orig={...} }
local raised, restGlow = {}, {}   -- PvP layering changes / rest-glow textures
local LayerEliteHook   -- set once the dragon layering exists
local elite = { holder = nil, tex = nil, atlas = nil }   -- the player-frame dragon

local function has(s, list, lower)
    if type(s) ~= "string" then return false end
    if lower then s = s:lower() end
    for _, p in ipairs(list) do
        if s:find(p, 1, true) then return true end
    end
    return false
end

local function NeverWord(atlas)
    -- whole-word check for the short words (lt/rt/lb/rb), substring for the rest
    local a = atlas:lower()
    for _, p in ipairs(CONFIG.NEVER) do
        if #p <= 2 then
            if a:find("%f[%a]" .. p .. "%f[%A]") then return true end
        elseif a:find(p, 1, true) then
            return true
        end
    end
    return false
end

local function SafeName(o)
    local ok, n = pcall(function() return o.GetName and o:GetName() end)
    return ok and type(n) == "string" and n or nil
end

local function Path(obj)
    local parts, cur, depth = {}, obj, 0
    while cur and depth < 6 do
        table.insert(parts, 1, SafeName(cur) or "?")
        local ok, p = pcall(function() return cur:GetParent() end)
        cur = ok and p or nil
        depth = depth + 1
    end
    return table.concat(parts, " > ")
end

local function InScope(frame)
    local cur, depth, gp, bar = frame, 0, false, false
    while cur and depth < 10 do
        local n = SafeName(cur)
        if has(n, CONFIG.SCOPE) then gp = true end
        if has(n, CONFIG.BARS) then bar = true end
        local ok, p = pcall(function() return cur:GetParent() end)
        cur = ok and p or nil
        depth = depth + 1
    end
    return gp
end

-- every frame under the Player/Target/Focus frames (a few hundred), instead of
-- walking every frame in the whole UI (thousands) each time the target changes
-- top-level frames whose names match the scope (PlayerFrame, TargetFrame, a gamepad
-- PlayerFrame...). Found once from UIParent's direct children, then reused.
local scopeRoots
local function ScopeRoots()
    if scopeRoots then return scopeRoots end
    local roots, seen = {}, {}
    for _, name in ipairs(CONFIG.SCOPE) do
        local f = _G[name]
        if type(f) == "table" and f.GetChildren and not seen[f] then seen[f] = true; roots[#roots + 1] = f end
    end
    if UIParent and UIParent.GetChildren then
        local ok, kids = pcall(function() return { UIParent:GetChildren() } end)
        for _, f in ipairs(ok and kids or {}) do
            local n = SafeName(f)
            if n and not seen[f] and has(n, CONFIG.SCOPE) then seen[f] = true; roots[#roots + 1] = f end
        end
    end
    scopeRoots = roots
    return roots
end

local function ScopeFrames()
    local list, seen = {}, {}
    local function walk(f, d)
        if not f or seen[f] or d > 14 then return end
        seen[f] = true
        list[#list + 1] = f
        local ok, kids = pcall(function() return { f:GetChildren() } end)
        if ok then for _, c in ipairs(kids) do walk(c, d + 1) end end
    end
    for _, root in ipairs(ScopeRoots()) do walk(root, 0) end
    return list
end

local function IsTexture(o)
    local ok, t = pcall(function() return o.GetObjectType and o:GetObjectType() end)
    return ok and t == "Texture"
end

local function AtlasOf(r)
    local ok, a = pcall(function() return r.GetAtlas and r:GetAtlas() end)
    return ok and type(a) == "string" and a or nil
end

local function IconOf(frame)
    local n = SafeName(frame)
    local cands = { rawget(frame, "icon"), rawget(frame, "Icon"), n and _G[n .. "Icon"] }
    for _, c in ipairs(cands) do
        if type(c) == "table" and IsTexture(c) then return c end
    end
end

---------------------------------------------------------------- applying the look
local function DarkenFrameArt(tex, darkness)
    local t = touched[tex]
    if not t then
        local r, g, b, a = tex:GetVertexColor()
        local desat = tex.IsDesaturated and tex:IsDesaturated() or false
        t = { kind = "frame", orig = { r or 1, g or 1, b or 1, a or 1, desat } }
        touched[tex] = t
    end
    if darkness then t.d = darkness end
    if CONFIG.DESATURATE and tex.SetDesaturated then tex:SetDesaturated(true) end
    local o, d = t.orig, t.d or CONFIG.DARKNESS
    local r, g, b = tex:GetVertexColor()
    if not (r and math.abs(r - o[1] * d) < 0.01 and math.abs(g - o[2] * d) < 0.01 and math.abs(b - o[3] * d) < 0.01) then
        tex:SetVertexColor(o[1] * d, o[2] * d, o[3] * d, o[4])
    end
end

local function CropIcon(tex)
    if CONFIG.ICON_CROP <= 0 then return end
    local c = CONFIG.ICON_CROP
    if not touched[tex] then touched[tex] = { kind = "icon" } end
    local l = tex:GetTexCoord()
    if not (l and math.abs(l - c) < 0.001) then tex:SetTexCoord(c, 1 - c, c, 1 - c) end
end

-- FLAT: a solid-color copy of the piece, stenciled by the original art.
local function FlattenRing(tex, atlas)
    local t = touched[tex]
    if not t then
        local owner = tex:GetParent()
        if not owner then return end
        local holder = CreateFrame("Frame", nil, owner)   -- our own frame; follows the button's fades
        holder:SetAllPoints(owner)
        holder:EnableMouse(false)
        -- sit underneath any health/power bars nearby so the fill never tints them
        local lowest
        local function look(f, depth)
            if not f or depth > 3 or not f.GetChildren then return end
            for _, c in ipairs({ f:GetChildren() }) do
                local ok, kind = pcall(function() return c:GetObjectType() end)
                if ok and kind == "StatusBar" and c.GetFrameLevel then
                    local lv = c:GetFrameLevel()
                    if not lowest or lv < lowest then lowest = lv end
                end
                look(c, depth + 1)
            end
        end
        look(owner, 0)
        local okp, parent = pcall(function() return owner:GetParent() end)
        if okp then look(parent, 1) end
        if lowest and holder.SetFrameLevel then holder:SetFrameLevel(math.max(0, lowest - 1)) end
        -- two stencilled copies of the piece: the darker one full size (shows
        -- as the outline), the lighter one shrunk by BORDER_SIZE on top
        local function layer(color, inset, sub)
            local l = holder:CreateTexture(nil, "ARTWORK", nil, sub)
            l:SetPoint("TOPLEFT", tex, "TOPLEFT", inset, -inset)
            l:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", -inset, inset)
            l:SetColorTexture(unpack(color))
            local m = holder:CreateMaskTexture()
            m:SetPoint("TOPLEFT", tex, "TOPLEFT", inset, -inset)
            m:SetPoint("BOTTOMRIGHT", tex, "BOTTOMRIGHT", -inset, inset)
            if not pcall(m.SetAtlas, m, atlas) then
                local file = tex.GetTexture and tex:GetTexture()
                if not file then return false end
                m:SetTexture(file, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            end
            l:AddMaskTexture(m)
            return true
        end
        local ok = true
        if CONFIG.BORDER_SIZE > 0 then ok = layer(CONFIG.BORDER_COLOR, 0, 0) end
        if ok then ok = layer(CONFIG.FILL_COLOR, CONFIG.BORDER_SIZE, 1) end
        if not ok then holder:Hide(); return end
        t = { kind = "flat", holder = holder, origAlpha = tex:GetAlpha() }
        touched[tex] = t
    end
    t.holder:SetShown(tex:IsShown())         -- appear/disappear with Blizzard's piece
    if tex:GetAlpha() ~= 0 then tex:SetAlpha(0) end -- fade out the shaded original (art only)
end

local function RestoreExtras()
    for obj, r in pairs(raised) do
        if r.kind == "layer" then pcall(obj.SetDrawLayer, obj, r.layer, r.sub or 0)
        elseif r.kind == "level" then pcall(obj.SetFrameLevel, obj, r.level) end
    end
    wipe(raised)
    for tex in pairs(restGlow) do
        local ok, r, g, b = pcall(tex.GetVertexColor, tex)
        if ok and r then pcall(tex.SetVertexColor, tex, r, g, b, 1) end
    end
end

local function Restore()
    pcall(RestoreExtras)
    for tex, t in pairs(touched) do
        if t.kind == "frame" then
            local o = t.orig
            pcall(tex.SetVertexColor, tex, o[1], o[2], o[3], o[4])
            if tex.SetDesaturated then pcall(tex.SetDesaturated, tex, o[5]) end
        elseif t.kind == "flat" then
            t.holder:Hide()
            pcall(tex.SetAlpha, tex, t.origAlpha or 1)
        elseif t.kind == "font" then
            local o = t.orig
            pcall(tex.SetFont, tex, o[1], o[2], o[3] or "")
        elseif t.kind == "hidden" then
            pcall(tex.SetAlpha, tex, t.origAlpha or 1)
            local p = t.prev
            if p and p.kind == "frame" then
                pcall(tex.SetVertexColor, tex, p.orig[1], p.orig[2], p.orig[3], p.orig[4])
                if tex.SetDesaturated then pcall(tex.SetDesaturated, tex, p.orig[5]) end
            end
        else
            pcall(tex.SetTexCoord, tex, 0, 1, 0, 1)
        end
    end
    wipe(touched)
end

-- is this frame part of the PLAYER frame (not target/focus)?
local function InPlayerFrame(frame)
    local cur, depth = frame, 0
    while cur and depth < 10 do
        local n = SafeName(cur)
        if n and (n:find("TargetFrame") or n:find("FocusFrame")) then return false end
        if n and n:find("PlayerFrame") then return true end
        local ok, p = pcall(function() return cur:GetParent() end)
        cur = ok and p or nil
        depth = depth + 1
    end
    return false
end

local function PlayerLevelString()
    local ok, lv = pcall(UnitLevel, "player")
    if not ok or lv == nil or (issecretvalue and issecretvalue(lv)) then return nil end
    return tostring(lv)
end

-- hide one region (texture or text) by making it transparent; remembered for restore
local function HideRegion(r)
    local t = touched[r]
    if not t or t.kind ~= "hidden" then
        touched[r] = { kind = "hidden", origAlpha = r:GetAlpha(), prev = t }
    end
    if r:GetAlpha() ~= 0 then r:SetAlpha(0) end
end

local function Plain(txt)
    if type(txt) ~= "string" or (issecretvalue and issecretvalue(txt)) then return nil end
    txt = txt:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    return (txt:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function ChainOK(obj)
    local cur, depth, player = obj, 0, false
    while cur and depth < 12 do
        local n = SafeName(cur)
        if n then
            if n:find("Target") or n:find("Focus") or n:find("Party") or n:find("Raid")
                or n:find("NamePlate") or n:find("Nameplate") then return false end
            if n:find("Player") then player = true end
        end
        local ok, p = pcall(function() return cur:GetParent() end)
        cur = ok and p or nil
        depth = depth + 1
    end
    return player
end

-- every visible text anywhere that reads as your level: { region, ok-for-player }
local function VisibleLevelTexts()
    local out, lvl = {}, PlayerLevelString()
    if not (lvl and EnumerateFrames) then return out end
    for _, f in ipairs(ScopeFrames()) do   -- only the unit frames, not the whole UI
        if f.GetRegions then
            for _, r in ipairs({ f:GetRegions() }) do
                local okT, kind = pcall(function() return r:GetObjectType() end)
                if okT and kind == "FontString" then
                    local okx, txt = pcall(function() return r:GetText() end)
                    if okx and Plain(txt) == lvl then
                        local okv, vis = pcall(function() return r:IsVisible() end)
                        local okc, cx = pcall(function() return (r:GetCenter()) end)
                        if okv and vis and okc and cx then
                            local okc2, good = pcall(ChainOK, r)
                            out[#out + 1] = { r = r, good = okc2 and good }
                        end
                    end
                end
            end
        end
    end
    return out
end

local function FindPlayerLevelText()
    for _, e in ipairs(VisibleLevelTexts()) do
        if e.good then return e.r end
    end
end

-- art around a region: its frame's regions, its parent frame's, and their children's
local function ArtAround(r)
    local list, seen = {}, {}
    local function addFrame(f, depth)
        if not f or seen[f] or depth > 2 then return end
        seen[f] = true
        if f.GetRegions then for _, x in ipairs({ f:GetRegions() }) do list[#list + 1] = x end end
        if f.GetChildren then for _, c in ipairs({ f:GetChildren() }) do addFrame(c, depth + 1) end end
    end
    local okp, p = pcall(function() return r:GetParent() end)
    if okp and p then
        addFrame(p, 0)
        local okg, g = pcall(function() return p:GetParent() end)
        if okg and g then addFrame(g, 1) end
    end
    return list
end

local playerRegions = {}   -- collected during a scan
local pvpArt = {}          -- target/focus PvP art found during a scan
local levelText

-- hide the level number, plus art named "level" and any small texture whose
-- area contains the number's center (the circle behind it)
local function HidePlayerLevel()
    if not CONFIG.HIDE_PLAYER_LEVEL then return end
    local okv, vis = pcall(function() return levelText and levelText:IsVisible() end)
    if not (okv and vis) then levelText = FindPlayerLevelText() end
    if levelText then pcall(HideRegion, levelText) end
    local cx, cy = nil, nil
    if levelText and levelText.GetCenter then
        local x, y = levelText:GetCenter()
        local es = (levelText.GetEffectiveScale and levelText:GetEffectiveScale()) or 1
        if x and y then cx, cy = x * es, y * es end   -- screen coordinates
    end
    local around = levelText and ArtAround(levelText) or {}
    for _, r in ipairs(playerRegions) do around[#around + 1] = r end
    for _, r in ipairs(around) do
        local okT, kind = pcall(function() return r:GetObjectType() end)
        if okT and kind == "Texture" then
            local a = AtlasOf(r)
            local named = a and a:lower():find("level", 1, true)
            local under = false
            if cx and r.GetLeft and r.GetSize then
                local okb, l, b, w, h, es = pcall(function()
                    local w0, h0 = r:GetSize()
                    return r:GetLeft(), r:GetBottom(), w0, h0, (r.GetEffectiveScale and r:GetEffectiveScale()) or 1
                end)
                if okb and l and b and w and h and w > 0 and w <= CONFIG.LEVEL_CIRCLE_MAX and h <= CONFIG.LEVEL_CIRCLE_MAX then
                    l, b, w, h = l * es, b * es, w * es, h * es
                    under = cx >= l and cx <= l + w and cy >= b and cy <= b + h
                end
            end
            if named or under then pcall(HideRegion, r) end
        end
    end
end

-- find artwork in the gamepad action bars and apply the look
-- which unit a frame chain belongs to
local function UnitOfChain(obj)
    local cur, depth = obj, 0
    while cur and depth < 12 do
        local n = SafeName(cur)
        if n then
            if n:find("TargetFrameToT") or n:find("TargetofTarget") then return nil end
            if n:find("TargetFrame") then return "target" end
            if n:find("FocusFrame") then return "focus" end
            if n:find("PlayerFrame") then return "player" end
        end
        local ok, p = pcall(function() return cur:GetParent() end)
        cur = ok and p or nil
        depth = depth + 1
    end
end

local nameTexts = {}   -- FontString -> true once known to be a unit name
local function KnownNameTexts()
    local list = { _G.PlayerName, TargetFrame and rawget(TargetFrame, "name"), FocusFrame and rawget(FocusFrame, "name"),
        _G.TargetFrameTextureFrameName, _G.FocusFrameTextureFrameName }
    for _, fs in ipairs(list) do if type(fs) == "table" then nameTexts[fs] = true end end
    local lv = { TargetFrame and rawget(TargetFrame, "levelText"), FocusFrame and rawget(FocusFrame, "levelText"),
        _G.TargetFrameTextureFrameLevelText, _G.FocusFrameTextureFrameLevelText }
    for _, fs in ipairs(lv) do if type(fs) == "table" then levelTexts[fs] = true end end
end

local function IsNameText(fs)
    if nameTexts[fs] then return true end
    local unit = UnitOfChain(fs)
    if not unit then return false end
    local okn, name = pcall(UnitName, unit)
    if not okn or name == nil or (issecretvalue and issecretvalue(name)) then return false end
    local okx, txt = pcall(function() return fs:GetText() end)
    if okx and type(txt) == "string" and not (issecretvalue and issecretvalue(txt)) then
        txt = txt:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if txt == name then nameTexts[fs] = true; return true end
    end
    return false
end

local levelTexts = {}   -- target/focus level numbers (kept in the default font)
local function IsLevelText(fs)
    if levelTexts[fs] then return true end
    local unit = UnitOfChain(fs)
    if unit ~= "target" and unit ~= "focus" then return false end
    local okl, lv = pcall(UnitLevel, unit)
    if not okl or lv == nil or (issecretvalue and issecretvalue(lv)) then return false end
    local okx, txt = pcall(function() return fs:GetText() end)
    if okx and type(txt) == "string" and not (issecretvalue and issecretvalue(txt)) then
        txt = txt:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if txt == tostring(lv) or (lv <= 0 and txt == "??") then levelTexts[fs] = true; return true end
    end
    return false
end

local function ChatFontPath()
    if ChatFontNormal and ChatFontNormal.GetFont then
        local p = ChatFontNormal:GetFont()
        if p then return p end
    end
    return "Fonts\\ARIALN.TTF"
end

-- swap one text to the chat font, keeping its size and outline
local function ChatFont(fs)
    if not CONFIG.USE_CHAT_FONT and not (nameTexts[fs] and CONFIG.NAME_SIZE_BONUS ~= 0) then return end
    local t = touched[fs]
    if t and t.kind ~= "font" then return end      -- e.g. the hidden player level
    local path, size, flags = fs:GetFont()
    if not size then return end
    if not t then
        t = { kind = "font", orig = { path, size, flags } }
        touched[fs] = t
    end
    local keepDefault = nameTexts[fs] or levelTexts[fs]
    local want = (CONFIG.USE_CHAT_FONT and not keepDefault) and ChatFontPath() or t.orig[1]
    local wantSize = t.orig[2] + ((nameTexts[fs] and CONFIG.NAME_SIZE_BONUS) or 0)
    if path ~= want or math.abs(size - wantSize) > 0.01 then fs:SetFont(want, wantSize, flags or "") end
end

---------------------------------------------------------------- rest glow
local function IsRestGlow(r)
    local a = (AtlasOf(r) or ""):lower()
    local n = (SafeName(r) or ""):lower()
    if a:find("flipbook", 1, true) or n:find("restloop", 1, true) then return false end -- the ZZZ
    return a:find("status", 1, true) or n:find("status", 1, true)
        or n:find("restglow", 1, true) or a:find("rest-glow", 1, true) or a:find("restglow", 1, true)
end

local lastAlpha = {}
local function Yellowish(r, g, b) return r and r > 0.85 and g > 0.6 and b < 0.55 end

-- candidates: player-frame textures that aren't ours, the ZZZ, bars or icons
local function RestCandidate(tex)
    if touched[tex] and touched[tex].kind ~= "frame" then return false end
    if tex == (elite and elite.tex) then return false end
    local a = (AtlasOf(tex) or ""):lower()
    local n = (SafeName(tex) or ""):lower()
    if a:find("flipbook", 1, true) or n:find("restloop", 1, true) or a:find("bar-", 1, true)
        or n:find("portrait", 1, true) or n:find("icon", 1, true) then return false end
    return true
end

local function AnimPlaying(obj)
    if not (obj and obj.GetAnimationGroups) then return false end
    local ok, groups = pcall(function() return { obj:GetAnimationGroups() } end)
    if not ok then return false end
    for _, g in ipairs(groups) do
        local okp, playing = pcall(function() return g:IsPlaying() end)
        if okp and playing then return true end
    end
    return false
end

local function GlowNamed(tex)
    local a = (AtlasOf(tex) or ""):lower()
    local n = (SafeName(tex) or ""):lower()
    for _, w in ipairs({ "status", "glow", "flash", "pulse", "rest", "shine" }) do
        if a:find(w, 1, true) or n:find(w, 1, true) then return true end
    end
    return false
end

local function RestReason(tex)
    if GlowNamed(tex) then return "named" end
    local okC, r, g, b = pcall(tex.GetVertexColor, tex)
    if okC and Yellowish(r, g, b) then return "yellow" end
    if AnimPlaying(tex) then return "animated" end
    local okp, p = pcall(function() return tex:GetParent() end)
    if okp and p and p ~= PlayerFrame and AnimPlaying(p) then return "animated frame" end
    return nil
end

local function UpdateRestGlow()
    if not (DB and DB.enabled) then return end
    local resting = IsResting and IsResting()
    if not resting then
        -- left the inn/city: give the art back to Blizzard
        for tex in pairs(CONFIG.HIDE_REST_GLOW and restGlow or {}) do
            local ok, r, g, b, a = pcall(tex.GetVertexColor, tex)
            if ok and a == 0 then pcall(tex.SetVertexColor, tex, r, g, b, 1) end
        end
        wipe(restGlow)
        wipe(lastAlpha)
        return
    end
    -- find the flash: tinted yellow, or its alpha keeps changing
    for _, tex in ipairs(playerRegions) do
        if not restGlow[tex] and IsTexture(tex) and RestCandidate(tex) then
            local okA, alpha = pcall(tex.GetAlpha, tex)
            local okC, r, g, b = pcall(tex.GetVertexColor, tex)
            local blinking = okA and alpha and lastAlpha[tex] and math.abs(alpha - lastAlpha[tex]) > 0.05
            local okR, reason = pcall(RestReason, tex)
            if (okR and reason) or blinking then restGlow[tex] = (okR and reason) or "blinking" end
            if okA then lastAlpha[tex] = alpha end
        end
    end
    -- vertex alpha 0: invisible even while Blizzard animates the texture's alpha
    if not CONFIG.HIDE_REST_GLOW then return end   -- found only so the dragon can sit above it
    for tex in pairs(restGlow) do
        local ok, r, g, b, a = pcall(tex.GetVertexColor, tex)
        if ok and a and a > 0 then pcall(tex.SetVertexColor, tex, r, g, b, 0) end
    end
end

-- while resting, look 5x a second so a blinking flash is caught quickly
local restWatch = CreateFrame("Frame")
local restAcc = 0
restWatch:SetScript("OnUpdate", function(_, e)
    if not (IsResting and IsResting() and DB and DB.enabled) then return end
    -- every frame: keep flash pieces invisible even if Blizzard re-colors them
    for tex in pairs(CONFIG.HIDE_REST_GLOW and restGlow or {}) do
        local ok, r, g, b, a = pcall(tex.GetVertexColor, tex)
        if ok and a and a > 0 then pcall(tex.SetVertexColor, tex, r, g, b, 0) end
    end
    restAcc = restAcc + e
    if restAcc < 0.2 then return end
    restAcc = 0
    pcall(M, "rest glow", UpdateRestGlow)
    if LayerEliteHook then pcall(M, "rest layering", LayerEliteHook) end
end)

---------------------------------------------------------------- PvP above level circle
local function IsPvPArt(r)
    local a = (AtlasOf(r) or ""):lower()
    local n = (SafeName(r) or ""):lower()
    return a:find("pvp", 1, true) or a:find("horde", 1, true) or a:find("alliance", 1, true)
        or a:find("prestige", 1, true) or a:find("honor", 1, true) or n:find("pvp", 1, true) or n:find("prestige", 1, true)
end

local function LiftPvP(pvpTex, unit, levelArt)
    if raised[pvpTex] then return end
    local okL, layer, sub = pcall(function() return pvpTex:GetDrawLayer() end)
    raised[pvpTex] = { kind = "layer", layer = okL and layer or "ARTWORK", sub = okL and sub or 0 }
    pcall(pvpTex.SetDrawLayer, pvpTex, "OVERLAY", 7)
    -- different frames: make sure the PvP art's frame sits above the circle's
    local owner = pvpTex:GetParent()
    for _, circ in ipairs(levelArt) do
        local cOwner = circ:GetParent()
        if owner and cOwner and owner ~= cOwner and owner.GetFrameLevel and cOwner.GetFrameLevel then
            local ol, cl = owner:GetFrameLevel(), cOwner:GetFrameLevel()
            if ol <= cl and not (InCombatLockdown and InCombatLockdown()) then
                if not raised[owner] then raised[owner] = { kind = "level", level = ol } end
                pcall(owner.SetFrameLevel, owner, cl + 1)
            end
        end
    end
end

local function Scan()
    if not (DB and DB.enabled) or not EnumerateFrames then return end
    wipe(playerRegions)
    wipe(pvpArt)
    pcall(KnownNameTexts)
    for _, f in ipairs(ScopeFrames()) do   -- only the unit frames, not the whole UI
        local okS, inScope = pcall(InScope, f)
        if okS and inScope and f.GetRegions then
            local okP, inPlayer = pcall(InPlayerFrame, f)
            if okP and inPlayer then
                for _, r in ipairs({ f:GetRegions() }) do
                    playerRegions[#playerRegions + 1] = r
                    if IsTexture(r) then
                        local okG, glow = pcall(IsRestGlow, r)
                        if okG and glow then restGlow[r] = "status art" end
                    end
                end
            end
            local okU, unitOf = pcall(UnitOfChain, f)
            if okU and (unitOf == "target" or unitOf == "focus") then
                for _, r in ipairs({ f:GetRegions() }) do
                    if IsTexture(r) then
                        local okV, pv = pcall(IsPvPArt, r)
                        if okV and pv then pvpArt[#pvpArt + 1] = { tex = r, unit = unitOf } end
                    end
                end
            end
            local icon = IconOf(f)
            if icon then pcall(CropIcon, icon) end
            for _, r in ipairs({ f:GetRegions() }) do
                local okK, rk = pcall(function() return r:GetObjectType() end)
                if okK and rk == "FontString" then
                    pcall(IsNameText, r)
                    pcall(IsLevelText, r)
                    pcall(ChatFont, r)
                end
                if r ~= icon and IsTexture(r) and not (touched[r] and touched[r].kind == "hidden") then
                    local atlas = AtlasOf(r)
                    if atlas and not NeverWord(atlas) and has(atlas, CONFIG.FRAME_ART, true) then
                        if has(atlas, CONFIG.SLOT_ART, true) then
                            pcall(DarkenFrameArt, r, CONFIG.EMPTY_DARKNESS)  -- empty-slot / backplate art
                        elseif CONFIG.STYLE == "flat" and has(atlas, CONFIG.RING_ART, true) then
                            pcall(FlattenRing, r, atlas)
                        else
                            pcall(DarkenFrameArt, r)
                        end
                    end
                end
            end
        end
    end
    pcall(HidePlayerLevel)
    if CONFIG.PVP_OVER_LEVEL then
        for _, e in ipairs(pvpArt) do
            local circles = {}
            for fs in pairs(levelTexts) do
                if UnitOfChain(fs) == e.unit then
                    local okc, x, y = pcall(function() return fs:GetCenter() end)
                    local tes = (fs.GetEffectiveScale and fs:GetEffectiveScale()) or 1
                    if okc and x then
                        for _, r in ipairs(ArtAround(fs)) do
                            if IsTexture(r) and r ~= e.tex then
                                local okb, l, b, w, h, es = pcall(function()
                                    local w0, h0 = r:GetSize()
                                    return r:GetLeft(), r:GetBottom(), w0, h0, (r.GetEffectiveScale and r:GetEffectiveScale()) or 1
                                end)
                                if okb and l and w and w > 0 and w <= CONFIG.LEVEL_CIRCLE_MAX and h <= CONFIG.LEVEL_CIRCLE_MAX then
                                    local cx, cy = x * tes, y * tes
                                    if cx >= l * es and cx <= (l + w) * es and cy >= b * es and cy <= (b + h) * es then
                                        circles[#circles + 1] = r
                                    end
                                end
                            end
                        end
                    end
                end
            end
            pcall(LiftPvP, e.tex, e.unit, circles)
        end
    end
end

-- once a second: put the look back on anything the game repainted
local function Recheck()
    if not (DB and DB.enabled) then return end
    pcall(UpdateRestGlow)
    for tex, t in pairs(touched) do
        if t.kind == "frame" then pcall(DarkenFrameArt, tex)
        elseif t.kind == "flat" then pcall(FlattenRing, tex)
        elseif t.kind == "hidden" then pcall(HideRegion, tex)
        elseif t.kind == "font" then pcall(ChatFont, tex)
        else pcall(CropIcon, tex) end
    end
end

---------------------------------------------------------------- player elite border

local function AtlasExists(name)
    if C_Texture and C_Texture.GetAtlasInfo then
        local ok, info = pcall(C_Texture.GetAtlasInfo, name)
        return ok and info ~= nil
    end
    return false
end

local function PlayerPortraitTex()
    local pf = PlayerFrame
    return _G.PlayerPortrait
        or (pf and rawget(pf, "portrait"))
        or (pf and pf.PlayerFrameContainer and pf.PlayerFrameContainer.PlayerPortrait)
end

local function PlaceElite()
    if not elite.tex then return end
    local portrait = PlayerPortraitTex() or PlayerFrame
    local x = (DB and DB.eliteX) or CONFIG.ELITE_X
    local y = (DB and DB.eliteY) or CONFIG.ELITE_Y
    elite.tex:ClearAllPoints()
    elite.tex:SetPoint("CENTER", portrait, "CENTER", x, y)
end

local function BuildElite()
    if elite.holder or not CONFIG.PLAYER_ELITE or not PlayerFrame then return end
    if InCombatLockdown and InCombatLockdown() then return end
    for _, name in ipairs(CONFIG.ELITE_ATLASES) do
        if AtlasExists(name) then elite.atlas = name; break end
    end
    if not elite.atlas then return end
    local h = CreateFrame("Frame", nil, PlayerFrame)
    h:SetAllPoints(PlayerFrame)
    h:EnableMouse(false)
    if h.SetFrameLevel and PlayerFrame.GetFrameLevel then h:SetFrameLevel(PlayerFrame:GetFrameLevel() + 10) end
    local t = h:CreateTexture(nil, "OVERLAY")
    t:SetAtlas(elite.atlas, true)
    if CONFIG.ELITE_SCALE ~= 1 and t.GetSize then
        local w, hh = t:GetSize()
        if w and hh then t:SetSize(w * CONFIG.ELITE_SCALE, hh * CONFIG.ELITE_SCALE) end
    end
    -- mirror: the target's dragon faces right, the player's should face left
    local ulx, uly, llx, lly, urx, ury, lrx, lry = t:GetTexCoord()
    if ulx and urx then t:SetTexCoord(urx, ury, lrx, lry, ulx, uly, llx, lly) end
    if t.SetDesaturated then t:SetDesaturated(true) end
    t:SetVertexColor(unpack(CONFIG.ELITE_COLOR))
    elite.holder, elite.tex = h, t
    PlaceElite()
end

-- the resting "ZZZ" animation's frame on the player frame
local function RestFrame()
    local pf = PlayerFrame
    local known = _G.PlayerRestLoop
        or (pf and pf.PlayerFrameContent and pf.PlayerFrameContent.PlayerFrameContentContextual
            and pf.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestLoop)
    if type(known) == "table" and known.GetFrameLevel then return known end
    if not EnumerateFrames then return nil end
    for _, f in ipairs(ScopeFrames()) do   -- only the unit frames, not the whole UI
        local okU, unit = pcall(UnitOfChain, f)
        if okU and unit == "player" and f.GetRegions then
            for _, r in ipairs({ f:GetRegions() }) do
                local a = AtlasOf(r)
                if a and a:lower():find("rest", 1, true) then return f end
            end
        end
    end
end

-- order on the player frame: rest flash < dragon < ZZZ
local layerNote = "not set yet"
local function LayerElite()
    if not (elite.holder and elite.holder.SetFrameLevel) then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local okR, rest = pcall(RestFrame)
    if not (okR and rest and rest.GetFrameLevel) then layerNote = "ZZZ frame not found"; return end
    -- highest frame holding a flash piece (not the ZZZ's own frame)
    local top, shared = nil, false
    for tex in pairs(restGlow) do
        local okP, owner = pcall(function() return tex:GetParent() end)
        if okP and owner and owner.GetFrameLevel then
            if owner == rest then shared = true
            else
                local l = owner:GetFrameLevel()
                if l and (not top or l > top) then top = l end
            end
        end
    end
    local want = math.max(elite.holder:GetFrameLevel(), (top or 0) + 1)
    if not top then want = math.min(want, math.max(0, rest:GetFrameLevel() - 1)) end
    elite.holder:SetFrameLevel(want)
    -- lift the ZZZ above the dragon
    if rest:GetFrameLevel() <= want then
        if not raised[rest] then raised[rest] = { kind = "level", level = rest:GetFrameLevel() } end
        pcall(rest.SetFrameLevel, rest, want + 1)
    end
    layerNote = ("flash frames up to %s, dragon %d, ZZZ %d%s"):format(tostring(top or "none"), want,
        rest:GetFrameLevel(), shared and " (some flash shares the ZZZ frame and stays on top)" or "")
end

LayerEliteHook = LayerElite

local function UpdateElite()
    if not elite.holder then pcall(BuildElite) end
    pcall(LayerElite)
    if elite.holder then elite.holder:SetShown(DB and DB.enabled and CONFIG.PLAYER_ELITE) end
end

local function NudgeElite(dx, dy)
    DB.eliteX = ((DB.eliteX) or CONFIG.ELITE_X) + dx
    DB.eliteY = ((DB.eliteY) or CONFIG.ELITE_Y) + dy
    PlaceElite()
end

---------------------------------------------------------------- commands
local function Say(m) print("|cff9999ffDarkIronUI_UnitFrames:|r " .. m) end

local function Debug()
    local dark, icons, skipped, seen = 0, 0, {}, {}
    local flat = 0
    for _, t in pairs(touched) do
        if t.kind == "frame" then dark = dark + 1 elseif t.kind == "flat" then flat = flat + 1 else icons = icons + 1 end
    end
    Say(("look %s (%s): %d pieces flat, %d darkened"):format(
        DB.enabled and "ON" or "off", CONFIG.STYLE, flat, dark))
    Say("player elite border: " .. (elite.holder and ("using " .. elite.atlas .. ", offset " ..
        ((DB.eliteX) or CONFIG.ELITE_X) .. "," .. ((DB.eliteY) or CONFIG.ELITE_Y))
        or "not created (elite art not found, or waiting for combat to end)"))
    pcall(LayerElite)
    Say("layers: " .. layerNote)
    local f = EnumerateFrames and EnumerateFrames()
    while f do
        local okS, inScope = pcall(InScope, f)
        if okS and inScope and f.GetRegions then
            for _, r in ipairs({ f:GetRegions() }) do
                local a = AtlasOf(r)
                if a and not seen[a] then
                    seen[a] = true
                    local t = touched[r]
                    local mark = (t and t.kind == "flat" and "flat") or (t and "dark") or "left alone"
                    skipped[#skipped + 1] = a .. "  [" .. mark .. "]"
                end
            end
        end
        f = EnumerateFrames(f)
    end
    local resting = IsResting and IsResting()
    local n = 0
    for _ in pairs(restGlow) do n = n + 1 end
    Say("resting: " .. (resting and "yes" or "no") .. ", flash pieces " .. (CONFIG.HIDE_REST_GLOW and "hidden: " or "found (kept visible, under the dragon): ") .. n)
    for tex, why in pairs(restGlow) do
        print("    " .. tostring(AtlasOf(tex) or SafeName(tex) or "unnamed art") .. "  (" .. tostring(why) .. ")")
    end
    local all = VisibleLevelTexts()
    Say("on-screen texts showing your level (" .. #all .. "):")
    for _, e in ipairs(all) do
        print("    " .. Path(e.r) .. (e.good and "   <- player frame" or ""))
    end
    if levelText then
        Say("player level text: " .. Path(levelText) .. ", " .. ((touched[levelText] and "hidden") or "visible"))
        local x, y = levelText:GetCenter()
        if not x then Say("that text has no position on screen") end
        local tes = (levelText.GetEffectiveScale and levelText:GetEffectiveScale()) or 1
        local near = {}
        if x then
            for _, r in ipairs(ArtAround(levelText)) do
                local okT, kind = pcall(function() return r:GetObjectType() end)
                if okT and kind == "Texture" then
                    local ok2, rx, ry, w, h, es = pcall(function()
                        local a, b = r:GetCenter(); local w0, h0 = r:GetSize()
                        return a, b, w0, h0, (r.GetEffectiveScale and r:GetEffectiveScale()) or 1
                    end)
                    if ok2 and rx then
                        local d = math.sqrt((rx * es - x * tes) ^ 2 + (ry * es - y * tes) ^ 2)
                        near[#near + 1] = { d = d, r = r, w = w, h = h }
                    end
                end
            end
            table.sort(near, function(p, q) return p.d < q.d end)
            Say("art nearest the level number:")
            for i = 1, math.min(#near, 8) do
                local n = near[i]
                local id = AtlasOf(n.r) or ("file " .. tostring(n.r.GetTexture and n.r:GetTexture()))
                print(("    %.0fpx away  %dx%d  %s  %s  [%s]"):format(n.d, n.w or 0, n.h or 0, id,
                    tostring(SafeName(n.r) or ""), touched[n.r] and touched[n.r].kind or "untouched"))
            end
        end
    else
        Say("player level text: NOT found. Player-frame texts:")
        for _, r in ipairs(playerRegions) do
            local okT, kind = pcall(function() return r:GetObjectType() end)
            if okT and kind == "FontString" then
                local okx, txt = pcall(function() return r:GetText() end)
                print("    '" .. tostring(okx and Plain(txt)) .. "'  " .. tostring(SafeName(r) or ""))
            end
        end
    end
    table.sort(skipped)
    Say("artwork in the player/target/focus frames (" .. #skipped .. "):")
    for i = 1, math.min(#skipped, 30) do print("  " .. skipped[i]) end
    if #skipped == 0 then Say("no player/target/focus frames found.") end
end

SLASH_FLATUNITFRAMES1 = "/uff"
SlashCmdList["FLATUNITFRAMES"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S*)")
    local sub, num = (msg or ""):lower():match("^%s*%S+%s+(%S+)%s*(%S*)")
    if cmd == "debug" then
        Debug()
    elseif cmd == "elite" then
        local n = tonumber(num) or 2
        if sub == "left" then NudgeElite(-n, 0)
        elseif sub == "right" then NudgeElite(n, 0)
        elseif sub == "up" then NudgeElite(0, n)
        elseif sub == "down" then NudgeElite(0, -n)
        elseif sub == "reset" then DB.eliteX, DB.eliteY = nil, nil; PlaceElite() end
    else
        DB.enabled = not DB.enabled
        if DB.enabled then Scan() else Restore() end
        UpdateElite()
        Say("flat look " .. (DB.enabled and "on" or "off"))
    end
end

local macroPending = true
local function TryMacros()
    if not macroPending or (InCombatLockdown and InCombatLockdown()) then return end
    macroPending = false
    if not (GetMacroIndexByName and CreateMacro and GetNumMacros) then return end
    pcall(function()
        for _, m in ipairs({ { "UFF Toggle", "/uff" }, { "UFF Debug", "/uff debug" },
                             { "UFF Elite Left", "/uff elite left" }, { "UFF Elite Right", "/uff elite right" },
                             { "UFF Elite Up", "/uff elite up" }, { "UFF Elite Down", "/uff elite down" } }) do
            local idx = GetMacroIndexByName(m[1])
            if not (idx and idx > 0) and GetNumMacros() < (MAX_ACCOUNT_MACROS or 36) then
                if not pcall(CreateMacro, m[1], "Spell_Shadow_Twilight", m[2], nil) then
                    pcall(CreateMacro, m[1], "INV_MISC_QUESTIONMARK", m[2], nil)
                end
            end
        end
    end)
end

---------------------------------------------------------------- events
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("CVAR_UPDATE")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("PLAYER_UPDATE_RESTING")
events:RegisterEvent("PLAYER_FOCUS_CHANGED")
local ADDON = ...
local scanQueued, scanMissed = false, false
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then
            DarkIronUI_UnitFramesDB = DarkIronUI_UnitFramesDB or {}
            DB = DarkIronUI_UnitFramesDB
            if DB.eliteY and not DB.moved03 then DB.eliteY = DB.eliteY - 5 end
            DB.moved03 = true
            if DB.eliteY and not DB.moved04 then DB.eliteY = DB.eliteY - 3 end
            DB.moved04 = true
            if DB.enabled == nil then DB.enabled = true end
        end
        return
    end
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED" then TryMacros() end
    if event == "PLAYER_ENTERING_WORLD" then scopeRoots = nil end
    if event == "CVAR_UPDATE" and not (type(arg1) == "string" and arg1:lower():find("gamepad", 1, true)) then return end
    -- full searches only outside combat; the 1s re-check covers combat.
    -- leaving combat: only rescan if a scan was skipped during the fight
    if event == "PLAYER_REGEN_ENABLED" and not scanMissed then return end
    if scanQueued then return end
    scanQueued = true
    C_Timer.After(0.40, function()   -- staggered against the other DarkIronUI parts
        scanQueued = false
        if InCombatLockdown and InCombatLockdown() then scanMissed = true; return end
        scanMissed = false
        pcall(M, "scan", Scan); pcall(M, "elite", UpdateElite)
    end)
end)

if C_Timer.NewTicker then C_Timer.NewTicker(1, function() M("recheck", Recheck) end) end
