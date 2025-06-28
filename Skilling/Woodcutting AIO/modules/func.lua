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
        print("\n--- All CONFIG keys and values ---")
        for key, value in pairs(config) do
            print(tostring(key) .. ": " .. tostring(value))
        end
        print("---------------------------------")
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

    return 500 --return 500 if no GOTE is found so it wont try to recharge it
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
    -- Validate config parameter
    if not config then
        print("DEBUG: GetBestTree returning nil - config is nil")
        return nil
    end
    
    if not config.Tree then
        print("DEBUG: GetBestTree returning nil - config.Tree is nil")
        return nil
    end
    
    if config.Tree == "None" then
        return "None"
    end
    
    -- Parse config.Tree to get tree type and location
    -- Format examples: "Regular tree - North of Burthorpe", "Oak tree - East of Draynor"
    local treeParts = {}
    for part in config.Tree:gmatch("[^%-]+") do
        table.insert(treeParts, part:match("^%s*(.-)%s*$")) -- trim whitespace
    end
    
    if #treeParts < 2 then
        print("DEBUG: GetBestTree returning nil - not enough tree parts parsed (got " .. #treeParts .. ", expected at least 2)")
        return nil
    end
    
    local treeType = treeParts[1]:match("^%s*(.-)%s*$") -- trim whitespace
    local location = treeParts[2]:match("^%s*(.-)%s*$") -- trim whitespace
    
    -- Get tree data from DATA based on tree type
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
        print("DEBUG: GetBestTree returning nil - no tree data found for type: '" .. tostring(treeType) .. "'")
        return nil
    end
    
    local treeName = treeData.NAME
    
    -- Find location data with case-insensitive matching
    local locationData = nil
    for key, data in pairs(treeData) do
        if type(key) == "string" and key:lower() == location:lower() then
            locationData = data
            break
        end
    end
    
    if not locationData or not locationData.area then
        print("DEBUG: GetBestTree returning nil - no location data or area found for location: '" .. tostring(location) .. "'")
        print("DEBUG: Available locations for " .. tostring(treeType) .. ":")
        for key, data in pairs(treeData) do
            if type(key) == "string" and key ~= "NAME" then
                print("DEBUG:   - '" .. key .. "'")
            end
        end
        return nil
    end
    
    local area = locationData.area
    
    -- Scan for trees using ReadAllObjectsArray
    local trees = API.ReadAllObjectsArray({ 0, 12 }, {-1}, { treeName })
    
    if not trees or #trees == 0 then
        print("DEBUG: GetBestTree returning nil - no trees found with name: '" .. tostring(treeName) .. "'")
        return nil
    end
    
    -- Filter trees by area and find the closest valid one
    local validTrees = {}
    
    for i, tree in ipairs(trees) do
        local treeX = math.floor(tree.TileX / 512)
        local treeY = math.floor(tree.TileY / 512)
        
        -- Check if tree is valid (Bool1 == 0 means tree is available)
        if tree.Bool1 ~= 0 then
            goto continue
        end
        
        -- Check if tree has an action (can be interacted with)
        if not tree.Action or tree.Action == "" then
            goto continue
        end
        
        -- Check if tree is in the specified area
        local inArea = false
        if area.rectangle then
            -- Some areas use rectangle sub-table (like Ivy locations)
            local rect = area.rectangle
            inArea = treeX >= rect.x1 and treeX <= rect.x2 and
                     treeY >= rect.y1 and treeY <= rect.y2
        elseif area.x1 and area.y1 and area.x2 and area.y2 then
            -- Direct area coordinates
            inArea = treeX >= area.x1 and treeX <= area.x2 and
                     treeY >= area.y1 and treeY <= area.y2
        end
        
        if inArea then
            table.insert(validTrees, tree)
        end
        
        ::continue::
    end
    
    if #validTrees == 0 then
        print("DEBUG: GetBestTree returning nil - no valid trees found in area after filtering")
        return nil
    end
    
    -- Sort by distance (using existing Distance field) and return the closest
    table.sort(validTrees, function(a, b) return a.Distance < b.Distance end)
    
    local bestTree = validTrees[1]
    local bestTreeX = math.floor(bestTree.TileX / 512)
    local bestTreeY = math.floor(bestTree.TileY / 512)
    --[[
    print("DEBUG: ===== BEST TREE ALL FIELDS =====")
    print("DEBUG: Mem = " .. tostring(bestTree.Mem))
    print("DEBUG: MemE = " .. tostring(bestTree.MemE))
    print("DEBUG: TileX = " .. tostring(bestTree.TileX))
    print("DEBUG: TileY = " .. tostring(bestTree.TileY))
    print("DEBUG: TileZ = " .. tostring(bestTree.TileZ))
    print("DEBUG: Id = " .. tostring(bestTree.Id))
    print("DEBUG: Life = " .. tostring(bestTree.Life))
    print("DEBUG: Anim = " .. tostring(bestTree.Anim))
    print("DEBUG: Name = '" .. tostring(bestTree.Name) .. "'")
    print("DEBUG: Action = '" .. tostring(bestTree.Action) .. "'")
    print("DEBUG: Floor = " .. tostring(bestTree.Floor))
    print("DEBUG: Amount = " .. tostring(bestTree.Amount))
    print("DEBUG: Type = " .. tostring(bestTree.Type))
    print("DEBUG: Bool1 = " .. tostring(bestTree.Bool1))
    print("DEBUG: ItemIndex = " .. tostring(bestTree.ItemIndex))
    print("DEBUG: ViewP = " .. tostring(bestTree.ViewP))
    print("DEBUG: ViewF = " .. tostring(bestTree.ViewF))
    print("DEBUG: Distance = " .. tostring(bestTree.Distance))
    print("DEBUG: Cmb_lv = " .. tostring(bestTree.Cmb_lv))
    print("DEBUG: Unique_Id = " .. tostring(bestTree.Unique_Id))
    print("DEBUG: CalcX = " .. tostring(bestTree.CalcX))
    print("DEBUG: CalcY = " .. tostring(bestTree.CalcY))
    print("DEBUG: Calculated X = " .. bestTreeX .. " (TileX/512 rounded down)")
    print("DEBUG: Calculated Y = " .. bestTreeY .. " (TileY/512 rounded down)")
    if bestTree.Tile_XYZ then
        print("DEBUG: Tile_XYZ.x = " .. tostring(bestTree.Tile_XYZ.x))
        print("DEBUG: Tile_XYZ.y = " .. tostring(bestTree.Tile_XYZ.y))
        print("DEBUG: Tile_XYZ.z = " .. tostring(bestTree.Tile_XYZ.z))
    else
        print("DEBUG: Tile_XYZ = nil")
    end
    if bestTree.Pixel_XYZ then
        print("DEBUG: Pixel_XYZ.x = " .. tostring(bestTree.Pixel_XYZ.x))
        print("DEBUG: Pixel_XYZ.y = " .. tostring(bestTree.Pixel_XYZ.y))
        print("DEBUG: Pixel_XYZ.z = " .. tostring(bestTree.Pixel_XYZ.z))
    else
        print("DEBUG: Pixel_XYZ = nil")
    end
    print("DEBUG: ================================")
    ]]
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

return FUNC
