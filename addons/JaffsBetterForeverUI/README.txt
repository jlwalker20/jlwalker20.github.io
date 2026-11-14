Jaff's Better Forever UI 0.4 (test)
===================================
One options panel for all of Jaff's Forever addons.

OPEN IT
  /jaffs                       (macro "Jaffs UI" is made if you have a free slot)
  the minimap's addon button   (Blizzard's addon compartment, if your client has it)

WHAT YOU SEE
  A tab for each of the package's addons you have installed, grouped like the
  download page (Look / Quality of life / Gamepad). Addons that don't have
  options in the panel yet say so; their settings are still in their .lua.
  Every tab starts with an "Addon enabled" switch (like the AddOns list, for
  this character; reload to apply). Addons you've switched off still get a
  tab, so you can switch them back on here.
  Settings marked (reload) need a /reload: use the Reload button at the bottom
  right (it turns red when a change is waiting for one).

CONTROLS
  Mouse:    click a row or its < > arrows; mouse wheel scrolls; drag the window.
  Gamepad:  (coming later: the panel uses the mouse layout for now)
            D-pad up/down  choose     D-pad left/right or A  change
            LB / RB        tabs       B  close      X  reload
  The controller can only steer the panel out of combat.

/jaffs debug   how many addons it found and which input mode it's in

Built for WoW: Forever, client 1.60.1 (live build 70790).
