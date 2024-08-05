local players = game:GetService("Players")
local plr = players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local main = playerGui:WaitForChild("Main")

local frame = main.Popup
local template = frame.Template

local stat = {}
stat.__index = stat

local burst
local spring

function stat.new(statName: string, count: number?, emoji: string?, destroyCallback: () -> any, duration: number?, color: Color3?)
    while not burst or not spring do
        task.wait()
    end

    local self = setmetatable({}, stat)

    self.count = count or 1
    self.name = statName
    self.statName = statName
    self.emoji = emoji
    self.callback = destroyCallback

    self.label = template:Clone()
    self.label.Text = `+{count} {statName}{emoji}`
    self.label.TextColor3 = color or Color3.fromRGB(255, 238, 0)
    self.label.Position = UDim2.fromScale(0.5, 0.5)
    self.label.Name = statName
    self.label.Visible = true
    self.label.Parent = frame

    task.delay(0.01, function()
        spring.target(self.label, 0.75, 2, {Position = UDim2.fromScale(math.random(), math.random())})

        task.wait(duration or 4)
        burst.new(self.label)
        if self.callback then
            task.spawn(self.callback)
        end

        local nextPosition = UDim2.fromScale(self.label.Position.X.Scale - 0.1, self.label.Position.Y.Scale + 0.2)
        spring.target(self.label, 0.7, 4, {Position = nextPosition})
        task.wait(0.2)
        spring.target(self.label, 1, 3, {Position = UDim2.fromScale(2, -2)})
        task.wait(0.3)
        self.label:Destroy()

    end)

    return self
end

function stat:changeCount(newCount: number)
    self.count = newCount
    self.label.Text = `+{self.count} {self.statName}{self.emoji}`
    burst.new(self.label)
end

function stat:add(increment: number)
    self:changeCount(self.count + increment)
end

function stat.start(modules)
    burst = modules.Components.burst
    spring = modules.Util.spring
end

return stat