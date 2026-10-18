DarkIronUI 1.0 - for World of Warcraft: Forever (client 1.60.1)
=================================================================

One addon that recolors the default Blizzard UI from gold/brown to a
consistent dark grey. Spell icons, bar colors, debuff-type borders and
other "meaningful" colors are left alone.

WHAT IT COVERS
  Unit frames      Player, Target and Focus frames; grey elite dragon on
                   your player frame; your own level circle hidden
  Gamepad bars     Flat light-grey rings, darkened empty slots
  Keyboard bars    Main bar, extra bars, stance and pet bars
  XP bar           Frame and background (XP / rested fill keep color)
  Bag bar          Backpack and bag slot borders
  Menu bar         Character, spellbook, talents, etc. (grey frame,
                   color picture in the middle)
  Buffs/debuffs    Plain frame art (debuff type colors kept)
  Nameplates       Health and cast bar borders
  Minimap          Border and round buttons (pictures stay in color)
  Quest tracker    Header and quest-button backgrounds
  Tooltips         Borders (item-quality colors kept)

INSTALL
  1. Copy the DarkIronUI folder into your game's Interface/AddOns/
     (so the .toc ends up at Interface/AddOns/DarkIronUI/DarkIronUI.toc).
  2. Delete any older versions: FlatUnitFrames, GamepadDarkMode,
     DarkMinimap, DarkTracker, DarkTooltip, DarkUI, DarkIronUI_Tracker.
  3. Use EITHER the full DarkIronUI folder OR the single DarkIronUI_*
     parts, not both. (If both are installed, each part still runs once.)

TOGGLE / DEBUG (each part on its own; macros are created for you)
  /uff  Unit frames     UFF Toggle, UFF Debug, UFF Elite Left/Right/Up/Down
  /gdm  Gamepad bars    GDM Toggle, GDM Debug
  /dkb  Keyboard bars   DKB Toggle, DKB Debug
  /dxp  XP bar          DXP Toggle, DXP Debug
  /dbb  Bag bar         DBB Toggle, DBB Debug
  /dmn  Menu bar        DMN Toggle, DMN Debug
  /dau  Buffs/debuffs   DAU Toggle, DAU Debug
  /dnp  Nameplates      DNP Toggle, DNP Debug
  /dmm  Minimap         DMM Toggle, DMM Debug
  /dot  Quest tracker   DOT Toggle, DOT Debug
  /dtt  Tooltips        DTT Toggle, DTT Debug
  Add "debug" after any command (e.g. /dmm debug) to list the art it found.
  On a Steam Deck, use the macros: typing in chat can hang gamepad mode.

TUNING (edit the files, then /reload)
  KeyboardBars.lua   DARKNESS = 0.70       ring brightness
  ActionBars.lua     FILL_COLOR / BORDER_COLOR   gamepad ring colors
  Mod_MenuBar.lua    ringCenter = 0.66     how much of each button stays in color
  Mod_Minimap.lua    ringCenter = 0.72     same, for calendar / tracking buttons
  UnitFrames.lua     HIDE_REST_GLOW = false   true hides the resting flash

SAFETY
  Only the color of artwork is changed. No Blizzard functions are
  replaced, nothing secure is shown/hidden in combat, and searches run
  out of combat (nameplates excepted: color only). Locked frames
  (e.g. friendly nameplates in dungeons) keep Blizzard's look.

KNOWN LIMITS
  The gamepad LT / RT / LT+RT tags beside the button clusters keep
  Blizzard's look.
