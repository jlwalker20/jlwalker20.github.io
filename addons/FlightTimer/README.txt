FlightTimer 1.4
===============
A plain text countdown for your current flight path, shown lower-middle
of the screen in the default UI font.

  Flight: 1:23

HOW IT KNOWS THE TIME
  The game does not tell addons how long a flight takes, so FlightTimer
  learns it:
    - First time you fly a route it counts UP:  Flying: 0:42 (learning)
    - When you land, it saves that time for that route.
    - Every flight after that counts DOWN:      Flight: 1:23
    - A route you have only flown the other way uses that time as an
      estimate until you fly it yourself.
  Routes are remembered between sessions. If you /reload mid-flight, it
  picks the flight back up with the right time left.
  For multi-stop routes, fly them all the way through once so the full
  time is learned (a short flight is treated as a partial hop and ignored
  unless you use "redo").

HOW TO INSTALL
  1. Download the .toc and .lua files from walkerwagoner.com/addons.
  2. Make a folder named exactly "FlightTimer" and put both files in it.
  3. Put that folder in your WoW Forever game folder under
     Interface/AddOns/ (so the .toc ends up at
     Interface/AddOns/FlightTimer/FlightTimer.toc).
  4. Start the game, or type /reload if it is already running (in gamepad
     mode use a macro that runs /reload, see below). Check the AddOns list
     on the character screen: it should be enabled and not red.

IF IT SHOWS RED / "OUT OF DATE" AFTER A GAME PATCH
  Tick "Load out of date AddOns" on the AddOns screen, or open
  FlightTimer.toc in a text editor and change the "## Interface:" number to
  match the new client build (it is 16001 for client 1.60.1, build 70170).

MACROS (created for you)
  Typing in chat can freeze the game in gamepad mode (a Blizzard bug), so
  FlightTimer makes these account-wide macros the first time it loads
  outside combat. Find them in the macro window (/macro, General tab) and
  drag them to a bar:

    FT Move     show / hide the placeholder for moving the timer
    FT Up       nudge the timer up 10 pixels
    FT Down     nudge down
    FT Left     nudge left
    FT Right    nudge right
    FT Redo     re-record: your next flight (or the one you are on) will
                replace the saved time for its route
    FT Forget   delete the saved time for the current or last route
    FT Clear    erase ALL learned times (press twice within 10 seconds)

  If your macro slots are full they are skipped. To turn this off set
  CREATE_MACROS = false near the top of FlightTimer.lua.

MOVING THE TIMER
  Press FT Move. A dark placeholder box appears.
    - With a mouse (PC, or the Deck trackpad in desktop mode): drag it.
    - In gamepad mode the box does not take the mouse: use FT Up / Down /
      Left / Right.
  Press FT Move again to hide the placeholder. The position is saved.
  Default position: center, a little below the middle of the screen.

FIXING A WRONG TIME
  Use FT Redo, then take the flight. It shows "learning", and the time you
  land with replaces the old one. Or FT Forget to delete that route, or
  FT Clear to start over.

TYPED COMMANDS (keyboard and mouse only)
  /ft or /flighttimer, then: unlock, lock, up/down/left/right [pixels],
  reset, redo [off], forget, clear, status, help. "/ft help" lists them.

NOTES
  - Saved data lives in WTF/Account/<account>/SavedVariables/FlightTimer.lua
  - Tested on the Forever beta, client 1.60.1 (70170).
