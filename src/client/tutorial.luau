local runService = game:GetService("RunService")
local soundService = game:GetService("SoundService")
local debris = game:GetService("Debris")
local rs = game:GetService("ReplicatedStorage")
local uis = game:GetService("UserInputService")
local players = game:GetService("Players")

local packages = rs:WaitForChild("Packages")
local bridgeNet = require(packages.BridgeNet2)
local janitor = require(packages.Janitor)
local signal = require(packages.GoodSignal)
local plr = players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local main = playerGui:WaitForChild("Main")
local tutorialText = main:WaitForChild("TutorialText")
local beam = rs:WaitForChild("TutorialBeam")

local collected = bridgeNet.ReferenceBridge("collected")
local hatchedBridge = bridgeNet.ReferenceBridge("hatchedEgg")
local dailyRewards
local mainClient

local tutorialBridge = bridgeNet.ReferenceBridge("Tutorial")

local tutorial = {}

function tutorial.playSound(soundId: number, volume: number?, duration: number?)
	local sound = Instance.new("Sound")
	sound.Parent = soundService
	sound.Volume = volume or 1
	sound.SoundId = soundId
	soundService:PlayLocalSound(sound)
	debris:AddItem(sound, duration or sound.TimeLength)
end

function tutorial.setBeamTarget(instance: Instance | Model)
    beam.Enabled = true
    beam.BeamPart.CFrame = if instance:IsA("Model") then instance:GetPivot() else instance.CFrame
end

function tutorial.removeBeam()
    beam.Enabled = false
end

function tutorial.displayText(text: string)
    tutorialText.Text = ""
    task.wait(0.5)
    tutorialText.Visible = true

    for i = 1, #text, 1 do
		tutorialText.Text = string.sub(text, 1, i)
        if i%20 == 0 then
            tutorial.playSound("rbxassetid://9118041965", 0.5, 0.1)
        end
		runService.Heartbeat:Wait()
	end
end

function tutorial.waitForInput()
    local continueSignal = signal.new()
    tutorial.janitor:Add(uis.InputEnded:Connect(function(input, gpe)
        if gpe then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.Gamepad1 then
            tutorial.janitor:Remove("clickToContinue")
            continueSignal:Fire()
        end
    end), "Disconnect", "clickToContinue")

    continueSignal:Wait()
end

function tutorial.waitForCollection()
    local collectedSignal = signal.new()
    tutorial.janitor:Add(collected:Connect(function(content)
        if content.isLocal then
            tutorial.janitor:Remove("collected")
            collectedSignal:Fire()
        end
    end), "Disconnect", "collected")
    collectedSignal:Wait()
end

function tutorial.beginTutorial()
    beam.Enabled = false
    beam.Parent = workspace
    if plr.Character then
        beam.Attachment0 = plr.Character.HumanoidRootPart.RootAttachment
    end

    tutorial.janitor = janitor.new()
    tutorial.janitor:Add(plr.CharacterAdded:Connect(function(char)
        beam.Attachment0 = char:WaitForChild("HumanoidRootPart").RootAttachment
    end))

    if dailyRewards.dailyFrame and dailyRewards.dailyFrame.opened:get() then
        dailyRewards.dailyFrame:close()
    end
    tutorial.janitor:Add(dailyRewards.dailyFrameOpened:Connect(function(dailyFrame)
        if not dailyFrame.opened:get() then
            return
        end

        dailyFrame:close()
    end), "Disconnect")

    if not plr.Character then
        plr.CharacterAdded:Wait()
    end

    local timeToTween = 15
    tutorial.janitor:Add(runService.RenderStepped:Connect(function()
        local hue = os.clock() % timeToTween / timeToTween
        local color = Color3.fromHSV(hue, 1, 1)

        beam.Color = ColorSequence.new(color, color)
    end))

    tutorial.janitor:Add(plr.Character.Humanoid.Died:Connect(function()
        tutorial.janitor:Destroy()
        tutorial.janitor = nil

        task.spawn(tutorial.beginTutorial)
    end), "Disconnect", "dead")

    tutorial.janitor:Add(task.spawn(function()
        --tutorial.displayText("Welcome to Be a Toilet! (Click anywhere to continue)")
        --tutorial.waitForInput()
        --tutorial.displayText("Walk to the portal to deploy.")
        tutorial.setBeamTarget(workspace.Lobby.Portal)

        if not plr.InfoPack.Deployed.Value then
            plr.InfoPack.Deployed:GetPropertyChangedSignal("Value"):Wait()
        end
        tutorial.removeBeam()
        task.wait(3)

        --tutorial.displayText("Collect this piece of gum on the ground!")
        tutorial.setBeamTarget(mainClient.getNearestOfName("Gum"))

        tutorial.waitForCollection()
        tutorial.removeBeam()

        task.wait(0.5)

        --tutorial.displayText("You have grown by one size! Collect one more piece of gum.")
        tutorial.setBeamTarget(mainClient.getNearestOfName("Gum"))

        tutorial.waitForCollection()

        --tutorial.displayText("You are now large enough to collect cans! Collect one can.")
        tutorial.setBeamTarget(mainClient.getNearestOfName("Can"))

        tutorial.waitForCollection()
        tutorial.removeBeam()
        --tutorial.displayText("Now click return to lobby to continue the tutorial")
        tutorial.janitor:Remove("dead")
        main.Arrows.Return.Visible = true

        plr.Character.Humanoid.Died:Wait()
        main.Arrows.Return.Visible = false
        main.Arrows.Water.Visible = true
        --tutorial.displayText("For each item you collect in the map you gain one water. These can be used to purchase eggs. (Click anywhere to continue)")
        --tutorial.waitForInput()

        main.Arrows.Water.Visible = false
        --tutorial.displayText("Follow the arrow and then activate the `Buy one` button to hatch the egg and receive a toilet.")
        tutorial.setBeamTarget(workspace.Lobby.Eggs:FindFirstChild("City Egg"))
        hatchedBridge:Wait()
        tutorial.removeBeam()

        task.wait(6)

        --tutorial.displayText("You received a new toilet! You are now able to equip this toilet skin and will receive boosts from it while playing. Enjoy the game! (Click anywhere to continue)")
        --tutorial.waitForInput()
        --tutorial.displayText("")
        tutorialBridge:Fire(true)
        tutorial.janitor:Destroy()
    end), true, "thread")

end

function tutorial.start(modules)
    dailyRewards = modules.dailyRewards
    mainClient = modules.mainClient

    tutorialBridge:Once(function(content)
        if content then
            tutorial.beginTutorial()
        end
    end)

    tutorialBridge:Fire()
end

return tutorial