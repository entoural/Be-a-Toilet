local players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local aes = game:GetService("AvatarEditorService")
local socialService = game:GetService("SocialService")
local runService = game:GetService("RunService")
local ts = game:GetService("TweenService")

local packages = rs:WaitForChild("Packages")
local fusion = require(packages.Fusion)
local bridgeNet = require(packages.BridgeNet2)
local signal = require(packages.GoodSignal)
local sift = require(packages.Sift)
local plr = players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local main = playerGui:WaitForChild("Main")
local billboards = playerGui:WaitForChild("Billboards")

local returnButton = main:WaitForChild("ReturnToLobby")
local userdataManipulation
local marketplaceEffect
local library
local toiletInfo
local springUtil
local button
local toiletViewport
local notifs
local frame

local killedBridge = bridgeNet.ReferenceBridge("killPlayer")
local spinBridge = bridgeNet.ReferenceBridge("spins")
local rewardsBridge = bridgeNet.ReferenceBridge("rewards")
--local wheelBridge = bridgeNet.ReferenceBridge("spinWheel")
local dictionary = sift.Dictionary
local new = fusion.New
local onEvent = fusion.OnEvent
local hydrate = fusion.Hydrate
local onChange = fusion.OnChange
local children = fusion.Children

local otherUI = {}
otherUI.startThread = true
otherUI.initThread = true

otherUI.defaultProps = {
	type = "ImageButton",
	onHover = true,
	onClick = true,
	callbacks = {},
	sounds = {click = "rbxassetid://18497925021", hover = "rbxassetid://18497999901", hoverVolume = 0.25, clickVolume = 0.5}
}

otherUI.returning = false

local function format(int)
	return string.format("%02i", int)
end

local function convertToHMS(seconds)
	local minutes = (seconds - seconds%60)/60
	seconds = seconds - minutes*60
	local hours = (minutes - minutes%60)/60
	minutes = minutes - hours*60
	return format(hours)..":"..format(minutes)..":"..format(seconds)
end

function otherUI.updateNameTags()
    for _, v in players:GetPlayers() do
        if v == plr  or not v:FindFirstChild("InfoPack") or not v.InfoPack.Deployed.Value or not v.Character.HumanoidRootPart:FindFirstChild("NameTag")then
            continue
        end

        if v.leaderstats.Size.Value < plr.leaderstats.Size.Value and v.leaderstats.Size.Value >= 1000 then
            v.Character.HumanoidRootPart:WaitForChild("NameTag").Frame.NameLabel.TextColor3 = Color3.new(0, 1, 0)
        else
            v.Character.HumanoidRootPart:WaitForChild("NameTag").Frame.NameLabel.TextColor3 = Color3.new(1, 0, 0)
        end
    end
end

function otherUI.killProductClicked(killProductButton)
    if library.devProducts[killProductButton.instance.Name] then
        marketplaceEffect.promptPurchase("devProduct", library.devProducts[killProductButton.instance.Name])
    end
end

function otherUI.scaleStrokes()
    local studioTestSize = Vector2.new(1542, 620)
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local ratio = viewportSize.X / studioTestSize.X

    for _, v in playerGui:GetDescendants() do
        if not v:IsA("UIStroke") then
            continue
        end

        v.Thickness *= ratio
    end
end

function otherUI.spinWheelClicked()
    if otherUI.spinFrame.opened:get() then
        otherUI.spinFrame:close()
    else
        otherUI.spinFrame:open()
    end
end

function otherUI.updatedSpinCount(newCount)
    local spinButton = main.SpinsFrame.Spins:FindFirstChild("1")
    if newCount == 0 then
        spinButton.Count.Visible = false
        spinButton.SpinText.Visible = false
        spinButton.ImageLabel.Visible = true
        spinButton.Price.Visible = true
        main.Arrows.Spins.Visible = false
    else
        spinButton.Count.Text = newCount.."x"
        spinButton.Count.Visible = true
        spinButton.SpinText.Visible = true
        spinButton.ImageLabel.Visible = false
        spinButton.Price.Visible = false
        main.Arrows.Spins.Visible = true
    end
end

function otherUI.update()
    if otherUI.last then
        local formattedTime = convertToHMS(86400 / 2 - (os.time() - otherUI.last))
        main.SpinsFrame.Timer.Text = formattedTime
    end
end

function otherUI.spinButtonClicked(spinButton)
    if otherUI.spins > 0 and spinButton.count == "1" then
        spinBridge:Fire(true)
    else
        marketplaceEffect.promptPurchase("devProduct", library.devProducts[spinButton.count.." Spin"])
    end
end

function otherUI.returnButtonClicked()
    if otherUI.returning then
        return
    end

    otherUI.returning = true
    returnButton.Time.Text = "7"

    local startTime = os.time()
    local connection
    connection = runService.Heartbeat:Connect(function()
        local count = math.clamp(os.time() - startTime, 0, 7)
        returnButton.Time.Text = 7 - count

        if count == 7 then
            connection:Disconnect()

            returnButton.Time.Text = ""

            if plr.Character then
                plr.Character.Humanoid.Health = 0
                otherUI.returning = false
            end
        end
    end)
end

function otherUI.setUpEggOptions()
    for _, egg in main.ShopFrame.Pages.Eggs:GetChildren() do
        if not egg:IsA("Frame") then continue end

        local eggTable = if egg.Name == "Mystery Egg" then library.eggs["???"] else library.eggs[egg.Name]

        for toiletName, chance in eggTable.options do
            local toiletFrame = new "ImageLabel" {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.178, 0, 1, 0),
                Image = "rbxassetid://18337189576",
                Name = toiletName,
                Parent = egg.Options,

                [children] = {
                    new "TextLabel" {
                        TextScaled = true,
                        FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular),
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0.5, 0, 0.9, 0),
                        Size = UDim2.new(1, 0, 0.2, 0),
                        TextColor3 = Color3.new(0, 0.7, 1),
                        Text = library.toilets[toiletName].waterBoost,
                        ZIndex = 2
                    },
                    new "TextLabel" {
                        TextScaled = true,
                        FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular),
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0.5, 0, 0.1, 0),
                        Size = UDim2.new(1, 0, 0.2, 0),
                        TextColor3 = Color3.new(0.015686, 0.760784, 0.176470),
                        Text = chance * 100 .. "%",
                        ZIndex = 2
                    },
                    new "ViewportFrame" {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        Name = "Viewport",
                        [children] = {
                            new "Camera" {
                                Name = "Camera"
                            }
                        }
                    },
                    new "UIAspectRatioConstraint" {
                        AspectRatio = 1
                    },
                    new "TextButton" {
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        Text = "",
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        Size = UDim2.new(1, 0, 1, 0),
                        ZIndex = 3,
                        [onEvent "MouseEnter"] = function()
                            toiletInfo.enable(toiletName)
                        end,
                        [onEvent "MouseLeave"] = function()
                            toiletInfo.disable()
                        end
                    }
                }
            }

            toiletViewport.new(toiletFrame.Viewport, toiletName)
        end
    end
end

function otherUI.init()
    local function attempt()
        local success, err = pcall(function()
            return game:GetService("StarterGui"):SetCore("ResetButtonCallback", false)
        end)
        if not success then
            task.wait(5)
            attempt()
        end
    end

    attempt()
end

function otherUI.start(modules)
    frame = modules.Components["frame"]
    button = modules.Components["button"]
    toiletViewport = modules.toiletViewport
    userdataManipulation = modules.Util.userdataManipulation
    marketplaceEffect = modules.marketplaceEffect
    springUtil = modules.Util.spring
    toiletInfo = modules.toiletInfo
    notifs = modules.notifs
    library = modules.library

    otherUI.deathFrame = frame.new(main.DiedFrame)
    otherUI.spinFrame = frame.new(main.SpinsFrame)

    button.new(dictionary.merge(otherUI.defaultProps, {instance = main.DiedFrame:FindFirstChild("Revenge Kill"), callbacks = {click = otherUI.killProductClicked}}))
    button.new(dictionary.merge(otherUI.defaultProps, {instance = main.DiedFrame:FindFirstChild("Respawn 2x Size"), callbacks = {click = otherUI.killProductClicked}}))
    button.new(dictionary.merge(otherUI.defaultProps, {instance = main.SpinsOpen, callbacks = {click = otherUI.spinWheelClicked}}))
    button.new(dictionary.merge(otherUI.defaultProps, {instance = returnButton, callbacks = {click = otherUI.returnButtonClicked}}))

    otherUI.setUpEggOptions()

    spinBridge:Connect(function(content)
        if content.purpose == "requested" then
            if content.spins ~= content.count then
                otherUI.spins = content.count
                otherUI.updatedSpinCount(content.count)
            end
            otherUI.last = content.last
        elseif content.purpose == "awarded" then

            for _, v in main.SpinsFrame.Spins:GetChildren() do
                v.Visible = false
            end

            local wheel = main.SpinsFrame.Outline.Wheel
            springUtil.stop(wheel)
            wheel.Rotation = 0

            local connection = runService.Heartbeat:Connect(function()
                local isAtHalfArc = (wheel.Rotation%60 > 57 or wheel.Rotation%60  < 3)
                if (wheel.Rotation%30 > 28 or wheel.Rotation%30 < 2 and (wheel.Rotation > 3 and wheel.Rotation < 357)) and not isAtHalfArc then
                    main.SpinsFrame.Indicator.Rotation = 15
                else
                    main.SpinsFrame.Indicator.Rotation = 0
                end
            end)

            springUtil.target(wheel, 1, 0.5, {Rotation = 15})
            task.wait(2)

            local pickedRotation = (content.award - 1) * 60
            local rot = math.random(pickedRotation - 14, pickedRotation + 14)

            springUtil.target(wheel, 1, 0.15, {Rotation = -(360 * 4) - rot})
            task.wait(10)
            connection:Disconnect()
            for _, v in main.SpinsFrame.Spins:GetChildren() do
                v.Visible = true
            end

            local awardedName = main.SpinsFrame.Outline.Wheel:FindFirstChild("Arc"..content.award).Award.Text
            local msg = `<stroke color="#000000" thickness="2.5"><b><font color="rgb(255,255,255)">You won {awardedName}!</font></b></stroke>`
            notifs.sendNotif({duration = 3, text = msg})
        end
    end)

    for _, v in main.SpinsFrame.Spins:GetChildren() do
        button.new(dictionary.merge(otherUI.defaultProps, {instance = v, callbacks = {click = otherUI.spinButtonClicked}, count = v.Name}))
    end

    spinBridge:Fire()
    runService.Heartbeat:Connect(otherUI.update)

    killedBridge:Connect(function(content: {killed: Player, killedBy: Player})
        if content.killed ~= plr then
            return
        end

        local size = plr.leaderstats.Size.Value
        local kills = plr.InfoPack.Kills.Value
        local killedSize = content.killedBy.leaderstats.Size.Value
        local killedKills = content.killedBy.InfoPack.Kills.Value
        local name = content.killedBy.Name

        local success, image = pcall(function()
            return players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        end)
        if success then
            main.DiedFrame.HeadshotFrame.ImageLabel.Image = image
        else
            main.DiedFrame.HeadshotFrame.ImageLabel.Visible = false
        end

        task.wait(2)

        main.DiedFrame.SizeLabel.Text = killedSize
        main.DiedFrame.KillsLabel.Text = killedKills
        main.DiedFrame.PlayerName.Text = name

        main.DiedFrame.MyKills.Count.Text = kills
        main.DiedFrame.MySize.Count.Text = size

        if not content.killedBy then
            main.DiedFrame:FindFirstChild("Revenge Kill").Visible = false
            main.DiedFrame.RevengeLabel.Visible = false
        else
            main.DiedFrame:FindFirstChild("Revenge Kill").Visible = true
            main.DiedFrame.RevengeLabel.Visible = true
        end

        otherUI.deathFrame:open()

        local deathConnection
        deathConnection = content.killedBy.Character.Humanoid.Died:Connect(function()
            deathConnection:Disconnect()
            deathConnection = nil

            main.DiedFrame:FindFirstChild("Revent Kill").Visible = false
            main.DiedFrame.RevengeLabel.Visible = false
        end)

        task.wait(10)

        if otherUI.deathFrame.opened:get() then
            otherUI.deathFrame:close()
        end
        if deathConnection then
            deathConnection:Disconnect()
            deathConnection = nil
        end
    end)

    local groupClaimed = false
    local friendsClaimed = false
    rewardsBridge:Connect(function(content: {friends: {number}, claimed: {[string]: boolean}})
        --[[local friendsCompletion = math.clamp(#content.friends / 3, 0, 1)
        if friendsCompletion == 1 then
            friendsClaimed = true
        end
        billboards.Friends.Frame.Frame.Canvas.Bar.Size = UDim2.new(friendsCompletion, 0, 1, 0)

        if content.claimed.Friends then
            friendsClaimed = true
            billboards.Friends.Frame.Button.TextLabel.Text = "Claimed"
        end]]
        if content.claimed.Group then
            groupClaimed = true
            billboards.Group.Frame.Button.TextLabel.Text = "Claimed"
        end
    end)
    rewardsBridge:Fire()

    --[[billboards.Friends.Frame.Button.MouseButton1Click:Connect(function()
        rewardsBridge:Fire("requested")
        if not friendsClaimed then
            socialService:PromptGameInvite(plr)
        end
    end)]]
    billboards.Group.Frame.Button.MouseButton1Click:Connect(function()
        rewardsBridge:Fire("requested")
        --[[if not groupClaimed then
            aes:PromptSetFavorite(game.PlaceId, 1, true)
        end]]
    end)


    local deployCallbacks = {}

    hydrate(plr:WaitForChild("InfoPack").Deployed) {
        [onChange "Value"] = function(newValue)
            if newValue then
                
            end

            for _,v in deployCallbacks do
                task.spawn(v, newValue)
            end
        end
    }

    table.insert(deployCallbacks, function(isDeployed)
        main:WaitForChild("BottomProducts"):FindFirstChild("Double Size").Visible = isDeployed
        main:WaitForChild("BottomProducts"):FindFirstChild("Shield").Visible = isDeployed

        returnButton.Visible = isDeployed
    end)

    task.spawn(function()
        while task.wait(2) do
            otherUI.updateNameTags()
        end
    end)

    task.spawn(function()
        local ti = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 2)
        for i, v in main:WaitForChild("BottomProducts"):GetChildren() do
            if not v:IsA("ImageButton") then
                continue
            end

            local props = {Size = userdataManipulation.multUDim2(v.Size, 1.2)}
            ts:Create(v, ti, props):Play()

            v.MouseButton1Click:Connect(function()
                if library.devProducts[v.Name] and v.Visible == true then
                    marketplaceEffect.promptPurchase("devProduct", library.devProducts[v.Name])
                end
            end)

            task.wait(2)
        end
    end)

    local arrowTI = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    for _, v in main.Arrows:GetChildren() do
        ts:Create(v:FindFirstChildOfClass("ImageLabel"), arrowTI, {Position = UDim2.new(0.5, 0, 1, 0)}):Play()
    end

    local timeToTween = 5
    runService.RenderStepped:Connect(function()
        local hue = os.clock() % timeToTween / timeToTween
        local color = Color3.fromHSV(hue, 1, 1)

        for _, v in main.Arrows:GetChildren() do
            v:FindFirstChildOfClass("ImageLabel").ImageColor3 = color
        end
    end)

    otherUI.scaleStrokes()
end

return otherUI