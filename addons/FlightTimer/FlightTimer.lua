-- FlightTimer
-- A plain text countdown for flight paths, lower-middle of the screen.
--
-- The game doesn't tell addons how long a flight takes, so this LEARNS it:
-- the first time you fly a route it shows time elapsed ("learning"), and
-- from then on that route counts down. Routes are remembered between
-- sessions, and a route you've only flown the other way uses that time as
-- an estimate until you fly it yourself.
--
-- Moving it (works in gamepad mode too, via macros):
--   /ft unlock        show a placeholder you can drag with a mouse
--   /ft lock          hide the placeholder, keep the position
--   /ft up|down|left|right [pixels]    nudge 10px (or your number)
--   /ft reset         back to the default spot
--   /ft redo          re-record: the next flight you take (or the one you're
--                     on right now) replaces the saved time for its route
--   /ft redo off      cancel a pending redo
--   /ft forget        delete the saved time for the current / last route
--   /ft help          list all commands
--   /ft clear         forget all learned flight times
--   /ft status        routes learned, last route and its time
-- Typing in chat can freeze the game in gamepad mode, so the addon creates
-- macros for these (FT Move, FT Up, FT Down, FT Left, FT Right, FT Redo,
-- FT Forget, FT Clear). Find them in /macro and drag them to a bar.

local ADDON = ...

local DEFAULT_POS = { "CENTER", "CENTER", 0, -250 }  -- point, relPoint, x, y
local NUDGE_STEP = 10
local FONT = "GameFontNormalLarge"                    -- the default UI font

local DB
local unlocked = false
local pending, flight, lastOrigin, lastKey, clearArmedAt

---------------------------------------------------------------- frame
local frame = CreateFrame("Frame", "FlightTimerFrame", UIParent)
frame:SetSize(280, 40)
frame:SetFrameStrata("MEDIUM")
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:EnableMouse(false)  -- only on while unlocked
frame:Hide()

local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
if bg.SetColorTexture then bg:SetColorTexture(0, 0, 0, 0.45) else bg:SetTexture(0, 0, 0, 0.45) end
bg:Hide()

local text = frame:CreateFontString(nil, "OVERLAY", FONT)
text:SetPoint("CENTER")

local function IsControllerMode()
    local ok, on = pcall(function()
        if C_GamePad and C_GamePad.IsEnabled then return C_GamePad.IsEnabled() end
        return GetCVar("GamePadEnable") == "1"
    end)
    return ok and on
end

---------------------------------------------------------------- position
local function ApplyPosition()
    local p = (DB and DB.pos) or DEFAULT_POS
    frame:ClearAllPoints()
    frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
end

local function SavePosition()
    local point, _, rel, x, y = frame:GetPoint()
    if point and DB then DB.pos = { point, rel, x, y } end
end

local function Nudge(dx, dy)
    local point, _, rel, x, y = frame:GetPoint()
    if not point then return end
    frame:ClearAllPoints()
    frame:SetPoint(point, UIParent, rel, x + dx, y + dy)
    SavePosition()
end

frame:SetScript("OnDragStart", function(self)
    if unlocked then self:StartMoving() end
end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SavePosition()
end)

---------------------------------------------------------------- display
local function Fmt(sec)
    sec = math.max(0, math.floor(sec + 0.5))
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

local function Render()
    if flight then
        local elapsed = GetTime() - flight.start
        if flight.expected then
            local left = flight.expected - elapsed
            if left > 0 then
                text:SetText("Flight: " .. Fmt(left))
            else
                text:SetText("Landing...")
            end
        else
            text:SetText("Flying: " .. Fmt(elapsed) .. " (learning)")
        end
        frame:Show()
    elseif unlocked then
        text:SetText("Flight: 1:23")
        frame:Show()
    else
        frame:Hide()
    end
end

---------------------------------------------------------------- flight tracking
local driver = CreateFrame("Frame")
local acc = 0
local Tick

local function Watch(on)
    if on then
        acc = 0
        driver:SetScript("OnUpdate", function(_, elapsed)
            acc = acc + elapsed
            if acc < 0.2 then return end
            acc = 0
            Tick()
        end)
    else
        driver:SetScript("OnUpdate", nil)
    end
end

local function ServerNow()
    return (GetServerTime and GetServerTime()) or time()
end

local function RouteKey(from, to) return (from or "?") .. " -> " .. (to or "?") end

local function Expected(from, to)
    if not (from and to and DB) then return nil end
    local direct = DB.routes[RouteKey(from, to)]
    if direct then return direct, false end
    local reverse = DB.routes[RouteKey(to, from)]
    if reverse then return reverse, true end
    return nil
end

local function StartFlight()
    local from, to = pending.from, pending.to
    pending = nil
    local redo = DB.redo and true or nil
    local expected, estimated
    if not redo then expected, estimated = Expected(from, to) end
    flight = { from = from, to = to, start = GetTime(), expected = expected, estimated = estimated, redo = redo }
    if from and to then
        lastKey = RouteKey(from, to)
        -- survives /reload: a reload mid-flight picks the flight back up
        DB.inflight = { from = from, to = to, t0 = ServerNow(), redo = redo }
    end
    Render()
end

local function EndFlight()
    if flight and flight.from and flight.to and DB then
        local elapsed = GetTime() - flight.start
        local key = RouteKey(flight.from, flight.to)
        local old = DB.routes[key]
        if flight.redo then
            -- you asked for a fresh recording: trust this flight completely
            if elapsed >= 5 then
                DB.routes[key] = math.floor(elapsed + 0.5)
                DB.redo = nil
            end
        elseif elapsed >= 5 and (not old or elapsed >= old * 0.8) then
            -- (a much shorter time than a known route is a partial hop: ignored)
            DB.routes[key] = math.floor(elapsed + 0.5)
        end
    end
    if DB then DB.inflight = nil end
    flight = nil
    Watch(false)
    Render()
end

Tick = function()
    local onTaxi = UnitOnTaxi and UnitOnTaxi("player")
    if flight then
        if not onTaxi then EndFlight() else Render() end
    elseif pending then
        if onTaxi then
            StartFlight()
        elseif GetTime() - pending.t > 20 then
            pending = nil
            Watch(false)
        end
    end
end

local function CurrentNodeName()
    if not (NumTaxiNodes and TaxiNodeGetType and TaxiNodeName) then return nil end
    for i = 1, NumTaxiNodes() do
        if TaxiNodeGetType(i) == "CURRENT" then return TaxiNodeName(i) end
    end
end

if TakeTaxiNode then
    hooksecurefunc("TakeTaxiNode", function(slot)
        local ok, to = pcall(TaxiNodeName, slot)
        local from = CurrentNodeName() or lastOrigin
        pending = { from = from, to = ok and to or nil, t = GetTime() }
        Watch(true)
    end)
end

---------------------------------------------------------------- lock / unlock
local function SetUnlocked(on)
    unlocked = on
    if on then
        bg:Show()
        -- in gamepad mode the frame never takes the mouse; use the nudge commands
        if not IsControllerMode() then frame:EnableMouse(true) end
    else
        bg:Hide()
        frame:EnableMouse(false)
    end
    Render()
end

---------------------------------------------------------------- slash command
local function Say(msg) print("|cff66ccffFlightTimer:|r " .. msg) end

local function CountRoutes()
    local n = 0
    for _ in pairs(DB.routes) do n = n + 1 end
    return n
end

SLASH_FLIGHTTIMER1 = "/flighttimer"
SLASH_FLIGHTTIMER2 = "/ft"
SlashCmdList["FLIGHTTIMER"] = function(msg)
    local cmd, arg = (msg or ""):lower():match("^%s*(%S*)%s*(%S*)")
    local n = tonumber(arg) or NUDGE_STEP
    if cmd == "unlock" then SetUnlocked(true)
    elseif cmd == "lock" then SetUnlocked(false)
    elseif cmd == "" then SetUnlocked(not unlocked)
    elseif cmd == "up" then Nudge(0, n)
    elseif cmd == "down" then Nudge(0, -n)
    elseif cmd == "left" then Nudge(-n, 0)
    elseif cmd == "right" then Nudge(n, 0)
    elseif cmd == "reset" then DB.pos = nil; ApplyPosition()
    elseif cmd == "clear" then
        -- destructive and easy to hit by accident from a macro: needs a second press
        if clearArmedAt and GetTime() - clearArmedAt < 10 then
            clearArmedAt = nil
            DB.routes = {}; DB.redo = nil; DB.inflight = nil
            Say("forgot all learned flight times")
        else
            clearArmedAt = GetTime()
            Say("this erases ALL learned flight times. Do it again within 10 seconds to confirm.")
        end
    elseif cmd == "redo" or cmd == "rerecord" then
        if arg == "off" or arg == "cancel" then
            DB.redo = nil
            Say("redo cancelled")
        elseif flight and flight.from and flight.to then
            flight.redo = true
            flight.expected = nil
            if DB.inflight then DB.inflight.redo = true end
            Say("re-recording this flight; the new time replaces the saved one when you land")
        else
            DB.redo = true
            Say("your next flight will be re-recorded and replace the saved time")
        end
    elseif cmd == "forget" then
        local key = (flight and flight.from and flight.to and RouteKey(flight.from, flight.to)) or lastKey
        if key and DB.routes[key] then
            DB.routes[key] = nil
            Say("forgot " .. key)
        else
            Say("no route to forget yet; fly one first")
        end
    elseif cmd == "status" then
        local last = lastKey and DB.routes[lastKey]
        Say(CountRoutes() .. " routes learned" ..
            (lastKey and (", last: " .. lastKey .. (last and (" = " .. Fmt(last)) or " (not saved)")) or "") ..
            (DB.redo and ", redo armed" or ""))
    else
        Say("commands (/ft or /flighttimer):")
        Say("  unlock / lock     show or hide the placeholder for moving (/ft alone toggles)")
        Say("  up|down|left|right [px]   nudge the timer (10px by default)")
        Say("  reset             put the timer back at the default spot")
        Say("  redo [off]        re-record the next (or current) flight; off cancels")
        Say("  forget            delete the saved time for the current/last route")
        Say("  clear             forget every learned flight time (asks you to repeat it)")
        Say("  status            routes learned, last route and its time")
        Say("  help              this list")
    end
end

---------------------------------------------------------------- macros
-- Typing in chat can freeze the game in gamepad mode (a Blizzard bug), but
-- macros run the same commands safely. So the addon makes these macros for
-- you the first time it loads (look in /macro, General tab) and you can
-- drag them onto your bars. Set CREATE_MACROS = false to turn this off.
local CREATE_MACROS = true
local MACRO_ICON = "INV_Misc_Map_01"
local MACROS = {
    { "FT Move", "/ft" },
    { "FT Up", "/ft up" },
    { "FT Down", "/ft down" },
    { "FT Left", "/ft left" },
    { "FT Right", "/ft right" },
    { "FT Redo", "/ft redo" },
    { "FT Forget", "/ft forget" },
    { "FT Clear", "/ft clear" },
}

local macroPending = true
local function TryMacros()
    if not macroPending then return end
    if InCombatLockdown and InCombatLockdown() then return end
    macroPending = false
    if not (CREATE_MACROS and GetMacroIndexByName and CreateMacro and GetNumMacros) then return end
    pcall(function()
        for _, m in ipairs(MACROS) do
            local idx = GetMacroIndexByName(m[1])
            if not (idx and idx > 0) then
                if GetNumMacros() >= (MAX_ACCOUNT_MACROS or 36) then return end
                if not pcall(CreateMacro, m[1], MACRO_ICON, m[2], nil) then
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
events:RegisterEvent("TAXIMAP_OPENED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_REGEN_ENABLED" then TryMacros() return end
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON then return end
        FlightTimerDB = FlightTimerDB or {}
        DB = FlightTimerDB
        DB.routes = DB.routes or {}
        ApplyPosition()
    elseif event == "TAXIMAP_OPENED" then
        lastOrigin = CurrentNodeName()
    elseif event == "PLAYER_ENTERING_WORLD" then
        TryMacros()
        if not DB then return end
        if UnitOnTaxi and UnitOnTaxi("player") then
            if not flight then
                -- /reload or relog mid-flight: pick the flight back up
                local inf = DB.inflight
                local age = inf and (ServerNow() - inf.t0)
                if inf and age >= 0 and age < 1800 then
                    local expected, estimated
                    if not inf.redo then expected, estimated = Expected(inf.from, inf.to) end
                    flight = { from = inf.from, to = inf.to, start = GetTime() - age,
                               expected = expected, estimated = estimated, redo = inf.redo }
                    lastKey = RouteKey(inf.from, inf.to)
                else
                    flight = { start = GetTime() } -- unknown route: show elapsed, learn nothing
                end
                Watch(true)
                Render()
            end
        else
            DB.inflight = nil
        end
    end
end)
