-- GatheringLevels
-- When the world map shows a single zone, a few lines of text in its top-left
-- corner give that zone's skill ranges for the gathering professions YOU
-- have (Herbalism, Mining, Skinning, Fishing). Nothing on continent or
-- world maps. Ranges come from Data.lua (see the source note there).
--
-- Colors compare the range with your current skill:
--   red    = below the low end: you can't gather anything there yet
--   yellow = inside the range: some of it is gatherable, and it gives skill
--   green  = at or past the high end: you can gather everything
--
-- No commands, no macros, nothing in chat, and it never takes the mouse:
-- it is text laid over the map and nothing else.

local _, NS = ...

local CONFIG = {
    POINT = "TOPLEFT",     -- corner of the map the text sits in
    X = 78, Y = -70,       -- clears the map's decorative corner border
    FONT_SIZE = 15,        -- profession lines
    HEADER_SIZE = 16,      -- "Gathering"
    SHOW_YOUR_SKILL = true, -- adds "(you 42)" after each range
    FONT = "GameFontHighlight",
    HEADER_FONT = "GameFontNormal",
}

local PROFS = {
    -- key, skill line ID, English name (fallback for old skill APIs)
    { key = "h", id = 182, name = "Herbalism" },
    { key = "m", id = 186, name = "Mining" },
    { key = "s", id = 393, name = "Skinning" },
    { key = "f", id = 356, name = "Fishing" },
}

---------------------------------------------------------------- your skills
local skills = {} -- key -> current skill, only for professions you have

local function ScanSkills()
    for k in pairs(skills) do skills[k] = nil end
    local byId, byName = {}, {}
    for _, p in ipairs(PROFS) do byId[p.id] = p.key; byName[p.name:lower()] = p.key end

    if GetProfessions and GetProfessionInfo then
        local list = { GetProfessions() }
        for i = 1, 5 do
            local idx = list[i]
            if idx then
                local name, _, rank, _, _, _, skillLine = GetProfessionInfo(idx)
                local key = (skillLine and byId[skillLine]) or (name and byName[name:lower()])
                if key then skills[key] = rank or 0 end
            end
        end
    end
    if next(skills) == nil and GetNumSkillLines and GetSkillLineInfo then
        for i = 1, GetNumSkillLines() do
            local name, isHeader, _, rank = GetSkillLineInfo(i)
            local key = name and not isHeader and byName[name:lower()]
            if key then skills[key] = rank or 0 end
        end
    end
end

---------------------------------------------------------------- ranges
local function SkinReq(level)
    if level <= 10 then return 1 end
    if level <= 20 then return (level - 10) * 10 end
    return level * 5
end

-- returns low, high, highLabel (or nil if the profession has nothing here)
local function Range(zone, key)
    if key == "s" then
        if not zone.lv then return nil end
        return SkinReq(zone.lv[1]), SkinReq(zone.lv[2])
    elseif key == "f" then
        if not zone.f then return nil end
        local low = math.max(1, zone.f)
        local high = zone.f + 95
        if low > 300 then return 300, 300, "300+" end
        return low, math.min(high, 300)
    else
        local r = zone[key]
        if not r then return nil end
        return r[1], r[2]
    end
end

local function Color(skill, low, high)
    if skill < low then return "|cffff4040" end
    if skill < high then return "|cffffd200" end
    return "|cff40ff40"
end

---------------------------------------------------------------- the overlay
local overlay, header, lines = nil, nil, {}

-- same typeface and outline as the font object, just a bigger size
local function Resize(fs, size)
    if not (fs.GetFont and fs.SetFont) then return end
    local path, _, flags = fs:GetFont()
    if path then fs:SetFont(path, size, flags or "") end
end

local function Build()
    if overlay or not WorldMapFrame then return end
    local anchor = WorldMapFrame.ScrollContainer or WorldMapFrame
    overlay = CreateFrame("Frame", "GatheringLevelsOverlay", WorldMapFrame)
    overlay:SetSize(1, 1)
    overlay:EnableMouse(false)
    overlay:SetFrameStrata("HIGH")
    overlay:SetPoint(CONFIG.POINT, anchor, CONFIG.POINT, CONFIG.X, CONFIG.Y)
    header = overlay:CreateFontString(nil, "OVERLAY", CONFIG.HEADER_FONT)
    header:SetPoint("TOPLEFT", overlay, "TOPLEFT", 0, 0)
    header:SetJustifyH("LEFT")
    Resize(header, CONFIG.HEADER_SIZE)
    for i = 1, #PROFS do
        local fs = overlay:CreateFontString(nil, "OVERLAY", CONFIG.FONT)
        fs:SetPoint("TOPLEFT", i == 1 and header or lines[i - 1], "BOTTOMLEFT", 0, -3)
        fs:SetJustifyH("LEFT")
        Resize(fs, CONFIG.FONT_SIZE)
        lines[i] = fs
    end
    overlay:Hide()
end

local function ZoneForMap(mapID)
    if not (mapID and C_Map and C_Map.GetMapInfo) then return nil end
    local info = C_Map.GetMapInfo(mapID)
    if not info then return nil end
    local zoneType = (Enum and Enum.UIMapType and Enum.UIMapType.Zone) or 3
    if info.mapType ~= zoneType then return nil end -- continents, world: nothing
    local name = info.name
    name = NS.ALIASES[name] or name
    return NS.ZONES[name], name
end

local function Render(mapID)
    if not overlay then return end
    local zone = ZoneForMap(mapID)
    if not zone then overlay:Hide(); return end
    local n = 0
    for _, p in ipairs(PROFS) do
        local skill = skills[p.key]
        if skill then
            local low, high, label = Range(zone, p.key)
            if low then
                n = n + 1
                local range = label or ((low == high) and tostring(low) or (low .. "-" .. high))
                local text = Color(skill, low, high) .. p.name .. "  " .. range .. "|r"
                if CONFIG.SHOW_YOUR_SKILL then text = text .. "  |cffaaaaaa(you " .. skill .. ")|r" end
                lines[n]:SetText(text)
                lines[n]:Show()
            end
        end
    end
    for i = n + 1, #lines do lines[i]:SetText(""); lines[i]:Hide() end
    if n == 0 then overlay:Hide(); return end
    header:SetText("Gathering")
    overlay:Show()
end

---------------------------------------------------------------- keeping it current
-- While the map is open, check its zone a few times a second. That works on
-- every version of the map without hooking Blizzard's map code.
local watcher = CreateFrame("Frame")
local lastMap, acc = nil, 0

local function CurrentMapID()
    return WorldMapFrame and WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
end

local function StartWatching()
    lastMap, acc = nil, 1
    watcher:SetScript("OnUpdate", function(_, elapsed)
        acc = acc + elapsed
        if acc < 0.2 then return end
        acc = 0
        local id = CurrentMapID()
        if id ~= lastMap then
            lastMap = id
            pcall(Render, id)
        end
    end)
end

local function StopWatching()
    watcher:SetScript("OnUpdate", nil)
end

local hooked = false
local function Hook()
    if hooked or not WorldMapFrame then return end
    hooked = true
    pcall(Build)
    WorldMapFrame:HookScript("OnShow", StartWatching)
    WorldMapFrame:HookScript("OnHide", StopWatching)
    if WorldMapFrame:IsShown() then StartWatching() end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("SKILL_LINES_CHANGED")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, event)
    pcall(ScanSkills)
    pcall(Hook) -- the map may load late (Blizzard_WorldMap)
    if overlay and WorldMapFrame and WorldMapFrame:IsShown() then
        lastMap = nil -- redraw with new skills
    end
end)
