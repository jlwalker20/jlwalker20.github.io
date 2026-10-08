-- ShowTotemBar
-- Forces the totem bar to stay visible regardless of input device, working
-- around it apparently being force-hidden (or its Edit Mode mover not
-- spawning) while a gamepad is active.
--
-- No slash commands, no print() calls -- nothing writes to chat. Every step
-- is wrapped in pcall so a wrong frame-name guess fails silently instead of
-- throwing errors. No fast-repeating OnUpdate loop -- only normal game
-- events trigger a re-check, same pattern as CastBarFix.
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

local function ForceShow()
    for name, f in pairs(found) do
        if f and f.Show then
            f:Show()
            if f.SetAlpha then
                f:SetAlpha(1)
            end
            if not hooked[name] and f.HookScript then
                hooked[name] = true
                f:HookScript("OnHide", function(self)
                    self:Show()
                end)
            end
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
frame:RegisterEvent("PLAYER_TOTEM_UPDATE")

frame:SetScript("OnEvent", function()
    SafeCall(function()
        LocateFrames()
        ForceShow()
    end)
end)
