-- PartyFramesImproved: Raid layout
-- Lays out Blizzard's raid frames from the BOTTOM-RIGHT corner toward the top
-- left, using the same order as the party frames (you, then class order).
--
-- The order is built like the party stack: the list is read bottom-first, so
-- one column of 5 looks exactly like your party frames. Columns fill upward
-- and new columns are added to the left (GROW = "UP"), or rows fill leftward
-- and new rows are added above (GROW = "LEFT").
--
-- "Keep Groups Together" OFF: one shared list of raid frames, laid out as a grid.
-- "Keep Groups Together" ON: each group is a column (group 1 at the right,
-- the next to its left), and inside each group the members stack upward in
-- the same order, with the group's label at the bottom like the party label.
-- Frames are protected, so they are only moved OUT of combat.

local ADDON, ns = ...

local CONFIG = {
    GROW     = "UP",   -- "UP": columns fill upward, new columns to the left
                       -- "LEFT": rows fill leftward, new rows above
    PER_LINE = 5,      -- frames per column (UP) or per row (LEFT)
    GAP_X    = 2,      -- space between columns, pixels
    GAP_Y    = 0,      -- space between rows, pixels
    -- the corner everything grows from: the bottom-right of a FULL 40-person
    -- raid placed where Blizzard's raid frames start (the Edit Mode box).
    -- Blizzard shrinks its own raid area to fit the groups you have, so its
    -- corner can't be used. FULL_COLUMNS = how many columns that full raid has.
    FULL_COLUMNS = 8,
    ANCHOR_X = 0, ANCHOR_Y = 0,   -- nudge the corner (pixels; + is right / up)
}

local DB
local function Say(m) print("|cff9999ffPFI:|r " .. m) end
local function InCombat() return InCombatLockdown and InCombatLockdown() end

local ours, hooked = {}, {}
local moving, pending = false, false
local note = "not run yet"

local function Container() return _G.CompactRaidFrameContainer end

local function FlowFrames()
    local list = {}
    for i = 1, 40 do
        local f = _G["CompactRaidFrame" .. i]
        if f and f.IsShown and f:IsShown() and not (f.IsForbidden and f:IsForbidden()) then
            local u = f.displayedUnit or f.unit
            if type(u) == "string" then list[#list + 1] = f end
        end
    end
    return list
end

local function ShownGroups()
    local list = {}
    for g = 1, 8 do
        local gf = _G["CompactRaidGroup" .. g]
        if gf and gf.IsShown and gf:IsShown() and not (gf.IsForbidden and gf:IsForbidden()) then list[#list + 1] = { gf = gf, n = g } end
    end
    return list
end
local function GroupsMode() return #ShownGroups() > 0 end

local function GroupMembers(g)
    local list = {}
    for m = 1, 5 do
        local f = _G["CompactRaidGroup" .. g .. "Member" .. m]
        if f and f.IsShown and f:IsShown() and not (f.IsForbidden and f:IsForbidden()) then
            local u = f.displayedUnit or f.unit
            if type(u) == "string" then list[#list + 1] = f end
        end
    end
    return list
end

local function GroupTitle(gf, g)
    local t = rawget(gf, "title") or _G["CompactRaidGroup" .. g .. "Title"]
    if type(t) == "table" and t.SetPoint and not (t.IsForbidden and t:IsForbidden()) then return t end
end

-- offsets from the container's top-left to the fixed bottom-right corner
local cornerNote = ""
local function Corner(colW, fullH)
    local x = CONFIG.FULL_COLUMNS * colW + CONFIG.ANCHOR_X
    local y = -fullH + CONFIG.ANCHOR_Y
    cornerNote = ("corner %.0f right, %.0f down from where the raid frames start"):format(x, -y)
    return x, y
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

local function Restore()
    for f in pairs(ours) do ours[f] = nil end
    local c = Container()
    if c then
        for _, fn in ipairs({ "TryUpdate", "Layout", "UpdateLayout" }) do
            if type(c[fn]) == "function" then pcall(c[fn], c) end
        end
    end
end

Apply = function()
    if InCombat() then note = "in combat: waiting"; return end
    for i = 1, 40 do local f = _G["CompactRaidFrame" .. i]; if f then Hook(f) end end
    for g = 1, 8 do
        local gf = _G["CompactRaidGroup" .. g]
        if gf then
            Hook(gf)
            local t = GroupTitle(gf, g); if t then Hook(t) end
            for m = 1, 5 do local f = _G["CompactRaidGroup" .. g .. "Member" .. m]; if f then Hook(f) end end
        end
    end
    if not DB or DB.off then note = "turned off"; return end
    if not (IsInRaid and IsInRaid()) then note = "not in a raid"; return end
    local c = Container()
    if not c then note = "raid container not found"; return end
    local m = FlowFrames()
    if #m == 0 then
        if GroupsMode() then return ns.ApplyGroups(c) end
        note = "no raid frames shown"
        return
    end
    local w, h = m[1]:GetWidth() or 0, m[1]:GetHeight() or 0
    if w <= 0 or h <= 0 then note = "frame size not ready"; return end

    -- bottom-first order: reverse of the party top-to-bottom order
    local topDown = ns.OrderTopDown and ns.OrderTopDown(m) or m
    local order = {}
    for i = #topDown, 1, -1 do order[#order + 1] = topDown[i] end

    local per = math.max(1, CONFIG.PER_LINE)
    local colW, rowH = w + CONFIG.GAP_X, h + CONFIG.GAP_Y
    local rows = (CONFIG.GROW == "LEFT") and math.ceil(40 / per) or per
    local cx, cy = Corner(colW, rows * rowH)
    if CONFIG.GROW == "LEFT" then cx = per * colW + CONFIG.ANCHOR_X end
    moving = true
    pcall(function()
        for i, f in ipairs(order) do
            local k = i - 1
            local col, row
            if CONFIG.GROW == "LEFT" then col, row = k % per, math.floor(k / per)
            else row, col = k % per, math.floor(k / per) end
            f:ClearAllPoints()
            f:SetPoint("BOTTOMRIGHT", c, "TOPLEFT", cx - col * colW, cy + row * rowH)
            ours[f] = true
        end
    end)
    moving = false
    note = ("%d frames laid out from the bottom-right (%s)"):format(#order, CONFIG.GROW == "LEFT" and "rows leftward" or "columns upward")
end

-- "Keep Groups Together" on: groups as columns from the right, members sorted inside
function ns.ApplyGroups(c)
    local groups = ShownGroups()
    local count, sorted = 0, 0
    moving = true
    pcall(function()
        local first = groups[1] and groups[1].gf
        local gw0 = first and first:GetWidth() or 0
        -- full group height = label + 5 members (groups may shrink to their members)
        local mh, th = 0, 0
        for _, e in ipairs(groups) do
            local mm = GroupMembers(e.n)[1]
            if mm then mh = math.max(mh, mm:GetHeight() or 0) end
            local t = GroupTitle(e.gf, e.n)
            if t then th = math.max(th, (t:GetHeight() or 0) + 2) end
        end
        local gh0 = th + 5 * (mh + CONFIG.GAP_Y)
        if gh0 <= 0 and first then gh0 = first:GetHeight() or 0 end
        local cx, cy = Corner(gw0 + CONFIG.GAP_X, gh0)
        for k, e in ipairs(groups) do
            local gf, g = e.gf, e.n
            local gw = gf:GetWidth() or 0
            gf:ClearAllPoints()
            gf:SetPoint("BOTTOMRIGHT", c, "TOPLEFT", cx - (k - 1) * (gw + CONFIG.GAP_X), cy)
            ours[gf] = true
            local mem = GroupMembers(g)
            if #mem > 0 then
                local topDown = ns.OrderTopDown and ns.OrderTopDown(mem) or mem
                local title = GroupTitle(gf, g)
                local below = gf          -- what the bottom member sits on
                local bp, rp, gap = "BOTTOMLEFT", "BOTTOMLEFT", 0
                if title then
                    title:ClearAllPoints()
                    title:SetPoint("BOTTOMLEFT", gf, "BOTTOMLEFT", 0, 0)
                    ours[title] = true
                    below, rp, gap = title, "TOPLEFT", 2
                end
                for i = #topDown, 1, -1 do
                    local f = topDown[i]
                    f:ClearAllPoints()
                    f:SetPoint(bp, below, rp, 0, gap)
                    ours[f] = true
                    below, rp, gap = f, "TOPLEFT", CONFIG.GAP_Y
                    count = count + 1
                end
                sorted = sorted + 1
            end
        end
    end)
    moving = false
    note = ("groups mode: %d groups as columns from the right, %d members sorted"):format(sorted, count)
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "PLAYER_REGEN_ENABLED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then DB = ns.Section("raid") end
        if arg1 ~= ADDON and arg1 ~= "Blizzard_CompactRaidFrames" then return end
    end
    Queue()
end)
C_Timer.NewTicker(2, function() if not InCombat() then Apply() end end)

ns.RaidCmd = function(msg)
    if not DB then return end
    if msg == "debug" then
        local c = Container()
        local cw, ch = 0, 0
        if c then cw, ch = c:GetWidth() or 0, c:GetHeight() or 0 end
        local pt, prel, prp = nil, nil, nil
        if c then pt, prel, prp = c:GetPoint(1) end
        Say(("raid: %s; container %s (%.0f x %.0f, held by its %s); %s"):format(note, c and "found" or "not found", cw, ch,
            tostring(pt), cornerNote))
        if IsInRaid and IsInRaid() then
            local parts = {}
            for _, f in ipairs(ns.OrderTopDown and ns.OrderTopDown(FlowFrames()) or FlowFrames()) do
                local u = f.displayedUnit or f.unit
                local okN, n = pcall(UnitName, u)
                parts[#parts + 1] = ((okN and type(n) == "string") and n or tostring(u)) .. "=" .. tostring(ns.ClassOf and ns.ClassOf(f))
                if #parts >= 12 then parts[#parts + 1] = "..."; break end
            end
            if #parts > 0 then Say("  raid order (top of the list first): " .. table.concat(parts, ", ")) end
        end
        return
    end
    if InCombat() then Say("can't change that in combat"); return end
    DB.off = not DB.off
    if DB.off then Restore(); Say("raid layout off: Blizzard's layout (/reload if it doesn't snap back)")
    else Apply(); Say("raid layout on: grows from the bottom-right") end
end
