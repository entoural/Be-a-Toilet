local soundService = game:GetService("SoundService")
local runService = game:GetService("RunService")
local debris = game:GetService("Debris")
local rs = game:GetService("ReplicatedStorage")

local janitor = require(rs:WaitForChild("Packages").Janitor)

local generalUtil = {}

function generalUtil.moveTo(humanoid, targetPoint, validate, andThen)
	local targetReached = false

	local connection
	connection = humanoid.MoveToFinished:Connect(function(reached)
		if validate and not validate() then
			return
		end
		targetReached = true
		connection:Disconnect()
		connection = nil
		if andThen then
			andThen(reached)
		end
	end)

	humanoid:MoveTo(targetPoint)

	task.spawn(function()
		while not targetReached do
			if not (humanoid and humanoid.Parent) then
				break
			end
			if humanoid.WalkToPoint ~= targetPoint then
				break
			end

			if validate and not validate() then
				task.wait(0.25)
				continue
			end

			humanoid:MoveTo(targetPoint)
			task.wait(6)
		end

		if connection then
			connection:Disconnect()
			connection = nil
		end
	end)
end

function generalUtil.followNoPathfinding(model, endSignal, validate) -- Validate is an optional function passed to check whether the NPC should be moving or not
	local plr = game.Players.LocalPlayer
	if not plr.Character then
		return
	end

	local followJanitor = janitor.new()

	local root = game.Players.LocalPlayer.Character.HumanoidRootPart
	local rigHuman = model:FindFirstChild("Humanoid")
	local rigTorso = model:FindFirstChild("LowerTorso")

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclusions = {model, plr.Character}
	for i, v in workspace:GetChildren() do
		if not v:IsA("BasePart") then
			continue
		end
		if v.CollisionGroup ~= root.CollisionGroup or v.CanCollide == false then
			table.insert(exclusions, v)
		end
	end
	params.FilterDescendantsInstances = exclusions

	followJanitor:Add(runService.Heartbeat:Connect(function()
		if validate and not validate() then
			return
		end
		--[[local direction = (root.Position - rigTorso.Position)
		local raycast = workspace:Raycast(rigTorso.Position, direction, params)
		if raycast and raycast.Instance then
            rigHuman.Jump = true
        end]]
		rigHuman:MoveTo(root.Position)
	end), "Disconnect")

	followJanitor:Add(endSignal:Connect(followJanitor.Destroy, followJanitor), "Disconnect")
	followJanitor:Add(rigHuman.Died:Connect(function()
		followJanitor:Destroy()
	end), "Disconnect")
end

 function generalUtil.playLocalSound(soundId, volume)
	local sound = Instance.new("Sound")
	sound.Parent = soundService
	sound.Volume = volume or 1
	sound.SoundId = soundId
	soundService:PlayLocalSound(sound)
	debris:AddItem(sound, sound.TimeLength)
end

return generalUtil