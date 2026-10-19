-- HideChatLegend 0.2
-- 0.2: no more flash: once found, the legend is kept invisible ahead of time
--      (and given back if another screen shows it while chat is closed)
-- In gamepad mode, opening the chat input box shows a button legend under it
-- ("A Send  X Chat Channels  Y Tab Settings  B Back"). This makes that legend
-- invisible while the chat box is open, and puts it back when it closes.
-- The buttons still work exactly the same; only the legend isn't drawn.
--
-- Safety (same rules as ChatFade): it never hooks the chat input box or
-- Blizzard's gamepad code (the path behind the chat hang). It only LOOKS at
-- the chat boxes a few times a second, and only changes the legend's opacity.
-- The legend is found once, the first time it appears, and remembered.
--
-- Macro (created for you):  HCL Debug   says whether the legend was found

local LABELS = { "Chat Channels", "Tab Settings" }   -- text on the legend (English client)
local MAX_SEARCHES = 6                                -- give up after this many tries per session

local legend, legendPath, savedAlpha
local searches = 0

local function SafeName(o)
    local ok, n = pcall(function() return o:GetName() end)
    return ok and type(n) == "string" and n or nil
end

local function Plain(t)
    if type(t) ~= "string" or (issecretvalue and issecretvalue(t)) then return nil end
    return (t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|[TA].-|[ta]", ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function Parent(o)
    local ok, p = pcall(function() return o:GetParent() end)
    return ok and p or nil
end

-- Is a chat input box open? (Read-only checks; nothing is hooked.)
local function ChatOpen()
    local imStyle = GetCVar and GetCVar("chatStyle") == "im"
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local eb = _G["ChatFrame" .. i .. "EditBox"]
        if eb then
            if eb.HasFocus and eb:HasFocus() then return true end
            if imStyle and eb.IsShown and eb:IsShown() then return true end
        end
    end
    return false
end

-- one search of the UI for the legend's labels; the legend is the closest
-- frame that holds both of them
local function FindLegend()
    searches = searches + 1
    local hits = {}
    local f = EnumerateFrames and EnumerateFrames()
    while f and #hits < #LABELS do
        local okR, regs = pcall(function() return { f:GetRegions() } end)
        if okR then
            for _, r in ipairs(regs) do
                local okT, kind = pcall(function() return r:GetObjectType() end)
                if okT and kind == "FontString" then
                    local okX, txt = pcall(function() return r:GetText() end)
                    txt = okX and Plain(txt)
                    if txt then
                        for _, l in ipairs(LABELS) do
                            if txt == l and r:IsVisible() then hits[#hits + 1] = r end
                        end
                    end
                end
            end
        end
        f = EnumerateFrames(f)
    end
    if #hits == 0 then return nil end
    -- ancestors of the first label
    local chainA, cur = {}, Parent(hits[1])
    while cur and cur ~= UIParent do chainA[cur] = true; cur = Parent(cur) end
    local box
    if hits[2] then
        cur = Parent(hits[2])
        while cur and cur ~= UIParent do
            if chainA[cur] then box = cur; break end
            cur = Parent(cur)
        end
    else
        box = Parent(Parent(hits[1]))   -- only one label found: its button's holder
    end
    -- never the chat window itself: if the box also holds a chat input box, fall
    -- back to just the label's own button holder
    if box then
        for i = 1, (NUM_CHAT_WINDOWS or 10) do
            local eb = _G["ChatFrame" .. i .. "EditBox"]
            local c = eb
            while c and c ~= UIParent do
                if c == box then box = Parent(Parent(hits[1])); break end
                c = Parent(c)
            end
        end
    end
    if box then
        local names, c = {}, box
        for _ = 1, 4 do if not c or c == UIParent then break end table.insert(names, 1, SafeName(c) or "?"); c = Parent(c) end
        legendPath = table.concat(names, " > ")
    end
    return box
end

local function HideLegend()
    if not legend then return end
    local ok, a = pcall(function() return legend:GetAlpha() end)
    if ok and a and a > 0 then
        savedAlpha = savedAlpha or a
        pcall(legend.SetAlpha, legend, 0)
    end
end

local function ShowLegend()
    if legend and savedAlpha then pcall(legend.SetAlpha, legend, savedAlpha) end
    savedAlpha = nil
end

-- Before the legend is known: look 10 times a second for the chat box opening.
-- Once known: check every frame, and keep the legend invisible ahead of time
-- whenever it's off screen, so the next chat open doesn't flash it. If some
-- other screen shows the same legend while chat is closed, it's given back.
local watch = CreateFrame("Frame")
local acc, wasOpen, tryAt = 0, false, nil
watch:SetScript("OnUpdate", function(_, e)
    if legend then
        if ChatOpen() then
            HideLegend()
        else
            local okV, vis = pcall(function() return legend:IsVisible() end)
            if okV and vis then ShowLegend() else HideLegend() end
        end
        return
    end
    acc = acc + e
    if acc < 0.1 then return end
    acc = 0
    local open = ChatOpen()
    if open and searches < MAX_SEARCHES then
        if not wasOpen then tryAt = GetTime() + 0.15 end    -- let the legend appear first
        if tryAt and GetTime() >= tryAt then
            tryAt = nil
            local ok, box = pcall(FindLegend)
            if ok and box then legend = box; HideLegend() end
        end
    end
    wasOpen = open
end)

---------------------------------------------------------------- debug macro
SLASH_HIDECHATLEGEND1 = "/hcl"
SlashCmdList["HIDECHATLEGEND"] = function()
    local say = function(m) print("|cff9999ffHideChatLegend:|r " .. m) end
    if legend then
        say("legend found: " .. (legendPath or "?") .. ", hidden while chat is open")
    else
        say(("legend not found yet (%d of %d searches used). Open the chat box once in gamepad mode."):format(searches, MAX_SEARCHES))
    end
end

local made = false
local mf = CreateFrame("Frame")
mf:RegisterEvent("PLAYER_ENTERING_WORLD")
mf:RegisterEvent("PLAYER_REGEN_ENABLED")
mf:SetScript("OnEvent", function()
    if made or (InCombatLockdown and InCombatLockdown()) then return end
    made = true
    if not (GetMacroIndexByName and CreateMacro and GetNumMacros) then return end
    pcall(function()
        local idx = GetMacroIndexByName("HCL Debug")
        if not (idx and idx > 0) and GetNumMacros() < (MAX_ACCOUNT_MACROS or 36) then
            if not pcall(CreateMacro, "HCL Debug", "INV_Letter_15", "/hcl", nil) then
                pcall(CreateMacro, "HCL Debug", "INV_MISC_QUESTIONMARK", "/hcl", nil)
            end
        end
    end)
end)
