local players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")

local plr = players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local main = playerGui:WaitForChild("Main")
local packages = rs:WaitForChild("Packages")
local signal = require(packages.GoodSignal)
local bridgeNet = require(packages.BridgeNet2)
local inventoryUI
local shopUI

local passesBridge = bridgeNet.ReferenceBridge("passesUpdate")

local library = {}
library.executePriority = 1

function colorToSequence(color: Color3)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, color),
        ColorSequenceKeypoint.new(1, color)})
end

library.ownedPasses = {}
library.passesChanged = signal.new()
library.billboardIgnoreParts = {plr:WaitForChild("PlayerGui"):WaitForChild("Main").Notifs}

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

library.specialEggs = {
    ["Tech Egg"] = {}
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
    ["VIP"] = 850223871,
    ["Lucky Hatch"] = 850312819,
    ["Extra Lucky Hatch"] = 850396419
}

library.devProducts = {
    ["700 Water"] = 1864026805,
    ["15000 Water"] = 1864027169,
    ["75000 Water"] = 1864027642,
    ["250000 Water"] = 1864027952,
    ["x1 Tech Egg"] = 1864533442,
    ["x3 Tech Egg"] = 1864533580,
    ["x10 Tech Egg"] = 1864533719,
    ["x1 Mystery Egg"] = 1864533900,
    ["x3 Mystery Egg"] = 1864534009,
    ["x10 Mystery Egg"] = 1864534133,
    ["Shield"] = 1865841500,
    ["Double Size"] = 1865841393,
    ["Nuke Server"] = 1865841284,
    ["Revenge Kill"] = 1866473243,
    ["Respawn 2x Size"] = 1866473165,
    ["1 Spin"] = 1868629873,
    ["10 Spin"] = 1868630042,
    ["100 Spin"] = 1868630285
}

function library.start(modules)
    inventoryUI = modules.inventoryUI
    shopUI = modules.shopUI

    for i, v in players:GetPlayers() do
        if v.Character then
            for _, instance in v.Character:GetDescendants() do
                if not instance:IsA("BasePart") and not instance:IsA("Accessory") then
                    continue
                end
                table.insert(library.billboardIgnoreParts, instance)
            end
       end

        v.CharacterAdded:Connect(function(char)
            for _, instance in char:GetDescendants() do
                if not instance:IsA("BasePart") and not instance:IsA("Accessory") then
                    continue
                end
                table.insert(library.billboardIgnoreParts, instance)
            end
        end)
    end

    players.PlayerAdded:Connect(function(newPlayer)
        newPlayer.CharacterAdded:Connect(function(char)
            for _, instance in char:GetDescendants() do
                if not instance:IsA("BasePart") and not instance:IsA("Accessory") then
                    continue
                end
                table.insert(library.billboardIgnoreParts, instance)
            end
        end)
    end)

    passesBridge:Connect(function(content)
        library.passesChanged:Fire(content)

        library.ownedPasses = content
        shopUI.updatePasses(content)
        inventoryUI.updateInventoryCount()
    end)
    passesBridge:Fire()
end

return library