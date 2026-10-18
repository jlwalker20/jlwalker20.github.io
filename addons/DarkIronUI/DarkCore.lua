-- DarkCore: shared engine for the DarkIronUI recolor addons (DarkIronUI_Minimap,
-- DarkIronUI_Tracker, DarkIronUI_Tooltip and the DarkIronUI compilation).
--
-- Same look as FlatUnitFrames' "dark" style: Blizzard's own art keeps its
-- detail and is greyed, then dimmed, from gold/brown to dark grey.
--
-- Safety (same rules as FlatUnitFrames / GamepadDarkMode): only the COLOR of
-- artwork is changed. No Blizzard frame or button is changed, nothing of
-- Blizzard's is hooked, searches run only out of combat, and a once-a-second
-- re-check puts the look back if the game repaints something.

local ADDON, NS = ...

local function IsSecret(v) return issecretvalue and issecretvalue(v) end

local function SafeName(o)
    local ok, n = pcall(function() return o.GetName and o:GetName() end)
    return ok and type(n) == "string" and n or nil
end

local function Kind(o)
    local ok, t = pcall(function() return o.GetObjectType and o:GetObjectType() end)
    return ok and t or nil
end

local function AtlasOf(r)
    local ok, a = pcall(function() return r.GetAtlas and r:GetAtlas() end)
    return ok and type(a) == "string" and a or nil
end

local function has(s, list)
    if type(s) ~= "string" or not list then return false end
    s = s:lower()
    for _, p in ipairs(list) do
        if s:find(p:lower(), 1, true) then return true end
    end
    return false
end

-- "A.B.C" -> _G.A.B.C ; functions are called
local function Resolve(root)
    if type(root) == "function" then
        local ok, f = pcall(root)
        return ok and f or nil
    end
    if type(root) ~= "string" then return nil end
    local cur
    for part in root:gmatch("[^%.]+") do
        if cur == nil then cur = _G[part] else cur = type(cur) == "table" and rawget(cur, part) or nil end
        if cur == nil then return nil end
    end
    return cur
end

local function IconLike(tex, parent, spec)
    local n = SafeName(tex)
    if n and has(n, spec.neverNames) then return true end
    -- buttons whose face IS the picture (sun/moon, calendar...): keep the face, grey only the rings
    if parent and spec.keepButtonFaces then
        local pname = SafeName(parent)
        local except = pname and has(pname, spec.keepFacesExcept)
        if not except then
            for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture" }) do
                local ok, face = pcall(function() return parent[getter] and parent[getter](parent) end)
                if ok and face == tex then return true end
            end
        end
    end
    -- plain image files cut from a bigger sheet are pictures (e.g. the sun/moon), not rings
    if spec.keepSheetPictures and not AtlasOf(tex) then
        local ok, l, t, _, b, r = pcall(function() return tex:GetTexCoord() end)
        if ok and l and (l > 0.01 or t > 0.01 or (r and r < 0.99) or (b and b < 0.99)) then
            local okw, w = pcall(function() return tex:GetWidth() end)
            if not (okw and w and w > 80) then return true end   -- big pieces are borders
        end
    end
    if parent then
        for _, key in ipairs({ "Icon", "icon", "IconTexture", "Portrait", "portrait" }) do
            if rawget(parent, key) == tex then return true end
        end
    end
    local ok, layer = pcall(function() return tex:GetDrawLayer() end)
    if ok and layer == "HIGHLIGHT" then return true end
    return false
end

local Collect
-- a root may resolve to one frame or to a list of frames (e.g. all nameplates)
local function CollectRoot(root, maxDepth, out, seen, skip)
    if type(root) == "table" and not root.GetRegions and root[1] then
        for _, f in ipairs(root) do Collect(f, 0, maxDepth, out, seen, skip) end
    else
        Collect(root, 0, maxDepth, out, seen, skip)
    end
end

function Collect(frame, depth, maxDepth, out, seen, skip)
    if not frame or seen[frame] or depth > maxDepth then return end
    seen[frame] = true
    if skip and depth > 0 and has(SafeName(frame), skip) then return end   -- another module's part
    local okF, forbidden = pcall(function() return frame.IsForbidden and frame:IsForbidden() end)
    if okF and forbidden then return end
    if frame.GetRegions then
        for _, r in ipairs({ frame:GetRegions() }) do
            if Kind(r) == "Texture" then out[#out + 1] = { tex = r, parent = frame } end
        end
    end
    if frame.GetChildren then
        for _, c in ipairs({ frame:GetChildren() }) do Collect(c, depth + 1, maxDepth, out, seen, skip) end
    end
end

-- is tex the normal/pushed/disabled picture of a button whose name matches words?
local function IsFaceOf(tex, parent, words)
    if not (words and parent and has(SafeName(parent), words)) then return false end
    for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture" }) do
        local ok, face = pcall(function() return parent[getter] and parent[getter](parent) end)
        if ok and face == tex then return true end
    end
    return false
end

local function Close(a, b) return a and b and math.abs(a - b) < 0.02 end
local function White(r, g, b) return r and r > 0.95 and g > 0.95 and b > 0.95 end

NS.mods = NS.mods or {}

-- spec = {
--   key, label, slash, macroPrefix, icon,
--   roots = { "Minimap", "MinimapCluster", function() ... end },
--   depth = 5,
--   darkness = 0.55, bgDarkness = 0.45, bgWords = {...},
--   only = { atlas words } or nil (= any atlas),
--   fileTextures = true/false  (also recolor textures without an atlas name),
--   never = { atlas words }, neverNames = { object-name words },
--   keep = { atlas/name words }  (pictures that always stay in full color),
--   respectTints = true/false  (leave colors Blizzard sets on purpose, e.g. item quality),
--   keepButtonFaces = true  (a button's own picture stays in color; only rings go grey),
--   keepFacesExcept = { frame-name words }  (buttons whose face may go grey, e.g. zoom),
--   keepSheetPictures = true  (small image-sheet pieces are pictures, left in color),
--   ringOnly = { atlas words }  (one-piece buttons: grey ring, full-color middle),
--   ringCenter = 0.72  (size of the colored middle, as a share of the button),
--   combatScan = true  (also scan in combat: only for art on non-secure frames, e.g. nameplates),
--   ringShape = "circle" or "square"  (shape of the colored middle),
--   ringParents = { frame-name words }  (those buttons' face pictures get the ring treatment),
--   skipFrames = { frame-name words }  (parts owned by another module, skipped),
--   events = { extra events that trigger a re-scan },
-- }
function NS.NewRecolor(spec)
    -- if another Dark* addon already runs this module, don't apply it twice
    local flag = "DarkIronUI_Module_" .. spec.key
    if _G[flag] then return end
    _G[flag] = true

    local mod = { spec = spec, touched = {} }
    NS.mods[spec.key] = mod
    local touched = mod.touched
    local DB

    local function Enabled() return DB and DB.enabled end

    local function Apply(tex, d)
        local r, g, b, a = tex:GetVertexColor()
        if IsSecret(r) or IsSecret(a) then return end   -- combat-hidden values: leave it this time
        local t = touched[tex]
        if not t then
            local desat = tex.IsDesaturated and tex:IsDesaturated() or false
            t = { orig = { r or 1, g or 1, b or 1, a or 1, desat }, d = d }
            touched[tex] = t
        end
        t.d = d or t.d
        local applied = t.applied
        if applied and Close(r, applied) and Close(g, applied) and Close(b, applied) then return end
        if spec.respectTints and r and not White(r, g, b) then
            -- Blizzard colored this on purpose (e.g. an item-quality border): leave it
            if t.desatOn and tex.SetDesaturated then tex:SetDesaturated(false); t.desatOn = false end
            t.applied = nil
            return
        end
        if tex.SetDesaturated then tex:SetDesaturated(true); t.desatOn = true end
        local base = (spec.respectTints and 1) or t.orig[1]
        local v = base * t.d
        tex:SetVertexColor(v, v, v, a or t.orig[4])
        t.applied = v
    end

    -- buttons drawn as ONE picture (ring + icon together, e.g. calendar, tracking):
    -- the original goes grey, and a full-color copy masked to a circle sits on top,
    -- so only the outer ring stays grey.
    local centers, ours = {}, {}   -- ours: our own copies, never recolored
    mod.centers = centers
    local CIRCLE = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
    local function SyncCenter(tex, c)
        local atlas = AtlasOf(tex)
        if atlas then
            if atlas ~= c.atlas then c.copy:SetAtlas(atlas); c.atlas = atlas end
        else
            -- plain image file (classic-style art): copy the file and its crop
            local okF, file = pcall(function() return tex:GetTexture() end)
            if okF and file and file ~= c.file then c.copy:SetTexture(file); c.file = file end
            local okC, a1, a2, a3, a4, a5, a6, a7, a8 = pcall(function() return tex:GetTexCoord() end)
            if okC and a1 then c.copy:SetTexCoord(a1, a2, a3, a4, a5, a6, a7, a8) end
        end
        local okW, w, h = pcall(function() return tex:GetSize() end)
        if okW and w and w > 0 then
            local f = spec.ringCenter or 0.72
            c.mask:SetSize(w * f, h * f)
        end
        local okS, shown = pcall(function() return tex:IsShown() end)
        c.copy:SetShown(Enabled() and okS and shown and true or false)
        local okA, a = pcall(function() return tex:GetAlpha() end)
        if okA and a then c.copy:SetAlpha(a) end
    end
    local function EnsureCenter(tex)
        local c = centers[tex]
        if not c then
            if InCombatLockdown and InCombatLockdown() then return end
            local owner = tex:GetParent()
            if not (owner and owner.CreateTexture and owner.CreateMaskTexture) then return end
            local okL, layer, sub = pcall(function() return tex:GetDrawLayer() end)
            layer = okL and layer or "ARTWORK"
            sub = math.min(7, (okL and sub or 0) + 1)
            local copy = owner:CreateTexture(nil, layer, nil, sub)
            copy:SetAllPoints(tex)
            local mask = owner:CreateMaskTexture()
            local shape = (spec.ringShape == "square") and "Interface\\Buttons\\WHITE8X8" or CIRCLE
            mask:SetTexture(shape, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            mask:SetPoint("CENTER", tex, "CENTER")
            copy:AddMaskTexture(mask)
            ours[copy] = true
            c = { copy = copy, mask = mask }
            centers[tex] = c
        end
        SyncCenter(tex, c)
    end

    local function Decide(e)
        local tex, parent = e.tex, e.parent
        if ours[tex] then return end
        -- a bar's own fill (XP, rep, health...) keeps its color
        if parent and parent.GetStatusBarTexture then
            local okB, fill = pcall(function() return parent:GetStatusBarTexture() end)
            if okB and fill == tex then return end
        end
        local atlas = AtlasOf(tex)
        local name = SafeName(tex)
        if has(atlas, spec.never) or has(name, spec.never) then return end
        if has(atlas, spec.keep) or has(name, spec.keep) then return end   -- pictures that stay in color
        if (has(atlas, spec.ringOnly) or IsFaceOf(tex, parent, spec.ringParents))
            and not (has(atlas, spec.bgWords) or has(name, spec.bgWords)) then
            pcall(Apply, tex, spec.darkness)
            pcall(EnsureCenter, tex)
            return
        end
        if IconLike(tex, parent, spec) then return end
        if atlas then
            if spec.only and not has(atlas, spec.only) then return end
        elseif not spec.fileTextures then
            return
        end
        local bg = has(atlas, spec.bgWords) or has(name, spec.bgWords)
        pcall(Apply, tex, bg and spec.bgDarkness or spec.darkness)
    end

    local function Scan()
        if not Enabled() then return end
        local list, seen = {}, {}
        for _, root in ipairs(spec.roots) do
            CollectRoot(Resolve(root), spec.depth or 5, list, seen, spec.skipFrames)
        end
        for _, e in ipairs(list) do pcall(Decide, e) end
        mod.lastCount = #list
    end

    local function Recheck()
        if not Enabled() then return end
        for tex, t in pairs(touched) do pcall(Apply, tex, t.d) end
        for tex, c in pairs(centers) do pcall(SyncCenter, tex, c) end
    end

    local function Restore()
        for tex, t in pairs(touched) do
            local o = t.orig
            pcall(tex.SetVertexColor, tex, o[1], o[2], o[3], o[4])
            if tex.SetDesaturated then pcall(tex.SetDesaturated, tex, o[5]) end
        end
        wipe(touched)
        for _, c in pairs(centers) do c.copy:Hide() end
    end

    local function Say(m) print("|cff9999ff" .. spec.label .. ":|r " .. m) end

    local function Debug()
        local n = 0
        for _ in pairs(touched) do n = n + 1 end
        Say(("look %s: %d pieces recolored"):format(Enabled() and "ON" or "off", n))
        for _, root in ipairs(spec.roots) do
            local f = Resolve(root)
            print("    root " .. (type(root) == "string" and root or "(function)") .. ": " .. (f and "found" or "not found"))
        end
        local list, seen, shown = {}, {}, {}
        for _, root in ipairs(spec.roots) do CollectRoot(Resolve(root), spec.depth or 5, list, seen, spec.skipFrames) end
        local rows = {}
        for _, e in ipairs(list) do
            local id = AtlasOf(e.tex) or SafeName(e.tex) or ("file " .. tostring(e.tex.GetTexture and e.tex:GetTexture()))
            if not shown[id] then
                shown[id] = true
                local owner = SafeName(e.parent) or "?"
                rows[#rows + 1] = id .. "  [" .. (touched[e.tex] and "grey" or "left alone") .. "]  in " .. owner
            end
        end
        table.sort(rows)
        Say("art found (" .. #rows .. "):")
        for i = 1, math.min(#rows, 60) do print("  " .. rows[i]) end
    end

    local slashKey = "DARKIRONUI_" .. spec.key:upper()
    _G["SLASH_" .. slashKey .. "1"] = spec.slash
    SlashCmdList[slashKey] = function(msg)
        if (msg or ""):lower():match("debug") then
            Debug()
        else
            DB.enabled = not DB.enabled
            if DB.enabled then Scan() else Restore() end
            Say("look " .. (DB.enabled and "on" or "off"))
        end
    end

    local macroPending = true
    local function TryMacros()
        if not macroPending or (InCombatLockdown and InCombatLockdown()) then return end
        macroPending = false
        if not (GetMacroIndexByName and CreateMacro and GetNumMacros) then return end
        pcall(function()
            for _, m in ipairs({ { spec.macroPrefix .. " Toggle", spec.slash }, { spec.macroPrefix .. " Debug", spec.slash .. " debug" } }) do
                local idx = GetMacroIndexByName(m[1])
                if not (idx and idx > 0) and GetNumMacros() < (MAX_ACCOUNT_MACROS or 36) then
                    if not pcall(CreateMacro, m[1], spec.icon or "Spell_Shadow_Twilight", m[2], nil) then
                        pcall(CreateMacro, m[1], "INV_MISC_QUESTIONMARK", m[2], nil)
                    end
                end
            end
        end)
    end

    local events = CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    for _, ev in ipairs(spec.events or {}) do pcall(events.RegisterEvent, events, ev) end
    local queued = false
    events:SetScript("OnEvent", function(_, event, arg1)
        if event == "ADDON_LOADED" then
            if arg1 ~= ADDON or DB then return end
            -- saved settings are ready now
            local svName = NS.SVNAME or "DarkIronUIDB"
            _G[svName] = _G[svName] or {}
            local sv = _G[svName]
            sv[spec.key] = sv[spec.key] or {}
            DB = sv[spec.key]
            if DB.enabled == nil then DB.enabled = true end
        end
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED" then TryMacros() end
        if event:sub(1, 5) == "UNIT_" and spec.eventUnit and arg1 ~= spec.eventUnit then return end
        if queued then return end
        queued = true
        C_Timer.After(0.5, function()
            queued = false
            if spec.combatScan or not (InCombatLockdown and InCombatLockdown()) then pcall(Scan) end
        end)
    end)

    if C_Timer.NewTicker then C_Timer.NewTicker(1, Recheck) end
    -- colored middles follow their button's state every frame (pressed, disabled...)
    local follow = CreateFrame("Frame")
    follow:SetScript("OnUpdate", function()
        if not next(centers) then return end
        for tex, c in pairs(centers) do
            local okS, shown = pcall(function() return tex:IsShown() end)
            local want = Enabled() and okS and shown and true or false
            if c.copy:IsShown() ~= want then c.copy:SetShown(want) end
        end
    end)
    return mod
end
