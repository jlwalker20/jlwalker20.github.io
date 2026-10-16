HideCrosshairs 0.2
==================
Hides the red (enemy) and green (friendly) crosshair icons that the
gamepad UI shows above the action bars on the bumpers (LB / RB). The
game's options call these the "Target Modifier". Your bumper bindings
keep working exactly as before; only the two icons become invisible.

HOW TO INSTALL
  1. Download the .toc and .lua files from walkerwagoner.com/addons
     (or use "Download all addons" there).
  2. Make a folder named exactly "HideCrosshairs" and put both files in it.
  3. Put that folder in your WoW Forever game folder under
     Interface/AddOns/ (so the .toc ends up at
     Interface/AddOns/HideCrosshairs/HideCrosshairs.toc).
  4. Start the game, or /reload if it is already running (in gamepad mode
     use a macro that runs /reload). Check the AddOns list on the
     character screen: it should be enabled and not red.

IF IT SHOWS RED / "OUT OF DATE" AFTER A GAME PATCH
  Tick "Load out of date AddOns" on the AddOns screen, or open
  HideCrosshairs.toc in a text editor and change the "## Interface:"
  number to match the new client (16001 for client 1.60.x).

HOW IT WORKS
  It makes the two icons fully transparent instead of hiding them.
  Hiding parts of the action bars during combat is blocked by the game
  ("Interface action failed because of an AddOn"); transparency is not,
  so it is safe mid-fight. If the game fades them back in, the addon
  sets them invisible again.
  It finds them by looking inside the gamepad UI for frames and artwork
  whose names mention "target" or "crosshair". Nothing outside the
  gamepad UI (like your normal target frame) is touched.

MACRO (created for you)
  HC Debug   prints what was hidden and lists the artwork the gamepad UI
             uses. Only needed if a game patch brings the icons back.

NOTES
  - Tested on the Forever beta, client 1.60.1, in gamepad mode.
