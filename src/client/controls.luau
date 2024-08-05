local rs = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local userdataManipulation
local packages = rs:WaitForChild("Packages")
local fusion = require(packages.Fusion)
local hydrate = fusion.Hydrate
local onEvent = fusion.OnEvent
local value = fusion.Value
local spring = fusion.Spring
local computed = fusion.Computed
local observer = fusion.Observer

local controls = {}
controls.keys = {
    [Enum.KeyCode.E] = {
        Gamepad = Enum.KeyCode.ButtonX,
        Touch = "touch"
    },
    [Enum.KeyCode.R] = {
        Gamepad = Enum.KeyCode.ButtonY,
        Touch = "touch"
    },
    [Enum.KeyCode.T] = {
        Gamepad = Enum.KeyCode.ButtonB,
        Touch = "touch"
    }
}
controls.primaryControlPlatform = value(nil)
controls.platformObserver = observer(controls.primaryControlPlatform)

controls.keyImages = {
    [Enum.KeyCode.E] = "rbxassetid://18269429786",
    [Enum.KeyCode.R] = "rbxassetid://18269429642",
    [Enum.KeyCode.T] = "rbxassetid://18269429515",
    [Enum.KeyCode.ButtonX] = "rbxassetid://18269429147",
    [Enum.KeyCode.ButtonY] = "rbxassetid://18250973865",
    [Enum.KeyCode.ButtonB] = "rbxassetid://18269428927",
    ["touch"] = "rbxassetid://18269429342"
}

function controls.getPlatform()
    if UIS.GamepadEnabled then
        return "Gamepad"
    end

    if UIS.KeyboardEnabled then
        return "Keyboard"
    end

    if UIS.TouchEnabled then
        return "Touch"
    end
end

function controls.getCompatibleKey(key: Enum.KeyCode | "touch")
    if controls.primaryControlPlatform:get() == "Keyboard" then
        return key
    end

    return controls.keys[key][controls.primaryControlPlatform:get()]
end

function controls.bindInputToImageButton(button: ImageButton, key: Enum.KeyCode | "touch", callback: (() -> nil) | nil, validate: () -> boolean | nil)
    local inputConnection

    local function fire()
        if validate and not validate() then
            return false
        end

        if callback then
            task.spawn(callback, key)
        end

        return true
    end

    local newKey = computed(function()
        return controls.getCompatibleKey(key)
    end)

    button.Image = controls.keyImages[newKey:get()]

    local originalSize = button.Size
    local size = value(button.Size)
    local hovering = false
    hydrate(button) {
        Size = spring(size, 14, 0.35),
        [onEvent "MouseButton1Click"] = function()
            fire()

            size:set(userdataManipulation.multUDim2(originalSize, 0.7))
            task.wait(0.3)
            if not hovering then
                size:set(originalSize)
            end
        end,
        [onEvent "MouseEnter"] = function()
            hovering = true
            size:set(userdataManipulation.multUDim2(originalSize, 1.1))
        end,
        [onEvent"MouseLeave"] = function()
            hovering = false
            size:set(originalSize)
        end
    }

    controls.platformObserver:onChange(function()
        button.Image = controls.keyImages[newKey:get()]
        if inputConnection then
            inputConnection:Disconnect()
        end

        if controls.primaryControlPlatform:get() == "Touch" then
            return
        end

        inputConnection = UIS.InputEnded:Connect(function(input)
            if input.KeyCode ~= newKey:get() then
                return
            end

            fire()
            size:set(userdataManipulation.multUDim2(originalSize, 0.7))
            task.wait(0.3)
            if not hovering then
                size:set(originalSize)
            end
        end)
    end)

    inputConnection = UIS.InputEnded:Connect(function(input, gpe)
        if input.KeyCode ~= newKey:get() or gpe then
            return
        end

        fire()
        size:set(userdataManipulation.multUDim2(originalSize, 0.7))
        task.wait(0.3)
        if not hovering then
            size:set(originalSize)
        end
    end)
end

function controls.init()
    controls.primaryControlPlatform:set(controls.getPlatform())
end

function controls.start(modules: {})

    -- Name(s) of Enum.KeyCode items separated by commas
    local KEYS = "LeftControl,RightControl"

    local mouseLockController = players.LocalPlayer
        .PlayerScripts
        :WaitForChild("PlayerModule")
        :WaitForChild("CameraModule")
        :WaitForChild("MouseLockController")

    local obj = mouseLockController:FindFirstChild("BoundKeys")
    if obj then
        obj.Value = KEYS
    else
        obj = Instance.new("StringValue")
        obj.Name = "BoundKeys"
        obj.Value = KEYS
        obj.Parent = mouseLockController
    end

    userdataManipulation = modules.Util.userdataManipulation

    UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            controls.primaryControlPlatform:set("Touch")
        elseif input.UserInputType == Enum.UserInputType.Keyboard then
            controls.primaryControlPlatform:set("Keyboard")
        elseif tostring(input.UserInputType):find("Gamepad") then
            controls.primaryControlPlatform:set("Gamepad")
        end
    end)
end

return controls