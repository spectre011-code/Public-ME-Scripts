-- Data module for Spectre011's Woodcutting AIO

local DATA = {}

DATA.BUFFS = {
    ["Beaver"] = 26095,
    ["Cadantine incense sticks"] = 47712,
    ["Guam incense sticks"] = 47699,
    ["Torstol incense sticks"] = 47715,
    ["Sharpening stone"] = {58257},
    ["Imbued bird feed"] = {58258},
    ["Lumberjack's courage"] = {58259},
    ["Scrimshaw"] = {26097},
}

DATA.ITEMS = {
    ["Super restore"] = { 23399, 23401, 23403, 23405, 23407, 23409, 3024, 3026, 3028, 3030 },
    ["Beaver"] = {12021},
    ["Sharpening stone"] = {58257},
    ["Imbued bird feed"] = {58258},
    ["Lumberjack's courage"] = {58259},
    ["Regular Juju"] = {20015, 20016, 20017, 20018, 23149, 23150, 23151, 23152, 23153, 23154},
    ["Perfect Juju"] = {32753, 32755, 32757, 32759, 32849, 32851, 32853, 32855, 32857, 32859},
    ["Perfect Plus"] = {33224, 33226, 33228, 33230, 33232, 33234},
    ["GOTE"] = {44550},
    ["Sign of the Porter"] = {29275, 29276, 29277, 29278, 29279, 29280, 29281, 29282, 29283, 29284, 29285, 39493, 39494, 39495, 51487, 51490},
    ["Wood boxes"] = {
        { id = 54895, capacity = 70 },  -- Wood box
        { id = 54897, capacity = 80 },  -- Oak wood box
        { id = 54899, capacity = 90 },  -- Willow wood box
        { id = 54901, capacity = 100 }, -- Teak wood box
        { id = 54903, capacity = 110 }, -- Maple wood box
        { id = 54905, capacity = 120 }, -- Acadia wood box
        { id = 54907, capacity = 130 }, -- Mahogany wood box
        { id = 54909, capacity = 140 }, -- Yew wood box
        { id = 54911, capacity = 150 }, -- Magic wood box
        { id = 54913, capacity = 160 }, -- Elder wood box
        { id = 58253, capacity = 170 }  -- Eternal magic wood box
    }
}

DATA.LOGS = {
    {id = 1511, name = "Logs"},
    {id = 1521, name = "Oak logs"},
    {id = 1519, name = "Willow logs"},
    {id = 6333, name = "Teak logs"},
    {id = 1517, name = "Maple logs"},
    {id = 40285, name = "Acadia logs"},
    {id = 12581, name = "Eucalyptus logs"},
    {id = 6332, name = "Mahogany logs"},
    {id = 1515, name = "Yew logs"},
    {id = 1513, name = "Magic logs"},
    {id = 29556, name = "Elder logs"},
    {id = 58250, name = "Eternal magic logs"}
}

DATA.NESTS = {
    {id = 5070, name = "Bird's nest (red egg)"},
    {id = 5071, name = "Bird's nest (green egg)"},
    {id = 5072, name = "Bird's nest (blue egg)"},
    {id = 5073, name = "Bird's nest (seeds)"},
    {id = 5074, name = "Bird's nest (ring)"},
    {id = 5075, name = "Bird's nest (empty)"},
    {id = 7413, name = "Bird's nest (cheap seeds)"},
    {id = 54872, name = "Bird's nest+ (seeds)"},
    {id = 54874, name = "Bird's nest+ (ring)"},
    {id = 54876, name = "Bird's nest (wood spirits)"}    
}

DATA.LOGPILE = {
    id = 125466,
    name = "Log pile"
}

DATA.TREES = {}

DATA.TREES.REGULAR = {
    NAME = "Tree",
    ["North of Burthorpe"] = {
        area = {x1 = 2879, y1 = 3527, x2 = 2915, y2 = 3554, z = 0},
    },
    ["North of Draynor"] = {
        area = {x1 = 3114, y1 = 3299, x2 = 3137, y2 = 3324, z = 0},
    },
    ["South of GE"] = {
        area = {x1 = 3126, y1 = 3418, x2 = 3148, y2 = 3445, z = 0},
    },
    ["Woodcutter grove"] = {
        area = {x1 = 3339, y1 = 3533, x2 = 3388, y2 = 3585, z = 0},
    }
}

DATA.TREES.OAK = {
    NAME = "Oak",
    ["East of Draynor"] = {
        area = {x1 = 3105, y1 = 3246, x2 = 3132, y2 = 3262, z = 0},
    },
    ["South of GE"] = {
        area = {x1 = 3161, y1 = 3410, x2 = 3171, y2 = 3423, z = 0},
    },
    ["South of Varrock"] = {
        area = {x1 = 3199, y1 = 3347, x2 = 3211, y2 = 3373, z = 0},
    },
    ["Woodcutter grove"] = {
        area = {x1 = 3339, y1 = 3533, x2 = 3388, y2 = 3585, z = 0},
    }
}

DATA.TREES.WILLOW = {
    NAME = "Willow",
    ["South of Draynor"] = {
        area = {x1 = 3079, y1 = 3225, x2 = 3091, y2 = 3239, z = 0},
    },
    ["Woodcutter grove"] = {
        area = {x1 = 3339, y1 = 3533, x2 = 3388, y2 = 3585, z = 0},
    }
}

DATA.TREES.TEAK = {
    NAME = "Teak",
    ["Karamja"] = {
        area = {x1 = 2817, y1 = 3076, x2 = 2829, y2 = 3090, z = 0},
    }
}

DATA.TREES.MAPLE = {
    NAME = "Maple Tree",
    ["North of Seer's Village"] = {
        area = {x1 = 2717, y1 = 3493, x2 = 2737, y2 = 3502, z = 0},
    }
}

DATA.TREES.ACADIA = {
    NAME = "Acadia tree",
    ["Menaphos VIP area"] = {
        area = {x1 = 3179, y1 = 2746, x2 = 3192, y2 = 2754, z = 0},
    },
    ["Menaphos Imperial District"] = {
        area = {x1 = 3172, y1 = 2701, x2 = 3196, y2 = 2725, z = 0},
    }
}

DATA.TREES.EUCALYPTUS = {
    NAME = "Eucalyptus tree",
    ["West of Oo'glog"] = {
        area = {x1 = 2495, y1 = 2835, x2 = 2526, y2 = 2876, z = 0},
    }
}

DATA.TREES.MAHOGANY = {
    NAME = "Mahogany",
    ["Karamja"] = {
        area = {x1 = 2817, y1 = 3076, x2 = 2829, y2 = 3090, z = 0},
    }
}

DATA.TREES.IVY = {
    NAME = "Ivy",
    ["Falador north wall"] = {
        area = {x1 = 3010, y1 = 3391, x2 = 3019, y2 = 3394, z = 0},
    },
    ["Falador south wall"] = {
        area = {x1 = 3041, y1 = 3325, x2 = 3055, y2 = 3330, z = 0},
    },
    ["Taverley east wall"] = {
        area = {x1 = 2938, y1 = 3425, x2 = 2941, y2 = 3435, z = 0},
    },
    ["Varrock east castle wall"] = {
        area = {x1 = 3231, y1 = 3454, x2 = 3235, y2 = 3464, z = 0},
    },
    ["Woodcutter grove"] = {
        area = {x1 = 3337, y1 = 3555, x2 = 3345, y2 = 3561, z = 0},
    }
}

DATA.TREES.MAGIC = {
    NAME = "Magic tree",
    ["North east of Ardougne"] = {
        area = {x1 = 2696, y1 = 3392, x2 = 2708, y2 = 3401, z = 0},
    }
}

DATA.TREES.ELDER = {
    NAME = "Elder tree",
    ["South of Draynor"] = {
        area = {x1 = 3094, y1 = 3211, x2 = 3101, y2 = 3218, z = 0},
    },
    ["South of Yanille"] = {
        area = {x1 = 2570, y1 = 3056, x2 = 2578, y2 = 3064, z = 0},
    },
    ["Woodcutter grove"] = {
        area = {x1 = 3339, y1 = 3533, x2 = 3388, y2 = 3585, z = 0},
    }
}

DATA.TREES.ETERNAL_MAGIC = {
    NAME = "Eternal magic tree",
    ["North of Eagle's Peak"] = {
        area = {x1 = 2319, y1 = 3582, x2 = 2348, y2 = 3598, z = 0},
    }
}

DATA.INTERFACES = {}

DATA.INTERFACES.GOTE1 = { { 847,0,-1,0 }, { 847,30,-1,0 } }

return DATA