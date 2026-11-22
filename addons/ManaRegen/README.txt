ManaRegen 0.4 (test)
====================
A small movable readout of your mana regen:

  Regen  12.5 /s      what you regenerate right now: the casting rate while the
                      five-second rule is on, the full rate once it's over
  5-sec rule  3.1     counts down after you spend mana, then "full regen"

The rate comes from the game itself. When the game hides your mana, only casts
that cost mana start the five-second rule: wand shots, fishing, gathering,
crafting, food and other free actions don't.

INSTALL
  Copy the ManaRegen folder into:
    World of Warcraft/_forever_/Interface/AddOns/

MOVING IT
  Edit Mode unlocks it (a teal outline): drag it. Or /mr unlock, drag, /mr unlock.
  Gamepad: /mr up | down | left | right nudge it; /mr reset puts it back.

SETTINGS (in /jaffs with Jaff's Better Forever UI, or the top of ManaRegen.lua)
  Per second / per 5 seconds (MP5) / per tick; show the other rate too;
  five-second rule line; hide while mana is full; text size.

/mr         shows the raw numbers and whether the game hid anything
/mr debug   reports each cast in chat: costs mana or not, and whether it
            started the five-second rule (type it again to stop)

Built for WoW: Forever, client 1.60.1 (live build 70790).
