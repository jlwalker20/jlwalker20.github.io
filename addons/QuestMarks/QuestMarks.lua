-- QuestMarks 0.5
-- 0.5: no chat message at login (it was only there for testing)
-- 0.4: says when it has loaded; debug reports any failure instead of staying silent
-- 0.3: four ways of asking (game check, tooltip data, tooltip text, kill
--      objectives by name); /qm debug shows what each one says
-- Puts a small "*" just after a nameplate's name when that unit is part of
-- one of your active quests: something you have to kill, or something that
-- drops an item a quest still needs.
--
-- How it knows: the game's own quest check for the unit, or (if that isn't
-- available) the quest lines the game puts in the unit's tooltip.
--
-- Safety: it never changes Blizzard's name text and hooks nothing. The "*"
-- is its own little label sitting next to the name. Every check is wrapped
-- so a failure can't spill errors: a plate it can't read just gets no mark.
--
-- Macro (created for you):  QM Toggle   turn the marks on/off

local MARK = "*"
local COLOR = { 1, 0.82, 0 }      -- quest yellow

local DB
local labels = {}                 -- nameplate frame -> our label
local known = {}                  -- unit token -> true/false (cleared when quests change)

local function IsSecret(v) return issecretvalue and issecretvalue(v) end

-- ---------------------------------------------------------------- detection
-- Several ways to ask, used in order; Forever's client may not have all of them.

-- 1) the game's direct check (modern clients)
local function ByQuestCheck(unit)
    local f = C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest
    if not f then return nil end
    local ok, v = pcall(f, unit)
    if not ok or IsSecret(v) then return nil end
    return v == true
end

-- 2) the unit's tooltip data (modern clients)
local function ByTooltipData(unit)
    local f = C_TooltipInfo and C_TooltipInfo.GetUnit
    local T = Enum and Enum.TooltipDataLineType
    if not (f and T) then return nil end
    local ok, data = pcall(f, unit)
    if not ok or type(data) ~= "table" or IsSecret(data) or type(data.lines) ~= "table" then return nil end
    for _, line in ipairs(data.lines) do
        local t = type(line) == "table" and line.type
        if t and not IsSecret(t) and (t == T.QuestObjective or t == T.QuestTitle) then
            local done = line.completed
            if IsSecret(done) or done ~= true then return true end
        end
    end
    return false
end

-- 3) read a hidden copy of the unit's tooltip: quest lines look like "Tiger Fur: 1/4"
local scanTip
local function ByTooltipText(unit)
    if not scanTip then
        local ok, tip = pcall(CreateFrame, "GameTooltip", "QuestMarksScanTip", nil, "GameTooltipTemplate")
        if not ok or not tip then return nil end
        scanTip = tip
    end
    local ok = pcall(function()
        scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
        scanTip:ClearLines()
        scanTip:SetUnit(unit)
    end)
    if not ok then return nil end
    local found = false
    for i = 2, math.min(scanTip:NumLines() or 0, 20) do
        local fs = _G["QuestMarksScanTipTextLeft" .. i]
        local okT, txt = pcall(function() return fs and fs:GetText() end)
        if okT and type(txt) == "string" and not IsSecret(txt) then
            local have, need = txt:match("(%d+)%s*/%s*(%d+)%s*$")
            if have and tonumber(have) < tonumber(need) then found = true; break end
        end
    end
    pcall(scanTip.Hide, scanTip)
    return found
end

-- 4) kill objectives in your quest log name the mob: "Bristleback Quilboar slain: 0/8"
local killNames = {}
local function ReadQuestLog()
    wipe(killNames)
    local function add(text, finished)
        if type(text) ~= "string" or IsSecret(text) or finished then return end
        local name, have, need = text:match("^(.-)%s*:%s*(%d+)%s*/%s*(%d+)")
        if name and tonumber(have) < tonumber(need) then
            name = name:gsub("%s+[Ss]lain$", ""):gsub("%s+[Kk]illed$", "")
            killNames[name] = true
        end
    end
    pcall(function()
        if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo and C_QuestLog.GetQuestObjectives then
            for i = 1, C_QuestLog.GetNumQuestLogEntries() do
                local info = C_QuestLog.GetInfo(i)
                if info and not info.isHeader and info.questID then
                    for _, o in ipairs(C_QuestLog.GetQuestObjectives(info.questID) or {}) do
                        if o.type == "monster" then add(o.text, o.finished) end
                    end
                end
            end
        elseif GetNumQuestLogEntries and GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
            for i = 1, (GetNumQuestLogEntries()) do
                for j = 1, (GetNumQuestLeaderBoards(i) or 0) do
                    local text, kind, finished = GetQuestLogLeaderBoard(j, i)
                    if kind == "monster" then add(text, finished) end
                end
            end
        end
    end)
end
local function ByKillName(unit)
    local ok, name = pcall(UnitName, unit)
    if not ok or type(name) ~= "string" or IsSecret(name) then return nil end
    return killNames[name] == true
end

local METHODS = {
    { "quest check", ByQuestCheck }, { "tooltip data", ByTooltipData },
    { "tooltip text", ByTooltipText }, { "kill objective", ByKillName },
}

local function CheckUnit(unit)
    for _, m in ipairs(METHODS) do
        local ok, v = pcall(m[2], unit)    -- one way failing never stops the others
        if ok and v == true then return true end
    end
    return false
end

local function LabelFor(plate)
    local l = labels[plate]
    if l then return l end
    local uf = rawget(plate, "UnitFrame")
    local name = uf and rawget(uf, "name")
    if not name then return nil end
    local holder = CreateFrame("Frame", nil, plate)        -- ours; hides with the plate
    holder:SetAllPoints(plate)
    if holder.SetFrameLevel and uf.GetFrameLevel then holder:SetFrameLevel(uf:GetFrameLevel() + 5) end
    local fs = holder:CreateFontString(nil, "OVERLAY")
    local okF, font, size, flags = pcall(name.GetFont, name)
    if okF and font and not IsSecret(font) then fs:SetFont(font, size or 10, flags) else fs:SetFontObject(GameFontNormalSmall) end
    fs:SetText(MARK)
    fs:SetTextColor(COLOR[1], COLOR[2], COLOR[3])
    fs:SetPoint("LEFT", name, "RIGHT", 1, 0)
    l = { holder = holder, fs = fs }
    labels[plate] = l
    return l
end

local function UpdatePlate(plate, unit)
    if not (plate and unit) then return end
    local want = false
    if DB and DB.enabled ~= false then
        if known[unit] == nil then known[unit] = CheckUnit(unit) end
        want = known[unit]
    end
    local l = labels[plate]
    if want and not l then l = LabelFor(plate) end
    if l then if want then l.fs:Show() else l.fs:Hide() end end
end

local function RefreshAll()
    if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
    for _, plate in ipairs(C_NamePlate.GetNamePlates() or {}) do
        local unit = rawget(plate, "namePlateUnitToken") or (rawget(plate, "UnitFrame") and rawget(plate.UnitFrame, "unit"))
        if type(unit) == "string" and not IsSecret(unit) then pcall(UpdatePlate, plate, unit) end
    end
end

local ADDON = ...
local events = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED",
                     "QUEST_LOG_UPDATE", "UNIT_QUEST_LOG_CHANGED", "QUEST_ACCEPTED", "QUEST_REMOVED" }) do
    pcall(events.RegisterEvent, events, e)
end
local queued = false
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then
            QuestMarksDB = QuestMarksDB or {}
            DB = QuestMarksDB
            if DB.enabled == nil then DB.enabled = true end
        end
        return
    end
    if event == "NAME_PLATE_UNIT_ADDED" or event == "NAME_PLATE_UNIT_REMOVED" then
        if type(arg1) == "string" and not IsSecret(arg1) then
            known[arg1] = nil
            if event == "NAME_PLATE_UNIT_ADDED" and C_NamePlate and C_NamePlate.GetNamePlateForUnit then
                local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, arg1)
                if ok and plate then pcall(UpdatePlate, plate, arg1) end
            end
        end
        return
    end
    -- quests changed: check every shown plate again (once per burst of events)
    wipe(known)
    ReadQuestLog()
    if queued then return end
    queued = true
    C_Timer.After(0.3, function() queued = false; pcall(RefreshAll) end)
end)

-- "/qm debug": what each way of asking says about each plate on screen
local function Debug()
    local say = function(m) print("|cff9999ffQuestMarks:|r " .. m) end
    ReadQuestLog()
    local names = {}
    for n in pairs(killNames) do names[#names + 1] = n end
    say("kill objectives in your log: " .. (#names > 0 and table.concat(names, ", ") or "none"))
    local plates = (C_NamePlate and C_NamePlate.GetNamePlates and C_NamePlate.GetNamePlates()) or {}
    if #plates == 0 then say("no nameplates on screen") end
    for i, plate in ipairs(plates) do
        if i > 6 then break end
        pcall(function()
            local unit = rawget(plate, "namePlateUnitToken") or (rawget(plate, "UnitFrame") and rawget(plate.UnitFrame, "unit"))
            local okN, nm = pcall(UnitName, unit)
            nm = okN and type(nm) == "string" and not IsSecret(nm) and nm or "?"
            local parts = {}
            for _, m in ipairs(METHODS) do
                local okM, v = pcall(m[2], unit)
                parts[#parts + 1] = m[1] .. "=" .. (not okM and "error" or v == nil and "n/a" or tostring(v))
            end
            local uf = rawget(plate, "UnitFrame")
            local l = labels[plate]
            say(("%s: %s; name text %s; mark %s"):format(nm, table.concat(parts, ", "),
                (uf and rawget(uf, "name")) and "found" or "NOT found",
                l and (l.fs:IsShown() and "shown" or "hidden") or "none"))
        end)
    end
end

SLASH_QUESTMARKS1 = "/qm"
SLASH_QUESTMARKS2 = "/questmarks"
SlashCmdList["QUESTMARKS"] = function(msg)
    if (msg or ""):lower():find("debug") then
        print("|cff9999ffQuestMarks:|r debug (version 0.5)")
        local ok, err = pcall(Debug)
        if not ok then print("|cff9999ffQuestMarks:|r debug stopped: " .. tostring(err)) end
        return
    end
    if not DB then return end
    DB.enabled = not DB.enabled
    wipe(known)
    pcall(RefreshAll)
    print("|cff9999ffQuestMarks:|r " .. (DB.enabled and "on" or "off"))
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
        for _, m in ipairs({ { "QM Toggle", "/qm" }, { "QM Debug", "/qm debug" } }) do
            local idx = GetMacroIndexByName(m[1])
            if not (idx and idx > 0) and GetNumMacros() < (MAX_ACCOUNT_MACROS or 36) then
                if not pcall(CreateMacro, m[1], "INV_Misc_Note_02", m[2], nil) then
                    pcall(CreateMacro, m[1], "INV_MISC_QUESTIONMARK", m[2], nil)
                end
            end
        end
    end)
end)
