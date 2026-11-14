-- Jaff's Better Forever UI: Core
-- The list of addons in the package, and the way addons hand their options to
-- the panel. An addon registers with:
--
--   JaffsUI:Register({ addon = "ChatFade", options = { ... } })
--
-- or, if it loads before this addon, by adding the same table to JaffsUI_Queue
-- (the panel picks those up when it loads). Each option is a table:
--   { type = "header", label = "..." }
--   { type = "note",   text = "..." }
--   { type = "toggle", label, desc, get = fn() -> bool, set = fn(bool), reload }
--   { type = "slider", label, desc, min, max, step, format, get, set, reload }
--   { type = "choice", label, desc, choices = { {value, label}, ... }, get, set, reload }
--   { type = "button", label, desc, func }
-- reload = true marks a setting that only takes effect after /reload.

local ADDON, ns = ...

JaffsUI = JaffsUI or {}
local J = JaffsUI
ns.J = J

-- the package, in the same order and sections as the download page
J.PACKAGE = {
    { section = "Look", addons = {
        { name = "DarkIronUI", match = { "DarkIronUI", "DarkIronUI_UnitFrames", "DarkIronUI_ActionBars", "DarkIronUI_Minimap",
                                         "DarkIronUI_Bags", "DarkIronUI_MenuBar", "DarkIronUI_Tooltip", "DarkIronUI_Tracker",
                                         "DarkIronUI_XPBar", "DarkIronUI_Castbar" } },
        { name = "CastBarPlus" }, { name = "TargetCastBarPlus" }, { name = "SquareMinimap" },
    } },
    { section = "Quality of life", addons = {
        { name = "ShortChannels" }, { name = "ChatFade" }, { name = "TargetClassColors" }, { name = "PartyFramesImproved" },
        { name = "QuestMarks" }, { name = "FlightTimer" }, { name = "GatheringLevels" }, { name = "HideChatButtons" },
        { name = "WeakenedSoulTracker" },
    } },
    { section = "Gamepad", addons = {
        { name = "ShowTotemBar" }, { name = "HideCrosshairs" }, { name = "HideChatLegend" },
    } },
}

J.registered = J.registered or {}

local function Loaded(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        local ok, v = pcall(C_AddOns.IsAddOnLoaded, name); return ok and v and true or false
    end
    if IsAddOnLoaded then local ok, v = pcall(IsAddOnLoaded, name); return ok and v and true or false end
    return false
end

-- installed (on disk), even if switched off in the AddOns list
local function Installed(name)
    if Loaded(name) then return true end
    local info = (C_AddOns and C_AddOns.GetAddOnInfo) or GetAddOnInfo
    if not info then return false end
    local ok, n, _, _, _, reason = pcall(info, name)
    if not ok or not n then return false end
    return reason ~= "MISSING"
end
J.Loaded = Loaded

local function Notes(name)
    local f = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    if not f then return nil end
    local ok, v = pcall(f, name, "Notes")
    return ok and type(v) == "string" and v or nil
end

local function Version(name)
    local f = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    if not f then return nil end
    local ok, v = pcall(f, name, "Version")
    return ok and type(v) == "string" and v or nil
end

-- the tabs to show: installed package addons, grouped by section
function J:Tabs()
    local out = {}
    for _, sec in ipairs(self.PACKAGE) do
        local list = {}
        for _, a in ipairs(sec.addons) do
            local found
            for _, n in ipairs(a.match or { a.name }) do if Loaded(n) then found = n; break end end
            if not found then
                for _, n in ipairs(a.match or { a.name }) do if Installed(n) then found = n; break end end
            end
            if found then
                list[#list + 1] = {
                    name = a.name, loadedAs = found,
                    notes = Notes(found), version = Version(found),
                    def = self.registered[a.name],
                    loaded = Loaded(found),
                }
            end
        end
        if #list > 0 then out[#out + 1] = { section = sec.section, tabs = list } end
    end
    return out
end

-- switch an addon on/off for this character (takes effect after a reload)
local function Me() local ok, n = pcall(UnitName, "player"); return ok and n or nil end
function J:IsEnabled(name)
    local f = (C_AddOns and C_AddOns.GetAddOnEnableState) or GetAddOnEnableState
    if not f then return self.Loaded and Loaded(name) end
    local ok, v
    if C_AddOns and C_AddOns.GetAddOnEnableState then ok, v = pcall(f, name, Me())
    else ok, v = pcall(f, Me(), name) end   -- the older function takes the character first
    return ok and type(v) == "number" and v > 0
end
function J:SetEnabled(name, on)
    local f = on and ((C_AddOns and C_AddOns.EnableAddOn) or EnableAddOn) or ((C_AddOns and C_AddOns.DisableAddOn) or DisableAddOn)
    if f then pcall(f, name, Me()) end
end

function J:Register(def)
    if type(def) ~= "table" or type(def.addon) ~= "string" then return end
    self.registered[def.addon] = def
    if self.OnRegister then pcall(self.OnRegister, def) end
end

-- addons that loaded before us
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(_, _, name)
    if name ~= ADDON then return end
    JaffsUIDB = JaffsUIDB or {}
    J.db = JaffsUIDB
    if type(JaffsUI_Queue) == "table" then
        for _, def in ipairs(JaffsUI_Queue) do J:Register(def) end
        JaffsUI_Queue = {}
    end
end)
