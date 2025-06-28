--[[
#Script Name:   <lodestones.lua>
# Description:  <Functions to teleport to Lodestones>
# Autor:        <Dead (dea.d - Discord)>
# Version:      <2.0>
# Datum:        <2024.10.27>

# Description:  This module provides functionality for teleporting to various lodestones and checking the player's current location relative to these lodestones.
                Each lodestone is represented as an object with 'Teleport' and 'IsAtLocation' methods.
                'Teleport' handles the teleportation process to the respective lodestone,
                while 'IsAtLocation' checks if the player is currently at the specified lodestone's location.

# Usage:        First, require this module in your script. 
                Then, use LODESTONES.<LODESTONE_NAME>.Teleport() to teleport to a lodestone, 
                or LODESTONES.<LODESTONE_NAME>.IsAtLocation() to check if you are at a specific lodestone.

# Example:      local LODESTONES = require("lodestones")
                LODESTONES.PORT_SARIM.Teleport()
                local atPortSarim = LODESTONES.PORT_SARIM.IsAtLocation()
]]

local API = require("api")
local LODESTONES = {}


local function IsAtLodestone(lode)
    local playerLoc = API.PlayerCoord()
    local lodeLoc = lode.loc
    local xDiff = math.abs(playerLoc.x - lodeLoc.x)
    local yDiff = math.abs(playerLoc.y - lodeLoc.y)

    return xDiff <= 20 and yDiff <= 20
end

local function SleepUntil(conditionFunc, timeout, message)
    local startTime = os.time()
    local sleepSuccessful = false
    while not conditionFunc() do
        if os.difftime(os.time(), startTime) >= timeout then
            print("Stopped waiting for " .. message .. " after " .. timeout .. " seconds.")
            break
        end
        if not API.Read_LoopyLoop() then
            print("Script exited - breaking sleep.")
            break
        end
        API.RandomSleep2(100, 100, 100)
    end
    if conditionFunc() then
        print("Sleep condition met for " .. message)
        sleepSuccessful = true
    end
    return sleepSuccessful
end

local function OpenLodestonesInterface()
    if API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1465, 18, -1, API.OFF_ACT_GeneralInterface_route) then
        SleepUntil(function() return API.Compare2874Status(30, false) end, 10, "Lodestone interface open")
    end
end

local function GoToLodestone(lode)
    if IsAtLodestone(lode) then
        print("At lodestone area")
        return true
    end

    print("Teleporting to lodestone")
    if not API.Compare2874Status(30, false) then
        OpenLodestonesInterface()
    end
    -- Lodestone interface is open. We shall teleport
    if API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1092, lode.id, -1, API.OFF_ACT_GeneralInterface_route) then
        if API.CheckAnim(200) then
            print("Wait for anim complete")
            if SleepUntil(function() return IsAtLodestone(lode) end, 20, "teleported to lodestone") then
                SleepUntil(function() return API.ReadPlayerAnim() > 0 end, 10, "first anim check")
                SleepUntil(function() return API.ReadPlayerAnim() == 0 end, 10, "second anim check")
                print("finished waiting for teleport")
                API.RandomSleep2(3000,100,100)
                return true
            end
        end
    end
    return false
end

local function buildLodestone(id, loc)
    return {
        id = id,
        loc = loc,
        Teleport = function()
            GoToLodestone({id = id, loc = loc})
            return IsAtLodestone({id = id, loc = loc})
        end,
        IsAtLocation = function()
            return IsAtLodestone({id = id, loc = loc})
        end
    }
end

LODESTONES.AL_KHARID = buildLodestone(11, WPOINT.new(3297, 3184, 0))
LODESTONES.ANACHRONIA = buildLodestone(25, WPOINT.new(5431, 2338, 0))
LODESTONES.ARDOUGNE = buildLodestone(12, WPOINT.new(2634, 3348, 0))
LODESTONES.ASHDALE = buildLodestone(34, WPOINT.new(2474, 2708, 2))
LODESTONES.BANDIT_CAMP = buildLodestone(9, WPOINT.new(2899, 3544, 0))
LODESTONES.BURTHOPE = buildLodestone(13, WPOINT.new(2899, 3544, 0))
LODESTONES.CANIFIS = buildLodestone(27, WPOINT.new(3517, 3515, 0))
LODESTONES.CATHERBY = buildLodestone(14, WPOINT.new(2811, 3449, 0))
LODESTONES.DRAYNOR_VILLAGE = buildLodestone(15, WPOINT.new(3105, 3298, 0))
LODESTONES.EAGLES_PEAK = buildLodestone(28, WPOINT.new(2366, 3479, 0))
LODESTONES.EDGEVILLE = buildLodestone(16, WPOINT.new(3067, 3505, 0))
LODESTONES.FALADOR = buildLodestone(17, WPOINT.new(2967, 3403, 0))
LODESTONES.FORT_FORINTHRY = buildLodestone(23, WPOINT.new(3298, 3525, 0))
LODESTONES.FREMENNIK_PROVINCE = buildLodestone(29, WPOINT.new(2712, 3677, 0))
LODESTONES.KARAMJA = buildLodestone(30, WPOINT.new(2761, 3147, 0))
LODESTONES.LUNAR_ISLE = buildLodestone(10, WPOINT.new(2085, 3914, 0))
LODESTONES.LUMBRIDGE = buildLodestone(18, WPOINT.new(3233, 3221, 0))
LODESTONES.MENAPHOS = buildLodestone(24, WPOINT.new(3216, 2716, 0))
LODESTONES.OOGLOG = buildLodestone(31, WPOINT.new(2532, 2871, 0))
LODESTONES.PORT_SARIM = buildLodestone(19, WPOINT.new(3011, 3215, 0))
LODESTONES.PRIFDDINAS = buildLodestone(35, WPOINT.new(2208, 3360, 1))
LODESTONES.SEERS_VILLAGE = buildLodestone(20, WPOINT.new(2689, 3482, 0))
LODESTONES.TAVERLEY = buildLodestone(21, WPOINT.new(2878, 3442, 0))
LODESTONES.TIRANNWN = buildLodestone(32, WPOINT.new(2254, 3149, 0))
LODESTONES.UM = buildLodestone(36, WPOINT.new(1084, 1768, 1))
LODESTONES.VARROCK = buildLodestone(22, WPOINT.new(3214, 3376, 0))
LODESTONES.WILDERNESS = buildLodestone(33, WPOINT.new(0, 0, 0))
LODESTONES.YANILLE = buildLodestone(26, WPOINT.new(2560, 3094, 0))

return LODESTONES