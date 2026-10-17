-- PartyLevels
-- Adds each group member's level to their name on Blizzard's raid-style
-- party and raid frames:  "52 Thrall"
--
-- How it stays safe: it only changes the NAME TEXT, right after Blizzard
-- writes it. It never calls Blizzard's frame code, never writes anything
-- onto Blizzard's frames (its notes live in its own table), never touches
-- nameplates, the chat box or the gamepad UI, and has no commands.

local CONFIG = {
    POSITION = "before",          -- "before" -> "52 Thrall", "after" -> "Thrall 52"
    COLOR_BY_DIFFICULTY = true,   -- color the level like the target frame does
    SHOW_SELF = true,             -- also show your own level on your frame
}

local decorated = setmetatable({}, { __mode = "k" }) -- frame -> { base=, shown=, unit= }

local function IsSecret(v) return issecretvalue and issecretvalue(v) end

local function IsGroupUnit(unit)
    if type(unit) ~= "string" or IsSecret(unit) then return false end
    if unit == "player" then return CONFIG.SHOW_SELF end
    return unit:find("^party%d") ~= nil or unit:find("^raid%d") ~= nil
end

local function LevelText(unit)
    local ok, level = pcall(UnitLevel, unit)
    if not ok or level == nil or IsSecret(level) then return nil end
    local text = (level > 0) and tostring(level) or "??"
    if CONFIG.COLOR_BY_DIFFICULTY and level > 0 then
        local getColor = GetCreatureDifficultyColor or GetQuestDifficultyColor
        if getColor then
            local okc, c = pcall(getColor, level)
            if okc and c and c.r then
                text = string.format("|cff%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, text)
            end
        end
    end
    return text
end

local function Compose(levelText, base)
    if CONFIG.POSITION == "after" then return base .. " " .. levelText end
    return levelText .. " " .. base
end

-- Put the level on one frame's name. `base` is the plain name Blizzard set.
local function Decorate(frame, unit, base)
    local fs = frame.name
    if not (fs and fs.SetText) then return end
    local lv = LevelText(unit)
    if not lv then return end
    local shown = Compose(lv, base)
    decorated[frame] = { base = base, shown = shown, unit = unit }
    fs:SetText(shown)
end

-- Runs right after Blizzard updates a compact unit frame's name.
local function OnUpdateName(frame)
    if not frame or (frame.IsForbidden and frame:IsForbidden()) then return end -- nameplates etc.
    local unit = frame.unit
    if not IsGroupUnit(unit) then return end
    local fs = frame.name
    if not (fs and fs.GetText) then return end
    local text = fs:GetText()
    if text == nil or IsSecret(text) or text == "" then return end
    local d = decorated[frame]
    if d and text == d.shown and d.unit == unit then return end -- already ours
    Decorate(frame, unit, text)
end

if type(CompactUnitFrame_UpdateName) == "function" then
    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame) pcall(OnUpdateName, frame) end)
end

-- Someone leveled: redraw their frames from the stored plain name.
local function Relevel(unit)
    for frame, d in pairs(decorated) do
        if d.unit == unit or not unit then
            local fs = frame.name
            if fs and fs.GetText and fs:GetText() == d.shown then
                pcall(Decorate, frame, d.unit, d.base)
            end
        end
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("UNIT_LEVEL")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LEVEL_UP" then
        -- your level changed: your own number, and every difficulty color
        C_Timer.After(0.5, function() Relevel(nil) end)
    elseif type(unit) == "string" and not IsSecret(unit) then
        Relevel(unit)
    end
end)
