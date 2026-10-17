-- HideCrosshairs 0.3
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
local guard = false

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

local function Blank(obj, why)
    if hidden[obj] then
        if obj:GetAlpha() ~= 0 then obj:SetAlpha(0) end
        return
    end
    hidden[obj] = why
    obj:SetAlpha(0)
    hooksecurefunc(obj, "SetAlpha", function(self, a)
        if guard or a == 0 then return end
        guard = true
        pcall(self.SetAlpha, self, 0)
        guard = false
    end)
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
                    pcall(Blank, obj, "name: " .. name)
                end
            end
        end
    end
    for _, name in ipairs(CONFIG.NAMES) do
        local obj = _G[name]
        if type(obj) == "table" and IsUsable(obj) then pcall(Blank, obj, "name: " .. name) end
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
    C_Timer.After(0.5, Scan)
end)
