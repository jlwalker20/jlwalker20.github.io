-- HideChatButtons 0.2
-- Hides the buttons stacked on the left side of the chat window. Each one can
-- be turned on or off below (true = hidden).
--
-- How: the buttons are made invisible (opacity 0) and stop taking clicks.
-- Nothing is replaced or deleted, and Blizzard's own show/hide calls are left
-- alone, so the game never finds a button missing. A light check once a
-- second re-hides anything Blizzard fades back in.
--
-- Macro (created for you):  HCB Toggle   show / hide the buttons again

local HIDE = {
    social   = true,    -- the social / friends button (with its online count)
    channels = true,    -- the chat channels button
    menu     = true,    -- the chat menu (speech bubble) button
    voice    = false,   -- the voice chat mute / deafen buttons, if your client shows them
    scroll   = false,   -- the scroll up / down / to-bottom arrows, if your client shows them
    frame    = true,    -- the dark side strip behind those buttons (every chat window)
}

-- the names Blizzard uses for each (the first that exists is used; several clients covered)
local PARTS = {
    social   = { "QuickJoinToastButton", "FriendsMicroButton", "ChatFrameSocialButton" },
    channels = { "ChatFrameChannelButton" },
    menu     = { "ChatFrameMenuButton" },
    voice    = { "ChatFrameToggleVoiceDeafenButton", "ChatFrameToggleVoiceMuteButton" },
    scroll   = { "ChatFrame1ButtonFrameUpButton", "ChatFrame1ButtonFrameDownButton",
                 "ChatFrame1ButtonFrameBottomButton", "ChatFrame1ButtonFrame" },
}

local DB
local function Say(m) print("|cff9999ffHideChatButtons:|r " .. m) end

local saved = {}   -- button -> { alpha, mouse } before we hid it

local function Hide(f)
    if not saved[f] then
        local okA, a = pcall(f.GetAlpha, f)
        local okM, m = pcall(function() return f.IsMouseEnabled and f:IsMouseEnabled() end)
        saved[f] = { alpha = (okA and a) or 1, mouse = okM and m }
    end
    local okA, a = pcall(f.GetAlpha, f)
    if not (okA and a == 0) then pcall(f.SetAlpha, f, 0) end
    if f.EnableMouse and f.IsMouseEnabled and f:IsMouseEnabled() then pcall(f.EnableMouse, f, false) end
end

local function Unhide(f)
    local s = saved[f]
    if not s then return end
    pcall(f.SetAlpha, f, s.alpha or 1)
    if s.mouse and f.EnableMouse then pcall(f.EnableMouse, f, true) end
    saved[f] = nil
end

-- the side strip: only its own textures are faded, so any buttons sitting on it
-- (like the scroll arrows) keep their own setting
local function SideFrames()
    local list = {}
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local bf = _G["ChatFrame" .. i .. "ButtonFrame"]
        if type(bf) == "table" and bf.GetRegions then
            for _, r in ipairs({ bf:GetRegions() }) do
                if r and r.SetAlpha then list[#list + 1] = r end
            end
        end
    end
    return list
end

local function Apply()
    local on = not (DB and DB.off)
    for _, r in ipairs(SideFrames()) do
        if on and HIDE.frame then Hide(r) else Unhide(r) end
    end
    for key, names in pairs(PARTS) do
        for _, n in ipairs(names) do
            local f = _G[n]
            if type(f) == "table" and f.SetAlpha then
                if on and HIDE[key] then Hide(f) else Unhide(f) end
            end
        end
    end
end

local ADDON = ...
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then HideChatButtonsDB = HideChatButtonsDB or {}; DB = HideChatButtonsDB end
        return
    end
    pcall(Apply)
end)
C_Timer.NewTicker(1, function() pcall(Apply) end)

SLASH_HIDECHATBUTTONS1 = "/hcb"
SlashCmdList["HIDECHATBUTTONS"] = function(msg)
    if not DB then return end
    if (msg or ""):lower():find("debug") then
        for key, names in pairs(PARTS) do
            local found = {}
            for _, n in ipairs(names) do if _G[n] then found[#found + 1] = n end end
            Say(("%s: %s%s"):format(key, #found > 0 and table.concat(found, ", ") or "none on this client",
                HIDE[key] and "" or " (set to show)"))
        end
        Say(("frame: %d side-strip textures found%s"):format(#SideFrames(), HIDE.frame and "" or " (set to show)"))
        return
    end
    DB.off = not DB.off
    pcall(Apply)
    Say(DB.off and "chat buttons shown" or "chat buttons hidden")
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
        local idx = GetMacroIndexByName("HCB Toggle")
        if not (idx and idx > 0) and GetNumMacros() < (MAX_ACCOUNT_MACROS or 36) then
            if not pcall(CreateMacro, "HCB Toggle", "INV_Letter_15", "/hcb", nil) then
                pcall(CreateMacro, "HCB Toggle", "INV_MISC_QUESTIONMARK", "/hcb", nil)
            end
        end
    end)
end)
