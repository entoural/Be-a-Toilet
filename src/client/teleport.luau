local rs = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local packages = rs:WaitForChild("Packages")
local plr = players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")

local circle = playerGui:WaitForChild("Main").Circle
local bridgeNet = require(packages.BridgeNet2)
local deployBridge = bridgeNet.ReferenceBridge("deploy")
local spr

local teleport = {}

function teleport.teleport()
    circle.Visible = true
    spr.target(circle, 0.3, 1, {Size = UDim2.new(3, 0, 3, 0)})
    task.wait(3)
    spr.stop(circle)
    spr.target(circle, 1, 1, {Size = UDim2.new(0, 0, 0, 0)})
    circle.Visible = false
end

function teleport.start(modules: {})
    spr = modules.Util.spring

    deployBridge:Connect(function()
        teleport.teleport()
    end)
end

return teleport