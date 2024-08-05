local library = {}

library.executePriority = 5

library.eggs = {
    ["City Egg"] = {type = "Water", options = {
    ["Concrete Toilet"] = 0.50, ["Brick Toilet"] = 0.30, ["Glass Toilet"] = 0.15, ["Steel Toilet"] = 0.05},
    cost = 10
    },
    ["Tech Egg"] = {type = "Robux", options = {
    ["Digital Toilet"] = 0.3, ["Robotic Toilet"] = 0.2, ["Circuit Toilet"] = 0.2, ["Holographic Toilet"] = 0.15, ["Neon Grid Toilet"] = 0.1, ["Plasma Toilet"] = 0.05},
    cost = 75
    }
}

library.toilets = {
    ["Concrete Toilet"] = {waterBoost = 1.2, sizeBoost = 1, speedBoost = 1, Color = Color3.new(0.231372, 0.231372, 0.231372)},
    ["Brick Toilet"] = {waterBoost = 1.5, sizeBoost = 1.05, speedBoost = 1, color = Color3.new(0.568627, 0.141176, 0.011764)},
    ["Glass Toilet"] = {waterBoost = 1.65, sizeBoost = 1.075, speedBoost = 1.05, color = Color3.new(0.325490, 0.568627, 0.768627)},
    ["Steel Toilet"] = {waterBoost = 1.8, sizeBoost = 1.075, speedBoost = 1.05, color = Color3.new(0.501960, 0.564705, 0.580392)},
    ["Default"] = {waterBoost = 1, sizeBoost = 1, speedBoost = 1},
    ["Digital Toilet"] = {waterBoost = 1, sizeBoost = 1, speedBoost = 1},
    ["Robotic Toilet"] = {waterBoost = 1, sizeBoost = 1, speedBoost = 1},
    ["Circuit Toilet"] = {waterBoost = 1, sizeBoost = 1, speedBoost = 1},
    ["Holographic Toilet"] = {waterBoost = 1, sizeBoost = 1, speedBoost = 1},
    ["Neon Grid Toilet"] = {waterBoost = 1, sizeBoost = 1, speedBoost = 1},
    ["Plasma Toilet"] = {waterBoost = 1, sizeBoost = 1, speedBoost = 1}
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