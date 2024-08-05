local players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local packages = rs:WaitForChild("Packages")
local plr = players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local fusion = require(packages.Fusion)
local bridgeNet = require(packages.BridgeNet2)

local sprintBridge = bridgeNet.ReferenceBridge("sprint")
local value = fusion.Value
local spring = fusion.Spring
local observer = fusion.Observer
local hydrate = fusion.Hydrate
local onChange = fusion.OnChange
local library
local inventoryUI
local springUtil

local sprinting = {}

function sprinting.start(modules)
    springUtil = modules.Util.spring
    library = modules.library
    inventoryUI = modules.inventoryUI

    hydrate(plr:WaitForChild("InfoPack").Deployed) {
        [onChange "Value"] = function(newVal)
            if newVal then
                playerGui.Main.SprintFrame.Visible = true
            else
                playerGui.Main.SprintFrame.Visible = false
            end
        end
    }

    local targetProgress = value(1)
    local progress = spring(targetProgress, 1, 1.25)
    local isSprinting = value(false)

    local sprintObserver = observer(isSprinting)
    local progressObserver = observer(progress)

    sprintObserver:onChange(function()
        local boost = if inventoryUI.equippedToilet then library.toilets[inventoryUI.equippedToilet].speedBoost else 1

        if isSprinting:get() and progress:get() >= 0.05 then
            sprintBridge:Fire(true)
            springUtil.target(workspace.CurrentCamera, 1, 1, {FieldOfView = 120})
        elseif isSprinting:get() and progress:get() < 0.05 then
            sprintBridge:Fire()
            isSprinting:set(false)
            plr.Character.Humanoid.WalkSpeed = 16 * boost
        else
            sprintBridge:Fire()
            playerGui.ZoomUI.ToggleEffect.Value = false
            springUtil.target(workspace.CurrentCamera, 1, 1, {FieldOfView = 80})
        end
    end)
    progressObserver:onChange(function()
        playerGui.Main.SprintFrame.Frame.Position = UDim2.new(progress:get(), 0, 0.5, 0)

        local boost = if inventoryUI.equippedToilet then library.toilets[inventoryUI.equippedToilet].speedBoost else 1

        if isSprinting:get() and progress:get() > 0.05 then
            plr.Character.Humanoid.WalkSpeed = 16 * boost * 1.175
        elseif progress:get() < 0.05 then
            isSprinting:set(false)
            targetProgress:set(1)
            plr.Character.Humanoid.WalkSpeed = 16 * boost
        end
    end)

    UIS.InputBegan:Connect(function(input, gpe)
        if gpe or not plr.InfoPack.Deployed.Value then
            return
        end

        if (input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift) and progress:get() > 0.9 then
            targetProgress:set(0)
            isSprinting:set(true)
        end
    end)

    playerGui.Main.SprintFrame.ImageButton.MouseButton1Click:Connect(function()
        if progress:get() > 0.9 then
            targetProgress:set(0)
            isSprinting:set(true)
        end
    end)

    task.spawn(function()
        while task.wait(1/3) do
            if isSprinting:get() and plr.Character and plr.Character.Humanoid:GetState() == Enum.HumanoidStateType.Running then
                playerGui.ZoomUI.ToggleEffect.Value = true
            else
                playerGui.ZoomUI.ToggleEffect.Value = false
            end
        end
    end)
end

return sprinting