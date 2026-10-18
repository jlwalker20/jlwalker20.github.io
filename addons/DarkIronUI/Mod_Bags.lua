-- DarkIronUI bag bar module: the borders of the backpack and bag slot buttons.
-- The bag pictures, counts and highlights keep their colors.
local _, NS = ...
NS.NewRecolor({
    key = "bags", label = "DarkIronUI_BagBar", slash = "/dbb", macroPrefix = "DBB",
    icon = "INV_Misc_Bag_08",
    roots = { "BagsBar", "MainMenuBarBackpackButton", "CharacterBag0Slot", "CharacterBag1Slot",
              "CharacterBag2Slot", "CharacterBag3Slot", "CharacterReagentBag0Slot", "KeyRingButton",
              "BagBarExpandToggle" },
    depth = 3,
    darkness = 0.55, bgDarkness = 0.45,
    bgWords = { "background", "backdrop", "bg", "slot" },
    fileTextures = true,     -- classic-style slot borders are plain files
    never = { "highlight", "glow", "flash", "checked", "new", "sparkle", "shine", "cooldown", "search", "pushed" },
    neverNames = { "Icon", "Highlight", "Count", "Flash", "Glow", "Search", "Cooldown", "Stock" },
    respectTints = false,
    events = { "BAG_UPDATE_DELAYED", "BAG_CONTAINER_UPDATE" },
})
