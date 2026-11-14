PartyFramesImproved 2.9 (test)
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
  Raid     raid frames grow from the bottom-right toward the top-left in the
           same order (you, then class order): columns fill upward, new
           columns to the left. With Blizzard's "Keep Groups Together" ON,
           each group becomes a column (group 1 at the right), members sorted
           inside it with the group label at the bottom. Out of combat only.
  Levels   each member's level in front of their name, colored by difficulty.
  Icons    leader crown (left edge, middle, under the faction icon), raid
           target marker (right edge, middle), top-left of the bar shows ONE of: the faction icon (gray when not
           flagged, full color when PvP-flagged), Blizzard's role icon, or
           nothing with the name moved flush left.
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
  /pfi label    hide / show "Party"
  /pfi heals    heal / shield bars on / off
  /pfi raid     raid layout on / off
  /pfi slot     top-left of the bar: PvP icon > role icon > nothing
  /pfi pvp | /pfi role | /pfi none   pick one directly
  /pfi debug    what every part sees     /pfi help    this list

SETTINGS
  Layout.lua      CLASS_ORDER, SLOTS, GAP
  RaidLayout.lua  GROW ("UP" or "LEFT"), PER_LINE, GAP_X / GAP_Y, FULL_COLUMNS,
                  ANCHOR_X / ANCHOR_Y (nudge the bottom-right corner)
  Levels.lua      POSITION ("before"/"after"), COLOR_BY_DIFFICULTY, SHOW_SELF
  Icons.lua       sizes and spots for crown, marker, flag (on the health bar); PVP_ALWAYS,
                  PVP_GRAY_ALPHA; LEFT_SLOT ("pvp"/"role"/"none"), NAME_PAD;
  HealPrediction.lua  HEAL_COLOR, SHIELD_COLOR, SHIELD_ICON, TEXTURE (nil = match health bar)

Built for WoW: Forever, client 1.60.1 (live build 70790).
