ChatFade 1.0
============
Fades the chat window out after 30 seconds with no new message, and
brings it back to full opacity the moment a new line arrives. That
includes system lines like "Changed Channel: [1. G]" when you travel, plus
loading screens and zone changes.

It stays visible while you are typing in chat or have the mouse over it.
The combat log tab is ignored, so fight spam does not keep chat awake.

HOW TO INSTALL
  1. Download the .toc and .lua files from walkerwagoner.com/addons.
  2. Make a folder named exactly "ChatFade" and put both files in it.
  3. Put that folder in your WoW Forever game folder under
     Interface/AddOns/ (so the .toc ends up at
     Interface/AddOns/ChatFade/ChatFade.toc).
  4. Start the game, or type /reload if it is already running (in gamepad
     mode use a macro that runs /reload, see below). Check the AddOns list
     on the character screen: it should be enabled and not red.

IF IT SHOWS RED / "OUT OF DATE" AFTER A GAME PATCH
  Tick "Load out of date AddOns" on the AddOns screen, or open
  ChatFade.toc in a text editor and change the "## Interface:" number to
  match the new client build (it is 16001 for client 1.60.1, build 70170).

SETTINGS
  Open ChatFade.lua in a text editor. The CONFIG block at the top has:
    IDLE_SECONDS   seconds of quiet before fading (default 30)
    FADED_ALPHA    how faded it gets: 0 = invisible, 0.25 = faint ghost
    FADE_OUT_TIME  seconds the fade-out takes (default 1.5)
    FADE_IN_TIME   seconds the fade-in takes (default 0.25)
  Save the file and /reload.

COMMANDS
  None.

NOTES
  - It never touches the chat input box. That is on purpose: opening the
    chat box in gamepad mode can freeze the Forever beta client (a
    Blizzard bug), so the addon stays away from it.
  - Works alongside ShortChannels.
  - Tested on the Forever beta, client 1.60.1 (70170).
