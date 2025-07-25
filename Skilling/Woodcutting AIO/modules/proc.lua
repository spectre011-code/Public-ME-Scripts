-- Procedures for Spectre011's Woodcutter AIO

local API = require("api")
local Slib = require("Woodcutting AIO.modules.slib")
local LODESTONES = require("Woodcutting AIO.modules.lodestones")
local FUNC = require("Woodcutting AIO.modules.func")
local DATA = require("Woodcutting AIO.modules.data")
local AURAS = require("Woodcutting AIO.modules.auras")
local BANK = require("Woodcutting AIO.modules.bank")

PROC = {}

local CanRenewal = {
    beaver = nil,
    crystalize = nil,
    cadantineStick = nil,
    guamStick = nil,
    torstolStick = nil,
    sharpeningStone = nil,
    imbuedBirdFeed = nil,
    lumberjacksCourage = nil, 
}

function PROC:HandleStartingState(config)
    Slib:Info("Current state: STARTING")
    local auraToUse = string.lower(config.Aura)
    Slib:Info("Aura to use: " .. auraToUse)
    FUNC:PrintConfig(config)

    -- Set all CanRenewal values to true
    CanRenewal.beaver = true
    CanRenewal.crystalize = true --Outlier, as is not a player buff
    CanRenewal.cadantineStick = true
    CanRenewal.guamStick = true
    CanRenewal.torstolStick = true
    CanRenewal.sharpeningStone = true
    CanRenewal.imbuedBirdFeed = true
    CanRenewal.lumberjacksCourage = true
    
    return "MOVING_TO_TREES"
end

function PROC:HandleMovingToTreesState(config)
    Slib:Info("Current state: MOVING_TO_TREES")

    -- Set all CanRenewal values to true
    CanRenewal.beaver = true
    CanRenewal.crystalize = true --Outlier, as is not a player buff
    CanRenewal.cadantineStick = true
    CanRenewal.guamStick = true
    CanRenewal.torstolStick = true
    CanRenewal.sharpeningStone = true
    CanRenewal.imbuedBirdFeed = true
    CanRenewal.lumberjacksCourage = true

    if config.Tree == "None" then
        Slib:Warn("Tree: No tree selected")

        return "ERROR"

    elseif config.Tree == "Regular tree - North of Burthorpe" then
        Slib:Info("Tree: Regular tree - North of Burthorpe")
        LODESTONES.BURTHOPE.Teleport()

        return "AT_TREES"

    elseif config.Tree == "Regular tree - North of Draynor" then
        Slib:Info("Tree: Regular tree - North of Draynor")
        if not Slib:IsPlayerInArea(3123, 3309, 0, 30) then
            LODESTONES.DRAYNOR_VILLAGE.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3123, 2), FUNC:GetRandomNumber(3309, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Regular tree - South of GE" then
        Slib:Info("Tree: Regular tree - South of GE")
        if not Slib:IsPlayerInArea(3135, 3423, 0, 30) then
            LODESTONES.VARROCK.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3154, 2), FUNC:GetRandomNumber(3455, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Regular tree - Woodcutter grove" then
        Slib:Info("Tree: Regular tree - Woodcutter grove")
        if not Slib:IsPlayerInArea(3370, 3542, 0, 60) then
            LODESTONES.FORT_FORINTHRY.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3370, 2), FUNC:GetRandomNumber(3542, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Oak tree - East of Draynor" then
        Slib:Info("Tree: Oak tree - East of Draynor")
        if not Slib:IsPlayerInArea(3117, 3255, 0, 15) then
            LODESTONES.DRAYNOR_VILLAGE.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3117, 2), FUNC:GetRandomNumber(3255, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Oak tree - South of GE" then
        Slib:Info("Tree: Oak tree - South of GE")
        if not Slib:IsPlayerInArea(3163, 3413, 0, 15) then
            LODESTONES.VARROCK.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3163, 2), FUNC:GetRandomNumber(3413, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Oak tree - South of Varrock" then
        Slib:Info("Tree: Oak tree - South of Varrock")
        if not Slib:IsPlayerInArea(3205, 3354, 0, 15) then
            LODESTONES.VARROCK.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3205, 2), FUNC:GetRandomNumber(3354, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Oak tree - Woodcutter grove" then
        Slib:Info("Tree: Oak tree - Woodcutter grove")
        if not Slib:IsPlayerInArea(3370, 3542, 0, 60) then
            LODESTONES.FORT_FORINTHRY.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3370, 2), FUNC:GetRandomNumber(3542, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Willow tree - South of Draynor" then
        Slib:Info("Tree: Willow tree - South of Draynor")
        if not Slib:IsPlayerInArea(3090, 3223, 0, 30) then
            LODESTONES.DRAYNOR_VILLAGE.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3090, 2), FUNC:GetRandomNumber(3223, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Willow tree - Woodcutter grove" then
        Slib:Info("Tree: Willow tree - Woodcutter grove")
        if not Slib:IsPlayerInArea(3370, 3542, 0, 60) then
            LODESTONES.FORT_FORINTHRY.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3370, 2), FUNC:GetRandomNumber(3542, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Teak tree - Karamja" then
        Slib:Info("Tree: Teak tree - Karamja")
        if Slib:IsPlayerInRectangle(2817, 2829, 3076, 3090, 0) then
            return "AT_TREES"
        elseif Slib:IsPlayerInArea(2814, 3083, 0, 2) then
            Interact:Object("Hardwood grove doors", "Quick-pay(100)")
            Slib:RandomSleep(3000, 5000, "ms")
            return "MOVING_TO_TREES"
        else
            LODESTONES.KARAMJA.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(2815, 1), FUNC:GetRandomNumber(3083, 1), 0)
            return "MOVING_TO_TREES"
        end
    elseif config.Tree == "Maple tree - North of Seer's Village" then
        Slib:Info("Tree: Maple tree - North of Seer's Village")
        if not Slib:IsPlayerInArea(2724, 3501, 0, 30) then
            LODESTONES.SEERS_VILLAGE.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(2724, 2), FUNC:GetRandomNumber(3501, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Acadia tree - Menaphos Imperial District" then
        Slib:Info("Tree: Acadia tree - Menaphos Imperial District")
        if not Slib:IsPlayerInRectangle(3172, 3197, 2703, 2737, 0) then
            LODESTONES.MENAPHOS.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3183, 2), FUNC:GetRandomNumber(2719, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Acadia tree - Menaphos VIP area" then
        Slib:Info("Tree: Acadia tree - Menaphos VIP area")
        if Slib:IsPlayerInRectangle(3180, 3192, 2740, 2757, 0) then
            return "AT_TREES"
        elseif Slib:IsPlayerInArea(3186, 2738, 0, 1) then
            Interact:Object("VIP archway", "Go through", 10)
            Slib:RandomSleep(3000, 5000, "ms")
            return "MOVING_TO_TREES"
        else
            LODESTONES.MENAPHOS.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3186, 1), FUNC:GetRandomNumber(2738, 1), 0)
            return "MOVING_TO_TREES"
        end
    elseif config.Tree == "Eucaliptus trees - West of Oo'glog" then
        Slib:Info("Tree: Eucaliptus trees - West of Oo'glog")
        if not Slib:IsPlayerInArea(2507, 2863, 0, 30) then
            LODESTONES.OOGLOG.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(2507, 2), FUNC:GetRandomNumber(2863, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Mahogany trees - Karamja" then
        Slib:Info("Tree: Mahogany trees - Karamja")
        if Slib:IsPlayerInRectangle(2817, 2829, 3076, 3090, 0) then
            return "AT_TREES"
        elseif Slib:IsPlayerInArea(2814, 3083, 0, 2) then
            Interact:Object("Hardwood grove doors", "Quick-pay(100)")
            Slib:RandomSleep(3000, 5000, "ms")
            return "MOVING_TO_TREES"
        else
            LODESTONES.KARAMJA.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(2815, 1), FUNC:GetRandomNumber(3083, 1), 0)
            return "MOVING_TO_TREES"
        end
    elseif config.Tree == "Ivy - falador north wall" then
        Slib:Info("Tree: Ivy - falador north wall")
        if not Slib:IsPlayerInRectangle(3011, 3018, 3393, 3398, 0) then
            LODESTONES.FALADOR.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3014, 2), FUNC:GetRandomNumber(3395, 2), 0)
        end

        Slib:Info("DEBUG: IsPlayerInRectangle returned true")
        return "AT_TREES"

    elseif config.Tree == "Ivy - falador south wall" then
        Slib:Info("Tree: Ivy - falador south wall")
        if not Slib:IsPlayerInRectangle(3044, 3052, 3323, 3327, 0) then
            LODESTONES.FALADOR.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3048, 2), FUNC:GetRandomNumber(3325, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Ivy - Taverley east wall" then
        Slib:Info("Tree: Ivy - Taverley east wall")
        Slib:Info(tostring(Slib:IsPlayerInArea(2937, 3427, 0, 5)))
        if not Slib:IsPlayerInArea(2937, 3427, 0, 5) then
            LODESTONES.TAVERLEY.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(2937, 2), FUNC:GetRandomNumber(3427, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Ivy - Varrock east castle wall" then
        Slib:Info("Tree: Ivy - Varrock east castle wall")
        if not Slib:IsPlayerInRectangle(3231, 3233, 3456, 3462, 0) then
            LODESTONES.VARROCK.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3232, 2), FUNC:GetRandomNumber(3459, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Ivy - Woodcutter grove" then
        Slib:Info("Tree: Ivy - Woodcutter grove")
        if not Slib:IsPlayerInArea(3342, 3557, 0, 6) then
            LODESTONES.FORT_FORINTHRY.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3342, 2), FUNC:GetRandomNumber(3557, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Magic tree - North east of Ardougne" then
        Slib:Info("Tree: Magic tree - North east of Ardougne")
        if not Slib:IsPlayerInRectangle(2697, 2707, 3393, 3400, 0) then
            LODESTONES.ARDOUGNE.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(2702, 2), FUNC:GetRandomNumber(3396, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Elder tree - South of Draynor" then
        Slib:Info("Tree: Elder tree - South of Draynor")
        if not Slib:IsPlayerInArea(3100, 3215, 0, 30) then
            LODESTONES.DRAYNOR_VILLAGE.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3102, 2), FUNC:GetRandomNumber(3214, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Elder tree - South of Yanille" then
        Slib:Info("Tree: Elder tree - South of Yanille")
        if not Slib:IsPlayerInArea(2571, 3061, 0, 30) then
            LODESTONES.YANILLE.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(2571, 2), FUNC:GetRandomNumber(3061, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Elder tree - Woodcutter grove" then
        Slib:Info("Tree: Elder tree - Woodcutter grove")
        if not Slib:IsPlayerInArea(3370, 3542, 0, 60) then
            LODESTONES.FORT_FORINTHRY.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3370, 2), FUNC:GetRandomNumber(3542, 2), 0)
        end

        return "AT_TREES"

    elseif config.Tree == "Eternal magic tree - North of Eagle's Peak" then
        Slib:Info("Tree: Eternal magic tree - North of Eagle's Peak")
        if not Slib:IsPlayerInArea(2331, 3587, 0, 30) then
            LODESTONES.EAGLES_PEAK.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(2327, 2), FUNC:GetRandomNumber(3593, 2), 0)
        end

        return "AT_TREES"
    else
        Slib:Error("Tree: Unknown tree type - " .. tostring(config.Tree))
        return "ERROR"
    end

    Slib:Error("Should not be here. AT_TREES state config.Tree: " .. tostring(config.Tree))
    return "ERROR"
end

function PROC:HandleAtTreesState(config)
    Slib:Info("Current state: AT_TREES")

    --Start upkeep buffs

    if config.Beaver == true or config.Beaver == "true" then
        if CanRenewal.beaver then
            if not API.Buffbar_GetIDstatus(DATA.BUFFS["Beaver"], false).found then
                if not API.DoAction_Inventory2(DATA.ITEMS["Super restore"], 0, 1, API.OFF_ACT_GeneralInterface_route) then
                    Slib:Warn("No super restore found in inventory.")
                    CanRenewal.beaver = false
                else
                    Slib:RandomSleep(100, 200, "ms")
                    API.DoAction_Inventory1(DATA.ITEMS["Beaver"],0,1,API.OFF_ACT_GeneralInterface_route)
                end
            end
        end
    end

    if config.CadantineStick == true or config.CadantineStick == "true" then
        if CanRenewal.cadantineStick then
            if not Inventory:Contains(DATA.BUFFS["Cadantine incense sticks"]) then
                Slib:Warn("No cadantine incense sticks found in inventory.")
                CanRenewal.cadantineStick = false
            else
                Slib:CheckIncenseStick(DATA.BUFFS["Cadantine incense sticks"])
            end
        end
    end

    if config.GuamStick == true or config.GuamStick == "true" then
        if CanRenewal.guamStick then
            if not Inventory:Contains(DATA.BUFFS["Guam incense sticks"]) then
                Slib:Warn("No guam incense sticks found in inventory.")
                CanRenewal.guamStick = false
            else
                Slib:CheckIncenseStick(DATA.BUFFS["Guam incense sticks"])
            end
        end
    end

    if config.TorstolStick == true or config.TorstolStick == "true" then
        if CanRenewal.torstolStick then
            if not Inventory:Contains(DATA.BUFFS["Torstol incense sticks"]) then
                Slib:Warn("No torstol incense sticks found in inventory.")
                CanRenewal.torstolStick = false
            else
                Slib:CheckIncenseStick(DATA.BUFFS["Torstol incense sticks"])
            end
        end
    end

    if config.SharpeningStone == true or config.SharpeningStone == "true" then
        if CanRenewal.sharpeningStone then
            if not Inventory:Contains(DATA.ITEMS["Sharpening stone"]) then
                Slib:Warn("No sharpening stone found in inventory.")
                CanRenewal.sharpeningStone = false
            else
                if not API.Buffbar_GetIDstatus(DATA.BUFFS["Sharpening stone"], false).found then
                    API.DoAction_Inventory1(DATA.ITEMS["Sharpening stone"],0,1,API.OFF_ACT_GeneralInterface_route)
                    Slib:RandomSleep(100, 200, "ms")
                end
            end
        end
    end

    if config.ImbuedBirdFeed == true or config.ImbuedBirdFeed == "true" then
        if CanRenewal.imbuedBirdFeed then
            if not Inventory:Contains(DATA.ITEMS["Imbued bird feed"]) then
                Slib:Warn("No imbued bird feed found in inventory.")
                CanRenewal.imbuedBirdFeed = false
            else
                if not API.Buffbar_GetIDstatus(DATA.BUFFS["Imbued bird feed"], false).found then
                    API.DoAction_Inventory1(DATA.ITEMS["Imbued bird feed"],0,1,API.OFF_ACT_GeneralInterface_route)
                    Slib:RandomSleep(100, 200, "ms")
                end 
            end
        end
    end

    if config.LumberjacksCourage == true or config.LumberjacksCourage == "true" then
        if CanRenewal.lumberjacksCourage then
            if not Inventory:Contains(DATA.ITEMS["Lumberjack's courage"]) then
                Slib:Warn("No lumberjack's courage found in inventory.")
                CanRenewal.lumberjacksCourage = false
            else
                if not API.Buffbar_GetIDstatus(DATA.BUFFS["Lumberjack's courage"], false).found then
                    API.DoAction_Inventory1(DATA.ITEMS["Lumberjack's courage"],0,1,API.OFF_ACT_GeneralInterface_route)
                    Slib:RandomSleep(100, 200, "ms")
                end
            end
        end
    end
    
    --End upkeep buffs

    if config.Tree == "Eternal magic tree - North of Eagle's Peak" then
        local Highlight = Slib:FindObj({8447}, 25, {4})
        if Highlight and not Slib:IsPlayerInArea(Highlight.Tile_XYZ.x, Highlight.Tile_XYZ.y, 0, 1) then
            Slib:WalkToCoordinates(math.floor(Highlight.Tile_XYZ.x), math.floor(Highlight.Tile_XYZ.y), 0)
            Slib:RandomSleep(1000, 2000, "ms")
        end
    end

    --Start action skipping
    if API.IsPlayerAnimating_(API.GetLocalPlayerName(), 10) then
        return "AT_TREES"
    end

    if API.IsPlayerMoving_(API.GetLocalPlayerName()) then
        return "AT_TREES"
    end

    --End action skipping

    if config.Aura ~= "None" and not AURAS.noResets then
        if not AURAS.isAuraActive() then
            AURAS.activateAura(config.Aura)
            return "AT_TREES"
        end
    end

    if Inventory:IsFull() then
        Slib:Info("Inventory is full")
        if not FUNC:GetWoodBox() then
            Slib:Warn("No wood box found")
            return "MOVING_TO_BANK"
        end
        
        if not FUNC:isWoodBoxFull(config) then
            Slib:Info("Wood box is not full")
            API.DoAction_Inventory1(FUNC:GetWoodBox().id,0,1,API.OFF_ACT_GeneralInterface_route)
            Slib:RandomSleep(1000, 2000, "ms")
            return "AT_TREES"
        end
        return "MOVING_TO_BANK"
    end

    local BestTree = FUNC:GetBestTree(CONFIG)    
    if BestTree then
        Slib:Info("BestTree = " .. tostring(BestTree.Name))
        if config.Crystalize == true or config.Crystalize == "true" then
            API.DoAction_Interface(0xffffffff,0xffffffff,0,1461,1,181,API.OFF_ACT_Bladed_interface_route)
            Slib:RandomSleep(100, 200, "ms")
            API.DoAction_Object2(0x9d,API.OFF_ACT_GeneralObject_route00,{BestTree.Id},50,WPOINT.new(BestTree.CalcX, BestTree.CalcY, 0))
            Slib:RandomSleep(100, 200, "ms")
        end

        Slib:Info("Cutting tree: " .. BestTree.Name)
        
        local actionResult
        if string.find(BestTree.Name:lower(), "ivy") then
            -- Use ivy-specific action
            actionResult = API.DoAction_Object2(0x3b,API.OFF_ACT_GeneralObject_route0,{ BestTree.Id },50,WPOINT.new(BestTree.Tile_XYZ.x, BestTree.Tile_XYZ.y, BestTree.Tile_XYZ.z))
        else
            -- Use regular tree action
            actionResult = API.DoAction_Object2(0x3b,API.OFF_ACT_GeneralObject_route0,{ BestTree.Id },50,WPOINT.new(BestTree.Tile_XYZ.x, BestTree.Tile_XYZ.y, BestTree.Tile_XYZ.z))
        end
        if not actionResult then
            Slib:Warn("DEBUG: DoAction_Object2 returned false!")
            Slib:Warn("DEBUG: BestTree.Id = " .. tostring(BestTree.Id))
            Slib:Warn("DEBUG: BestTree.CalcX = " .. tostring(BestTree.CalcX))
            Slib:Warn("DEBUG: BestTree.CalcY = " .. tostring(BestTree.CalcY))
            Slib:Warn("DEBUG: BestTree.Name = " .. tostring(BestTree.Name))
            Slib:Warn("DEBUG: BestTree.Action = " .. tostring(BestTree.Action))
            Slib:Warn("DEBUG: BestTree.Distance = " .. tostring(BestTree.Distance))
            Slib:Warn("DEBUG: BestTree.Bool1 = " .. tostring(BestTree.Bool1))
            Slib:Warn("DEBUG: Max distance = 50")
            Slib:Warn("DEBUG: WPOINT = (" .. BestTree.CalcX .. ", " .. BestTree.CalcY .. ", 0)")
        end
        Slib:RandomSleep(1000, 5000, "ms")
        return "AT_TREES"
    else
        Slib:Warn("No best tree found")
        Slib:RandomSleep(1000, 5000, "ms")
        return "MOVING_TO_TREES"
    end

end

function PROC:HandleMovingToBankState(config)
    Slib:Info("Current state: MOVING_TO_BANK")

    if config.Bank == "Drop logs" then
        Slib:Info("Bank: Drop logs")
        for _, log in pairs(DATA.LOGS) do
            while API.Read_LoopyLoop() and BANK:InventoryContains(log.id) do
                Inventory:Drop(log.id)
                Slib:RandomSleep(400, 600, "ms")
            end
        end

        for _, nest in pairs(DATA.NESTS) do
            while API.Read_LoopyLoop() and BANK:InventoryContains(nest.id) do
                Inventory:Drop(nest.id)
                Slib:RandomSleep(400, 600, "ms")
            end
        end

    elseif config.Bank == "Burthorpe" then
        Slib:Info("Bank: Burthorpe")
        if not Slib:FindObj2(19086, 50, 1, 2886, 3535, 1) then --gnome banker
            LODESTONES.BURTHOPE.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(2888, 1), FUNC:GetRandomNumber(3536, 1), 0)           
        else
            if not Slib:IsPlayerInArea(2888, 3536, 0, 5) then
                Slib:MoveTo(FUNC:GetRandomNumber(2888, 1), FUNC:GetRandomNumber(3536, 1), 0)
            else
                return "AT_BANK"
            end
        end

        return "MOVING_TO_BANK"

    elseif config.Bank == "Draynor" then
        Slib:Info("Bank: Draynor")
        if not Slib:FindObj2(4459, 50, 1, 3090, 3241, 2) then -- banker
            LODESTONES.DRAYNOR_VILLAGE.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3093, 1), FUNC:GetRandomNumber(3243, 1), 0)
        else
            if not Slib:IsPlayerInArea(3093, 3241, 0, 5) then
                Slib:MoveTo(FUNC:GetRandomNumber(3093, 1), FUNC:GetRandomNumber(3241, 1), 0)
            else
                return "AT_BANK"
            end
        end

        return "MOVING_TO_BANK"

    elseif config.Bank == "Varrock west bank" then
        Slib:Info("Bank: Varrock west bank")
        if not Slib:FindObj2(2759, 50, 1, 3180, 3433, 2) then -- banker
            LODESTONES.VARROCK.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3185, 1), FUNC:GetRandomNumber(3439, 1), 0)
        else
            if not Slib:IsPlayerInRectangle(3182, 3189, 3436, 3443, 0) then
                Slib:MoveTo(FUNC:GetRandomNumber(3185, 1), FUNC:GetRandomNumber(3439, 1), 0)
            else
                return "AT_BANK"
            end
        end
    elseif config.Bank == "Woodcutters grove - Log pile" then
        Slib:Info("Bank: Woodcutters grove - Log pile")
        if not Slib:FindObj(125466, 50, 0) then -- log pile
            LODESTONES.FORT_FORINTHRY.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3370, 2), FUNC:GetRandomNumber(3542, 2), 0)
        else
            return "AT_BANK"
        end

        return "MOVING_TO_BANK"

    elseif config.Bank == "Seer's village" then
        Slib:Info("Bank: Seer's village")
        if not Slib:FindObj2(494, 50, 1, 2724, 3495, 2) then -- banker
            LODESTONES.SEERS_VILLAGE.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(2726, 1), FUNC:GetRandomNumber(3492, 1), 0)
        else
            if not Slib:IsPlayerInRectangle(2721, 2730, 3490, 3493, 0) then
                Slib:MoveTo(FUNC:GetRandomNumber(2726, 1), FUNC:GetRandomNumber(3492, 1), 0)
            else
                return "AT_BANK"
            end
        end

        return "MOVING_TO_BANK"

    elseif config.Bank == "Menaphos VIP area - Bank chest" then
        Slib:Info("Bank: Menaphos VIP area - Bank chest")
        if not Slib:FindObj2(107737, 50, 12, 3182, 2741, 14) then -- chest
            LODESTONES.MENAPHOS.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3186, 1), FUNC:GetRandomNumber(2737, 1), 0)
        else
            if Slib:IsPlayerInRectangle(3180, 3192, 2740, 2757, 0) then
                Slib:MoveTo(FUNC:GetRandomNumber(3182, 1), FUNC:GetRandomNumber(2743, 1), 0)
                return "AT_BANK"
            elseif Slib:IsPlayerInArea(3186, 2738, 0, 1) then
                Interact:Object("VIP archway", "Go through", 10)
                Slib:RandomSleep(3000, 5000, "ms")
                return "MOVING_TO_BANK"
            else
                Slib:MoveTo(FUNC:GetRandomNumber(3186, 1), FUNC:GetRandomNumber(2737, 1), 0)
                return "MOVING_TO_BANK"
            end
        end

        return "MOVING_TO_BANK"

    elseif config.Bank == "Menaphos Imperial District" then
        Slib:Info("Bank: Menaphos Imperial District")
        if not Slib:FindObj2(107493, 50, 0, 3172, 2705, 15) then -- chest
            LODESTONES.MENAPHOS.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(3174, 1), FUNC:GetRandomNumber(2705, 1), 0)
        else
            if Slib:IsPlayerInArea(3173, 2705, 0, 3) then
                return "AT_BANK"
            else
                Slib:MoveTo(FUNC:GetRandomNumber(3174, 1), FUNC:GetRandomNumber(2705, 1), 0)
                return "MOVING_TO_BANK"
            end
        end

        return "MOVING_TO_BANK"

    elseif config.Bank == "Oo'glog" then
        Slib:Info("Bank: Oo'glog")
        if not Slib:FindObj2(7049, 50, 1, 2554, 2840, 2) then -- ogress banker
            LODESTONES.OOGLOG.Teleport()
            Slib:MoveTo(FUNC:GetRandomNumber(2557, 1), FUNC:GetRandomNumber(2839, 1), 0)
        else
            if Slib:IsPlayerInRectangle(2556, 2559, 2836, 2841, 0) then
                return "AT_BANK"
            else
                Slib:MoveTo(FUNC:GetRandomNumber(2557, 1), FUNC:GetRandomNumber(2839, 1), 0)
                return "MOVING_TO_BANK"
            end
        end

        return "MOVING_TO_BANK"

    elseif config.Bank == "Guthix Memorial" then
        Slib:Info("Bank: Guthix Memorial")
        if not Slib:IsPlayerInArea(2280, 3557, 0, 5) then
            Slib:MemoryStrandTeleport()
            Slib:MoveTo(FUNC:GetRandomNumber(2280, 1), FUNC:GetRandomNumber(3557, 1), 0)
            return "MOVING_TO_BANK"
        else
            return "AT_BANK"
        end

    elseif config.Bank == "Wars retreat" then
        Slib:Info("Bank: Wars retreat")
        --35042 wars retreat teleport
        if not FUNC:IsSkillInAbBar(35042) then
            Slib:Error("Wars retreat teleport not found")
            return "ERROR"
        end

        if not Slib:FindObj(26773, 50, 1) then --war
            Slib:UseAbilityById(35042)
            Slib:SleepUntil(function() 
                return Slib:FindObj(26773, 50, 1)
            end, 10, 100)
            return "MOVING_TO_BANK"
        else
            if Slib:IsPlayerInRectangle(3298, 3301, 10129, 10132, 0) then
                return "AT_BANK"
            else
                Slib:MoveTo(FUNC:GetRandomNumber(3299, 1), FUNC:GetRandomNumber(10130, 1), 0)
                return "MOVING_TO_BANK"
            end
        end

    elseif config.Bank == "Max guild" then
        Slib:Info("Bank: Max guild")
        --12531 max guild teleport
        if not FUNC:IsSkillInAbBar(12531) then
            Slib:Error("Max guild teleport not found")
            return "ERROR"
        end

        if not Slib:FindObj2(19918, 50, 1, 2276, 3310, 20) then --banker
            Slib:UseAbilityById(12531)
            Slib:SleepUntil(function() 
                return Slib:FindObj2(19918, 50, 1, 2276, 3310, 20)
            end, 10, 100)
            Slib:RandomSleep(2000, 3000, "ms") --fade animation
            return "MOVING_TO_BANK"
        else
            if Slib:IsPlayerInArea(2276, 3312, 1, 1) then
                return "AT_BANK"
            else
                Slib:MoveTo(FUNC:GetRandomNumber(2276, 1), FUNC:GetRandomNumber(3312, 1), 0)
                return "MOVING_TO_BANK"
            end
        end
    else
        Slib:Error("Bank: Unknown bank type - " .. tostring(config.Bank))
        return "ERROR"
    end

    return "AT_BANK"
end

function PROC:HandleAtBankState(config)
    Slib:Info("Current state: AT_BANK")

    if config.Bank == "Drop logs" then
        Slib:Info("Banking: Dropping logs")
        for _, log in pairs(DATA.LOGS) do
            while API.Read_LoopyLoop() and BANK:InventoryContains(log.id) do
                Inventory:Drop(log.id)
                Slib:RandomSleep(400, 600, "ms")
            end
        end

        for _, nest in pairs(DATA.NESTS) do
            while API.Read_LoopyLoop() and BANK:InventoryContains(nest.id) do
                Inventory:Drop(nest.id)
                Slib:RandomSleep(400, 600, "ms")
            end
        end
        return "MOVING_TO_TREES"
    end

    if config.Bank == "Woodcutters grove - Log pile" then
        Slib:Info("Bank: Woodcutters grove - Log pile")
        Interact:Object("Log Pile", "Deposit Logs", 100)
        Slib:RandomSleep(1000, 2000, "ms")
    else
        if FUNC:GetWoodBox() ~= nil then
            BANK:Open()
            Slib:SleepUntil(function()
                return BANK:IsOpen()
            end, 30, 100)
            Slib:RandomSleep(1000, 2000, "ms")
            local id, slot = FUNC:GetWoodBoxHexIdAndSlot()
            API.DoAction_Interface(0xffffffff,id,8,517,15,slot,API.OFF_ACT_GeneralInterface_route2)
        else
            Slib:Warn("No wood box found")
        end

        if config.RegularJuju == true or config.RegularJuju == "true" then
            if not BANK:IsOpen() then
                BANK:Open()
                Slib:SleepUntil(function()
                    return BANK:IsOpen()
                end, 30, 100)
                Slib:RandomSleep(1000, 2000, "ms")
            end
                
            if BANK:ContainsAny(DATA.ITEMS["Regular Juju"]) then
                local juju = FUNC:GetRegularJuju()
                BANK:SetNoteMode(false)
                BANK:Withdraw1(juju)
                Slib:RandomSleep(1000, 2000, "ms")
                BANK:Close()
                Slib:RandomSleep(1000, 2000, "ms")
                API.DoAction_Inventory1(juju, 0, 1, API.OFF_ACT_GeneralInterface_route)
                Slib:RandomSleep(1000, 2000, "ms")
            else
                Slib:Warn("No regular juju found in bank")
            end
        end

        if config.PerfectJuju == true or config.PerfectJuju == "true" then
            if not BANK:IsOpen() then
                BANK:Open()
                Slib:SleepUntil(function()
                    return BANK:IsOpen()
                end, 30, 100)
                Slib:RandomSleep(1000, 2000, "ms")
            end

            if BANK:ContainsAny(DATA.ITEMS["Perfect Juju"]) then
                local juju = FUNC:GetPerfectJuju()
                BANK:SetNoteMode(false)
                BANK:Withdraw1(juju)
                Slib:RandomSleep(1000, 2000, "ms")
                BANK:Close()
                Slib:RandomSleep(1000, 2000, "ms")
                API.DoAction_Inventory1(juju, 0, 1, API.OFF_ACT_GeneralInterface_route)
                Slib:RandomSleep(1000, 2000, "ms")
            else
                Slib:Warn("No perfect juju found in bank")
            end
        end

        if config.PerfectPlus == true or config.PerfectPlus == "true" then
            if not BANK:IsOpen() then
                BANK:Open()
                Slib:SleepUntil(function()
                    return BANK:IsOpen()
                end, 30, 100)
                Slib:RandomSleep(1000, 2000, "ms")
            end
                
            if BANK:ContainsAny(DATA.ITEMS["Perfect Plus"]) then
                local perfectPlus = FUNC:GetPerfectPlus()
                BANK:SetNoteMode(false)
                BANK:Withdraw1(perfectPlus)
                Slib:RandomSleep(1000, 2000, "ms")
                BANK:Close()
                Slib:RandomSleep(1000, 2000, "ms")
                API.DoAction_Inventory1(perfectPlus, 0, 1, API.OFF_ACT_GeneralInterface_route)
                Slib:RandomSleep(1000, 2000, "ms")
            else
                Slib:Warn("No perfect plus found in bank")
            end
        end

        if config.Gote == true or config.Gote == "true" then
            while API.Read_LoopyLoop() and (FUNC:GetGOTECharges() <= (FUNC:GetGOTEMaxCharges() - 50)) do
                Slib:Info("GOTE Charges: " .. tostring(FUNC:GetGOTECharges()))
                Slib:Info("GOTE Max Charges: " .. tostring(FUNC:GetGOTEMaxCharges()))
                BANK:Open()
                Slib:SleepUntil(function()
                    return BANK:IsOpen()
                end, 30, 100)
                Slib:RandomSleep(1000, 2000, "ms")
                BANK:SetNoteMode(false)
                BANK:DepositEquipment()
                BANK:DepositInventory()
                Slib:RandomSleep(1000, 2000, "ms")
                BANK:Withdraw1(DATA.ITEMS["GOTE"])
                local signOfThePorter = FUNC:GetSignOfThePorter()  
                if BANK:ContainsAny(DATA.ITEMS["Sign of the Porter"]) then      
                    BANK:WithdrawAll(signOfThePorter)
                    BANK:Close()
                    Slib:RandomSleep(1000, 2000, "ms")
                else
                    Slib:Warn("No sign of the porter found in bank")
                    BANK:LoadLastPreset()
                    Slib:RandomSleep(1000, 5000, "ms")
                    return "MOVING_TO_TREES"
                end
                Inventory:UseItemOnItem(signOfThePorter, DATA.ITEMS["GOTE"][1])
                Slib:SleepUntil(function()
                    return FUNC:GOTEInterfaceIsOpen()
                end, 5, 100)
                Slib:RandomSleep(1000, 2000, "ms")
                API.DoAction_Interface(0xffffffff,0xffffffff,0,847,22,-1,API.OFF_ACT_GeneralInterface_Choose_option) --Use all
                Slib:RandomSleep(1000, 2000, "ms")
            end
        end

        BANK:LoadLastPreset()
        Slib:RandomSleep(1000, 5000, "ms")
    end

    return "MOVING_TO_TREES"
end

return PROC