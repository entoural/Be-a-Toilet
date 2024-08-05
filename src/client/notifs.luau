local players = game:GetService("Players")
local runService = game:GetService("RunService")
local rs = game:GetService("ReplicatedStorage")

local plr = players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local main = playerGui:WaitForChild("Main")
local notifs = main:FindFirstChild("Notifs")
local packages = rs:WaitForChild("Packages")
local bridgeNet = require(packages.BridgeNet2)
local fusion = require(packages.Fusion)

local noticeBridge = bridgeNet.ReferenceBridge("notice")
local New = fusion.New
local Children = fusion.Children
local Tween = fusion.Tween
local Spring = fusion.Spring
local Value = fusion.Value

local lastNotifNum = 0

local notifController = {}
notifController.minNotifsToForce = 6

function notifController.sortLabels()
	if #notifs:GetChildren() <= 1 or not notifs:FindFirstChildWhichIsA("UIListLayout") then
		return
	end

	local children = notifs:GetChildren()
	table.remove(children, table.find(children, notifs:FindFirstChildWhichIsA("UIListLayout")))

	table.sort(children, function(a, b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)

	return children
end

function notifController.sendNotif(props)
	lastNotifNum += 1
	local size = Value(UDim2.new(1, 0, 0.1, 0))
	local notif = New "TextLabel" {
		BackgroundTransparency = 1,
		TextScaled = true,
		Size = Spring(size, 15, 0.5),
		TextColor3 = props.color or Color3.new(1, 1, 1),
		Text = props.text,
		RichText = true,
		Name = lastNotifNum,
		-- FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		[Children] = {
			New "NumberValue" {
				Value = props.duration,
				Name = "Duration"
			},
			New "NumberValue" {
				Value = os.clock(),
				Name = "Created"
			}
		},
		Parent = notifs
	}

	size:set(UDim2.new(1, 0, 0.2, 0), true)

	return notif
end

-- Called after all modules have been initialized and passes the other modules
function notifController.start()

	runService.RenderStepped:Connect(function(dt)
		local sorted = notifController.sortLabels()
		if not sorted then
			return
		end

		if #notifs:GetChildren() < notifController.minNotifsToForce and os.clock() - sorted[1]:FindFirstChild("Created").Value < sorted[1]:FindFirstChild("Duration").Value then
			return
		end

		local nextYSize = math.clamp(sorted[1].Size.Y.Scale - ((#notifs:GetChildren() - 1) * 0.3) * dt, 0, 1)
		sorted[1].Size = UDim2.fromScale(1, nextYSize)
		if nextYSize == 0 then
			sorted[1]:Destroy()
		end
	end)

	noticeBridge:Connect(notifController.sendNotif)
end

return notifController