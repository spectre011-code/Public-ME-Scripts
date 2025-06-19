local ScriptName = "Interface Exporter"
local Author = "Spectre011"
local ScriptVersion = "1.0.0"
local ReleaseDate = "15-06-2025"
local DiscordHandle = "not_spectre011"


--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                          INTERFACE EXPORTER SCRIPT                           ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Description: Recursively scans game interfaces and exports data to CSV      ║
║  Usage:       Configure parameters in the Config table below and execute     ║
║  Output:      CSV file with detailed interface information                   ║
║                                                                              ║
║  Credits:     Based on the excellent work of Ernie                           ║
║               GitHub: https://github.com/Ernestohh/                          ║
╚══════════════════════════════════════════════════════════════════════════════╝
]]

--[[
Changelog:
v1.0.0 - 15-06-2025
    - Initial release.
]]

local API = require("api")

-- Configuration
local Config = {
    StartingInterface = { {1473,0,-1,0}, {1473,7,-1,0}, {1473,10,-1,0}, {1473,10,5120,0} },
    OutputDirectory = os.getenv("USERPROFILE") .. "\\MemoryError\\Lua_Scripts\\exports\\interfaces\\",
    OutputFileName = "interfaces_export.csv"
}

-- Opens the specified directory in Windows Explorer
local function openDirectory(path)
    -- Remove trailing backslash if present
    path = path:gsub("\\+$", "")
    -- Use os.execute to open the directory
    os.execute('explorer "' .. path .. '"')
end

-- Creates directory if it doesn't exist and tests write access
local function ensureDirectoryExists(dirPath)
    local success = os.execute('mkdir "' .. dirPath .. '" 2>nul')
    
    -- Test directory access by creating a temporary file
    local testFile = io.open(dirPath .. "test_write.tmp", "w")
    if testFile then
        testFile:close()
        os.remove(dirPath .. "test_write.tmp")
        return true
    else
        print("[" .. ScriptName .. "] Error: Could not access directory: " .. dirPath)
        return false
    end
end

-- Ensure output directory exists, fallback to current directory
if not ensureDirectoryExists(Config.OutputDirectory) then
    print("[" .. ScriptName .. "] Fallback: Using Documents folder instead.")
    Config.OutputDirectory = ".\\"
end

-- Generates a unique filename by appending a counter if file already exists
local function getUniqueFilename(baseFilename)
    local fullPath = Config.OutputDirectory .. baseFilename
    
    -- Check if base filename is available
    local file = io.open(fullPath, "r")
    if not file then
        return fullPath
    end
    file:close()
    
    -- Split filename into name and extension
    local name, ext = baseFilename:match("^(.+)%.([^%.]+)$")
    if not name then
        name = baseFilename
        ext = ""
    end
    
    -- Find next available numbered filename
    local counter = 1
    local newFilename
    repeat
        if ext and ext ~= "" then
            newFilename = Config.OutputDirectory .. name .. "_" .. counter .. "." .. ext
        else
            newFilename = Config.OutputDirectory .. name .. "_" .. counter
        end
        
        local testFile = io.open(newFilename, "r")
        if testFile then
            testFile:close()
            counter = counter + 1
        else
            break
        end
    until false
    
    print("[" .. ScriptName .. "] File exists, using: " .. newFilename)
    return newFilename
end

-- Escapes special characters for CSV format
local function escapeCSV(value)
    if not value then
        return ""
    end
    
    local str = tostring(value)
    -- Wrap in quotes and escape internal quotes if contains special chars
    if string.find(str, '[,"\n\r]') then
        str = string.gsub(str, '"', '""') -- Double quotes to escape them
        str = '"' .. str .. '"'
    end
    return str
end

-- Converts boolean values to string representation
local function boolToString(value)
    if type(value) == "boolean" then
        return value and "true" or "false"
    end
    return tostring(value or "")
end

-- Creates a unique string key from interface path for duplicate detection
local function pathToKey(path)
    local parts = {}
    for i, segment in ipairs(path) do
        table.insert(parts, segment[1] .. "," .. segment[2])
    end
    return table.concat(parts, ";")
end

-- Creates child interface path by appending new id2 segment
local function createChildPath(currentPath, id2)
    local childPath = {}
    -- Copy existing path segments
    for i = 1, #currentPath do
        local pathSegment = {}
        for k, v in ipairs(currentPath[i]) do
            pathSegment[k] = v
        end
        table.insert(childPath, pathSegment)
    end
    
    -- Add new segment with same path identifier as root
    local pathIdentifier = currentPath[1][1]
    table.insert(childPath, { pathIdentifier, id2, -1, 0 })
    
    return childPath
end

-- Recursively scans all interface levels and collects interface data
local function scanAllInterfaces(currentPath, visitedPaths, allInterfaces, depth, maxDepth, seenMemlocs)
    depth = depth or 0
    maxDepth = maxDepth or 50
    visitedPaths = visitedPaths or {}
    allInterfaces = allInterfaces or {}
    seenMemlocs = seenMemlocs or {}
    
    -- Prevent infinite recursion
    if depth > maxDepth then
        print("[" .. ScriptName .. "] Warning: Max depth reached (" .. depth .. ")")
        return allInterfaces
    end
    
    -- Skip if this path was already visited
    local pathKey = pathToKey(currentPath)
    if visitedPaths[pathKey] then
        return allInterfaces
    end
    visitedPaths[pathKey] = true
    
    -- Create readable path string for logging
    local pathString = ""
    for i, segment in ipairs(currentPath) do
        if i > 1 then pathString = pathString .. " -> " end
        pathString = pathString .. table.concat(segment, ",")
    end
    
    -- Create interface ID string in table format
    local interfaceIDString = "{ "
    for i, segment in ipairs(currentPath) do
        if i > 1 then interfaceIDString = interfaceIDString .. ", " end
        interfaceIDString = interfaceIDString .. "{" .. table.concat(segment, ",") .. "}"
    end
    interfaceIDString = interfaceIDString .. " }"
    
    -- Attempt to scan current interface level
    local success, interfaces = pcall(function() 
        return API.ScanForInterfaceTest2Get(true, currentPath) 
    end)
    
    if not success then
        print("[" .. ScriptName .. "] Error at depth " .. depth .. ": " .. tostring(interfaces))
        return allInterfaces
    end
    
    if not interfaces or #interfaces == 0 then
        return allInterfaces
    end
    
    print("[" .. ScriptName .. "] Level " .. depth .. ": Found " .. #interfaces .. " interfaces")
    
    -- Track unique id2 values for next level scanning
    local uniqueId2Values = {}
    local id2Count = 0
    
    -- Process each interface found at this level
    for i, interface in ipairs(interfaces) do
        -- Skip duplicates based on memory location
        if interface.memloc and seenMemlocs[interface.memloc] then
            -- Skip silently to avoid spam
        else
            if interface.memloc then 
                seenMemlocs[interface.memloc] = true 
            end

            -- Create interface copy with additional metadata
            local interfaceCopy = {
                _interfaceID = interfaceIDString,
                _depth = depth,
                -- Copy all original interface properties
                index = interface.index,
                x = interface.x,
                xs = interface.xs,
                y = interface.y,
                ys = interface.ys,
                box_x = interface.box_x,
                box_y = interface.box_y,
                scroll_y = interface.scroll_y,
                id1 = interface.id1,
                id2 = interface.id2,
                id3 = interface.id3,
                itemid1 = interface.itemid1,
                itemid1_size = interface.itemid1_size,
                itemid2 = interface.itemid2,
                hov = interface.hov,
                textids = interface.textids,
                textitem = interface.textitem,
                memloc = interface.memloc,
                memloctop = interface.memloctop,
                fullpath = interface.fullpath,
                fullIDpath = interface.fullIDpath,
                notvisible = interface.notvisible,
                OP = interface.OP,
                xy = interface.xy
            }
            
            table.insert(allInterfaces, interfaceCopy)
            
            -- Collect valid id2 values for sub-interface scanning
            if interface.id2 ~= nil and interface.id2 ~= -1 and interface.id2 ~= 0 then
                if not uniqueId2Values[interface.id2] then
                    uniqueId2Values[interface.id2] = true
                    id2Count = id2Count + 1
                end
            end
        end
    end
    
    -- Recursively scan sub-interfaces
    if id2Count > 0 then
        print("[" .. ScriptName .. "] Level " .. depth .. ": Scanning " .. id2Count .. " sub-interfaces")
        for id2, _ in pairs(uniqueId2Values) do
            local childPath = createChildPath(currentPath, id2)
            local childKey = pathToKey(childPath)
            
            if not visitedPaths[childKey] then
                scanAllInterfaces(childPath, visitedPaths, allInterfaces, depth + 1, maxDepth, seenMemlocs)
            end
        end
    end
    
    -- Clean up memory periodically
    collectgarbage("collect")
    
    return allInterfaces
end

-- Main function that scans interfaces and exports them to CSV file
local function exportInterfacesToCSV()
    print("[" .. ScriptName .. "] Starting interface scan...")
    
    -- Scan all interfaces recursively
    local allInterfaces = scanAllInterfaces(Config.StartingInterface, {}, {}, 0, 50, {})
    
    if not allInterfaces or #allInterfaces == 0 then
        print("[" .. ScriptName .. "] No interfaces found!")
        return false
    end
    
    print("[" .. ScriptName .. "] Total interfaces found: " .. #allInterfaces)
    
    -- Get unique filename to avoid overwriting
    local finalFilename = getUniqueFilename(Config.OutputFileName)
    
    -- Open file for writing
    local file = io.open(finalFilename, "w")
    if not file then
        print("[" .. ScriptName .. "] Error: Could not create file: " .. finalFilename)
        return false
    end
    
    -- Write CSV header row
    local headers = {
        "interfaceID", "depth", "index", "x", "xs", "y", "ys", "box_x", "box_y", "scroll_y",
        "id1", "id2", "id3", "itemid1", "itemid1_size", "itemid2",
        "hov", "textids", "textitem", "memloc", "memloctop",
        "fullpath", "fullIDpath", "notvisible", "OP", "xy"
    }
    
    file:write(table.concat(headers, ",") .. "\n")
    
    -- Write interface data rows
    local exportedCount = 0
    for i, interface in ipairs(allInterfaces) do
        local rowData = {
            escapeCSV(interface._interfaceID),
            escapeCSV(interface._depth),
            escapeCSV(interface.index),
            escapeCSV(interface.x),
            escapeCSV(interface.xs),
            escapeCSV(interface.y),
            escapeCSV(interface.ys),
            escapeCSV(interface.box_x),
            escapeCSV(interface.box_y),
            escapeCSV(interface.scroll_y),
            escapeCSV(interface.id1),
            escapeCSV(interface.id2),
            escapeCSV(interface.id3),
            escapeCSV(interface.itemid1),
            escapeCSV(interface.itemid1_size),
            escapeCSV(interface.itemid2),
            escapeCSV(boolToString(interface.hov)),
            escapeCSV(interface.textids),
            escapeCSV(interface.textitem),
            escapeCSV(interface.memloc),
            escapeCSV(interface.memloctop),
            escapeCSV(interface.fullpath),
            escapeCSV(interface.fullIDpath),
            escapeCSV(boolToString(interface.notvisible)),
            escapeCSV(interface.OP),
            escapeCSV(interface.xy)
        }
        
        file:write(table.concat(rowData, ",") .. "\n")
        exportedCount = exportedCount + 1
    end
    
    file:close()
    
    print("[" .. ScriptName .. "] Export completed!")
    print("[" .. ScriptName .. "] Exported " .. exportedCount .. " interfaces to: " .. finalFilename)
    
    return true
end

-- Execute the main export process
local success = exportInterfacesToCSV()

-- Display script information and results
print("=" .. string.rep("=", 50) .. "=")
print("  " .. ScriptName .. " v" .. ScriptVersion)
print("  Author: " .. Author .. " (" .. DiscordHandle .. ")")
print("  Released: " .. ReleaseDate)
print("=" .. string.rep("=", 50) .. "=")

if success then
    print("")
    print("[" .. ScriptName .. "] Export successful!")
    -- Open the output directory
    openDirectory(Config.OutputDirectory)
else
    print("")
    print("[" .. ScriptName .. "] Export failed!")
end

-- The line below is needed to run the script from the ScriptManager, do not uncomment it
-- while API.Read_LoopyLoop() do
