local rs = game:GetService("ReplicatedStorage")
local httpService = game:GetService("HttpService")

local packages = rs:WaitForChild("Packages")
local bridgeNet = require(packages.BridgeNet2)

local rewardsBridge = bridgeNet.ReferenceBridge("rewards")
local noticeBridge = bridgeNet.ReferenceBridge("notice")
local playerService

local rewards = {}
rewards.groupId = 33838237

rewards.followDebounce = {}

function rewards.checkFollowing(playerObject)
    return pcall(function()
        local follower = playerObject.id
        local followed = 4914526256

        local tab = "https://friends.roproxy.com/v1/users/"..follower.."/followings?sortOrder=Desc&limit=100"
        local response = httpService:RequestAsync({
            Url = tab,
            Method = "GET"
        });

        if response.Success then
            local tabBody = httpService:JSONDecode(response.Body)

            for _, v in tabBody.data do
                if v.id == followed then
                    return true
                end
            end
        end

        return false
    end)
end

function rewards.playerRequested(player, content)
    local object = playerService.players[player]
    if content ~= "requested" then
        if content == "twitter" and not object.data.RewardsClaimed["Twitter Follow"] then
            object.data.RewardsClaimed["Twitter Follow"] = true
            table.insert(object.data.Boosts.shield, 120)
            local received = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">Claimed a 120 second shield boost!</font></b></stroke>`
            noticeBridge:Fire(player, {duration = 10, text = received})

            rewardsBridge:Fire(player, {friends =  object.data.FriendsJoined, claimed = object.data.RewardsClaimed})
        elseif content == "roblox" and not object.data.RewardsClaimed["Roblox Follow"] then
            if table.find(rewards.followDebounce, player.Name) then
                local msg = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(255,0,0)">Wait to try again!</font></b></stroke>`
                noticeBridge:Fire(player, {duration = 10, text = msg})
            else
                table.insert(rewards.followDebounce, player.Name)

                local success, response = rewards.checkFollowing(object)

                if not success or not response then
                    local msg = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(255,0,0)">Did not detect you following!</font></b></stroke>`
                    noticeBridge:Fire(player, {duration = 10, text = msg})
                elseif success then
                    object.data.RewardsClaimed["Roblox Follow"] = true
                    local received = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">Claimed a 75,000 size boost!</font></b></stroke>`
                    noticeBridge:Fire(player, {duration = 10, text = received})

                    table.insert(object.data.Boosts.size, 75000)

                    rewardsBridge:Fire(player, {friends =  object.data.FriendsJoined, claimed = object.data.RewardsClaimed})
                end

                task.wait(45)
                table.remove(rewards.followDebounce, table.find(rewards.followDebounce, player.Name))
            end
        elseif content == "friends" and not object.data.RewardsClaimed.Friends then
            object.data.RewardsClaimed.Friends = true
            table.insert(object.data.Boosts.size, 5000)
            local received = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">Claimed a 5,000 size boost!</font></b></stroke>`
            noticeBridge:Fire(player, {duration = 10, text = received})

            rewardsBridge:Fire(player, {friends =  object.data.FriendsJoined, claimed = object.data.RewardsClaimed})
        else
            rewardsBridge:Fire(player, {friends =  object.data.FriendsJoined, claimed = object.data.RewardsClaimed})
        end

        return
    end

    if not object.data.RewardsClaimed.Group and player:GetRankInGroup(rewards.groupId) > 0 then
        object.data.RewardsClaimed.Group = true
        local received = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(50,205,50)">Claimed a 200 second speed boost!</font></b></stroke>`
        table.insert(object.data.Boosts.speed, 120)
        noticeBridge:Fire(player, {duration = 10, text = received})
    elseif not object.data.RewardsClaimed.Group and player:GetRankInGroup(rewards.groupId) == 0 then
        local msg = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(255,0,0)">Join the group to accept the reward!</font></b></stroke>`
        noticeBridge:Fire(player, {duration = 10, text = msg})
    end

    rewardsBridge:Fire(player, {friends =  object.data.FriendsJoined, claimed = object.data.RewardsClaimed})
end

function rewards.start(modules)
    playerService = modules.playerService

    rewardsBridge:Connect(rewards.playerRequested)
end

return rewards