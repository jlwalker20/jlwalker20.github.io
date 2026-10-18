-- DarkIronUI XP bar module: the frame and background of the experience /
-- reputation bars. The XP, rested and reputation fills keep their colors.
local _, NS = ...
NS.NewRecolor({
    key = "xpbar", label = "DarkIronUI_XPBar", slash = "/dxp", macroPrefix = "DXP",
    icon = "INV_Misc_Book_09",
    roots = { "StatusTrackingBarManager", "MainStatusTrackingBarContainer", "SecondaryStatusTrackingBarContainer",
              "MainMenuExpBar", "ReputationWatchBar", "MainMenuBarMaxLevelBar", "MainMenuBarPerformanceBarFrame",
              "ExhaustionTick" },
    depth = 6,
    darkness = 0.55, bgDarkness = 0.45,
    bgWords = { "background", "backdrop", "bg" },
    fileTextures = true,     -- the classic-style XP bar art is plain files
    never = { "fill", "exhaustion", "tick", "rested", "glow", "flash", "spark", "highlight", "levelup", "gain", "pulse",
              "statusbar", "ui-statusbar", "barfill" },
    neverNames = { "Highlight", "Spark", "Tick", "Glow", "Flash" },
    respectTints = false,
    events = { "PLAYER_LEVEL_UP" },   -- the 1s re-check covers repaints; no rescans on every XP gain
})
