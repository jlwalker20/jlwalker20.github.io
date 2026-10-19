HideChatLegend 0.2
==================
In gamepad mode, opening the chat input box shows a button legend under it:
"A Send  X Chat Channels  Y Tab Settings  B Back". This addon makes that
legend invisible while the chat box is open and puts it back when it closes.
The buttons still do the same things; only the legend isn't drawn.

HOW TO INSTALL
  1. Download the .toc and .lua files from walkerwagoner.com/addons
     (or use "Download all addons" there).
  2. Make a folder named exactly "HideChatLegend" and put both files in it.
  3. Put that folder in your WoW Forever game folder under
     Interface/AddOns/ (so the .toc ends up at
     Interface/AddOns/HideChatLegend/HideChatLegend.toc).
  4. Start the game, or /reload (in gamepad mode use a macro that runs /reload).

HOW IT WORKS
  The first time you open the chat box, it finds the legend by its labels
  ("Chat Channels", "Tab Settings") and remembers it. After that it only
  changes the legend's opacity. It never hooks the chat input box or the
  gamepad code (the path behind the gamepad chat hang).
  Labels are matched in English; other client languages need LABELS edited
  at the top of HideChatLegend.lua.

COMMANDS
  Macro "HCL Debug" (created for you): says whether the legend was found.

NOTES
  - Beta: built for the Forever beta, client 1.60.1.
