local players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local soundService = game:GetService("SoundService")
local debris = game:GetService("Debris")

local packages = rs:WaitForChild("Packages")
local plr = players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local main = playerGui:WaitForChild("Main")
local bridgeNet = require(packages.BridgeNet2)
local sift = require(packages.Sift)
local fusion = require(packages.Fusion)
local util
local shopUI
local button
local library
local toiletFrame
local marketplaceEffect
local burst
local frame

local updateInventoryBridge = bridgeNet.ReferenceBridge("updatedInventory")
local equippedUpdate = bridgeNet.ReferenceBridge("equippedUpdate")
local dictionary = sift.Dictionary
local hydrate = fusion.Hydrate
local onChange = fusion.OnChange
local value = fusion.Value
local computed = fusion.Computed
local observer = fusion.Observer
local new = fusion.New

local inventoryUI = {}
inventoryUI.startThread = true

inventoryUI.skinsFrame = nil
inventoryUI.selectedToilet = nil
inventoryUI.equippedToilet = nil
inventoryUI.trashButton = nil
inventoryUI.moreInventory = nil
inventoryUI.deleteEnabled = false
inventoryUI.autoDeleteSelection = {}

inventoryUI.defaultProps = {
	type = "ImageButton",
	onHover = true,
	onClick = true,
	callbacks = {},
	sounds = {click = "rbxassetid://18497925021", hover = "rbxassetid://18497999901", hoverVolume = 0.25, clickVolume = 0.5}
}

local function _playLocalSound(soundId, volume)
	local sound = Instance.new("Sound")
	sound.Parent = soundService
	sound.Volume = volume or 1
	sound.SoundId = soundId
	soundService:PlayLocalSound(sound)
	debris:AddItem(sound, sound.TimeLength)
end

function inventoryUI.closeInfo()
    inventoryUI.skinsFrame.instance.InfoFrame.Visible = false
    inventoryUI.skinsFrame.instance.ScrollingFrame.Size = UDim2.new(0.921, 0, 0.873, 0)
end

function inventoryUI.openInfo(toilet)
    local infoFrame = inventoryUI.skinsFrame.instance.InfoFrame

    if #infoFrame.Frame:GetChildren() >= 1 then
        for _, v in infoFrame.Frame:GetChildren() do
            v:Destroy()
        end
    end

    infoFrame.Title.Text = toilet.name
    util.colorText.color(infoFrame.Title, library.toilets[toilet.name].color or Color3.new(1, 1, 1))

    infoFrame.Water.Text = `Water Boost {library.toilets[toilet.name]["waterBoost"]}x`
    infoFrame:FindFirstChild("Size").Text = `Size Boost {library.toilets[toilet.name]["sizeBoost"]}x`
    infoFrame.Speed.Text = `Speed Boost {library.toilets[toilet.name]["speedBoost"]}x`

    if toilet.equipped:get() then
        infoFrame.Equip.Label.Text = "Unequip"
        infoFrame.Equip.Equipped.Enabled = true
        infoFrame.Equip.Unequipped.Enabled = false
    else
        infoFrame.Equip.Label.Text = "Equip"
        infoFrame.Equip.Unequipped.Enabled = true
        infoFrame.Equip.Equipped.Enabled = false
    end

    toilet.frame.ViewportFrame:Clone().Parent = infoFrame.Frame

    inventoryUI.skinsFrame.instance.InfoFrame.Visible = true
    inventoryUI.skinsFrame.instance.ScrollingFrame.Size = UDim2.new(0.921 * 0.6, 0, 0.873, 0)
end

function inventoryUI.toiletSelected(toilet)
    if not inventoryUI.deleteEnabled then
        if inventoryUI.selectedToilet == toilet then
            inventoryUI.selectedToilet = nil
            inventoryUI.closeInfo()
        else
            inventoryUI.selectedToilet = toilet
            inventoryUI.openInfo(toilet)
        end
    else
        local found = table.find(inventoryUI.autoDeleteSelection, toilet.id)

        if found then
            table.remove(inventoryUI.autoDeleteSelection, found)
            toilet:selectDelete(false)
        else
            table.insert(inventoryUI.autoDeleteSelection, toilet.id)
            toilet:selectDelete(true)
        end

        inventoryUI.skinsFrame.instance.Delete.Visible = #inventoryUI.autoDeleteSelection >= 1
    end
end

function inventoryUI.updateInventory(content: {newInventory: {{string}}})
    local inventoryDictionary = {}
    for _, v in content.newInventory do
        inventoryDictionary[v[2]] = v[1]
    end

    local sortArray = {}

    for i, v in inventoryDictionary do
        if not toiletFrame.frames[i] then
            local newFrame = toiletFrame.new(v, i, inventoryUI.toiletSelected)
            newFrame.frame.Parent = inventoryUI.skinsFrame.instance.ScrollingFrame
        end
    end
-- for _, v in game.StarterGui.Main.ShopFrame.Pages.Passes:GetChildren() do v.Circle.Image = "rbxassetid://18759747211"   end
-- game.StarterGui.Main.ShopFrame.Pages.UIPageLayout:JumpToIndex(1)
    for i, v in toiletFrame.frames do
        if not inventoryDictionary[i] then
            v.frame:Destroy()
            toiletFrame.frames[i] = nil
            v = nil
        else
            table.insert(sortArray, v)
        end
    end
    
    table.sort(sortArray, function(a, b)
        return a.waterBoost > b.waterBoost
    end)

    for i, v in sortArray do
        v.frame.LayoutOrder = i
        if v.frame:FindFirstChild("Order") then
            v.frame:FindFirstChild("Order"):Destroy()
        end

        new "IntValue" {
            Name = "Order",
            Value = i,
            Parent = v.frame
        }
    end

    inventoryUI.updateInventoryCount()
end

function inventoryUI.equippedUpdate(content: {{string}})
    inventoryUI.equippedToilet = if content[1] then content[1][1] else nil
    for i, v in toiletFrame.frames do
        if content[1] and content[1][2] == v.id then
            v:equip()

            if v == inventoryUI.selectedToilet then
                inventoryUI.skinsFrame.instance.InfoFrame.Equip.Label.Text = "Unequip"
                inventoryUI.skinsFrame.instance.InfoFrame.Equip.Equipped.Enabled = true
                inventoryUI.skinsFrame.instance.InfoFrame.Equip.Unequipped.Enabled = false
            end
        elseif v.equipped:get() then
            v:unequip()

            if inventoryUI.selectedToilet and v == inventoryUI.selectedToilet then
                inventoryUI.openInfo(v)
            end
        end
    end
end

function inventoryUI.updateInventoryCount()
    local max = 50
    local owned = false
    if library.ownedPasses["Extra Inventory"] and library.ownedPasses["Extra Inventory"][1] then
        max = 200
        owned = true
    end

    local count = 0
    for _, _ in toiletFrame.frames do
        count += 1
    end

    inventoryUI.skinsFrame.instance.Count.Text = `{count} / {max}`
    if inventoryUI.moreInventory and owned then
        inventoryUI.moreInventory.button:Destroy()
        inventoryUI.moreInventory = nil
    end
end

function inventoryUI.trashClicked()
    if not inventoryUI.deleteEnabled then
        for _, v in toiletFrame.frames do
            if v.equipped:get() then
                v:unequip()
                updateInventoryBridge:Fire({id = ""})
            end
        end

        inventoryUI.closeInfo()
        inventoryUI.deleteEnabled = true
        inventoryUI.trashButton.button.ImageColor3 = Color3.new(1, 0, 0)
    else
        inventoryUI.deleteEnabled = false
        inventoryUI.trashButton.button.ImageColor3 = Color3.new(1, 1, 1)
        inventoryUI.skinsFrame.instance.Delete.Visible = false

        for _, v in toiletFrame.frames do
            if table.find(inventoryUI.autoDeleteSelection, v.id) then
               v:selectDelete(false)
            end
        end

        inventoryUI.autoDeleteSelection = {}
    end
end

function inventoryUI.equipClicked()
    if not inventoryUI.selectedToilet then
        return
    end

    if inventoryUI.selectedToilet.equipped:get() then
        updateInventoryBridge:Fire({id = ""})
    else
        updateInventoryBridge:Fire({id = inventoryUI.selectedToilet.id})
    end
end

function inventoryUI.deleteClicked()
    if not inventoryUI.deleteEnabled or #inventoryUI.autoDeleteSelection == 0 then
        return
    end

    updateInventoryBridge:Fire({deleteList = inventoryUI.autoDeleteSelection})
    inventoryUI.trashClicked()
end

function inventoryUI.skinsFrameUpdate(wasOpened)
    if not wasOpened and inventoryUI.deleteEnabled then
        inventoryUI.trashClicked()
    end
end

function inventoryUI.start(modules)
    frame = modules["Components"].frame
    button = modules["Components"].button
    toiletFrame = modules["Components"].toiletFrame
    burst = modules["Components"].burst
    library = modules.library
    util = modules.Util
    marketplaceEffect = modules.marketplaceEffect
    shopUI = modules.shopUI

    inventoryUI.studioTestSize = Vector2.new(1542, 620)
    inventoryUI.viewportSize = workspace.CurrentCamera.ViewportSize
    inventoryUI.ratio = inventoryUI.viewportSize.X / inventoryUI.studioTestSize.X
    inventoryUI.viewportSize = value(workspace.CurrentCamera.ViewportSize)

    inventoryUI.ratio = computed(function()
        return inventoryUI.viewportSize:get().X / inventoryUI.studioTestSize.X
    end)
    inventoryUI.viewportObserver = observer(inventoryUI.viewportSize)


    main.Water.Count.Text = plr:WaitForChild("InfoPack").Water.Value
    hydrate(plr:WaitForChild("InfoPack").Water) {
        [onChange "Value"] = function(newWater)
            main.Water.Count.Text = newWater
            burst.new(main.Water)
        end
    }

    button.new(dictionary.merge(inventoryUI.defaultProps, {instance = main.Water.Add, callbacks = {click = function()
        shopUI.openToPage("Water")
    end}}))

    inventoryUI.skinsFrame = frame.new(main.SkinsFrame, inventoryUI.skinsFrameUpdate)
    function inventoryUI.openSkins()
        if inventoryUI.skinsFrame.opened:get() then
            inventoryUI.skinsFrame:close()
        else
            inventoryUI.skinsFrame:open()
        end
    end
    button.new(dictionary.merge(inventoryUI.defaultProps, {instance = main.SkinsOpen, callbacks = {click = inventoryUI.openSkins}}))
    button.new(dictionary.merge(inventoryUI.defaultProps, {instance = main.SkinsFrame.InfoFrame.Equip, callbacks = {click = inventoryUI.equipClicked}}))
    button.new(dictionary.merge(inventoryUI.defaultProps, {instance = main.SkinsFrame.Delete, callbacks = {click = inventoryUI.deleteClicked}}))
    inventoryUI.trashButton = button.new(dictionary.merge(inventoryUI.defaultProps, {instance = main.SkinsFrame.Trash, callbacks = {click = inventoryUI.trashClicked}}))

    local function moreInventory()
        marketplaceEffect.promptPurchase("pass", library.passes["Extra Inventory"])
    end

    inventoryUI.moreInventory = button.new(dictionary.merge(inventoryUI.defaultProps, {instance = main.SkinsFrame.MoreSpace, callbacks = {click = moreInventory}}))

    updateInventoryBridge:Connect(inventoryUI.updateInventory)
    equippedUpdate:Connect(inventoryUI.equippedUpdate)

    local padding = 10 * inventoryUI.ratio:get()
    local canvas = inventoryUI.skinsFrame.instance.ScrollingFrame
    canvas.UIPadding.PaddingLeft = UDim.new(0, padding)
    canvas.UIPadding.PaddingTop = UDim.new(0, padding)

    canvas.UIGridLayout.CellPadding = UDim2.new(0, padding, 0, padding)
    canvas.UIGridLayout.CellSize = UDim2.new(0, 90 * inventoryUI.ratio:get(), 0, 90 * inventoryUI.ratio:get())

    hydrate(workspace.CurrentCamera) {
        [onChange "ViewportSize"] = function(newSize)
            inventoryUI.viewportSize:set(newSize)
        end
    }

    inventoryUI.viewportObserver:onChange(function()
        padding = 10 * inventoryUI.ratio:get()
        canvas.UIPadding.PaddingLeft = UDim.new(0, padding)
        canvas.UIPadding.PaddingTop = UDim.new(0, padding)
        inventoryUI.skinsFrame.instance.ScrollingFrame.UIGridLayout.CellPadding = UDim2.new(0, padding, 0, padding)
        inventoryUI.skinsFrame.instance.ScrollingFrame.UIGridLayout.CellSize = UDim2.new(0, 90 * inventoryUI.ratio:get(), 0, 90 * inventoryUI.ratio:get())
    end)

    updateInventoryBridge:Fire()
end

return inventoryUI