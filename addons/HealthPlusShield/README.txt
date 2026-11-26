HealthPlusShield 0.6 (test)
===========================
Adds your health plus your shields at the right end of your player frame's
health bar, in Arial Narrow, like the bar's own text. It takes the place of the frame's own
right-hand number; the percentage on the left stays:

    2,072 + 427

The "+ 427" is every absorb on you added together: Power Word: Shield, Divine
Aegis and anything else. The game only gives the total, so it can't split them
by spell. With no shield it shows just your health.

HIDDEN NUMBERS
  If the game hides the numbers from addons, the addon lets the game print
  them, using the game's own helper to leave out "+ 0". If that helper isn't
  on this client, "+ 0" can't be hidden. /hps tells you which is happening.

INSTALL
  Copy the HealthPlusShield folder into:
    World of Warcraft/_forever_/Interface/AddOns/

COMMANDS
  /hps          status
  /hps max      also show max health (2,072 / 3,000 + 427)
  /hps zero     show "+ 0" with no shield
  /hps size 13  text size (0 = same as the frame)
  /hps up | down | left | right   nudge the text 1 pixel

SETTINGS
  In /jaffs with Jaff's Better Forever UI: max health, "+ 0", size, outline,
  shield colour.

Built for WoW: Forever, client 1.60.1 (live build 70790).
