--Config file for woodcutter.lua for script manager

SM:AddTab("Main")
SM:Dropdown("Tree to cut", "Tree", {"None", "Regular tree - North of Burthorpe", "Regular tree - North of Draynor", "Regular tree - South of GE", "Regular tree - Woodcutter grove", "Oak tree - East of Draynor", "Oak tree - South of GE", "Oak tree - South of Varrock", "Oak tree - Woodcutter grove", "Willow tree - South of Draynor", "Willow tree - Woodcutter grove", "Teak tree - Karamja", "Maple tree - North of Seer's Village", "Acadia tree - Menaphos Imperial District",  "Acadia tree - Menaphos VIP area", "Eucaliptus trees - West of Oo'glog", "Mahogany trees - Karamja", "Ivy - falador north wall", "Ivy - falador south wall", "Ivy - Taverley east wall", "Ivy - Varrock east castle wall", "Ivy - Woodcutter grove", "Magic tree - North east of Ardougne", "Elder tree - South of Draynor", "Elder tree - South of Yanille", "Elder tree - Woodcutter grove", "Eternal magic tree - North of Eagle's Peak"}, "None")
SM:Dropdown("Where to bank", "Bank", {"Drop logs", "Burthorpe", "Draynor", "Varrock west bank", "Woodcutters grove - Log pile", "Seer's village", "Menaphos VIP area - Bank chest", "Menaphos Imperial District", "Oo'glog", "Wars retreat", "Max guild"}, {"Drop logs"})
SM:Dropdown("Aura to use", "Aura", {"None", "Lumberjack", "Greater Lumberjack", "Master Lumberjack", "Supreme Lumberjack", "Legendary Lumberjack", "Resourceful "}, "None")
SM:NumberInput("Stop at level", "MaxLevel", 121, 1, 121)
SM:NumberInput("Stop after time (min)", "MaxTime", 1440, 1, 1440)

SM:AddTab("Buffs")
SM:Checkbox("Use beaver? (Requires pouch a super restore pot)", "Beaver", false)
SM:Checkbox("Use crystalize? (Requires runes)", "Crystalize", false)
SM:Checkbox("Use cadantine incense sticks?", "CadantineStick", false)
SM:Checkbox("Use guam incense sticks?", "GuamStick", false)
SM:Checkbox("Use torstol incense sticks?", "TorstolStick", false)
SM:Checkbox("Use sharpening stone?", "SharpeningStone", false)
SM:Checkbox("Use imbued bird feed?", "ImbuedBirdFeed", false)
SM:Checkbox("Use lumberjack's courage?", "LumberjacksCourage", false)

SM:AddTab("At bank")
SM:Checkbox("Use regular juju?", "RegularJuju", false)
SM:Checkbox("Use perfect juju?", "PerfectJuju", false)
SM:Checkbox("Use perfect plus?", "PerfectPlus", false)
SM:Checkbox("Recharge GOTE?", "Gote", false)
SM:Checkbox("Siphon hatchet at level 12? (not implemented)", "Siphon", false)



--[[
TreesToCut = { 
    "None",
    "Regular tree - North of Burthorpe",
    "Regular tree - North of Draynor",
    "Regular tree - South of GE",
    "Regular tree - Woodcutter grove",
    "Oak tree - East of Draynor",
    "Oak tree - South of GE",
    "Oak tree - South of Varrock",
    "Oak tree - Woodcutter grove",
    "Willow tree - South of Draynor",
    "Willow tree - Woodcutter grove",
    "Teak tree - Karamja",
    "Maple tree - North of Seer's Village",
    "Acadia tree - Menaphos VIP area",
    "Eucaliptus trees - West of Oo'glog",
    "Mahogany trees - Karamja",
    "Ivy - falador north wall",
    "Ivy - falador south wall",
    "Ivy - Taverley east wall",
    "Ivy - Varrock east castle wall",
    "Ivy - Varrock north castle wall",
    "Ivy - Woodcutter grove",
    "Magic tree - North east of Ardougne",
    "Elder tree - South of Draynor",
    "Elder tree - South of Yanille",
    "Elder tree - Woodcutter grove", 
}

BankToBank = {
    "Drop logs",
    "Burthorpe",
    "Draynor",
    "Varrock west bank",
    "Woodcutters grove - Log pile",
    "Seer's village",
    "Menaphos VIP area - Bank chest",
    "Menaphos Imperial District",
    "Oo'glog",
    "Wars retreat",
    "Max guild"
}
]]