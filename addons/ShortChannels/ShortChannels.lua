-- ShortChannels: shortens chat channel names in all chat frames.
-- Edit the table below to add or change abbreviations.
--
-- Keys are the channel name in lowercase with spaces, brackets and
-- punctuation removed, so "Trade (Services)" is "tradeservices".
-- The full name is checked first, then just the part before " - "
-- (which drops city/language suffixes):
--   "Trade (Services) - English"   -> "tradeservices" -> TS
--   "Trade (Local) - Thunder Bluff" -> "tradelocal"    -> TL
--   "Trade - Orgrimmar"             -> "trade"         -> T

local SHORT = {
    general         = "G",
    trade           = "T",
    tradelocal      = "TL",   -- Forever's city trade (Thunder Bluff, Orgrimmar, Undercity...)
    tradeservices   = "TS",   -- Forever's "Trade (Services)"
    localdefense    = "LD",
    worlddefense    = "WD",
    lookingforgroup = "LFG",
    services        = "S",
    newcomers       = "N",
}

local function Key(s)
    return (s:lower():gsub("[^%w]", ""))
end

local function Shorten(text)
    -- Channel text looks like: |Hchannel:channel:5|h[5. Trade (Local) - Thunder Bluff]|h
    return (text:gsub("(|Hchannel:[^|]*|h)%[(%d+)%. ([^%]]+)%]|h", function(link, num, name)
        local short = SHORT[Key(name)]
        if not short then
            local base = name:match("^(.-) %- ") or name
            short = SHORT[Key(base)]
        end
        if not short then
            return nil -- unknown channel: leave untouched
        end
        return link .. "[" .. num .. ". " .. short .. "]|h"
    end))
end

local function HookFrame(frame)
    if not frame or frame.shortChannelsHooked or frame == ChatFrame2 then
        return
    end
    frame.shortChannelsHooked = true
    local orig = frame.AddMessage
    frame.AddMessage = function(self, text, ...)
        if type(text) == "string" then
            text = Shorten(text)
        end
        return orig(self, text, ...)
    end
end

for i = 1, NUM_CHAT_WINDOWS do
    HookFrame(_G["ChatFrame" .. i])
end
