local ms = game:GetService("MarketplaceService")
local rs = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local players = game:GetService("Players")

local packages = rs:WaitForChild("Packages")
local janitor = require(packages.Janitor)
local fusion = require(packages.Fusion)
local bridgeNet = require(packages.BridgeNet2)
local plr = players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local purchase = playerGui:WaitForChild("Purchase")

local hydrate = fusion.Hydrate
local value = fusion.Value
local spring = fusion.Spring
local promptProductBridge = bridgeNet.ReferenceBridge("promptProduct")

local effect = {}
effect.inProgress = false

function effect.beginEffect()
    if effect.janitor then
        effect.janitor:Destroy()
        effect.janitor = nil
    end
    effect.inProgress = true

    effect.janitor = janitor.new()
    effect.frame.Visible = true
    effect.transparency:set(0.2)
    effect.janitor:Add(function()
        effect.transparency:set(1)
        task.wait(1)
        effect.frame.Visible = false
        effect.inProgress = false
    end)

    effect.janitor:Add(runService.RenderStepped:Connect(function(dt)
        effect.frame.ImageLabel.Rotation += 360 * dt
    end))
end

function effect.endEffect()
    if not effect.janitor then
        return
    end

    if effect.janitor:Get("thread") then
        effect.janitor:Remove("thread")
    end

    effect.janitor:Add(task.spawn(function()
        task.wait(1)
        effect.janitor:RemoveNoClean("thread")
        effect.janitor:Destroy()
        effect.janitor = nil
    end), nil, "thread")
end

function effect.promptPurchase(type, id)
    if effect.inProgress then
        warn("Purchase already in progress")
        return
    end

    if type == "pass" then
        ms:PromptGamePassPurchase(plr, id)
    elseif type == "devProduct" then
        ms:PromptProductPurchase(plr, id)
    end
    effect.beginEffect()
end

function effect.start()
    effect.transparency = value(1)
    effect.frame = hydrate(purchase.Frame) {
        Transparency = spring(effect.transparency, 10, 1)
    }
    hydrate(purchase.Frame.ImageLabel) {
        ImageTransparency = spring(effect.transparency, 10, 1)
    }

    promptProductBridge:Connect(function(content: {type: string, id: number})
        effect.promptPurchase(content.type, content.id)
 
        --[[if content.type == "pass" then
            ms:PromptGamePassPurchase(plr, content.id)
        end
        effect.beginEffect()]]
    end)

    ms.PromptGamePassPurchaseFinished:Connect(function(player)
        if player ~= plr then
            return
        end

        effect.endEffect()
    end)

    ms.PromptProductPurchaseFinished:Connect(function(id)
        if id ~= plr.UserId then
            return
        end

        effect.endEffect()
    end)
end

return effect