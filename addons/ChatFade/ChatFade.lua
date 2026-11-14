-- ChatFade 1.2
-- 1.2: settings saved and changeable in Jaff's Better Forever UI (/jaffs)
-- Fades the chat window out after IDLE_SECONDS with no new chat line, and
-- brings it straight back to full opacity when a line arrives. That
-- includes system lines such as "Changed Channel: [1. G]" when you move
-- between zones, plus loading screens and zone changes as a backup.
--
-- It stays visible while you're typing in chat or have the mouse over it,
-- and (1.1) comes straight back when you open the chat input box.
--
-- Controller-mode safety (lessons from Angler's Journal): no Blizzard
-- templates, no mouse capture, nothing added to Blizzard's Esc list, and
-- it never hooks the chat input box (the path that hangs when you type in
-- chat in controller mode). To notice the input box opening it only LOOKS
-- at it a few times a second, and only while the chat is faded. It only listens for new lines on the chat
-- windows and changes their opacity. No loop runs while idle; a short
-- per-frame update runs only during the fade itself.

local CONFIG = {
    IDLE_SECONDS = 30,     -- seconds without a new line before fading
    FADED_ALPHA = 0,       -- 0 = fully hidden; try 0.25 for a faint ghost
    FADE_OUT_TIME = 1.5,   -- seconds the fade-out takes
    FADE_IN_TIME = 0.25,   -- seconds the fade-in takes
}

-- Chat frames whose new lines wake the chat. ChatFrame2 is the combat log
-- tab; its spam would keep chat awake during every fight.
local IGNORE_FOR_WAKE = { ChatFrame2 = true }

-- Extra chat pieces that sit outside the chat frames themselves. Each is
-- only used if it exists in this client. The tab bar (GeneralDockManager)
-- fades the tabs with it.
local EXTRA_PARTS = {
    "GeneralDockManager",
    "ChatFrameMenuButton",
    "ChatFrameChannelButton",
    "ChatFrameToggleVoiceDeafenButton",
    "ChatFrameToggleVoiceMuteButton",
    "QuickJoinToastButton",
}

local DEFAULTS = {}
for k, v in pairs(CONFIG) do DEFAULTS[k] = v end
local DB

local driver = CreateFrame("Frame")
local alpha, target, speed = 1, 1, 0
local lastActivity = 0
local checkPending = false
local hooked = {}

local function NumWindows()
    return NUM_CHAT_WINDOWS or 10
end

local function ChatParts()
    local list = {}
    for i = 1, NumWindows() do
        local f = _G["ChatFrame" .. i]
        if f and f.SetAlpha then list[#list + 1] = f end
    end
    for _, name in ipairs(EXTRA_PARTS) do
        local f = _G[name]
        if f and f.SetAlpha then list[#list + 1] = f end
    end
    return list
end

local parts = {}

local function ApplyAlpha(a)
    for _, f in ipairs(parts) do
        f:SetAlpha(a)
    end
end

local function OnUpdate(self, elapsed)
    if alpha < target then
        alpha = math.min(target, alpha + elapsed * speed)
    else
        alpha = math.max(target, alpha - elapsed * speed)
    end
    ApplyAlpha(alpha)
    if alpha == target then
        self:SetScript("OnUpdate", nil) -- stop updating once the fade is done
    end
end

local function FadeTo(newTarget, duration)
    parts = ChatParts() -- picks up chat windows created since last time
    target = newTarget
    local diff = math.abs(newTarget - alpha)
    if diff == 0 then
        ApplyAlpha(alpha)
        driver:SetScript("OnUpdate", nil)
        return
    end
    speed = diff / math.max(duration, 0.01)
    driver:SetScript("OnUpdate", OnUpdate)
end

-- Is a chat input box open? (Read-only checks; nothing is hooked.)
local function EditBoxOpen()
    local imStyle = GetCVar and GetCVar("chatStyle") == "im"
    for i = 1, NumWindows() do
        local eb = _G["ChatFrame" .. i .. "EditBox"]
        if eb then
            if eb.HasFocus and eb:HasFocus() then return true end
            -- in "IM" chat style the box is only shown while open
            if imStyle and eb.IsShown and eb:IsShown() then return true end
        end
    end
    return false
end

-- Stay visible while you're typing or pointing at the chat.
local function KeepVisible()
    if EditBoxOpen() then return true end
    if MouseIsOver then
        for i = 1, NumWindows() do
            local f = _G["ChatFrame" .. i]
            if f and f:IsShown() then
                local ok, over = pcall(MouseIsOver, f)
                if ok and over then return true end
            end
        end
    end
    return false
end

local ScheduleCheck
local Watch

local function Check()
    checkPending = false
    if DB and DB.off then return end
    local idle = GetTime() - lastActivity
    if idle < CONFIG.IDLE_SECONDS then
        ScheduleCheck(CONFIG.IDLE_SECONDS - idle)
    elseif KeepVisible() then
        ScheduleCheck(2)
    elseif target ~= CONFIG.FADED_ALPHA then
        FadeTo(CONFIG.FADED_ALPHA, CONFIG.FADE_OUT_TIME)
        Watch(true)
    end
end

-- At most one timer is ever waiting; it re-checks how long chat has
-- really been idle when it fires.
ScheduleCheck = function(delay)
    if checkPending then return end
    checkPending = true
    C_Timer.After(math.max(delay, 0.1), function() pcall(Check) end)
end

local watcher = CreateFrame("Frame")
local Wake

-- While the chat is faded, look for the input box opening a few times a second.
Watch = function(on)
    if on then
        local acc = 0
        watcher:SetScript("OnUpdate", function(_, elapsed)
            acc = acc + elapsed
            if acc < 0.15 then return end
            acc = 0
            if EditBoxOpen() then pcall(Wake) end
        end)
    else
        watcher:SetScript("OnUpdate", nil)
    end
end

Wake = function()
    lastActivity = GetTime()
    Watch(false)
    if target ~= 1 or alpha ~= 1 then
        FadeTo(1, CONFIG.FADE_IN_TIME)
    end
    ScheduleCheck(CONFIG.IDLE_SECONDS)
end

local function HookChatFrames()
    for i = 1, NumWindows() do
        local name = "ChatFrame" .. i
        local f = _G[name]
        if f and not hooked[name] and not IGNORE_FOR_WAKE[name] and f.AddMessage then
            hooked[name] = true
            -- post-hook: runs after Blizzard (or ShortChannels) adds the line
            hooksecurefunc(f, "AddMessage", function() pcall(Wake) end)
        end
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:RegisterEvent("UPDATE_CHAT_WINDOWS")

events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "ChatFade" then
            ChatFadeDB = ChatFadeDB or {}
            DB = ChatFadeDB
            for k in pairs(DEFAULTS) do if DB[k] ~= nil then CONFIG[k] = DB[k] end end
        end
        return
    end
    if event == "PLAYER_LOGIN" or event == "UPDATE_CHAT_WINDOWS" then
        pcall(HookChatFrames)
    end
    pcall(Wake)
end)

-- ---------------------------------------------------------------- options for Jaff's Better Forever UI
local function Setting(key)
    return function() return CONFIG[key] end,
           function(v) CONFIG[key] = v; if DB then DB[key] = v end; pcall(Wake) end
end
local function Opt(t, key) t.get, t.set = Setting(key); return t end

local def = { addon = "ChatFade", options = {
    { type = "toggle", label = "Fade the chat", desc = "Off keeps the chat fully visible.",
      get = function() return not (DB and DB.off) end,
      set = function(v) if DB then DB.off = not v end; pcall(Wake) end },
    Opt({ type = "slider", label = "Fade after (seconds)", desc = "Seconds with no new chat line before the chat fades.",
          min = 5, max = 120, step = 5 }, "IDLE_SECONDS"),
    Opt({ type = "slider", label = "Faded opacity", desc = "0 hides the chat completely; higher leaves a faint ghost.",
          min = 0, max = 0.8, step = 0.05, format = "%.2f" }, "FADED_ALPHA"),
    Opt({ type = "slider", label = "Fade-out time (seconds)", min = 0.25, max = 5, step = 0.25, format = "%.2f" }, "FADE_OUT_TIME"),
    Opt({ type = "slider", label = "Fade-in time (seconds)", min = 0, max = 2, step = 0.25, format = "%.2f" }, "FADE_IN_TIME"),
    { type = "button", label = "Defaults", button = "Reset to defaults", desc = "Put every ChatFade setting back to how it shipped.",
      func = function()
          for k, v in pairs(DEFAULTS) do CONFIG[k] = v; if DB then DB[k] = nil end end
          if DB then DB.off = nil end
          pcall(Wake)
      end },
} }
if JaffsUI and JaffsUI.Register then JaffsUI:Register(def)
else JaffsUI_Queue = JaffsUI_Queue or {}; table.insert(JaffsUI_Queue, def) end
