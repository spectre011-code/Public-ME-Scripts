local API = require("api")
local Slib = require("slib")
local FUNC = require("Slayer.libs.func")
local PROC = require("Slayer.libs.proc")
local DATA = require("Slayer.libs.data")

local Mode = "XP" --"XP" or "Slayer Points"

local States = {
    GettingTask     = "Getting Task",
    MovingToTask    = "Moving To Task",
    SlayingTask     = "Slaying Task",
    Rebanking       = "Rebanking"
}

local CurrentState = States.GettingTask
local TaskID = nil
local TaskAmount = nil
local TaskStreak = nil
local SlayerPoints = nil

API.TurnOffMrHasselhoff(false)
API.SetMaxIdleTime(7)

while API.Read_LoopyLoop() do
    TaskID = FUNC:GetTaskID()
    TaskAmount = FUNC:GetCurrentTaskAmount()
    TaskStreak = FUNC:GetTaskStreak()
    SlayerPoints = FUNC:GetSlayerPoints()
    print("Current State: " .. tostring(CurrentState))
    print("Task ID: " .. tostring(TaskID))
    print("Task Amount: " .. tostring(TaskAmount))
    print("Task Streak: " .. tostring(TaskStreak))
    print("Slayer Points: " .. tostring(SlayerPoints))

    if TaskAmount == 0 then
        CurrentState = States.GettingTask
    elseif not FUNC:IsTaskValid() then
        Slib:Error("Invalid Task ID: " .. tostring(TaskID))
        API.Write_LoopyLoop(false)
        goto continue
    end

    if CurrentState == States.GettingTask then
        CurrentState = PROC:GetTask()
    elseif CurrentState == States.MovingToTask then
        CurrentState = PROC:MoveToTask()
    elseif CurrentState == States.SlayingTask then
        CurrentState = PROC:SlayTask()
    elseif CurrentState == States.Rebanking then
        CurrentState = PROC:Rebank()
    else
        Slib:Error("Unknown State: " .. tostring(CurrentState))
        API.Write_LoopyLoop(false)
        goto continue
    end

    ::continue::
    Slib:RandomSleep(100, 200, "ms")    
end
--[[

]]
