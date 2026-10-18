-- HideCrosshairs 0.5
-- Hides the red (enemy) and green (friendly) target crosshairs that the
-- gamepad UI shows above the action bars, on the bumpers (LB / RB). Your
-- bumper bindings keep working; only the icons become invisible.
--
-- How: it makes them fully transparent (alpha 0) instead of hiding them.
-- Hiding parts of the secure action bars in combat is blocked by the game;
-- transparency is not.
--
-- Finding them (their internal names aren't documented), two ways:
--  1. named frames: gamepad frames whose names contain a MATCH word
--  2. artwork: inside any gamepad frame, textures whose atlas name contains
--     an ART word (e.g. "crosshair", "target")
-- The "HC Debug" macro (created for you) prints what it hid and what else
-- it can see, so the exact pieces can be targeted by name if needed.
--
-- 0.5: narrower. Only artwork drawn by the matched piece itself (not
-- anything attached to it, like the menu a bumper opens), and only artwork
-- that is on screen at the moment it searches (menus are closed then).
--
-- 0.4: no longer touches Blizzard's frames or buttons at all, and no longer
-- hooks any Blizzard function. 0.3 made the buttons themselves transparent
-- and hooked their SetAlpha, which the gamepad bars also use when they
-- fade; that could get Blizzard's own bar code blocked ("blocked from an
-- action only available to the Blizzard UI"). 0.4 only fades the icon
-- ARTWORK (textures) and re-checks it once a second instead of hooking.
--
-- 0.3: only touches things INSIDE the gamepad action bars. 0.2 also caught
-- the aiming crosshair in the middle of the screen, which lives elsewhere
-- in the gamepad UI. "Reticle" is no longer a match word either.

local CONFIG = {
    SCOPE = { "Gamepad", "GamePad" },
    MATCH = { "Target", "Crosshair", "Bumper", "Shoulder" },
    SKIP  = { "Bind", "Label", "Text", "Frame$" },
    ART   = { "crosshair", "target", "bumper", "shoulder" },
    -- must sit inside a frame whose name contains one of these
    BARS  = { "ActionBar" },
    -- never touch frames/art whose name contains one of these
    NEVER = { "Reticle", "reticle", "Cursor", "cursor", "Aim", "aim" },
    -- exact names to hide, if the debug output shows them (filled in later)
    NAMES = {},
}

local hidden = {}   -- object -> description

local function has(s, list, lower)
    if type(s) ~= "string" then return false end
    if lower then s = s:lower() end
    for _, p in ipairs(list) do
        if s:find(p) then return true end
    end
    return false
end

local function SafeName(obj)
    local ok, n = pcall(function() return obj.GetName and obj:GetName() end)
    return ok and type(n) == "string" and n or nil
end

local function InGamepadUI(obj)
    local cur, depth = obj, 0
    while cur and depth < 10 do
        if has(SafeName(cur), CONFIG.SCOPE) then return true end
        local ok, p = pcall(function() return cur:GetParent() end)
        cur = ok and p or nil
        depth = depth + 1
    end
    return false
end

local function InActionBars(obj)
    local cur, depth = obj, 0
    while cur and depth < 10 do
        local n = SafeName(cur)
        if has(n, CONFIG.NEVER) then return false end
        if has(n, CONFIG.BARS) then return true end
        local ok, p = pcall(function() return cur:GetParent() end)
        cur = ok and p or nil
        depth = depth + 1
    end
    return false
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

local function IsTexture(obj)
    local ok, t = pcall(function() return obj.GetObjectType and obj:GetObjectType() end)
    return ok and (t == "Texture" or t == "MaskTexture")
end

-- Only ever fades artwork (textures). Never a frame or button.
local function Blank(obj, why)
    if not IsTexture(obj) then return end
    if not hidden[obj] then
        -- only adopt artwork that is on screen right now (menus are closed
        -- when the search runs, so their artwork is left alone)
        local okv, vis = pcall(function() return obj.IsVisible and obj:IsVisible() end)
        if not (okv and vis) then return end
    end
    hidden[obj] = hidden[obj] or why
    if obj:GetAlpha() ~= 0 then obj:SetAlpha(0) end
end

-- For a matched named frame: fade only the artwork it draws itself.
-- (Not its children: the menu a bumper opens hangs off these.)
local function BlankArtOf(frame, why)
    if not (frame and frame.GetRegions) then return end
    for _, r in ipairs({ frame:GetRegions() }) do pcall(Blank, r, why) end
end

local function IsUsable(obj)
    local okf, forbidden = pcall(function() return obj.IsForbidden and obj:IsForbidden() end)
    return not (okf and forbidden) and obj.SetAlpha ~= nil
end

-- 1. named frames
local function ScanNames()
    for name, obj in pairs(_G) do
        if type(name) == "string" and type(obj) == "table" and has(name, CONFIG.SCOPE) then
            local exact = false
            for _, n in ipairs(CONFIG.NAMES) do if n == name then exact = true end end
            if exact or (has(name, CONFIG.MATCH) and not has(name, CONFIG.SKIP)) then
                local ok, t = pcall(function() return obj.GetObjectType and obj:GetObjectType() end)
                local okb, inBars = pcall(InActionBars, obj)
                if ok and t and IsUsable(obj) and (exact or (okb and inBars)) then
                    pcall(BlankArtOf, obj, "art of " .. name)
                end
            end
        end
    end
    for _, name in ipairs(CONFIG.NAMES) do
        local obj = _G[name]
        if type(obj) == "table" and IsUsable(obj) then pcall(BlankArtOf, obj, "art of " .. name) end
    end
end

-- 2. artwork inside gamepad frames
local function AtlasOf(region)
    local ok, a = pcall(function() return region.GetAtlas and region:GetAtlas() end)
    return ok and type(a) == "string" and a or nil
end

local function EachGamepadFrame(fn)
    if not EnumerateFrames then return end
    local f = EnumerateFrames()
    while f do
        local okv, gp = pcall(InGamepadUI, f)
        if okv and gp then pcall(fn, f) end
        f = EnumerateFrames(f)
    end
end

local function ScanArt()
    EachGamepadFrame(function(f)
        if not f.GetRegions or not InActionBars(f) then return end
        for _, r in ipairs({ f:GetRegions() }) do
            local atlas = AtlasOf(r)
            if atlas and has(atlas, CONFIG.ART, true) and not has(atlas, CONFIG.NEVER) and IsUsable(r) then
                Blank(r, "art: " .. atlas .. "  in " .. Path(f))
            end
        end
    end)
end

local function Scan()
    pcall(ScanNames)
    pcall(ScanArt)
end

---------------------------------------------------------------- debug
local function Say(m) print("|cffff8080HideCrosshairs:|r " .. m) end

local function Debug()
    Scan()
    local n = 0
    for _, why in pairs(hidden) do n = n + 1; Say("hidden " .. why) end
    if n == 0 then Say("nothing matched.") end
    -- every atlas used inside the gamepad UI, so the crosshair art can be named
    local seen, atlases = {}, {}
    EachGamepadFrame(function(f)
        if not f.GetRegions then return end
        for _, r in ipairs({ f:GetRegions() }) do
            local a = AtlasOf(r)
            if a and not seen[a] then
                seen[a] = true
                atlases[#atlases + 1] = a .. "  (" .. Path(f) .. ")"
            end
        end
    end)
    table.sort(atlases)
    Say("artwork in the gamepad UI (" .. #atlases .. "):")
    for i = 1, math.min(#atlases, 30) do print("  " .. atlases[i]) end
    if #atlases == 0 then Say("no gamepad frames found. Is gamepad mode on?") end
end

SLASH_HIDECROSSHAIRS1 = "/hidecrosshairs"
SlashCmdList["HIDECROSSHAIRS"] = function() Debug() end

local macroPending = true
local function TryMacro()
    if not macroPending or (InCombatLockdown and InCombatLockdown()) then return end
    macroPending = false
    if not (GetMacroIndexByName and CreateMacro and GetNumMacros) then return end
    pcall(function()
        local idx = GetMacroIndexByName("HC Debug")
        if not (idx and idx > 0) and GetNumMacros() < (MAX_ACCOUNT_MACROS or 36) then
            if not pcall(CreateMacro, "HC Debug", "Ability_Hunter_SniperShot", "/hidecrosshairs", nil) then
                pcall(CreateMacro, "HC Debug", "INV_MISC_QUESTIONMARK", "/hidecrosshairs", nil)
            end
        end
    end)
end

---------------------------------------------------------------- events
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("CVAR_UPDATE")
events:SetScript("OnEvent", function(_, event)
    if event ~= "ADDON_LOADED" then TryMacro() end
    C_Timer.After(0.5, function()
        -- full searches only outside combat; the re-check below covers combat
        if not (InCombatLockdown and InCombatLockdown()) then Scan() end
    end)
end)

-- Once a second, put back any icon the game has faded in again.
-- (Reading and fading artwork only; nothing of Blizzard's is hooked.)
local function Recheck()
    for tex in pairs(hidden) do
        local ok, a = pcall(tex.GetAlpha, tex)
        if ok and a and a ~= 0 then pcall(tex.SetAlpha, tex, 0) end
    end
end
if C_Timer.NewTicker then
    C_Timer.NewTicker(1, Recheck)
else
    local acc = 0
    events:SetScript("OnUpdate", function(_, e) acc = acc + e; if acc >= 1 then acc = 0; Recheck() end end)
end
