GatheringLevels 0.3
===================
Shows each zone's gathering skill ranges on the world map, for the
gathering professions your character actually has (Herbalism, Mining,
Skinning, Fishing). Text only, in the top-left of the map.

  Gathering
  Herbalism  1-125  (you 42)
  Fishing  1-75  (you 75)

Continent and world maps show nothing. Only single-zone maps do.

WHAT THE COLORS MEAN
  red     your skill is below the low end: nothing there you can gather
  yellow  inside the range: some of it is gatherable and gives skill-ups
  green   at or past the high end: you can gather everything there

WHAT THE RANGES MEAN
  Herbalism / Mining   lowest to highest node skill in the zone
  Skinning             worked out from the zone's mob levels
  Fishing              from "can fish here" to "no more lost catches";
                       endgame zones show 300+

HOW TO INSTALL
  1. Download all three files from walkerwagoner.com/addons:
     GatheringLevels.toc, Data.lua, GatheringLevels.lua
  2. Make a folder named exactly "GatheringLevels" and put all three in it.
  3. Put that folder in your WoW Forever game folder under
     Interface/AddOns/ (so the .toc ends up at
     Interface/AddOns/GatheringLevels/GatheringLevels.toc).
  4. Start the game, or /reload if it is already running (in gamepad mode
     use a macro that runs /reload). Check the AddOns list on the
     character screen: it should be enabled and not red.

IF IT SHOWS RED / "OUT OF DATE" AFTER A GAME PATCH
  Tick "Load out of date AddOns" on the AddOns screen, or open
  GatheringLevels.toc in a text editor and change the "## Interface:"
  number to match the new client (16001 for client 1.60.x).

SETTINGS
  Top of GatheringLevels.lua:
    X, Y          where the text sits (pixels from the top-left corner)
    FONT_SIZE     size of the profession lines (default 15)
    HEADER_SIZE   size of "Gathering" (default 16)
    SHOW_YOUR_SKILL   true/false: the "(you 42)" part

ABOUT THE DATA (please read)
  Forever guides say the herb and ore skill ladders are unchanged from
  Classic (Peacebloom 1 ... Black Lotus 300, Copper 1 ... Rich Thorium
  275), but no Forever guide lists which nodes spawn in which zone yet.
  So the zone ranges are Classic values and may be off at the edges.
  New Forever herbs and ores (Marefoil, Demonsage, Death Lotus,
  Pitchblende...) and new zones (Shen'dralas, Riverglade, Mount Hyjal,
  Zephras Isle) have no published data and show nothing for now.
  Every zone is one line in Data.lua: fix it there if you see something
  different in game.

COMMANDS
  None. No macros, nothing in chat, and it never takes the mouse.

NOTES
  - English zone names only.
  - Tested on the Forever beta, client 1.60.1, in gamepad mode.
