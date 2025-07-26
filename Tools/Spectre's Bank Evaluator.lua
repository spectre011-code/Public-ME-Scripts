local script_name = "Spectre's Bank Evaluator"
local author = "Spectre011"
local script_version = "2.0.0"
local release_date = "26-01-2025"
local discord_handle = "not_spectre011"

--[[
╔═════════════════════════════════════════════════════════════════════════════╗
║                           BANK EVALUATOR SCRIPT                             ║
║                           BY SPECTRE011                                     ║
╠═════════════════════════════════════════════════════════════════════════════╣
║  Description: Scans all bank items and exports item data to CSV             ║
║  Usage:       Have bank open and execute script                             ║
║  Output:      CSV file with item ID, name, stack size, unit value and total ║
╚═════════════════════════════════════════════════════════════════════════════╝
]]

local API = require("api")
local BANK = require("bank")
local Slib = require("slib")

-- Gets current player name with safety fallback
---@return string player_name The player name or "Unknown_Player" if not available
local function get_safe_player_name()
    local player_name = API.GetLocalPlayerName()
    
    -- Safety check for empty or nil player name
    if not player_name or player_name == "" or player_name == " " then
        return "Unknown_Player"
    end
    
    -- Remove any characters that aren't safe for filenames
    player_name = string.gsub(player_name, "[<>:\"/\\|?*]", "_")
    
    return player_name
end

-- Generates filename with player name and current date
---@return string filename The formatted filename with player name and date
local function generate_filename()
    local player_name = get_safe_player_name()
    local date_string = os.date("%Y-%m-%d_%H-%M-%S")
    
    return "bank_evaluation_" .. player_name .. "_" .. date_string .. ".csv"
end

-- Configuration for output settings
local config = {
    output_directory = os.getenv("USERPROFILE") .. "\\MemoryError\\Lua_Scripts\\exports\\BankEvaluator\\",
    output_filename = generate_filename()
}

-- Gets item data using the same approach as Slib:PrintContainer
---@param item table The item object from the container
---@return table item_info Table containing name and tradeable status
local function get_item_data(item)
    local default_data = {
        name = "Unknown",
        tradeable = false
    }
    
    if not item or not item.item_id or item.item_id < 0 then
        return default_data
    end
    
    local item_data = nil
    
    -- Try to get item data using Item.Get method (same as Slib:PrintContainer)
    if item and item.Get then
        local success, data = pcall(item.Get, item, item.item_id)
        if success and data then
            item_data = data
        end
    elseif _G.Item and _G.Item.Get then
        local success, data = pcall(_G.Item.Get, _G.Item, item.item_id)
        if success and data then
            item_data = data
        end
    end
    
    if item_data then
        return {
            name = item_data.name or "Unknown",
            tradeable = item_data.tradeable or false
        }
    end
    
    return default_data
end

-- Searches for tradeable version of an item using cache when equipped items have no GE value
---@param item_name string The name of the item to search for
---@param original_item_id number The original item ID for fallback
---@return number ge_value The GE value of the tradeable version, or 0 if not found
local function get_tradeable_alternative_value(item_name, original_item_id)
    -- Only search if we have a valid item name
    if not item_name or item_name == "Unknown" or item_name == "" then
        return 0
    end
    
    -- Use Item:GetAll to search for similar items by name
    local search_results = nil
    if _G.Item and _G.Item.GetAll then
        local success, results = pcall(_G.Item.GetAll, _G.Item, item_name, true) -- partial_match = true
        if success and results then
            search_results = results
        end
    end
    
    if not search_results then
        return 0
    end
    
    -- Look through search results for a tradeable version with GE value
    for _, result_item in ipairs(search_results) do
        if result_item and result_item.id and result_item.id ~= original_item_id then
            -- Check if this alternative is tradeable and has a GE value
            if result_item.tradeable then
                local ge_value = API.GetExchangePrice(result_item.id)
                if ge_value and ge_value > 0 then
                    Slib:Info("Found tradeable alternative for '" .. item_name .. "': ID " .. result_item.id .. " (Value: " .. ge_value .. " GP)")
                    return ge_value
                end
            end
        end
    end
    
    return 0
end

-- Creates directory structure and validates write permissions
---@param dir_path string The directory path to create and validate
---@return boolean success True if directory exists and is writable, false otherwise
local function ensure_directory_exists(dir_path)
    -- Attempt to create directory (silently fails if already exists)
    local success = os.execute('mkdir "' .. dir_path .. '" 2>nul')
    
    -- Validate write access by creating and removing a temporary test file
    local test_file = io.open(dir_path .. "test_write.tmp", "w")
    if test_file then
        test_file:close()
        os.remove(dir_path .. "test_write.tmp")
        return true
    else
        Slib:Error("Could not access directory: " .. dir_path)
        return false
    end
end

-- Initialize output directory with fallback handling
if not ensure_directory_exists(config.output_directory) then
    Slib:Warn("Fallback: Using current directory instead of configured path.")
    config.output_directory = ".\\"
end

-- Generates unique filename by appending incremental counter to prevent overwrites
---@param base_filename string The base filename to make unique
---@return string unique_filename A filename guaranteed not to exist
local function get_unique_filename(base_filename)
    local full_path = config.output_directory .. base_filename
    
    -- Return base filename if it doesn't exist
    local file = io.open(full_path, "r")
    if not file then
        return full_path
    end
    file:close()
    
    -- Parse filename into name and extension components
    local name, ext = base_filename:match("^(.+)%.([^%.]+)$")
    if not name then
        name = base_filename
        ext = ""
    end
    
    -- Find next available numbered filename
    local counter = 1
    local new_filename
    repeat
        if ext and ext ~= "" then
            new_filename = config.output_directory .. name .. "_" .. counter .. "." .. ext
        else
            new_filename = config.output_directory .. name .. "_" .. counter
        end
        
        local test_file = io.open(new_filename, "r")
        if test_file then
            test_file:close()
            counter = counter + 1
        else
            break
        end
    until false
    
    Slib:Info("File exists, using numbered variant: " .. new_filename)
    return new_filename
end

-- Escapes special characters in data values for CSV compatibility
---@param value any The value to escape and format for CSV
---@return string escaped_value The properly escaped CSV value
local function escape_csv(value)
    if not value then
        return ""
    end
    
    local str = tostring(value)
    -- Quote and escape if contains CSV special characters (comma, quote, newline, carriage return)
    if string.find(str, '[,"\n\r]') then
        str = string.gsub(str, '"', '""') -- Escape internal quotes by doubling them
        str = '"' .. str .. '"'
    end
    return str
end

-- Opens the specified directory in Windows Explorer
---@param path string The directory path to open (backslashes will be normalized)
local function open_directory(path)
    -- Normalize path by removing trailing backslashes
    path = path:gsub("\\+$", "")
    
    -- Use Windows 'start' command for optimal window management
    os.execute('start "" "' .. path .. '"')
end

-- Main function to scan bank items and export to CSV
---@return boolean success True if export completed successfully, false on error
local function export_bank_items_to_csv()
    Slib:Info("Starting bank item scan...")
    
    -- Check if bank is open and accessible
    if not BANK:IsOpen() then
        Slib:Error("Bank is not open! Please open your bank first.")
        return false
    end
    
    -- Fetch all bank items using the API
    local bank_items = API.Container_Get_all(95)
    local ValidItems = 0

    for _, item in ipairs(bank_items) do
        if item.item_id and item.item_id >= 0 then
            ValidItems = ValidItems + 1
        end
    end
    
    if not bank_items or #bank_items == 0 then
        Slib:Error("No items found in bank!")
        return false
    end

    Slib:Info("Found " .. ValidItems .. " valid items in bank")
    
    -- Process each bank item and collect data
    local processed_items = {}
    local processed_count = 0    
    
    for _, item in ipairs(bank_items) do
        -- Check loop control to allow script termination
        if not API.Read_LoopyLoop() then
            Slib:Warn("Script terminated by user")
            return false
        end
        
        -- Only process items with valid IDs (skip empty bank slots)
        if item.item_id and item.item_id >= 0 then
            -- Get item data using proper method
            local item_info = get_item_data(item)
            
            -- Get item exchange price (returns 0 if item has no GE price)
            local unit_value = API.GetExchangePrice(item.item_id) or 0
            
            -- If item has no GE value, try to find tradeable alternative
            if unit_value <= 0 then
                local alternative_value = get_tradeable_alternative_value(item_info.name, item.item_id)
                if alternative_value > 0 then
                    unit_value = alternative_value
                end
            end
            
            local total_value = unit_value * item.item_stack
            
            -- Create item data record
            local item_data = {
                item_id = item.item_id,
                item_name = item_info.name,
                stack_size = item.item_stack,
                unit_value = unit_value,
                total_value = total_value,
                tradeable = item_info.tradeable
            }
            
            table.insert(processed_items, item_data)
            processed_count = processed_count + 1
            
            -- Provide progress feedback for large banks
            if processed_count % 50 == 0 then
                Slib:Info("Processed " .. processed_count .. "/" .. ValidItems .. " items...")
            end
        end
    end
    
    -- Sort items by total value (highest first)
    table.sort(processed_items, function(a, b)
        return a.total_value > b.total_value
    end)
    
    Slib:Info("Processing complete. Creating CSV file...")
    
    -- Generate unique filename to prevent overwrites
    local final_filename = get_unique_filename(config.output_filename)
    
    -- Create and open CSV file for writing
    local file = io.open(final_filename, "w")
    if not file then
        Slib:Error("Could not create file: " .. final_filename)
        return false
    end
    
    -- Write CSV header row
    local headers = {"Item ID", "Item Name", "Stack Size", "Unit Value (GP)", "Total Value (GP)", "Tradeable"}
    local escaped_headers = {}
    for _, header in ipairs(headers) do
        table.insert(escaped_headers, escape_csv(header))
    end
    file:write(table.concat(escaped_headers, ",") .. "\n")
    
    -- Write data rows
    local exported_count = 0
    local total_bank_value = 0
    local tradeable_bank_value = 0
    
    for _, item in ipairs(processed_items) do
        -- Build row data with proper CSV escaping
        local row_data = {
            escape_csv(item.item_id),
            escape_csv(item.item_name),
            escape_csv(item.stack_size),
            escape_csv(item.unit_value),
            escape_csv(item.total_value),
            escape_csv(item.tradeable and "Yes" or "No")
        }
        
        -- Write row to file
        file:write(table.concat(row_data, ",") .. "\n")
        exported_count = exported_count + 1
        total_bank_value = total_bank_value + item.total_value
        
        -- Add to tradeable value if item is tradeable
        if item.tradeable then
            tradeable_bank_value = tradeable_bank_value + item.total_value
        end
    end
    
    -- Add summary rows
    file:write("\n")
    file:write(escape_csv("SUMMARY") .. "," .. escape_csv("Total Items: " .. exported_count) .. 
               "," .. escape_csv("") .. "," .. escape_csv("") .. "," .. escape_csv(total_bank_value) .. "," .. escape_csv("") .. "\n")
    file:write(escape_csv("") .. "," .. escape_csv("Tradeable Value:") .. 
               "," .. escape_csv("") .. "," .. escape_csv("") .. "," .. escape_csv(tradeable_bank_value) .. "," .. escape_csv("") .. "\n")
    
    file:close()
    
    Slib:Info("Export completed!")
    Slib:Info("Exported " .. exported_count .. " items to: " .. final_filename)
    Slib:Info("Total bank value: " .. total_bank_value .. " GP")
    Slib:Info("Tradeable bank value: " .. tradeable_bank_value .. " GP")
    
    return true
end

-- Display script information
Slib:Info("=" .. string.rep("=", 60) .. "=")
Slib:Info("  " .. script_name .. " v" .. script_version)
Slib:Info("  Author: " .. author .. " (" .. discord_handle .. ")")
Slib:Info("  Released: " .. release_date)
Slib:Info("=" .. string.rep("=", 60) .. "=")
Slib:Info("")

-- Execute the main export process
local success = export_bank_items_to_csv()

if success then
    Slib:Info("")
    Slib:Info("Export successful!")
    -- Automatically open the output directory for user convenience
    open_directory(config.output_directory)
else
    Slib:Error("")
    Slib:Error("Export failed!")
end

-- The line below is needed to run the script from the ScriptManager, do not uncomment it
-- while API.Read_LoopyLoop() do