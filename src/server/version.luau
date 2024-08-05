local m = {}

function m.start()
    local StarterGui = game:GetService("StarterGui")

    local versionGui = Instance.new("ScreenGui")

    local textLabel = Instance.new("TextLabel")
    textLabel.Position = UDim2.new(1, -10, 1, 0)
    textLabel.AnchorPoint = Vector2.new(1, 1)
    textLabel.Size = UDim2.new(0, 150, 0, 40)

    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextXAlignment = Enum.TextXAlignment.Right
    textLabel.TextScaled = true

    --local placeVersion = game.PlaceVersion
    local placeVersion = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Updated
    local headerText = "Version: " .. placeVersion
    textLabel.Text = string.format(headerText)

    textLabel.Parent = versionGui
    versionGui.Parent = StarterGui
end

return m