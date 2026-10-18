-- DarkIronUI nameplates module: the frame art of the bars over units' heads
-- (health bar border, cast bar border). Bar colors (reaction, class, cast),
-- names, raid marks, threat/selection glows and elite/rare icons are untouched.
local _, NS = ...
NS.NewRecolor({
    key = "nameplates", label = "DarkIronUI_Nameplates", slash = "/dnp", macroPrefix = "DNP",
    icon = "Ability_Hunter_MarkedForDeath",
    roots = { function()
        if not (C_NamePlate and C_NamePlate.GetNamePlates) then return nil end
        local plates = C_NamePlate.GetNamePlates() or {}
        return plates[1] and plates or nil
    end },
    depth = 5,
    combatScan = true,       -- plates appear mid-fight; only their art colors change, which is safe
    darkness = 0.55, bgDarkness = 0.45,
    bgWords = { "background", "backdrop", "bg" },
    fileTextures = true,     -- classic-style plate borders are plain files
    respectTints = true,     -- art Blizzard colors on purpose stays as it is
    never = { "fill", "statusbar", "highlight", "glow", "threat", "aggro", "selection", "target", "raid", "icon",
              "spark", "flash", "elite", "rare", "boss", "skull", "shield", "absorb", "healprediction", "pip", "focus" },
    neverNames = { "Icon", "Highlight", "Glow", "Threat", "Aggro", "Selection", "Raid", "Spark", "Flash",
                   "Shield", "Absorb", "HealPrediction", "Elite" },
    events = { "NAME_PLATE_UNIT_ADDED" },
})
