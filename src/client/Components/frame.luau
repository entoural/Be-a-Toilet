local rs = game:GetService("ReplicatedStorage")

local packages = rs:WaitForChild("Packages")

local fusion = require(packages.Fusion)
local sift = require(packages.Sift)
local signal = require(packages.GoodSignal)

local dictionary = sift.Dictionary
local value = fusion.Value
local spring = fusion.Spring
local hydrate = fusion.Hydrate
local onEvent = fusion.OnEvent

local userdataManipulation
local button

local frame = {}
frame.loadingFinished = false
frame.loaded = signal.new()
frame.__index = frame

frame.frames = {}

function frame.new(instance, callback)
    local self = setmetatable({}, frame)

    if not userdataManipulation then
        repeat task.wait()
        until userdataManipulation
    end

    self.instance = instance
    self.opened = value(false)
    self.originalSize = instance.Size
    self.originalPosition = instance.Position
    self.callback = callback
    self.instance.Visible = false

    self.size = value(userdataManipulation.multUDim2(self.originalSize, 0.3))
    self.position = value(UDim2.new(self.originalPosition.X.Scale, 0, self.originalPosition.Y.Scale + 0.2, 0))

    hydrate(self.instance) {
        Size = spring(self.size, 35, 0.6),
        Position = spring(self.position, 25, 0.6)
    }

    if self.instance:FindFirstChild("Close") then
        local close = function()
            self:close()
        end
        button.new(dictionary.merge(button.defaultProps, {instance = self.instance.Close, callbacks = {click = close}}))
    end

    table.insert(frame.frames, self)
    return self
end

function frame:close()
    if not self.opened:get() then return end

    self.opened:set(false)
    if self.callback then
        self.callback()
    end

    self.size:set(userdataManipulation.multUDim2(self.originalSize, 0.3))
    self.position:set(UDim2.new(self.originalPosition.X.Scale, 0, self.originalPosition.Y.Scale + 0.2, 0))

    task.wait(0.1)
    self.instance.Visible = false
end

function frame:open()
    for i, v in frame.frames do
        if v == self then
            continue
        end
        v:close()
    end

    self.opened:set(true)
    if self.callback then
        self.callback(true)
    end

    self.instance.Visible = true
    self.size:set(self.originalSize)
    self.position:set(self.originalPosition)
end

function frame.retrieveDependencies(modules)
    button = modules.button
end

function frame.start(modules)
    userdataManipulation = modules.Util.userdataManipulation

    frame.loadingFinished = true
    frame.loaded:Fire()
end

return frame