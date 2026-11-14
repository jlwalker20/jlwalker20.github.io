-- PartyFramesImproved: Icons
-- On each raid-style party/raid frame:
--   * a leader crown on the group leader
--   * your group's raid target marker (skull, star, ...) on that member
--   * a PvP flag at the far left when the member is flagged
--   * Blizzard's role icon hidden (opacity only; nothing replaced)
-- The crown, marker and flag are our own textures in our own frame laid over
-- Blizzard's, made out of combat.

local ADDON, ns = ...

local CONFIG = {
    -- spots are on the HEALTH BAR (corner, x, y)
    LEADER       = true,  LEADER_SIZE = 12, LEADER_POINT = { "LEFT", 3, 0 },
    MARKER       = true,  MARKER_SIZE = 16, MARKER_POINT = { "RIGHT", -2, 0 },
    -- the PvP flag goes where Blizzard's role icon sits (top-left of the health bar)
    PVP          = true,  PVP_SIZE = 16, PVP_POINT = { "TOPLEFT", 2, -2 },
    PVP_ALWAYS   = true,  -- always show the faction icon: gray when not flagged, full color when flagged
    PVP_GRAY_ALPHA = 0.6,
    -- what sits at the top-left of the health bar, before the name:
    --   "pvp"  = the faction / PvP icon (Blizzard's role icon hidden)
    --   "role" = Blizzard's role icon (no faction icon)
    --   "none" = nothing: the name moves flush left
    LEFT_SLOT    = "pvp",
    NAME_PAD     = 3,     -- left padding for the name in "none" (pixels)

}

local DB
local function Say(m) print("|cff9999ffPFI:|r " .. m) end
local function Secret(v) return issecretvalue and issecretvalue(v) end
local function InCombat() return InCombatLockdown and InCombatLockdown() end
local function UnitOf(f) local u = f.displayedUnit or f.unit; if type(u) == "string" and not Secret(u) then return u end end

-- ---------------------------------------------------------------- our overlay
local overlays = {}
local STRATA = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG" }

local function MakeOverlay(f)
    local o = CreateFrame("Frame", nil, UIParent)
    o:SetAllPoints(f)
    local hb = rawget(f, "healthBar")
    if not (type(hb) == "table" and hb.GetWidth and not (hb.IsForbidden and hb:IsForbidden())) then hb = o end
    local function Place(tex, pt)
        tex:ClearAllPoints()
        if not pcall(tex.SetPoint, tex, pt[1], hb, pt[1], pt[2], pt[3]) then tex:SetPoint(pt[1], o, pt[1], pt[2], pt[3]) end
    end
    local okS, st = pcall(f.GetFrameStrata, f)
    local want = "MEDIUM"
    if okS then for i, n in ipairs(STRATA) do if n == st then want = STRATA[math.min(i + 1, #STRATA)] end end end
    o:SetFrameStrata(want)

    o.leader = o:CreateTexture(nil, "OVERLAY")
    o.leader:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    o.leader:SetSize(CONFIG.LEADER_SIZE, CONFIG.LEADER_SIZE)
    Place(o.leader, CONFIG.LEADER_POINT)
    o.leader:Hide()

    o.marker = o:CreateTexture(nil, "OVERLAY")
    o.marker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    o.marker:SetSize(CONFIG.MARKER_SIZE, CONFIG.MARKER_SIZE)
    Place(o.marker, CONFIG.MARKER_POINT)
    o.marker:Hide()

    o.pvp = o:CreateTexture(nil, "OVERLAY")
    o.pvp:SetSize(CONFIG.PVP_SIZE, CONFIG.PVP_SIZE)
    Place(o.pvp, CONFIG.PVP_POINT)
    o.pvp:Hide()
    return o
end

-- the same faction art the player frame uses (the icon without the shield
-- background), found by atlas name; falls back to the classic flag file
local function AtlasExists(name)
    if not (C_Texture and C_Texture.GetAtlasInfo) then return false end
    local ok, info = pcall(C_Texture.GetAtlasInfo, name)
    return ok and info ~= nil
end

local ART = {
    Horde    = { "UI-HUD-UnitFrame-SmallCircle-Horde", "ui-hud-unitframe-player-pvp-hordeicon", "UI-HUD-UnitFrame-Player-PVP-HordeIcon" },
    Alliance = { "UI-HUD-UnitFrame-SmallCircle-Alliance", "ui-hud-unitframe-player-pvp-allianceicon", "UI-HUD-UnitFrame-Player-PVP-AllianceIcon" },
    FFA      = { "ui-hud-unitframe-player-pvp-ffaicon", "UI-HUD-UnitFrame-Player-PVP-FFAIcon" },
}
local artCache, artNote = {}, {}

-- the player frame's own flag: search the player frame for the PvP art it is
-- showing right now and copy exactly that (atlas, or file + crop)
local function LooksPvP(r)
    local okA, a = pcall(function() return r.GetAtlas and r:GetAtlas() end)
    a = (okA and type(a) == "string" and not Secret(a)) and a:lower() or ""
    local okN, n = pcall(function() return r.GetName and r:GetName() end)
    n = (okN and type(n) == "string") and n:lower() or ""
    local okT, t = pcall(function() return r.GetTexture and r:GetTexture() end)
    t = (okT and type(t) == "string" and not Secret(t)) and t:lower() or ""
    return a:find("pvp", 1, true) or a:find("horde", 1, true) or a:find("alliance", 1, true) or a:find("prestige", 1, true)
        or n:find("pvp", 1, true) or t:find("pvp", 1, true)
end

local function FindPlayerArt()
    if not PlayerFrame then return end
    local best
    local function scan(fr, depth)
        if best or depth > 5 then return end
        local okR, regions = pcall(function() return { fr:GetRegions() } end)
        if okR then
            for _, r in ipairs(regions) do
                if r.GetObjectType and select(2, pcall(r.GetObjectType, r)) == "Texture" and LooksPvP(r) then
                    local okS, shown = pcall(r.IsShown, r)
                    if okS and shown == true then best = r; return end
                end
            end
        end
        local okC, kids = pcall(function() return { fr:GetChildren() } end)
        if okC then for _, c in ipairs(kids) do if type(c) == "table" then scan(c, depth + 1) end end end
    end
    pcall(scan, PlayerFrame, 0)
    if not best then return end
    local okA, atlas = pcall(best.GetAtlas, best)
    if okA and type(atlas) == "string" and not Secret(atlas) and atlas ~= "" then return { atlas = atlas } end
    local okT, file = pcall(best.GetTexture, best)
    if okT and file ~= nil and not Secret(file) then
        -- GetTexCoord gives ULx,ULy,LLx,LLy,URx,URy,LRx,LRy; SetTexCoord wants left,right,top,bottom
        local c = { pcall(best.GetTexCoord, best) }
        local tc
        if c[1] == true and type(c[2]) == "number" and not Secret(c[2]) then tc = { c[2], c[8], c[3], c[9] } end
        return { file = file, coords = tc }
    end
end

local playerArt, nextLook = nil, 0
local function SetFactionArt(t, key)
    -- your own faction: copy the player frame's art when it is showing
    local okG, mine = pcall(UnitFactionGroup, "player")
    if okG and not Secret(mine) and mine == key then
        if not playerArt and GetTime() >= nextLook then
            playerArt = FindPlayerArt(); nextLook = GetTime() + 5
            if playerArt then
                artNote[key] = "copied from player frame: " .. (playerArt.atlas or tostring(playerArt.file))
                -- remember it for good, so it's there from login even when you're not flagged
                if DB then DB.art = DB.art or {}; DB.art[key] = playerArt end
            end
        end
        if playerArt then
            if playerArt.atlas and pcall(t.SetAtlas, t, playerArt.atlas) then return true end
            if playerArt.file then
                t:SetTexture(playerArt.file)
                if playerArt.coords then t:SetTexCoord((unpack or table.unpack)(playerArt.coords)) else t:SetTexCoord(0, 1, 0, 1) end
                return true
            end
        end
    end
    if artCache[key] == nil then
        local a
        for _, n in ipairs(ART[key] or {}) do if AtlasExists(n) then a = n; break end end
        artCache[key] = a or false
        artNote[key] = artNote[key] or (a and ("atlas " .. a) or "classic flag file (no atlas found)")
    end
    local a = artCache[key]
    if a and pcall(t.SetAtlas, t, a) then return false end
    t:SetTexture("Interface\\TargetingFrame\\UI-PVP-" .. key)
    t:SetTexCoord(0.05, 0.6, 0.02, 0.6)   -- the flag art fills only the top-left of its file
    return false
end

-- returns art key, flagged
local function PvPState(unit)
    local okF, ffa = pcall(UnitIsPVPFreeForAll, unit)
    if okF and not Secret(ffa) and ffa == true then return "FFA", true end
    local okP, pvp = pcall(UnitIsPVP, unit)
    local flagged = okP and not Secret(pvp) and pvp == true
    local okG, faction = pcall(UnitFactionGroup, unit)
    if okG and not Secret(faction) and (faction == "Horde" or faction == "Alliance") then return faction, flagged end
end

local function MarkerTex(t, idx)
    if SetRaidTargetIconTexture then SetRaidTargetIconTexture(t, idx); return end
    local c = (idx - 1) % 4; local r = math.floor((idx - 1) / 4)
    t:SetTexCoord(c * 0.25, (c + 1) * 0.25, r * 0.25, (r + 1) * 0.25)
end

local roleHidden = {}
local roleErr

local function Slot()
    local v = DB and DB.slot
    if v == "pvp" or v == "role" or v == "none" then return v end
    return CONFIG.LEFT_SLOT
end

-- the name: flush left in "none"; given back to Blizzard otherwise
local nameMoved, nameHooked, nameBusy, nameSaved = {}, {}, false, {}
local function PlaceName(f)
    local n = rawget(f, "name")
    local hb = rawget(f, "healthBar")
    if type(n) ~= "table" or not n.SetPoint or (n.IsForbidden and n:IsForbidden()) then return end
    if type(hb) ~= "table" then hb = f end
    if Slot() == "none" then
        if InCombat() then return end
        if not nameHooked[n] then
            nameHooked[n] = true
            -- Blizzard re-places the name when roles change; put it back right after
            hooksecurefunc(n, "SetPoint", function()
                if nameBusy then return end
                if nameMoved[n] and Slot() == "none" and not InCombat() then
                    C_Timer.After(0, function() PlaceName(f) end)
                elseif not nameMoved[n] then
                    nameSaved[n] = nil   -- Blizzard chose a new spot; re-read it next time
                end
            end)
        end
        -- remember Blizzard's own spot for the name, the first time only
        if nameSaved[n] == nil and not nameMoved[n] then
            local list, ok = {}, true
            local okN, cnt = pcall(n.GetNumPoints, n)
            if okN and type(cnt) == "number" and not Secret(cnt) then
                for i = 1, cnt do
                    local okP, p, rel, rp, x, y = pcall(n.GetPoint, n, i)
                    if not okP or Secret(p) or Secret(rel) or Secret(rp) or Secret(x) or Secret(y) then ok = false; break end
                    list[#list + 1] = { p, rel, rp, x or 0, y or 0 }
                end
            else ok = false end
            nameSaved[n] = ok and list or false
        end
        nameBusy = true
        pcall(function()
            n:ClearAllPoints()
            n:SetPoint("TOPLEFT", hb, "TOPLEFT", CONFIG.NAME_PAD, -2)
            n:SetPoint("TOPRIGHT", hb, "TOPRIGHT", -3, -2)
        end)
        nameBusy = false
        nameMoved[n] = true
    elseif nameMoved[n] then
        if InCombat() then return end
        nameMoved[n] = nil
        -- put the name back exactly where Blizzard had it (saved before we moved it)
        local saved = nameSaved[n]
        nameBusy = true
        pcall(function()
            n:ClearAllPoints()
            if type(saved) == "table" and #saved > 0 then
                for _, pt in ipairs(saved) do n:SetPoint(pt[1], pt[2], pt[3], pt[4], pt[5]) end
            else
                local r = rawget(f, "roleIcon")
                n:SetPoint("TOPLEFT", r or hb, r and "TOPRIGHT" or "TOPLEFT", r and 0 or 16, -1)
                n:SetPoint("TOPRIGHT", hb, "TOPRIGHT", -3, -2)
            end
        end)
        nameBusy = false
    end
end

local function HideRole(f, hide)
    local r = rawget(f, "roleIcon")
    if type(r) ~= "table" or not r.SetAlpha then return end
    if r.IsForbidden and r:IsForbidden() then return end
    if hide then
        -- its alpha reads back as a hidden (secret) value, so don't compare it; just set it
        local ok = pcall(r.SetAlpha, r, 0)
        roleHidden[r] = ok and true or "failed"
    elseif roleHidden[r] then
        pcall(r.SetAlpha, r, 1); roleHidden[r] = nil
    end
end

local function UpdateFrame(f)
    if f.IsForbidden and f:IsForbidden() then return end
    local o = overlays[f]
    if not o then
        if InCombat() then return end
        o = MakeOverlay(f); overlays[f] = o
    end
    local okR, errR = pcall(HideRole, f, Slot() ~= "role")
    if not okR then roleErr = tostring(errR) end
    pcall(PlaceName, f)
    local unit = UnitOf(f)
    local on = unit and f.IsVisible and f:IsVisible() and not (DB and DB.off)
    -- leader
    local lead = false
    if on and CONFIG.LEADER and UnitIsGroupLeader then
        local ok, v = pcall(UnitIsGroupLeader, unit); lead = ok and not Secret(v) and v == true
    end
    if lead then o.leader:Show() else o.leader:Hide() end
    -- raid target marker
    local shown, note = false, "none"
    if on and CONFIG.MARKER and GetRaidTargetIndex then
        local ok, v = pcall(GetRaidTargetIndex, unit)
        if not ok then note = "error"
        elseif Secret(v) then
            -- the game hides which marker it is; hand it straight to the icon
            -- setter (no comparing), which can still draw it
            if SetRaidTargetIconTexture and pcall(SetRaidTargetIconTexture, o.marker, v) then shown = true; note = "hidden number, drawn"
            else note = "hidden number, can't draw" end
        elseif type(v) == "number" and v >= 1 and v <= 8 then
            MarkerTex(o.marker, v); shown = true; note = tostring(v)
        end
    end
    o.markerNote = note
    if shown then o.marker:Show() else o.marker:Hide() end
    -- pvp flag
    local key, flagged
    if on and CONFIG.PVP and Slot() == "pvp" then key, flagged = PvPState(unit) end
    if key and (flagged or CONFIG.PVP_ALWAYS) then
        if o.pvpKey ~= key or not o.pvpCopied then o.pvpCopied = SetFactionArt(o.pvp, key); o.pvpKey = key end
        if flagged then
            o.pvp:SetDesaturated(false); o.pvp:SetVertexColor(1, 1, 1); o.pvp:SetAlpha(1)
        else
            o.pvp:SetDesaturated(true); o.pvp:SetVertexColor(0.8, 0.8, 0.8); o.pvp:SetAlpha(CONFIG.PVP_GRAY_ALPHA)
        end
        o.pvp:Show()
        o.pvpFlagged = flagged
    else o.pvp:Hide(); o.pvpFlagged = nil end
end

local lastErr
local function UpdateAll()
    if not ns.Frames then lastErr = "frame list missing"; return end
    for _, f in ipairs(ns.Frames()) do
        local ok, err = pcall(UpdateFrame, f)
        if not ok then lastErr = tostring(err) end
    end
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "PARTY_LEADER_CHANGED",
                     "RAID_TARGET_UPDATE", "UNIT_FACTION", "PLAYER_FLAGS_CHANGED", "PLAYER_REGEN_ENABLED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then
            DB = ns.Section("icons")
            local okG, mine = pcall(UnitFactionGroup, "player")
            if DB.art and okG and type(mine) == "string" and not Secret(mine) and DB.art[mine] then
                playerArt = DB.art[mine]
                artNote[mine] = "saved from player frame: " .. (playerArt.atlas or tostring(playerArt.file))
            end
        end
        return
    end
    UpdateAll()
end)
C_Timer.NewTicker(0.5, UpdateAll)

ns.IconsCmd = function(msg)
    if not DB then return end
    if msg == "debug" then
        local n = 0
        for f, o in pairs(overlays) do
            local unit = UnitOf(f)
            if unit and f:IsVisible() then
                n = n + 1
                local r = rawget(f, "roleIcon")
                Say(("icons %s: leader %s, marker %s, pvp %s, role icon %s"):format(unit,
                    o.leader:IsShown() and "yes" or "no", (o.marker:IsShown() and "yes" or "no") .. " (" .. tostring(o.markerNote) .. ")",
                    (o.pvp:IsShown() and (o.pvpFlagged and "flagged" or "gray")) or "no",
                    (type(r) ~= "table" and "not found") or ((r.IsForbidden and r:IsForbidden()) and "locked") or ((roleHidden[r] == "failed" and "can't be changed") or (roleHidden[r] and "hidden") or "shown")))
            end
        end
        Say("  top-left of the bar: " .. Slot())
        Say(("icons: %d frames%s; APIs: leader %s, pvp %s, marker %s"):format(n, DB.off and ", turned OFF" or "",
            type(UnitIsGroupLeader) == "function" and "yes" or "NO", type(UnitIsPVP) == "function" and "yes" or "NO",
            type(GetRaidTargetIndex) == "function" and "yes" or "NO"))
        local f1 = CompactPartyFrameMember1
        if f1 then
            local keys = {}
            for k, v in pairs(f1) do
                if type(k) == "string" and (k:lower():find("role") or k:lower():find("leader") or k:lower():find("pvp")) then
                    local okT, t = pcall(function() return v.GetObjectType and v:GetObjectType() end)
                    keys[#keys + 1] = k .. "=" .. (okT and tostring(t) or "locked")
                end
            end
            Say("  frame parts with role/leader/pvp in the name: " .. (#keys > 0 and table.concat(keys, ", ") or "none"))
        end
        for k, v in pairs(artNote) do Say(("  %s art: %s"):format(k, v)) end
        if lastErr then Say("  last error: " .. lastErr) end
        if roleErr then Say("  role icon error: " .. roleErr) end
        return
    end
    local SLOT_TEXT = { pvp = "faction / PvP icon", role = "Blizzard's role icon", none = "nothing (name flush left)" }
    if msg == "pvp" or msg == "role" or msg == "none" or msg == "slot" then
        if InCombat() then Say("can't change that in combat"); return end
        if msg == "slot" then
            local nxt = { pvp = "role", role = "none", none = "pvp" }
            DB.slot = nxt[Slot()]
        else DB.slot = msg end
        UpdateAll()
        Say("top-left of the bar: " .. SLOT_TEXT[Slot()])
        return
    end
    if msg == "resetart" then
        DB.art = nil; playerArt = nil; nextLook = 0
        for f, o in pairs(overlays) do o.pvpCopied = nil end
        Say("saved PvP art forgotten; it is copied again next time you're flagged")
        return
    end
    DB.off = not DB.off; UpdateAll()
    Say(DB.off and "icons off" or "icons on")
end
