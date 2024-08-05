local players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")

local plr = players.LocalPlayer
local timer = rs:WaitForChild("ResetTime")
local vipCollision = workspace:WaitForChild("VIPCollision")
local playerGui = plr:WaitForChild("PlayerGui")
local timeText = playerGui:WaitForChild("Main"):WaitForChild("Timer")
local billboards = playerGui:WaitForChild("CollectibleBillboards")
local packages = rs:WaitForChild("Packages")
local fusion = require(packages.Fusion)
local library
local burst
local statPopup
local notifs

local new = fusion.New
local children = fusion.Children
local hydrate = fusion.Hydrate
local onChange = fusion.OnChange

local main = {}
main.startThread = true

function format(int)
	return string.format("%02i", int)
end

function convertToMS(seconds)
	local minutes = (seconds - seconds%60)/60
	seconds = seconds - minutes*60
	return format(minutes)..":"..format(seconds)
end

function main.getNearestOfName(name: string)
    local closest = nil
    local closestMagnitude = nil
    local playerPosition = plr.Character:GetPivot().Position

    for _, v in workspace.Collect:GetChildren() do
        local position = if v:IsA("Model") then v:GetPivot().Position else v.Position
        if v.OriginalName.Value == name and (if closest then (playerPosition - position).Magnitude < closestMagnitude else true) and not v.Collected.Value then
            closest = v
            closestMagnitude = (playerPosition - position).Magnitude
        end
    end

    if not closest then
        task.wait(2)
        return main.getNearestOfName(name)
    end

    return closest
end

function main.start(modules)
    library = modules.library
    notifs = modules.notifs
    burst = modules.Components.burst
    statPopup = modules.Components.statPopup

    if library.ownedPasses and library.ownedPasses["VIP"] and library.ownedPasses["VIP"][1] then
        vipCollision.CanCollide = false
    end

    library.passesChanged:Connect(function(newPasses)
        if newPasses["VIP"][1] then
            vipCollision.CanCollide = false
        end
    end)

    for _, v in workspace:WaitForChild("Collect"):GetDescendants() do
        if v:IsA("BasePart") then
            local value = Instance.new("NumberValue")
            value.Name = "OriginalTransparency"
            value.Value = v.Transparency
            value.Parent = v

            v.Anchored = true
        elseif v:IsA("Weld") or v:IsA("WeldConstraint") then
            v:Destroy()
        end
    end

    for _, v in workspace:WaitForChild("Collect"):GetChildren() do
        local x = if v:IsA("BasePart") then math.max(v.Size.X, v.Size.Z) else math.max(v:GetExtentsSize().X, v:GetExtentsSize().Z)

        if v:FindFirstChild("Size") then
            new "BillboardGui" {
                Adornee = v,
                Size = UDim2.new(math.clamp(x, 5, math.huge), 0, math.clamp(x / 3, 3, 10), 0),
                Name = v.Name,
                ResetOnSpawn = false,
                MaxDistance = 140,
                AlwaysOnTop = true,
                Parent = billboards,
                [children] = {
                    new "TextLabel" {
                        Size = UDim2.new(1, 0, 1, 0),
                        TextScaled = true,
                        FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular),
                        BackgroundTransparency = 1,
                        TextColor3 = Color3.new(1, 0, 0),
                        Text = v:FindFirstChild("Size").Value,
                        [children] = {
                            new "UIStroke" {
                                Thickness = 1,
                                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
                            }
                        }
                    }
                }
            }
        end

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

    for _, v in billboards:GetChildren() do
        if not v.Adornee or not v.Adornee:FindFirstChild("Size") then
            continue
        end

        if v.Adornee:FindFirstChild("VIP") then
            v.TextLabel.TextColor3 = Color3.new(1, 1, 0)
            continue
        end

        local size = v.Adornee:FindFirstChild("Size").Value
        if size <= plr.leaderstats.Size.Value then
            v.TextLabel.TextColor3 = Color3.new(0, 1, 0)
        else
            v.TextLabel.TextColor3 = Color3.new(1, 0, 0)
        end
    end

    local lastSize = plr:WaitForChild("leaderstats"):WaitForChild("Size").Value
    hydrate(plr:WaitForChild("leaderstats"):WaitForChild("Size")) {
        [onChange "Value"] = function(playerSize)
            if playerSize > lastSize then
                if main.sizePopup then
                    main.sizePopup:add(playerSize - lastSize)
                else
                    main.sizePopup = statPopup.new("Size", playerSize - lastSize, "📊", function ()
                        main.sizePopup = nil
                    end)
                end
            end
            lastSize = playerSize

            for _, v in billboards:GetChildren() do
                if not v.Adornee or not v.Adornee:FindFirstChild("Size") then
                    continue
                end

                if v.Adornee:FindFirstChild("VIP") then
                    v.TextLabel.TextColor3 = Color3.new(1, 1, 0)
                    continue
                end

                local size = v.Adornee:FindFirstChild("Size").Value
                if size <= playerSize then
                    v.TextLabel.TextColor3 = Color3.new(0, 1, 0)
                else
                    v.TextLabel.TextColor3 = Color3.new(1, 0, 0)
                end
            end
        end
    }

    while task.wait(1) do
        local remainingSeconds = math.clamp(timer.Value - os.time(), 0, 900)
        local completion = math.clamp((900 - remainingSeconds) / 900, 0, 900)
        local nextColor = Color3.new(0, 1, 0):Lerp(Color3.new(1, 0, 0), completion)
        timeText.TextColor3 = nextColor
        timeText.Text = `All players size will reset in {convertToMS(remainingSeconds)}`

        if remainingSeconds < 60 then
            burst.new(timeText)
        end
    end
end

return main