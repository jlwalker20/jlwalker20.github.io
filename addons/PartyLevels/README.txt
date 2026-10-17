PartyLevels 1.0
===============
Adds each group member's level to their name on the raid-style party and
raid frames:

  18 Thrall
  25 Cairne

The number is colored by difficulty compared with your level, like the
target frame: red = well above you, yellow = close, green/gray = below.
Your own frame shows your level too. An unknown level shows as "??".
Numbers update as soon as someone levels.

HOW TO INSTALL
  1. Download the .toc and .lua files from walkerwagoner.com/addons
     (or use "Download all addons" there).
  2. Make a folder named exactly "PartyLevels" and put both files in it.
  3. Put that folder in your WoW Forever game folder under
     Interface/AddOns/ (so the .toc ends up at
     Interface/AddOns/PartyLevels/PartyLevels.toc).
  4. Start the game, or /reload if it is already running (in gamepad mode
     use a macro that runs /reload). Check the AddOns list on the
     character screen: it should be enabled and not red.
  You need raid-style party frames turned on for it to show.

IF IT SHOWS RED / "OUT OF DATE" AFTER A GAME PATCH
  Tick "Load out of date AddOns" on the AddOns screen, or open
  PartyLevels.toc in a text editor and change the "## Interface:"
  number to match the new client (16001 for client 1.60.x).

SETTINGS
  Top of PartyLevels.lua:
    POSITION             "before" -> "52 Thrall", "after" -> "Thrall 52"
    COLOR_BY_DIFFICULTY  true/false
    SHOW_SELF            true/false: your own level on your frame

HOW IT WORKS
  It only rewrites the name text right after Blizzard draws it. It never
  calls Blizzard's frame code, and never touches nameplates, the chat box
  or the gamepad UI.

COMMANDS
  None. No macros, nothing in chat.

NOTES
  - Tested on the Forever beta, client 1.60.1.
