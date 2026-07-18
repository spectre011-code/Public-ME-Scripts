local ScriptName = "Spectre's Bank Evaluator"
local Author = "Spectre011"
local ScriptVersion = "1.2.0"
local ReleaseDate = "11-07-2026"
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
v1.2.0 - 11-07-2026
    - Prices now fetched live from the RuneScape Wiki API (client GE data can be stale);
      client GetExchangePrice kept as fallback.
    - Alternative-item price lookup now requires an exact name match (partial matching
      could assign prices from unrelated items).
    - Added "Price Source" column to the CSV output.
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
    OutputDirectory = os.getenv("USERPROFILE") .. "\\MemoryError\\Lua_Scripts\\Exports\\BankEvaluator\\",
    OutputFilename = GenerateFilename()
}

-- Checks whether a name from the item cache is a real name rather than a placeholder
---@param Name any The name value to validate
---@return boolean Valid True if the name is usable
local function IsValidItemName(Name)
    return type(Name) == "string" and Name ~= "" and Name ~= "NoName" and Name ~= "Unknown"
end

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

    -- Try the container item's own Get method first, then the global Item class.
    -- Some lookups return placeholder entries ("NoName", tradeable=false) for
    -- items that are fine in the other source, so a bad result from the first
    -- source must not block trying the second.
    local Candidates = {}
    if Item.Get then
        local Success, Data = pcall(Item.Get, Item, Item.item_id)
        if Success and Data then
            table.insert(Candidates, Data)
        end
    end
    if _G.Item and _G.Item.Get then
        local Success, Data = pcall(_G.Item.Get, _G.Item, Item.item_id)
        if Success and Data then
            table.insert(Candidates, Data)
        end
    end

    local Best = nil
    for _, Data in ipairs(Candidates) do
        if IsValidItemName(Data.name) then
            Best = Data
            break
        end
    end
    Best = Best or Candidates[1]

    if Best then
        return {
            Name = Best.name or "Unknown",
            Tradeable = Best.tradeable or false
        }
    end

    return DefaultData
end

-- Cache of live prices fetched from the RuneScape Wiki exchange API, keyed by item ID
local WikiPriceCache = {}
local WikiApiFailed = false

-- Fetches latest GE prices for one batch of item IDs from the RuneScape Wiki API
---@param ItemIds number[] Array of item IDs (max 100 per call)
local function FetchWikiPriceBatch(ItemIds)
    if WikiApiFailed or #ItemIds == 0 then
        return
    end

    if not Http or not Http.Get then
        WikiApiFailed = true
        Slib:Warn("Http API not available - falling back to client GE prices")
        return
    end

    local IdStrings = {}
    for _, Id in ipairs(ItemIds) do
        table.insert(IdStrings, tostring(Id))
    end
    local Url = "https://api.weirdgloop.org/exchange/history/rs/latest?id=" .. table.concat(IdStrings, "%7C")

    -- The wiki API asks for a descriptive User-Agent; default client UA may be rejected
    local Headers = {"User-Agent: Spectres-Bank-Evaluator/1.2 (RuneScape bank value script)"}
    local Success, Response = pcall(Http.Get, Http, Url, Headers)
    if not Success or not Response or Response.statusCode ~= 200 or not Response.body then
        WikiApiFailed = true
        local Status = (Response and Response.statusCode) and tostring(Response.statusCode) or "no response"
        Slib:Warn("Wiki price API request failed (status: " .. Status .. ") - falling back to client GE prices")
        return
    end

    local Ok, Data = pcall(API.JsonDecode, Response.body)
    if not Ok or type(Data) ~= "table" then
        WikiApiFailed = true
        Slib:Warn("Could not parse wiki price API response - falling back to client GE prices")
        Slib:Warn("Response status: " .. tostring(Response.statusCode) .. ", body starts with: " .. string.sub(tostring(Response.body), 1, 200))
        return
    end

    for IdString, Entry in pairs(Data) do
        local Id = tonumber(IdString)
        local Price = type(Entry) == "table" and tonumber(Entry.price) or nil
        if Id and Price and Price > 0 then
            WikiPriceCache[Id] = Price
        end
    end
end

-- Fetches wiki prices for all given item IDs in batches of 100
---@param ItemIds number[] Array of unique item IDs
local function FetchWikiPrices(ItemIds)
    local Batch = {}
    for _, Id in ipairs(ItemIds) do
        table.insert(Batch, Id)
        if #Batch == 100 then
            FetchWikiPriceBatch(Batch)
            Batch = {}
        end
    end
    FetchWikiPriceBatch(Batch)
end

-- Fetches an item's name from the Jagex item DB when the local cache has none.
-- One request per item, so this is only used for the few placeholder entries.
---@param ItemId number The item ID to look up
---@return string|nil Name The item name, or nil if unavailable
local function FetchItemNameFromItemDb(ItemId)
    if not Http or not Http.Get then
        return nil
    end

    local Url = "https://secure.runescape.com/m=itemdb_rs/api/catalogue/detail.json?item=" .. ItemId
    local Success, Response = pcall(Http.Get, Http, Url)
    if not Success or not Response or Response.statusCode ~= 200 or not Response.body then
        return nil
    end

    local Ok, Data = pcall(API.JsonDecode, Response.body)
    if Ok and type(Data) == "table" and type(Data.item) == "table" and IsValidItemName(Data.item.name) then
        return Data.item.name
    end

    return nil
end

-- Finds a tradeable item with this exact name in the item cache
---@param Name string The exact item name to search for
---@param ExcludeId number Item ID to exclude from results
---@param MaxIdDistance number|nil If set, only accept IDs within this distance of ExcludeId
---@return number|nil ItemId The ID of the tradeable item, or nil if not found
local function FindTradeableIdByName(Name, ExcludeId, MaxIdDistance)
    if not (_G.Item and _G.Item.GetAll) then
        return nil
    end

    local Success, Results = pcall(_G.Item.GetAll, _G.Item, Name, false) -- strict name match
    if not Success or not Results then
        return nil
    end

    for _, ResultItem in ipairs(Results) do
        if ResultItem and ResultItem.id and ResultItem.id ~= ExcludeId
           and ResultItem.name == Name and ResultItem.tradeable then
            if not MaxIdDistance or math.abs(ResultItem.id - ExcludeId) <= MaxIdDistance then
                return ResultItem.id
            end
        end
    end

    return nil
end

-- Resolves which item ID to price an item by when it has no GE data itself.
-- Augmented items are priced as their base item (exact name match). Other
-- untradeable items are only priced via a same-name tradeable twin when that
-- twin's ID is within 2 of the original (e.g. Brooch of the Gods 50464 ->
-- 50462): adjacent IDs are bound/unbound variants of the same item, while a
-- distant same-name item is a different item entirely (e.g. the untradeable
-- Gower Quest "Disk of returning" vs the multi-billion tradeable rare).
---@param ItemName string The name of the item
---@param OriginalItemId number The original item ID
---@return number|nil PriceId The item ID to use for price lookup, or nil if none found
local function GetAlternativePriceId(ItemName, OriginalItemId)
    if not ItemName or ItemName == "Unknown" or ItemName == "" then
        return nil
    end

    if string.sub(ItemName, 1, 10) ~= "Augmented " then
        local TwinId = FindTradeableIdByName(ItemName, OriginalItemId, 2)
        if TwinId then
            Slib:Info("Pricing untradeable item '" .. ItemName .. "' as tradeable twin ID " .. TwinId)
        end
        return TwinId
    end

    local BaseItemName = string.sub(ItemName, 11) -- Remove "Augmented " prefix

    local BaseId = FindTradeableIdByName(BaseItemName, OriginalItemId)
    if BaseId then
        Slib:Info("Pricing augmented item '" .. ItemName .. "' as base item ID " .. BaseId)
        return BaseId
    end

    -- Handle variants like "Augmented X (uncharged)" where only "X" is tradeable
    local StrippedName = BaseItemName:match("^(.-)%s*%([^%)]*%)$")
    if StrippedName and StrippedName ~= "" then
        BaseId = FindTradeableIdByName(StrippedName, OriginalItemId)
        if BaseId then
            Slib:Info("Pricing augmented item '" .. ItemName .. "' as base item ID " .. BaseId)
            return BaseId
        end
    end

    return nil
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

            -- Resolve which item ID to price this item by. Untradeable items
            -- (augmented gear, untradeable twins) have no GE data of their own,
            -- so they are priced via an exact-name tradeable match instead.
            -- Note: API.GetExchangePrice is deliberately NOT called here - the
            -- client's per-item price fetch is broken (JSON parse errors) and slow.
            local PriceId = Item.item_id
            if not ItemInfo.Tradeable then
                local AlternativeId = GetAlternativePriceId(ItemInfo.Name, Item.item_id)
                if AlternativeId then
                    PriceId = AlternativeId
                end
            end

            -- Create item data record (values are filled in after wiki price fetch)
            local ItemData = {
                ItemId = Item.item_id,
                ItemName = ItemInfo.Name,
                StackSize = Item.item_stack,
                PriceId = PriceId,
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

    -- Fetch live prices from the RuneScape Wiki API for all price IDs.
    -- The client's built-in GetExchangePrice data can be badly stale, so wiki
    -- prices take priority and the client price is only a fallback.
    Slib:Info("Fetching live prices from RuneScape Wiki API...")
    local UniquePriceIds = {}
    local SeenPriceIds = {}
    for _, Record in ipairs(ProcessedItems) do
        if not SeenPriceIds[Record.PriceId] then
            SeenPriceIds[Record.PriceId] = true
            table.insert(UniquePriceIds, Record.PriceId)
        end
    end
    FetchWikiPrices(UniquePriceIds)

    -- Fill in names the local item cache is missing (placeholder "NoName"
    -- entries) via the Jagex item DB, one request per unique broken item.
    -- Budget-capped so a badly broken cache cannot cause hundreds of requests.
    local NameLookupBudget = 50
    local FetchedNames = {}
    for _, Record in ipairs(ProcessedItems) do
        if not IsValidItemName(Record.ItemName) then
            if FetchedNames[Record.ItemId] then
                Record.ItemName = FetchedNames[Record.ItemId]
            elseif NameLookupBudget > 0 then
                NameLookupBudget = NameLookupBudget - 1
                local Name = FetchItemNameFromItemDb(Record.ItemId)
                if Name then
                    FetchedNames[Record.ItemId] = Name
                    Record.ItemName = Name
                    Slib:Info("Resolved missing name for item ID " .. Record.ItemId .. ": " .. Name)
                end
            end
        end
    end

    -- Compute unit and total values using the best available price source.
    -- Client GetExchangePrice is only consulted when the wiki API was unreachable:
    -- if the wiki responded, a missing ID simply means the item has no GE price,
    -- and each client price call risks a broken/slow HTTP fetch of its own.
    for _, Record in ipairs(ProcessedItems) do
        local UnitValue = WikiPriceCache[Record.PriceId]
        if UnitValue and UnitValue > 0 then
            Record.PriceSource = "Wiki"
            -- The item cache sometimes returns placeholder entries that wrongly
            -- mark GE items untradeable; a wiki price on the item's own ID
            -- proves it is traded on the GE
            if Record.PriceId == Record.ItemId then
                Record.Tradeable = true
            end
        elseif WikiApiFailed then
            UnitValue = API.GetExchangePrice(Record.PriceId) or 0
            Record.PriceSource = (UnitValue > 0) and "Client GE" or "None"
        else
            UnitValue = 0
            Record.PriceSource = "None"
        end

        -- Ensure unit value is never negative (prevents negative totals)
        if UnitValue < 0 then
            UnitValue = 0
        end

        Record.UnitValue = UnitValue
        Record.TotalValue = UnitValue * Record.StackSize
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
    local Headers = {"Item ID", "Item Name", "Stack Size", "Unit Value (GP)", "Total Value (GP)", "Tradeable", "Price Source"}
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
            EscapeCsv(Item.Tradeable and "Yes" or "No"),
            EscapeCsv(Item.PriceSource or "None")
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
               "," .. EscapeCsv("") .. "," .. EscapeCsv("") .. "," .. EscapeCsv(TotalBankValue) .. "," .. EscapeCsv("") .. "," .. EscapeCsv("") .. "\n")
    File:write(EscapeCsv("") .. "," .. EscapeCsv("Tradeable Value:") ..
               "," .. EscapeCsv("") .. "," .. EscapeCsv("") .. "," .. EscapeCsv(TradeableBankValue) .. "," .. EscapeCsv("") .. "," .. EscapeCsv("") .. "\n")
    
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
