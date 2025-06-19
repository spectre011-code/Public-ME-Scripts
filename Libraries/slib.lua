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

-- ##################################
-- #                                #
-- #       LOGGING FUNCTIONS        #
-- #                                #
-- ##################################

-- Logs a general message with Slib prefix
---@param Message string The message to log
---@return string logged_message The logged message
function Slib:Log(Message)
    if not self:Sanitize(Message, "string", "Message") then
        return ""
    end
    API.printlua("[Slib][LOG] " .. tostring(Message), 0, false)
    return Message
end

-- Logs an informational message with INFO level
---@param Message string The informational message to log
---@return string logged_message The logged message
function Slib:Info(Message)
    if not self:Sanitize(Message, "string", "Message") then
        return ""
    end
    API.printlua("[Slib][INFO] " .. tostring(Message), 7, false)
    return Message
end

-- Logs a warning message with WARN level
---@param Message string The warning message to log
---@return string logged_message The logged message
function Slib:Warn(Message)
    if not self:Sanitize(Message, "string", "Message") then
        return ""
    end
    API.printlua("[Slib][WARN] " .. tostring(Message), 2, false)
    return Message
end

-- Logs an error message with ERROR level
---@param Message string The error message to log
---@return string logged_message The logged message
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
---   - "any" - accepts any non-nil value (unless allow_nil is true)
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
---@param value any The value to validate
---@param expected_type string|table The expected type(s) - can be single type or array of types
---@param param_name string|nil Optional parameter name for error messages (default: "parameter")
---@param allow_nil boolean|nil Whether nil values should be considered valid (optional, default: false)
---@param calling_function string|nil Optional calling function name for error messages
---@return boolean is_valid True if validation passes, false otherwise (errors logged via self:Error)
function Slib:Sanitize(Value, ExpectedType, ParamName, AllowNil, CallingFunction)
    -- Set defaults
    ParamName = ParamName or "parameter"
    if AllowNil == nil then
        AllowNil = false
    end
    
    -- Get calling function name for better error messages
    if not CallingFunction then
        CallingFunction = "unknown"
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
                for i, Item in ipairs(Value) do
                    if type(Item) ~= "string" then
                        self:Error("[" .. CallingFunction .. "] " .. ParamName .. " must be a table of strings (item " .. i .. " is " .. type(Item) .. ")")
                        return false
                    end
                end
                return true
            end
            
            -- Check for 'table_of_numbers'
            if ExpectedPattern == "table_of_numbers" then
                for i, Item in ipairs(Value) do
                    if type(Item) ~= "number" then
                        self:Error("[" .. CallingFunction .. "] " .. ParamName .. " must be a table of numbers (item " .. i .. " is " .. type(Item) .. ")")
                        return false
                    end
                end
                return true
            end
            
            -- Check for 'table_of_ids'
            if ExpectedPattern == "table_of_ids" then
                for i, Item in ipairs(Value) do
                    if type(Item) ~= "number" or Item < 0 or math.floor(Item) ~= Item then
                        self:Error("[" .. CallingFunction .. "] " .. ParamName .. " must be a table of IDs (non-negative integers) (item " .. i .. " is invalid)")
                        return false
                    end
                end
                return true
            end
            
            -- Check for 'table_of_positive_numbers'
            if ExpectedPattern == "table_of_positive_numbers" then
                for i, Item in ipairs(Value) do
                    if type(Item) ~= "number" or Item <= 0 then
                        self:Error("[" .. CallingFunction .. "] " .. ParamName .. " must be a table of positive numbers (item " .. i .. " is invalid)")
                        return false
                    end
                end
                return true
            end
            
            -- Check for 'table_of_integers'
            if ExpectedPattern == "table_of_integers" then
                for i, Item in ipairs(Value) do
                    if type(Item) ~= "number" or math.floor(Item) ~= Item then
                        self:Error("[" .. CallingFunction .. "] " .. ParamName .. " must be a table of integers (item " .. i .. " is invalid)")
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
---     {playerName, "non_empty_string", "player_name"},
---     {npcIds, "table_of_ids", "npc_ids"},
---     {range, "positive_number", "range"}
--- }) then
---     return false
--- end
---
--- -- With optional parameters
--- if not self:ValidateParams({
---     {itemId, "id", "item_id"},
---     {timeout, "positive_number", "timeout", true}, -- allow_nil = true
---     {options, "table", "options", true}
--- }) then
---     return false
--- end
---
--- -- Multiple allowed types
--- if not self:ValidateParams({
---     {searchCriteria, {"string", "table_of_strings"}, "search_criteria"},
---     {coords, {"number", "table_of_numbers"}, "coordinates"}
--- }) then
---     return false
--- end
--- ```
---
---@param params table Array of parameter specs: {value, expected_type, param_name, allow_nil}
---   - **value**: The parameter value to validate
---   - **expected_type**: Type(s) to validate against (see Sanitize documentation for all types)
---   - **param_name**: Name for error messages (optional, defaults to "parameter N")
---   - **allow_nil**: Whether nil is acceptable (optional, defaults to false)
---@return boolean all_valid True if all parameters are valid, false otherwise (errors logged via self:Error)
function Slib:ValidateParams(Params)
    -- Get calling function name for better error messages
    local CallingFunction = "unknown"
    local Info = debug.getinfo(2, "n")
    if Info and Info.name then
        CallingFunction = Info.name
    end
    
    if not Params or type(Params) ~= "table" then
        self:Error("[" .. CallingFunction .. "] ValidateParams requires a table of parameter specifications")
        return false
    end
    
    for i, ParamSpec in ipairs(Params) do
        if type(ParamSpec) ~= "table" then
            self:Error("[" .. CallingFunction .. "] Parameter specification " .. i .. " must be a table")
            return false
        end
        
        -- Extract parameters with explicit nil checking to handle false values
        local Value
        if ParamSpec[1] ~= nil then
            Value = ParamSpec[1]
        else
            Value = ParamSpec.value
        end
        
        local ExpectedType = ParamSpec[2] or ParamSpec.expected_type
        local ParamName = ParamSpec[3] or ParamSpec.param_name or ("parameter " .. i)
        
        local AllowNil
        if ParamSpec[4] ~= nil then
            AllowNil = ParamSpec[4]
        else
            AllowNil = ParamSpec.allow_nil or false
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
---@return boolean success True if buffs were found and printed, false if no buffs or error occurred
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
    for i = 1, #Buffs do
        local Buff = Buffs[i]
        
        -- Check if buff exists and is valid
        if not Buff then
            self:Warn("Skipping nil buff at index " .. i)
            goto continue
        end
        
        if type(Buff) ~= "table" and type(Buff) ~= "userdata" then
            self:Warn("Skipping invalid buff at index " .. i .. " (type: " .. type(Buff) .. ")")
            goto continue
        end
        
        -- Format buff information with nice borders
        print("+=========================+")
        print("|         BUFF #" .. i .. "         |")
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
---@return boolean success True if debuffs were found and printed, false if no debuffs or error occurred
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
    for i = 1, #Debuffs do
        local Debuff = Debuffs[i]
        
        -- Check if debuff exists and is valid
        if not Debuff then
            self:Warn("Skipping nil debuff at index " .. i)
            goto continue
        end
        
        if type(Debuff) ~= "table" and type(Debuff) ~= "userdata" then
            self:Warn("Skipping invalid debuff at index " .. i .. " (type: " .. type(Debuff) .. ")")
            goto continue
        end
        
        -- Format debuff information with nice borders
        print("+=========================+")
        print("|        DEBUFF #" .. i .. "        |")
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
---@param containerId number
---@return boolean
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
    for i = 1, #Items do
        local Item = Items[i]
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
    for i = 1, #Items do
        local Item = Items[i]
        
        -- Check if item exists and is valid
        if not Item then
            self:Warn("Skipping nil item at slot " .. i)
            goto continue
        end
        
        if type(Item) ~= "table" and type(Item) ~= "userdata" then
            self:Warn("Skipping invalid item at slot " .. i .. " (type: " .. type(Item) .. ")")
            goto continue
        end
        
        -- Only print items that have a valid item_id (>= 0)
        if not Item.item_id or Item.item_id < 0 then
            goto continue
        end
        
        -- Format item information with nice borders
        print("+========================+")
        print("|      ITEM SLOT #" .. i .. "      |")
        print("+========================+")
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
---@param BarID number|table
---@return boolean
function Slib:PrintAbilityBar(BarID)
    -- Parameter validation
    if not self:Sanitize(BarID, {"number", "table_of_numbers"}, "BarID") then
        return false
    end
    
    -- Ensure BarID is a table for consistent processing
    local barTable = type(BarID) == "table" and BarID or {BarID}
    
    -- Validate range (0-4) for each bar ID
    for i, barId in ipairs(barTable) do
        if barId < 0 or barId > 4 then
            self:Error("BarID must be between 0-4, got: " .. barId .. " at index " .. i)
            return false
        end
    end
    
    local totalAbilities = 0
    local processedBars = 0
    
    -- Process each ability bar
    for _, barId in ipairs(barTable) do
        local bar = API.GetABarInfo(barId)
        
        if not bar then
            self:Warn("Unable to get ability bar " .. barId)
            goto continue
        end
        
        if type(bar) ~= "table" and type(bar) ~= "userdata" then
            self:Warn("Invalid data type for bar " .. barId .. ": " .. type(bar))
            goto continue
        end
        
        if #bar == 0 then
            self:Info("Ability bar " .. barId .. " is empty")
            goto continue
        end
        
        -- Count valid abilities in this bar
        local validAbilities = 0
        for i = 1, #bar do
            local ability = bar[i]
            if ability and ability.id and ability.id ~= 65535 then
                validAbilities = validAbilities + 1
            end
        end
        
        if validAbilities == 0 then
            self:Info("No valid abilities found in bar " .. barId)
            goto continue
        end
        
        self:Info("=== Ability Bar " .. barId .. " ===")
        self:Info("Found " .. validAbilities .. " abilities:")
        print("")
        
        -- Safe iteration through abilities
        for i = 1, #bar do
            local ability = bar[i]
            
            -- Check if ability exists and is valid
            if not ability then
                self:Warn("Skipping nil ability at slot " .. i .. " in bar " .. barId)
                goto continue_ability
            end
            
            if type(ability) ~= "table" and type(ability) ~= "userdata" then
                self:Warn("Skipping invalid ability at slot " .. i .. " in bar " .. barId .. " (type: " .. type(ability) .. ")")
                goto continue_ability
            end
            
            -- Skip empty/invalid abilities (ID 65535 is empty slot)
            if not ability.id or ability.id == 65535 then
                goto continue_ability
            end
            
            -- Format ability information with nice borders
            print("+========================+")
            print("|     ABILITY SLOT #" .. string.format("%-2s", i) .. "   |")
            print("|        (Bar " .. barId .. ")         |")
            print("+========================+")
            print("|   slot           : " .. tostring(ability.slot or "N/A"))
            print("|   id             : " .. tostring(ability.id or "N/A"))
            print("|   name           : " .. tostring(ability.name or "N/A"))
            print("|   hotkey         : " .. tostring(ability.hotkey or "N/A"))
            print("|   cooldown_timer : " .. tostring(ability.cooldown_timer or "N/A"))
            print("|   action         : " .. tostring(ability.action or "N/A"))
            print("|   enabled        : " .. tostring(ability.enabled or "N/A"))

            -- Print ability info if it exists
            if ability.info then
                local info = ability.info
                print("|                        ")
                print("|     --- info ---       ")
                print("|   x              : " .. tostring(info.x or "N/A"))
                print("|   xs             : " .. tostring(info.xs or "N/A"))
                print("|   y              : " .. tostring(info.y or "N/A"))
                print("|   ys             : " .. tostring(info.ys or "N/A"))
                print("|   box_x          : " .. tostring(info.box_x or "N/A"))
                print("|   box_y          : " .. tostring(info.box_y or "N/A"))
                print("|   scroll_y       : " .. tostring(info.scroll_y or "N/A"))
                print("|   id1            : " .. tostring(info.id1 or "N/A"))
                print("|   id2            : " .. tostring(info.id2 or "N/A"))
                print("|   id3            : " .. tostring(info.id3 or "N/A"))
                print("|   itemid1        : " .. tostring(info.itemid1 or "N/A"))
                print("|   itemid1_size   : " .. tostring(info.itemid1_size or "N/A"))
                print("|   itemid2        : " .. tostring(info.itemid2 or "N/A"))
                print("|   hov            : " .. tostring(info.hov or "N/A"))
                print("|   textids        : " .. tostring(info.textids or "N/A"))
                print("|   textitem       : " .. tostring(info.textitem or "N/A"))
                print("|   memloc         : " .. tostring(info.memloc or "N/A"))
                print("|   memloctop      : " .. tostring(info.memloctop or "N/A"))
                print("|   index          : " .. tostring(info.index or "N/A"))
                print("|   fullpath       : " .. tostring(info.fullpath or "N/A"))
                print("|   fullIDpath     : " .. tostring(info.fullIDpath or "N/A"))
                print("|   notvisible     : " .. tostring(info.notvisible or "N/A"))
                print("|   OP             : " .. tostring(info.OP or "N/A"))
                print("|   xy             : " .. tostring(info.xy or "N/A"))
                print("|   xy.x           : " .. tostring(info.xy.x or "N/A"))
                print("|   xy.y           : " .. tostring(info.xy.y or "N/A"))
            else
                print("|   info           : N/A")
            end
            
            print("+========================+")
            print("")
            
            totalAbilities = totalAbilities + 1
            
            ::continue_ability::
        end
        
        processedBars = processedBars + 1
        
        ::continue::
    end
    
    if processedBars == 0 then
        self:Error("No ability bars could be processed")
        return false
    end
    
    self:Info("Ability scan completed - processed " .. processedBars .. " bar(s) with " .. totalAbilities .. " total abilities")
    return true
end

-- Prints all objects with specified parameters
---@param Id number|table
---@param Range number
---@param Type number|table
---@return boolean
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
    local idTable = type(Id) == "table" and Id or {Id}
    local typeTable = type(Type) == "table" and Type or {Type}
    
    -- Direct API call
    local objects = API.GetAllObjArray1(idTable, Range, typeTable)
    
    -- Check if API returned valid data
    if not objects then
        self:Error("API returned nil")
        return false
    end
    
    if type(objects) ~= "table" and type(objects) ~= "userdata" then
        self:Error("API returned invalid data type: " .. type(objects))
        return false
    end
    
    if #objects == 0 then
        self:Info("No objects found matching criteria")
        return false
    end
    
    self:Info("Found " .. #objects .. " objects:")
    
    -- Safe iteration with bounds checking
    for i = 1, #objects do
        local object = objects[i]
        
        -- Check if object exists and is valid
        if not object then
            self:Warn("Skipping nil object at index " .. i)
            goto continue
        end
        
        if type(object) ~= "table" and type(object) ~= "userdata" then
            self:Warn("Skipping invalid object at index " .. i .. " (type: " .. type(object) .. ")")
            goto continue
        end
        
        -- Direct object printing
        print("+==============================+")
        print("|          OBJECT #" .. i .. "           |")
        print("+==============================+")
        print("|    Name           : " .. tostring(object.Name or "N/A"))
        print("|    Id             : " .. tostring(object.Id or "N/A"))
        print("|    Type           : " .. tostring(object.Type or "N/A"))
        print("|    Life           : " .. tostring(object.Life or "N/A"))
        print("|    Action         : " .. tostring(object.Action or "N/A"))
        print("|    Anim           : " .. tostring(object.Anim or "N/A"))
        print("|    Amount         : " .. tostring(object.Amount or "N/A"))
        print("|    Distance       : " .. tostring(object.Distance or "N/A"))
        print("|    Floor          : " .. tostring(object.Floor or "N/A"))
        print("|    CalcX          : " .. tostring(object.CalcX or "N/A"))
        print("|    CalcY          : " .. tostring(object.CalcY or "N/A"))
        print("|    TileX          : " .. tostring(object.TileX or "N/A") .. " (÷512: " .. tostring(object.TileX and (object.TileX/512) or "N/A") .. ")")
        print("|    TileY          : " .. tostring(object.TileY or "N/A") .. " (÷512: " .. tostring(object.TileY and (object.TileY/512) or "N/A") .. ")")
        print("|    TileZ          : " .. tostring(object.TileZ or "N/A") .. " (÷512: " .. tostring(object.TileZ and (object.TileZ/512) or "N/A") .. ")")
        print("|    Tile_XYZ.x     : " .. tostring(object.Tile_XYZ and object.Tile_XYZ.x or "N/A"))
        print("|    Tile_XYZ.y     : " .. tostring(object.Tile_XYZ and object.Tile_XYZ.y or "N/A"))
        print("|    Tile_XYZ.z     : " .. tostring(object.Tile_XYZ and object.Tile_XYZ.z or "N/A"))
        print("|    Pixel_XYZ.x    : " .. tostring(object.Pixel_XYZ and object.Pixel_XYZ.x or "N/A"))
        print("|    Pixel_XYZ.y    : " .. tostring(object.Pixel_XYZ and object.Pixel_XYZ.y or "N/A"))
        print("|    Pixel_XYZ.z    : " .. tostring(object.Pixel_XYZ and object.Pixel_XYZ.z or "N/A"))
        print("|    Mem            : " .. tostring(object.Mem or "N/A"))
        print("|    MemE           : " .. tostring(object.MemE or "N/A"))
        print("|    Unique_Id      : " .. tostring(object.Unique_Id or "N/A"))
        print("|    Cmb_lv         : " .. tostring(object.Cmb_lv or "N/A"))
        print("|    ItemIndex      : " .. tostring(object.ItemIndex or "N/A"))
        print("|    Bool1          : " .. tostring(object.Bool1 or "N/A"))
        print("|    ViewP          : " .. tostring(object.ViewP or "N/A"))
        print("|    ViewF          : " .. tostring(object.ViewF or "N/A"))
        print("+==============================+")
        print("")
        
        ::continue::
    end
    
    return true
end

-- Prints info about specified VarBit(s)
---@param VB number|table
---@return boolean
function Slib:PrintVB(VB)
    -- Parameter validation
    if not self:Sanitize(VB, {"number", "table_of_numbers"}, "VB") then
        return false
    end
    
    -- Ensure VB is a table for consistent processing
    local vbTable = type(VB) == "table" and VB or {VB}
    
    local totalFound = 0
    local processedVBs = 0
    
    -- Process each VarBit
    for _, vbId in ipairs(vbTable) do
        local var = API.VB_FindPSettinOrder(vbId)
        
        if not var then
            self:Warn("VarBit " .. vbId .. " not found")
            goto continue
        end
        
        if type(var) ~= "table" and type(var) ~= "userdata" then
            self:Warn("Invalid data type for VarBit " .. vbId .. ": " .. type(var))
            goto continue
        end
        
        -- Format VarBit information with nice borders
        print("+========================+")
        print("|      VARBIT #" .. string.format("%-2s", vbId) .. "      |")
        print("+========================+")
        print("|   id             : " .. tostring(var.id or "N/A"))
        print("|   state          : " .. tostring(var.state or "N/A"))
        print("|   addr           : " .. tostring(var.addr or "N/A"))
        print("|   indexaddr_orig : " .. tostring(var.indexaddr_orig or "N/A"))
        print("+========================+")
        print("")
        
        totalFound = totalFound + 1
        processedVBs = processedVBs + 1
        
        ::continue::
    end
    
    if processedVBs == 0 then
        self:Error("No VarBits could be processed")
        return false
    end
    
    self:Info("VarBit scan completed - processed " .. processedVBs .. " VarBit(s), found " .. totalFound .. " valid")
    return true
end

-- Prints detailed information about interface elements
---@param target_under boolean
---@param interfaceToScan table
---@return boolean
function Slib:PrintInterfaceInfo(target_under, interfaceToScan)
    -- Parameter validation
    if not self:ValidateParams({
        {target_under, "boolean", "target_under"},
        {interfaceToScan, "table", "interfaceToScan"}
    }) then
        return false
    end
    
    -- API call to get interface elements
    local interface = API.ScanForInterfaceTest2Get(target_under, interfaceToScan)
    
    if not interface then
        self:Error("Failed to scan interface")
        return false
    end
    
    if type(interface) ~= "table" and type(interface) ~= "userdata" then
        self:Error("Invalid data type returned from API: " .. type(interface))
        return false
    end
    
    if #interface == 0 then
        self:Info("No interface elements found")
        return false
    end
    
    self:Info("Found " .. #interface .. " interface elements:")
    print("")
    
    -- Safe iteration through interface elements
    for i = 1, #interface do
        local element = interface[i]
        
        -- Check if element exists and is valid
        if not element then
            self:Warn("Skipping nil element at index " .. i)
            goto continue_element
        end
        
        if type(element) ~= "table" and type(element) ~= "userdata" then
            self:Warn("Skipping invalid element at index " .. i .. " (type: " .. type(element) .. ")")
            goto continue_element
        end
        
        -- Format interface element information with nice borders
        print("+============================+")
        print("|       ELEMENT #" .. string.format("%-2s", i) .. "          |")
        print("+============================+")
        print("|   x              : " .. tostring(element.x or "N/A"))
        print("|   xs             : " .. tostring(element.xs or "N/A"))
        print("|   y              : " .. tostring(element.y or "N/A"))
        print("|   ys             : " .. tostring(element.ys or "N/A"))
        print("|   box_x          : " .. tostring(element.box_x or "N/A"))
        print("|   box_y          : " .. tostring(element.box_y or "N/A"))
        print("|   scroll_y       : " .. tostring(element.scroll_y or "N/A"))
        print("|   id1            : " .. tostring(element.id1 or "N/A"))
        print("|   id2            : " .. tostring(element.id2 or "N/A"))
        print("|   id3            : " .. tostring(element.id3 or "N/A"))
        print("|   itemid1        : " .. tostring(element.itemid1 or "N/A"))
        print("|   itemid1_size   : " .. tostring(element.itemid1_size or "N/A"))
        print("|   itemid2        : " .. tostring(element.itemid2 or "N/A"))
        print("|   hov            : " .. tostring(element.hov or "N/A"))
        print("|   textids        : " .. tostring(element.textids or "N/A"))
        print("|   textitem       : " .. tostring(element.textitem or "N/A"))
        print("|   memloc         : " .. tostring(element.memloc or "N/A"))
        print("|   memloctop      : " .. tostring(element.memloctop or "N/A"))
        print("|   index          : " .. tostring(element.index or "N/A"))
        print("|   fullpath       : " .. tostring(element.fullpath or "N/A"))
        print("|   fullIDpath     : " .. tostring(element.fullIDpath or "N/A"))
        print("|   notvisible     : " .. tostring(element.notvisible or "N/A"))
        print("|   OP             : " .. tostring(element.OP or "N/A"))
        print("|   xy             : " .. tostring(element.xy or "N/A"))
        print("|   xy.x           : " .. tostring(element.xy.x or "N/A"))
        print("|   xy.y           : " .. tostring(element.xy.y or "N/A"))
        print("+============================+")
        print("")
        
        ::continue_element::
    end
    
    self:Info("Interface scan completed successfully")
    return true
end

-- Prints all fields of a QuestData object
---@param quest_ids_or_names number|string|table
---@return boolean
function Slib:PrintQuestData(quest_ids_or_names)
    -- Parameter validation
    if not self:Sanitize(quest_ids_or_names, {"number", "string", "table_of_strings", "table_of_numbers"}, "quest_ids_or_names") then
        return false
    end
    
    -- Ensure quest_ids_or_names is a table for consistent processing
    local questTable = type(quest_ids_or_names) == "table" and quest_ids_or_names or {quest_ids_or_names}
    
    local totalFound = 0
    local processedQuests = 0
    
    -- Process each quest
    for _, questId in ipairs(questTable) do
        -- API call to get quest data
        local questData = Quest:Get(questId)
        
        if not questData then
            self:Warn("Quest not found: " .. tostring(questId))
            goto continue
        end
        
        if type(questData) ~= "table" and type(questData) ~= "userdata" then
            self:Warn("Invalid quest data type for " .. tostring(questId) .. ": " .. type(questData))
            goto continue
        end

        self:Info("=== Quest: " .. tostring(questId) .. " ===")
        print("")
    
    -- Format quest information with nice borders
    print("+================================+")
    print("|           QUEST DATA           |")
    print("+================================+")
    print("|   id                 : " .. tostring(questData.id or "N/A"))
    print("|   name               : " .. tostring(questData.name or "N/A"))
    print("|   list_name          : " .. tostring(questData.list_name or "N/A"))
    print("|   members            : " .. tostring(questData.members or "N/A"))
    print("|   category           : " .. tostring(questData.category or "N/A"))
    print("|   difficulty         : " .. tostring(questData.difficulty or "N/A"))
    print("|   points_reward      : " .. tostring(questData.points_reward or "N/A"))
    print("|   points_required    : " .. tostring(questData.points_required or "N/A"))
    print("|   progress_start_bit : " .. tostring(questData.progress_start_bit or "N/A"))
    print("|   progress_end_bit   : " .. tostring(questData.progress_end_bit or "N/A"))
    print("|   progress_varbit    : " .. tostring(questData.progress_varbit or "N/A"))
    print("|                                ")
    print("|     --- Methods ---            ")
    
    -- Call methods safely
    if questData.getProgress then
        local success, progress = pcall(questData.getProgress, questData)
        print("|   getProgress()      : " .. tostring(success and progress or "Error"))
    else
        print("|   getProgress()      : N/A")
    end
    
    if questData.isStarted then
        local success, started = pcall(questData.isStarted, questData)
        print("|   isStarted()        : " .. tostring(success and started or "Error"))
    else
        print("|   isStarted()        : N/A")
    end
    
    if questData.isComplete then
        local success, complete = pcall(questData.isComplete, questData)
        print("|   isComplete()       : " .. tostring(success and complete or "Error"))
    else
        print("|   isComplete()       : N/A")
    end
    
    print("|                                ")
    print("|   --- Required Quests ---      ")
    
    -- Print required quests with debugging
    if questData.required_quests then
        if (type(questData.required_quests) == "table" or type(questData.required_quests) == "userdata") and #questData.required_quests > 0 then
            for i, reqQuest in ipairs(questData.required_quests) do
                if reqQuest and (type(reqQuest) == "table" or type(reqQuest) == "userdata") then
                    local questId = tostring(reqQuest.id or "N/A")
                    local questName = tostring(reqQuest.name or "N/A")
                    -- Split long lines to fit within border
                    print("|   [" .. i .. "] ID: " .. questId)
                    if string.len(questName) > 25 then
                        print("|       Name: " .. string.sub(questName, 1, 22) .. "...")
                    else
                        print("|       Name: " .. questName)
                    end
                else
                    print("|   [" .. i .. "] Invalid quest data     ")
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
        if questData.required_skills then
            if (type(questData.required_skills) == "table" or type(questData.required_skills) == "userdata") and #questData.required_skills > 0 then
                for i, skill in ipairs(questData.required_skills) do
                    if skill and (type(skill) == "table" or type(skill) == "userdata") then
                        local skillId = skill.id or "N/A"
                        local skillLevel = tostring(skill.level or "N/A")
                        
                        -- Get skill name from API
                        local skillName = "Unknown"
                        if skillId ~= "N/A" then
                            local skillData = API.GetSkillById(skillId)
                            if skillData and skillData.name then
                                skillName = skillData.name
                            else
                                skillName = "ID:" .. tostring(skillId)
                            end
                        end
                        
                        print("|   [" .. i .. "] " .. skillName .. " Level: " .. skillLevel)
                    else
                        print("|   [" .. i .. "] Invalid skill data    ")
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
        
        totalFound = totalFound + 1
        processedQuests = processedQuests + 1
        
        ::continue::
    end
    
    if processedQuests == 0 then
        self:Error("No quests could be processed")
        return false
    end
    
    self:Info("Quest data scan completed - processed " .. processedQuests .. " quest(s), found " .. totalFound .. " valid")
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

-- Walks to specified coordinates
---@param X number The target X coordinate
---@param Y number The target Y coordinate
---@param Z number The target Z coordinate (floor/plane)
---@return boolean success True if walk was initiated or player is already at destination, false on failure
function Slib:WalkToCoordinates(X, Y, Z)
    -- Parameter validation
    if not self:ValidateParams({
        {X, "number", "X"},
        {Y, "number", "Y"},
        {Z, "number", "Z"}
    }) then
        return false
    end
    
    -- Check if already at destination
    local AtDest = self:IsPlayerAtCoords(X, Y, Z)
    if AtDest then
        return true
    end
    
    -- Attempt to walk
    local WalkResult = API.DoAction_Tile(WPOINT.new(X, Y, Z))
    if not WalkResult then
        self:Error("Failed to initiate walk to (" .. X .. ", " .. Y .. ", " .. Z .. ")")
        return false
    end
    
    return true
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

-- Uses an ability by name if it exists and is enabled. ExactMatch is used to check if the ability name is exact.
---@param AbilityName string
---@param ExactMatch boolean
---@return boolean
function Slib:UseAbilityByName(AbilityName, ExactMatch)
    -- Parameter validation
    if not self:ValidateParams({
        {AbilityName, "non_empty_string", "AbilityName"},
        {ExactMatch, "boolean", "ExactMatch"}
    }) then
        return false
    end
    
    -- Get ability information using GetABs_name
    local Ability = API.GetABs_name(AbilityName, ExactMatch)
    if not Ability then
        self:Warn("Ability not found: " .. AbilityName)
        return false
    end
    
    if type(Ability) ~= "table" and type(Ability) ~= "userdata" then
        self:Error("Invalid ability data type: " .. type(Ability))
        return false
    end
    
    -- Check if ability is enabled
    if not Ability.enabled then
        self:Warn("Ability is not enabled: " .. AbilityName)
        return false
    end
    
    -- Attempt to use the ability
    local Result = API.DoAction_Ability(AbilityName,1,API.OFF_ACT_GeneralInterface_route,ExactMatch)
    if not Result then
        self:Error("Failed to use ability: " .. AbilityName)
        return false
    end
    
    return true
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

-- Waits for a specific object to appear within range using GetAllObjArray2 (supports tile parameter)
---@param ObjID number|table The object ID(s) to wait for
---@param Range number Maximum search distance in tiles
---@param ObjType number|table The object type(s) to search for
---@param Tile WPOINT The tile position to search from (WPOINT)
---@param TimeoutSeconds number Maximum wait time in seconds
---@return boolean found True if object was found within timeout, false otherwise
function Slib:WaitForObjectToAppear2(ObjID, Range, ObjType, Tile, TimeoutSeconds)
    -- Parameter validation
    if not self:ValidateParams({
        {ObjID, {"number", "table_of_numbers"}, "ObjID"},
        {Range, "positive_number", "Range"},
        {ObjType, {"number", "table_of_numbers"}, "ObjType"},
        {Tile, {"table", "userdata"}, "Tile"},
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
    local TileStr = "from tile (" .. tostring(Tile.x) .. ", " .. tostring(Tile.y) .. ")"
    
    self:Info("Waiting for object ID(s) [" .. ObjIdStr .. "] (Type(s) [" .. ObjTypeStr .. "]) within range " .. Range .. " tiles " .. TileStr .. "...")
    
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

-- Finds the nearest object with specified ID(s) and type(s) within range using GetAllObjArray2 (supports tile parameter)
---@param ObjId number|table The object ID(s) to search for
---@param Distance number Maximum search distance in tiles
---@param ObjType number|table The object type(s) to search for
---@param Tile WPOINT The tile position to search from (WPOINT)
---@return table|nil nearest_object The nearest matching object, or nil if none found
function Slib:FindObj2(ObjId, Distance, ObjType, Tile)
    -- Parameter validation
    if not self:ValidateParams({
        {ObjId, {"number", "table_of_numbers"}, "ObjId"},
        {Distance, "id", "Distance"},
        {ObjType, {"number", "table_of_numbers"}, "ObjType"},
        {Tile, {"table", "userdata"}, "Tile"}
    }) then
        return nil
    end
    
    -- Convert to tables for API call
    local ObjIdTable = type(ObjId) == "table" and ObjId or {ObjId}
    local ObjTypeTable = type(ObjType) == "table" and ObjType or {ObjType}
    
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


return Slib
