-- Helper functions for Spectre011's Woodcutter AIO
local API = require("api")
local Slib = require("Woodcutting AIO.modules.slib")
local CONFIG = require("Woodcutting AIO.config")
local DATA = require("Woodcutting AIO.modules.data")
local BANK = require("Woodcutting AIO.modules.bank")

math.randomseed(os.time())

FUNC = {}

function FUNC:PrintConfig(config)
    if config then
        Slib:Info("--- All CONFIG keys and values ---")
        for key, value in pairs(config) do
            Slib:Info(tostring(key) .. ": " .. tostring(value))
        end
        Slib:Info("---------------------------------")
    end
end

function FUNC:GetRandomNumber(base, variance)
    local min_val = base - variance
    local max_val = base + variance
    local random = math.random(min_val, max_val)
    return random
end

function FUNC:GetGOTEMaxCharges()
    if API.GetVarbitValue(52157) == 1 then
        return 2000
    else
        return 500
    end
end

function FUNC:GetGOTECharges()
    local equipment = API.Container_Get_all(94)
    local inventory = API.Container_Get_all(93)

    for _, item in pairs(equipment) do
        if item.item_id == 44550 then
            return item.Extra_ints[2]
        end
    end

    for _, item in pairs(inventory) do
        if item.item_id == 44550 then
            return item.Extra_ints[2]
        end
    end

    return 2000 --anti-stuck
end

function FUNC:GetSignOfThePorter()
    for _, item in pairs(DATA.ITEMS["Sign of the Porter"]) do
        if BANK:Contains(item) then
            return item
        end
    end

    return false
end

function FUNC:GOTEInterfaceIsOpen()
    local Interface = API.ScanForInterfaceTest2Get(true, DATA.INTERFACES.GOTE1)
    if #Interface > 0 then
        return true
    end

    return false
end

function FUNC:IsSkillInAbBar(AbID)

    for bar_id = 0, 4 do
        local bar_info = API.GetABarInfo(bar_id)
        if bar_info then
            for slot = 1, #bar_info do
                local ability = bar_info[slot]                
                if ability and ability.id and ability.id == AbID then
                    return true
                end
            end
        end
    end
    
    return false
end

function FUNC:GetBestTree(config)
    if not config then
        Slib:Warn("DEBUG: GetBestTree returning nil - config is nil")
        return nil
    end
    
    if not config.Tree then
        Slib:Warn("DEBUG: GetBestTree returning nil - config.Tree is nil")
        return nil
    end
    
    if config.Tree == "None" then
        return "None"
    end
    
    local treeParts = {}
    for part in config.Tree:gmatch("[^%-]+") do
        table.insert(treeParts, part:match("^%s*(.-)%s*$"))
    end
    
    if #treeParts < 2 then
        Slib:Warn("DEBUG: GetBestTree returning nil - not enough tree parts parsed (got " .. #treeParts .. ", expected at least 2)")
        return nil
    end
    
    local treeType = treeParts[1]:match("^%s*(.-)%s*$")
    local location = treeParts[2]:match("^%s*(.-)%s*$")
    local treeData = nil
    if treeType == "Regular tree" then
        treeData = DATA.TREES.REGULAR
    elseif treeType == "Oak tree" then
        treeData = DATA.TREES.OAK
    elseif treeType == "Willow tree" then
        treeData = DATA.TREES.WILLOW
    elseif treeType == "Teak tree" then
        treeData = DATA.TREES.TEAK
    elseif treeType == "Maple tree" then
        treeData = DATA.TREES.MAPLE
    elseif treeType == "Acadia tree" then
        treeData = DATA.TREES.ACADIA
    elseif treeType == "Eucaliptus trees" then
        treeData = DATA.TREES.EUCALYPTUS
    elseif treeType == "Mahogany trees" then
        treeData = DATA.TREES.MAHOGANY
    elseif treeType == "Ivy" then
        treeData = DATA.TREES.IVY
    elseif treeType == "Magic tree" then
        treeData = DATA.TREES.MAGIC
    elseif treeType == "Elder tree" then
        treeData = DATA.TREES.ELDER
    elseif treeType == "Eternal magic tree" then
        treeData = DATA.TREES.ETERNAL_MAGIC
    end
    
    if not treeData then
        Slib:Warn("DEBUG: GetBestTree returning nil - no tree data found for type: '" .. tostring(treeType) .. "'")
        return nil
    end
    
    local treeName = treeData.NAME
    
    local locationData = nil
    for key, data in pairs(treeData) do
        if type(key) == "string" and key:lower() == location:lower() then
            locationData = data
            break
        end
    end
    
    if not locationData or not locationData.area then
        Slib:Warn("DEBUG: GetBestTree returning nil - no location data or area found for location: '" .. tostring(location) .. "'")
        Slib:Info("DEBUG: Available locations for " .. tostring(treeType) .. ":")
        for key, data in pairs(treeData) do
            if type(key) == "string" and key ~= "NAME" then
                Slib:Info("DEBUG:   - '" .. key .. "'")
            end
        end
        return nil
    end
    
    local area = locationData.area
    
    local trees = API.ReadAllObjectsArray({ 0, 12 }, {-1}, { treeName })
    
    if not trees or #trees == 0 then
        Slib:Warn("DEBUG: GetBestTree returning nil - no trees found with name: '" .. tostring(treeName) .. "'")
        return nil
    end
    
    local validTrees = {}
    
    for i, tree in ipairs(trees) do
        local treeX = math.floor(tree.TileX / 512)
        local treeY = math.floor(tree.TileY / 512)
        
        if tree.Bool1 ~= 0 then
            goto continue
        end
        
        if not tree.Action or tree.Action == "" then
            goto continue
        end
        
        local inArea = false
        if area.rectangle then
            local rect = area.rectangle
            inArea = treeX >= rect.x1 and treeX <= rect.x2 and
                     treeY >= rect.y1 and treeY <= rect.y2
        elseif area.x1 and area.y1 and area.x2 and area.y2 then
            inArea = treeX >= area.x1 and treeX <= area.x2 and
                     treeY >= area.y1 and treeY <= area.y2
        end
        
        if inArea then
            table.insert(validTrees, tree)
        end
        
        ::continue::
    end
    
    if #validTrees == 0 then
        Slib:Warn("DEBUG: GetBestTree returning nil - no valid trees found in area after filtering")
        return nil
    end
    
    table.sort(validTrees, function(a, b) return a.Distance < b.Distance end)
    
    local bestTree = validTrees[1]
    local bestTreeX = math.floor(bestTree.TileX / 512)
    local bestTreeY = math.floor(bestTree.TileY / 512)
    return bestTree
end

function FUNC:GetRegularJuju()
    for _, item in pairs(DATA.ITEMS["Regular Juju"]) do
        if BANK:Contains(item) then
            return item
        end
    end

    return false
end

function FUNC:GetPerfectJuju()
    for _, item in pairs(DATA.ITEMS["Perfect Juju"]) do
        if BANK:Contains(item) then
            return item
        end
    end

    return false
end

function FUNC:GetPerfectPlus()
    for _, item in pairs(DATA.ITEMS["Perfect Plus"]) do
        if BANK:Contains(item) then
            return item
        end
    end

    return false
end

function FUNC:GetWoodBox()
    for _, item in pairs(DATA.ITEMS["Wood boxes"]) do
        if Inventory:Contains(item.id) then
            return item
        end
    end
end

function FUNC:GetLogIdFromTree(treeSelection)
    if not treeSelection then
        return nil
    end
    
    local lowerTree = treeSelection:lower()
    
    if lowerTree:find("regular tree") then
        return 1511
    elseif lowerTree:find("oak tree") then
        return 1521
    elseif lowerTree:find("willow tree") then
        return 1519
    elseif lowerTree:find("teak tree") then
        return 6333
    elseif lowerTree:find("maple tree") then
        return 1517
    elseif lowerTree:find("acadia tree") then
        return 40285
    elseif lowerTree:find("eucaliptus") then
        return 12581
    elseif lowerTree:find("mahogany tree") then
        return 6332
    elseif lowerTree:find("magic tree") and not lowerTree:find("eternal") then
        return 1513
    elseif lowerTree:find("elder tree") then
        return 29556
    elseif lowerTree:find("eternal magic tree") then
        return 58250
    end
    
    return nil
end

function FUNC:getWoodBoxItemCount(config)
    local logId = self:GetLogIdFromTree(config.Tree)
    
    if not logId then
        return 0
    end
    
    local itemCount = 0
    for _, itemData in pairs(API.Container_Get_all(937)) do
        if itemData.item_id == logId then
            itemCount = itemCount + itemData.item_stack
        end
    end
    return itemCount
end

function FUNC:GetWoodBoxMaxCapacity()
    local currentBox = self:GetWoodBox()
    if not currentBox then
        return 0
    end
    
    local woodcuttingLevel = API.GetSkillByName("WOODCUTTING").level
    local extraCapacity = math.floor(woodcuttingLevel / 10) * 10
    
    return currentBox.capacity + extraCapacity
end

function FUNC:isWoodBoxFull(config)
    local logId = self:GetLogIdFromTree(config.Tree)
    
    if not logId then
        return false
    end
    
    local currentCount = self:getWoodBoxItemCount(config)
    local maxCapacity = self:GetWoodBoxMaxCapacity()
    
    return currentCount >= maxCapacity
end

function FUNC:GetWoodBoxHexIdAndSlot()
    local inventory = API.Container_Get_all(93) -- Get inventory contents
    
    -- Loop through inventory slots
    for slot, item in pairs(inventory) do
        -- Check if this item is a wood box
        for _, woodBox in pairs(DATA.ITEMS["Wood boxes"]) do
            if item.item_id == woodBox.id then
                -- Convert decimal ID to hex format
                local hexId = string.format("0x%x", item.item_id)
                return hexId, (slot - 1)
            end
        end
    end
    
    -- Return nil if no wood box found
    return nil, nil
end

return FUNC
