local module = {}

function module.color(instance, color)
    if typeof(color) == "Color3" then
        instance.TextColor3 = color

        if instance:FindFirstChildOfClass("UIGradient") then
            instance:FindFirstChildOfClass("UIGradient"):Destroy()
        end
    elseif typeof(color) == "ColorSequence" then
        instance.TextColor3 = Color3.new(1, 1, 1)

        if instance:FindFirstChildOfClass("UIGradient") then
            instance:FindFirstChildOfClass("UIGradient").Color = color
        else
            local gradient = Instance.new("UIGradient")
            gradient.Color = color
            gradient.Enabled = true
            gradient.Parent = instance
        end
    end
end

return module