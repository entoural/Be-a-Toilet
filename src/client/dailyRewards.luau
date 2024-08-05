local players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local ts = game:GetService("TweenService")
local runService = game:GetService("RunService")
local soundService = game:GetService("SoundService")
local debris = game:GetService("Debris")

local packages = rs:WaitForChild("Packages")
local plr = players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local main = playerGui:WaitForChild("Main")
local bridgeNet = require(packages.BridgeNet2)
local janitor = require(packages.Janitor)
local sift = require(packages.Sift)
local signal = require(packages.GoodSignal)
local fusion = require(packages.Fusion)
local button
local productButton
local giftFrame
local library
local marketplaceEffect
local frame

local streakBridge = bridgeNet.ReferenceBridge("streak")
local playtimeBridge = bridgeNet.ReferenceBridge("playtimeReward")
local dictionary = sift.Dictionary
local hydrate = fusion.Hydrate
local onChange = fusion.OnChange
local spring = fusion.Spring
local value = fusion.Value
local computed = fusion.Computed
local observer = fusion.Observer
local new = fusion.New

local daily = {}
daily.defaultProps = {
	type = "ImageButton",
	onHover = true,
	onClick = true,
	callbacks = {},
	sounds = {click = "rbxassetid://18497925021", hover = "rbxassetid://18497999901", hoverVolume = 0.25, clickVolume = 0.5}
}
daily.streakInfo = {}
daily.startThread = true

daily.rewardButtons = {}
daily.dailyFrameOpened = signal.new()

function format(int)
	return string.format("%02i", int)
end

function convertToHMS(seconds)
	local minutes = (seconds - seconds%60)/60
	seconds = seconds - minutes*60
	local hours = (minutes - minutes%60)/60
	minutes = minutes - hours*60
	return format(hours)..":"..format(minutes)..":"..format(seconds)
end

function daily.heartbeat()
    if not daily.streakInfo.started then
        main.DailyFrame.ClaimIn.Visible = false
        return
    end

    local isExpireTime = os.time() - daily.streakInfo.started > daily.streakInfo.length * 86400
    local text = convertToHMS(math.floor((daily.streakInfo.started + (daily.streakInfo.length + if not isExpireTime then 0 else 1) * 86400) - os.time()))
    main.DailyFrame.ClaimIn.Text = text
    main.DailyFrame.ClaimIn.Visible = true
end

function daily.update(content)
    if content.length ~= daily.streakInfo.length and daily.streakInfo.length ~= 0 and daily.streakInfo.length then
        task.delay(3, daily.dailyFrame.close, daily.dailyFrame)
    end

    for i, v in main.DailyFrame.ScrollingFrame:GetChildren() do
        if not v:IsA("Frame") then
            continue
        end

        local num = tonumber(v.Name)
        if num <= content.length then
            v.Claim.Visible = true
            v.Claim.ImageTransparency = 1
            v.Claim.Price.Text = "Claimed"
            v.Claim.Price.TextColor3 = Color3.new(1, 1, 1)
        elseif num > content.length + 1 then
            v.Claim.Visible = false
        elseif num == content.length + 1 then
            if not content.started or (os.time() - content.started > content.length * 86400 and os.time() - content.started < (content.length + 1) * 86400) then
                if daily.tween and daily.tween.Instance ~= v then
                    daily.tween:Cancel()
                    local props = {ImageColor3 = Color3.new(0.2, 0.2, 0.2)}
                    daily.tween = ts:Create(v.ImageLabel, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 1), props)
                    daily.tween:Play()
                elseif not daily.tween then
                    local props = {ImageColor3 = Color3.new(0.2, 0.2, 0.2)}
                    daily.tween = ts:Create(v.ImageLabel, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 1), props)
                    daily.tween:Play()
                end

                v.Claim.Visible = true
                v.Claim.ImageTransparency = 0
                v.Claim.Price.Text = "Claim"
                v.Claim.Price.TextColor3 = Color3.fromRGB(22, 22, 22)
            else
                if daily.tween then
                    daily.tween:Cancel()
                end

                v.Claim.Visible = false
            end
        end
    end

    daily.streakInfo = content
end

function daily.skinsFrameUpdate()
    daily.dailyFrameOpened:Fire(daily.dailyFrame, daily.dailyFrame.opened:get())

    if daily.dailyFrame.opened:get() then
        if daily.janitor then
            daily.janitor:Destroy()
            daily.janitor = nil
        end

        daily.janitor = janitor.new()
        daily.janitor:Add(runService.Heartbeat:Connect(daily.heartbeat))
    else
        if daily.janitor then
            daily.janitor:Destroy()
            daily.janitor = nil
        end
    end
end

function daily.playtimeHeartbeat()
    local earliestUnclaimed = nil
    local earliestReceivedUnclaimed = nil
    for _, v in daily.rewardButtons do
        local t = tonumber(v.instance.Name) * 60 - (os.time() - daily.joined)
        if not v.claimed and (not earliestUnclaimed or tonumber(v.instance.Name) < tonumber(earliestUnclaimed.instance.Name)) and t >= 0 then
            earliestUnclaimed = v
        end

        if not v.claimed and t < 0 then
            earliestReceivedUnclaimed = v
        end

        if not daily.playtimeFrame.opened:get() then
            continue
        end

        if v.claimed then
            v.instance.Timer.Text = "Claimed"
            v.instance.Timer.TextColor3 = Color3.new(0.1, 0.1, 0.1)
        elseif tonumber(v.instance.Name) * 60 > os.time() - daily.joined then
            v.instance.Timer.Text = convertToHMS((tonumber(v.instance.Name) * 60) - (os.time() - daily.joined))
            v.instance.Timer.TextColor3 = Color3.new(1, 0, 0)
        elseif tonumber(v.instance.Name) * 60 <= os.time() - daily.joined then
            v.instance.Timer.Text = "Ready!"
            v.instance.Timer.TextColor3 = Color3.new(1 ,1, 1)
        end
    end

    if earliestUnclaimed then
        main.PlaytimeOpen.TextLabel.Text = convertToHMS((tonumber(earliestUnclaimed.instance.Name) * 60) - (os.time() - daily.joined))
    elseif main.PlaytimeOpen.TextLabel.Visible then
        main.PlaytimeOpen.TextLabel.Visible = false
    end

    if earliestReceivedUnclaimed then
        main.Arrows.Playtime.Visible = true
    else
        main.Arrows.Playtime.Visible = false
    end
end

--[[function daily.playtimeFrameUpdate()
    if daily.playtimeFrame.opened:get() then
        if daily.playtimeJanitor then
            daily.playtimeJanitor:Destroy()
        end

        daily.playtimeJanitor = janitor.new()
        daily.playtimeJanitor:Add(runService.Heartbeat:Connect(daily.playtimeHeartbeat))
    else
        if daily.playtimeJanitor then
            daily.playtimeJanitor:Destroy()
            daily.playtimeJanitor = nil
        end
    end
end]]

function daily.claimClicked()
    streakBridge:Fire("claim")
end

function daily.openPlaytime()
    if daily.playtimeFrame.opened:get() then
        daily.playtimeFrame:close()
    else
        daily.playtimeFrame:open()
    end
end

function daily.rewardClicked(rewardButton)
    if rewardButton.claimed then
        return
    end

    if tonumber(rewardButton.instance.Name) * 60 > os.time() - daily.joined then
        return
    end

    playtimeBridge:Fire(tonumber(rewardButton.instance.Name))
end

function daily.start(modules)
    button = modules["Components"].button
    frame = modules["Components"].frame

    for _, v in main.DailyFrame.ScrollingFrame:GetChildren() do
        if not v:IsA("Frame") then
            continue
        end

        button.new(dictionary.merge(daily.defaultProps, {instance = v.Claim, callbacks = {click = daily.claimClicked}}))
    end

    daily.dailyFrame = frame.new(main.DailyFrame, daily.skinsFrameUpdate)
    streakBridge:Connect(daily.update)

    task.spawn(function()
        streakBridge:Wait()
        daily.dailyFrame:open()
    end)

    daily.playtimeFrame = frame.new(main.PlaytimeFrame, daily.playtimeFrameUpdate)
    button.new(dictionary.merge(daily.defaultProps, {instance = main.PlaytimeOpen, callbacks = {click = daily.openPlaytime}}))

    daily.joined = os.time()
    local multis = {hover = 1.1, click = 0.9}
    for _, v in main.PlaytimeFrame.Rewards:GetChildren() do
        table.insert(daily.rewardButtons, button.new(dictionary.merge(daily.defaultProps, {instance = v, callbacks = {click = daily.rewardClicked}, claimed = false, multis = multis})))
    end

    playtimeBridge:Connect(function(content)
        if content[1] == "claimed" then
            for _, v in daily.rewardButtons do
                if tonumber(v.instance.Name) ~= content[2] then
                    continue
                end

                v.claimed = true
            end
        end
    end)

    runService.Heartbeat:Connect(daily.playtimeHeartbeat)

    local started = os.clock()
    local connection
    connection = runService.Heartbeat:Connect(function()
        if os.clock() - started <= 15 then
            main.DailyFrame.Timer.Text  = math.floor((15 - (os.clock() - started)) * 100) / 100
        else
            connection:Disconnect()
            main.DailyFrame.Timer.Text = "0"

            task.wait(0.5)

            if daily.dailyFrame.opened:get() then
                daily.dailyFrame:close()
            end
        end
    end)

    
end

return daily