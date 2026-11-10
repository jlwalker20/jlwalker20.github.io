HideChatButtons 0.2
===================
Hides the buttons stacked on the left side of the chat window:
social (friends), chat channels, the chat menu (speech bubble),
and the dark side strip behind them on every chat window.

INSTALL
  Copy the HideChatButtons folder into:
    World of Warcraft/_forever_/Interface/AddOns/

SETTINGS (top of HideChatButtons.lua, true = hidden)
  social   = true
  channels = true
  menu     = true
  voice    = false   (voice mute/deafen, if your client shows them)
  scroll   = false   (scroll arrows, if your client shows them)
  frame    = true    (the side strip itself)

HOW IT WORKS
  The buttons are set to invisible and stop taking clicks. Nothing is
  replaced or deleted, so it can't cause "blocked" errors. A light check
  once a second re-hides anything the game fades back in.

COMMANDS / MACROS
  /hcb          show or hide the buttons again (macro "HCB Toggle" is made for you
                if you have a free account macro slot)
  /hcb debug    lists which button names exist on your client, and how many
                side-strip textures it found

Built for WoW: Forever, client 1.60.1 (live build 70790).
