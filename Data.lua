-- GatheringLevels zone data.
--
-- SOURCE: Forever guides say the herb and ore skill ladders are unchanged
-- from Classic (Peacebloom 1 ... Black Lotus 300; Copper 1 ... Rich Thorium
-- 275), but no Forever guide publishes per-zone node lists yet. So the
-- zone ranges below are CLASSIC values. Forever's new herbs and ores
-- (Marefoil, Demonsage, Death Lotus, Pitchblende...) and new zones
-- (Shen'dralas, Riverglade, Mount Hyjal, Zephras Isle) have no published
-- data, so they are not listed. Fix any line that's wrong in game: it's
-- just text.
--
-- Per zone:
--   h  = Herbalism skill range (lowest herb - highest herb in the zone)
--   m  = Mining skill range (lowest ore - highest ore)
--   lv = mob level range; Skinning skill is worked out from it
--        (mobs up to level 10 need 1, levels 11-20 need (level-10)x10,
--        above 20 need level x 5)
--   f  = Classic fishing zone level. Shown as "can fish" to "no lost
--        catches" (zone level + 95). nil = no fishable water.
-- A missing field means the profession has nothing in that zone.

local _, NS = ...

NS.ZONES = {
    -- Kalimdor
    ["Durotar"]              = { h = { 1, 15 },    m = { 1, 1 },     lv = { 1, 10 },  f = -70 },
    ["Mulgore"]              = { h = { 1, 15 },    m = { 1, 1 },     lv = { 1, 10 },  f = -70 },
    ["Teldrassil"]           = { h = { 1, 15 },                      lv = { 1, 11 },  f = -70 },
    ["Darkshore"]            = { h = { 1, 100 },   m = { 1, 75 },    lv = { 10, 20 }, f = -20 },
    ["The Barrens"]          = { h = { 1, 125 },   m = { 1, 75 },    lv = { 10, 25 }, f = -20 },
    ["Stonetalon Mountains"] = { h = { 1, 125 },   m = { 1, 75 },    lv = { 15, 27 }, f = 55 },
    ["Ashenvale"]            = { h = { 50, 150 },  m = { 65, 125 },  lv = { 18, 30 }, f = 55 },
    ["Thousand Needles"]     = { h = { 100, 170 }, m = { 65, 175 },  lv = { 25, 35 }, f = 130 },
    ["Desolace"]             = { h = { 85, 250 },  m = { 65, 175 },  lv = { 30, 40 }, f = 130 },
    ["Dustwallow Marsh"]     = { h = { 85, 185 },  m = { 65, 175 },  lv = { 35, 45 }, f = 130 },
    ["Feralas"]              = { h = { 85, 230 },  m = { 125, 230 }, lv = { 40, 50 }, f = 205 },
    ["Tanaris"]              = { h = { 205, 230 }, m = { 125, 230 }, lv = { 40, 50 }, f = 205 },
    ["Azshara"]              = { h = { 210, 280 }, m = { 155, 275 }, lv = { 45, 55 }, f = 205 },
    ["Felwood"]              = { h = { 220, 285 }, m = { 175, 275 }, lv = { 48, 55 }, f = 205 },
    ["Un'Goro Crater"]       = { h = { 210, 280 }, m = { 175, 275 }, lv = { 48, 55 }, f = 205 },
    ["Silithus"]             = { h = { 230, 300 }, m = { 230, 275 }, lv = { 55, 60 }, f = 330 },
    ["Winterspring"]         = { h = { 270, 300 }, m = { 175, 275 }, lv = { 55, 60 }, f = 330 },
    ["Moonglade"]            = {                                                      f = 205 },
    ["Orgrimmar"]            = {                                                      f = -20 },
    ["Thunder Bluff"]        = {                                                      f = -20 },
    ["Darnassus"]            = {                                                      f = -20 },

    -- Eastern Kingdoms
    ["Tirisfal Glades"]      = { h = { 1, 15 },    m = { 1, 1 },     lv = { 1, 10 },  f = -70 },
    ["Elwynn Forest"]        = { h = { 1, 15 },    m = { 1, 1 },     lv = { 1, 10 },  f = -70 },
    ["Dun Morogh"]           = { h = { 1, 15 },    m = { 1, 1 },     lv = { 1, 10 },  f = -70 },
    ["Silverpine Forest"]    = { h = { 1, 85 },    m = { 1, 75 },    lv = { 10, 20 }, f = -20 },
    ["Westfall"]             = { h = { 1, 85 },    m = { 1, 75 },    lv = { 10, 20 }, f = -20 },
    ["Loch Modan"]           = { h = { 1, 70 },    m = { 1, 75 },    lv = { 10, 20 }, f = -20 },
    ["Redridge Mountains"]   = { h = { 1, 100 },   m = { 1, 75 },    lv = { 15, 25 }, f = 55 },
    ["Duskwood"]             = { h = { 50, 125 },  m = { 65, 155 },  lv = { 18, 30 }, f = 55 },
    ["Wetlands"]             = { h = { 70, 150 },  m = { 65, 155 },  lv = { 20, 30 }, f = 55 },
    ["Hillsbrad Foothills"]  = { h = { 70, 150 },  m = { 65, 155 },  lv = { 20, 30 }, f = 55 },
    ["Alterac Mountains"]    = { h = { 115, 195 }, m = { 75, 175 },  lv = { 30, 40 }, f = 130 },
    ["Arathi Highlands"]     = { h = { 85, 185 },  m = { 65, 175 },  lv = { 30, 40 }, f = 130 },
    ["Stranglethorn Vale"]   = { h = { 85, 210 },  m = { 65, 175 },  lv = { 30, 45 }, f = 130 },
    ["Badlands"]             = { h = { 115, 210 }, m = { 125, 230 }, lv = { 35, 45 } },
    ["Swamp of Sorrows"]     = { h = { 85, 235 },  m = { 75, 175 },  lv = { 35, 45 }, f = 130 },
    ["The Hinterlands"]      = { h = { 160, 260 }, m = { 125, 230 }, lv = { 40, 50 }, f = 205 },
    ["Searing Gorge"]        = { h = { 205, 205 }, m = { 125, 245 }, lv = { 43, 50 } },
    ["Blasted Lands"]        = { h = { 205, 270 }, m = { 175, 245 }, lv = { 45, 55 } },
    ["Burning Steppes"]      = { h = { 205, 300 }, m = { 175, 275 }, lv = { 50, 58 } },
    ["Western Plaguelands"]  = { h = { 220, 285 }, m = { 155, 245 }, lv = { 51, 58 }, f = 205 },
    ["Eastern Plaguelands"]  = { h = { 220, 300 }, m = { 175, 275 }, lv = { 53, 60 }, f = 330 },
    ["Deadwind Pass"]        = {                   m = { 175, 245 }, lv = { 55, 60 }, f = 330 },
    ["Undercity"]            = {                                                      f = -20 },
    ["Stormwind City"]       = {                                                      f = -20 },
    ["Ironforge"]            = {                                                      f = -20 },
}

-- Other names the map might use for the same zone
NS.ALIASES = {
    ["Barrens"] = "The Barrens",
    ["Hinterlands"] = "The Hinterlands",
    ["Northern Stranglethorn"] = "Stranglethorn Vale",
    ["The Cape of Stranglethorn"] = "Stranglethorn Vale",
    ["Stormwind"] = "Stormwind City",
    ["Hillsbrad"] = "Hillsbrad Foothills",
}
