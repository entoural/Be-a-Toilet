local ms = game:GetService("MarketplaceService")
local rs = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local ts = game:GetService("TweenService")
local soundService = game:GetService("SoundService")
local players = game:GetService("Players")

local packages = rs:WaitForChild("Packages")
local bridgeNet = require(packages.BridgeNet2)
local janitor = require(packages.Janitor)

local promptProductBridge = bridgeNet.ReferenceBridge("promptProduct")
local nukeBridge = bridgeNet.ReferenceBridge("nuke")
local noticeBridge = bridgeNet.ReferenceBridge("notice")
local passesBridge = bridgeNet.ReferenceBridge("passesUpdate")
local eggBridge = bridgeNet.ReferenceBridge("eggsUpdated")
local spinBridge = bridgeNet.ReferenceBridge("spins")
local giftBridge = bridgeNet.ReferenceBridge("giftUpdate")
local library
local main
local streaks
local playerService

local monetization = {}
monetization.productFunctions = {}
monetization.playerOwnsPass = `<stroke color="#000000" thickness="2.5"><b><font color="rgb(255,0,0)">Player already owns that gamepass!</font></b></stroke>`

local function rigModel(model, startAngle)
    local root = Instance.new("Part")
    root.Anchored = true
    root.Transparency = 1
    root.Size = Vector3.new(0.5, 0.5, 0.5)
    root.CFrame = CFrame.new(model:GetPivot().Position) * startAngle or CFrame.Angles(0, 0, 0)
    root.CanCollide = false
    root.Name = "Root"
    root.Parent = model

    for _, v in model:GetDescendants() do
        if not v:IsA("BasePart") or v == root then
            continue
        end

        local weld = Instance.new("WeldConstraint")
        weld.Parent = v
        weld.Part0 = v
        weld.Part1 = root

        v.Anchored = false
    end

    return root
end

monetization.waterProducts = {
    [1864091499] = 700, -- Gifts 
    [1864091687] = 15000,
    [1864091882] = 75000,
    [1864092182] = 250000,
    [1864026805] = 700, -- Self-purchased,
    [1864027169] = 15000,
    [1864027642] = 75000,
    [1864027952] = 250000
}

monetization.techEggProducts = {
    [1864534402] = 1, -- Gifts 
    [1864534601] = 3,
    [1864534689] = 10,
    [1864533442] = 1, -- Self-purchased
    [1864533580] = 3,
    [1864533719] = 10,
}

monetization.mysteryEggProducts = {
    [1864534852] = 1, -- Gifts
    [1864534947] = 3,
    [1864535148] = 10,
    [1864533900] = 1, -- Self-purchased
    [1864534009] = 3,
    [1864534133] = 10,
}

monetization.spinProducts = {
    [1868629873] = 1,
    [1868630042] = 10,
    [1868630285] = 100
}

function monetization.checkPasses(player)
    while not library do
        task.wait()
    end

    for i, v in library.passes do
        if not player.ownedPasses[i] or player.ownedPasses[i][1] then
            continue
        end

        pcall(function()
            if ms:UserOwnsGamePassAsync(player.id, v) then
                player.ownedPasses[i][1] = true
                player.ownedPasses[i][2] = "Purchased"

                if not player.ownedPasses[i][3] then
                    player.ownedPasses[i][3] = os.time()
                end

                player.data.OwnedPasses[i] = player.ownedPasses[i]
                passesBridge:Fire(player.player, player.ownedPasses)
            end
        end)
    end
end

function monetization.promptPass(player, passName)
    if playerService.players[player].ownedPasses[passName][1] then
        return
    end

    promptProductBridge:Fire(player, {type = "pass", id = library.passes[passName]})
end

function monetization.giftPass(player, productId)
    print("Thing firing")
    if not playerService.players[player] or not playerService.players[player].giftTarget:get() then
        print("No player or target")
        return
    end

    local passName = nil
    for i, v in library.giftIds do
        if v[2] == productId then
            passName = i
        end
    end

    if not passName then
        print("Couldn't find product name")
        return
    end

    local target = playerService.players[playerService.players[player].giftTarget:get()]
    if target.ownedPasses[passName][1] then
        print("Already owns pass")
        if target.ownedPasses[passName][2] == "Gifted" then
            return true
        end
        return false
    else
        print(`Gifting target.Name {passName}`)
        local giftedMessage = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">Gifted {target.player.Name} {passName} gamepass!</font></b></stroke>`
        local received = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">{player.Name} gifted you the {passName} gamepass!</font></b></stroke>`

        target.ownedPasses[passName] = {true, "Gifted", os.time()}
        target.data.OwnedPasses[passName] = {true, "Gifted", os.time()}
        noticeBridge:Fire(player, {duration = 10, text = giftedMessage})
        noticeBridge:Fire(target.player, {duration = 10, text = received})
        passesBridge:Fire(target.player, target.ownedPasses)
    end

    return true
end

function monetization.eggFromId(productId)
    if monetization.techEggProducts[productId] then
        return "Tech Egg"
    elseif monetization.mysteryEggProducts[productId] then
        return "Mystery Egg"
    end
end

function monetization.purchasedEgg(player, productId, isGift)
    if not monetization.eggFromId(productId) or not playerService.players[player] then
        print("Couldn't find either water product or player")
        return
    end

    local quantity = monetization.techEggProducts[productId] or monetization.mysteryEggProducts[productId]
    local egg = monetization.eggFromId(productId)

    local received = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">You purchased {quantity} eggs!</font></b></stroke>`
    if not isGift then
        noticeBridge:Fire(player, {duration = 10, text = received})
    end

    playerService.players[player].data.SpecialEggs[egg] += quantity
    eggBridge:Fire(player, playerService.players[player].data.SpecialEggs)

    return true
end

function monetization.giftEgg(player, productId)
    if not playerService.players[player] or not playerService.players[player].giftTarget:get() then
        print("No player or target")
        return
    end

    local name = playerService.players[player].giftTarget:get().Name
    local quantity = monetization.techEggProducts[productId] or monetization.mysteryEggProducts[productId]
    local giftedMessage = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">Gifted {name} {quantity} eggs!</font></b></stroke>`
    local received = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">{player.Name} gifted you {quantity} eggs!</font></b></stroke>`

    noticeBridge:Fire(playerService.players[player].giftTarget:get(), {duration = 10, text = received})
    noticeBridge:Fire(player, {duration = 10, text = giftedMessage})

    return monetization.purchasedEgg(playerService.players[player].giftTarget:get(), productId, true)
end

function monetization.purchasedWater(player, productId, isGift)
    if not monetization.waterProducts[productId] or not playerService.players[player] then
        print("Couldn't find either water product or player")
        return
    end

    local received = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">You purchased {monetization.waterProducts[productId]} water!</font></b></stroke>`
    if not isGift then
        noticeBridge:Fire(player, {duration = 10, text = received})
    end

    playerService.players[player]:addWater(monetization.waterProducts[productId])
    return true
end

function monetization.giftWater(player, productId)
    if not playerService.players[player] or not playerService.players[player].giftTarget:get() then
        print("No player or target")
        return
    end

    local name = playerService.players[player].giftTarget:get().Name
    local giftedMessage = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">Gifted {name} {monetization.waterProducts[productId]} water!</font></b></stroke>`
    local received = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">{player.Name} gifted you {monetization.waterProducts[productId]} water!</font></b></stroke>`
    noticeBridge:Fire(playerService.players[player].giftTarget:get(), {duration = 10, text = received})
    noticeBridge:Fire(player, {duration = 10, text = giftedMessage})

    return monetization.purchasedWater(playerService.players[player].giftTarget:get(), productId, true)
end

function monetization.purchasedSpins(player, productId)
    local count = monetization.spinProducts[productId]

    streaks.awardSpin(player, count)
    local received = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">You purchased {count} spins!</font></b></stroke>`
    noticeBridge:Fire(player, {duration = 10, text = received})

    return true
end

-- Gift Passes
monetization.productFunctions[1864093160] = monetization.giftPass
monetization.productFunctions[1864093314] = monetization.giftPass
monetization.productFunctions[1864093524] = monetization.giftPass
monetization.productFunctions[1866742986] = monetization.giftPass
monetization.productFunctions[1866743073] = monetization.giftPass
monetization.productFunctions[1866743186] = monetization.giftPass

-- Gift Water
monetization.productFunctions[1864091499] = monetization.giftWater
monetization.productFunctions[1864091687] = monetization.giftWater
monetization.productFunctions[1864091882] = monetization.giftWater
monetization.productFunctions[1864092182] = monetization.giftWater

-- Self-purchased Water
monetization.productFunctions[1864026805] = monetization.purchasedWater
monetization.productFunctions[1864027169] = monetization.purchasedWater
monetization.productFunctions[1864027642] = monetization.purchasedWater
monetization.productFunctions[1864027952] = monetization.purchasedWater

-- Gift Eggs
monetization.productFunctions[1864534402] = monetization.giftEgg
monetization.productFunctions[1864534601] = monetization.giftEgg
monetization.productFunctions[1864534689] = monetization.giftEgg
monetization.productFunctions[1864534852] = monetization.giftEgg
monetization.productFunctions[1864534947] = monetization.giftEgg
monetization.productFunctions[1864535148] = monetization.giftEgg

-- Self-purchased Eggs
monetization.productFunctions[1864533442] = monetization.purchasedEgg
monetization.productFunctions[1864533580] = monetization.purchasedEgg
monetization.productFunctions[1864533719] = monetization.purchasedEgg
monetization.productFunctions[1864533900] = monetization.purchasedEgg
monetization.productFunctions[1864534009] = monetization.purchasedEgg
monetization.productFunctions[1864534133] = monetization.purchasedEgg


for i, _ in monetization.spinProducts do
    monetization.productFunctions[i] = monetization.purchasedSpins
end

monetization.productFunctions[1865841393] = function(plr) -- 2X Size
    if not playerService.players[plr].deployed:get() or playerService.players[plr].beingKilled:get() then
        return false
    end

    local received = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">Purchased double size! +{playerService.players[plr].size.Value} Size</font></b></stroke>`

    playerService.players[plr].size.Value *= 2
    playerService.players[plr].character.HumanoidRootPart.NameTag.Frame.SizeLabel.Text = playerService.players[plr].size.Value
    main.resizePlayer(plr, playerService.players[plr].size.Value)
    noticeBridge:Fire(plr, {duration = 5, text = received})

    return true
end

monetization.productFunctions[1865841500] = function(plr) -- 60 Second Shield
    if not playerService.players[plr].deployed:get() or playerService.players[plr].beingKilled:get() or playerService.players[plr].shielded:get() then
        return false
    end

    local received = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">Received 60 second shield boost!</font></b></stroke>`
    task.spawn(main.shieldPlayer, plr, 60)
    noticeBridge:Fire(plr, {duration = 5, text = received})

    return true
end

monetization.productFunctions[1866473165] = function(plr) -- Respawn 2x size
    if not playerService.players[plr].lastKilledBy:get() or not playerService.players[plr].lastSize:get() or playerService.players[plr].deployed:get() then
        print("Was not killed / player left or not a last size or is already deployed")
        return
    end

    local size = playerService.players[plr].lastSize:get()
    local received = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">Respawning at {size * 2} size!</font></b></stroke>`

    noticeBridge:Fire(plr, {duration = 5, text = received})
    task.spawn(main.deployPlayer, plr, size * 2, false, 10)

    return true
end

monetization.productFunctions[1866473243] = function(plr) -- Revenge kill
    local lastKilled = playerService.players[plr].lastKilledBy:get()
    if not lastKilled or not playerService.players[lastKilled].deployed:get() then
        print("No last killed players or player isnt deployed")
        return
    end

    local received = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">Killed {lastKilled.Name}!</font></b></stroke>`
    local killed = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(255,0,0)">Revenge killed by {plr.Name}!</font></b></stroke>`

    noticeBridge:Fire(plr, {duration = 5, text = received})
    noticeBridge:Fire(lastKilled, {duration = 10, text = killed})

    lastKilled.Character.Humanoid.Health = 0
    return true
end

monetization.productFunctions[1865841284] = function(plr) -- Nuke
    if monetization.nukeJanitor then
        monetization.nukeJanitor:Destroy()
    end
    monetization.nukeJanitor = janitor.new()

    nukeBridge:Fire(bridgeNet.AllPlayers(), {purchased = plr})

    local explosionSound = soundService.Explosion
    local nukeSound = soundService.NukeSound
    local nukeSiren = soundService.NukeSiren

    local nuke = monetization.nukeJanitor:Add(rs.Nuke:Clone(), "Destroy", "nuke")
    local explosion = monetization.nukeJanitor:Add(rs.NukeExplosion:Clone(), "Destroy", "explosion")
    nuke.Parent = game.Lighting
    explosion.Parent = game.Lighting

    monetization.nukeJanitor:Add(function()
        nukeSiren:Stop()
        nukeSound:Stop()
        explosionSound:Stop()
    end)

    nukeSiren:Play()

    monetization.nukeJanitor:Add(task.spawn(function()
        task.wait(5)

        nukeSound:Play()
        nuke:PivotTo(workspace.NukeStart.CFrame)
        nuke.Parent = workspace
        local root = rigModel(nuke, CFrame.Angles(math.rad(-90), 0, 0))

        local ti = TweenInfo.new(10, Enum.EasingStyle.Linear)
        local tween = ts:Create(root, ti, {CFrame = workspace.NukeEnd.CFrame})
        tween:Play()

        monetization.nukeJanitor:Add(tween.Completed:Connect(function()
            explosion:PivotTo(workspace.NukeEnd.CFrame)
            explosion.Parent = workspace
            explosionSound:Play()

            monetization.nukeJanitor:Remove("nuke")

            local start = os.clock()
            local totalTime = 10
            local targetScale = 150
            local currentScale = 1
            local originalMagnitude = explosion:GetExtentsSize().X / 2

            monetization.nukeJanitor:Add(runService.Heartbeat:Connect(function(dt)
                local completion = math.clamp((os.clock() - start) / totalTime, 0, 1)
                if completion == 1 then
                    monetization.nukeJanitor:Remove("heartbeat")

                    task.wait(3)

                    monetization.nukeJanitor:RemoveNoClean("thread")
                    monetization.nukeJanitor:Destroy()
                    monetization.nukeJanitor = nil

                    for i, v in playerService.players do
                        if not v.deployed:get() or not v.character or v.character.Humanoid.Health == 0 or i == plr then
                            continue
                        end

                        v.character.Humanoid.Health = 0
                    end

                    return
                end

                currentScale = completion * targetScale

                explosion:ScaleTo(currentScale)
                explosion.Effect.CFrame *= CFrame.Angles(0, dt * 3, 0)

                for i, v in playerService.players do
                    if not v.deployed:get() or not v.character or v.character.Humanoid.Health == 0 or i == plr then
                        continue
                    end

                    if (v.character:GetPivot().Position - explosion:GetPivot().Position).Magnitude < originalMagnitude * currentScale then
                        v.character.Humanoid.Health = 0
                    end
                end
            end), "Disconnect", "heartbeat")


        end), "Disconnect")
    end), true, "thread")

    return true
end

function monetization.handleReciepts(recieptInfo)
	local player = players:FindFirstChild(players:GetNameFromUserIdAsync(recieptInfo.PlayerId))
	if not player then
		return
	end

	--monetization.donationSignal:Fire(recieptInfo)

	local data = playerService.players[player].data

	if data.Purchases[recieptInfo.PurchaseId] then
        print("Already granted")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if monetization.productFunctions[recieptInfo.ProductId] then
		local res = monetization.productFunctions[recieptInfo.ProductId](player, recieptInfo.ProductId)
		if not res then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		else
			data.Purchases[recieptInfo.PurchaseId] = true
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	else
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

function monetization.start(modules: {ModuleScript})
    library = modules.library
    playerService = modules.playerService
    main = modules.main
    streaks = modules.streaks

    ms.ProcessReceipt = monetization.handleReciepts

    ms.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
        print("Prompt finished", player, gamePassId, wasPurchased)
        if not wasPurchased then
            return
        end

        local playerObject = playerService.players[player]

        for i, v in library.passes do
            if v == gamePassId then
                playerObject.ownedPasses[i] = {true, "Purchased", os.time()}
                playerObject.data.OwnedPasses[i] = playerObject.ownedPasses[i]
                print(`Bought gamepass: {i}`)
            end
        end

        passesBridge:Fire(player, playerObject.ownedPasses)
    end)

    giftBridge:Connect(function(player, content: {type: string, name: string, target: string})
        print("Received")
        local missingContent = not content.type or not content.name or not content.target
        if missingContent or (not library.giftIds[content.name] or library.giftIds[content.name][1] ~= content.type) then
            return
        end

        local foundPlayer = players:FindFirstChild(content.target) and players:FindFirstChild(content.target) ~= player
        if foundPlayer and content.type == "pass" and playerService.players[players:FindFirstChild(content.target)].ownedPasses[content.name][1] then
            noticeBridge:Fire(player, {duration = 5, text = monetization.playerOwnsPass})
            foundPlayer = false
        end

        if not foundPlayer then
            print("Not found player")
            return
        end

        playerService.players[player].giftTarget:set(players:FindFirstChild(content.target))
        giftBridge:Fire(player, {success = true, type = content.type, id = library.giftIds[content.name][2]})
        print("Successfully set target")
    end)
end

return monetization