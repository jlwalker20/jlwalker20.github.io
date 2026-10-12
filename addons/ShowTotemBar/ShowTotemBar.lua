-- ShowTotemBar
-- Forces the totem bar to stay visible regardless of input device, working
-- around it apparently being force-hidden (or its Edit Mode mover not
-- spawning) while a gamepad is active.
--
-- No slash commands, no print() calls -- nothing writes to chat. Every step
-- is wrapped in pcall so a wrong frame-name guess fails silently instead of
-- throwing errors. No fast-repeating OnUpdate loop -- only normal game
-- events trigger a re-check.
--
-- 1.1: never touches the bar during combat (the game blocks addons from
-- showing secure action bar frames then, which caused "Interface action
-- failed because of an AddOn"). It waits for combat to end instead.
--
-- [Classic/Beta assumption] This tries a short list of plausible frame
-- names for the totem bar, since I haven't been able to confirm which one
-- Forever actually uses. "MultiCastActionBarFrame" is Blizzard's long-
-- standing internal name for the totem bar (dating back to Cataclysm) and
-- is the most likely candidate; the others are fallbacks in case Forever
-- renamed or rebuilt it for the new Edit Mode system. If none of these
-- exist, this addon safely does nothing -- tell me and I'll need another
-- way to find the real name (ideally without typing in chat while a
-- gamepad is connected, given what happened last time).

local CANDIDATE_FRAME_NAMES = {
    "MultiCastActionBarFrame",
    "TotemFrame",
    "ShamanBarFrame",
    "PlayerTotemFrame",
}

local function SafeCall(fn, ...)
    local ok = pcall(fn, ...)
    return ok
end

local found = {} -- name -> frame, once located
local hooked = {}
local needsShow = false -- a Show was wanted during combat; do it afterwards

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function LocateFrames()
    for _, name in ipairs(CANDIDATE_FRAME_NAMES) do
        if not found[name] then
            local f = _G[name]
            if f then
                found[name] = f
            end
        end
    end
end

local ForceShow

-- The totem bar is part of the secure action bars. The game refuses ("Interface
-- action failed because of an AddOn") when an addon shows or hides one of
-- those during combat, so nothing is touched until combat ends.
local function QueueShow()
    if InCombat() then
        needsShow = true
        return
    end
    -- one frame later, so we never act in the middle of Blizzard's own code
    C_Timer.After(0, function() SafeCall(ForceShow) end)
end

ForceShow = function()
    if InCombat() then
        needsShow = true
        return
    end
    needsShow = false
    for name, f in pairs(found) do
        if f and f.Show then
            if f.IsShown and not f:IsShown() then
                f:Show()
            end
            if f.SetAlpha then
                f:SetAlpha(1)
            end
            if not hooked[name] and f.HookScript then
                hooked[name] = true
                f:HookScript("OnHide", QueueShow)
            end
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
frame:RegisterEvent("PLAYER_TOTEM_UPDATE")

frame:SetScript("OnEvent", function(_, event)
    SafeCall(function()
        LocateFrames()
        if event == "PLAYER_REGEN_ENABLED" or not InCombat() then
            ForceShow()
        else
            needsShow = true
        end
    end)
end)
