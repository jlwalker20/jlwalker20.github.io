ShowTotemBar 1.0
================
Keeps the Shaman totem bar visible. In gamepad mode the default totem bar
can be hidden and its blue Edit Mode box does not appear, so you cannot
place it. This addon forces the bar to show, so it appears in Edit Mode and
on screen.

HOW TO INSTALL
  1. Download the .toc and .lua files from walkerwagoner.com/addons.
  2. Make a folder named exactly "ShowTotemBar" and put both files in it.
  3. Put that folder in your WoW Forever game folder under
     Interface/AddOns/ (so the .toc ends up at
     Interface/AddOns/ShowTotemBar/ShowTotemBar.toc).
  4. Start the game, or type /reload if it is already running (in gamepad
     mode use a macro that runs /reload, see below). Check the AddOns list
     on the character screen: it should be enabled and not red.

IF IT SHOWS RED / "OUT OF DATE" AFTER A GAME PATCH
  Tick "Load out of date AddOns" on the AddOns screen, or open
  ShowTotemBar.toc in a text editor and change the "## Interface:" number to
  match the new client build (it is 16001 for client 1.60.1, build 70170).

USING IT
  1. Enable the addon and enter the game (or /reload).
  2. Open Edit Mode. The totem bar and its blue box should now be there.
  3. Place it where you want and save the layout.

COMMANDS
  None. It never prints anything to chat and has no settings.

NOTES
  - It tries a short list of likely frame names for the totem bar
    (MultiCastActionBarFrame, TotemFrame, ShamanBarFrame,
    PlayerTotemFrame). If none exist it does nothing, quietly.
  - It re-checks on login, when combat ends, when Edit Mode layouts change
    and when a totem is dropped or expires. There is no constant polling.
  - Tested on the Forever beta, client 1.60.1 (70170), on a Shaman.
