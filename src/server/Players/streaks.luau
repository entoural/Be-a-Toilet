local runService = game:GetService("RunService")
local rs = game:GetService("ReplicatedStorage")

local packages = rs:WaitForChild("Packages")
local bridgeNet = require(packages.BridgeNet2)

local spinBridge = bridgeNet.ReferenceBridge("spins")
local streakBridge = bridgeNet.ReferenceBridge("streak")
local playtimeBridge = bridgeNet.ReferenceBridge("playtimeReward")
local noticeBridge = bridgeNet.ReferenceBridge("notice")
local passesBridge = bridgeNet.ReferenceBridge("passesUpdate")
local eggBridge = bridgeNet.ReferenceBridge("eggsUpdated")
local playerService

local streaks = {}

function streaks.awardSpin(plr, count)
    playerService.players[plr].data.Spins += count or 1
    playerService.players[plr].data.streakInfo.lastClaimedSpin = os.time()
    spinBridge:Fire(plr, {purpose = "requested", count =  playerService.players[plr].data.Spins, last = playerService.players[plr].data.streakInfo.lastClaimedSpin})

    return `{count or 1} wheel spin`
end

function streaks.awardBoost(plr, data)
    table.insert(playerService.players[plr].data.Boosts[data[1]], data[2])
    return data[3]
end

streaks.playertimeRewards = {
    [2] = 20,
    [5] = {streaks.awardBoost, {"size", 2500, "2,500 size boost"}},
    [10] = {streaks.awardSpin},
    [15] = 200,
    [20] = {streaks.awardBoost, {"speed", 30, "30 second speed boost"}},
    [25] = {streaks.awardSpin},
    [30] = 500,
    [60] = 1250,
    [90] = {streaks.awardBoost, {"size", 100000, "100,000 size boost"}}
}

streaks.spinRewards = {
    [1] = {chance = 0.1, callback = function(plr)
        playerService.players[plr]:addWater(300)
    end},
    [2] = {chance = 0.01, callback = function(plr)
        if not playerService.players[plr].ownedPasses["Auto Hatch"][1] then
            playerService.players[plr].ownedPasses["Auto Hatch"] = {true, "won", os.time()}
            passesBridge:Fire(plr, playerService.players[plr].ownedPasses)
        end
    end},
    [3] = {chance = 0.5, callback = function(plr)
        playerService.players[plr].data.Spins += 1
        spinBridge:Fire(plr, {purpose = "requested", count =  playerService.players[plr].data.Spins, last = playerService.players[plr].data.streakInfo.lastClaimedSpin})
    end},
    [4] = {chance = 0.22, callback = function(plr)
        streaks.awardBoost(plr, {"shield", 60})
    end},
    [5] = {chance = 0.1, callback = function(plr)
        streaks.awardBoost(plr, {"size", 50000})
    end},
    [6] = {chance = 0.05, callback = function(plr)
        playerService.players[plr].data.SpecialEggs["Tech Egg"] += 1
        eggBridge:Fire(plr, playerService.players[plr].data.SpecialEggs)
    end}
}

function streaks.pickSpinReward()
    local weight = 0

    for _, v in streaks.spinRewards do
        weight += (v.chance * 100)
    end

    local ran = math.random(1, weight)

    weight = 0
    for i, v in streaks.spinRewards do
        weight += (v.chance * 100)
        if weight >= ran then
            return i
        end
    end
end

function streaks.streakToCash(count)
    count = math.clamp(count, 1, 30)
    return math.round((50 * count) ^ (1 + count / 30))
end

function streaks.start(modules)
    playerService = modules.playerService

    streakBridge:Connect(function(plr, content)
        if not content or content ~= "claim" then
            streakBridge:Fire(plr, playerService.players[plr].data.streakInfo)
        elseif content == "claim" then
            local info = playerService.players[plr].data.streakInfo
            if not info.started then
                info.started = os.time()
                info.length = 1

                playerService.players[plr]:addWater(streaks.streakToCash(1))
                streakBridge:Fire(plr, playerService.players[plr].data.streakInfo)
            elseif os.time() - info.started > 86400 * (info.length) and os.time() - info.started < 86400 * (info.length + 1) then
                playerService.players[plr]:addWater(streaks.streakToCash(info.length + 1))
                if info.length == 29 then
                    info.started = os.time()
                    info.length = 0
                else
                    info.length += 1
                end
            end

            streakBridge:Fire(plr, playerService.players[plr].data.streakInfo)
        end
    end)

    task.spawn(function()
        while task.wait(2) do
            local t = os.time()
            for _, plr in playerService.players do
                if not plr.data.streakInfo.started then
                    streakBridge:Fire(plr.player, plr.data.streakInfo)
                    continue
                end

                if t - plr.data.streakInfo.started > (plr.data.streakInfo.length + 1) * 86400 then
                    plr.data.streakInfo.started = nil
                    plr.data.streakInfo.length = 0
                end
                streakBridge:Fire(plr.player, plr.data.streakInfo)

                if t - plr.data.streakInfo.lastClaimedSpin >= 43200 then
                    plr.data.streakInfo.lastClaimedSpin = os.time()
                    plr.data.Spins += 1

                    spinBridge:Fire(plr, {purpose = "requested", count =  plr.data.Spins, last = plr.data.streakInfo.lastClaimedSpin})
                end
            end
        end
    end)

    spinBridge:Connect(function(plr, content)
        if not content then
            spinBridge:Fire(plr, {purpose = "requested", count =  playerService.players[plr].data.Spins, last = playerService.players[plr].data.streakInfo.lastClaimedSpin})
            return
        end

        if playerService.players[plr].data.Spins == 0 then
            return
        end

        playerService.players[plr].data.Spins -= 1
        spinBridge:Fire(plr, {purpose = "requested", count =  playerService.players[plr].data.Spins, last = playerService.players[plr].data.streakInfo.lastClaimedSpin})

        local picked = streaks.pickSpinReward()
        streaks.spinRewards[picked].callback(plr)
        spinBridge:Fire(plr, {purpose = "awarded", award = picked})
    end)

    playtimeBridge:Connect(function(plr, content)
        local object = playerService.players[plr]
        if typeof(content) ~= "number" or object[content] then
            return
        end

        if typeof(streaks.playertimeRewards[content]) == "number" and os.time() - object.joined >= content * 60 then
            object:addWater(streaks.playertimeRewards[content])
            local received = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">Received {streaks.playertimeRewards[content]} water playtime reward!</font></b></stroke>`
            noticeBridge:Fire(plr, {duration = 5, text = received})
            playtimeBridge:Fire(plr, {"claimed", content})
            object[content] = true
        elseif typeof(streaks.playertimeRewards[content]) == "table" and os.time() - object.joined >= content * 60 then
            local res = streaks.playertimeRewards[content][1](plr, streaks.playertimeRewards[content][2])
            local msg = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">Received {res} playtime reward!</font></b></stroke>`

            noticeBridge:Fire(plr, {duration = 5, text = msg})
            playtimeBridge:Fire(plr, {"claimed", content})
            object[content] = true
        end
    end)
end

return streaks