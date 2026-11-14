-- DarkTracker module: the quest objective tracker's headers and decorative art.
local _, NS = ...
NS.NewRecolor({
    key = "tracker", label = "DarkIronUI_QuestTracker", slash = "/dot", macroPrefix = "DOT",
    icon = "INV_Misc_Note_01",
    roots = { "ObjectiveTrackerFrame", "QuestWatchFrame", "WatchFrame", "QuestObjectiveTracker",
              "ScenarioObjectiveTracker", "CampaignQuestObjectiveTracker", "AchievementObjectiveTracker" },
    depth = 6,
    darkness = 0.55, bgDarkness = 0.45,
    bgWords = { "background", "backdrop", "bg" },
    fileTextures = false,    -- only named art: never quest icons or item buttons
    -- quest markers (the round "..." / "?" buttons): their backgrounds go grey,
    -- their yellow symbols stay (those are "icon" art or the button's Icon)
    never = { "icon", "check", "glow", "flash", "highlight", "progressbar", "bar-fill", "statusbar",
              "questitem", "item", "spark", "quest-campaign", "selected",
              "supertracked" },   -- the selected quest's marker keeps Blizzard's yellow
    neverNames = { "Icon", "Check", "Bar", "Highlight" },
    -- Blizzard draws brown "..." on its yellow marker; on our grey marker use its yellow "..."
    atlasSwap = { ["quest-in-progress-icon-brown"] = "Quest-In-Progress-Icon-yellow" },
    swapUnlessSibling = "supertracked",   -- on the selected (yellow) marker, keep the brown dots
    -- on the selected (yellow) marker, draw its "..." near-black
    tintOnSibling = { words = { "in-progress-icon" },   -- the "..." only; "?" stays yellow
                      sibling = "supertracked", value = 0.12 },
    respectTints = false,
    events = { "QUEST_WATCH_LIST_CHANGED", "QUEST_LOG_UPDATE", "SUPER_TRACKING_CHANGED" },
})
