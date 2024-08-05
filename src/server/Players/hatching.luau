local rs = game:GetService("ReplicatedStorage")
local httpService = game:GetService("HttpService")
local runService = game:GetService("RunService")
local starterGui = game:GetService("StarterGui")
local ms = game:GetService("MarketplaceService")

type props = {ShakeOnce: boolean | nil, Magnitude: number | nil, Roughness: any, FadeIn: any, FadeOut: any, PosInf: any, RotInf: any}

local eggBillboards = starterGui:WaitForChild("EggBillboards")
local specialEggBilloards = starterGui:WaitForChild("SpecialEggBillboards")
local packages = rs:WaitForChild("Packages")
local bridgeNet = require(packages.BridgeNet2)
local fusion = require(packages.Fusion)
local hatchBrige = bridgeNet.ReferenceBridge("hatchEgg")
local hatchedBridge = bridgeNet.ReferenceBridge("hatchedEgg")
local updateInventoryBridge = bridgeNet.ReferenceBridge("updatedInventory")
local updateAutoBridge = bridgeNet.ReferenceBridge("updateAutoDelete")
local promptProductBridge = bridgeNet.ReferenceBridge("promptProduct")
local sendPlayerNotice = bridgeNet.ReferenceBridge("notice")
local specialEggBridge = bridgeNet.ReferenceBridge("eggsUpdated")
local library
local playerService
local monetization

local hatching = {}
hatching.autoCooldown = 5.5
hatching.acceptedTypes = {One = 1, Three = 3, Auto = 1}
hatching.typeGamepassNames = {["Three"] = "Triple Hatch", ["Auto"] = "Auto Hatch"}

hatching.fullInventory = `<stroke color="#000000" thickness="2.5"><b><font color="rgb(255,255,255)">Not enough</font><font color="rgb(191, 64, 191)"> inventory space!</font></b></stroke>`

--[[local function pickRandom(dictionary: {[string]: number})
    local rarestPicked = nil
    local ran = math.random()
    local optionsArray = {}

    for i, v in dictionary do
        table.insert(optionsArray, {i, v})
    end

    table.sort(optionsArray, function(a, b)
        return a[2] > b[2]
    end)

    rarestPicked = optionsArray[1]

    for _, v in optionsArray do
        if ran >= 1 - v[2] and v[2] < if rarestPicked then rarestPicked[2] else 1.5 then
            rarestPicked = v
        end
    end

    return rarestPicked[1]
end]]

local function pickRandom(dictionary: {[string]: number}, player)
    local run = 1
    if player and playerService.players[player].ownedPasses["Lucky Hatch"][1] then
        run += 1
    end

    if player and playerService.players[player].ownedPasses["Extra Lucky Hatch"][1] then
        run += 2
    end

    local picked = nil

    for _ = 1, run do
        local weight = 0

        for _, chance in dictionary do
            weight += (chance * 100)
        end

        local ran = math.random(1, weight)

        weight = 0
        local continued = false
        for i, chance in dictionary do
            if not continued then
                weight += (chance * 100)
                if weight >= ran and (if picked then dictionary[picked] >= chance else true) then
                    picked = i
                    continued = true
                end
            end
        end
    end

    return picked
end

local function isPlayerAtMaxInventory(player, count)
    local playerObject = playerService.players[player]

    local max = 50
    if playerObject.ownedPasses["Extra Inventory"][1] then
        max = 200
    end

    if #playerObject.data.Inventory + count >= max then
        sendPlayerNotice:Fire(player, {duration = 5, text = hatching.fullInventory})
        if max == 50 then
            task.spawn(monetization.promptPass, player, "Extra Inventory")
        end
        return true
    end

    return false
end

function hatching.start(modules: {ModuleScript})
    library = modules.library
    playerService = modules.playerService
    monetization = modules.monetization

    --hatchBrige:RateLimit(1, function() end)

    specialEggBridge:Connect(function(player)
        local playerSpecialEggs = playerService.players[player].data.SpecialEggs

        specialEggBridge:Fire(player, playerSpecialEggs)
    end)

    hatchBrige:Connect(function(player: Player, content: {name: string, type: string})
        local eggName = content.name
        local eggType = content.type
        local count = hatching.acceptedTypes[eggType]
        local object = playerService.players[player]
        local typeGamepassNames = hatching.typeGamepassNames
        local libraryEggs = library.eggs
        local librarySpecialEggs = library.specialEggProducts
        local specialEggs = object.data.SpecialEggs

        local conditions = { -- Will return if any of these are true
            os.clock() - object.lastHatched:get() < 5,
            not library.eggs[eggName],
            not hatching.acceptedTypes[eggType],
            object.autoHatching:get(),
            isPlayerAtMaxInventory(player, count),
            if libraryEggs[eggName].type == "Water" then object:getWater() < libraryEggs[eggName].cost * count else false
        }

        for _, v in conditions do
            if v then
                return
            end
        end

        local conditionalCallbackReturns = { -- Will return after calling the 2nd index if any of these 1st indexes are true
            {libraryEggs[eggName].type == "Robux" and specialEggs[eggName] <= count - 1,
            function()
                promptProductBridge:Fire(player, {type = "devProduct", id = librarySpecialEggs[eggName]})
            end},

            {typeGamepassNames[eggType] and not object.ownedPasses[typeGamepassNames[eggType]][1],
            function()
                monetization.promptPass(player, typeGamepassNames[eggType])
            end},

            {content.type == "Auto",
            function()
                object.autoHatching:set({content.name, 10})
            end}
        }

        for _, v in conditionalCallbackReturns do
            if v[1] then
                v[2]()
                return
            end
        end

        if library.eggs[content.name].type == "Robux" then
            object.data.SpecialEggs[content.name] -= count
            specialEggBridge:Fire(player, object.data.SpecialEggs)
        end

        if libraryEggs[eggName].type == "Water" then
            playerService.players[player]:removeWater(library.eggs[content.name].cost * count)
        end

        local picked = {}
        for i = 1, count do
            local pickedToilet = pickRandom(library.eggs[content.name].options, player)

            if not playerService.players[player].autoDelete or not table.find(playerService.players[player].autoDelete, pickedToilet) then
                local success, id = pcall(function()
                    return httpService:GenerateGUID()
                end)
                if not success then
                    warn(id)
                    continue
                end
                table.insert(playerService.players[player].data.Inventory, {pickedToilet, id})
            else
                print("Auto deleted ".. pickedToilet)
            end

            table.insert(picked, pickedToilet)
        end

        playerService.players[player].lastHatched:set(os.clock())
        updateInventoryBridge:Fire(player, {newInventory = playerService.players[player].data.Inventory})
        hatchedBridge:Fire(player, {eggName = content.name, eggCount = count, results = picked})
    end)

    runService.Heartbeat:Connect(function()
        for _, v in playerService.players do
            local autoHatching = v.autoHatching:get()
            local notEnoughWater = if autoHatching and library.eggs[autoHatching[1]].type == "Water" then v:getWater() < library.eggs[autoHatching[1]].cost else false
            if not autoHatching or not v.character or isPlayerAtMaxInventory(v.player, 1) or notEnoughWater then
                continue
            end

            local screenGui = if library.eggs[autoHatching[1]].type == "Water" then eggBillboards else specialEggBilloards

            local distance = (v.character:GetPivot().Position - screenGui:FindFirstChild(autoHatching[1]).Adornee.Position).Magnitude
            if distance > 15 then
                v.autoHatching:set(nil)
                continue
            elseif os.clock() - autoHatching[2] < hatching.autoCooldown then
                continue
            end

            if library.eggs[autoHatching[1]].type == "Robux" then
                if v.data.SpecialEggs[autoHatching[1]] == 0 then
                    v.autoHatching:set({autoHatching[1], os.clock()})
                    v.lastHatched:set(os.clock())
                    promptProductBridge:Fire(v.player, {type = "devProduct", id = library.specialEggProducts[autoHatching[1]]})
                    continue
                else
                    v.data.SpecialEggs[autoHatching[1]] -= 1
                    specialEggBridge:Fire(v.player, v.data.SpecialEggs)
                end
            else
                v:removeWater(library.eggs[autoHatching[1]].cost)
            end

            v.autoHatching:set({autoHatching[1], os.clock()})
            v.lastHatched:set(os.clock())

            local picked = {pickRandom(library.eggs[autoHatching[1]].options, v.player)}
            if not v.autoDelete or not table.find(v.autoDelete, picked[1]) then
                local success, id = pcall(function()
                    return httpService:GenerateGUID()
                end)
                if not success then
                    warn(id)
                    continue
                end
                table.insert(v.data.Inventory, {picked[1], id})
            else
                print("Auto Deleted "..picked[1])
            end

            updateInventoryBridge:Fire(v.player, {newInventory = v.data.Inventory})
            hatchedBridge:Fire(v.player, {eggName = autoHatching[1], eggCount = 1, results = picked})
        end
    end)

    updateAutoBridge:Connect(function(player: Player, content: {string})
        playerService.players[player].autoDelete = content
    end)

    --[[task.spawn(function()
        local results = {["Concrete Toilet"] = 0, ["Brick Toilet"] = 0, ["Glass Toilet"] = 0, ["Steel Toilet"] = 0}
        for i = 1, 10000 do
            results[pickRandom(library.eggs["City Egg"].options)] += 1
        end

        for i, v in results do
            print(i..": "..v.." / "..v/10000*100 .."%")
            task.wait()
        end
    end)]]
end

return hatching