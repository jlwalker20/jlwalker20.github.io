-- PartyFramesImproved: shared settings and the /pfi command

local ADDON, ns = ...

-- each part keeps its settings in its own section of the saved table
function ns.Section(name)
    PartyFramesImprovedDB = PartyFramesImprovedDB or {}
    PartyFramesImprovedDB[name] = PartyFramesImprovedDB[name] or {}
    return PartyFramesImprovedDB[name]
end

local function Say(m) print("|cff9999ffPFI:|r " .. m) end
ns.Say = Say

-- every raid-style frame Blizzard might be using
function ns.Frames()
    local list = {}
    for i = 1, 5 do list[#list + 1] = _G["CompactPartyFrameMember" .. i] end
    for i = 1, 40 do list[#list + 1] = _G["CompactRaidFrame" .. i] end
    for g = 1, 8 do for m = 1, 5 do list[#list + 1] = _G["CompactRaidGroup" .. g .. "Member" .. m] end end
    return list
end

local HELP = {
    "/pfi            layout on / off (bottom-up stacking)",
    "/pfi top        your frame on top / at the bottom",
    "/pfi sort       class order on / off",
    "/pfi label      hide / show the \"Party\" label",
    "/pfi icons      leader / PvP / marker icons on / off",
    "/pfi role       Blizzard's role icon hidden / shown",
    "/pfi heals      incoming heal / shield bars on / off",
    "/pfi debug      what every part sees",
}

SLASH_PARTYFRAMESIMPROVED1 = "/pfi"
SlashCmdList["PARTYFRAMESIMPROVED"] = function(msg)
    msg = (msg or ""):lower()
    if msg:find("help") then for _, l in ipairs(HELP) do Say(l) end; return end
    if msg:find("debug") then
        if ns.LayoutCmd then ns.LayoutCmd("debug") end
        if ns.IconsCmd then ns.IconsCmd("debug") end
        if ns.HealsCmd then ns.HealsCmd("debug") end
        return
    end
    if msg:find("icons") then if ns.IconsCmd then ns.IconsCmd("icons") end; return end
    if msg:find("resetart") then if ns.IconsCmd then ns.IconsCmd("resetart") end; return end
    if msg:find("role") then if ns.IconsCmd then ns.IconsCmd("role") end; return end
    if msg:find("heal") then if ns.HealsCmd then ns.HealsCmd("") end; return end
    if ns.LayoutCmd then ns.LayoutCmd(msg) end
end

-- one macro (account slots are often full): PFI Debug
local made = false
local mf = CreateFrame("Frame")
mf:RegisterEvent("PLAYER_ENTERING_WORLD")
mf:SetScript("OnEvent", function()
    if made or (InCombatLockdown and InCombatLockdown()) then return end
    made = true
    if not (GetMacroIndexByName and CreateMacro and GetNumMacros) then return end
    pcall(function()
        for _, mk in ipairs({ { "PFI Debug", "/pfi debug" } }) do
            local idx = GetMacroIndexByName(mk[1])
            if not (idx and idx > 0) and GetNumMacros() < (MAX_ACCOUNT_MACROS or 36) then
                pcall(CreateMacro, mk[1], "INV_MISC_QUESTIONMARK", mk[2], nil)
            end
        end
    end)
end)
