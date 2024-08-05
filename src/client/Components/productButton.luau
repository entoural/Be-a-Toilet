local rs = game:GetService("ReplicatedStorage")

local packages = rs:WaitForChild("Packages")

local sift = require(packages.Sift)
local dictionary = sift.Dictionary
local button

local productButton = {}
productButton.__index = productButton

productButton.props = {
	type = "ImageButton",
	onHover = true,
	onClick = true,
	callbacks = {},
	sounds = {click = "rbxassetid://6324790483", hover = "rbxassetid://7218169592", hoverVolume = 0.5},
    multis = {hover = 1.05, click = 0.95}
}

productButton.giftProps = dictionary.copyDeep(productButton.props)

function productButton.new(instance: ImageButton, type: string, callback: ({}, boolean) -> any)
    local self = setmetatable({}, productButton)

    self.instance = instance
    self.type = type
    self.callback = callback

    self.props.callbacks = {click = function()
        self.callback(self)
    end}

    self.props.instance = self.instance
    self.button = button.new(self.props)

    if self.instance:FindFirstChild("Gift") then
        self.giftProps.callbacks = {click = function()
            self.callback(self, true)
        end}
        self.giftProps.instance = self.instance:FindFirstChild("Gift")
        self.giftButton = button.new(self.giftProps)
    end

    return productButton
end

function productButton.retrieveDependencies(components)
    button = components.button
end


return productButton