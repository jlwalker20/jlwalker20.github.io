-- DarkIronUI cast bar module: the frame and background of your cast bar and
-- the target / focus cast bars. The bar's fill colors (casting, channeling,
-- interrupted), the spark, flash, spell icon, text and the "can't interrupt"
-- shield keep their looks.
local _, NS = ...
NS.NewRecolor({
    key = "castbar", label = "DarkIronUI_Castbar", slash = "/dcb", macroPrefix = "DCB",
    icon = "Spell_Holy_FlashHeal",
    roots = { "PlayerCastingBarFrame", "CastingBarFrame", "PetCastingBarFrame", "OverlayPlayerCastingBarFrame",
              "TargetFrameSpellBar", "FocusFrameSpellBar" },
    depth = 3,
    darkness = 0.55, bgDarkness = 0.45,
    bgWords = { "background", "backdrop", "bg" },
    fileTextures = true,     -- classic-style cast bar borders are plain files
    respectTints = false,
    skipAdditive = true,     -- the end-of-cast flash and spark are drawn additively
    never = { "fill", "spark", "flash", "glow", "shield", "icon", "statusbar", "interrupt", "channel", "pip",
              "standard", "crafting", "empower", "highlight" },
    neverNames = { "Icon", "Spark", "Flash", "Shield", "Glow", "Text", "Highlight" },
    events = { "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED" },
})
