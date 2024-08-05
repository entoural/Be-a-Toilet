local rs = game:GetService("ReplicatedStorage")

local packages = rs:WaitForChild("Packages")
local sift = require(packages.Sift)
local bridgeNet = require(packages.BridgeNet2)
local fusion = require(packages.Fusion)

local updateAutoBridge = bridgeNet.ReferenceBridge("updateAutoDelete")

local array = sift.Array
local new = fusion.New
local children = fusion.Children
local onEvent = fusion.OnEvent
local spring = fusion.Spring
local value = fusion.Value

local toiletInfo
local library
local toiletViewport

local eggOption = {}
eggOption.deleteList = {}
eggOption.__index = eggOption

eggOption.colors = {[false] = Color3.fromRGB(171, 171, 171),
 [true] = Color3.fromRGB(143, 32, 32),
 hovered = Color3.fromRGB(167, 107, 107)}

function eggOption.new(name: string, eggName: string)
    local self = setmetatable({}, eggOption)

    while not library do
        task.wait()
    end

    self.name = name
    self.selected = value(false)
    self.hovered = value(false)
    self.button = new "ImageButton" {
        BackgroundTransparency = 1,
        Size = UDim2.new(1/3, 0, 1/3, 0),
        Image = "rbxassetid://18337189576",
        --[[TextScaled = true,
        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold),]]
        Name = name,
        [children] = {
            new "UIAspectRatioConstraint" {
                AspectRatio = 1
            },
            --[[new "UICorner" {
                CornerRadius = UDim.new(0.2, 0)
            },
            new "UIPadding" {
                PaddingBottom = UDim.new(0.1, 0),
                PaddingLeft = UDim.new(0.1, 0),
                PaddingRight = UDim.new(0.1, 0),
                PaddingTop = UDim.new(0.1, 0)
            }]]
            new "TextLabel" {
                TextScaled = true,
                FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular),
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.9, 0),
                Size = UDim2.new(1, 0, 0.2, 0),
                TextColor3 = Color3.new(0, 0.7, 1),
                Text = library.toilets[name].waterBoost,
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
                Text = library.eggs[eggName].options[name] * 100 .. "%",
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
            new "ImageLabel" {
                Name = "X",
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(0.4, 0, 0.4, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Visible = false,
                Image = "rbxassetid://18337496926",
                ZIndex = 4
            }
        },
        [onEvent "MouseButton1Click"] = function()
            self.selected:set(not self.selected:get())
            if self.selected:get() then
                self.button.X.Visible = true
                if not array.includes(eggOption.deleteList, self.name) then
                    eggOption.deleteList = array.push(eggOption.deleteList, self.name)
                end
            else
                if not not self.hovered:get() then
                    self.button.X.Visible = false
                end
                if array.includes(eggOption.deleteList, self.name) then
                    eggOption.deleteList = array.removeValue(eggOption.deleteList, self.name)
                end
            end

            updateAutoBridge:Fire(eggOption.deleteList)
        end,
        [onEvent "MouseEnter"] = function()
            toiletInfo.enable(self.name)
            self.hovered:set(true)
            --[[if not self.selected:get() then
            end]]
        end,
        [onEvent "MouseLeave"] = function()
            toiletInfo.disable()
            self.hovered:set(false)
            --[[if not self.selected:get() then
                self.color:set(self.colors[false])
            end]]
        end
    }

    toiletViewport.new(self.button.Viewport, name)

    return self
end

function eggOption.start(modules)
    toiletInfo = modules.toiletInfo
    toiletViewport = modules.toiletViewport
    library = modules.library
end

return eggOption