-- DarkTooltip module: tooltip borders. Item-quality colored borders keep
-- their color (respectTints): only the default gold/white border goes grey.
local _, NS = ...
NS.NewRecolor({
    key = "tooltip", label = "DarkIronUI_Tooltip", slash = "/dtt", macroPrefix = "DTT",
    icon = "INV_Misc_Book_09",
    roots = { "GameTooltip.NineSlice", "ItemRefTooltip.NineSlice", "ShoppingTooltip1.NineSlice",
              "ShoppingTooltip2.NineSlice", "EmbeddedItemTooltip.NineSlice", "GameTooltip", "ItemRefTooltip" },
    depth = 1,
    darkness = 0.55, bgDarkness = 1,   -- leave the dark center alone
    bgWords = { "center", "background", "bg" },
    fileTextures = true,
    never = { "icon", "glow", "highlight", "statusbar", "bar" },
    neverNames = { "Icon", "StatusBar", "TextLeft", "TextRight", "Money", "Highlight" },
    respectTints = true,
})
