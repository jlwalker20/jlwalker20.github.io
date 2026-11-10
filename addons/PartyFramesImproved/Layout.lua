-- PartyFramesImproved: Layout (was PartyGrowUp 0.9)
-- Stacks the raid-style party frames from the bottom up, with you on top and
-- everyone else in class order; the "Party" label moves to the bottom.
-- Frames are protected, so they are only moved OUT of combat.

local ADDON, ns = ...
local SLOTS = 5          -- frames in a full party (sets where the bottom is)
local GAP   = 0          -- extra space between frames, in pixels
local PLAYER_ON_TOP = true   -- default for keeping your frame at the top (/pgu top flips it)
local SORT_BY_ROLE  = true   -- default for the class sort (/pgu sort flips it)

-- class order, top to bottom (below you). Edit to taste.
local CLASS_ORDER = { "WARRIOR", "PALADIN", "DRUID", "ROGUE", "HUNTER", "SHAMAN", "WARLOCK", "MAGE", "PRIEST" }

local DB
local function Say(m) print("|cff9999ffPFI:|r " .. m) end

local ours, hooked = {}, {}
local moving, pending = false, false
local base             -- Blizzard's own anchor for the first frame
local tbase            -- Blizzard's own anchor for the "Party" label

local function Title()
    local t = (CompactPartyFrame and CompactPartyFrame.title) or _G.CompactPartyFrameTitle
    if type(t) == "table" and t.SetPoint and t.GetPoint then return t end
end

local function IsMe(f)
    local u = f.displayedUnit or f.unit
    if u == "player" then return true end
    if type(u) == "string" and UnitIsUnit then
        local ok, r = pcall(UnitIsUnit, u, "player")
        return ok and not (issecretvalue and issecretvalue(r)) and r == true
    end
    return false
end

local function SortOn()
    if DB and DB.sort ~= nil then return DB.sort end
    return SORT_BY_ROLE
end

-- sort key: position in the class list (unknown classes go last)
local function ClassOf(f)
    local u = f.displayedUnit or f.unit
    if type(u) ~= "string" then return nil end
    local ok, _, class = pcall(UnitClass, u)
    return ok and type(class) == "string" and class or nil
end

local function RankOf(f)
    local class = ClassOf(f)
    for i, c in ipairs(CLASS_ORDER) do if c == class then return i end end
    return #CLASS_ORDER + 1
end

local function LabelHidden() return DB and DB.hideLabel end

-- hide = invisible and no clicks; nothing replaced
local labelSaved
local function ShowLabel(title, show)
    if not title then return end
    if not show then
        if not labelSaved then
            local okM, m = pcall(function() return title.IsMouseEnabled and title:IsMouseEnabled() end)
            labelSaved = { alpha = title:GetAlpha() or 1, mouse = okM and m }
        end
        pcall(title.SetAlpha, title, 0)
        if title.EnableMouse then pcall(title.EnableMouse, title, false) end
    elseif labelSaved then
        pcall(title.SetAlpha, title, labelSaved.alpha or 1)
        if labelSaved.mouse and title.EnableMouse then pcall(title.EnableMouse, title, true) end
        labelSaved = nil
    end
end

local function PlayerOnTop()
    if DB and DB.playerTop ~= nil then return DB.playerTop end
    return PLAYER_ON_TOP
end

local function Members()
    local list = {}
    for i = 1, 5 do
        local f = _G["CompactPartyFrameMember" .. i]
        if f and f.IsShown and f:IsShown() then list[#list + 1] = f end
    end
    return list
end

local Apply
local function Queue()
    if pending then return end
    pending = true
    C_Timer.After(0, function() pending = false; Apply() end)
end

local function Hook(f)
    if hooked[f] then return end
    hooked[f] = true
    hooksecurefunc(f, "SetPoint", function() if not moving then ours[f] = nil; Queue() end end)
    if f.HookScript then f:HookScript("OnShow", Queue); f:HookScript("OnHide", Queue) end
end

local function Horizontal(m1, m2)
    if not m2 or ours[m2] then return false end
    local p, rel, rp = m2:GetPoint(1)
    return rel == m1 and type(p) == "string" and type(rp) == "string"
        and p:find("LEFT") ~= nil and rp:find("RIGHT") ~= nil
end

local function Restore()
    -- give the frames back to Blizzard: ask it to lay them out again
    for f in pairs(ours) do ours[f] = nil end
    if CompactPartyFrame_RefreshMembers then pcall(CompactPartyFrame_RefreshMembers) end
    if CompactPartyFrame and CompactPartyFrame.Layout then pcall(CompactPartyFrame.Layout, CompactPartyFrame) end
end

Apply = function()
    if InCombatLockdown and InCombatLockdown() then return end
    for i = 1, 5 do local f = _G["CompactPartyFrameMember" .. i]; if f then Hook(f) end end
    local title = Title()
    if title then Hook(title); ShowLabel(title, not LabelHidden()) end
    if not DB or DB.off then return end
    local m = Members()
    if #m == 0 then return end
    local m1 = m[1]
    if not ours[m1] then
        local p, rel, rp, x, y = m1:GetPoint(1)
        if p and p:find("TOP") then base = { rel, rp, x or 0, y or 0, (p:gsub("TOP", "BOTTOM")) } end
    end
    if not base or Horizontal(m1, m[2]) then return end
    local h = m1:GetHeight() or 0
    if h <= 0 then return end
    -- order top to bottom: you (if kept on top), then by role, then Blizzard's order
    if #m > 1 and (PlayerOnTop() or SortOn()) then
        local pos, key = {}, {}
        for i, f in ipairs(m) do
            pos[f] = i
            local r = SortOn() and RankOf(f) or 0
            if PlayerOnTop() and IsMe(f) then r = -1 end
            key[f] = r
        end
        local topDown = {}
        for i, f in ipairs(m) do topDown[i] = f end
        table.sort(topDown, function(a, b)
            if key[a] ~= key[b] then return key[a] < key[b] end
            return pos[a] < pos[b]
        end)
        if not PlayerOnTop() and SortOn() then
            -- you asked to sit at the bottom: you go last
            for i, f in ipairs(topDown) do if IsMe(f) then table.remove(topDown, i); topDown[#topDown + 1] = f; break end end
        end
        m = {}
        for i = #topDown, 1, -1 do m[#m + 1] = topDown[i] end   -- stack is built bottom first
    end
    local bottomFrame = m[1]
    local rel, rp, x, y, bp = base[1], base[2], base[3], base[4], base[5]

    -- the label can move only if the first frame hangs off it and it doesn't
    -- hang off a member frame itself (that would be a loop)
    local moveTitle = false
    if title and rel == title then
        if not ours[title] then
            local tp, trel, trp, tx, ty = title:GetPoint(1)
            local loops = false
            for i = 1, 5 do if trel == _G["CompactPartyFrameMember" .. i] then loops = true end end
            if tp and tp:find("TOP") and trel and not loops then tbase = { trel, trp, tx or 0, ty or 0 } end
        end
        moveTitle = tbase ~= nil
    end

    moving = true
    pcall(function()
        local m1 = bottomFrame
        m1:ClearAllPoints()
        if moveTitle then
            -- label's bottom goes where the full stack used to end; frames sit on top of it
            local th = title:GetHeight() or 0
            local bottom = tbase[4] - th + y - SLOTS * (h + GAP) + GAP
            title:ClearAllPoints()
            title:SetPoint("BOTTOMLEFT", tbase[1], tbase[2], tbase[3], bottom)
            ours[title] = true
            m1:SetPoint("BOTTOMLEFT", title, "TOPLEFT", x, -y)
        elseif title and rel ~= title then
            -- live client: frames hang off the party frame itself, so the label
            -- can simply sit under the bottom frame; lift the stack by the label's
            -- height so the label lands where a full party used to end
            local th = LabelHidden() and 0 or ((title:GetHeight() or 0) + 2)
            m1:SetPoint(bp, rel, rp, x, y - SLOTS * (h + GAP) + GAP + th)
            title:ClearAllPoints()
            title:SetPoint("TOPLEFT", m1, "BOTTOMLEFT", 0, -2)
            ours[title] = true
        else
            m1:SetPoint(bp, rel, rp, x, y - SLOTS * (h + GAP) + GAP)
        end
        ours[m1] = true
        for i = 2, #m do
            m[i]:ClearAllPoints()
            m[i]:SetPoint("BOTTOMLEFT", m[i - 1], "TOPLEFT", 0, GAP)
            ours[m[i]] = true
        end
    end)
    moving = false
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("GROUP_ROSTER_UPDATE")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then DB = ns.Section("layout") end
        if arg1 ~= "Blizzard_CompactRaidFrames" and arg1 ~= ADDON then return end
    end
    Queue()
end)
-- fallback: catch any layout we missed, out of combat only
C_Timer.NewTicker(2, function() if not (InCombatLockdown and InCombatLockdown()) then Apply() end end)

ns.LayoutCmd = function(msg)
    if not DB then return end
    if (msg or ""):lower():find("debug") then
        Say("CompactPartyFrame: " .. (CompactPartyFrame and (CompactPartyFrame:IsShown() and "shown" or "hidden") or "not found"))
        local m = Members()
        Say(("%d member frames shown; %s; you on %s"):format(#m, DB.off and "turned off" or "on", PlayerOnTop() and "top" or "bottom"))
        if m[1] then
            local p, rel, rp, x, y = m[1]:GetPoint(1)
            Say(("first frame: %s to %s %s (%.0f, %.0f)%s"):format(tostring(p),
                rel and rel.GetName and (rel:GetName() or "?") or tostring(rel), tostring(rp), x or 0, y or 0,
                ours[m[1]] and " [moved by PFI]" or ""))
            if Horizontal(m[1], m[2]) then Say("frames are side by side (horizontal), so left alone") end
        end
        local t = Title()
        Say("Party label: " .. (t and ((t.GetName and t:GetName()) or "found") .. (ours[t] and " [moved to bottom]" or "") .. (LabelHidden() and " [hidden]" or "") or "not found"))
        if SortOn() then
            local parts = {}
            for _, f in ipairs(m) do
                local u = f.displayedUnit or f.unit
                local okN, n = pcall(UnitName, u)
                parts[#parts + 1] = ((okN and type(n) == "string") and n or tostring(u)) .. "=" .. tostring(ClassOf(f))
            end
            Say("order by class: " .. table.concat(parts, ", "))
        end
        if InCombatLockdown and InCombatLockdown() then Say("in combat: waiting") end
        return
    end
    if InCombatLockdown and InCombatLockdown() then Say("can't change that in combat"); return end
    if (msg or ""):lower():find("sort") then
        DB.sort = not SortOn()
        Apply()
        Say(DB.sort and "sorted: you, then by class" or "class sort off (Blizzard's order)")
        return
    end
    if (msg or ""):lower():find("label") then
        DB.hideLabel = not DB.hideLabel
        Apply()
        Say(DB.hideLabel and "Party label hidden" or "Party label shown")
        return
    end
    if (msg or ""):lower():find("top") then
        DB.playerTop = not PlayerOnTop()
        Apply()
        Say(DB.playerTop and "your frame stays at the top" or "your frame sits at the bottom")
        return
    end
    DB.off = not DB.off
    if DB.off then Restore(); Say("layout off: Blizzard's top-down order") else Apply(); Say("layout on: bottom-up") end
end
