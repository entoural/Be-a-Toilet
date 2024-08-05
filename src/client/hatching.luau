local rs = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local soundService = game:GetService("SoundService")
local debris = game:GetService("Debris")
local lighting = game:GetService("Lighting")
local players = game:GetService("Players")

local plr = players.LocalPlayer
local confetti = rs:WaitForChild("Confetti")
local blur = lighting:WaitForChild("Blur")
local eggs = rs:WaitForChild("Eggs")
local skins = rs:WaitForChild("ToiletSkins")
local packages = rs:WaitForChild("Packages")
local fusion = require(packages.Fusion)
local bridgeNet = require(packages.BridgeNet2)
local janitor = require(packages.Janitor)
local library
local cameraShake
local springUtil

local new = fusion.New
local spring = fusion.Spring
local value = fusion.Value
local tween = fusion.Tween
local computed = fusion.Computed
local observer = fusion.Observer

local hatchBridge = bridgeNet.ReferenceBridge("hatchedEgg")
local hatchedBridge = bridgeNet.ReferenceBridge("hatchedEgg")
local updateInventoryBridge = bridgeNet.ReferenceBridge("updatedInventory")
local sendPlayerNotice = bridgeNet.ReferenceBridge("notice")

local hatching = {}
hatching.hatchingInProgress = false
hatching.currentJanitor = nil
hatching.startThread = true

local function _playLocalSound(soundId, volume)
	local sound = Instance.new("Sound")
	sound.Parent = soundService
	sound.Volume = volume or 1
	sound.SoundId = soundId
	soundService:PlayLocalSound(sound)
	debris:AddItem(sound, sound.TimeLength)
end

local function fitSize(v1: Vector3, v2: Vector3)
    local largestRatio = math.max(v1.X/v2.X, v1.Y/v2.Y, v1.Z/v2.Z)

    return v1 / largestRatio
end

function hatching.hatchEgg(content: {eggName: string, eggCount: number, results: {string}})
    if not library.eggs[content.eggName] or not eggs:FindFirstChild(content.eggName) then
        return
    end

    if hatching.hatchingInProgress and hatching.currentJanitor then
        hatching.currentJanitor:Destroy()
        hatching.currentJanitor = nil
    end

    hatching.hatchingInProgress = true
    hatching.currentJanitor = janitor.new()

    plr.CameraMinZoomDistance = 9
    springUtil.target(blur, 1, 1, {Size = 10})
    springUtil.target(workspace.CurrentCamera, 1, 1, {FieldOfView = 80})
    hatching.currentJanitor:Add(function()
        springUtil.target(blur, 1, 1, {Size = 2.5})
        springUtil.target(workspace.CurrentCamera, 1, 1, {FieldOfView = 70})
        plr.CameraMinZoomDistance = 0.5
    end)

    local eggModels = {}
    for i = 1, content.eggCount do
        local egg = eggs:FindFirstChild(content.eggName):Clone()
        table.insert(eggModels, egg)
        hatching.currentJanitor:Add(egg)
        egg.Parent = workspace
    end

    local cam = workspace.CurrentCamera
    cameraShake.hatchShake()
    hatching.currentJanitor:Add(cameraShake, "stopHatch", "camShake")

    local rotation = value(0)
    local distance = value(-8)
    local camPos = value(cam.CFrame)
    local damp = value(0.2)
    local speed = value(15)
    local animatedRotation = spring(rotation, 15, 0.65)
    local animatedDistance = spring(distance, speed, damp)

    local eCFrame = computed(function()
        return camPos:get() * CFrame.new(0, 0, animatedDistance:get())
    end)

    hatching.currentJanitor:Add(runService.RenderStepped:Connect(function()
        camPos:set(cam.CFrame)

        for i, v in eggModels do
            local offset = i - (#eggModels + 1) / 2
            local angle = CFrame.Angles(0, 0, math.rad(animatedRotation:get()))
            v.CFrame = eCFrame:get() * CFrame.new(offset * 3, 0, 0) * angle
        end
    end), "Disconnect", "Render")

    hatching.currentJanitor:Add(task.spawn(function()
        task.wait(0.25)
        for i = 1, 4 do
            _playLocalSound("rbxassetid://9113251325")
            if i == 1 then
                rotation:set(30)
            else
                rotation:set(-1 * rotation:get())
            end
            distance:set(distance:get() + 1)
            task.wait(0.35)
        end

        local toilets = {}
        for i, v in content.results do
            local toilet = skins:FindFirstChild(v):Clone()
            toilet.Anchored = true
            toilet.CanCollide = false
            toilet.CastShadow = false
            toilet.Parent = workspace

            toilet.Size = fitSize(toilet.Size, eggModels[i].Size * 0.5)
            local offset = i - (#eggModels + 1) / 2
            local angle = CFrame.Angles(0, 0, math.rad(animatedRotation:get()))
            toilet.CFrame = eCFrame:get() * CFrame.new(offset * 3, 0, 0) * angle

            hatching.currentJanitor:Add(toilet)
            table.insert(toilets, toilet)
        end

        springUtil.target(blur, 1, 1, {Size = 2.5})
        hatching.currentJanitor:Remove("camShake")

        local startedRotation = os.clock()
        hatching.currentJanitor:Add(runService.RenderStepped:Connect(function()
            local pos = cam.CFrame
            local c = pos * CFrame.new(0, 0, -4)
            for i, v in toilets do
                local offset = i - (#eggModels + 1) / 2
                v.CFrame = c * CFrame.new(offset * 3, 0, 0) * CFrame.Angles(0, (os.clock()-startedRotation) * 2, 0)
            end
        end), "Disconnect")

        task.wait(0.25)
        rotation:set(0)
        distance:set(-2)
        task.wait(0.1)

        local transparencyValue = value(0)
        local transparency = tween(transparencyValue, TweenInfo.new(1))

        local observe = observer(transparency)
        observe:onChange(function()
            for i, v in eggModels do
                v.Transparency = transparency:get()
            end
        end)

        transparencyValue:set(1)
        for i, v in toilets do
            local newConfetti = confetti:Clone()
            newConfetti.Parent = v
            newConfetti.CFrame = v.CFrame

            new "WeldConstraint" {
                Parent = workspace,
                Part0 = newConfetti,
                Part1 = v
            }

            newConfetti.Anchored = false

            for _, instance in newConfetti:GetChildren() do
                instance.Enabled = true
            end
        end

        task.wait(0.25)
        _playLocalSound("rbxassetid://4612378364")
        for i, v in toilets do
            for _, instance in v.Confetti:GetChildren() do
                instance.Rate = 0
            end
        end

        task.wait(3)

        task.spawn(function()
            hatching.currentJanitor:Destroy()
            hatching.currentJanitor = nil
            hatching.hatchingInProgress = false
        end)
    end))
end

function hatching.start(modules: {ModuleScript})
    library = modules.library
    cameraShake = modules.cameraShake
    springUtil = modules.Util.spring

    hatchBridge:Connect(hatching.hatchEgg)

    --[[task.wait(5)

    local results = {
        "GoldToilet", "GreenToilet", "BlueToilet"
    }
    while true do
        hatching.hatchEgg({eggName = "Egg1", eggCount =  3, results = results})
        repeat task.wait() until not hatching.hatchingInProgress
    end]]
end

return hatching