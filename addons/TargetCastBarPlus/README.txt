TargetCastBarPlus 0.7
=====================
Reshapes your target's and focus's cast bars the way CastBarPlus does yours:
taller, the spell name inside the bar (centered), and a cast
timer inside the bar on its right edge. The spell icon keeps Blizzard's
size and is centered on the bar.

HOW TO INSTALL
  1. Download the .toc and .lua files from walkerwagoner.com/addons.
  2. Make a folder named exactly "TargetCastBarPlus" and put both files in it.
  3. Put that folder in _forever_/Interface/AddOns/ (so the .toc ends up at
     _forever_/Interface/AddOns/TargetCastBarPlus/TargetCastBarPlus.toc).
  4. Start the game, or /reload (in gamepad mode use a macro).

SETTINGS (top of TargetCastBarPlus.lua, then /reload)
  FONT_FILE / FONT_SIZE / FONT_OUTLINE   one fixed font for the spell name
                 and timer (default Friz Quadrata, size 10, plain; the same
                 face as CastBarPlus, a little smaller for the shorter bar).
  TARGET_HEIGHT    bar height in pixels (default 18); nil leaves it alone
  ICON_GAP         gap between the icon and the bar, if Blizzard's can't be read
  TIMER_PAD        gap between the timer and the bar's right edge
  NAME_ROOM        space kept free each side of the name, so it never runs
                   into the timer
  BORDER_SLICE   keeps the border's corners and edges at their real size and
                 stretches only the middle (default 4; try 3-5; nil = Blizzard's stretch)
  HIDE_NAME_BOX    hide the dark box Blizzard draws under the bar for the name

HOW IT WORKS
  Bars are resized only out of combat; the text labels are moved inside them
  and put back whenever Blizzard re-lays the bar out. Nothing of Blizzard's is
  replaced. Blizzard gives these bars no timer, so this addon adds one. The
  game may hide other units' cast timing from addons in combat; then the
  timer simply stays blank.

COMMANDS
  Macro "TCB Debug" (created for you): lists what it found on the cast bars.

NOTES
  - Works on its own or together with CastBarPlus.
  - Built for WoW: Forever, client 1.60.1 (live build 70790).
