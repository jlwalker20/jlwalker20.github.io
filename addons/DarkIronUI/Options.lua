-- DarkIronUI: options for Jaff's Better Forever UI (/jaffs)
-- One tab, a section per part of the look. Each part has its on/off switch
-- (the same as its slash command); the recolored parts also get a darkness slider.

local ADDON, NS = ...

local function Slash(key, msg) local f = SlashCmdList[key]; if f then pcall(f, msg or "") end end

-- a part with its own saved table and slash toggle
local function PartToggle(label, svName, slashKey, desc)
    return { type = "toggle", label = label, desc = desc,
             get = function() local db = _G[svName]; return db and db.enabled ~= false end,
             set = function(v)
                 local db = _G[svName]
                 if db and (db.enabled ~= false) ~= v then Slash(slashKey) end
             end }
end

-- a recolor module (DarkCore): on/off + darkness
local function Recolor(key, title, desc)
    local rows = {
        { type = "header", label = title },
        { type = "toggle", label = "Dark look", desc = desc,
          get = function() local m = NS.mods and NS.mods[key]; return m and m.Enabled and m.Enabled() end,
          set = function(v)
              local m = NS.mods and NS.mods[key]
              if m and m.Enabled and (m.Enabled() and true or false) ~= v then Slash("DARKIRONUI_" .. key:upper()) end
          end },
        { type = "slider", label = "Darkness", desc = "Lower is darker. Shows straight away.", min = 0.2, max = 1, step = 0.05, format = "%.2f",
          get = function() local m = NS.mods and NS.mods[key]; return m and m.Darkness and m.Darkness() end,
          set = function(v) local m = NS.mods and NS.mods[key]; if m and m.SetDarkness then m.SetDarkness(v) end end },
    }
    return rows
end

local options = {}
local function Add(list) for _, o in ipairs(list) do options[#options + 1] = o end end

Add({
    { type = "header", label = "Player, target and focus frames" },
    PartToggle("Dark look", "DarkIronUI_UnitFramesDB", "FLATUNITFRAMES", "Same as /uff."),
    { type = "button", label = "Elite dragon: nudge up", button = "Up", func = function() Slash("FLATUNITFRAMES", "elite up") end },
    { type = "button", label = "Elite dragon: nudge down", button = "Down", func = function() Slash("FLATUNITFRAMES", "elite down") end },
    { type = "button", label = "Elite dragon: nudge left", button = "Left", func = function() Slash("FLATUNITFRAMES", "elite left") end },
    { type = "button", label = "Elite dragon: nudge right", button = "Right", func = function() Slash("FLATUNITFRAMES", "elite right") end },
    { type = "button", label = "Elite dragon position", button = "Reset", func = function() Slash("FLATUNITFRAMES", "elite reset") end },
    { type = "header", label = "Action bars" },
    PartToggle("Gamepad action bars", "DarkIronUI_ActionBarsDB", "GAMEPADDARKMODE", "Same as /gdm."),
    PartToggle("Keyboard action bars", "DarkIronUI_KeyboardBarsDB", "DARKIRONUI_KBARS", "Same as /dkb."),
})
Add(Recolor("minimap", "Minimap", "The border and the round buttons around it. Same as /dmm."))
Add(Recolor("tracker", "Quest tracker", "Same as /dot."))
Add(Recolor("tooltip", "Tooltips", "Same as /dtt."))
Add(Recolor("xpbar", "XP bar", "Same as /dxp."))
Add(Recolor("bags", "Bag bar", "Same as /dbb."))
Add(Recolor("menubar", "Menu bar", "Same as /dmn."))
Add(Recolor("castbar", "Cast bars", "Same as /dcb."))
options[#options + 1] = { type = "button", label = "Darkness", button = "Reset all", desc = "Every darkness slider back to how it shipped.",
    func = function()
        for _, m in pairs(NS.mods or {}) do
            if m.SetDarkness and m.baseDarkness then m.SetDarkness(m.baseDarkness) end
        end
        for _, db in pairs(DarkIronUIDB or {}) do if type(db) == "table" then db.darkness = nil end end
    end }

local def = { addon = "DarkIronUI", options = options }
if JaffsUI and JaffsUI.Register then JaffsUI:Register(def)
else JaffsUI_Queue = JaffsUI_Queue or {}; table.insert(JaffsUI_Queue, def) end
