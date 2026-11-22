-- PartyFramesImproved: options for Jaff's Better Forever UI (/jaffs)
-- Every part's settings in one tab. Saved per part (PartyFramesImprovedDB.<part>.cfg).

local ADDON, ns = ...

-- saved settings: applied over each part's defaults when the addon loads
local DEFAULTS = {}
local function Saved(part) local s = ns.Section(part); s.cfg = s.cfg or {}; return s.cfg end

local lf = CreateFrame("Frame")
lf:RegisterEvent("ADDON_LOADED")
lf:SetScript("OnEvent", function(_, _, n)
    if n ~= ADDON then return end
    for part, cfg in pairs(ns.cfg or {}) do
        DEFAULTS[part] = {}
        for k, v in pairs(cfg) do if type(v) ~= "table" then DEFAULTS[part][k] = v end end
        for k, v in pairs(Saved(part)) do if DEFAULTS[part][k] ~= nil then cfg[k] = v end end
    end
    if ns.LevelsRefresh then ns.LevelsRefresh() end
    if ns.IconsRefresh then ns.IconsRefresh() end
end)

local REFRESH = {
    levels = function() if ns.LevelsRefresh then ns.LevelsRefresh() end end,
    icons  = function() if ns.IconsRefresh then ns.IconsRefresh() end end,
    heals  = function() if ns.HealsRefresh then ns.HealsRefresh() end end,
    raid   = function() if ns.RaidRefresh then ns.RaidRefresh() end end,
}

local function Opt(part, key, t)
    t.get = function() return ns.cfg[part] and ns.cfg[part][key] end
    t.set = function(v)
        if not ns.cfg[part] then return end
        ns.cfg[part][key] = v
        Saved(part)[key] = v
        if REFRESH[part] then pcall(REFRESH[part]) end
    end
    return t
end

local function LayoutToggle(label, field, cmd, desc)
    return { type = "toggle", label = label, desc = desc,
             get = function() local st = ns.LayoutState and ns.LayoutState(); return st and (field == "off" and not st.off or (field ~= "off" and st[field])) end,
             set = function(v)
                 local st = ns.LayoutState and ns.LayoutState(); if not st then return end
                 local cur = (field == "off") and not st.off or st[field]
                 if (cur and true or false) ~= v and ns.LayoutCmd then ns.LayoutCmd(cmd) end
             end }
end

local SLOT_CHOICES = { { "pvp", "Faction / PvP icon" }, { "role", "Blizzard's role icon" }, { "none", "Nothing (name flush left)" } }

local def = { addon = "PartyFramesImproved", options = {
    { type = "header", label = "Party layout" },
    LayoutToggle("Grow from the bottom", "off", "", "Party frames stack upward from a fixed bottom."),
    LayoutToggle("You on top", "top", "top"),
    LayoutToggle("Sort by class", "sort", "sort", "Warrior, Paladin, Druid, Rogue, Hunter, Shaman, Warlock, Mage, Priest (edit CLASS_ORDER in Layout.lua to change)."),
    LayoutToggle("Hide the \"Party\" label", "label", "label"),

    { type = "header", label = "Raid layout" },
    { type = "toggle", label = "Grow from the bottom-right", desc = "Raid frames in the same order, from a fixed bottom-right corner.",
      get = function() return ns.RaidOn and ns.RaidOn() end,
      set = function(v) if ns.RaidOn and ns.RaidOn() ~= v and ns.RaidCmd then ns.RaidCmd("") end end },
    Opt("raid", "GROW", { type = "choice", label = "Fill", choices = { { "UP", "Columns, upward" }, { "LEFT", "Rows, leftward" } } }),
    Opt("raid", "PER_LINE", { type = "slider", label = "Frames per column / row", min = 1, max = 10, step = 1 }),
    Opt("raid", "FULL_COLUMNS", { type = "slider", label = "Room for columns", desc = "How wide a full raid is; sets where the bottom-right corner sits.", min = 1, max = 10, step = 1 }),
    Opt("raid", "GAP_X", { type = "slider", label = "Gap between columns", min = 0, max = 20, step = 1 }),
    Opt("raid", "GAP_Y", { type = "slider", label = "Gap between rows", min = 0, max = 20, step = 1 }),
    Opt("raid", "ANCHOR_X", { type = "slider", label = "Corner sideways", min = -200, max = 200, step = 2 }),
    Opt("raid", "ANCHOR_Y", { type = "slider", label = "Corner up / down", min = -200, max = 200, step = 2 }),

    { type = "header", label = "Icons" },
    { type = "toggle", label = "Show icons", desc = "Leader crown, target marker and the top-left icon.",
      get = function() return ns.IconsOn and ns.IconsOn() end,
      set = function(v) if ns.IconsOn and ns.IconsOn() ~= v and ns.IconsCmd then ns.IconsCmd("icons") end end },
    { type = "choice", label = "Top-left of the bar", choices = SLOT_CHOICES,
      get = function() return ns.IconsSlot and ns.IconsSlot() end,
      set = function(v) if ns.IconsCmd then ns.IconsCmd(v) end end },
    Opt("icons", "PVP_ALWAYS", { type = "toggle", label = "Faction icon always (gray when not flagged)" }),
    Opt("icons", "PVP_GRAY_ALPHA", { type = "slider", label = "Gray icon opacity", min = 0.1, max = 1, step = 0.05, format = "%.2f" }),
    Opt("icons", "NAME_PAD", { type = "slider", label = "Name padding (with nothing)", min = 0, max = 12, step = 1 }),
    Opt("icons", "NAME_RIGHT_PAD", { type = "slider", label = "Room right of the name", desc = "Long names stop this many pixels from the right edge, so debuff icons there aren't covered. 0 = Blizzard's spot.", min = 0, max = 50, step = 2 }),
    Opt("icons", "LEADER", { type = "toggle", label = "Leader crown" }),
    Opt("icons", "MARKER", { type = "toggle", label = "Target marker" }),
    Opt("icons", "LEADER_SIZE", { type = "slider", label = "Crown size", min = 8, max = 24, step = 1, reload = true }),
    Opt("icons", "MARKER_SIZE", { type = "slider", label = "Marker size", min = 8, max = 28, step = 1, reload = true }),
    Opt("icons", "PVP_SIZE", { type = "slider", label = "Faction icon size", min = 8, max = 28, step = 1, reload = true }),

    { type = "header", label = "Levels" },
    Opt("levels", "POSITION", { type = "choice", label = "Level", choices = { { "before", "Before the name" }, { "after", "After the name" } } }),
    Opt("levels", "COLOR_BY_DIFFICULTY", { type = "toggle", label = "Color by difficulty" }),
    Opt("levels", "SHOW_SELF", { type = "toggle", label = "On your own frame too" }),

    { type = "header", label = "Incoming heals and shields" },
    { type = "toggle", label = "Show heal / shield bars",
      get = function() return ns.HealsOn and ns.HealsOn() end,
      set = function(v) if ns.HealsOn and ns.HealsOn() ~= v and ns.HealsCmd then ns.HealsCmd("") end end },
    Opt("heals", "SHIELD_ICON", { type = "toggle", label = "Shield icon when amounts aren't available" }),

    { type = "button", label = "Defaults", button = "Reset to defaults", desc = "Every setting above back to how it shipped (on/off switches stay as they are).",
      func = function()
          for part, d in pairs(DEFAULTS) do
              for k, v in pairs(d) do if ns.cfg[part] then ns.cfg[part][k] = v end end
              ns.Section(part).cfg = {}
              if REFRESH[part] then pcall(REFRESH[part]) end
          end
      end },
} }

if JaffsUI and JaffsUI.Register then JaffsUI:Register(def)
else JaffsUI_Queue = JaffsUI_Queue or {}; table.insert(JaffsUI_Queue, def) end
