local replicatedStorage = game:GetService("ReplicatedStorage")
local socialService = game:GetService("SocialService")
local players = game:GetService("Players")

local plr = players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local main = playerGui:WaitForChild("Main")
local packages = replicatedStorage:WaitForChild("Packages")
local bridgeNet = require(packages.BridgeNet2)
local sift = require(packages.Sift)
local dictionary = sift.Dictionary
local frame
local notifs
local button

local rewardsBridge = bridgeNet.ReferenceBridge("rewards")

local rewards = {}
rewards.startThread = true

rewards.robloxClaimed = false
rewards.twitterClaimed = false
rewards.inviteClaimed = false

rewards.defaultProps = {
	type = "ImageButton",
	onHover = true,
	onClick = true,
	callbacks = {},
	sounds = {click = "rbxassetid://18497925021", hover = "rbxassetid://18497999901", hoverVolume = 0.25, clickVolume = 0.5}
}

function rewards.followButtonClicked()
    if rewards.followFrame.opened:get() then
        rewards.followFrame:close()
    else
        rewards.followFrame:open()
    end
end

function rewards.followTwitterClicked()
    local textBox = main.FollowFrame.TextBox

    if textBox.Text == "" then
        local msg = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(255,0,0)">Enter a valid username.</font></b></stroke>`
        notifs.sendNotif({text = msg, duration = 3})
    elseif not rewards.twitterClaimed then
        rewardsBridge:Fire("twitter")
    end
end

function rewards.followRobloxClicked()
    if not rewards.robloxClaimed then
        rewardsBridge:Fire("roblox")
    end
end

function rewards.inviteClicked()
    socialService:PromptGameInvite(plr)

    if not rewards.inviteClaimed then
        rewardsBridge:Fire("friends")
    end
end

function rewards.start(modules)
    frame = modules.frame
    button = modules.button
    notifs = modules.notifs

    rewards.followFrame = frame.new(main.FollowFrame)
    rewards.followButton = button.new(dictionary.merge(rewards.defaultProps, {instance = main.FollowOpen, callbacks = {click = rewards.followButtonClicked}}))

    button.new(dictionary.merge(rewards.defaultProps, {instance = main.FollowFrame.TwitterClaim, callbacks = {click = rewards.followTwitterClicked}}))
    button.new(dictionary.merge(rewards.defaultProps, {instance = main.FollowFrame.RobloxClaim, callbacks = {click = rewards.followRobloxClicked}}))
    button.new(dictionary.merge(rewards.defaultProps, {instance = main.Invite, callbacks = {click = rewards.inviteClicked}}))

    rewardsBridge:Connect(function(content)
        if content.claimed["Roblox Follow"] then
            rewards.robloxClaimed = true
            main.FollowFrame.RobloxClaim.TextLabel.Text = "Claimed"
        end

        if content.claimed["Twitter Follow"] then
            rewards.twitterClaimed = true
            main.FollowFrame.TwitterClaim.TextLabel.Text = "Claimed"
        end

        if content.claimed.Friends then
            rewards.inviteClaimed = true
            main.Arrows.Invite.Visible = false
        else
            main.Arrows.Invite.Visible = true
        end
    end)
end

return rewards