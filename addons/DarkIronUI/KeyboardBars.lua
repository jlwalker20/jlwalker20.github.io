-- DarkIronUI_KeyboardBars 1.0
-- The DarkIronUI gamepad action bar look (flat light-grey rings with a darker
-- outline, darkened slots, full-color icons) for the regular mouse & keyboard
-- action bars: main bar, the extra MultiBars, stance and pet bars. The
-- gryphon/wyvern end caps and bar dividers are greyed to match.

-- run once even if both DarkIronUI and DarkIronUI_KeyboardBars are installed
if _G.DarkIronUI_KeyboardBars_Running then return end
_G.DarkIronUI_KeyboardBars_Running = true
--
-- Safety: same rules as the gamepad module. Only the color, crop and alpha of
-- artwork change; our flat copies live on our own frames; no Blizzard code is
-- hooked; searches run out of combat only, with a 1s re-check.
--
-- Macros (created for you):
--   DKB Toggle   turn the look on/off
--   DKB Debug    list the artwork it found

local CONFIG = {
    STYLE = "dark",      -- "dark" = Blizzard's own ring art greyed (crisp); "flat" = solid stencil copy (looks soft/glowy on these bars)
    FILL_COLOR = { 0.70, 0.70, 0.70, 1 },    -- flat ring fill (light grey)
    BORDER_COLOR = { 0.40, 0.40, 0.40, 1 },  -- thin outline around each ring
    BORDER_SIZE = 1.5,                       -- outline thickness in pixels (0 = no outline)
    RING_ART = { "frame", "border", "ring", "rim", "edge", "trim" },  -- drawn flat
    -- empty-slot / behind-the-icon art: always darkened, never drawn over
    SLOT_ART = { "slot", "background", "backplate", "bg", "base", "empty", "plate" },
    EMPTY_DARKNESS = 0.50,
    DARKNESS = 0.70,     -- ring brightness: 0 = black, 1 = unchanged. Raise for lighter rings, lower for darker
    DESATURATE = true,   -- grey out the frame art before darkening
    ICON_CROP = 0.07,    -- trim this much off each icon edge (0 = off)
    -- artwork names (atlas) that count as button frame/border art
    FRAME_ART = { "empty", "frame", "border", "ring", "backplate", "background", "bg", "plate", "slot", "circle", "base", "edge", "rim", "trim", "bar",
                  "gryphon", "wyvern", "endcap", "divider" },
    -- never touch artwork whose name contains any of these
    NEVER = { "glow", "highlight", "flash", "cooldown", "proc", "activation", "glyph", "crosshair", "target",
              "reticle", "cursor", "swipe", "bling", "mask", "pushed", "checked", "autocast", "shine", "spark",
              "arrow", "keybind", "hotkey", "down", "mouseover", "hover", "lt", "rt", "lb", "rb" },
    -- frame must sit inside one of these bars (and NOT inside the gamepad UI)
    SCOPE = { "MainMenuBar", "MainActionBar", "MultiBar", "ActionButton", "MultiAction", "StanceBar",
              "PetActionBar", "PossessBar", "OverrideActionBar" },
    EXCLUDE = { "Gamepad", "GamePad", "StatusTracking", "ExpBar", "ReputationWatch", "MaxLevelBar",
                "MicroButton", "MicroMenu", "Bag", "Backpack", "KeyRing" },  -- other modules' parts
}

local DB
local touched = {}  -- texture -> { kind="frame"|"icon", orig={...} }

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

local function InScope(frame)
    local cur, depth, inBar = frame, 0, false
    while cur and depth < 10 do
        local n = SafeName(cur)
        if has(n, CONFIG.EXCLUDE) then return false end
        if has(n, CONFIG.SCOPE) then inBar = true end
        local ok, p = pcall(function() return cur:GetParent() end)
        cur = ok and p or nil
        depth = depth + 1
    end
    return inBar
end

-- the bars' top-level frames, found once from UIParent's children, then walked;
-- far cheaper than looking at every frame in the UI on each slot change
local roots
local function BarFrames()
    if not roots then
        roots = {}
        local ok, kids = pcall(function() return { UIParent:GetChildren() } end)
        for _, f in ipairs(ok and kids or {}) do
            local n = SafeName(f)
            if n and has(n, CONFIG.SCOPE) and not has(n, CONFIG.EXCLUDE) then roots[#roots + 1] = f end
        end
    end
    local list, seen = {}, {}
    local function walk(f, d)
        if not f or seen[f] or d > 8 then return end
        seen[f] = true
        list[#list + 1] = f
        local ok, kids = pcall(function() return { f:GetChildren() } end)
        if ok then for _, c in ipairs(kids) do walk(c, d + 1) end end
    end
    for _, f in ipairs(roots) do walk(f, 0) end
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

local function Restore()
    for tex, t in pairs(touched) do
        if t.kind == "frame" then
            local o = t.orig
            pcall(tex.SetVertexColor, tex, o[1], o[2], o[3], o[4])
            if tex.SetDesaturated then pcall(tex.SetDesaturated, tex, o[5]) end
        elseif t.kind == "flat" then
            t.holder:Hide()
            pcall(tex.SetAlpha, tex, t.origAlpha or 1)
        else
            pcall(tex.SetTexCoord, tex, 0, 1, 0, 1)
        end
    end
    wipe(touched)
end

-- find artwork in the gamepad action bars and apply the look
local function Scan()
    if not (DB and DB.enabled) then return end
    for _, f in ipairs(BarFrames()) do
        local okS, inScope = pcall(InScope, f)
        if okS and inScope and f.GetRegions then
            local icon = IconOf(f)
            if icon then pcall(CropIcon, icon) end
            for _, r in ipairs({ f:GetRegions() }) do
                if r ~= icon and IsTexture(r) then
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
end

-- once a second: put the look back on anything the game repainted
local function Recheck()
    if not (DB and DB.enabled) then return end
    for tex, t in pairs(touched) do
        if t.kind == "frame" then pcall(DarkenFrameArt, tex)
        elseif t.kind == "flat" then pcall(FlattenRing, tex)
        else pcall(CropIcon, tex) end
    end
end

---------------------------------------------------------------- commands
local function Say(m) print("|cff9999ffDarkIronUI_KeyboardBars:|r " .. m) end

local function Debug()
    local dark, icons, skipped, seen = 0, 0, {}, {}
    local flat = 0
    for _, t in pairs(touched) do
        if t.kind == "frame" then dark = dark + 1 elseif t.kind == "flat" then flat = flat + 1 else icons = icons + 1 end
    end
    Say(("look %s (%s): %d pieces flat, %d darkened, %d icons cropped"):format(
        DB.enabled and "ON" or "off", CONFIG.STYLE, flat, dark, icons))
    for _, f in ipairs(BarFrames()) do
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
    end
    table.sort(skipped)
    Say("artwork in the action bars (" .. #skipped .. "):")
    for i = 1, math.min(#skipped, 30) do print("  " .. skipped[i]) end
    if #skipped == 0 then Say("no action bars found (in gamepad mode the gamepad bars replace them)") end
end

SLASH_DARKIRONUI_KBARS1 = "/dkb"
SlashCmdList["DARKIRONUI_KBARS"] = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S*)")
    if cmd == "debug" then
        Debug()
    else
        DB.enabled = not DB.enabled
        if DB.enabled then Scan() else Restore() end
        Say("look " .. (DB.enabled and "on" or "off"))
    end
end

local macroPending = true
local function TryMacros()
    if not macroPending or (InCombatLockdown and InCombatLockdown()) then return end
    macroPending = false
    if not (GetMacroIndexByName and CreateMacro and GetNumMacros) then return end
    pcall(function()
        for _, m in ipairs({ { "DKB Toggle", "/dkb" }, { "DKB Debug", "/dkb debug" } }) do
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
events:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
local ADDON = ...
local scanQueued = false
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then
            DarkIronUI_KeyboardBarsDB = DarkIronUI_KeyboardBarsDB or {}
            DB = DarkIronUI_KeyboardBarsDB
            if DB.enabled == nil then DB.enabled = true end
        end
        return
    end
    if event ~= "ACTIONBAR_SLOT_CHANGED" then TryMacros() end
    if event == "PLAYER_ENTERING_WORLD" then roots = nil end
    -- full searches only outside combat; the 1s re-check covers combat
    if scanQueued then return end
    scanQueued = true
    C_Timer.After(0.5, function()
        scanQueued = false
        if not (InCombatLockdown and InCombatLockdown()) then pcall(Scan) end
    end)
end)

if C_Timer.NewTicker then C_Timer.NewTicker(1, Recheck) end
