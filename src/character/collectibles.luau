local runService = game:GetService("RunService")
local rs = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local plr = players.LocalPlayer
local packages = rs:WaitForChild("Packages")
local bridgeNet = require(packages.BridgeNet2)
local toilet = rs:WaitForChild("Toilet")

local collected = bridgeNet.ReferenceBridge("collected")
local collect = bridgeNet.ReferenceBridge("collect")
local killBridge = bridgeNet.ReferenceBridge("killPlayer")

local collectibles = {}

function lerp(a, b, c)
	return a + (b - a) * c
end

function quadBezier(t, p0, p1, p2)
	local l1 = lerp(p0, p1, t)
	local l2 = lerp(p1, p2, t)
	local quad = lerp(l1, l2, t)
	return quad
end

function getMultiFromSize(size)
    return size ^ (1 / 7)
end

function getMidPointWithHeight(v1, v2)
    local newX = math.clamp((v2 - v1).X, -10, 10)
    local newZ = math.clamp((v2 - v1).Z, -10, 10)
    local newV = v1 + Vector3.new(newX, getMultiFromSize(plr.leaderstats.Size.Value) * 6, newZ)

    return newV
end

function collectibles.sizeToMulti(size)
    return size ^ (1 / 7)
end

function collectibles.getSizedToilet(size)
    local defaultSize = toilet.Size

    return defaultSize * collectibles.sizeToMulti(size)
end


function collectibles.start(modules: {})

    for i, v in workspace:WaitForChild("Collect"):GetDescendants() do
        if not v:IsA("BasePart") then
            continue
        end

        local value = Instance.new("NumberValue")
        value.Name = "OriginalTransparency"
        value.Value = v.Transparency
        value.Parent = v
    end

    for i, v in workspace:WaitForChild("Collect"):GetChildren() do
        if not v.Collected.Value then
            continue
        end

        if v:IsA("BasePart") then
            v.Transparency = 1
        end

        for _, instance in v:GetDescendants() do
            if not instance:IsA("BasePart") then
                continue
            end
            instance.Transparency = 1
        end
    end

    local function sizeToMulti(size)
        return size ^ (1 / 7)
    end

    local function isInRange(collectible)
        local range = plr.Character:GetExtentsSize().Y * 0.6 + (sizeToMulti(plr.leaderstats.Size.Value) * 2)
        local objectPosition = if collectible:IsA("BasePart") then collectible.Position else collectible:GetPivot().Position
        if (plr.Character:GetPivot().Position - objectPosition).Magnitude <= range then
            return true
        end
    end

    runService.Heartbeat:Connect(function()
        if not plr.Character then
            return
        end

        for _, v in workspace:WaitForChild("Collect"):GetChildren() do
            if v.Collected.Value then
                continue
            end

            local condition = isInRange(v)

            if condition then
                collect:Fire({name = v.Name})
            end
        end

        for _, v in players:GetPlayers() do
            if v == plr or not v.Character or not v:WaitForChild("InfoPack").Deployed.Value then
                continue
            end

            local xDist = math.abs((plr.Character:GetPivot().Position - v.Character:GetPivot().Position).X)
            local zDist = math.abs((plr.Character:GetPivot().Position - v.Character:GetPivot().Position).Z)
            local sized = collectibles.getSizedToilet(plr.leaderstats.Size.Value)

            if xDist < sized.X * 1.3 and zDist < sized.X and v.leaderstats.Size.Value < plr.leaderstats.Size.Value then
                killBridge:Fire(v)
            end
        end
    end)

    collected:Connect(function(content)
        if not content.isLocal then
            local instance = workspace:WaitForChild("Collect"):FindFirstChild(content.name)
            if instance:IsA("BasePart") then
                if content.isCollected then
                    instance.Transparency = 1
                else
                    instance.Transparency = instance.OriginalTransparency.Value
                end
            end

            for i, v in instance:GetDescendants() do
                if not v:IsA("BasePart") then
                    continue
                end

                if content.isCollected then
                    v.Transparency = 1
                else
                    v.Transparency = v.OriginalTransparency.Value
                end
            end
        else
            local instance = workspace:WaitForChild("Collect"):FindFirstChild(content.name)
            local clone = instance:Clone()
            clone.Parent = workspace

            if instance:IsA("BasePart") then
                if content.isCollected then
                    instance.Transparency = 1
                else
                    instance.Transparency = instance.OriginalTransparency.Value
                end
            end

            for i, v in instance:GetDescendants() do
                if not v:IsA("BasePart") then
                    continue
                end

                if content.isCollected then
                    v.Transparency = 1
                else
                    v.Transparency = v.OriginalTransparency.Value
                end
            end

            local rigged = nil
            if clone:IsA("BasePart") then
                rigged = clone
            else
                local newPart = Instance.new("Part")
                newPart.Name = "Rigged"
                newPart.Size = Vector3.new(0.5, 0.5, 0.5)
                newPart.CanCollide = false
                newPart.Anchored = true
                newPart.Transparency = 1
                newPart.Position = clone:GetPivot().Position
                newPart.Parent = clone

                for i, v in clone:GetDescendants() do
                    if not v:IsA("BasePart") or v.Name == "Rigged" then
                        continue
                    end

                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = v
                    weld.Part1 = newPart
                    weld.Parent = v
                    v.Anchored = false
                    v.CanCollide = false
                end
                rigged = newPart
            end

            local origPos = rigged.Position
            local mid = getMidPointWithHeight(origPos, plr.Character.Toilet.Attachment.WorldCFrame.Position)
            local totalTweenTime = 0.5
            local position = 0
            local started = os.clock()
            local heartbeat
            local spinHeartbeat

            local a1 = Instance.new("Attachment")
            local a2 = Instance.new("Attachment")
            a1.CFrame = CFrame.new(0, 1, 0)
            a2.CFrame = CFrame.new(0, -1, 0)
            a1.Parent = rigged
            a2.Parent = rigged

            local trail =  Instance.new("Trail")
            trail.Lifetime = 1.5
            trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(1, 0.75)})
            trail.Attachment0 = a1
            trail.Attachment1 = a2
            trail.Parent = rigged

            local function beginSpinning()
                trail.Enabled = false
                local axis = Vector3.new(math.random(), math.random(), math.random())
                spinHeartbeat = runService.Heartbeat:Connect(function()
                    rigged.CFrame *= CFrame.Angles(math.rad(1 * axis.X) * 3, math.rad(1 * axis.Y) * 3, math.rad(1 * axis.Z) * 3)
                end)
            end

            heartbeat = runService.Heartbeat:Connect(function()
                position = math.clamp(os.clock() - started, 0, totalTweenTime) / totalTweenTime
                if position == 1 and not spinHeartbeat then
                    beginSpinning()
                end
                local X, Y, Z = rigged.CFrame:ToOrientation()
                rigged.CFrame = CFrame.new(quadBezier(position, origPos, mid, plr.Character.Toilet.Attachment.WorldCFrame.Position)) * CFrame.Angles(X, Y, Z)
            end)

            local deathHeartbeat = plr.Character.Humanoid.Died:Connect(function()
                if heartbeat then
                    heartbeat:Disconnect()
                end
                if spinHeartbeat then
                    spinHeartbeat:Disconnect()
                end
            end)

            task.wait(totalTweenTime * 6)
            if heartbeat then
                heartbeat:Disconnect()
            end
            if spinHeartbeat then
                spinHeartbeat:Disconnect()
            end
            if deathHeartbeat then
                deathHeartbeat:Disconnect()
            end

            clone:Destroy()
        end
    end)

    killBridge:Connect(function(content)
        print("Received", content)
        if content.killed == plr then
            task.spawn(function()
                workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
                plr.CharacterAdded:Wait()
                workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
            end)
        end

        if content.killed.Character.HumanoidRootPart:FindFirstChild("NameTag") then
            content.killed.Character.HumanoidRootPart.NameTag:Destroy()
        end

        local started = os.clock()
        local totalTime = 1
        local startedCFrame = content.killed.Character:GetPivot()

        local connection
        connection = runService.Heartbeat:Connect(function()
            if not content.killed or not content.killedBy or not content.killed.Character or not content.killedBy.Character or content.killed.Character.Humanoid.Health == 0 then
                connection:Disconnect()
                connection = nil
                return
            end

            local progress = math.clamp((os.clock() - started) / totalTime, 0, 1)

            local hum = content.killed.Character.Humanoid
            local scale = 0.5 * getMultiFromSize(content.killed.leaderstats.Size.Value)
            hum:FindFirstChild("HeadScale").Value = scale
            hum:FindFirstChild("BodyDepthScale").Value = scale
            hum:FindFirstChild("BodyWidthScale").Value = scale
            hum:FindFirstChild("BodyHeightScale").Value = scale

            content.killed.Character:PivotTo(startedCFrame:lerp(content.killedBy.Character.Toilet.Attachment.WorldCFrame, progress))
        end)

        content.killed.Character.Humanoid.Died:Once(function()
            if not connection then
                return
            end

            connection:Disconnect()
        end)
    end)
end

return collectibles