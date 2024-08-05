local LocalizationService = game:GetService("LocalizationService")
local players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local playerService
local library
local spring

local packages = rs:WaitForChild("Packages")
local bridgeNet = require(packages.BridgeNet2)

local deployBridge = bridgeNet.ReferenceBridge("deploy")
local hatchBridge = bridgeNet.ReferenceBridge("hatchEgg")
local collected = bridgeNet.ReferenceBridge("collected")
local collect = bridgeNet.ReferenceBridge("collect")
local killBridge = bridgeNet.ReferenceBridge("killPlayer")
local sprintBridge = bridgeNet.ReferenceBridge("sprint")

local deploy = workspace:WaitForChild("Lobby").Deploy
local toilet = rs:WaitForChild("Toilet")
local toilets = rs:WaitForChild("ToiletSkins")
local spawns = workspace:WaitForChild("Spawns"):GetChildren()

local main = {}
main.executePriority = 2

main.deployIgnored = {
    "Head",
    "head",
    "Torso",
    "UpperTorso"
}
main.deployIgnoredAccessories = {
    Enum.AccessoryType.Hair,
    Enum.AccessoryType.Hat
}

function main.sizeToMulti(size)
    --return if size == 1 then 0.2 else math.log(size) / math.log(10)
    return size ^ (1 / 7)
end

function main.isInRange(player, collectible)
    if not playerService.players[player] or not playerService.players[player].character then
        return false
    end

    local range = playerService.players[player].character:GetExtentsSize().Y * 0.4 + (main.sizeToMulti(playerService.players[player].size.Value) * 2) + 3
    local objectPosition = if collectible:IsA("BasePart") then collectible.Position else collectible:GetPivot().Position
    if (playerService.players[player].character.HumanoidRootPart.Position - objectPosition).Magnitude <= range then
        return true
    end
end

function main.shieldPlayer(player, dur)
    local object = playerService.players[player]
    if object.shielded:get() then
        return
    end

    object.shielded:set(true)

    local shield = rs:WaitForChild("Shield"):Clone()
    shield.CFrame = object.character:GetPivot()
    shield.Size = object.character:GetExtentsSize()
    shield.Parent = object.character

    local weld = Instance.new("WeldConstraint")
    weld.Parent = shield
    weld.Part0 = shield
    weld.Part1 = object.character.HumanoidRootPart
    shield.Anchored = false

    local heartbeat = game:GetService("RunService").Heartbeat:Connect(function()
        if not player or player.Parent ~= players then
            return
        end

        local newSize = 6.76 * main.sizeToMulti(playerService.players[player].size.Value)
        shield.Size = Vector3.new(newSize, newSize, newSize)
        shield.Mesh.Scale = Vector3.new(newSize, newSize, newSize)
    end)

    local deadConnection = object.character.Humanoid.Died:Connect(function()
        if heartbeat then
            heartbeat:Disconnect()
        end
    end)

    task.wait(dur)
    if heartbeat then
        heartbeat:Disconnect()
        object.shielded:set(false)

        spring.target(shield, 1, 1, {Size = Vector3.new(0.5, 0.5, 0.5)})
        task.wait(2)
        shield:Destroy()
    end
    if deadConnection then
        deadConnection:Disconnect()
    end
end

function main.resizePlayer(player, newSize)
    local multi = main.sizeToMulti(newSize)
    local char = playerService.players[player].character

    local hum = char.Humanoid
    hum:FindFirstChild("HeadScale").Value = multi
    hum:FindFirstChild("BodyDepthScale").Value = multi
    hum:FindFirstChild("BodyWidthScale").Value = multi
    hum:FindFirstChild("BodyHeightScale").Value = multi

    char.HumanoidRootPart.NameTag.Size = UDim2.new(7.5 * multi, 0, 3.75 * multi)
    char.Toilet.Size = main.getSizedToilet(newSize)
end

function main.getSizedToilet(size)
    local defaultSize = toilet.Size

    return defaultSize * main.sizeToMulti(size)
end

function main.deployPlayer(player, size, speed, shield)
    local object = playerService.players[player]
    if object.deployed:get() then
        return
    end

    object.deployed:set(true)
    object.deployedToilet = object.equipped

    deployBridge:Fire(player)
    object.character.HumanoidRootPart.Anchored = true
    object.character.Humanoid.JumpHeight = 0
    object.size.Value = size

    task.wait(2)
    if not object.deployed:get() or not player then
        return
    end

    for i, v in object.character:GetDescendants() do
        if not v:IsA("BasePart") or table.find(main.deployIgnored, v.Name) then
            if v:IsA("Clothing") or v:IsA("Accessory") then
                v:Destroy()
            end

            continue
        end

        v.Transparency = 1
    end

    local hum = playerService.players[player].character.Humanoid
    local multi = main.sizeToMulti(size)
    hum:FindFirstChild("HeadScale").Value = multi
    hum:FindFirstChild("BodyDepthScale").Value = multi
    hum:FindFirstChild("BodyWidthScale").Value = multi
    hum:FindFirstChild("BodyHeightScale").Value = multi

    local nameTag = rs.NameTag:Clone()
    nameTag.Size = UDim2.new(7.5 * multi, 0, 3.75 * multi)
    nameTag.Frame.NameLabel.Text = player.Name
    nameTag.Frame.SizeLabel.Text = size
    local success, err = pcall(function()
        return players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)

    if success then
        nameTag.Frame.ImageLabel.Image = err
    else
        nameTag.Frame.ImageLabel.Visible = false
    end

    nameTag.Parent = playerService.players[player].character.HumanoidRootPart

    task.spawn(main.shieldPlayer, player, shield)

    local clone = toilets:FindFirstChild(object.equipped):Clone()
    clone.CanCollide = false
    clone.Size = main.getSizedToilet(size)
    clone.CFrame = object.character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(-90), 0)
    clone.Anchored = true
    clone.Name = "Toilet"
    clone.Parent = object.character

    local weld = Instance.new("WeldConstraint")
    weld.Parent = clone
    weld.Part0 = clone
    weld.Part1 = object.character.HumanoidRootPart

    clone.Anchored = false

    local spawn = spawns[math.random(1, 4)]
    object.character.HumanoidRootPart.Anchored = false
    object.character:PivotTo(spawn.CFrame + Vector3.new(0, object.character:GetExtentsSize().Y / 2, 0))

    object.character.Humanoid.WalkSpeed = library.toilets[object.equipped].speedBoost * 16 * if speed then 2 else 1
    if speed then
        task.delay(speed, function()
            if object.deployed then
                object.character.Humanoid.WalkSpeed = library.toilets[object.deployedToilet].speedBoost * 16
            end
        end)
    end

    return true
end

function main.start(modules: {})
    playerService = modules["playerService"]
    spring = modules["Util"].spring
    library = modules.library

    for i, v in workspace:WaitForChild("Collect"):GetChildren() do
        v.Name = math.random(1, 10000000)
        local value = Instance.new("BoolValue")
        value.Name = "Collected"
        value.Value = false
        value.Parent = v
    end

    deploy.Touched:Connect(function(hit)
        for i, v in players:GetPlayers() do
            if not v.Character or hit.Parent ~= v.Character then
                continue
            end
            local object = playerService.players[v]

            local size = 1
            if #object.data.Boosts.size >= 1 then
                table.sort(object.data.Boosts.size, function(a, b)
                    return a > b
                end)
                size = object.data.Boosts.size[1]
                table.remove(object.data.Boosts.size, 1)
            end

            local speed = false
            if #object.data.Boosts.speed >= 1 then
                table.sort(object.data.Boosts.speed, function(a, b)
                    return a > b
                end)
                speed = object.data.Boosts.speed[1]
                table.remove(object.data.Boosts.speed, 1)
            end

            local shield = 10
            if #object.data.Boosts.shield >= 1 then
                table.sort(object.data.Boosts.shield, function(a, b)
                    return a > b
                end)
                shield = object.data.Boosts.shield[1]
                table.remove(object.data.Boosts.shield, 1)
            end

            main.deployPlayer(v, size, speed, shield)
        end
    end)

    collect:Connect(function(plr, content)
        local sizeValue = workspace.Collect:FindFirstChild(content.name):FindFirstChild("Size").Value
        local isInRange = main.isInRange(plr, workspace.Collect:FindFirstChild(content.name))
        local collectedValue = workspace.Collect:FindFirstChild(content.name).Collected.Value
        local size = playerService.players[plr].size.Value
        local playerSize = size >= sizeValue

        if not workspace.Collect:FindFirstChild(content.name) or not playerService.players[plr].deployed:get() or collectedValue or not isInRange or not playerSize or playerService.players[plr].beingKilled:get()then
            return
        end

        local sizeBoost = library.toilets[playerService.players[plr].deployedToilet].sizeBoost
        local waterBoost = library.toilets[playerService.players[plr].deployedToilet].waterBoost

        playerService.players[plr]:addWater(1 * waterBoost)
        workspace.Collect:FindFirstChild(content.name).Collected.Value = true
        playerService.players[plr].size.Value += if sizeValue <= 100 then sizeValue * sizeBoost else 0.55 * sizeValue * sizeBoost
        size = playerService.players[plr].size.Value

        main.resizePlayer(plr, size)
        plr.Character.HumanoidRootPart.NameTag.Frame.SizeLabel.Text = size

        collected:Fire(bridgeNet.PlayersExcept({plr}), {name = content.name, isCollected = true, isLocal = false})
        collected:Fire(plr, {name = content.name, isCollected = true, isLocal = true})

        task.wait(20)
        workspace.Collect:FindFirstChild(content.name).Collected.Value = false
        for i, v in players:GetPlayers() do
            collected:Fire(v, {name = content.name, isCollected = false, isLocal = false})
        end
    end)

    killBridge:Connect(function(plr, target)
        print("Received: ", plr, target)
        if not target or target.Parent ~= players or target == plr then
            warn("Couldn't find the target or it is equal to the player")
            return
        end

        plr.InfoPack.Kills.Value += 1

        local object = playerService.players[plr]
        local targetObject = playerService.players[target]

        if not object.deployed:get() or not targetObject.deployed:get() or targetObject.shielded:get() or targetObject.beingKilled:get() then
            print("Not deployed or shielded or is being killed")
            return
        end

        local sized = main.getSizedToilet(object.size.Value)
        local difference = object.character:GetPivot().Position - targetObject.character:GetPivot().Position
        if math.abs(difference.X) > sized.X * 1.3 and math.abs(difference.X) > sized.X * 1.3 or object.size.Value <= targetObject.size.Value then
            print("Didnt pass requirements")
            return
        end

        targetObject.beingKilled:set(true)
        targetObject.lastKilledBy:set(plr)
        local size = targetObject.size.Value
        killBridge:Fire(bridgeNet.AllPlayers(), {killed = target, killedBy = plr})

        task.delay(3, function()
            if plr and object then
                object.size.Value += size
                if object.deployed:get() then
                    main.resizePlayer(plr, object.size.Value)
                end
            end
            if targetObject.character then
                targetObject.character.Humanoid.Health = 0
            end
        end)
    end)

    sprintBridge:Connect(function(plr, content)
        if content and playerService.players[plr].deployed:get() then
            plr.Character.Toilet.Sprint.Effect1.Enabled = true
            plr.Character.Toilet.Sprint.Effect1.Enabled = true
        elseif playerService.players[plr].deployed:get() then
            plr.Character.Toilet.Sprint.Effect1.Enabled = false
            plr.Character.Toilet.Sprint.Effect1.Enabled = false
        end
    end)
end

return main