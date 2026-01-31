-- Title: Spectre's Barrows Killer
-- Author: Spectre011
-- Description: Kills the barrows brothers
-- Version: 1.0.0
-- Category: Combat

ScriptName = "Spectre's Barrows Killer"
Author = "Spectre011"
ScriptVersion = "1.0.0"
ReleaseDate = "30-01-2026"
DiscordHandle = "not_spectre011"

--[[
Changelog:
v1.0.0 - 30-01-2026
    - Initial release.

]]

local API = require("api")
local Slib = require("slib")
local BANK = require("bank")
local FUNC = require("Barrows.modules.func")
local PROC = require("Barrows.modules.proc")
local DATA = require("Barrows.modules.data")

API.SetMaxIdleTime(7)
API.Write_fake_mouse_do(false)
API.TurnOffMrHasselhoff(false)

--------------------START GUI STUFF--------------------
ClearRender()
local CurrentStatus = "Starting"
local Location      = "Starting"

local WINDOW_WIDTH  = 275
local WINDOW_HEIGHT = 80
local LABEL_X       = 90

local BROTHER_ORDER = {
    "VERAC", "AKRISAE", "AHRIM", "LINZA",
    "DHAROK", "TORAG", "KARIL", "GUTHAN"
}

local BROTHER_GLYPH = {
    VERAC    = "V ",
    AKRISAE = "A ",
    AHRIM   = "A ",
    LINZA   = "L ",
    DHAROK  = "D ",
    TORAG   = "T ",
    KARIL   = "K ",
    GUTHAN  = "G "
}

local ALIVE_R,  ALIVE_G,  ALIVE_B,  ALIVE_A  = 1.0, 1.0, 0.2, 1.0
local DEAD_R,   DEAD_G,   DEAD_B,   DEAD_A   = 0.3, 0.3, 0.3, 1.0
local TUNNEL_R, TUNNEL_G, TUNNEL_B, TUNNEL_A = 0.2, 1.0, 0.2, 1.0
local BG_R,     BG_G,     BG_B,     BG_A     = 0.06, 0.06, 0.08, 0.95

local function DrawLabelValue(label, value)
    ImGui.Text(label)
    ImGui.SameLine()
    ImGui.SetCursorPosX(LABEL_X)
    ImGui.TextColored(1, 1, 0.2, 1, tostring(value))
end

local function DrawBrothers()
    local killList      = FUNC:GetKillList()
    local tunnelBrother = FUNC:GetTunnelLocation()

    ImGui.Text("Brothers:")
    ImGui.SameLine()
    ImGui.SetCursorPosX(LABEL_X)

    for i, brother in ipairs(BROTHER_ORDER) do
        local glyph    = BROTHER_GLYPH[brother] or "?"
        local isDead   = killList[brother] == 1
        local isTunnel = (brother == tunnelBrother)

        if isDead then
            ImGui.TextColored(DEAD_R, DEAD_G, DEAD_B, DEAD_A, glyph)
        elseif isTunnel then
            ImGui.TextColored(TUNNEL_R, TUNNEL_G, TUNNEL_B, TUNNEL_A, glyph)
        else
            ImGui.TextColored(ALIVE_R, ALIVE_G, ALIVE_B, ALIVE_A, glyph)
        end

        if i < #BROTHER_ORDER then
            ImGui.SameLine()
        end
    end
end

local function DrawGUI()
    -- Set default size ONCE so the user can resize freely
    ImGui.SetNextWindowSize(WINDOW_WIDTH, WINDOW_HEIGHT, ImGuiCond.Once)

    ImGui.PushStyleColor(ImGuiCol.WindowBg, BG_R, BG_G, BG_B, BG_A)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 10, 8)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 0, 4)

    ImGui.Begin(
        ScriptName .. " v" .. ScriptVersion,
        nil,
        ImGuiWindowFlags.NoCollapse
    )

    DrawLabelValue("Location:", Location)
    DrawBrothers()
    DrawLabelValue("Status:", CurrentStatus)

    ImGui.End()
    ImGui.PopStyleVar(2)
    ImGui.PopStyleColor()
end

function UpdateGUI(newLocation, newStatus)
    if newLocation then Location = newLocation end
    if newStatus   then CurrentStatus = newStatus end
end

DrawImGui(DrawGUI)

--------------------END GUI STUFF--------------------

local HasLooted = nil
local RNG = nil
local RNG2 = nil
local Ovl = nil
local ChatOptions = {
    "Yeah I'm fearless"
}

while (API.Read_LoopyLoop()) do
    if not API.CacheEnabled then
        Slib:Error("Cache is not enabled. Halting script.")
        API.Write_LoopyLoop(false)
        goto continue
    end

    if (API.ScriptRuntime()/60) > tonumber(CONFIG.MaxTime) then
        Slib:Warn("Script runtime is greater than max time. Halting script.")
        API.Write_LoopyLoop(false)
        goto continue
    end

    if not Inventory:Contains(21576) then
        Slib:Error("Drakan's medallion not found. Halting script.")
        API.Write_LoopyLoop(false)
        goto continue
    end

    if API.GetVarbitValue(42166) ~= 0 then
        Slib:Error("Auto retaliate disabled. Halting script.")
        API.Write_LoopyLoop(false)
        goto continue
    end

    --Buff/Health upkeep
    RNG = Slib:RandomNumber(5, -5, 5)
    if not Slib:HasDebuff(DATA.Buffs.EnhancedExcalibur) then
        if RNG > 8 then
            API.DoAction_Inventory1(DATA.Items.AugmentedEnhancedExcalibur,0,2,API.OFF_ACT_GeneralInterface_route)
        end
    end

    if not Slib:HasDebuff(DATA.Buffs.ElvenShard) then
        if RNG > 7 then
            API.DoAction_Inventory1(DATA.Items.ElvenShard,0,1,API.OFF_ACT_GeneralInterface_route)
        end
    end

    if not Slib:HasBuff(DATA.Buffs.Darkness) then
        Slib:UseAbilityById(30700) --Darkness
    end

    RNG2 = Slib:RandomNumber(50, 20, 30)
    if API.GetPrayPrecent() < RNG2 then
        API.DoAction_Inventory2(DATA.Items.SuperRestore,0,1,API.OFF_ACT_GeneralInterface_route)
    end

    if API.GetHPrecent() < RNG2 then
        if Slib:CanCastAbility(1601) then
            Slib:UseAbilityById(1601) --Eat Food
        else
            if Location ~= "CHEST_ROOM" and Location ~= "TUNNELS" then                
                if CONFIG.Bank == "Wars retreat" then
                    Slib:UseAbilityById(35042)
                    Slib:RandomSleep(6000, 8000, "ms")
                else
                    Slib:Error("Unknown banking location. Halting script.")
                    API.Write_LoopyLoop(false)
                    goto continue
                end
            end
        end
    end

    Ovl = FUNC:GetOverloadItemId()
    if not Slib:HasBuff(DATA.Buffs.Overload) and not Slib:HasBuff(DATA.Buffs.SupremeOverload) and not Slib:HasBuff(DATA.Buffs.ElderOverload) then
        if Ovl then
            API.DoAction_Inventory1(Ovl,0,1,API.OFF_ACT_GeneralInterface_route)
        else
            if CONFIG.Bank == "Wars retreat" then
                Slib:UseAbilityById(35042)
                Slib:RandomSleep(6000, 8000, "ms")
            else
                Slib:Error("Unknown banking location. Halting script.")
                API.Write_LoopyLoop(false)
                goto continue
            end
        end
    end

    Location = FUNC:WhereAmI()
    NextBrother = FUNC:GetNextBrother()
    TunnelLocation = FUNC:GetTunnelLocation()
    HasLooted = FUNC:HasLootedChest()

    if not Location or Location == "Starting" then
        goto continue
    end

    if FUNC:DialogBoxOpen() then
        PROC:HandleDialog()
        goto continue
    end
    
    if API.IsPlayerMoving_(API.GetLocalPlayerName()) then
        goto continue
    end

    if API.LocalPlayer_IsInCombat_() and API.IsTargeting() then
        if not Slib:HasBuff(DATA.Buffs.SoulSplit) and API.GetPray_() > 0 then
            Slib:UseAbilityById(DATA.Buffs.SoulSplit)
            Slib:RandomSleep(600, 1200, "ms")
        end
        goto continue
    else
        if Slib:HasBuff(DATA.Buffs.SoulSplit) then
            Slib:UseAbilityById(DATA.Buffs.SoulSplit)
        end
    end

    if Location == "UNKNOWN" then
        Slib:Error("Unknown location. Halting script.")
        API.Write_LoopyLoop(false)
        goto continue

    elseif Location == "OUTSIDE_BARROWS" then
        UpdateGUI(Location, "Entering Barrows")
        Slib:MoveTo(Slib:RandomNumber(3560, -2, 2), Slib:RandomNumber(3298, -2, 2), 0)
        goto continue

    elseif Location == "WARS" then
        UpdateGUI(Location, "Rebanking")
        BANK:LoadLastPreset()
        Slib:RandomSleep(6000, 12000, "ms")
        API.DoAction_Inventory1(DATA.Items.DrakansMedallion,0,1,API.OFF_ACT_GeneralInterface_route)
        Slib:RandomSleep(1200, 2400, "ms")
        Slib:TypeText("1")
        Slib:RandomSleep(3000, 3600, "ms")        
        goto continue

    elseif HasLooted and Location ~= "ABOVE_BARROWS" then
        UpdateGUI(Location, "Leaving Crypt")
        PROC:HandleLeavingCrypt()
        goto continue

    elseif Location == "CHEST_ROOM" then
        UpdateGUI(Location, "Last Brother and Looting")
        PROC:HandleLootingAndLastBrother()
        goto continue

    elseif Location == "TUNNELS" then
        UpdateGUI(Location, "Going through tunnel")
        PROC:HandleTunnel()
        goto continue

    elseif Location ~= NextBrother then
        UpdateGUI(Location, "Moving to next brother")
        PROC:HandleMovingToNextBrother()
        goto continue

    elseif Location == NextBrother then
        UpdateGUI(Location, "Opening sarcophagus")
        PROC:HandleOpenSarcophagus()
        goto continue

    else
        Slib:Error("Should not be here. Something is broken. 001")
        Slib:Error("Location: ", tostring(Location))
        Slib:Error("NextBrother: ", tostring(NextBrother))
        Slib:Error("TunnelLocation: ", tostring(TunnelLocation))
        Slib:Error("HasLooted: ", tostring(HasLooted))
        API.Write_LoopyLoop(false)
        goto continue
    end

    ::continue::
    Slib:RandomSleep(50, 150, "ms")
    collectgarbage("collect")
end

ClearRender()
print("----------//----------")
print("Script Name: " .. ScriptName)
print("Author: " .. Author)
print("Version: " .. ScriptVersion)
print("Release Date: " .. ReleaseDate)
print("Discord: " .. DiscordHandle)
print("----------//----------")
