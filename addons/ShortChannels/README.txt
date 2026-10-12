ShortChannels 1.1
=================
Shortens chat channel names in your chat windows.

  [1. General - Durotar]            ->  [1. G]
  [2. Trade - Orgrimmar]            ->  [2. T]
  [4. Trade (Services) - English]   ->  [4. TS]
  [5. Trade (Local) - Thunder Bluff] -> [5. TL]

Built-in abbreviations
  General = G            Trade = T
  Trade (Local) = TL     Trade (Services) = TS
  LocalDefense = LD      WorldDefense = WD
  LookingForGroup = LFG  Services = S       Newcomers = N

Channels it does not know are left exactly as the game shows them.
The combat log tab is never touched.

HOW TO INSTALL
  1. Download the .toc and .lua files from walkerwagoner.com/addons.
  2. Make a folder named exactly "ShortChannels" and put both files in it.
  3. Put that folder in your WoW Forever game folder under
     Interface/AddOns/ (so the .toc ends up at
     Interface/AddOns/ShortChannels/ShortChannels.toc).
  4. Start the game, or type /reload if it is already running (in gamepad
     mode use a macro that runs /reload, see below). Check the AddOns list
     on the character screen: it should be enabled and not red.

IF IT SHOWS RED / "OUT OF DATE" AFTER A GAME PATCH
  Tick "Load out of date AddOns" on the AddOns screen, or open
  ShortChannels.toc in a text editor and change the "## Interface:" number to
  match the new client build (it is 16001 for client 1.60.1, build 70170).

CHANGING AN ABBREVIATION
  Open ShortChannels.lua in a text editor. The list at the top (the
  "SHORT" table) maps a channel name to its short form. Names are written
  in lowercase with spaces and punctuation removed, so "Trade (Services)"
  is "tradeservices". The part after " - " (city or language) is ignored.
  Save the file and /reload.

COMMANDS
  None. Nothing to configure in game.

NOTES
  - Load order: it hooks the chat windows at login. If you add another
    chat addon that rewrites channel names, the two may fight; disable one.
  - Tested on the Forever beta, client 1.60.1 (70170).
