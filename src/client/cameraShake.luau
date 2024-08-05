local rs = game:GetService("ReplicatedStorage")

local packages = rs:WaitForChild("Packages")
local camera = workspace.CurrentCamera
local camShaker

local cameraShake = {}
cameraShake.executePriority = 3

local function shakeCamera(shakeCf)
	-- shakeCf: CFrame value that represents the offset to apply for shake effect.
	-- Apply the effect:
	workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * shakeCf
end

function cameraShake.hatchShake()
    cameraShake.hatchShaker:ShakeSustain(camShaker.Presets.Earthquake)
end

function cameraShake.stopHatch()
    cameraShake.hatchShaker:StopSustained(2)
end

function cameraShake.startExplosion()
    cameraShake.stopHatch()
    cameraShake.hatchShaker:ShakeSustain(camShaker.Presets.Explosion)
end

function cameraShake.start(modules: {ModuleScript})
    local renderPriority = Enum.RenderPriority.Camera.Value --+ 1
    camShaker = modules.Util.cameraShaker
    cameraShake.hatchShaker = camShaker.new(renderPriority, shakeCamera)
    cameraShake.hatchShaker:Start()
end

return cameraShake