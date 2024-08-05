local rs = game:GetService("ReplicatedStorage")
local ts = game:GetService("TweenService")
local players = game:GetService("Players")

local plr = players.LocalPlayer
local packages = rs:WaitForChild("Packages")
local bridgeNet = require(packages.BridgeNet2)
local signal = require(packages.GoodSignal)
local playerGui = plr:WaitForChild("PlayerGui")
local eggBillboards = playerGui:WaitForChild("EggBillboards")
local specialEggBillboards = playerGui:WaitForChild("SpecialEggBillboards")
local lobbyFolder = workspace:WaitForChild("Lobby")
local wheel = lobbyFolder.Wheel

local specialEggBridge = bridgeNet.ReferenceBridge("eggsUpdated")
local springUtil
local otherUI
local eggBillboard

local lobby = {}
lobby.startThread = true

function lobby.wheelSequence()
    springUtil.target(wheel.Circle, 1, 2, {Color = Color3.fromRGB(4, 175, 236)})
    springUtil.target(wheel.Center, 0.7, 2, {CFrame = CFrame.new(wheel.Center.Position) * CFrame.Angles(math.rad(180), math.rad(27.893), 0)})
end

function lobby.resetWheel()
    springUtil.target(wheel.Circle, 1, 2, {Color = Color3.fromRGB(0, 0, 0)})
    springUtil.target(wheel.Center, 0.7, 2, {CFrame = CFrame.new(wheel.Center.Position) * CFrame.Angles(0, math.rad(-27.893), 0)})
end

function lobby.connectWheelPrompt()
    local prompt = wheel.Stand.Prompt

    prompt.PromptShown:Connect(lobby.wheelSequence)
    prompt.PromptHidden:Connect(lobby.resetWheel)
    prompt.Triggered:Connect(function()
        otherUI.spinFrame:open()
    end)

    lobby.resetWheel()
end

function lobby.tweenEggs()
    local ti = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 1)

    for _, v in lobbyFolder.Eggs:GetChildren() do
        ts:Create(v.Egg, ti, {CFrame = (v.Egg.CFrame + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.rad(90), 0)}):Play()
    end
end

function lobby.linkEggBillboards()
    for _, v in eggBillboards:GetChildren() do
        eggBillboard.new(v, v.Name)
    end
end

function lobby.linkSpecialEggs()
    for _, v in specialEggBillboards:GetChildren() do
        local countUpdated = signal.new()
        specialEggBridge:Connect(function(content)
            countUpdated:Fire(content[v.Name])
        end)

        eggBillboard.new(v, v.Name, countUpdated)
    end

    specialEggBridge:Fire()
end

function lobby.start(modules)
    otherUI = modules.otherUI
    springUtil = modules.Util.spring
    eggBillboard = modules.Components.eggBillboard

    lobby.connectWheelPrompt()
    lobby.tweenEggs()
    lobby.linkEggBillboards()
    lobby.linkSpecialEggs()
end

return lobby