--[[local runService = game:GetService("RunService")
local rs = game:GetService("ReplicatedStorage")
local packages =  rs:WaitForChild("Packages")
local fusion = require(packages.Fusion)
local spring = fusion.Spring
local value = fusion.Value
local tween = fusion.Tween
local computed = fusion.Computed
local observer = fusion.Observer
local egg = workspace:WaitForChild("Egg")
local cam = workspace.CurrentCamera

local m = {}
m.startThread = true

function m.start()
    task.wait(5)

    local e = egg:Clone()
    e.Parent = workspace

    local rotation = value(0)
    local distance = value(-8)
    local camPos = value(cam.CFrame)
    local damp = value(0.2)
    local speed = value(15)
    local animatedRotation = spring(rotation, 15, 0.65)
    local animatedDistance = spring(distance, speed, damp)

    local eCFrame = computed(function()
        local angle = CFrame.Angles(0, 0, math.rad(animatedRotation:get()))
        return camPos:get() * CFrame.new(0, 0, animatedDistance:get()) * angle
    end)

    local render = runService.RenderStepped:Connect(function()
        camPos:set(cam.CFrame)
        e.CFrame = eCFrame:get()
    end)

    task.wait(0.5)
    for i = 1, 4 do
        if i == 1 then
            rotation:set(30)
        else
            rotation:set(-1 * rotation:get())
        end
        distance:set(distance:get() + 1)
        task.wait(0.7)
    end

    task.wait(0.5)
    rotation:set(0)
    distance:set(-2)
    task.wait(0.2)
    local t = value(0)
    local transparency = tween(t, TweenInfo.new(1))
    local observe = observer(transparency)
    observe:onChange(function()
        e.Transparency = transparency:get()
    end)
    t:set(1)
    task.wait(1)
    render:Disconnect()
    e:Destroy()
end]]

return {}