WeakenedSoulTracker 0.6 (test)
==============================
A cooldown-style icon for each player you Power Word: Shield: their portrait,
a cooldown sweep and a countdown until Weakened Soul wears off and you can
shield them again. Icons line up in a bar, soonest-to-end first.

HOW IT KNOWS
  It watches your own Power Word: Shield casts and starts a timer for the
  player it landed on. It doesn't need to read auras (Forever hides those from
  addons in combat). Out of combat it reads the real Weakened Soul time and
  corrects the timer, and remembers that duration for next time.

INSTALL
  Copy the WeakenedSoulTracker folder into:
    World of Warcraft/_forever_/Interface/AddOns/

MOVING IT
  Opening Edit Mode unlocks it (a blue "Weakened Soul" box): drag it.
  Or /ws unlock, drag, /ws unlock again. On gamepad: /ws up, /ws down,
  /ws left, /ws right nudge it 5 pixels (make macros for these).
  /ws reset puts it back near the middle.

THREE SPOTS
  You get three saved spots (named Solo, Party and Raid to start). Each keeps
  its own position and grow direction. Moving, nudging or /ws grow changes the
  spot you're on.
  /ws spot        switch to the next spot (1 > 2 > 3 > 1)
  /ws spot 2      jump to spot 2
  /ws spots       list them (> marks the one in use)
  /ws name Raid Left   rename the spot you're on

COMMANDS (macros "WS Unlock" and "WS Test" are made if you have free slots)
  /ws           status: what it last saw
  /ws help      every command with what it does
  /ws unlock    unlock / lock for moving
  /ws test      three sample icons
  /ws grow      grow to the right / to the left (saved per spot)
  /ws clear     remove all icons

SETTINGS (top of WeakenedSoulTracker.lua)
  ICON_SIZE, SPACING, GROW ("RIGHT", "LEFT", "UP", "DOWN"),
  ICON_STYLE ("portrait" or "class"), SHAPE ("square" or "round"),
  PORTRAIT_CROP (raise it if any dark corners remain), BORDER, SHOW_NAME, CLASS_COLOR, NAME_LENGTH, DURATION, NUDGE

Built for WoW: Forever, client 1.60.1 (live build 70790).
