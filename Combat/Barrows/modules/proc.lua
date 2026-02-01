-- Procedures for Spectre011's Barrows Killer
local API = require("api")
local Slib = require("slib")
local QUEST = require("quest")
local FUNC = require("Barrows.modules.func")
local DATA = require("Barrows.modules.data")

local PROC = {}

function PROC:HandleMovingToNextBrother()
    local Location = FUNC:WhereAmI()
    local NextBrother = FUNC:GetNextBrother()

    if Location == "VERAC" then
        if NextBrother == "AKRISAE" then
            Slib:MoveTo(Slib:RandomNumber(4074, 1, 1), Slib:RandomNumber(5723, -1, 1), 0)
        else
            Interact:Object("Staircase", "Climb-up")
            Slib:SleepUntil(function()
                return not API.IsPlayerMoving_(API.GetLocalPlayerName()) and FUNC:WhereAmI() == "ABOVE_BARROWS"
            end, 6, 100)
        end
        
    elseif Location == "AHRIM" then
        if NextBrother == "LINZA" then
            Slib:MoveTo(Slib:RandomNumber(3533, -1, 1), Slib:RandomNumber(9588, -1, 1), 0)
        else
            Interact:Object("Staircase", "Climb-up")
            Slib:SleepUntil(function()
                return not API.IsPlayerMoving_(API.GetLocalPlayerName()) and FUNC:WhereAmI() == "ABOVE_BARROWS"
            end, 6, 100)
        end

    elseif Location == "AKRISAE" or Location == "LINZA" or Location == "DHAROK" or Location == "TORAG" or Location == "KARIL" or Location == "GUTHAN" then 
        Interact:Object("Staircase", "Climb-up")
        Slib:SleepUntil(function()
            return not API.IsPlayerMoving_(API.GetLocalPlayerName()) and FUNC:WhereAmI() == "ABOVE_BARROWS"
        end, 6, 100)
        
    elseif Location == "ABOVE_BARROWS" then
        if NextBrother == "VERAC" or NextBrother == "AKRISAE" then
            Interact:Object("Spade", "Dig-with", WPOINT.new(3557, 3298, 5))
            Slib:SleepUntil(function()
                return not API.IsPlayerMoving_(API.GetLocalPlayerName()) and Slib:FindObj(DATA.Sarcophaguses, 10, 12) ~= false
            end, 6, 100)
            Slib:RandomSleep(100, 200, "ms")

        elseif NextBrother == "AHRIM" or NextBrother == "LINZA" then
            Interact:Object("Spades", "Dig-with", WPOINT.new(3567, 3288, 5))
            Slib:SleepUntil(function()
                return not API.IsPlayerMoving_(API.GetLocalPlayerName()) and Slib:FindObj(DATA.Sarcophaguses, 10, 12) ~= false
            end, 6, 100)
            Slib:RandomSleep(100, 200, "ms")

        elseif NextBrother == "DHAROK" then
            Interact:Object("Spades", "Dig-with", WPOINT.new(3575, 3298, 5))
            Slib:SleepUntil(function()
                return not API.IsPlayerMoving_(API.GetLocalPlayerName()) and Slib:FindObj(DATA.Sarcophaguses, 10, 12) ~= false
            end, 6, 100)
            Slib:RandomSleep(100, 200, "ms")

        elseif NextBrother == "TORAG" then
            Interact:Object("Spades", "Dig-with", WPOINT.new(3554, 3282, 5))
            Slib:SleepUntil(function()
                return not API.IsPlayerMoving_(API.GetLocalPlayerName()) and Slib:FindObj(DATA.Sarcophaguses, 10, 12) ~= false
            end, 6, 100)
            Slib:RandomSleep(100, 200, "ms")

        elseif NextBrother == "KARIL" then
            Interact:Object("Spade", "Dig-with", WPOINT.new(3564, 3277, 5))
            Slib:SleepUntil(function()
                return not API.IsPlayerMoving_(API.GetLocalPlayerName()) and Slib:FindObj(DATA.Sarcophaguses, 10, 12) ~= false
            end, 6, 100)
            Slib:RandomSleep(100, 200, "ms")

        elseif NextBrother == "GUTHAN" then
            Interact:Object("Spade", "Dig-with", WPOINT.new(3576, 3281, 5))
            Slib:SleepUntil(function()
                return not API.IsPlayerMoving_(API.GetLocalPlayerName()) and Slib:FindObj(DATA.Sarcophaguses, 10, 12) ~= false
            end, 6, 100)
            Slib:RandomSleep(100, 200, "ms")

        else
            Location = FUNC:WhereAmI()
            if not Location then
                Slib:Error("Should not be here. Something is broken. 002")
                Slib:Error("Location: ", tostring(Location))
                Slib:Error("NextBrother: ", tostring(NextBrother))
                API.Write_LoopyLoop(false)
            end
        end

    else
        Slib:Error("Should not be here. Something is broken. 003")
        Slib:Error("Location: ", tostring(Location))
        Slib:Error("NextBrother: ", tostring(NextBrother))
        API.Write_LoopyLoop(false)
    end
end

function PROC:HandleOpenSarcophagus()
    local NextBrother = FUNC:GetNextBrother()
    local TunnelLocation = FUNC:GetTunnelLocation()

    if NextBrother ~= TunnelLocation then
        Slib:UseAbilityById(30702) --Invoke Death
        Slib:RandomSleep(50, 100, "ms")
    end

    if NextBrother == "VERAC" then
        if not Interact:Object("Sarcophagus", "Search", WPOINT.new(3574, 9642, 1), 10) then
            Interact:Object("Sarcophagus", "Search", WPOINT.new(4073, 5710, 2))
        end

    elseif NextBrother == "AHRIM" then
        if not Interact:Object("Sarcophagus", "Search", WPOINT.new(3555, 9630, 1), 10) then
            Interact:Object("Sarcophagus", "Search", WPOINT.new(3545, 9586, 1))
        end

    elseif NextBrother == "DHAROK" then
        Interact:Object("Sarcophagus", "Search", WPOINT.new(3555, 9652, 1))

    elseif NextBrother == "GUTHAN" then
        Interact:Object("Sarcophagus", "Search", WPOINT.new(3534, 9640, 1))

    elseif NextBrother == "AKRISAE" then
        Interact:Object("Sarcophagus", "Search", WPOINT.new(4072, 5723, 2))

    elseif NextBrother == "TORAG" then
        Interact:Object("Sarcophagus", "Search", WPOINT.new(3568, 9613, 1))

    elseif NextBrother == "KARIL" then
        Interact:Object("Sarcophagus", "Search", WPOINT.new(3535, 9615, 1))

    elseif NextBrother == "LINZA" then
        Interact:Object("Sarcophagus", "Search", WPOINT.new(3531, 9588, 1))

    end

    Slib:SleepUntil(function()
        return not API.IsPlayerMoving_(API.GetLocalPlayerName()) and (QUEST:DialogBoxOpen() or Slib:FindObj(DATA.Brothers, 10, 1) ~= nil)
    end, 1, 100)
    if Slib:FindObj(DATA.Brothers, 10, 1) ~= nil then
        Interact:NPC(Slib:FindObj(DATA.Brothers, 10, 1).Name, "Attack")
        Slib:RandomSleep(600, 1000, "ms")
        if Slib:FindObj(DATA.Brothers, 10, 1) ~= nil then
            if Slib:FindObj(DATA.Brothers, 10, 1).Name == "Linza the Disgraced" then
                API.DoAction_Inventory1(DATA.Items.VulnBomb,0,1,API.OFF_ACT_GeneralInterface_route)
            end
        end
    end
end

function PROC:HandleTunnel()
    local Location = FUNC:WhereAmI()
    if Location == "TUNNELS" then
        Slib:SleepUntil(function()
            return Slib:FindObj(DATA.Portal, 10, 0) ~= nil
        end, 6, 100)

        if Slib:FindObj(DATA.Portal, 10, 0) == nil then
            Slib:Error("Could not find the portal to the chest room.")
            API.Write_LoopyLoop(false)
        end

        if Slib:FindObj(DATA.Portal, 10, 0) == nil then 
            Slib:Error("Unknown location. Halting script.")
            API.Write_LoopyLoop(false)

        else
            Interact:Object("Portal", "Enter", nil, 10)
        end
    end
end

function PROC:HandleLootingAndLastBrother()
    local Location = FUNC:WhereAmI()
    local NextBrother = FUNC:GetNextBrother()
    local TunnelLocation = FUNC:GetTunnelLocation()
    local HasLootedChest = FUNC:HasLootedChest()
    
    if HasLootedChest then
        return
    end

    if Location ~= "CHEST_ROOM" then
        return
    end

    if NextBrother == nil then
        Slib:RandomSleep(600, 1200, "ms")
        Interact:Object("Chest", "Search")
        Slib:RandomSleep(100, 200, "ms")
        Slib:SleepUntil(function()
            return not API.IsPlayerMoving_(API.GetLocalPlayerName()) and (FUNC:ChestInterfaceIsOpen())
        end, 6, 100)
        Slib:RandomSleep(600, 1200, "ms")
        if FUNC:ChestInterfaceIsOpen() then
            Slib:RandomSleep(200, 400, "ms")
            API.DoAction_Interface(0x24,0xffffffff,1,168,27,-1,API.OFF_ACT_GeneralInterface_route) --Bank Loot
            Slib:RandomSleep(600, 1200, "ms")
        end
    else
        if not API.LocalPlayer_IsInCombat_() then
            Interact:Object("Chest", "Open") 
            Slib:RandomSleep(600, 1200, "ms")
            Slib:SleepUntil(function()
                return not API.IsPlayerMoving_(API.GetLocalPlayerName()) and (Slib:FindObj(DATA.Brothers, 10, 1) ~= nil)
            end, 6, 100)
            Slib:RandomSleep(600, 900, "ms")
            Slib:UseAbilityById(30702) --Invoke Death
            Slib:RandomSleep(50, 100, "ms")
            Interact:NPC(Slib:FindObj(DATA.Brothers, 10, 1).Name, "Attack")
        end
    end    

    if Slib:FindObj(DATA.Brothers, 10, 1) ~= nil and not API.IsTargeting() then
        Slib:UseAbilityById(30702) --Invoke Death
        Slib:RandomSleep(50, 100, "ms")
        Interact:NPC(Slib:FindObj(DATA.Brothers, 10, 1).Name, "Attack")
    end

    if FUNC:ChestInterfaceIsOpen() then
        Slib:RandomSleep(200, 400, "ms")
        API.DoAction_Interface(0x24,0xffffffff,1,168,27,-1,API.OFF_ACT_GeneralInterface_route) --Bank Loot
        Slib:RandomSleep(600, 1200, "ms")
    end
end

function PROC:HandleLeavingCrypt()
    local Location = FUNC:WhereAmI()
    local staircaseLocations = {
        "AHRIM", "DHAROK", "GUTHAN", "AKRISAE", 
        "TORAG", "VERAC", "KARIL", "LINZA"
    }
    
    if Location == "CHEST_ROOM" then
        Interact:Object("Portal", "Enter")

    elseif Location == "TUNNELS" then
        Interact:Object("Rope", "Climb-up")

    elseif table.concat(staircaseLocations, ","):find(Location) then
        if Interact:Object("Staircase", "Climb-up") then
            Slib:SleepUntil(function()
                return not API.IsPlayerMoving_(API.GetLocalPlayerName()) and FUNC:WhereAmI() == "ABOVE_BARROWS"
            end, 6, 100)
        end
    else
        Slib:Error("Unknown location. Halting script.")
        API.Write_LoopyLoop(false)
    end
end

function PROC:HandleDialog()
    function OptionSelector(options)
        for i, optionText in ipairs(options) do
            local optionNumber = tonumber(API.Dialog_Option(optionText))
            if optionNumber and optionNumber > 0 then
                local keyCode = 0x30 + optionNumber
                API.KeyboardPress2(keyCode, 60, 100)
                API.RandomSleep2(400,300,600)
                return true
            end
        end
        return false
    end

    if FUNC:DialogHasOption() then
        OptionSelector(DATA.DialogOptions)
        return
    else
        Slib:TypeText(" ")
        return
    end
end

return PROC