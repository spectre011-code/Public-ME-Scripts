local API = require("api")
local DATA = require("Slayer.libs.data")
local Slib = require("slib")

local FUNC = {}

function FUNC:GetTaskID()
    --If no task, returns the id of the last task
    return API.GetVarbitValue(7219) or API.GetVarbitValue(7923)
end

function FUNC:GetTaskStreak()
    return API.VB_FindPSettinOrder(10077).state
end

function FUNC:GetCurrentTaskAmount()
    return API.GetVarbitValue(7917)
end

function FUNC:GetSlayerPoints()
    --Can use varbits 6639 or 9071 apparently
    return API.GetVarbitValue(6639) or API.GetVarbitValue(9071)
end

function FUNC:IsTaskValid()
    local taskId = self:GetTaskID()

    for _, task in pairs(DATA.Tasks) do
        if task.Id == taskId then
            return true
        end
    end

    return false
end

function FUNC:StreakEndsWith9()
    return (self:GetTaskStreak() % 10) == 9
end

function FUNC:IsPlayerAtTaskLocation()
    local TaskID = self:GetTaskID()
    if TaskID == DATA.Tasks["Bats"].Id then
        return Slib:IsPlayerInRectangle(4011, 4027, 5503, 5521, 0) --Lumb catacombs

    elseif TaskID == DATA.Tasks["Goblins"].Id then
        return Slib:IsPlayerInRectangle(3992, 4008, 5491, 5499, 0) --Lumb catacombs

    elseif TaskID == DATA.Tasks["Rats"].Id then
        return Slib:IsPlayerInRectangle(4017, 4029, 5538, 5548, 0) --Lumb catacombs

    elseif TaskID == DATA.Tasks["Spiders"].Id then
        return Slib:IsPlayerInRectangle(3978, 3994, 5549, 5556, 0) --Lumb catacombs

    elseif TaskID == DATA.Tasks["Skeletons"].Id then
        return Slib:IsPlayerInRectangle(4019, 5533, 5521, 5537, 0) --Lumb catacombs

    elseif TaskID == DATA.Tasks["Zombies"].Id then
        return Slib:IsPlayerInRectangle(3978, 3994, 5549, 5556, 0) --Lumb catacombs

    elseif TaskID == DATA.Tasks["Fire giants"].Id then
        return Slib:IsPlayerInRectangle(2626, 2646, 9532, 9598, 2) --Brimhaven dungeon

    elseif TaskID == DATA.Tasks["Green dragons"].Id then
        return Slib:IsPlayerInRectangle(2965, 2995, 3605, 3626, 0) --Wilderness lv 15

    elseif TaskID == DATA.Tasks["Black dragons"].Id then
        return Slib:IsPlayerInRectangle(2826, 2846, 9814, 9829, 0) --Taverley dungeon

    else 
        return false
    end
end

function FUNC:IsPlayerAtLumbCatacombs()
    return Slib:IsPlayerInRectangle(3969, 4029, 5462, 5565, 0)
end

return FUNC