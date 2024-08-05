local rs = game:GetService("ReplicatedStorage")

local packages = rs:WaitForChild("Packages")

local fusion = require(packages.Fusion)
local sift = require(packages.Sift)
local dictionary = sift.Dictionary
local button


local array = sift.Array
local new = fusion.New
local hydrate = fusion.Hydrate
local children = fusion.Children
local onEvent = fusion.OnEvent
local spring = fusion.Spring
local value = fusion.Value

local giftFrame = {}
giftFrame.__index = giftFrame

giftFrame.props = {
	type = "ImageButton",
	onHover = true,
	onClick = true,
	callbacks = {},
	sounds = {click = "rbxassetid://18497925021", hover = "rbxassetid://18497999901", hoverVolume = 0.25},
    multis = {hover = 1.05, click = 0.9}
}

function giftFrame.new(player: Player, callback: () -> any)
    local self = setmetatable({}, giftFrame)

    self.player = player
    self.callback = callback
    self.props.callbacks = {click = function()
        self.callback(self)
    end}

    self.frame = rs:WaitForChild("GiftFrame"):Clone()
    self.frame.Name = player.Name
    self.frame.TextLabel.Text = player.Name

    self.props.instance = self.frame.ImageButton
    self.giftButton = button.new(self.props)

    return self
end

function giftFrame.retrieveDependencies(components)
    button = components.button
end


return giftFrame