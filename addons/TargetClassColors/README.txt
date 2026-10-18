TargetClassColors 0.1
=====================
When your target (or focus) is another player, the health bar on the
target frame turns their class color: shaman blue, warrior tan, rogue
yellow and so on. NPCs keep Blizzard's normal green/yellow/red.

HOW TO INSTALL
  1. Download the .toc and .lua files from walkerwagoner.com/addons
     (or use "Download all addons" there).
  2. Make a folder named exactly "TargetClassColors" and put both files in it.
  3. Put that folder in your WoW Forever game folder under
     Interface/AddOns/ (so the .toc ends up at
     Interface/AddOns/TargetClassColors/TargetClassColors.toc).
  4. Start the game, or /reload if it is already running (in gamepad mode
     use a macro that runs /reload).

IF IT SHOWS RED / "OUT OF DATE" AFTER A GAME PATCH
  Tick "Load out of date AddOns" on the AddOns screen, or open
  TargetClassColors.toc in a text editor and change the "## Interface:"
  number to match the new client (16001 for client 1.60.x).

SETTINGS
  Top of TargetClassColors.lua:
    COLOR_HEALTH   true/false: class-color the health bar
    COLOR_NAME     true/false: also class-color the name text (off by default)

HOW IT WORKS
  It only changes the bar's color, and puts Blizzard's color back when you
  target an NPC. It hooks nothing, and doesn't touch the gamepad UI.
  Works alongside DarkIronUI.

COMMANDS
  None. No macros, nothing in chat.

NOTES
  - Beta: built for the Forever beta, client 1.60.1.
