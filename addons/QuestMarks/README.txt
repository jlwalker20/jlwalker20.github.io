QuestMarks 0.5
==============
Puts a small yellow "*" just after a nameplate's name when that unit is part
of one of your active quests: a mob you have to kill, or a mob that drops an
item a quest still needs. The mark goes away once the quest no longer needs it.

HOW TO INSTALL
  1. Download the .toc and .lua files from walkerwagoner.com/addons.
  2. Make a folder named exactly "QuestMarks" and put both files in it.
  3. Put that folder in Interface/AddOns/ (so the .toc ends up at
     Interface/AddOns/QuestMarks/QuestMarks.toc).
  4. Start the game, or /reload (in gamepad mode use a macro).

HOW IT WORKS
  It tries several ways to tell, in order: the game's own quest check for the
  unit, the quest lines in the unit's tooltip, and the kill objectives in your
  quest log (matched by the mob's name). The "*" is its own label next to
  the name: Blizzard's name text is never changed and nothing is hooked.
  If the game hides a unit's data from addons (e.g. in combat), that plate
  simply gets no mark.

COMMANDS
  Macros (created for you): "QM Toggle" turns the marks on/off,
  "QM Debug" shows what the game reports for each plate on screen.

NOTES
  - Beta: built for the Forever beta, client 1.60.1.
