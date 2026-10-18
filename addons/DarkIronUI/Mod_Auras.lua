-- DarkIronUI auras module: frame art around your buffs and debuffs (top right).
-- Spell icons, timers and stack counts are untouched, and debuff borders keep
-- their type colors (magic blue, curse purple, poison green...), as do weapon
-- enchant borders: only plain (uncolored) frame art goes grey.
local _, NS = ...
NS.NewRecolor({
    key = "auras", label = "DarkIronUI_Auras", slash = "/dau", macroPrefix = "DAU",
    icon = "Spell_Holy_WordFortitude",
    roots = { "BuffFrame", "DebuffFrame", "TemporaryEnchantFrame", "ConsolidatedBuffs" },
    depth = 5,
    darkness = 0.55, bgDarkness = 0.45,
    bgWords = { "background", "backdrop", "bg" },
    fileTextures = true,
    respectTints = true,     -- colored borders (debuff type, enchants) stay as Blizzard colors them
    never = { "cooldown", "swipe", "count", "duration", "glow", "flash", "highlight", "pandemic", "spark", "shine" },
    neverNames = { "Icon", "Count", "Duration", "Cooldown", "Highlight", "Glow", "Flash" },
    events = { "UNIT_AURA" },   -- new aura buttons get styled shortly after they appear
    eventUnit = "player",
})
