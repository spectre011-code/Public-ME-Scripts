-- Helper functions for Spectre011's Barrows Killer
local API = require("api")
local Slib = require("slib")
local QUEST = require("quest")
local DATA = require("Barrows.modules.data")

local FUNC = {}

-- Returns a table with kill status for all brothers (1 = dead, 0 = alive)
function FUNC:GetKillList()
    return {
        AHRIM = API.GetVarbitValue(4554),
        DHAROK = API.GetVarbitValue(4555),
        GUTHAN = API.GetVarbitValue(4556),
        KARIL = API.GetVarbitValue(4557),
        TORAG = API.GetVarbitValue(4558),
        VERAC = API.GetVarbitValue(4559),
        AKRISAE = API.GetVarbitValue(11655),
        LINZA = API.GetVarbitValue(31434)
    }
end

function FUNC:GetTunnelLocation()
    local tunnelData = API.VB_FindPSettinOrder(1512).state
    
    local function isBitActive(value, bitPosition)
        return ((value >> bitPosition) & 1) == 1
    end
    
    if isBitActive(tunnelData, 0) then return "AHRIM" end
    if isBitActive(tunnelData, 1) then return "DHAROK" end
    if isBitActive(tunnelData, 2) then return "GUTHAN" end
    if isBitActive(tunnelData, 3) then return "KARIL" end
    if isBitActive(tunnelData, 4) then return "TORAG" end
    if isBitActive(tunnelData, 5) then return "VERAC" end    
    return "AKRISAE"
end

function FUNC:WhereAmI()
    local startTime = os.time()
    
    while API.Read_LoopyLoop() and (os.time() - startTime < 3) do
        local location = nil
        
        if Slib:IsPlayerInArea(3565, 3315, 0, 50) and not Slib:IsPlayerInRectangle(3547, 3582, 3269, 3311, 0) then
            location = "OUTSIDE_BARROWS"
        elseif Slib:IsPlayerInRectangle(3547, 3582, 3269, 3311, 0) then
            location = "ABOVE_BARROWS"
        elseif Slib:IsPlayerInRectangle(3537, 3549, 9581, 9590, 0) then
            location = "AHRIM"
        elseif Slib:IsPlayerInRectangle(3550, 3559, 9648, 9655, 0) then
            location = "DHAROK"
        elseif Slib:IsPlayerInRectangle(3529, 3539, 9636, 9643, 0) then
            location = "GUTHAN"
        elseif Slib:IsPlayerInRectangle(4067, 4076, 5717, 5726, 0) then
            location = "AKRISAE"
        elseif Slib:IsPlayerInRectangle(3563, 3572, 9610, 9618, 0) then
            location = "TORAG"
        elseif Slib:IsPlayerInRectangle(4068, 4077, 5707, 5716, 0) then
            location = "VERAC"
        elseif Slib:IsPlayerInRectangle(3530, 3540, 9611, 9619, 0) then
            location = "KARIL"
        elseif Slib:IsPlayerInRectangle(3527, 3536, 9582, 9593, 0) then
            location = "LINZA"
        elseif Slib:IsPlayerInArea(3294, 10127, 0, 50) then
            location = "WARS"
        else
            local chestObj = Slib:FindObj2(132113, 100, 0, 3552, 9694, 2)
            if chestObj ~= nil then
                if chestObj.Distance < 5 then
                    location = "CHEST_ROOM"
                else
                    location = "TUNNELS"
                end
            end
        end
        
        if location ~= nil then
            return location
        end
        
        Slib:RandomSleep(100, 300, "ms")
    end

    return "UNKNOWN"
end

--Return the next brother in the kill order. Order is Verac > Akrisae > Ahrim > Linza > Dharok > Torag > Karil > Guthan with tunnel last
function FUNC:GetNextBrother()
    local KillAkrisae = Quest:Get(194):isComplete() --Ritual of the Mahjarrat
    local KillLinza = Quest:Get(384):isComplete() --Kindred Spirits
    
    -- Build the kill order based on quest completion
    local killOrder = {"VERAC"}
    
    if KillAkrisae then
        table.insert(killOrder, "AKRISAE")
    end
    
    table.insert(killOrder, "AHRIM")
    
    if KillLinza then
        table.insert(killOrder, "LINZA")
    end
    
    table.insert(killOrder, "DHAROK")
    table.insert(killOrder, "TORAG")
    table.insert(killOrder, "KARIL")
    table.insert(killOrder, "GUTHAN")
    
    -- Get tunnel location and move it to the end
    local tunnelLocation = FUNC:GetTunnelLocation()
    
    -- Remove tunnel location from its current position
    local foundTunnel = false
    for i, brother in ipairs(killOrder) do
        if brother == tunnelLocation then
            table.remove(killOrder, i)
            foundTunnel = true
            break
        end
    end

    -- Add tunnel location to the end (keep uppercase)
    if tunnelLocation then
        table.insert(killOrder, tunnelLocation)
    end
   
    -- Get kill status for all brothers
    local killList = self:GetKillList()
    
    -- Find the first brother that hasn't been killed yet
    for i, brother in ipairs(killOrder) do
        local status = killList[brother]
        if status == 0 then
            return brother
        end
    end

    return nil
end

function FUNC:ChestInterfaceIsOpen()
    return #API.ScanForInterfaceTest2Get(true, DATA.Interfaces.LootChest) > 0
end

function FUNC:HasLootedChest()
    local tunnelData = API.VB_FindPSettinOrder(1512).state
    return ((tunnelData >> 26) & 1) == 1
end

function FUNC:GetOverloadItemId()
    -- Search for items with both lowercase and capitalized variants
    local overload_items = {}

    local lower = Item:GetAll("overload", true)
    local upper = Item:GetAll("Overload", true)

    -- Merge results
    if lower then
        for _, item in ipairs(lower) do
            table.insert(overload_items, item)
        end
    end

    if upper then
        for _, item in ipairs(upper) do
            table.insert(overload_items, item)
        end
    end

    -- Check if any items were found
    if #overload_items == 0 then
        return nil
    end

    -- Check each overload variant to see if it's in inventory
    for _, item in ipairs(overload_items) do
        if Inventory:Contains(item.id) then
            return item.id
        end
    end

    -- No overload found in inventory
    return nil
end

function FUNC:DialogBoxOpen()
    return API.VB_FindPSett(2874, 1, 0).state == 12
end

function FUNC:DialogHasOption()
    local option = API.ScanForInterfaceTest2Get(false, { { 1188, 5, -1, -1}, { 1188, 3, -1, 5}, { 1188, 3, 14, 3} })

    if #option > 0 and #option[1].textids > 0 then
        return option[1].textids
    end

    return false
end

return FUNC