QuestMarks 0.6
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
  It checks, in order: the quest progress in the unit's tooltip, the kill
  objectives in your quest log (matched by the mob's name), and finally the
  game's own "belongs to one of your quests" check. Progress comes first, so
  once you've finished a mob's part of a quest (e.g. 4/4 slain) its mark goes
  away even while the quest itself is still open.
  Known limit: for mobs that only drop a quest item, the mark may stay until
  the quest is turned in if the game shows no progress in their tooltip. The "*" is its own label next to
  the name: Blizzard's name text is never changed and nothing is hooked.
  If the game hides a unit's data from addons (e.g. in combat), that plate
  simply gets no mark.

COMMANDS
  Macros (created for you): "QM Toggle" turns the marks on/off,
  "QM Debug" shows what the game reports for each plate on screen.

NOTES
  - Beta: built for the Forever beta, client 1.60.1.
