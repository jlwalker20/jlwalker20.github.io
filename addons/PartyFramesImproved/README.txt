PartyFramesImproved 2.2 (test)
==============================
Party Frames Improved: one addon for Blizzard's raid-style party/raid frames.
Replaces PartyGrowUp, PartyLevels and DispelGlow: delete those three folders
first (and their PGU / DG macros, to free macro slots). For dispels, use
Blizzard's own indicators (they keep working in combat; addon ones can't).

WHAT IT DOES
  Layout   party frames stack from the bottom up; you stay on top; everyone
           else in class order: Warrior, Paladin, Druid, Rogue, Hunter,
           Shaman, Warlock, Mage, Priest. The "Party" label moves to the
           bottom (or can be hidden). Moved only out of combat.
  Levels   each member's level in front of their name, colored by difficulty.
  Icons    leader crown (top-right of the health bar), raid target marker (bottom-right
           of the health bar), faction icon where the role icon was (top-left): gray when not
           flagged, full color when PvP-flagged; role icon hidden.
  Heals    a green bar for incoming heals that starts where health ends and
           can run past the frame's edge; shields after it (white) if the game
           gives shield amounts, otherwise a small PW:Shield icon.
           Needs the game's incoming-heal API; /pfi debug says if it exists.

INSTALL
  Copy the PartyFramesImproved folder into:
    World of Warcraft/_forever_/Interface/AddOns/

COMMANDS (macro "PFI Debug" is made if you have a free slot)
  /pfi          layout on / off
  /pfi top      you on top / bottom
  /pfi sort     class order on / off     /pfi icons   crown/marker/flag on / off
  /pfi label    hide / show "Party"      /pfi role    role icon hidden / shown
  /pfi heals    heal / shield bars on / off
  /pfi debug    what every part sees     /pfi help    this list

SETTINGS
  Layout.lua      CLASS_ORDER, SLOTS, GAP
  Levels.lua      POSITION ("before"/"after"), COLOR_BY_DIFFICULTY, SHOW_SELF
  Icons.lua       sizes and spots for crown, marker, flag (on the health bar); PVP_ALWAYS,
                  PVP_GRAY_ALPHA; HIDE_ROLE;
  HealPrediction.lua  HEAL_COLOR, SHIELD_COLOR, SHIELD_ICON, TEXTURE (nil = match health bar)

Built for WoW: Forever, client 1.60.1 (live build 70790).
