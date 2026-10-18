-- DarkIronUI menu bar module: the row of option buttons (character, spellbook,
-- talents, professions, quest log, social, main menu...). Each button's frame
-- goes grey while its picture in the middle keeps full color.
local _, NS = ...
NS.NewRecolor({
    key = "menubar", label = "DarkIronUI_MenuBar", slash = "/dmn", macroPrefix = "DMN",
    icon = "INV_Misc_Gear_01",
    roots = { "MicroMenuContainer", "MicroMenu", "MicroButtonAndBagsBar",
              "CharacterMicroButton", "SpellbookMicroButton", "ProfessionMicroButton", "PlayerSpellsMicroButton",
              "TalentMicroButton", "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton",
              "SocialsMicroButton", "LFDMicroButton", "LFGMicroButton", "CollectionsMicroButton", "EJMicroButton",
              "PVPMicroButton", "WorldMapMicroButton", "StoreMicroButton", "MainMenuMicroButton", "HelpMicroButton",
              "HousingMicroButton" },
    depth = 3,
    skipFrames = { "Bag", "Backpack", "KeyRing" },     -- the bag buttons belong to the bag bar module
    darkness = 0.55, bgDarkness = 0.45,
    bgWords = { "background", "backdrop", "bg" },
    fileTextures = true,
    ringParents = { "MicroButton" },     -- each button's face: grey frame, color middle
    ringOnly = { "MicroMenu-", "MicroButton-" },
    ringShape = "square",
    ringCenter = 0.66,                   -- raise to color more of each button, lower for a wider grey frame
    never = { "highlight", "glow", "flash", "alert", "notification", "new", "shine", "pulse", "badge",
              "performance", "portrait" },
    neverNames = { "Highlight", "Flash", "Portrait", "Alert", "Glow", "Performance", "Shine" },
    respectTints = false,
    events = { "PLAYER_LEVEL_UP" },
})
