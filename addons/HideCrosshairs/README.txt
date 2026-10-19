HideCrosshairs 0.7
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
  It only fades the icon ARTWORK of the two crosshairs. It never changes
  Blizzard's buttons or frames and never hooks Blizzard's code, and once
  a second it puts the icons back to invisible if the game faded them in.
  (0.3 changed the buttons themselves, which on the Steam Deck could get
  the game's own bar code blocked with a "blocked from an action" warning.
  0.4 fixes that. 0.4 also faded the menus the bumpers open; 0.5 only
  fades the two icons themselves, never anything attached to them.)
  It only looks inside the gamepad ACTION BARS, so your target frame and
  the aiming crosshair in the middle of the screen are never touched.

MACRO (created for you)
  HC Debug   prints what was hidden and lists the artwork the gamepad UI
             uses. Only needed if a game patch brings the icons back.

NOTES
  - Tested on the Forever beta, client 1.60.1, in gamepad mode.
