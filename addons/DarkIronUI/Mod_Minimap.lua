-- DarkMinimap module: minimap border and the round buttons around it.
local _, NS = ...
NS.NewRecolor({
    key = "minimap", label = "DarkIronUI_Minimap", slash = "/dmm", macroPrefix = "DMM",
    icon = "INV_Misc_Map_01",
    roots = { "MinimapCluster", "Minimap", "MinimapBackdrop", "MinimapZoomIn", "MinimapZoomOut",
              "MiniMapTracking", "MiniMapTrackingButton", "MiniMapMailFrame", "GameTimeFrame",
              "TimeManagerClockButton", "MiniMapWorldMapButton", "QueueStatusButton",
              "MiniMapBattlefieldFrame", "ExpansionLandingPageMinimapButton" },
    depth = 4,
    darkness = 0.55, bgDarkness = 0.45,
    bgWords = { "background", "backdrop", "bg" },
    fileTextures = true,     -- many minimap borders are plain files, not named art
    never = { "icon", "blip", "arrow", "ping", "glow", "flash", "highlight", "pushed",
              "zoom-icon", "plus", "minus", "poi", "objecticon", "partymember", "raidmember" },
    neverNames = { "Icon", "Blip", "Arrow", "Ping", "Highlight" },
    keep = { "DayCycle" },                         -- sun/moon picture stays in color
    ringOnly = { "calendar-button", "tracking-button" },  -- one-piece buttons: grey ring, color middle
    ringCenter = 0.72,                             -- raise to color more of the button, lower for a thicker grey ring
    keepButtonFaces = true,            -- button pictures (sun/moon, calendar, tracking) stay in color
    keepFacesExcept = { "Zoom" },      -- the zoom +/- buttons may go grey whole
    keepSheetPictures = true,
    respectTints = false,
    events = { "ZONE_CHANGED_NEW_AREA", "UPDATE_PENDING_MAIL", "MINIMAP_UPDATE_TRACKING" },
})
