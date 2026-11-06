-- ShortChannels 1.4
-- 1.4: fixes channels 1-5 disappearing on the live client (short labels are padded
--      with invisible codes so the game's length check still passes)
-- 1.3: channel 6 shows as "OOC" (BY_NUMBER table below), plus an "OOC" name entry
-- Shortens chat channel names:  [2. Trade - Orgrimmar] -> [2. T]
--
-- 1.2: rebuilt to stop the gamepad chat hang / "blocked from an action"
-- prompt. Versions up to 1.1 REPLACED each chat window's AddMessage
-- function, which taints Blizzard's chat code, and the gamepad UI then
-- trips over it. 1.2 never touches the chat windows at all. It uses the
-- game's official chat-filter hook instead: before Blizzard draws a channel
-- message, it hands the channel name to this addon, which returns the short
-- version. If the game hides a message's contents from addons (secret
-- values), the message is passed through untouched.
--
-- Edit the table below to add or change abbreviations. Keys are the
-- channel name in lowercase with spaces and punctuation removed, so
-- "Trade (Services)" is "tradeservices". The full name is checked first,
-- then just the part before " - " (which drops city/language suffixes):
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
    ooc             = "OOC",
    outofcharacter  = "OOC",
}

-- By channel NUMBER, whatever the channel is called: these win over the names above.
-- e.g. [6] = "OOC" shows every channel-6 message as [6. OOC]
local BY_NUMBER = {
    [6] = "OOC",
}

-- Chat events whose 4th argument is the channel string, e.g. "2. Trade - Orgrimmar"
local EVENTS = {
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_CHANNEL_NOTICE",       -- "Changed Channel: [1. General - Durotar]"
    "CHAT_MSG_CHANNEL_NOTICE_USER",
    "CHAT_MSG_CHANNEL_JOIN",
    "CHAT_MSG_CHANNEL_LEAVE",
}

local function IsSecret(v) return issecretvalue and issecretvalue(v) end

local function Key(s)
    return (s:lower():gsub("[^%w]", ""))
end

local function ShortName(name)
    local short = SHORT[Key(name)]
    if not short then
        local base = name:match("^(.-) %- ") or name
        short = SHORT[Key(base)]
    end
    return short
end

-- "2. Trade - Orgrimmar" -> "2. T"; "Trade - Orgrimmar" -> "T"; unknown -> nil
local function Shorten(channelString)
    local num, name = channelString:match("^(%d+)%. (.+)$")
    if num then
        local short = BY_NUMBER[tonumber(num)] or ShortName(name)
        return short and (num .. ". " .. short) or nil
    end
    return ShortName(channelString)
end

local function Filter(_, _, arg1, arg2, arg3, arg4, ...)
    if type(arg4) ~= "string" or IsSecret(arg4) or arg4 == "" then return false end
    local ok, short = pcall(Shorten, arg4)
    if not (ok and short) then return false end
    -- The live client only shows a channel message if this label is LONGER
    -- than the channel's own name (it compares lengths before matching the
    -- channel to your chat tab). "2. T" is shorter than "Trade", so the game
    -- dropped the message. Pad the short label back to the original length
    -- with "|r" codes: they print nothing, so you still see just [2. T].
    local missing = #arg4 - #short
    if missing > 0 then short = short .. string.rep("|r", math.ceil(missing / 2)) end
    -- pass every other argument through exactly as received
    return false, arg1, arg2, arg3, short, ...
end

local AddFilter = ChatFrame_AddMessageEventFilter
    or (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter)
if AddFilter then
    for _, event in ipairs(EVENTS) do
        AddFilter(event, Filter)
    end
end
