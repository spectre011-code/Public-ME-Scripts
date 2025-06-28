-- Title: Spectre011's Woodcutting AIO
-- Author: Spectre011
-- Description: Cuts trees
-- Version: 1.0.0
-- Category: Woodcutting

local API = require("api")
local Slib = require("Woodcutting AIO.modules.slib")
local FUNC = require("Woodcutting AIO.modules.func")
local PROC = require("Woodcutting AIO.modules.proc")


local States = {
    STARTING = "STARTING",
    AT_TREES = "AT_TREES",
    MOVING_TO_TREES = "MOVING_TO_TREES",
    MOVING_TO_BANK = "MOVING_TO_BANK",
    AT_BANK = "AT_BANK",
    ERROR = "ERROR",
}

local CurrentState = "STARTING"
local IsFirstRun = true

API.SetMaxIdleTime(7)
API.Write_fake_mouse_do(false)
while (API.Read_LoopyLoop()) do
    if not API.CacheEnabled then
        print("Cache is not enabled. Halting script.")
        API.Write_LoopyLoop(false)
        goto continue
    end

    if (API.ScriptRuntime()/60) > tonumber(CONFIG.MaxTime) then
        print("Script runtime is greater than max time. Halting script.")
        API.Write_LoopyLoop(false)
        goto continue
    end

    if API.GetSkillByName("WOODCUTTING").level >= tonumber(CONFIG.MaxLevel) then
        print("Woodcutting level is greater than max level. Halting script.")
        API.Write_LoopyLoop(false)
        goto continue
    end
    
    if IsFirstRun then
        CurrentState = States.STARTING
        IsFirstRun = false
    end

    if CurrentState == States.STARTING then
        CurrentState = PROC:HandleStartingState(CONFIG)
    elseif CurrentState == States.AT_TREES then
        CurrentState = PROC:HandleAtTreesState(CONFIG)
    elseif CurrentState == States.MOVING_TO_TREES then
        CurrentState = PROC:HandleMovingToTreesState(CONFIG)
    elseif CurrentState == States.MOVING_TO_BANK then
        CurrentState = PROC:HandleMovingToBankState(CONFIG)
    elseif CurrentState == States.AT_BANK then
        CurrentState = PROC:HandleAtBankState(CONFIG)
    elseif CurrentState == States.ERROR then
        print("Error. Halting script.")
        API.Write_LoopyLoop(false)
        goto continue
    else
        if CurrentState then
            print("Unknown state: " .. CurrentState .. ". Halting script.")
            API.Write_LoopyLoop(false)
            goto continue
        else
            print("CurrentState is nil. Halting script.")
            API.Write_LoopyLoop(false)
            goto continue
        end
    end

    
    ::continue::
    Slib:Sleep(300, "ms")
    collectgarbage("collect")
    --API.Write_LoopyLoop(false)
end