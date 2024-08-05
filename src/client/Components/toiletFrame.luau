local rs = game:GetService("ReplicatedStorage")

local packages = rs:WaitForChild("Packages")
local toilets = rs:WaitForChild("ToiletSkinModels")

local fusion = require(packages.Fusion)
local sift = require(packages.Sift)
local library
local toiletInfo
local toiletViewport
local colorUtil
local springUtil

local dictionary = sift.Dictionary
local value = fusion.Value
local spring = fusion.Spring
local new = fusion.New
local children = fusion.Children
local hydrate = fusion.Hydrate
local onEvent = fusion.OnEvent

local toiletFrame = {}
toiletFrame.executePriority = 4
toiletFrame.__index = toiletFrame

toiletFrame.frames = {}

function toiletFrame.new(name, id, clickCallback)
    local self = setmetatable({}, toiletFrame)

    self.name = name
    self.id = id
    self.equipped = value(false)
    self.size = value(UDim2.new(1, 0, 1, 0))
    --self.color = value(Color3.new(1, 1, 1))
    self.waterBoost = library.toilets[name].waterBoost
    local color = library.toilets[name].color
    self.callback = clickCallback

    self.frame = new "Frame" {
        Size = UDim2.new((1 - (0.02 * 6)) / 6, 0, 1, 0),
        BackgroundTransparency = 1,
        [children] = {
            new "UIAspectRatioConstraint" {
                AspectRatio = 1,
                AspectType = Enum.AspectType.ScaleWithParentSize,
                DominantAxis = Enum.DominantAxis.Width
            },
            new "TextLabel" {
                BackgroundTransparency = 1,
                TextScaled = true,
                Text = self.waterBoost,
                TextColor3 = Color3.fromRGB(19, 110, 247),
                Position = UDim2.new(0.5, 0, 1.1, 0),
                Size = UDim2.new(1, 0, 0.3, 0),
                ZIndex = 4,
                AnchorPoint = Vector2.new(0.5, 1),
                FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold),
                [children] = {
                    new "UIStroke" {
                        Color = Color3.new(0, 0, 0),
                        Thickness = 2
                    }
                }
            },
            new "ImageLabel" {
                Name = "Check",
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0),
                Size = UDim2.new(0.3, 0, 0.3, 0),
                Position = UDim2.new(1, 0, 0, 0),
                Visible = false,
                Image = "rbxassetid://18337467732",
                ZIndex = 4
            },
            new "ImageLabel" {
                Name = "X",
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(0.8, 0, 0.8, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Visible = false,
                Image = "rbxassetid://18337496926",
                ZIndex = 4
            },
            new "ImageButton" {
                Size = spring(self.size, 15, 0.6),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                --ImageColor3 = spring(self.color, 15, 1),
                BackgroundTransparency = 1,
                ImageTransparency = 0.6,
                Image = "rbxassetid://18759482627",
                ZIndex = 2,

                [children] = {
                    new "UICorner" {
                        CornerRadius = UDim.new(0.2, 0)
                    },

                    new "UIGradient" {
                        Color = if color then colorUtil.colorToGradient(color) else colorUtil.colorToGradient(Color3.new(0.7, 0.7, 0.7))
                    }
                },

                [onEvent "MouseButton1Click"] = function()
                    if self.callback then
                        self.callback(self)
                    end
                end,
                [onEvent "MouseEnter"] = function()
                    self.size:set(UDim2.new(1.1, 0, 1.1, 0))
                    toiletInfo.enable(self.name)
                end,
                [onEvent "MouseLeave"] = function()
                    self.size:set(UDim2.new(1, 0, 1, 0))
                    toiletInfo.disable(self.name)
                end
            },
            new "ViewportFrame" {
                Size = UDim2.new(1, 0, 1, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                ZIndex = 3,
                Position = UDim2.new(0.5, 0, 0.5, 0),
                [children] = new "Camera" {
                    Name = "Camera"
                }
            }
        },
    }

    toiletViewport.new(self.frame.ViewportFrame, name)

    toiletFrame.frames[self.id] = self
    return self
end

function toiletFrame:equip()
    self.equipped:set(true)
    self.frame.Check.Visible = true

    if self.frame:FindFirstChild("Order") then
        self.frame.LayoutOrder = -1
    end
end

function toiletFrame:unequip()
    self.equipped:set(false)
    self.frame.Check.Visible = false

    if self.frame:FindFirstChild("Order") then
        self.frame.LayoutOrder = self.frame:FindFirstChild("Order").Value
    end
end

function toiletFrame:selectDelete(isSelected)
    springUtil.stop(self.frame.X)
    if isSelected then
        self.frame.X.Size = UDim2.new(0, 0, 0, 0)
        springUtil.target(self.frame.X, 0.8, 4, {Size = UDim2.new(0.8, 0, 0.8, 0)})
    end

    self.frame.X.Visible = isSelected
end

function toiletFrame.start(modules)
    library = modules.library
    toiletInfo = modules.toiletInfo
    springUtil = modules.Util.spring
    toiletViewport = modules.toiletViewport
    colorUtil = modules.Util.colorText
end

return toiletFrame