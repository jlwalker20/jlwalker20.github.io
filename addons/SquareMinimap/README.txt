SquareMinimap 0.7 (test)
========================
Makes the minimap square and replaces the round ring with a square border
built from Blizzard's own metal frame pieces (sharp corners, stretched edges),
tinted gray to match DarkIronUI. The north arrow is kept, centered on the top
edge, the zoom buttons sit side by side hugging the bottom-right of the
border. Other addons are told the map is square, so edge buttons sit right.

INSTALL
  Copy the SquareMinimap folder into:
    World of Warcraft/_forever_/Interface/AddOns/

BORDER STYLES (/sqm style cycles the ones this client has)
  Diamond metal (default), Dialog box edge, Thin tooltip edge,
  Generic metal, Metal (window frame, shown smaller)
  /sqm probe lists which exist on your client.

COMMANDS (macros "SQM Style" and "SQM Debug" if you have free slots)
  /sqm style   next border style
  /sqm probe   which border art exists
  /sqm frames  list the buttons on / around the map, numbered, with where
               they sit and their art name
  /sqm sun 3   put frame 3 from that list on the top-right corner, over the
               border (saved);  /sqm sun off  stop (then /reload)
  /sqm round   switch back to Blizzard's round map (and again for square)
  /sqm debug   what it hid, which border, where the north arrow came from
  /sqm help    this list

SETTINGS (top of SquareMinimap.lua)
  TINT, DESATURATE, SCALE (corner size), INSET, HIDE_ROUND, NORTH, NORTH_Y,
  ZOOM, ZOOM_GAP, ZOOM_X, ZOOM_Y

Built for WoW: Forever, client 1.60.1 (live build 70790).

OPTIONS PANEL
  With "Jaff's Better Forever UI" installed, its settings (and an on/off
  switch) are in /jaffs instead of the .lua (they are saved).
