local ScriptName = "Spectre's Bank Evaluator"
local Author = "Spectre011"
local ScriptVersion = "1.1.0"
local ReleaseDate = "26-07-2025"
local DiscordHandle = "not_spectre011"

--[[
╔═════════════════════════════════════════════════════════════════════════════╗
║                           BANK EVALUATOR                                    ║
╠═════════════════════════════════════════════════════════════════════════════╣
║  Description: Scans all bank items and exports item data to CSV             ║
║  Usage:       Have bank open and execute script                             ║
║  Output:      CSV file with item ID, name, stack size, unit value and total ║
╚═════════════════════════════════════════════════════════════════════════════╝
]]

--[[
Changelog:
v1.0.0 - 26-07-2025
    - Initial release.
v1.1.0 - 26-07-2025
    - Added support for augmented items.
]]

local API = require("api")
local BANK = require("bank")
local Slib = require("slib")

-- Gets current player name with safety fallback
---@return string PlayerName The player name or "Unknown_Player" if not available
local function GetSafePlayerName()
    local PlayerName = API.GetLocalPlayerName()
    
    -- Safety check for empty or nil player name
    if not PlayerName or PlayerName == "" or PlayerName == " " then
        return "Unknown_Player"
    end
    
    -- Remove any characters that aren't safe for filenames
    PlayerName = string.gsub(PlayerName, "[<>:\"/\\|?*]", "_")
    
    return PlayerName
end

-- Generates filename with player name and current date
---@return string Filename The formatted filename with player name and date
local function GenerateFilename()
    local PlayerName = GetSafePlayerName()
    local DateString = os.date("%Y-%m-%d_%H-%M-%S")
    
    return "Bank_Evaluation_" .. PlayerName .. "_" .. DateString .. ".csv"
end

-- Configuration for output settings
local Config = {
    OutputDirectory = os.getenv("USERPROFILE") .. "\\MemoryError\\Lua_Scripts\\exports\\BankEvaluator\\",
    OutputFilename = GenerateFilename()
}

-- Gets item data using the same approach as Slib:PrintContainer
---@param Item table The item object from the container
---@return table ItemInfo Table containing name and tradeable status
local function GetItemData(Item)
    local DefaultData = {
        Name = "Unknown",
        Tradeable = false
    }
    
    if not Item or not Item.item_id or Item.item_id < 0 then
        return DefaultData
    end
    
    local ItemData = nil
    
    -- Try to get item data using Item.Get method (same as Slib:PrintContainer)
    if Item and Item.Get then
        local Success, Data = pcall(Item.Get, Item, Item.item_id)
        if Success and Data then
            ItemData = Data
        end
    elseif _G.Item and _G.Item.Get then
        local Success, Data = pcall(_G.Item.Get, _G.Item, Item.item_id)
        if Success and Data then
            ItemData = Data
        end
    end
    
    if ItemData then
        return {
            Name = ItemData.name or "Unknown",
            Tradeable = ItemData.tradeable or false
        }
    end
    
    return DefaultData
end

-- Searches for tradeable version of an item using cache when equipped items have no GE value
---@param ItemName string The name of the item to search for
---@param OriginalItemId number The original item ID for fallback
---@return number GeValue The GE value of the tradeable version, or 0 if not found
local function GetTradeableAlternativeValue(ItemName, OriginalItemId)
    -- Only search if we have a valid item name
    if not ItemName or ItemName == "Unknown" or ItemName == "" then
        return 0
    end
    
    -- Special handling for augmented items - try to find base item value
    if string.sub(ItemName, 1, 10) == "Augmented " then
        local BaseItemName = string.sub(ItemName, 11) -- Remove "Augmented " prefix
        
        Slib:Info("Detected augmented item: '" .. ItemName .. "', searching for base item: '" .. BaseItemName .. "'")
        
        -- Try to find the base item by name
        local BaseSearchResults = nil
        if _G.Item and _G.Item.GetAll then
            local Success, Results = pcall(_G.Item.GetAll, _G.Item, BaseItemName, false) -- exact_match = false for flexibility
            if Success and Results then
                BaseSearchResults = Results
            end
        end
        
        if BaseSearchResults then
            -- Look for exact or close match to base item name
            for _, ResultItem in ipairs(BaseSearchResults) do
                if ResultItem and ResultItem.id and ResultItem.id ~= OriginalItemId then
                    -- Check for exact match or very close match
                    if ResultItem.name == BaseItemName or 
                       (ResultItem.name and string.find(ResultItem.name:lower(), BaseItemName:lower(), 1, true)) then
                        if ResultItem.tradeable then
                            local GeValue = API.GetExchangePrice(ResultItem.id)
                            if GeValue and GeValue > 0 then
                                Slib:Info("Found base item for augmented item '" .. ItemName .. "': '" .. ResultItem.name .. "' ID " .. ResultItem.id .. " (Value: " .. GeValue .. " GP)")
                                return GeValue
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Fallback: Use general search for similar items by name
    local SearchResults = nil
    if _G.Item and _G.Item.GetAll then
        local Success, Results = pcall(_G.Item.GetAll, _G.Item, ItemName, true) -- partial_match = true
        if Success and Results then
            SearchResults = Results
        end
    end
    
    if not SearchResults then
        return 0
    end
    
    -- Look through search results for a tradeable version with GE value
    for _, ResultItem in ipairs(SearchResults) do
        if ResultItem and ResultItem.id and ResultItem.id ~= OriginalItemId then
            -- Check if this alternative is tradeable and has a GE value
            if ResultItem.tradeable then
                local GeValue = API.GetExchangePrice(ResultItem.id)
                if GeValue and GeValue > 0 then
                    Slib:Info("Found tradeable alternative for '" .. ItemName .. "': ID " .. ResultItem.id .. " (Value: " .. GeValue .. " GP)")
                    return GeValue
                end
            end
        end
    end
    
    return 0
end

-- Creates directory structure and validates write permissions
---@param DirPath string The directory path to create and validate
---@return boolean Success True if directory exists and is writable, false otherwise
local function EnsureDirectoryExists(DirPath)
    -- Attempt to create directory (silently fails if already exists)
    local Success = os.execute('mkdir "' .. DirPath .. '" 2>nul')
    
    -- Validate write access by creating and removing a temporary test file
    local TestFile = io.open(DirPath .. "test_write.tmp", "w")
    if TestFile then
        TestFile:close()
        os.remove(DirPath .. "test_write.tmp")
        return true
    else
        Slib:Error("Could not access directory: " .. DirPath)
        return false
    end
end

-- Initialize output directory with fallback handling
if not EnsureDirectoryExists(Config.OutputDirectory) then
    Slib:Warn("Fallback: Using current directory instead of configured path.")
    Config.OutputDirectory = ".\\"
end

-- Generates unique filename by appending incremental counter to prevent overwrites
---@param BaseFilename string The base filename to make unique
---@return string UniqueFilename A filename guaranteed not to exist
local function GetUniqueFilename(BaseFilename)
    local FullPath = Config.OutputDirectory .. BaseFilename
    
    -- Return base filename if it doesn't exist
    local File = io.open(FullPath, "r")
    if not File then
        return FullPath
    end
    File:close()
    
    -- Parse filename into name and extension components
    local Name, Extension = BaseFilename:match("^(.+)%.([^%.]+)$")
    if not Name then
        Name = BaseFilename
        Extension = ""
    end
    
    -- Find next available numbered filename
    local Counter = 1
    local NewFilename
    repeat
        if Extension and Extension ~= "" then
            NewFilename = Config.OutputDirectory .. Name .. "_" .. Counter .. "." .. Extension
        else
            NewFilename = Config.OutputDirectory .. Name .. "_" .. Counter
        end
        
        local TestFile = io.open(NewFilename, "r")
        if TestFile then
            TestFile:close()
            Counter = Counter + 1
        else
            break
        end
    until false
    
    Slib:Info("File exists, using numbered variant: " .. NewFilename)
    return NewFilename
end

-- Escapes special characters in data values for CSV compatibility
---@param Value any The value to escape and format for CSV
---@return string EscapedValue The properly escaped CSV value
local function EscapeCsv(Value)
    if not Value then
        return ""
    end
    
    local String = tostring(Value)
    -- Quote and escape if contains CSV special characters (comma, quote, newline, carriage return)
    if string.find(String, '[,"\n\r]') then
        String = string.gsub(String, '"', '""') -- Escape internal quotes by doubling them
        String = '"' .. String .. '"'
    end
    return String
end

-- Opens the specified directory in Windows Explorer
---@param Path string The directory path to open (backslashes will be normalized)
local function OpenDirectory(Path)
    -- Normalize path by removing trailing backslashes
    Path = Path:gsub("\\+$", "")
    
    -- Use Windows 'start' command for optimal window management
    os.execute('start "" "' .. Path .. '"')
end

-- Main function to scan bank items and export to CSV
---@return boolean Success True if export completed successfully, false on error
local function ExportBankItemsToCsv()
    Slib:Info("Starting bank item scan...")
    
    -- Check if bank is open and accessible
    if not BANK:IsOpen() then
        Slib:Error("Bank is not open! Please open your bank first.")
        return false
    end
    
    -- Fetch all bank items using the API
    local BankItems = API.Container_Get_all(95)
    local ValidItems = 0

    for _, Item in ipairs(BankItems) do
        if Item.item_id and Item.item_id >= 0 and Item.item_stack > 0 then
            ValidItems = ValidItems + 1
        end
    end
    
    if not BankItems or #BankItems == 0 then
        Slib:Error("No items found in bank!")
        return false
    end

    Slib:Info("Found " .. ValidItems .. " valid items in bank")
    
    -- Process each bank item and collect data
    local ProcessedItems = {}
    local ProcessedCount = 0    
    
    for _, Item in ipairs(BankItems) do
        -- Check loop control to allow script termination
        if not API.Read_LoopyLoop() then
            Slib:Warn("Script terminated by user")
            return false
        end
        
        -- Only process items with valid IDs (skip empty bank slots)
        if Item.item_id and Item.item_id >= 0 and Item.item_stack > 0 then
            -- Get item data using proper method
            local ItemInfo = GetItemData(Item)
            
            -- Get item exchange price (returns 0 if item has no GE price)
            local UnitValue = API.GetExchangePrice(Item.item_id) or 0
            
            -- If item has no GE value, try to find tradeable alternative
            if UnitValue <= 0 then
                local AlternativeValue = GetTradeableAlternativeValue(ItemInfo.Name, Item.item_id)
                if AlternativeValue > 0 then
                    UnitValue = AlternativeValue
                end
            end
            
            -- Ensure unit value is never negative (prevents negative totals)
            if UnitValue < 0 then
                UnitValue = 0
            end
            
            local TotalValue = UnitValue * Item.item_stack
            
            -- Create item data record
            local ItemData = {
                ItemId = Item.item_id,
                ItemName = ItemInfo.Name,
                StackSize = Item.item_stack,
                UnitValue = UnitValue,
                TotalValue = TotalValue,
                Tradeable = ItemInfo.Tradeable
            }
            
            table.insert(ProcessedItems, ItemData)
            ProcessedCount = ProcessedCount + 1
            
            -- Provide progress feedback for large banks
            if ProcessedCount % 50 == 0 then
                Slib:Info("Processed " .. ProcessedCount .. "/" .. ValidItems .. " items...")
            end
        end
    end
    
    -- Sort items by total value (highest first)
    table.sort(ProcessedItems, function(A, B)
        return A.TotalValue > B.TotalValue
    end)
    
    Slib:Info("Processing complete. Creating CSV file...")
    
    -- Generate unique filename to prevent overwrites
    local FinalFilename = GetUniqueFilename(Config.OutputFilename)
    
    -- Create and open CSV file for writing
    local File = io.open(FinalFilename, "w")
    if not File then
        Slib:Error("Could not create file: " .. FinalFilename)
        return false
    end
    
    -- Write CSV header row
    local Headers = {"Item ID", "Item Name", "Stack Size", "Unit Value (GP)", "Total Value (GP)", "Tradeable"}
    local EscapedHeaders = {}
    for _, Header in ipairs(Headers) do
        table.insert(EscapedHeaders, EscapeCsv(Header))
    end
    File:write(table.concat(EscapedHeaders, ",") .. "\n")
    
    -- Write data rows
    local ExportedCount = 0
    local TotalBankValue = 0
    local TradeableBankValue = 0
    
    for _, Item in ipairs(ProcessedItems) do
        -- Build row data with proper CSV escaping
        local RowData = {
            EscapeCsv(Item.ItemId),
            EscapeCsv(Item.ItemName),
            EscapeCsv(Item.StackSize),
            EscapeCsv(Item.UnitValue),
            EscapeCsv(Item.TotalValue),
            EscapeCsv(Item.Tradeable and "Yes" or "No")
        }
        
        -- Write row to file
        File:write(table.concat(RowData, ",") .. "\n")
        ExportedCount = ExportedCount + 1
        TotalBankValue = TotalBankValue + Item.TotalValue
        
        -- Add to tradeable value if item is tradeable
        if Item.Tradeable then
            TradeableBankValue = TradeableBankValue + Item.TotalValue
        end
    end
    
    -- Add summary rows
    File:write("\n")
    File:write(EscapeCsv("SUMMARY") .. "," .. EscapeCsv("Total Items: " .. ExportedCount) .. 
               "," .. EscapeCsv("") .. "," .. EscapeCsv("") .. "," .. EscapeCsv(TotalBankValue) .. "," .. EscapeCsv("") .. "\n")
    File:write(EscapeCsv("") .. "," .. EscapeCsv("Tradeable Value:") .. 
               "," .. EscapeCsv("") .. "," .. EscapeCsv("") .. "," .. EscapeCsv(TradeableBankValue) .. "," .. EscapeCsv("") .. "\n")
    
    File:close()
    
    Slib:Info("Export completed!")
    Slib:Info("Exported " .. ExportedCount .. " items to: " .. FinalFilename)
    Slib:Info("Total bank value: " .. TotalBankValue .. " GP")
    Slib:Info("Tradeable bank value: " .. TradeableBankValue .. " GP")
    
    return true
end

-- Display script information
Slib:Info("=" .. string.rep("=", 60) .. "=")
Slib:Info("  " .. ScriptName .. " v" .. ScriptVersion)
Slib:Info("  Author: " .. Author .. " (" .. DiscordHandle .. ")")
Slib:Info("  Released: " .. ReleaseDate)
Slib:Info("=" .. string.rep("=", 60) .. "=")
Slib:Info("")

-- Execute the main export process
local Success = ExportBankItemsToCsv()

if Success then
    Slib:Info("")
    Slib:Info("Export successful!")
    -- Automatically open the output directory for user convenience
    OpenDirectory(Config.OutputDirectory)
else
    Slib:Error("")
    Slib:Error("Export failed!")
end

-- The line below is needed to run the script from the ScriptManager, do not uncomment it
-- while API.Read_LoopyLoop() do