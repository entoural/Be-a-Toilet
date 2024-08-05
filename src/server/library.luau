local library = {}

library.executePriority = 5

library.eggs = {
    ["City Egg"] = {type = "Water", options = {
     ["Concrete Toilet"] = 0.50, ["Brick Toilet"] = 0.30, ["Glass Toilet"] = 0.15, ["Steel Toilet"] = 0.05},
     cost = 10
    },

    ["Nature Egg"] = {type = "Water", options = {
    ["Grass Toilet"] = 0.3, ["Wooden Toilet"] = 0.25, ["Stone Toilet"] = 0.2, ["Leafy Toilet"] = 0.15, ["Water Toilet"] = 0.1},
    cost = 4000
    },

    ["Fantasy Egg"] = {type = "Water", options = {
    ["Crystal Toilet"] = 0.25, ["Magic Toilet"] = 0.2, ["Golden Toilet"] = 0.2, ["Rainbow Toilet"] = 0.15, ["Starry Toilet"] = 0.1, ["Dragon Toilet"] = 0.1},
    cost = 25000
    },

    ["Holiday Egg"] = {type = "Water", options = {
    ["Christmas Toilet"] = 0.3, ["Halloween Toilet"] = 0.25, ["Easter Toilet"] = 0.2, ["New Years Toilet"] = 0.15, ["Valentine's Toilet"] = 0.07, ["Patriotic Toilet"] = 0.03},
    cost = 80000
    },

    ["Tech Egg"] = {type = "Robux", options = {
    ["Digital Toilet"] = 0.3, ["Robotic Toilet"] = 0.2, ["Circuit Toilet"] = 0.2, ["Holographic Toilet"] = 0.15, ["Neon Grid Toilet"] = 0.1, ["Plasma Toilet"] = 0.05},
    cost = 75
    },

    ["Mystery Egg"] = {type = "Robux", options = {
    ["Ghost Toilet"] = 0.25, ["Shadow Toilet"] = 0.2, ["Galaxy Toilet"] = 0.18, ["Slime Toilet"] = 0.15, ["Lava Toilet"] = 0.12, ["Mystic Toilet"] = 0.10},
    cost = 245
    }
}

library.specialEggs = {
    ["Tech Egg"] = {},
    ["Mystery Egg"] = {}
}

local rainbow = ColorSequence.new{
    ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),
    ColorSequenceKeypoint.new(0.2,Color3.fromRGB(255,255,0)),
    ColorSequenceKeypoint.new(0.4,Color3.fromRGB(0,255,0)),
    ColorSequenceKeypoint.new(0.6,Color3.fromRGB(0,255,255)),
    ColorSequenceKeypoint.new(0.8,Color3.fromRGB(0,0,255)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,255)),
}

library.toilets = {
    ["Default"] = {waterBoost = 1, sizeBoost = 1, speedBoost = 1},
    ["???"] = {waterBoost = "?", sizeBoost = "?", speedBoost = "?"},

    ["Concrete Toilet"] = {waterBoost = 1.5, sizeBoost = 1, speedBoost = 1, color = Color3.new(0.231372, 0.231372, 0.231372)},
    ["Brick Toilet"] = {waterBoost = 3, sizeBoost = 1.05, speedBoost = 1, color = Color3.new(0.568627, 0.141176, 0.011764)},
    ["Glass Toilet"] = {waterBoost = 5, sizeBoost = 1.075, speedBoost = 1.05, color = Color3.new(0.325490, 0.568627, 0.768627)},
    ["Steel Toilet"] = {waterBoost = 10, sizeBoost = 1.075, speedBoost = 1.05, color = ColorSequence.new(Color3.new(0.501960, 0.564705, 0.580392), Color3.new(0.4, 0.4, 0.4))},

    ["Grass Toilet"] = {waterBoost = 5, sizeBoost = 1.05, speedBoost = 1, color = Color3.new(0.454901, 0.721568, 0.419607)},
    ["Wooden Toilet"] = {waterBoost = 10, sizeBoost = 1.1, speedBoost = 1.05, color = Color3.new(0.466666, 0.317647, 0.137254)},
    ["Stone Toilet"] = {waterBoost = 20, sizeBoost = 1.1, speedBoost = 1.1, color = Color3.new(0.309803, 0.329411, 0.333333)},
    ["Leafy Toilet"] = {waterBoost = 35, sizeBoost = 1.15, speedBoost = 1.1, color = Color3.new(0.109803, 0.419607, 0.188235)},
    ["Water Toilet"] = {waterBoost = 45, sizeBoost = 1.2, speedBoost = 1.15, color = ColorSequence.new(Color3.new(0.184313, 0.6, 0.701960), Color3.new(0.188235, 0.360784, 0.686274))},

    ["Crystal Toilet"] = {waterBoost = 40, sizeBoost = 1.15, speedBoost = 1.05, color = Color3.new(0.419607, 0.635294, 0.721568)},
    ["Magic Toilet"] = {waterBoost = 50, sizeBoost = 1.2, speedBoost = 1.1, color = Color3.new(0.317647, 0.137254, 0.466666)},
    ["Golden Toilet"] = {waterBoost = 70, sizeBoost = 1.2, speedBoost = 1.15, color = Color3.new(0.905882, 0.784313, 0.090196)},
    ["Rainbow Toilet"] = {waterBoost = 95, sizeBoost = 1.2, speedBoost = 1.2, color = rainbow},
    ["Starry Toilet"] = {waterBoost = 115, sizeBoost = 1.3, speedBoost = 1.2, color = Color3.new(1, 0.850980, 0)},
    ["Dragon Toilet"] = {waterBoost = 140, sizeBoost = 1.35, speedBoost = 1.25, color = ColorSequence.new(Color3.new(0.247058, 0.607843, 0.101960), Color3.new(0.074509, 0.266666, 0.015686))},

    ["Christmas Toilet"] = {waterBoost = 120, sizeBoost = 1.3, speedBoost = 1.1, color = ColorSequence.new(Color3.new(0.819607, 0.023529, 0.023529), Color3.new(1, 1, 1))},
    ["Halloween Toilet"] = {waterBoost = 150, sizeBoost = 1.35, speedBoost = 1.1, color = ColorSequence.new(Color3.new(0.925490, 0.533333, 0.019607), Color3.new(0, 0, 0))},
    ["Easter Toilet"] = {waterBoost = 155, sizeBoost = 1.5, speedBoost = 1.25, color = Color3.new(0.905882, 0.784313, 0.090196)},
    ["New Years Toilet"] = {waterBoost = 165, sizeBoost = 1.5, speedBoost = 1.25, color = ColorSequence.new(Color3.new(0.619607, 0.611764, 0.050980), Color3.new(0.125490, 0.125490, 0.125490))},
    ["Valentine's Toilet"] = {waterBoost = 180, sizeBoost = 1.6, speedBoost = 1.25, color = Color3.new(0.725490, 0.066666, 0.396078)},
    ["Patriotic Toilet"] = {waterBoost = 200, sizeBoost = 1.75, speedBoost = 1.3, color = ColorSequence.new(Color3.new(0.607843, 0.101960, 0.101960), Color3.new(1, 1, 1), Color3.new(0, 0.266666, 1))},

    ["Digital Toilet"] = {waterBoost = 60, sizeBoost = 1.2, speedBoost = 1.1, color = Color3.new(0.109803, 0.419607, 0.188235)},
    ["Robotic Toilet"] = {waterBoost = 65, sizeBoost = 1.25, speedBoost = 1.15, color = ColorSequence.new(Color3.new(0.184313, 0.262745, 0.701960), Color3.new(0.458823, 0.458823, 0.458823))},
    ["Circuit Toilet"] = {waterBoost = 70, sizeBoost = 1.3, speedBoost = 1.175, color = ColorSequence.new(Color3.new(0.184313, 0.701960, 0.211764), Color3.new(0.227450, 0.227450, 0.227450))},
    ["Holographic Toilet"] = {waterBoost = 80, sizeBoost = 1.5, speedBoost = 1.15, color = ColorSequence.new(Color3.new(0.666666, 0.541176, 0.619607), Color3.new(0.615686, 0.705882, 0.788235))},
    ["Neon Grid Toilet"] = {waterBoost = 90, sizeBoost = 1.5, speedBoost = 1.2, color = ColorSequence.new(Color3.new(0.450980, 0.184313, 0.701960), Color3.new(0.270588, 0.686274, 0.188235))},
    ["Plasma Toilet"] = {waterBoost = 110, sizeBoost = 1.75, speedBoost = 1.35, color = ColorSequence.new(Color3.new(0.384313, 0.184313, 0.701960), Color3.new(0.686274, 0.188235, 0.686274))},

    ["Ghost Toilet"] = {waterBoost = 100, sizeBoost = 1.3, speedBoost = 1.15, color = ColorSequence.new(Color3.new(0.831372, 0.831372, 0.831372), Color3.new(0.4, 0.4, 0.4))},
    ["Shadow Toilet"] = {waterBoost = 100, sizeBoost = 1.35, speedBoost = 1.15, color = ColorSequence.new(Color3.new(0.188235, 0.188235, 0.188235), Color3.new(0.125490, 0.125490, 0.125490))},
    ["Galaxy Toilet"] = {waterBoost = 115, sizeBoost = 1.35, speedBoost = 1.2, color = ColorSequence.new(Color3.new(0.643137, 0.184313, 0.701960), Color3.new(0.039215, 0.196078, 0.713725))},
    ["Slime Toilet"] = {waterBoost = 130, sizeBoost = 1.5, speedBoost = 1.2, color = ColorSequence.new(Color3.new(0.2, 0.705882, 0.152941), Color3.new(0.082352, 0.458823, 0.113725))},
    ["Lava Toilet"] = {waterBoost = 150, sizeBoost = 1.75, speedBoost = 1.3, color = ColorSequence.new(Color3.new(0.847058, 0.227450, 0.039215), Color3.new(0.266666, 0.066666, 0.066666))},
    ["Mystic Toilet"] = {waterBoost = 175, sizeBoost = 2, speedBoost = 1.5, color = ColorSequence.new(Color3.new(0.384313, 0.184313, 0.701960), Color3.new(0.180392, 0.180392, 0.180392))}
}

library.passes = {
    ["Triple Hatch"] = 846457453,
    ["Auto Hatch"] = 846240922,
    ["Extra Inventory"] = 846334980,
    ["Lucky Hatch"] = 850312819,
    ["Extra Lucky Hatch"] = 850396419,
    ["VIP"] = 850223871
}
library.specialEggProducts = {
    ["Tech Egg"] = 1864533442,
    ["Mystery Egg"] = 1864533900
}

library.giftIds = {
    ["Triple Hatch"] = {"pass", 1864093160},
    ["Auto Hatch"] = {"pass", 1864093314},
    ["Extra Inventory"] = {"pass", 1864093524},
    ["Lucky Hatch"] = {"pass", 1866743073},
    ["Extra Lucky Hatch"] = {"pass", 1866743186},
    ["VIP"] = {"pass", 1866742986},
    ["700 Water"] = {"devProduct", 1864091499},
    ["15000 Water"] = {"devProduct", 1864091687},
    ["75000 Water"] = {"devProduct", 1864091882},
    ["250000 Water"] = {"devProduct", 1864092182},
    ["x1 Tech Egg"] = {"devProduct", 1864534402},
    ["x3 Tech Egg"] = {"devProduct", 1864534601},
    ["x10 Tech Egg"] = {"devProduct", 1864534689},
    ["x1 Mystery Egg"] = {"devProduct", 1864534852},
    ["x3 Mystery Egg"] = {"devProduct", 1864534947},
    ["x10 Mystery Egg"] = {"devProduct", 1864535148}
}

return library