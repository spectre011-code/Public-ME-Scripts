local ScriptName = "Spectre011's Lua Utility Library" 
local Author = "Spectre011"
local ScriptVersion = "1.0.0"
local ReleaseDate = "15-06-2025"
local DiscordHandle = "not_spectre011"

--[[
======================================================================================
                       Spectre011's Lua Utility Library (Slib)                       
======================================================================================

A comprehensive utility library for RuneScape automation scripts to me used with ME,
providing robust parameter validation, debugging tools, helper functions, and table 
manipulation utilities designed specifically for the RuneScape API environment.

--------------------------------------------------------------------------------------
                                       CREDITS                                       
--------------------------------------------------------------------------------------

Primary Author: Spectre011 (Discord: not_spectre011)
GitHub: https://github.com/spectre011-code
AI Assistant: Claude (Anthropic) - Code generation and optimization

This library was developed with AI assistance for:
• Code structure and organization
• Documentation and error handling
• Testing and debugging utilities

======================================================================================

Changelog:
v1.0.0 - 15-06-2025
    - Initial release
]]

local API = require("api")

local Slib = {}

Slib.ChatMessages = API.GatherEvents_chat_check()
Slib.Interfaces = {}

Slib.Interfaces.InstanceTimer = { 
    { 861,0,-1,0 }, { 861,2,-1,0 }, { 861,4,-1,0 }, { 861,8,-1,0 } 
}

Slib.Interfaces.GWD1KillCounts = {
    { {601,11,-1,0}, {601,9,-1,0}, { 601,18,-1,0 } }, -- Armadyl
    { {601,11,-1,0}, {601,9,-1,0}, { 601,19,-1,0 } }, -- Bandos
    { {601,11,-1,0}, {601,9,-1,0}, { 601,20,-1,0 } }, -- Saradomin
    { {601,11,-1,0}, {601,9,-1,0}, { 601,21,-1,0 } }, -- Zamorak
    { {601,11,-1,0}, {601,9,-1,0}, { 601,22,-1,0 } }, -- Zaros
}

Slib.Interfaces.GWD2KillCounts = {
    { { 1746,0,-1,0 }, { 1746,38,-1,0 }, { 1746,41,-1,0 }, { 1746,43,-1,0 }, { 1746,47,-1,0 } },  -- Seren
    { { 1746,0,-1,0 }, { 1746,38,-1,0 }, { 1746,41,-1,0 }, { 1746,49,-1,0 }, { 1746,54,-1,0 } },  -- Sliske
    { { 1746,0,-1,0 }, { 1746,38,-1,0 }, { 1746,41,-1,0 }, { 1746,55,-1,0 }, { 1746,60,-1,0 } },  -- Zamorak
    { { 1746,0,-1,0 }, { 1746,38,-1,0 }, { 1746,41,-1,0 }, { 1746,61,-1,0 }, { 1746,66,-1,0 } },  -- Zaros
}

Slib.Interfaces.CurrencyPouch = {
    { {1473,0,-1,0}, {1473,13,-1,0}, {1473,17,-1,0}, {1473,18,-1,0}, {1473,21,-1,0} }
}

-- ##################################
-- #                                #
-- #       LOGGING FUNCTIONS        #
-- #                                #
-- ##################################

-- Logs a general message with Slib prefix
---@param Message string The message to log
---@return string Message The logged message
function Slib:Log(Message)
    if not self:Sanitize(Message, "string", "Message") then
        return ""
    end
    API.printlua("[Slib][LOG] " .. tostring(Message), 0, false)
    return Message
end

-- Logs an informational message with INFO level
---@param Message string The informational message to log
---@return string Message The logged message
function Slib:Info(Message)
    if not self:Sanitize(Message, "string", "Message") then
        return ""
    end
    API.printlua("[Slib][INFO] " .. tostring(Message), 7, false)
    return Message
end

-- Logs a warning message with WARN level
---@param Message string The warning message to log
---@return string Message The logged message
function Slib:Warn(Message)
    if not self:Sanitize(Message, "string", "Message") then
        return ""
    end
    API.printlua("[Slib][WARN] " .. tostring(Message), 2, false)
    return Message
end

-- Logs an error message with ERROR level
---@param Message string The error message to log
---@return string Message The logged message
function Slib:Error(Message)
    -- Manual validation to avoid circular dependency with sanitization system
    if Message == nil then
        API.printlua("[Slib][ERROR] Error function received nil message", 4, false)
        return ""
    end
    if type(Message) ~= "string" then
        API.printlua("[Slib][ERROR] Error function received non-string message: " .. tostring(Message), 4, false)
        return tostring(Message)
    end
    API.printlua("[Slib][ERROR] " .. tostring(Message), 4, false)
    return Message
end

-- ##################################
-- #                                #
-- #    SANITIZATION FUNCTIONS      #
-- #                                #
-- ##################################

-- Validates that a value matches the specified type(s) with support for complex types
---
--- **Basic Lua Types:**
---   - "string", "number", "boolean", "function", "table", "userdata", "thread"
---   - "any" - accepts any non-nil value (unless AllowNil is true)
---
--- **Enhanced Number Types:**
---   - "id" - non-negative integers (0, 1, 2, 3...)
---   - "positive_number" - numbers greater than 0
---   - "non_negative_number" - numbers >= 0  
---   - "integer" - whole numbers (positive, negative, or zero)
---
--- **Enhanced String Types:**
---   - "non_empty_string" - strings that aren't empty
---
--- **Table Types:**
---   - "table_of_strings" - array of strings
---   - "table_of_numbers" - array of numbers
---   - "table_of_ids" - array of non-negative integers
---   - "table_of_positive_numbers" - array of positive numbers
---   - "table_of_integers" - array of whole numbers
---   - "non_empty_table" - table that has at least one element
---
---
---@param Value any The value to validate
---@param ExpectedType string|table The expected type(s) - can be single type or array of types
---@param ParamName string|nil Optional parameter name for error messages (default: "Parameter")
---@param AllowNil boolean|nil Whether nil values should be considered valid (optional, default: false)
---@param CallingFunction string|nil Optional calling function name for error messages
---@return boolean IsValid True if validation passes, false otherwise (errors logged via self:Error)
function Slib:Sanitize(Value, ExpectedType, ParamName, AllowNil, CallingFunction)
    -- Set defaults
    ParamName = ParamName or "Parameter"
    if AllowNil == nil then
        AllowNil = false
    end
    
    -- Get calling function name for better error messages
    if not CallingFunction then
        CallingFunction = "Unknown"
        local Info = debug.getinfo(2, "n")
        if Info and Info.name then
            CallingFunction = Info.name
        end
    end
    
    -- Handle nil values
    if Value == nil then
        if AllowNil then
            return true
        else
            self:Error("[" .. CallingFunction .. "] " .. ParamName .. " cannot be nil")
            return false
        end
    end
    
    -- Ensure ExpectedType is a table for consistent processing
    local TypeTable = type(ExpectedType) == "table" and ExpectedType or {ExpectedType}
    
    -- Get actual type of the value
    local ActualType = type(Value)
    
    -- Check each expected type
    for _, ExpectedPattern in ipairs(TypeTable) do
        if type(ExpectedPattern) ~= "string" then
            self:Error("[" .. CallingFunction .. "] Invalid type specification: " .. tostring(ExpectedPattern))
            return false
        end
        
        -- Check basic Lua types
        if ExpectedPattern == ActualType then
            return true
        end
        
        -- Check for 'any' type (accepts anything except nil unless AllowNil is true)
        if ExpectedPattern == "any" then
            return true
        end
        
        -- Check for 'id' type (non-negative integer)
        if ExpectedPattern == "id" then
            if ActualType == "number" and Value >= 0 and math.floor(Value) == Value then
                return true
            end
        end
        
        -- Check for 'positive_number' type
        if ExpectedPattern == "positive_number" then
            if ActualType == "number" and Value > 0 then
                return true
            end
        end
        
        -- Check for 'non_negative_number' type
        if ExpectedPattern == "non_negative_number" then
            if ActualType == "number" and Value >= 0 then
                return true
            end
        end
        
        -- Check for 'integer' type
        if ExpectedPattern == "integer" then
            if ActualType == "number" and math.floor(Value) == Value then
                return true
            end
        end
        
        -- Check for 'non_empty_string' type
        if ExpectedPattern == "non_empty_string" then
            if ActualType == "string" and Value ~= "" then
                return true
            end
        end
        
        -- Check for table-based complex types
        if ActualType == "table" or ActualType == "userdata" then
            -- Check for 'table_of_strings'
            if ExpectedPattern == "table_of_strings" then
                for I, Item in ipairs(Value) do
                    if type(Item) ~= "string" then
                        self:Error("[" .. CallingFunction .. "] " .. ParamName .. " must be a table of strings (item " .. I .. " is " .. type(Item) .. ")")
                        return false
                    end
                end
                return true
            end
            
            -- Check for 'table_of_numbers'
            if ExpectedPattern == "table_of_numbers" then
                for I, Item in ipairs(Value) do
                    if type(Item) ~= "number" then
                        self:Error("[" .. CallingFunction .. "] " .. ParamName .. " must be a table of numbers (item " .. I .. " is " .. type(Item) .. ")")
                        return false
                    end
                end
                return true
            end
            
            -- Check for 'table_of_ids'
            if ExpectedPattern == "table_of_ids" then
                for I, Item in ipairs(Value) do
                    if type(Item) ~= "number" or Item < 0 or math.floor(Item) ~= Item then
                        self:Error("[" .. CallingFunction .. "] " .. ParamName .. " must be a table of IDs (non-negative integers) (item " .. I .. " is invalid)")
                        return false
                    end
                end
                return true
            end
            
            -- Check for 'table_of_positive_numbers'
            if ExpectedPattern == "table_of_positive_numbers" then
                for I, Item in ipairs(Value) do
                    if type(Item) ~= "number" or Item <= 0 then
                        self:Error("[" .. CallingFunction .. "] " .. ParamName .. " must be a table of positive numbers (item " .. I .. " is invalid)")
                        return false
                    end
                end
                return true
            end
            
            -- Check for 'table_of_integers'
            if ExpectedPattern == "table_of_integers" then
                for I, Item in ipairs(Value) do
                    if type(Item) ~= "number" or math.floor(Item) ~= Item then
                        self:Error("[" .. CallingFunction .. "] " .. ParamName .. " must be a table of integers (item " .. I .. " is invalid)")
                        return false
                    end
                end
                return true
            end
            
            -- Check for 'non_empty_table'
            if ExpectedPattern == "non_empty_table" then
                if next(Value) ~= nil then
                    return true
                else
                    self:Error("[" .. CallingFunction .. "] " .. ParamName .. " cannot be an empty table")
                    return false
                end
            end
            

        end
    end
    
    -- If no types matched, log error and return false
    local ExpectedStr = type(ExpectedType) == "table" and table.concat(ExpectedType, " or ") or tostring(ExpectedType)
    self:Error("[" .. CallingFunction .. "] " .. ParamName .. " must be " .. ExpectedStr .. " (got " .. ActualType .. ")")
    return false
end

-- Validates function parameters using the sanitization system
---
--- **Usage Examples:**
--- ```lua
--- -- Basic validation
--- if not self:ValidateParams({
---     {PlayerName, "non_empty_string", "PlayerName"},
---     {NpcIds, "table_of_ids", "NpcIds"},
---     {Range, "positive_number", "Range"}
--- }) then
---     return false
--- end
---
--- -- With optional parameters
--- if not self:ValidateParams({
---     {ItemId, "id", "ItemId"},
---     {Timeout, "positive_number", "Timeout", true}, -- AllowNil = true
---     {Options, "table", "Options", true}
--- }) then
---     return false
--- end
---
--- -- Multiple allowed types
--- if not self:ValidateParams({
---     {SearchCriteria, {"string", "table_of_strings"}, "SearchCriteria"},
---     {Coords, {"number", "table_of_numbers"}, "Coords"}
--- }) then
---     return false
--- end
--- ```
---
---@param Params table Array of parameter specs: {Value, ExpectedType, ParamName, AllowNil}
---   - **Value**: The parameter value to validate
---   - **ExpectedType**: Type(s) to validate against (see Sanitize documentation for all types)
---   - **ParamName**: Name for error messages (optional, defaults to "Parameter N")
---   - **AllowNil**: Whether nil is acceptable (optional, defaults to false)
---@return boolean AllValid True if all parameters are valid, false otherwise (errors logged via self:Error)
function Slib:ValidateParams(Params)
    -- Get calling function name for better error messages
    local CallingFunction = "Unknown"
    local Info = debug.getinfo(2, "n")
    if Info and Info.name then
        CallingFunction = Info.name
    end
    
    if not Params or type(Params) ~= "table" then
        self:Error("[" .. CallingFunction .. "] ValidateParams requires a table of parameter specifications")
        return false
    end
    
    for I, ParamSpec in ipairs(Params) do
        if type(ParamSpec) ~= "table" then
            self:Error("[" .. CallingFunction .. "] Parameter specification " .. I .. " must be a table")
            return false
        end
        
        -- Extract parameters with explicit nil checking to handle false values
        local Value
        if ParamSpec[1] ~= nil then
            Value = ParamSpec[1]
        else
            Value = ParamSpec.Value
        end
        
        local ExpectedType = ParamSpec[2] or ParamSpec.ExpectedType
        local ParamName = ParamSpec[3] or ParamSpec.ParamName or ("Parameter " .. I)
        
        local AllowNil
        if ParamSpec[4] ~= nil then
            AllowNil = ParamSpec[4]
        else
            AllowNil = ParamSpec.AllowNil or false
        end
        
        if not self:Sanitize(Value, ExpectedType, ParamName, AllowNil, CallingFunction) then
            return false
        end
    end
    
    return true
end

-- ##################################
-- #                                #
-- #       UTILITY FUNCTIONS        #
-- #                                #
-- ##################################

-- Generic sleep function that automatically determines the best precision based on duration
---@param Duration number The sleep duration (must be positive)
---@param Unit string The time unit: "ms", "s", "m", "h" (milliseconds, seconds, minutes, hours)
---@return boolean success True if sleep completed successfully, false if interrupted or invalid parameters
function Slib:Sleep(Duration, Unit)
    -- Parameter validation
    if not self:ValidateParams({
        {Duration, "positive_number", "Duration"},
        {Unit, "string", "Unit"}
    }) then
        return false
    end
    
    -- Normalize unit to lowercase
    Unit = string.lower(Unit)
    
    -- Convert duration to seconds and implement sleep logic
    local TargetDuration
    local YieldInterval
    
    if Unit == "ms" or Unit == "milli" or Unit == "millisecond" or Unit == "milliseconds" then
        TargetDuration = Duration / 1000
        YieldInterval = 0.001  -- 1ms yield for precision
    elseif Unit == "s" or Unit == "sec" or Unit == "second" or Unit == "seconds" then
        TargetDuration = Duration
        YieldInterval = 0.01   -- 10ms yield for balance
    elseif Unit == "m" or Unit == "min" or Unit == "minute" or Unit == "minutes" then
        TargetDuration = Duration * 60
        YieldInterval = 0.1    -- 100ms yield for longer sleeps
    elseif Unit == "h" or Unit == "hr" or Unit == "hour" or Unit == "hours" then
        TargetDuration = Duration * 3600
        YieldInterval = 0.5    -- 500ms yield for very long sleeps
    else
        self:Error("Invalid time unit: " .. Unit .. ". Valid units: ms, s, m, h")
        return false
    end
    
    -- Implement sleep logic
    local StartTime = os.clock()
    local LastYield = StartTime
    
    while API.Read_LoopyLoop() and (os.clock() - StartTime) < TargetDuration do
        -- Yield CPU at appropriate intervals based on duration
        if (os.clock() - LastYield) >= YieldInterval then
            -- Force garbage collection periodically to yield CPU
            collectgarbage("step", 1)
            LastYield = os.clock()
        end
    end
    
    return (os.clock() - StartTime) >= TargetDuration
end

-- Sleeps for a random duration between min and max values
---@param MinDuration number The minimum sleep duration (must be positive)
---@param MaxDuration number The maximum sleep duration (must be greater than MinDuration)
---@param Unit string The time unit: "ms", "s", "m", "h" (milliseconds, seconds, minutes, hours)
---@return boolean success True if sleep completed successfully, false if interrupted or invalid parameters
---@usage
--- -- Sleep between 1-3 seconds
--- Slib:RandomSleep(1, 3, "s")
--- -- Sleep between 500-1500 milliseconds
--- Slib:RandomSleep(500, 1500, "ms")
function Slib:RandomSleep(MinDuration, MaxDuration, Unit)
    -- Parameter validation
    if not self:ValidateParams({
        {MinDuration, "positive_number", "MinDuration"},
        {MaxDuration, "positive_number", "MaxDuration"},
        {Unit, "string", "Unit"}
    }) then
        return false
    end
    
    -- Validate min/max relationship
    if MinDuration >= MaxDuration then
        self:Error("[RandomSleep] MinDuration must be less than MaxDuration")
        return false
    end
    
    -- Generate random duration
    local Duration = MinDuration + math.random() * (MaxDuration - MinDuration)
    self:Info(string.format("[RandomSleep] Sleeping for %.2f %s", Duration, Unit))
    
    -- Use existing Sleep function
    return self:Sleep(Duration, Unit)
end

-- Sleeps until a condition is met or timeout occurs
---@param ConditionFunc function The function to check (should return boolean)
---@param TimeoutSeconds number|nil Maximum wait time in seconds (optional, default: 30)
---@param CheckIntervalMs number|nil How often to check condition in milliseconds (optional, default: 100)
---@return boolean success True if condition was met, false if timeout or error occurred
function Slib:SleepUntil(ConditionFunc, TimeoutSeconds, CheckIntervalMs)
    -- Set defaults
    TimeoutSeconds = TimeoutSeconds or 30
    CheckIntervalMs = CheckIntervalMs or 100
    
    -- Parameter validation
    if not self:ValidateParams({
        {ConditionFunc, "function", "ConditionFunc"},
        {TimeoutSeconds, "positive_number", "TimeoutSeconds"},
        {CheckIntervalMs, "positive_number", "CheckIntervalMs"}
    }) then
        return false
    end
    
    local StartTime = os.clock()
    local MaxTime = TimeoutSeconds
    local CheckCount = 0
    
    self:Info("Waiting for condition with " .. TimeoutSeconds .. "s timeout, checking every " .. CheckIntervalMs .. "ms...")
    
    while API.Read_LoopyLoop() do
        CheckCount = CheckCount + 1
        
        -- Check timeout
        if (os.clock() - StartTime) >= MaxTime then
            self:Warn("Timeout reached (" .. TimeoutSeconds .. "s) after " .. CheckCount .. " condition checks")
            return false
        end
        
        -- Test condition with error handling
        local Success, Result = pcall(ConditionFunc)
        if not Success then
            self:Error("Condition function error: " .. tostring(Result))
            return false
        end
        
        if Result then
            local Elapsed = os.clock() - StartTime
            self:Info("Condition met after " .. string.format("%.2f", Elapsed) .. " seconds (" .. CheckCount .. " checks)")
            return true
        end
        
        -- Sleep between checks
        self:Sleep(CheckIntervalMs, "ms")
    end
    
    self:Warn("Loop stopped while waiting for condition after " .. CheckCount .. " checks")
    return false
end

-- ##################################
-- #                                #
-- #       DEBUG FUNCTIONS          #
-- #                                #
-- ##################################

-- Prints all the buffs currently active with detailed information
---@return boolean Success True if buffs were found and printed, false if no buffs or error occurred
function Slib:PrintBuffs()
    -- Protected API call with validation
    local Buffs = API.Buffbar_GetAllIDs()
    
    -- Check if API returned valid data
    if not Buffs then
        self:Error("API returned nil for buffs")
        return false
    end
    
    if type(Buffs) ~= "table" and type(Buffs) ~= "userdata" then
        self:Error("API returned invalid buff data type: " .. type(Buffs))
        return false
    end
    
    if #Buffs == 0 then
        self:Info("No buffs currently active")
        return false
    end
    
    self:Info("Found " .. #Buffs .. " active buffs:")
    print("")
    
    -- Safe iteration with bounds checking
    for I = 1, #Buffs do
        local Buff = Buffs[I]
        
        -- Check if buff exists and is valid
        if not Buff then
            self:Warn("Skipping nil buff at index " .. I)
            goto continue
        end
        
        if type(Buff) ~= "table" and type(Buff) ~= "userdata" then
            self:Warn("Skipping invalid buff at index " .. I .. " (type: " .. type(Buff) .. ")")
            goto continue
        end
        
        -- Format buff information with nice borders
        print("+=========================+")
        print("|         BUFF #" .. I .. "         |")
        print("+=========================+")
        print("|   ID             : " .. tostring(Buff.id or "N/A"))
        print("|   Found          : " .. tostring(Buff.found or "N/A"))
        print("|   Text           : " .. tostring(Buff.text or "N/A"))
        print("|   Conv Text      : " .. tostring(Buff.conv_text or "N/A"))
        
        -- Add additional fields if they exist
        if Buff.duration then
            print("|   Duration       : " .. tostring(Buff.duration))
        end
        
        if Buff.remaining then
            print("|   Remaining      : " .. tostring(Buff.remaining))
        end
        
        if Buff.stacks then
            print("|   Stacks         : " .. tostring(Buff.stacks))
        end
        
        if Buff.icon then
            print("|   Icon           : " .. tostring(Buff.icon))
        end
        
        print("+=========================+")
        print("")
        
        ::continue::
    end
    
    self:Info("Buff scan completed successfully")
    return true
end

-- Prints all the debuffs currently active with detailed information
---@return boolean Success True if debuffs were found and printed, false if no debuffs or error occurred
function Slib:PrintDebuffs()
    -- Protected API call with validation
    local Debuffs = API.DeBuffbar_GetAllIDs()
    
    -- Check if API returned valid data
    if not Debuffs then
        self:Error("API returned nil for debuffs")
        return false
    end
    
    if type(Debuffs) ~= "table" and type(Debuffs) ~= "userdata" then
        self:Error("API returned invalid debuff data type: " .. type(Debuffs))
        return false
    end
    
    if #Debuffs == 0 then
        self:Info("No debuffs currently active")
        return false
    end
    
    self:Info("Found " .. #Debuffs .. " active debuffs:")
    print("")
    
    -- Safe iteration with bounds checking
    for I = 1, #Debuffs do
        local Debuff = Debuffs[I]
        
        -- Check if debuff exists and is valid
        if not Debuff then
            self:Warn("Skipping nil debuff at index " .. I)
            goto continue
        end
        
        if type(Debuff) ~= "table" and type(Debuff) ~= "userdata" then
            self:Warn("Skipping invalid debuff at index " .. I .. " (type: " .. type(Debuff) .. ")")
            goto continue
        end
        
        -- Format debuff information with nice borders
        print("+=========================+")
        print("|        DEBUFF #" .. I .. "        |")
        print("+=========================+")
        print("|   ID             : " .. tostring(Debuff.id or "N/A"))
        print("|   Found          : " .. tostring(Debuff.found or "N/A"))
        print("|   Text           : " .. tostring(Debuff.text or "N/A"))
        print("|   Conv Text      : " .. tostring(Debuff.conv_text or "N/A"))
        
        -- Add additional fields if they exist
        if Debuff.duration then
            print("|   Duration       : " .. tostring(Debuff.duration))
        end
        
        if Debuff.remaining then
            print("|   Remaining      : " .. tostring(Debuff.remaining))
        end
        
        if Debuff.stacks then
            print("|   Stacks         : " .. tostring(Debuff.stacks))
        end
        
        if Debuff.icon then
            print("|   Icon           : " .. tostring(Debuff.icon))
        end
        
        print("+=========================+")
        print("")
        
        ::continue::
    end
    
    self:Info("Debuff scan completed successfully")
    return true
end

-- Prints container contents with detailed information for each item (93 = inventory, 94 = equipment, 95 = bank)
---@param ContainerId number
---@return boolean Success
function Slib:PrintContainer(ContainerId)
    -- Parameter validation
    if not self:Sanitize(ContainerId, "number", "ContainerId") then
        return false
    end
    
    -- API call to get container contents
    local Items = API.Container_Get_all(ContainerId)
    
    -- Check if API returned valid data
    if not Items then
        self:Error("API returned nil for container " .. ContainerId)
        return false
    end
    
    if type(Items) ~= "table" and type(Items) ~= "userdata" then
        self:Error("API returned invalid container data type: " .. type(Items))
        return false
    end
    
    if #Items == 0 then
        self:Info("Container " .. ContainerId .. " is empty")
        return false
    end

    -- Count valid items (items with valid item_id >= 0)
    local ValidItemCount = 0
    for I = 1, #Items do
        local Item = Items[I]
        if Item and Item.item_id and Item.item_id >= 0 then
            ValidItemCount = ValidItemCount + 1
        end
    end
    
    if ValidItemCount == 0 then
        self:Info("Container " .. ContainerId .. " has no valid items")
        return false
    end
    
    self:Info("=== Container " .. ContainerId .. " Contents ===")
    self:Info("Valid items: " .. ValidItemCount .. " / " .. #Items .. " total slots")
    print("")

    -- Safe iteration with bounds checking
    for I = 1, #Items do
        local Item = Items[I]
        local ItemName = nil
        if Item and Item.item_id and Item.item_id >= 0 and Item.Get then
            local Success, ItemData = pcall(Item.Get, Item, Item.item_id)
            if Success and ItemData and ItemData.name then
                ItemName = ItemData.name
            end
        elseif Item and Item.item_id and Item.item_id >= 0 and Item.Get == nil and Item.Get ~= nil then
            -- fallback if Item is not a class instance, try global Item
            if Item.Get then
                local Success, ItemData = pcall(Item.Get, Item.item_id)
                if Success and ItemData and ItemData.name then
                    ItemName = ItemData.name
                end
            end
        elseif _G.Item and _G.Item.Get then
            local Success, ItemData = pcall(_G.Item.Get, _G.Item, Item.item_id)
            if Success and ItemData and ItemData.name then
                ItemName = ItemData.name
            end
        end
        
        -- Check if item exists and is valid
        if not Item then
            self:Warn("Skipping nil item at slot " .. I)
            goto continue
        end
        
        if type(Item) ~= "table" and type(Item) ~= "userdata" then
            self:Warn("Skipping invalid item at slot " .. I .. " (type: " .. type(Item) .. ")")
            goto continue
        end
        
        -- Only print items that have a valid item_id (>= 0)
        if not Item.item_id or Item.item_id < 0 then
            goto continue
        end
        
        -- Format item information with nice borders
        print("+========================+")
        print("|      ITEM SLOT #" .. I .. "      |")
        print("+========================+")
        print("|   Item Name      : " .. tostring(ItemName or "N/A"))
        print("|   Item ID        : " .. tostring(Item.item_id or "N/A"))
        print("|   Item Stack     : " .. tostring(Item.item_stack or "N/A"))
        print("|   Item Slot      : " .. tostring(Item.item_slot or "N/A"))
        
        -- Print Extra_mem table if it exists
        print("|   Extra_mem      :")
        if Item.Extra_mem then
            if type(Item.Extra_mem) == "table" or type(Item.Extra_mem) == "userdata" then
                local MemCount = 0
                for K, V in pairs(Item.Extra_mem) do
                    print("|     " .. tostring(K) .. " : " .. tostring(V))
                    MemCount = MemCount + 1
                end
                if MemCount == 0 then
                    print("|     (empty)")
                end
            else
                print("|     (type: " .. type(Item.Extra_mem) .. ", value: " .. tostring(Item.Extra_mem) .. ")")
            end
        else
            print("|     N/A")
        end
        
        -- Print Extra_ints table if it exists
        print("|   Extra_ints     :")
        if Item.Extra_ints then
            if type(Item.Extra_ints) == "table" or type(Item.Extra_ints) == "userdata" then
                local IntCount = 0
                for K, V in pairs(Item.Extra_ints) do
                    print("|     " .. tostring(K) .. " : " .. tostring(V))
                    IntCount = IntCount + 1
                end
                if IntCount == 0 then
                    print("|     (empty)")
                end
            else
                print("|     (type: " .. type(Item.Extra_ints) .. ", value: " .. tostring(Item.Extra_ints) .. ")")
            end
        else
            print("|     N/A")
        end
        
        print("+========================+")
        print("")
        
        ::continue::
    end
    
    self:Info("Container scan completed successfully")
    return true
end

-- Prints all abilities from specified ability bar(s)
---@param BarId number|table
---@return boolean Success
function Slib:PrintAbilityBar(BarId)
    -- Parameter validation
    if not self:Sanitize(BarId, {"number", "table_of_numbers"}, "BarId") then
        return false
    end
    
    -- Ensure BarId is a table for consistent processing
    local BarTable = type(BarId) == "table" and BarId or {BarId}
    
    -- Validate range (0-4) for each bar ID
    for I, Bar in ipairs(BarTable) do
        if Bar < 0 or Bar > 4 then
            self:Error("BarId must be between 0-4, got: " .. Bar .. " at index " .. I)
            return false
        end
    end
    
    local TotalAbilities = 0
    local ProcessedBars = 0
    
    -- Process each ability bar
    for _, Bar in ipairs(BarTable) do
        local BarInfo = API.GetABarInfo(Bar)
        
        if not BarInfo then
            self:Warn("Unable to get ability bar " .. Bar)
            goto continue
        end
        
        if type(BarInfo) ~= "table" and type(BarInfo) ~= "userdata" then
            self:Warn("Invalid data type for bar " .. Bar .. ": " .. type(BarInfo))
            goto continue
        end
        
        if #BarInfo == 0 then
            self:Info("Ability bar " .. Bar .. " is empty")
            goto continue
        end
        
        -- Count valid abilities in this bar
        local ValidAbilities = 0
        for I = 1, #BarInfo do
            local Ability = BarInfo[I]
            if Ability and Ability.id and Ability.id ~= 65535 then
                ValidAbilities = ValidAbilities + 1
            end
        end
        
        if ValidAbilities == 0 then
            self:Info("No valid abilities found in bar " .. Bar)
            goto continue
        end
        
        self:Info("=== Ability Bar " .. Bar .. " ===")
        self:Info("Found " .. ValidAbilities .. " abilities:")
        print("")
        
        -- Safe iteration through abilities
        for I = 1, #BarInfo do
            local Ability = BarInfo[I]
            
            -- Check if ability exists and is valid
            if not Ability then
                self:Warn("Skipping nil ability at slot " .. I .. " in bar " .. Bar)
                goto continue_ability
            end
            
            if type(Ability) ~= "table" and type(Ability) ~= "userdata" then
                self:Warn("Skipping invalid ability at slot " .. I .. " in bar " .. Bar .. " (type: " .. type(Ability) .. ")")
                goto continue_ability
            end
            
            -- Skip empty/invalid abilities (ID 65535 is empty slot)
            if not Ability.id or Ability.id == 65535 then
                goto continue_ability
            end
            
            -- Format ability information with nice borders
            print("+========================+")
            print("|     ABILITY SLOT #" .. string.format("%-2s", I) .. "   |")
            print("|        (Bar " .. Bar .. ")         |")
            print("+========================+")
            print("|   slot           : " .. tostring(Ability.slot or "N/A"))
            print("|   id             : " .. tostring(Ability.id or "N/A"))
            print("|   name           : " .. tostring(Ability.name or "N/A"))
            print("|   hotkey         : " .. tostring(Ability.hotkey or "N/A"))
            print("|   cooldown_timer : " .. tostring(Ability.cooldown_timer or "N/A"))
            print("|   action         : " .. tostring(Ability.action or "N/A"))
            print("|   enabled        : " .. tostring(Ability.enabled or "N/A"))

            -- Print ability info if it exists
            if Ability.info then
                local Info = Ability.info
                print("|                        ")
                print("|     --- info ---       ")
                print("|   x              : " .. tostring(Info.x or "N/A"))
                print("|   xs             : " .. tostring(Info.xs or "N/A"))
                print("|   y              : " .. tostring(Info.y or "N/A"))
                print("|   ys             : " .. tostring(Info.ys or "N/A"))
                print("|   box_x          : " .. tostring(Info.box_x or "N/A"))
                print("|   box_y          : " .. tostring(Info.box_y or "N/A"))
                print("|   scroll_y       : " .. tostring(Info.scroll_y or "N/A"))
                print("|   id1            : " .. tostring(Info.id1 or "N/A"))
                print("|   id2            : " .. tostring(Info.id2 or "N/A"))
                print("|   id3            : " .. tostring(Info.id3 or "N/A"))
                print("|   itemid1        : " .. tostring(Info.itemid1 or "N/A"))
                print("|   itemid1_size   : " .. tostring(Info.itemid1_size or "N/A"))
                print("|   itemid2        : " .. tostring(Info.itemid2 or "N/A"))
                print("|   hov            : " .. tostring(Info.hov or "N/A"))
                print("|   textids        : " .. tostring(Info.textids or "N/A"))
                print("|   textitem       : " .. tostring(Info.textitem or "N/A"))
                print("|   memloc         : " .. tostring(Info.memloc or "N/A"))
                print("|   memloctop      : " .. tostring(Info.memloctop or "N/A"))
                print("|   index          : " .. tostring(Info.index or "N/A"))
                print("|   fullpath       : " .. tostring(Info.fullpath or "N/A"))
                print("|   fullIDpath     : " .. tostring(Info.fullIDpath or "N/A"))
                print("|   notvisible     : " .. tostring(Info.notvisible or "N/A"))
                print("|   OP             : " .. tostring(Info.OP or "N/A"))
                print("|   xy             : " .. tostring(Info.xy or "N/A"))
                print("|   xy.x           : " .. tostring(Info.xy.x or "N/A"))
                print("|   xy.y           : " .. tostring(Info.xy.y or "N/A"))
            else
                print("|   info           : N/A")
            end
            
            print("+========================+")
            print("")
            
            TotalAbilities = TotalAbilities + 1
            
            ::continue_ability::
        end
        
        ProcessedBars = ProcessedBars + 1
        
        ::continue::
    end
    
    if ProcessedBars == 0 then
        self:Error("No ability bars could be processed")
        return false
    end
    
    self:Info("Ability scan completed - processed " .. ProcessedBars .. " bar(s) with " .. TotalAbilities .. " total abilities")
    return true
end

-- Prints all objects with specified parameters
---@param Id number|table
---@param Range number
---@param Type number|table
---@return boolean Success
function Slib:PrintObjects(Id, Range, Type)
    -- Parameter validation
    if not self:ValidateParams({
        {Id, {"number", "table_of_numbers"}, "Id"},
        {Range, "non_negative_number", "Range"},
        {Type, {"number", "table_of_numbers"}, "Type"}
    }) then
        return false
    end
    
    -- Ensure Id and Type are tables
    local IdTable = type(Id) == "table" and Id or {Id}
    local TypeTable = type(Type) == "table" and Type or {Type}
    
    -- Direct API call
    local Objects = API.GetAllObjArray1(IdTable, Range, TypeTable)
    
    -- Check if API returned valid data
    if not Objects then
        self:Error("API returned nil")
        return false
    end
    
    if type(Objects) ~= "table" and type(Objects) ~= "userdata" then
        self:Error("API returned invalid data type: " .. type(Objects))
        return false
    end
    
    if #Objects == 0 then
        self:Info("No objects found matching criteria")
        return false
    end
    
    self:Info("Found " .. #Objects .. " objects:")
    
    -- Safe iteration with bounds checking
    for I = 1, #Objects do
        local Object = Objects[I]
        
        -- Check if object exists and is valid
        if not Object then
            self:Warn("Skipping nil object at index " .. I)
            goto continue
        end
        
        if type(Object) ~= "table" and type(Object) ~= "userdata" then
            self:Warn("Skipping invalid object at index " .. I .. " (type: " .. type(Object) .. ")")
            goto continue
        end
        
        -- Direct object printing
        print("+==============================+")
        print("|          OBJECT #" .. I .. "           |")
        print("+==============================+")
        print("|    Name           : " .. tostring(Object.Name or "N/A"))
        print("|    Id             : " .. tostring(Object.Id or "N/A"))
        print("|    Type           : " .. tostring(Object.Type or "N/A"))
        print("|    Life           : " .. tostring(Object.Life or "N/A"))
        print("|    Action         : " .. tostring(Object.Action or "N/A"))
        print("|    Anim           : " .. tostring(Object.Anim or "N/A"))
        print("|    Amount         : " .. tostring(Object.Amount or "N/A"))
        print("|    Distance       : " .. tostring(Object.Distance or "N/A"))
        print("|    Floor          : " .. tostring(Object.Floor or "N/A"))
        print("|    CalcX          : " .. tostring(Object.CalcX or "N/A"))
        print("|    CalcY          : " .. tostring(Object.CalcY or "N/A"))
        print("|    TileX          : " .. tostring(Object.TileX or "N/A") .. " (÷512: " .. tostring(Object.TileX and (Object.TileX/512) or "N/A") .. ")")
        print("|    TileY          : " .. tostring(Object.TileY or "N/A") .. " (÷512: " .. tostring(Object.TileY and (Object.TileY/512) or "N/A") .. ")")
        print("|    TileZ          : " .. tostring(Object.TileZ or "N/A") .. " (÷512: " .. tostring(Object.TileZ and (Object.TileZ/512) or "N/A") .. ")")
        print("|    Tile_XYZ.x     : " .. tostring(Object.Tile_XYZ and Object.Tile_XYZ.x or "N/A"))
        print("|    Tile_XYZ.y     : " .. tostring(Object.Tile_XYZ and Object.Tile_XYZ.y or "N/A"))
        print("|    Tile_XYZ.z     : " .. tostring(Object.Tile_XYZ and Object.Tile_XYZ.z or "N/A"))
        print("|    Pixel_XYZ.x    : " .. tostring(Object.Pixel_XYZ and Object.Pixel_XYZ.x or "N/A"))
        print("|    Pixel_XYZ.y    : " .. tostring(Object.Pixel_XYZ and Object.Pixel_XYZ.y or "N/A"))
        print("|    Pixel_XYZ.z    : " .. tostring(Object.Pixel_XYZ and Object.Pixel_XYZ.z or "N/A"))
        print("|    Mem            : " .. tostring(Object.Mem or "N/A"))
        print("|    MemE           : " .. tostring(Object.MemE or "N/A"))
        print("|    Unique_Id      : " .. tostring(Object.Unique_Id or "N/A"))
        print("|    Cmb_lv         : " .. tostring(Object.Cmb_lv or "N/A"))
        print("|    ItemIndex      : " .. tostring(Object.ItemIndex or "N/A"))
        print("|    Bool1          : " .. tostring(Object.Bool1 or "N/A"))
        print("|    ViewP          : " .. tostring(Object.ViewP or "N/A"))
        print("|    ViewF          : " .. tostring(Object.ViewF or "N/A"))
        print("+==============================+")
        print("")
        
        ::continue::
    end
    
    return true
end

-- Prints info about specified VarBit(s)
---@param Vb number|table
---@return boolean Success
function Slib:PrintVb(Vb)
    -- Parameter validation
    if not self:Sanitize(Vb, {"number", "table_of_numbers"}, "Vb") then
        return false
    end
    
    -- Ensure Vb is a table for consistent processing
    local VbTable = type(Vb) == "table" and Vb or {Vb}
    
    local TotalFound = 0
    local ProcessedVbs = 0
    
    -- Process each VarBit
    for _, VbId in ipairs(VbTable) do
        local Var = API.VB_FindPSettinOrder(VbId)
        
        if not Var then
            self:Warn("VarBit " .. VbId .. " not found")
            goto continue
        end
        
        if type(Var) ~= "table" and type(Var) ~= "userdata" then
            self:Warn("Invalid data type for VarBit " .. VbId .. ": " .. type(Var))
            goto continue
        end
        
        -- Format VarBit information with nice borders
        print("+========================+")
        print("|      VARBIT #" .. string.format("%-2s", VbId) .. "      |")
        print("+========================+")
        print("|   id             : " .. tostring(Var.id or "N/A"))
        print("|   state          : " .. tostring(Var.state or "N/A"))
        print("|   addr           : " .. tostring(Var.addr or "N/A"))
        print("|   indexaddr_orig : " .. tostring(Var.indexaddr_orig or "N/A"))
        print("+========================+")
        print("")
        
        TotalFound = TotalFound + 1
        ProcessedVbs = ProcessedVbs + 1
        
        ::continue::
    end
    
    if ProcessedVbs == 0 then
        self:Error("No VarBits could be processed")
        return false
    end
    
    self:Info("VarBit scan completed - processed " .. ProcessedVbs .. " VarBit(s), found " .. TotalFound .. " valid")
    return true
end

-- Prints detailed information about interface elements
---@param TargetUnder boolean
---@param InterfaceToScan table
---@return boolean Success
function Slib:PrintInterfaceInfo(TargetUnder, InterfaceToScan)
    -- Parameter validation
    if not self:ValidateParams({
        {TargetUnder, "boolean", "TargetUnder"},
        {InterfaceToScan, "table", "InterfaceToScan"}
    }) then
        return false
    end
    
    -- API call to get interface elements
    local Interface = API.ScanForInterfaceTest2Get(TargetUnder, InterfaceToScan)
    
    if not Interface then
        self:Error("Failed to scan interface")
        return false
    end
    
    if type(Interface) ~= "table" and type(Interface) ~= "userdata" then
        self:Error("Invalid data type returned from API: " .. type(Interface))
        return false
    end
    
    if #Interface == 0 then
        self:Info("No interface elements found")
        return false
    end
    
    self:Info("Found " .. #Interface .. " interface elements:")
    print("")
    
    -- Safe iteration through interface elements
    for I = 1, #Interface do
        local Element = Interface[I]
        
        -- Check if element exists and is valid
        if not Element then
            self:Warn("Skipping nil element at index " .. I)
            goto continue_element
        end
        
        if type(Element) ~= "table" and type(Element) ~= "userdata" then
            self:Warn("Skipping invalid element at index " .. I .. " (type: " .. type(Element) .. ")")
            goto continue_element
        end
        
        -- Format interface element information with nice borders
        print("+=============================================+")
        print("|       ELEMENT #" .. string.format("%-2s", I) .. "                    |")
        print("+=============================================+")
        print("|   x              : " .. tostring(Element.x or "N/A"))
        print("|   xs             : " .. tostring(Element.xs or "N/A"))
        print("|   y              : " .. tostring(Element.y or "N/A"))
        print("|   ys             : " .. tostring(Element.ys or "N/A"))
        print("|   box_x          : " .. tostring(Element.box_x or "N/A"))
        print("|   box_y          : " .. tostring(Element.box_y or "N/A"))
        print("|   scroll_y       : " .. tostring(Element.scroll_y or "N/A"))
        print("|   id1            : " .. tostring(Element.id1 or "N/A"))
        print("|   id2            : " .. tostring(Element.id2 or "N/A"))
        print("|   id3            : " .. tostring(Element.id3 or "N/A"))
        print("|   itemid1        : " .. tostring(Element.itemid1 or "N/A"))
        print("|   itemid1_size   : " .. tostring(Element.itemid1_size or "N/A"))
        print("|   itemid2        : " .. tostring(Element.itemid2 or "N/A"))
        print("|   hov            : " .. tostring(Element.hov or "N/A"))
        print("|   textids        : " .. tostring(Element.textids or "N/A"))
        print("|   textitem       : " .. tostring(Element.textitem or "N/A"))
        print("|   memloc         : " .. tostring(Element.memloc or "N/A"))
        print("|   memloctop      : " .. tostring(Element.memloctop or "N/A"))
        print("|   index          : " .. tostring(Element.index or "N/A"))
        print("|   fullpath       : " .. tostring(Element.fullpath or "N/A"))
        print("|   fullIDpath     : " .. tostring(Element.fullIDpath or "N/A"))
        print("|   notvisible     : " .. tostring(Element.notvisible or "N/A"))
        print("|   OP             : " .. tostring(Element.OP or "N/A"))
        print("|   xy             : " .. tostring(Element.xy or "N/A"))
        print("|   xy.x           : " .. tostring(Element.xy.x or "N/A"))
        print("|   xy.y           : " .. tostring(Element.xy.y or "N/A"))
        
        -- Add memory read information if memloc is available
        if Element.memloc and type(Element.memloc) == "number" then
            print("|                                ")
            print("|     --- MEMORY READS ---       ")
            print("|                                ")
            
            -- Define API constants
            local ApiConstants = {
                {name = "I_00textP", value = API.I_00textP},
                {name = "I_itemids3", value = API.I_itemids3},
                {name = "I_itemids", value = API.I_itemids},
                {name = "I_itemstack", value = API.I_itemstack},
                {name = "I_slides", value = API.I_slides},
                {name = "I_buffb", value = API.I_buffb}
            }
            
            -- Group memory reads by function type
            local MemReadGroups = {
                {
                    name = "Mem_Read_char",
                    func = API.Mem_Read_char,
                    reads = {
                        {name = "memloc", offset = 0}
                    }
                },
                {
                    name = "Mem_Read_short", 
                    func = API.Mem_Read_short,
                    reads = {
                        {name = "memloc", offset = 0}
                    }
                },
                {
                    name = "Mem_Read_int",
                    func = API.Mem_Read_int,
                    reads = {
                        {name = "memloc", offset = 0}
                    }
                },
                {
                    name = "Mem_Read_uint64",
                    func = API.Mem_Read_uint64,
                    reads = {
                        {name = "memloc", offset = 0}
                    }
                },
                {
                    name = "ReadCharsLimit",
                    func = API.ReadCharsLimit,
                    reads = {}
                }
            }
            
            -- Add constant combinations to each group
            for _, Constant in ipairs(ApiConstants) do
                if Constant.value and type(Constant.value) == "number" then
                    -- Add to Mem_Read functions
                    for _, Group in ipairs(MemReadGroups) do
                        if Group.name ~= "ReadCharsLimit" then
                            table.insert(Group.reads, {name = "memloc+" .. Constant.name, offset = Constant.value})
                        end
                    end
                    
                    -- Add to ReadCharsLimit group
                    table.insert(MemReadGroups[5].reads, {name = "memloc+" .. Constant.name, offset = Constant.value, limit = 255})
                end
            end
            
            -- Build all function names first to determine max width
            local allFunctionNames = {}
            for _, Group in ipairs(MemReadGroups) do
                for _, Read in ipairs(Group.reads) do
                    local FunctionName = Group.name .. "(" .. Read.name .. ")"
                    if Group.func == API.ReadCharsLimit then
                        FunctionName = Group.name .. "(" .. Read.name .. ", 255)"
                    end
                    table.insert(allFunctionNames, FunctionName)
                end
            end
            local maxFuncNameLen = 0
            for _, name in ipairs(allFunctionNames) do
                if #name > maxFuncNameLen then maxFuncNameLen = #name end
            end
            maxFuncNameLen = math.max(maxFuncNameLen, 20)  -- minimum width for aesthetics
            local formatString = string.format("|   %%-%ds : %%s", maxFuncNameLen)

            -- Process each group
            local funcIdx = 1
            for _, Group in ipairs(MemReadGroups) do
                for _, Read in ipairs(Group.reads) do
                    local FunctionName = Group.name .. "(" .. Read.name .. ")"
                    if Group.func == API.ReadCharsLimit then
                        FunctionName = Group.name .. "(" .. Read.name .. ", 255)"
                    end
                    local Success, Result = pcall(function()
                        if Group.func == API.ReadCharsLimit then
                            return Group.func(Element.memloc + Read.offset, Read.limit)
                        else
                            return Group.func(Element.memloc + Read.offset)
                        end
                    end)
                    if Success and Result then
                        local FormattedResult
                        local ResultType = type(Result)
                        if ResultType == "number" then
                            -- Helper function to safely format numbers
                            local function SafeFormat(result, hexFormat, hexWidth)
                                -- Check if number is finite and within safe integer range
                                if result ~= result then -- NaN check
                                    return "NaN"
                                elseif result == math.huge then
                                    return "Infinity"
                                elseif result == -math.huge then
                                    return "-Infinity"
                                elseif math.abs(result) > 9007199254740991 then -- 2^53 - 1 (safe integer limit)
                                    return string.format("%.0f (too large for hex)", result)
                                elseif result < 0 then
                                    return string.format("%.0f (negative)", result)
                                elseif math.floor(result) ~= result then
                                    return string.format("%.6f (fractional)", result)
                                else
                                    -- Safe to format as integer and hex
                                    local success, formattedHex = pcall(string.format, hexFormat, result)
                                    local success2, formattedDec = pcall(string.format, "%.0f", result)
                                    if success and success2 then
                                        return formattedHex .. " (" .. formattedDec .. ")"
                                    else
                                        return tostring(result) .. " (format error)"
                                    end
                                end
                            end
                            
                            if Group.func == API.Mem_Read_char then
                                FormattedResult = SafeFormat(Result, "0x%02X", 2)
                            elseif Group.func == API.Mem_Read_short then
                                FormattedResult = SafeFormat(Result, "0x%04X", 4)
                            elseif Group.func == API.Mem_Read_int then
                                FormattedResult = SafeFormat(Result, "0x%08X", 8)
                            elseif Group.func == API.Mem_Read_uint64 then
                                FormattedResult = SafeFormat(Result, "0x%016X", 16)
                            else
                                FormattedResult = tostring(Result)
                            end
                        elseif ResultType == "string" then
                            if Result == "" then
                                FormattedResult = '"" (empty string)'
                            else
                                local EscapedResult = string.gsub(Result, "[\0-\31\127-\255]", function(c)
                                    local byteVal = string.byte(c)
                                    if byteVal and byteVal >= 0 and byteVal <= 255 then
                                        return string.format("\\x%02X", byteVal)
                                    else
                                        return "\\x??"
                                    end
                                end)
                                if string.len(EscapedResult) > 50 then
                                    EscapedResult = string.sub(EscapedResult, 1, 47) .. "..."
                                end
                                FormattedResult = '"' .. EscapedResult .. '"'
                            end
                        else
                            -- Handle other types (boolean, table, etc.)
                            FormattedResult = tostring(Result) .. " (" .. ResultType .. ")"
                        end
                        
                        -- Create function name with proper alignment
                        local FunctionName = Group.name .. "(" .. Read.name .. ")"
                        if Group.func == API.ReadCharsLimit then
                            FunctionName = Group.name .. "(" .. Read.name .. ", 255)"
                        end
                        
                        print(string.format(formatString, FunctionName, FormattedResult))
                    else
                        -- Create function name with proper alignment
                        local FunctionName = Group.name .. "(" .. Read.name .. ")"
                        if Group.func == API.ReadCharsLimit then
                            FunctionName = Group.name .. "(" .. Read.name .. ", 255)"
                        end
                        
                        local ErrorMsg = "Error"
                        if not Success then
                            ErrorMsg = "Failed"
                        elseif not Result then
                            ErrorMsg = "No Result"
                        end
                        
                        print(string.format(formatString, FunctionName, ErrorMsg))
                    end
                end
            end
        else
            print("|                                ")
            print("|     --- MEMORY READS ---       ")
            print("|   No memloc available          ")
        end
        
        print("+=============================================+")
        print("")
        
        ::continue_element::
    end
    
    self:Info("Interface scan completed successfully")
    return true
end

-- Prints all fields of a QuestData object
---@param QuestIdsOrNames number|string|table
---@return boolean Success
function Slib:PrintQuestData(QuestIdsOrNames)
    -- Parameter validation
    if not self:Sanitize(QuestIdsOrNames, {"number", "string", "table_of_strings", "table_of_numbers"}, "QuestIdsOrNames") then
        return false
    end
    
    -- Ensure QuestIdsOrNames is a table for consistent processing
    local QuestTable = type(QuestIdsOrNames) == "table" and QuestIdsOrNames or {QuestIdsOrNames}
    
    local TotalFound = 0
    local ProcessedQuests = 0
    
    -- Process each quest
    for _, QuestId in ipairs(QuestTable) do
        -- API call to get quest data
        local QuestData = Quest:Get(QuestId)
        
        if not QuestData then
            self:Warn("Quest not found: " .. tostring(QuestId))
            goto continue
        end
        
        if type(QuestData) ~= "table" and type(QuestData) ~= "userdata" then
            self:Warn("Invalid quest data type for " .. tostring(QuestId) .. ": " .. type(QuestData))
            goto continue
        end

        self:Info("=== Quest: " .. tostring(QuestId) .. " ===")
        print("")
    
        -- Format quest information with nice borders
        print("+================================+")
        print("|           QUEST DATA           |")
        print("+================================+")
        print("|   id                 : " .. tostring(QuestData.id or "N/A"))
        print("|   name               : " .. tostring(QuestData.name or "N/A"))
        print("|   list_name          : " .. tostring(QuestData.list_name or "N/A"))
        print("|   members            : " .. tostring(QuestData.members or "N/A"))
        print("|   category           : " .. tostring(QuestData.category or "N/A"))
        print("|   difficulty         : " .. tostring(QuestData.difficulty or "N/A"))
        print("|   points_reward      : " .. tostring(QuestData.points_reward or "N/A"))
        print("|   points_required    : " .. tostring(QuestData.points_required or "N/A"))
        print("|   progress_start_bit : " .. tostring(QuestData.progress_start_bit or "N/A"))
        print("|   progress_end_bit   : " .. tostring(QuestData.progress_end_bit or "N/A"))
        print("|   progress_varbit    : " .. tostring(QuestData.progress_varbit or "N/A"))
        print("|                                ")
        print("|     --- Methods ---            ")
        
        -- Call methods safely
        if QuestData.getProgress then
            local Success, Progress = pcall(QuestData.getProgress, QuestData)
            print("|   getProgress()      : " .. tostring(Success and Progress or "Error"))
        else
            print("|   getProgress()      : N/A")
        end
        
        if QuestData.isStarted then
            local Success, Started = pcall(QuestData.isStarted, QuestData)
            print("|   isStarted()        : " .. tostring(Success and Started or "Error"))
        else
            print("|   isStarted()        : N/A")
        end
        
        if QuestData.isComplete then
            local Success, Complete = pcall(QuestData.isComplete, QuestData)
            print("|   isComplete()       : " .. tostring(Success and Complete or "Error"))
        else
            print("|   isComplete()       : N/A")
        end
        
        print("|                                ")
        print("|   --- Required Quests ---      ")
        
        -- Print required quests with debugging
        if QuestData.required_quests then
            if (type(QuestData.required_quests) == "table" or type(QuestData.required_quests) == "userdata") and #QuestData.required_quests > 0 then
                for I, ReqQuest in ipairs(QuestData.required_quests) do
                    if ReqQuest and (type(ReqQuest) == "table" or type(ReqQuest) == "userdata") then
                        local ReqQuestId = tostring(ReqQuest.id or "N/A")
                        local ReqQuestName = tostring(ReqQuest.name or "N/A")
                        -- Split long lines to fit within border
                        print("|   [" .. I .. "] ID: " .. ReqQuestId)
                        if string.len(ReqQuestName) > 25 then
                            print("|       Name: " .. string.sub(ReqQuestName, 1, 22) .. "...")
                        else
                            print("|       Name: " .. ReqQuestName)
                        end
                    else
                        print("|   [" .. I .. "] Invalid quest data     ")
                    end
                end
            else
                print("|   None                         ")
            end
        else
            print("|   N/A                          ")
        end

        print("|                                ")
        print("|   --- Required Skills ---      ")
        
        -- Print required skills with debugging  
        if QuestData.required_skills then
            if (type(QuestData.required_skills) == "table" or type(QuestData.required_skills) == "userdata") and #QuestData.required_skills > 0 then
                for I, Skill in ipairs(QuestData.required_skills) do
                    if Skill and (type(Skill) == "table" or type(Skill) == "userdata") then
                        local SkillId = Skill.id or "N/A"
                        local SkillLevel = tostring(Skill.level or "N/A")
                        
                        -- Get skill name from API
                        local SkillName = "Unknown"
                        if SkillId ~= "N/A" then
                            local SkillData = API.GetSkillById(SkillId)
                            if SkillData and SkillData.name then
                                SkillName = SkillData.name
                            else
                                SkillName = "ID:" .. tostring(SkillId)
                            end
                        end
                        
                        print("|   [" .. I .. "] " .. SkillName .. " Level: " .. SkillLevel)
                    else
                        print("|   [" .. I .. "] Invalid skill data    ")
                    end
                end
            else
                print("|   None                         ")
            end
        else
            print("|   N/A                          ")
        end
        
        print("+================================+")
        print("")
        
        TotalFound = TotalFound + 1
        ProcessedQuests = ProcessedQuests + 1
        
        ::continue::
    end
    
    if ProcessedQuests == 0 then
        self:Error("No quests could be processed")
        return false
    end
    
    self:Info("Quest data scan completed - processed " .. ProcessedQuests .. " quest(s), found " .. TotalFound .. " valid")
    return true
end

-- Prints all items in the currency pouch with detailed information
---@return boolean Success True if currency pouch items were found and printed, false if no items or error occurred
function Slib:PrintCurrencyPouch()
    if not self.Interfaces or not self.Interfaces.CurrencyPouch then
        self:Error("CurrencyPouch interface not defined")
        return false
    end
    
    local TotalFound = 0
    local ProcessedInterfaces = 0
    
    -- Process each interface configuration
    for I = 1, #self.Interfaces.CurrencyPouch do
        local Interface = API.ScanForInterfaceTest2Get(true, self.Interfaces.CurrencyPouch[I])
        
        -- Count valid items in this interface
        local ValidItems = 0
        for _, Item in pairs(Interface) do
            if Item and Item.itemid1 and Item.itemid1 >= 0 then
                ValidItems = ValidItems + 1
            end
        end
        
        if ValidItems > 0 then
            self:Info("=== Currency Pouch Interface " .. I .. " ===")
            self:Info("Found " .. ValidItems .. " items:")
            print("")
            
            -- Process each item
            for _, Item in pairs(Interface) do
                if Item and Item.itemid1 and Item.itemid1 >= 0 then
                    -- Format item information with nice borders
                    print("+================================+")
                    print("|        CURRENCY ITEM           |")
                    print("+================================+")
                    print("|   Item ID         : " .. tostring(Item.itemid1))
                    print("|   Amount/Text     : " .. tostring(Item.textitem or "N/A"))
                    
                    -- Add additional fields if they exist
                    if Item.id1 then print("|   id1            : " .. tostring(Item.id1)) end
                    if Item.id2 then print("|   id2            : " .. tostring(Item.id2)) end
                    if Item.id3 then print("|   id3            : " .. tostring(Item.id3)) end
                    if Item.memloc then print("|   memloc         : " .. tostring(Item.memloc)) end
                    if Item.textids then print("|   textids        : " .. tostring(Item.textids)) end
                    
                    print("+================================+")
                    print("")
                    
                    TotalFound = TotalFound + 1
                end
            end
        end
        
        ProcessedInterfaces = ProcessedInterfaces + 1
        
        ::continue::
    end
    
    if ProcessedInterfaces == 0 then
        self:Error("No currency pouch interfaces could be processed")
        return false
    end
    
    if TotalFound == 0 then
        self:Info("No currency items found in pouch")
        return false
    end
    
    self:Info("Currency pouch scan completed - processed " .. ProcessedInterfaces .. " interface(s), found " .. TotalFound .. " items")
    return true
end

-- Prints a table's contents in a formatted, readable way
---@param Tbl table The table to print (supports nested tables)
---@return boolean success True if table was printed successfully, false if invalid table
function Slib:PrintTable(Tbl)
    -- Parameter validation
    if not self:Sanitize(Tbl, "table", "Tbl") then
        return false
    end
    
    -- Try to get the variable name from debug info
    local TableName = "Table"
    
    -- Helper function to recursively print table contents
    local function printTableRecursive(tbl, indent)
        local spacing = string.rep("  ", indent)
        
        -- Sort keys for consistent output
        local keys = {}
        for key in pairs(tbl) do
            table.insert(keys, key)
        end
        
        table.sort(keys, function(a, b)
            local aType = type(a)
            local bType = type(b)
            if aType == bType then
                return tostring(a) < tostring(b)
            else
                return aType == "number" and bType ~= "number"
            end
        end)
        
        for _, key in ipairs(keys) do
            local value = tbl[key]
            local keyStr = type(key) == "string" and key or "[" .. tostring(key) .. "]"
            
            if type(value) == "table" then
                print(spacing .. keyStr .. " = {")
                printTableRecursive(value, indent + 1)
                print(spacing .. "}")
            elseif type(value) == "string" then
                print(spacing .. keyStr .. ' = "' .. tostring(value) .. '"')
            elseif type(value) == "function" then
                print(spacing .. keyStr .. " = [Function]")
            elseif type(value) == "userdata" then
                print(spacing .. keyStr .. " = [UserData]")
            else
                print(spacing .. keyStr .. " = " .. tostring(value))
            end
        end
    end
    
    -- Check if table is empty
    if next(Tbl) == nil then
        print(TableName .. " = {} (empty)")
        return true
    end
    
    -- Print the table
    print(TableName .. " = {")
    printTableRecursive(Tbl, 1)
    print("}")
    
    return true
end

-- ##################################
-- #                                #
-- #       HELPER FUNCTIONS         #
-- #                                #
-- ##################################

-- Checks if the player is in a specified area (circular radius)
---@param X number The center X coordinate
---@param Y number The center Y coordinate  
---@param Z number The Z coordinate (floor/plane)
---@param Radius number The radius in tiles (must be non-negative)
---@return boolean inArea True if player is within the specified circular area, false otherwise
function Slib:IsPlayerInArea(X, Y, Z, Radius)
    -- Parameter validation
    if not self:ValidateParams({
        {X, "number", "X"},
        {Y, "number", "Y"},
        {Z, "number", "Z"},
        {Radius, "non_negative_number", "Radius"}
    }) then
        return false
    end
    
    -- Get player coordinates safely
    local Coord = API.PlayerCoord()
    if not Coord then
        self:Error("Failed to get player coordinates")
        return false
    end
    
    -- Calculate distance
    local Dx = Coord.x - X
    local Dy = Coord.y - Y
    local Distance = math.sqrt(Dx^2 + Dy^2)
    
    -- Check if player is in area
    local InArea = Distance <= Radius and Coord.z == Z
    return InArea
end

-- Checks if the player is in a rectangular area
---@param MinX number The minimum X coordinate (left boundary)
---@param MaxX number The maximum X coordinate (right boundary)
---@param MinY number The minimum Y coordinate (top boundary)
---@param MaxY number The maximum Y coordinate (bottom boundary)
---@param Z number The Z coordinate (floor/plane)
---@return boolean inArea True if player is within the specified rectangular area, false otherwise
function Slib:IsPlayerInRectangle(MinX, MaxX, MinY, MaxY, Z)
    -- Parameter validation
    if not self:ValidateParams({
        {MinX, "number", "MinX"},
        {MaxX, "number", "MaxX"},
        {MinY, "number", "MinY"},
        {MaxY, "number", "MaxY"},
        {Z, "number", "Z"}
    }) then
        return false
    end
    
    local Coord = API.PlayerCoord()
    if not Coord then
        self:Error("Failed to get player coordinates")
        return false
    end
    
    local InArea = Coord.x >= MinX and Coord.x <= MaxX and 
                   Coord.y >= MinY and Coord.y <= MaxY and 
                   Coord.z == Z
    
    return InArea
end

-- Checks if the player is at the specified coordinates
---@param X number The exact X coordinate
---@param Y number The exact Y coordinate
---@param Z number The exact Z coordinate (floor/plane)
---@return boolean atCoords True if player is at the exact coordinates, false otherwise
function Slib:IsPlayerAtCoords(X, Y, Z)
    -- Parameter validation
    if not self:ValidateParams({
        {X, "number", "X"},
        {Y, "number", "Y"},
        {Z, "number", "Z"}
    }) then
        return false
    end
    
    -- Get player coordinates safely
    local Coord = API.PlayerCoord()
    if not Coord then
        self:Error("Failed to get player coordinates")
        return false
    end
    
    local AtCoords = Coord.x == X and Coord.y == Y and Coord.z == Z
    return AtCoords
end

-- Gets the current instance timer text
---@return string timerText The instance timer text, or empty string if not found/unavailable
function Slib:GetInstanceTimer()
    if not self.Interfaces or not self.Interfaces.InstanceTimer then
        self:Error("InstanceTimer interface not defined")
        return ""
    end
    
    local Result = API.ScanForInterfaceTest2Get(false, self.Interfaces.InstanceTimer)
    if not Result then
        self:Warn("Failed to scan instance timer interface")
        return ""
    end
    
    if type(Result) ~= "table" and type(Result) ~= "userdata" then
        self:Error("Invalid result type from interface scan: " .. type(Result))
        return ""
    end
    
    if #Result == 0 then
        self:Warn("No timer interface elements found")
        return ""
    end
    
    local Element = Result[1]
    if not Element or not Element.textids then
        self:Warn("Timer element or textids not found")
        return ""
    end
    
    return tostring(Element.textids)
end

-- Checks if the instance timer matches a specific time value
---@param TimeToCheck string The time string to check for
---@return boolean matches True if timer matches the specified time, false otherwise
function Slib:InstanceTimerCheck(TimeToCheck)
    -- Parameter validation
    if not self:ValidateParams({
        {TimeToCheck, "string", "TimeToCheck"}
    }) then
        return false
    end
    
    local TimerText = self:GetInstanceTimer()
    
    -- Safety checks for nil or invalid return values
    if not TimerText then
        self:Warn("GetInstanceTimer returned nil")
        return false
    end
    
    if type(TimerText) ~= "string" then
        self:Warn("GetInstanceTimer returned non-string value: " .. type(TimerText))
        return false
    end
    
    if TimerText == "" then
        return false
    end
    
    local Found = string.find(TimerText, TimeToCheck, 1, true)
    return Found ~= nil
end

-- Retrieves the kill counts for GWD1 (God Wars Dungeon 1) followers
---@return table<string, number>|nil killCounts Table containing kill counts for each faction, or nil if failed to retrieve data
function Slib:GetGWD1KillCounts()

    local FactionNames = { "Armadyl", "Bandos", "Saradomin", "Zamorak", "Zaros" }
    local Results = {}
    local SuccessCount = 0

    -- Process each faction
    for i, BaseAddress in ipairs(self.Interfaces.GWD1KillCounts) do
        local FactionName = FactionNames[i]
        
        -- Scan interface for faction data
        local Data = API.ScanForInterfaceTest2Get(false, BaseAddress)
        if not Data then
            self:Warn(string.format("[GetGWD1KillCounts] Failed to scan interface for %s", FactionName))
            Results[FactionName] = 0
            goto continue
        end
        
        if type(Data) ~= "table" and type(Data) ~= "userdata" then
            self:Error(string.format("[GetGWD1KillCounts] Invalid data type for %s: %s", FactionName, type(Data)))
            Results[FactionName] = 0
            goto continue
        end
        
        if #Data == 0 then
            self:Warn(string.format("[GetGWD1KillCounts] No interface data found for %s", FactionName))
            Results[FactionName] = 0
            goto continue
        end
        
        -- Get the first element and validate it
        local Element = Data[1]
        if not Element or not Element.memloc then
            self:Warn(string.format("[GetGWD1KillCounts] Invalid element data for %s", FactionName))
            Results[FactionName] = 0
            goto continue
        end
        
        -- Read kill count from memory
        local Amount = API.ReadCharsLimit(Element.memloc + API.I_itemids3, 255)
        if not Amount then
            self:Warn(string.format("[GetGWD1KillCounts] Failed to read kill count for %s", FactionName))
            Results[FactionName] = 0
            goto continue
        end
        
        -- Convert to number
        local KillCount = tonumber(Amount)
        if not KillCount then
            self:Warn(string.format("[GetGWD1KillCounts] Invalid kill count value for %s: %s", FactionName, tostring(Amount)))
            Results[FactionName] = 0
            goto continue
        end
        
        Results[FactionName] = KillCount
        SuccessCount = SuccessCount + 1
        self:Info(string.format("[GetGWD1KillCounts] %s kill count: %d", FactionName, KillCount))
        
        ::continue::
    end

    -- Print formatted results
    if SuccessCount > 0 then
        self:Info("=== GWD1 Kill Counts ===")
        print("+========================+")
        print("|      GWD1 KILLS        |")
        print("+========================+")
        print("|   Armadyl   : " .. string.format("%-8s", tostring(Results.Armadyl or 0)) .. " |")
        print("|   Bandos    : " .. string.format("%-8s", tostring(Results.Bandos or 0)) .. " |")
        print("|   Saradomin : " .. string.format("%-8s", tostring(Results.Saradomin or 0)) .. " |")
        print("|   Zamorak   : " .. string.format("%-8s", tostring(Results.Zamorak or 0)) .. " |")
        print("|   Zaros     : " .. string.format("%-8s", tostring(Results.Zaros or 0)) .. " |")
        print("+========================+")

        return Results
    else
        self:Error("[GetGWD1KillCounts] Failed to retrieve any kill counts")
        return nil
    end
end

-- Retrieves the kill counts for GWD2 (God Wars Dungeon 2) followers
---@return table<string, number>|nil killCounts Table containing kill counts for each faction, or nil if failed to retrieve data
function Slib:GetGWD2KillCounts()

    local FactionNames = { "Seren", "Sliske", "Zamorak", "Zaros" }
    local Results = {}
    local SuccessCount = 0

    -- Process each faction
    for i, BaseAddress in ipairs(self.Interfaces.GWD2KillCounts) do
        local FactionName = FactionNames[i]
        
        -- Scan interface for faction data
        local Data = API.ScanForInterfaceTest2Get(false, BaseAddress)
        if not Data then
            self:Warn(string.format("[GetGWD2KillCounts] Failed to scan interface for %s", FactionName))
            Results[FactionName] = 0
            goto continue
        end
        
        if type(Data) ~= "table" and type(Data) ~= "userdata" then
            self:Error(string.format("[GetGWD2KillCounts] Invalid data type for %s: %s", FactionName, type(Data)))
            Results[FactionName] = 0
            goto continue
        end
        
        if #Data == 0 then
            self:Warn(string.format("[GetGWD2KillCounts] No interface data found for %s", FactionName))
            Results[FactionName] = 0
            goto continue
        end
        
        -- Get the first element and validate it
        local Element = Data[1]
        if not Element or not Element.memloc then
            self:Warn(string.format("[GetGWD2KillCounts] Invalid element data for %s", FactionName))
            Results[FactionName] = 0
            goto continue
        end
        
        -- Read kill count from memory
        local Amount = API.ReadCharsLimit(Element.memloc + API.I_itemids3, 255)
        if not Amount then
            self:Warn(string.format("[GetGWD2KillCounts] Failed to read kill count for %s", FactionName))
            Results[FactionName] = 0
            goto continue
        end
        
        -- Convert to number
        local KillCount = tonumber(Amount)
        if not KillCount then
            self:Warn(string.format("[GetGWD2KillCounts] Invalid kill count value for %s: %s", FactionName, tostring(Amount)))
            Results[FactionName] = 0
            goto continue
        end
        
        Results[FactionName] = KillCount
        SuccessCount = SuccessCount + 1
        self:Info(string.format("[GetGWD2KillCounts] %s kill count: %d", FactionName, KillCount))
        
        ::continue::
    end

    -- Print formatted results
    if SuccessCount > 0 then
        self:Info("=== GWD2 Kill Counts ===")
        print("+========================+")
        print("|      GWD2 KILLS        |")
        print("+========================+")
        print("|   Seren    : " .. string.format("%-8s", tostring(Results.Seren or 0)) .. " |")
        print("|   Sliske   : " .. string.format("%-8s", tostring(Results.Sliske or 0)) .. " |")
        print("|   Zamorak  : " .. string.format("%-8s", tostring(Results.Zamorak or 0)) .. " |")
        print("|   Zaros    : " .. string.format("%-8s", tostring(Results.Zaros or 0)) .. " |")
        print("+========================+")

        return Results
    else
        self:Error("[GetGWD2KillCounts] Failed to retrieve any kill counts")
        return nil
    end
end

-- Checks recent chat messages for specified patterns and returns true if any are found
---@param Patterns string|table The pattern(s) to search for in chat messages
---@param DebugPrint boolean|nil Whether to print debug information (optional, default: false)
---@return boolean found True if any pattern was found in recent messages, false otherwise
function Slib:RecentMessageCheck(Patterns, DebugPrint)
    -- Parameter validation
    if not self:ValidateParams({
        {Patterns, {"string", "table_of_strings"}, "Patterns"},
        {DebugPrint, "boolean", "DebugPrint", true} -- allow_nil = true
    }) then
        return false
    end
    
    -- Convert single string to table for consistent processing
    local PatternTable = type(Patterns) == "table" and Patterns or {Patterns}
    
    -- Default debug_print to false
    DebugPrint = DebugPrint or false
    
    -- Gather recent chat messages
    self.ChatMessages = API.GatherEvents_chat_check()
    if not self.ChatMessages then
        self:Warn("Failed to gather chat self.ChatMessages")
        return false
    end
    
    if type(self.ChatMessages) ~= "table" and type(self.ChatMessages) ~= "userdata" then
        self:Error("Invalid self.ChatMessages data type: " .. type(self.ChatMessages))
        return false
    end
    
    if #self.ChatMessages == 0 then
        return false
    end
    
    -- Process each message
    for i, Message in ipairs(self.ChatMessages) do
        -- Validate message structure
        if not Message or not Message.text then
            if DebugPrint then
                self:Warn("Skipping invalid message at index " .. i)
            end
            goto continue_message
        end
        
        -- Debug print if requested
        if DebugPrint then
            print(string.format("[Chat Message] %s", Message.text))
        end
        
        -- Check message against all patterns (case insensitive)
        for _, Pattern in ipairs(PatternTable) do
            if string.find(string.lower(Message.text), string.lower(Pattern)) then
                if DebugPrint then
                    print(string.format("[RecentMessageCheck] Pattern matched: '%s'", Pattern))
                end
                return true
            end
        end
        
        ::continue_message::
    end
    
    -- No patterns matched
    return false
end

-- Waits for a specific object to appear within range
---@param ObjID number|table The object ID(s) to wait for
---@param Range number Maximum search distance in tiles
---@param ObjType number|table The object type(s) to search for
---@param TimeoutSeconds number Maximum wait time in seconds
---@return boolean found True if object was found within timeout, false otherwise
function Slib:WaitForObjectToAppear(ObjID, Range, ObjType, TimeoutSeconds)
    -- Parameter validation
    if not self:ValidateParams({
        {ObjID, {"number", "table_of_numbers"}, "ObjID"},
        {Range, "positive_number", "Range"},
        {ObjType, {"number", "table_of_numbers"}, "ObjType"},
        {TimeoutSeconds, "positive_number", "TimeoutSeconds"}
    }) then
        return false
    end
    
    -- Convert single numbers to tables for consistent processing
    local ObjIdTable = type(ObjID) == "table" and ObjID or {ObjID}
    local ObjTypeTable = type(ObjType) == "table" and ObjType or {ObjType}
    
    local StartTime = os.clock()
    local MaxTime = TimeoutSeconds
    
    -- Create descriptive strings for logging
    local ObjIdStr = type(ObjID) == "table" and table.concat(ObjIdTable, ", ") or tostring(ObjID)
    local ObjTypeStr = type(ObjType) == "table" and table.concat(ObjTypeTable, ", ") or tostring(ObjType)
    
    self:Info("Waiting for object ID(s) [" .. ObjIdStr .. "] (Type(s) [" .. ObjTypeStr .. "]) within range " .. Range .. " tiles...")
    
    while API.Read_LoopyLoop() do
        -- Check timeout
        if (os.clock() - StartTime) >= MaxTime then
            self:Warn("Timeout reached (" .. TimeoutSeconds .. "s) while waiting for object ID(s) [" .. ObjIdStr .. "]")
            return false
        end
        
        -- Search for the objects
        local Objects = API.GetAllObjArray1(ObjIdTable, Range, ObjTypeTable)
        
        if not Objects then
            self:Warn("API returned nil for object search")
            goto continue_wait
        end
        
        if type(Objects) ~= "table" and type(Objects) ~= "userdata" then
            self:Error("Invalid objects data type: " .. type(Objects))
            return false
        end
        
        if #Objects > 0 then
            -- Check each object to find exact match
            for _, Object in ipairs(Objects) do
                if not Object then
                    goto continue_object
                end
                
                local Id = Object.Id or 0
                local ObjectType = Object.Type or 0
                
                -- Check if this object matches any of our target IDs and types
                local IdMatch = false
                local TypeMatch = false
                
                for _, TargetId in ipairs(ObjIdTable) do
                    if Id == TargetId then
                        IdMatch = true
                        break
                    end
                end
                
                for _, TargetType in ipairs(ObjTypeTable) do
                    if ObjectType == TargetType then
                        TypeMatch = true
                        break
                    end
                end
                
                if IdMatch and TypeMatch then
                    local Elapsed = os.clock() - StartTime
                    self:Info("Object found! ID " .. Id .. " (Type " .. ObjectType .. ") after " .. string.format("%.1f", Elapsed) .. " seconds")
                    return true
                end
                
                ::continue_object::
            end
        end
        
        ::continue_wait::
        
        -- Short sleep to prevent excessive CPU usage
        self:Sleep(200, "ms")
    end
    
    self:Warn("Loop stopped while waiting for object ID(s) [" .. ObjIdStr .. "]")
    return false
end

-- Waits for a specific object to appear within range using GetAllObjArray2 (supports x, y, z parameters)
---@param ObjID number|table The object ID(s) to wait for
---@param Range number Maximum search distance in tiles
---@param ObjType number|table The object type(s) to search for
---@param x number The x coordinate to search from
---@param y number The y coordinate to search from
---@param z number The z coordinate to search from
---@param TimeoutSeconds number Maximum wait time in seconds
---@return boolean found True if object was found within timeout, false otherwise
function Slib:WaitForObjectToAppear2(ObjID, Range, ObjType, x, y, z, TimeoutSeconds)
    -- Parameter validation
    if not self:ValidateParams({
        {ObjID, {"number", "table_of_numbers"}, "ObjID"},
        {Range, "positive_number", "Range"},
        {ObjType, {"number", "table_of_numbers"}, "ObjType"},
        {x, "number", "x"},
        {y, "number", "y"},
        {z, "number", "z"},
        {TimeoutSeconds, "positive_number", "TimeoutSeconds"}
    }) then
        return false
    end
    
    -- Convert single numbers to tables for consistent processing
    local ObjIdTable = type(ObjID) == "table" and ObjID or {ObjID}
    local ObjTypeTable = type(ObjType) == "table" and ObjType or {ObjType}
    
    local StartTime = os.clock()
    local MaxTime = TimeoutSeconds
    
    -- Create descriptive strings for logging
    local ObjIdStr = type(ObjID) == "table" and table.concat(ObjIdTable, ", ") or tostring(ObjID)
    local ObjTypeStr = type(ObjType) == "table" and table.concat(ObjTypeTable, ", ") or tostring(ObjType)
    local TileStr = "from tile (" .. tostring(x) .. ", " .. tostring(y) .. ", " .. tostring(z) .. ")"
    
    self:Info("Waiting for object ID(s) [" .. ObjIdStr .. "] (Type(s) [" .. ObjTypeStr .. "]) within range " .. Range .. " tiles " .. TileStr .. "...")
    
    -- Construct WPOINT from x, y, z
    local Tile = WPOINT.new(x, y, z)
    
    while API.Read_LoopyLoop() do
        -- Check timeout
        if (os.clock() - StartTime) >= MaxTime then
            self:Warn("Timeout reached (" .. TimeoutSeconds .. "s) while waiting for object ID(s) [" .. ObjIdStr .. "]")
            return false
        end
        
        -- Search for the objects using GetAllObjArray2
        local Objects = API.GetAllObjArray2(ObjIdTable, Range, ObjTypeTable, Tile)
        
        if not Objects then
            self:Warn("API returned nil for object search")
            goto continue_wait
        end
        
        if type(Objects) ~= "table" and type(Objects) ~= "userdata" then
            self:Error("Invalid objects data type: " .. type(Objects))
            return false
        end
        
        if #Objects > 0 then
            -- Check each object to find exact match
            for _, Object in ipairs(Objects) do
                if not Object then
                    goto continue_object
                end
                
                local Id = Object.Id or 0
                local ObjectType = Object.Type or 0
                
                -- Check if this object matches any of our target IDs and types
                local IdMatch = false
                local TypeMatch = false
                
                for _, TargetId in ipairs(ObjIdTable) do
                    if Id == TargetId then
                        IdMatch = true
                        break
                    end
                end
                
                for _, TargetType in ipairs(ObjTypeTable) do
                    if ObjectType == TargetType then
                        TypeMatch = true
                        break
                    end
                end
                
                if IdMatch and TypeMatch then
                    local Elapsed = os.clock() - StartTime
                    self:Info("Object found! ID " .. Id .. " (Type " .. ObjectType .. ") after " .. string.format("%.1f", Elapsed) .. " seconds")
                    return true
                end
                
                ::continue_object::
            end
        end
        
        ::continue_wait::
        
        -- Short sleep to prevent excessive CPU usage
        self:Sleep(200, "ms")
    end
    
    self:Warn("Loop stopped while waiting for object ID(s) [" .. ObjIdStr .. "]")
    return false
end

-- Finds the nearest object with specified ID(s) and type(s) within range
---@param ObjId number|table The object ID(s) to search for
---@param Distance number Maximum search distance in tiles
---@param ObjType number|table The object type(s) to search for
---@return table|nil nearest_object The nearest matching object, or nil if none found
function Slib:FindObj(ObjId, Distance, ObjType)
    -- Parameter validation
    if not self:ValidateParams({
        {ObjId, {"number", "table_of_numbers"}, "ObjId"},
        {Distance, "id", "Distance"},
        {ObjType, {"number", "table_of_numbers"}, "ObjType"}
    }) then
        return nil
    end
    
    -- Convert to tables for API call
    local ObjIdTable = type(ObjId) == "table" and ObjId or {ObjId}
    local ObjTypeTable = type(ObjType) == "table" and ObjType or {ObjType}
    
    -- Search for objects
    local Objects = API.GetAllObjArray1(ObjIdTable, Distance, ObjTypeTable)
    
    if not Objects or #Objects == 0 then
        return nil
    end
    
    -- Find nearest object
    local NearestObj = nil
    local NearestDistance = math.huge
    
    for _, Obj in ipairs(Objects) do
        if Obj and Obj.Distance and Obj.Distance < NearestDistance then
            NearestObj = Obj
            NearestDistance = Obj.Distance
        end
    end
    
    return NearestObj
end

-- Finds the nearest object with specified ID(s) and type(s) within range using GetAllObjArray2 (supports x, y, z parameters)
---@param ObjId number|table The object ID(s) to search for
---@param Distance number Maximum search distance in tiles
---@param ObjType number|table The object type(s) to search for
---@param x number The x coordinate to search from
---@param y number The y coordinate to search from
---@param z number The z coordinate to search from
---@return table|nil nearest_object The nearest matching object, or nil if none found
function Slib:FindObj2(ObjId, Distance, ObjType, x, y, z)
    -- Parameter validation
    if not self:ValidateParams({
        {ObjId, {"number", "table_of_numbers"}, "ObjId"},
        {Distance, "id", "Distance"},
        {ObjType, {"number", "table_of_numbers"}, "ObjType"},
        {x, "number", "x"},
        {y, "number", "y"},
        {z, "number", "z"}
    }) then
        return nil
    end
    
    -- Convert to tables for API call
    local ObjIdTable = type(ObjId) == "table" and ObjId or {ObjId}
    local ObjTypeTable = type(ObjType) == "table" and ObjType or {ObjType}
    
    -- Construct WPOINT from x, y, z
    local Tile = WPOINT.new(x, y, z)
    
    -- Search for objects using GetAllObjArray2
    local Objects = API.GetAllObjArray2(ObjIdTable, Distance, ObjTypeTable, Tile)
    
    if not Objects or #Objects == 0 then
        return nil
    end
    
    -- Find nearest object
    local NearestObj = nil
    local NearestDistance = math.huge
    
    for _, Obj in ipairs(Objects) do
        if Obj and Obj.Distance and Obj.Distance < NearestDistance then
            NearestObj = Obj
            NearestDistance = Obj.Distance
        end
    end
    
    return NearestObj
end

-- Checks if the currency pouch contains an item with the given ID or any ID in a list
---@param Ids number|table The item ID or list of item IDs to check for
---@return boolean found True if at least one of the IDs is found in the currency pouch, false otherwise
function Slib:CurrencyPouchContains(Ids)
    -- Parameter validation
    if not self:Sanitize(Ids, {"number", "table_of_ids"}, "Ids") then
        return false
    end
    
    -- Convert to table for consistent processing
    local IdTable = type(Ids) == "table" and Ids or {Ids}
    
    -- Track which IDs have been found
    local found = {}
    for _, id in ipairs(IdTable) do
        found[id] = false
    end
    
    -- Scan all currency pouch interfaces
    for I = 1, #self.Interfaces.CurrencyPouch do
        local Interface = API.ScanForInterfaceTest2Get(true, self.Interfaces.CurrencyPouch[I])
        if Interface and (type(Interface) == "table" or type(Interface) == "userdata") then
            for _, Item in pairs(Interface) do
                if Item and Item.itemid1 and Item.itemid1 >= 0 then
                    if found[Item.itemid1] == false then
                        found[Item.itemid1] = true
                    end
                end
            end
        end
    end
    -- Check if all IDs were found
    for _, id in ipairs(IdTable) do
        if not found[id] then
            return false
        end
    end
    return true
end

-- ##################################
-- #                                #
-- #           PROCEDURES           #
-- #                                #
-- ##################################

-- Walks to specified coordinates
---@param X number The target X coordinate
---@param Y number The target Y coordinate
---@param Z number The target Z coordinate (floor/plane)
---@return boolean success True if walk was initiated or player is already at destination, false on failure
function Slib:WalkToCoordinates(X, Y, Z)
    self:Info("[WalkToCoordinates] Starting walk to coordinates (" .. X .. ", " .. Y .. ", " .. Z .. ")...")
    -- Parameter validation
    if not self:ValidateParams({
        {X, "number", "X"},
        {Y, "number", "Y"},
        {Z, "number", "Z"}
    }) then
        self:Error("[WalkToCoordinates] Parameter validation failed")
        return false
    end
    
    -- Check if already at destination
    local AtDest = self:IsPlayerAtCoords(X, Y, Z)
    if AtDest then
        self:Info("[WalkToCoordinates] Already at destination coordinates")
        return true
    end
    
    self:Info("[WalkToCoordinates] Initiating walk...")
    -- Attempt to walk
    local WalkResult = API.DoAction_Tile(WPOINT.new(X, Y, Z))
    if not WalkResult then
        self:Error("[WalkToCoordinates] Failed to initiate walk to (" .. X .. ", " .. Y .. ", " .. Z .. ")")
        return false
    end

    return true
end

-- Attempts to use Surge ability if player is facing the specified orientation
---@param Orientation number The orientation angle to check (0-360 degrees)
---@return boolean success True if surge was used successfully, false if wrong orientation or ability unavailable
function Slib:SurgeIfFacing(Orientation)
    -- Parameter validation
    if not self:ValidateParams({
        {Orientation, "number", "Orientation"}
    }) then
        return false
    end

    self:Info(string.format("[SurgeIfFacing] Checking if player is facing %d degrees...", Orientation))
    
    -- Normalize orientation values
    local PlayerFacing = math.floor(API.calculatePlayerOrientation())
    if PlayerFacing == 0 then PlayerFacing = 360 end
    if Orientation == 0 then Orientation = 360 end
    
    -- Check if player is facing the correct direction
    if Orientation ~= PlayerFacing then
        self:Info(string.format("[SurgeIfFacing] Player facing %d degrees, not matching required %d degrees", PlayerFacing, Orientation))
        return false
    end
    
    self:Info("[SurgeIfFacing] Player facing correct direction, attempting to surge...")
    return self:UseAbilityById(14233) --Surge ID
end

-- Dives to the specified coordinates using Bladed Dive or regular Dive
---@param X number The target X coordinate
---@param Y number The target Y coordinate
---@param Z number The target Z coordinate
---@return boolean success True if dive was successful, false if abilities on cooldown or dive failed
function Slib:Dive(X, Y, Z)
    -- Parameter validation
    if not self:ValidateParams({
        {X, "number", "X"},
        {Y, "number", "Y"},
        {Z, "number", "Z"}
    }) then
        return false
    end

    self:Info(string.format("[Dive] Attempting to dive to coordinates (%d, %d, %d)", X, Y, Z))
    
    -- Check Bladed Dive ability
    local BladedDive = API.GetABs_id(30331)
    if not BladedDive then
        self:Error("[Dive] Failed to get Bladed Dive ability info")
        return false
    end
    
    -- Check regular Dive ability
    local RegularDive = API.GetABs_id(23714)
    if not RegularDive then
        self:Error("[Dive] Failed to get regular Dive ability info")
        return false
    end
    
    -- Check if either ability is available
    local BladedDiveReady = BladedDive.id ~= 0 and BladedDive.enabled and BladedDive.cooldown_timer < 1
    local RegularDiveReady = RegularDive.id ~= 0 and RegularDive.enabled and RegularDive.cooldown_timer < 1
    
    if not (BladedDiveReady or RegularDiveReady) then
        self:Warn("[Dive] No dive abilities available (on cooldown or disabled)")
        return false
    end
    
    -- Create target point
    local TargetPoint = WPOINT.new(X, Y, Z)
    
    -- Try Bladed Dive first
    if BladedDiveReady then
        self:Info("[Dive] Attempting Bladed Dive...")
        if API.DoAction_BDive_Tile(TargetPoint) then
            self:Info("[Dive] Bladed Dive successful")
            return true
        end
        self:Warn("[Dive] Bladed Dive failed")
    end
    
    -- Try regular Dive as fallback
    if RegularDiveReady then
        self:Info("[Dive] Attempting regular Dive...")
        if API.DoAction_Dive_Tile(TargetPoint) then
            self:Info("[Dive] Regular Dive successful")
            return true
        end
        self:Warn("[Dive] Regular Dive failed")
    end
    
    self:Error("[Dive] All dive attempts failed")
    return false
end

-- Uses an ability by its ID
---@param AbilityId number The ID of the ability to use
---@return boolean success True if ability was used successfully, false if ability not found, on cooldown, or disabled
function Slib:UseAbilityById(AbilityId)
    -- Parameter validation
    if not self:ValidateParams({
        {AbilityId, "id", "AbilityId"}
    }) then
        return false
    end

    self:Info(string.format("[UseAbilityById] Attempting to use ability with ID: %d", AbilityId))
    
    -- Get ability information
    local Ability = API.GetABs_id(AbilityId)
    if not Ability or Ability.id == 0 then
        self:Error(string.format("[UseAbilityById] Ability with ID %d not found", AbilityId))
        return false
    end
    
    -- Check if ability is available
    if not Ability.enabled then
        self:Info(string.format("[UseAbilityById] Ability %d is currently disabled", AbilityId))
        return false
    end
    
    -- Check cooldown
    if Ability.cooldown_timer >= 1 then
        self:Info(string.format("[UseAbilityById] Ability %d is on cooldown (%.1f seconds remaining)", AbilityId, Ability.cooldown_timer))
        return false
    end
    
    -- Attempt to use the ability
    self:Info(string.format("[UseAbilityById] Using ability %d", AbilityId))
    return API.DoAction_Ability_Direct(Ability, 1, API.OFF_ACT_GeneralInterface_route)
end

-- Uses an ability by name if it exists and is enabled. ExactMatch is used to check if the ability name is exact.
---@param AbilityName string
---@param ExactMatch boolean
---@return boolean
function Slib:UseAbilityByName(AbilityName, ExactMatch)
    self:Info("[UseAbilityByName] Attempting to use ability: " .. AbilityName .. " (ExactMatch: " .. tostring(ExactMatch) .. ")")
    -- Parameter validation
    if not self:ValidateParams({
        {AbilityName, "non_empty_string", "AbilityName"},
        {ExactMatch, "boolean", "ExactMatch"}
    }) then
        self:Error("[UseAbilityByName] Parameter validation failed")
        return false
    end
    
    -- Get ability information using GetABs_name
    local Ability = API.GetABs_name(AbilityName, ExactMatch)
    if not Ability then
        self:Warn("[UseAbilityByName] Ability not found: " .. AbilityName)
        return false
    end
    
    if type(Ability) ~= "table" and type(Ability) ~= "userdata" then
        self:Error("[UseAbilityByName] Invalid ability data type: " .. type(Ability))
        return false
    end
    
    -- Check if ability is enabled
    if not Ability.enabled then
        self:Warn("[UseAbilityByName] Ability is not enabled: " .. AbilityName)
        return false
    end
    
    self:Info("[UseAbilityByName] Ability found and enabled. Attempting to use...")
    -- Attempt to use the ability
    local Result = API.DoAction_Ability(AbilityName,1,API.OFF_ACT_GeneralInterface_route,ExactMatch)
    if not Result then
        self:Error("[UseAbilityByName] Failed to use ability: " .. AbilityName)
        return false
    end
    
    self:Info("[UseAbilityByName] Ability used successfully: " .. AbilityName)
    return true
end

-- Teleports the player to Guthix Memorial using the Memory Strand currency from the currency pouch
---@return boolean success True if teleport was successful, false if Memory Strand not found or teleport failed
function Slib:MemoryStrandTeleport()
    if not self:CurrencyPouchContains(39486) then
        self:Error("[MemoryStrandTeleport] Memory Strand not found in currency pouch")
        return false
    end

    while API.Read_LoopyLoop() and not (self:IsPlayerInArea(2265, 3554, 0, 20) or self:IsPlayerInArea(2293, 3554, 0, 5)) do
        self:Info("[MemoryStrandTeleport] Attempting to use Memory Strand teleport...")
        API.DoAction_Interface(0x24,0x9A3E,1,1473,21,10,API.OFF_ACT_GeneralInterface_route) -- Memory Strand teleport
        self:SleepUntil(function()
            return self:IsPlayerInArea(2265, 3554, 0, 20) or self:IsPlayerInArea(2293, 3554, 0, 20)
        end, 6, 100)
    end
    return true
end

-- Uses incense sticks and keep them active
---@param BuffID number
---@return boolean
function Slib:CheckIncenseStick(BuffID)
    -- Parameter validation
    if not self:ValidateParams({
        {BuffID, "id", "buffID"}
    }) then
        return false
    end

    self:Info("[CheckIncenseStick] Checking incense stick buff: " .. BuffID)
    
    -- Get all active buffs
    local buffs = API.Buffbar_GetAllIDs()
    if not buffs then
        self:Error("[CheckIncenseStick] Failed to get buff information")
        return false
    end
    
    -- Check if the buff is active
    local found = false
    for _, object in ipairs(buffs) do
        if object.id == BuffID then
            found = true
            self:Info("[CheckIncenseStick] Found active incense stick buff")
            
            -- Parse buff information
            local time, level = string.match(object.text, "(%d+)%a* %((%d+)%)")
            time = tonumber(time)
            level = tonumber(level)
            
            if not time or not level then
                self:Error("[CheckIncenseStick] Failed to parse buff time or level")
                return false
            end
            
            -- Check and maintain buff level
            if level < 4 then
                self:Info("[CheckIncenseStick] Buff level low (" .. level .. "), applying overload...")
                API.DoAction_Inventory1(BuffID,0,2,API.OFF_ACT_GeneralInterface_route)
            end
            
            -- Check and extend duration if needed
            if time < 50 then
                self:Info("[CheckIncenseStick] Buff duration low (" .. time .. "m), extending...")
                for i = 1, 5 do
                    API.DoAction_Inventory1(BuffID,0,1,API.OFF_ACT_GeneralInterface_route)
                    self:RandomSleep(100, 300, "ms")
                end
            end
            break
        end
    end
    
    -- If buff not found, apply new buff
    if not found then
        self:Info("[CheckIncenseStick] Buff not active, applying new buff...")
        -- Apply overload
        API.DoAction_Inventory1(BuffID,0,2,API.OFF_ACT_GeneralInterface_route)
        self:RandomSleep(100, 300, "ms")
        
        -- Extend multiple times
        self:Info("[CheckIncenseStick] Extending new buff...")
        for i = 1, 5 do
            API.DoAction_Inventory1(BuffID,0,1,API.OFF_ACT_GeneralInterface_route)
            self:RandomSleep(100, 300, "ms")
        end
        self:Info("[CheckIncenseStick] New buff applied and extended")
        return true
    end

    return true
end

-- Recharges silverhawk boots when stored feathers are below minimum quantity
---@param MinQuantity number The minimum quantity of feathers to maintain
---@return boolean success True if boots were recharged successfully, false if no boots found or no feathers available
function Slib:RechargeSilverhawkBoots(MinQuantity)
    -- Parameter validation
    if not self:ValidateParams({
        {MinQuantity, "positive_number", "MinQuantity"}
    }) then
        return false
    end
   
    -- Check if boots are equipped
    local Boots = API.Container_Get_s(94, 30924)  -- 94 = equipment, 30924 = silverhawk boots
    if not Boots or not Boots.item_id or Boots.item_id ~= 30924 then
        self:Error("[RechargeSilverhawkBoots] Silverhawk boots not found in equipment")
        return false
    end
    
    local CurrentFeathers = Boots.Extra_ints[2]
    self:Info(string.format("[RechargeSilverhawkBoots] Current feathers: %d (Minimum: %d)", CurrentFeathers, MinQuantity))
    
    -- Check if recharge is needed
    if CurrentFeathers >= MinQuantity then
        self:Info("[RechargeSilverhawkBoots] Feather quantity sufficient")
        return false
    end
    
    -- Check for regular silverhawk feathers
    local HasFeathers = API.CheckInvStuff0(30915)
    if HasFeathers then
        self:Info("[RechargeSilverhawkBoots] Using regular silverhawk feathers")
        API.DoAction_Inventory1(30915,0,1,API.OFF_ACT_GeneralInterface_route)
        return true
    end

    -- Check for silverhawk down
    local HasDown = API.CheckInvStuff0(34823)
    if HasDown then
        self:Info("[RechargeSilverhawkBoots] Using silverhawk down")
        API.DoAction_Inventory1(34823,0,1,API.OFF_ACT_GeneralInterface_route)
        return true
    end
    
    self:Warn("[RechargeSilverhawkBoots] No feathers or down found in inventory")
    return false
end

return Slib
