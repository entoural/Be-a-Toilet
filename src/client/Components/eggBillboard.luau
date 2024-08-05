local rs = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local plr = players.LocalPlayer
local infoPack = plr:WaitForChild("InfoPack")
local deployed = infoPack.Deployed
local packages = rs:WaitForChild("Packages")

local bridgeNet = require(packages.BridgeNet2)
local fusion = require(packages.Fusion)
local sift = require(packages.Sift)
local hatchBridge = bridgeNet.ReferenceBridge("hatchEgg")
local new = fusion.New
local children = fusion.Children
local dictionary = sift.Dictionary

local controls
local button
local marketplaceEffect
local billboard
local hatching
local eggOption
local notifs
local shopUI
local inventoryUI
local library

local eggBillboards = {}
eggBillboards.startThread = true
eggBillboards.eggs = {}
eggBillboards.executePriority = 10
eggBillboards.startThread = true

eggBillboards.missingWater = `<stroke color="#000000" thickness="2.5"><b><font color="rgb(255,255,255)">Not enough</font><font color="rgb(116,204,244)"> water!</font></b></stroke>`

local egg = {}
egg.__index = egg

egg.defaultProps = {
	type = "ImageButton",
	onHover = true,
	onClick = true,
	callbacks = {},
	sounds = {click = "rbxassetid://6324790483", hover = "rbxassetid://7218169592", hoverVolume = 0.5, clickVolume = 0.5}
}

function eggBillboards.getEggFromBillboard(billboardObject)
    for i, v in eggBillboards.eggs do
        if v.gui == billboardObject.instance then
            return v
        end
    end
end


function eggBillboards.new(gui, name, countSignal)
    local self = setmetatable({}, egg)

    self.gui = gui
    self.billboard = billboard.new(self.gui, nil, eggBillboards.openedBillboard, function()
        return eggBillboards.requestOpen(self)
    end, self)

    self.gui.Frame.Main.EggName.Text = name
    self.gui.Frame.Main.EggCost.Text = library.eggs[name].cost

    while not library do
        task.wait()
    end

    self.toiletOptions = {}

    local toilets = self.gui.Frame.Main.Toilets
    for i, _ in library.eggs[name].options do
        --[[self.toiletOptions[i] = new "Frame" {
            BackgroundColor3 = Color3.fromRGB(171, 171, 171),
            Size = UDim2.new(1/3, 0, 1/3, 0),
            Name = i,
            Parent = toilets,
            [children] = {
                new "UIAspectRatioConstraint" {
                    AspectRatio = 1
                },
                new "TextLabel" {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    TextScaled = true,
                    FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json	", Enum.FontWeight.Bold),
                    Text = i
                },
                new "UICorner" {
                    CornerRadius = UDim.new(0.2, 0)
                }
            }
        }]]

        local newOption = eggOption.new(i, name)
        newOption.button.Parent = toilets
        self.toiletOptions[i] = newOption
    end

    local function passCallback(passButton)
        if library.ownedPasses[passButton.name][1] then
            return
        end

        marketplaceEffect.promptPurchase("pass", library.passes[passButton.name])
    end

    for _, v in self.gui.Frame.Passes:GetChildren() do
        if not v:IsA("Frame") then
            continue
        end

        button.new(dictionary.merge(self.defaultProps, {instance = v.Buy, callbacks = {click = passCallback}, name = v.Name}))

        if library.ownedPasses[v.Name] and library.ownedPasses[v.Name][1] then
            v.Buy.ImageTransparency = 1
            v.Buy.ImageLabel:Destroy()
            v.Buy.Price.Position = UDim2.new(0.5, 0, 0.5, 0)
            v.Buy.Price.TextXAlignment = Enum.TextXAlignment.Center
            v.Buy.Price.Text = "Owned"
            v.Buy.Price.TextColor3 = Color3.new(0, 0.8, 0.2)
        end

        library.passesChanged:Connect(function(newPasses)
            if newPasses[v.Name][1] then
                v.Buy.ImageTransparency = 1
                v.Buy.ImageLabel:Destroy()
                v.Buy.Price.Position = UDim2.new(0.5, 0, 0.5, 0)
                v.Buy.Price.TextXAlignment = Enum.TextXAlignment.Center
                v.Buy.Price.Text = "Owned"
                v.Buy.Price.TextColor3 = Color3.new(0, 0.8, 0.2) 
            end
        end)
    end

    local function validateActivation()
        return (self.billboard.opened and not inventoryUI.skinsFrame.opened:get())
    end

    local keyTypes = {
        [Enum.KeyCode.E] = "One",
        [Enum.KeyCode.R] = "Three",
        [Enum.KeyCode.T] = "Auto"
    }
    local keyCount = {One = 1, Three = 3, Auto = 1}

    local function activatedCallback(key)
        if not keyTypes[key] then
            return
        end

        if library.eggs[name].type == "Water" and plr.InfoPack.Water.Value < library.eggs[name].cost * keyCount[keyTypes[key]] then
            notifs.sendNotif({duration = 3, text = eggBillboards.missingWater})
            shopUI.openToPage("Water")
            return
        end

        hatchBridge:Fire({type = keyTypes[key], name = name})
    end

    if countSignal then
        self.countLabel = self.gui.Frame.Main.EggCount

        countSignal:Connect(function(newCount)
            self.count = newCount
            self.countLabel.Text = if newCount >= 1 then newCount.."x" else ""
        end)
    end

    controls.bindInputToImageButton(self.gui.Frame.Main.Controls.E.Button, Enum.KeyCode.E, activatedCallback, validateActivation)
    controls.bindInputToImageButton(self.gui.Frame.Main.Controls.R.Button, Enum.KeyCode.R, activatedCallback, validateActivation)
    controls.bindInputToImageButton(self.gui.Frame.Main.Controls.T.Button, Enum.KeyCode.T, activatedCallback, validateActivation)
    table.insert(eggBillboards.eggs, self)
    return self
end

function eggBillboards.requestOpen(eggObject): boolean
    if deployed.Value or hatching.hatchingInProgress then
        return false
    end
    local closest = nil
    for i, v in eggBillboards.eggs do
        if closest == nil then
            closest = v
            continue
        end

        local characterPosition = game.Players.LocalPlayer.Character:GetPivot().Position

        if (characterPosition - v.gui.Adornee.Position).Magnitude <= (characterPosition - closest.gui.Adornee.Position).Magnitude then
            closest = v
        end
    end
    return closest == eggObject
end

function eggBillboards.openedBillboard(wasOpened, eggObject)
    if not wasOpened then
        return
    end

    for i, v in eggBillboards.eggs do
        if v ~= eggObject then
            v.billboard:close(true)
        end
    end
end

function eggBillboards.retrieveDependencies(modules: {})
    billboard = modules.billboard
    --eggOption = modules.eggOption
end

function eggBillboards.start(modules: {})
    button = modules.button
    eggOption = modules.eggOption
    billboard = modules.billboard
    hatching = modules.hatching
    library = modules.library
    controls = modules.controls
    notifs = modules.notifs
    shopUI = modules.shopUI
    marketplaceEffect = modules.marketplaceEffect
    inventoryUI = modules.inventoryUI
end

return eggBillboards