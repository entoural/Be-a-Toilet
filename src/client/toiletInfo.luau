local UIS = game:GetService("UserInputService")
local players = game:GetService("Players")
local runService = game:GetService("RunService")

local plr = players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local main = playerGui:WaitForChild("Main")
local frame = main.ToiletInfo

local library
local util

local toiletInfo = {}
toiletInfo.isEnabling = false

function toiletInfo.enable(toilet)
    if toiletInfo.connection then
        toiletInfo.connection:Disconnect()
    end
    toiletInfo.isEnabling = true
    local info = library.toilets[toilet]

    frame.ToiletName.Text = toilet
    util.colorText.color(frame.ToiletName, info["color"] or Color3.fromRGB(81, 81, 81))

    frame.SizeBoost.Text = `{info["sizeBoost"]}x Size Boost`
    frame.SpeedBoost.Text = `{info["speedBoost"]}x Speed Boost`
    frame.WaterBoost.Text = `{info["waterBoost"]}x Water Boost`

    toiletInfo.connection = runService.Heartbeat:Connect(function()
        local pos = UIS:GetMouseLocation()
        frame.Position = UDim2.new(0, pos.X, 0, pos.Y)
    end)
    runService.Heartbeat:Wait()

    frame.Visible = true
    toiletInfo.isEnabling = false
end

function toiletInfo.disable()
    if toiletInfo.isEnabling then
        return
    end

    if toiletInfo.connection then
        toiletInfo.connection:Disconnect()
    end
    frame.Visible = false
end

function toiletInfo.start(modules)
    library = modules.library
    util = modules.Util
end

return toiletInfo