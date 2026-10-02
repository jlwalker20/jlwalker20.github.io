-- ShortChannels: shortens chat channel names in all chat frames.
-- Edit the table below to add or change abbreviations.
-- Keys are lowercase with spaces removed. A full "base - suffix" key
-- (e.g. "trade-services") is checked first for special-cased channels
-- like "Trade - Services"; otherwise it falls back to just the part
-- before " - " (e.g. "Trade - Thunder Bluff" -> "trade" -> "T").

local SHORT = {
    general            = "G",
    trade              = "T",
    localdefense       = "LD",
    worlddefense       = "WD",
    lookingforgroup    = "LFG",
    services           = "S",
    newcomers          = "N",
    ["trade-services"] = "TS",
}

local function Shorten(text)
    -- Channel messages look like: |Hchannel:channel:2|h[2. Trade - Thunder Bluff]|h
    return (text:gsub("(|Hchannel:[^|]*|h)%[(%d+)%. ([^%]]+)%]|h", function(link, num, name)
        -- Try the full name first (handles special cases like "Trade - Services").
        local fullKey = name:lower():gsub("%s+", "")
        local short = SHORT[fullKey]

        if not short then
            -- Fall back to just the part before " - " (strips city/zone suffixes).
            local base = name:match("^(.-) %- ") or name
            local baseKey = base:lower():gsub("%s+", "")
            short = SHORT[baseKey]
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
