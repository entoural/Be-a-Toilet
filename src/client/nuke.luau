local rs = game:GetService("ReplicatedStorage")
local lighting = game:GetService("Lighting")

local colorCorrection = lighting:WaitForChild("ColorCorrection")
local packages = rs:WaitForChild("Packages")
local bridgeNet = require(packages.BridgeNet2)
local janitor = require(packages.Janitor)

local nukeBridge = bridgeNet.ReferenceBridge("nuke")
local cameraShake
local spring
local notifs

local nuke = {}


function nuke.start(modules)
    cameraShake = modules.cameraShake
    spring = modules.Util.spring
    notifs = modules.notifs

    nukeBridge:Connect(function(content)
        if nuke.janitor then
            nuke.janitor:Destroy()
        end

        local msg = `<stroke color="#FFFFFF" thickness="2.5"><b><font color="rgb(255,0,0)">{content.purchased.Name} has launched a nuke!!</font></b></stroke>`
        notifs.sendNotif({duration = 27.5, text = msg})

        nuke.janitor = janitor.new()

        nuke.janitor:Add(function()
            spring.stop(colorCorrection)
            cameraShake.stopHatch()
            colorCorrection.TintColor = Color3.new(1, 1, 1)
        end)

        spring.target(colorCorrection, 1, 1, {TintColor = Color3.new(1, 0, 0)})

        nuke.janitor:Add(task.spawn(function()
            task.wait(5)
            cameraShake.stopHatch()
            cameraShake.hatchShake()

            task.wait(10)
            cameraShake.startExplosion()

            task.wait(10)

            nuke.janitor:RemoveNoClean("thread")
            nuke.janitor:Destroy()
            nuke.janitor = nil
        end), true, "thread")

    end)
end

return nuke