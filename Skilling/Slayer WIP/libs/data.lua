local API = require("api")
local Slib = require("slib")

local DATA = {}

--https://chisel.weirdgloop.org/structs_rs3/index.html?type=enums&id=1563
DATA.Tasks = {
    ["Goblins"]             = { Id = 2,   Name = "Goblins" }, --loc
    ["Rats"]                = { Id = 3,   Name = "Rats" }, --loc
    ["Spiders"]             = { Id = 4,   Name = "Spiders" }, --loc
    ["Bats"]                = { Id = 8,   Name = "Bats" }, --loc
    ["Zombies"]             = { Id = 10,  Name = "Zombies" }, --loc
    ["Skeletons"]           = { Id = 11,  Name = "Skeletons" }, --loc
    ["Fire giants"]         = { Id = 16,  Name = "Fire giants" }, --loc
    ["Green dragons"]       = { Id = 24,  Name = "Green dragons" }, --loc
    ["Black dragons"]       = { Id = 27,  Name = "Black dragons" }, --loc
    ["Lesser demons"]       = { Id = 28,  Name = "Lesser demons" },
    ["Greater demons"]      = { Id = 29,  Name = "Greater demons" },
    ["Black demons"]        = { Id = 30,  Name = "Black demons" },
    ["Hellhounds"]          = { Id = 31,  Name = "Hellhounds" },
    ["Dagannoth"]           = { Id = 35,  Name = "Dagannoth" },
    ["Aberrant spectres"]   = { Id = 41,  Name = "Aberrant spectres" },
    ["Abyssal demons"]      = { Id = 42,  Name = "Abyssal demons" },
    ["Kalphite"]            = { Id = 53,  Name = "Kalphite" },
    ["Dark beasts"]         = { Id = 66,  Name = "Dark beasts" },
    ["Ankou"]               = { Id = 79,  Name = "Ankou" },
    ["Grotworms"]           = { Id = 112, Name = "Grotworms" },
    ["Aviansies"]           = { Id = 114, Name = "Aviansies" },
    ["Living wyverns"]      = { Id = 130, Name = "Living wyverns" },
    --["Ripper demons"]       = { Id = 131, Name = "Ripper demons" }, --Skip. Too difficult.
    --["Camel warriors"]      = { Id = 132, Name = "Camel warriors" }, --Skip. Too annoying to kill.
    ["Acheron mammoths"]    = { Id = 133, Name = "Acheron mammoths" },
    ["Dragons"]             = { Id = 173, Name = "Dragons" },
    ["Demons"]              = { Id = 174, Name = "Demons" },
    ["Fetid zombies"]       = { Id = 185, Name = "Fetid zombies" },
    ["Bound skeletons"]     = { Id = 186, Name = "Bound skeletons" },
    ["Risen ghosts"]        = { Id = 187, Name = "Risen ghosts" },
    ["Armoured phantoms"]   = { Id = 188, Name = "Armoured phantoms" },
    ["Zemouregal's undead"] = { Id = 189, Name = "Zemouregal's undead" },
    ["Undead"]              = { Id = 191, Name = "Undead" }
}

return DATA