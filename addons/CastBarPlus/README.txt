CastBarPlus 0.8
===============
Reshapes your cast bar: it's taller, the spell name sits inside the bar
(centered, like a name over a health bar), and the cast timer sits inside the
bar on its right edge.
For your target's and focus's cast bars, see TargetCastBarPlus.

HOW TO INSTALL
  1. Download the .toc and .lua files from walkerwagoner.com/addons.
  2. Make a folder named exactly "CastBarPlus" and put both files in it.
  3. Put that folder in _forever_/Interface/AddOns/ (so the .toc ends up at
     _forever_/Interface/AddOns/CastBarPlus/CastBarPlus.toc).
  4. Start the game, or /reload (in gamepad mode use a macro).

SETTINGS (top of CastBarPlus.lua, then /reload)
  FONT_FILE / FONT_SIZE / FONT_OUTLINE   one fixed font for the spell name
                 and timer (default Friz Quadrata, size 13, plain).
                 TargetCastBarPlus uses the same face at size 10.
  TIMER_NUMBER_ONLY  true: the timer shows "1.5" instead of "1.5s"
  BAR_HEIGHT     your bar's height in pixels (default 22); nil leaves it alone
  TIMER_PAD      gap between the timer and the bar's right edge
  NAME_ROOM      space kept free each side of the name, so it never runs
                 into the timer
  BORDER_SLICE   keeps the border's corners and edges at their real size and
                 stretches only the middle (default 4; try 3-5; nil = Blizzard's stretch)
  HIDE_NAME_BOX  hide the dark box Blizzard draws under the bar for the name

HOW IT WORKS
  The bar is resized only out of combat; the text labels are moved inside it
  and put back in place whenever Blizzard re-lays the bar out. Nothing of
  Blizzard's is replaced. If your client has no cast timer, it shows its own.
  With CastBarFix installed, CastBarFix keeps control of the bar's size and
  position (set the height there) and this addon only moves the text.

COMMANDS
  Macro "CBP Debug" (created for you): lists what it found on the cast bar.

NOTES
  - Built for WoW: Forever, client 1.60.1 (live build 70790).
