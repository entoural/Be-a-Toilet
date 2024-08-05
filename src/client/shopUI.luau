local players = game:GetService("Players")
local rs = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local soundService = game:GetService("SoundService")
local debris = game:GetService("Debris")

local packages = rs:WaitForChild("Packages")
local plr = players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local main = playerGui:WaitForChild("Main")
local bridgeNet = require(packages.BridgeNet2)
local sift = require(packages.Sift)
local fusion = require(packages.Fusion)
local button
local productButton
local giftFrame
local library
local marketplaceEffect
local frame

local giftBridge = bridgeNet.ReferenceBridge("giftUpdate")
local dictionary = sift.Dictionary
local hydrate = fusion.Hydrate
local onChange = fusion.OnChange
local spring = fusion.Spring
local value = fusion.Value
local computed = fusion.Computed
local observer = fusion.Observer
local new = fusion.New

local shop = {}
shop.startThread = true

shop.defaultProps = {
	type = "ImageButton",
	onHover = true,
	onClick = true,
	callbacks = {},
	sounds = {click = "rbxassetid://6324790483", hover = "rbxassetid://7218169592", hoverVolume = 0.5, clickVolume = 0.5}
}

shop.typeLibraryNames = {pass = "passes", devProduct = "devProducts"}
shop.selectedGift = nil

shop.selectedPageButton = "rbxassetid://18338815425"
shop.defaultPageButton = "rbxassetid://18338790877"

function shop.openShop()
    if shop.shopFrame.opened:get() then
        shop.shopFrame:close()
    else
        shop.shopFrame:open()
    end
end

function shop.shopFrameUpdate()
    if not shop.shopFrame.opened:get() and shop.giftFrame.Visible then
        shop.closeGiftFrame()
    end
end

function shop.productButtonClicked(product, isGift)
    local name = product.instance.Name
    local id = library[shop.typeLibraryNames[product.type]][name]
    if not id then
        return
    end

    if not isGift then
        if product.type == "devProduct" then
            marketplaceEffect.promptPurchase("devProduct", id)
        elseif product.type == "pass" and not library.ownedPasses[name][1] then
            marketplaceEffect.promptPurchase("pass", id)
        end
    else
        shop.selectedGift = product
        shop.giftFrameSize:set(shop.originalGiftSize)
        shop.giftFrame.Visible = true
        shop.giftFrame.TextLabel.Text = "Gift "..name
        shop.giftFrame.Scrolling.Visible = false
        task.wait(0.1)
        shop.giftFrame.Scrolling.Visible = true
    end
end

function shop.playerJoined(player)
    local newFrame = giftFrame.new(player, shop.giftClicked)
    newFrame.frame.Parent = shop.giftFrame.Scrolling
end

function shop.playerLeft(player)
    if shop.giftFrame.Scrolling:FindFirstChild(player.Name) then
        shop.giftFrame.Scrolling:FindFirstChild(player.Name):Destroy()
    end
end

function shop.closeGiftFrame()
    shop.giftFrameSize:set(UDim2.new(0, 0, 0, 0))
    shop.selectedGift = nil
    shop.giftFrame.Scrolling.Visible = false
    task.wait(0.5)
    shop.giftFrame.TextLabel.Text = "Gift"
    shop.giftFrame.Visible = false
end

function shop.giftClicked(gift)
    if not shop.selectedGift then
        return
    end

    local name = if typeof(shop.selectedGift) == "string" then shop.selectedGift else shop.selectedGift.instance.Name
    local productType = if typeof(shop.selectedGift) == "string" then "devProduct" else shop.selectedGift.type

    local content = {type = productType, name = name, target = gift.player.Name}
    giftBridge:Fire(content)
end

function shop.specialEgg(eggFrame)
    local giftEnabled = value(false)
    local giftButton

    local giftObserver = observer(giftEnabled)
    giftObserver:onChange(function()
        if not giftEnabled:get() then
            shop.closeGiftFrame()
        end
    end)

    local function giftClicked()
        giftEnabled:set(not giftEnabled:get())

        if giftEnabled:get() then
          giftButton.instance.ImageColor3 = Color3.new(0, 1, 0)
        else
            giftButton.instance.ImageColor3 = Color3.new(1, 1, 1)
        end
    end

    giftButton = button.new(dictionary.merge(shop.defaultProps, {instance = eggFrame.Gift, callbacks = {click = giftClicked}, multis = {hover = 1.05, click = 0.95}}))

    local function buyClicked(quantity)
        local name = quantity.." "..eggFrame.Name
        local id = library.devProducts[name]
        if not id then
            return
        end

        if giftEnabled:get() then
            shop.selectedGift = name
            shop.giftFrameSize:set(shop.originalGiftSize)
            shop.giftFrame.Visible = true
            shop.giftFrame.TextLabel.Text = "Gift "..name
            shop.giftFrame.Scrolling.Visible = false
            task.wait(0.1)
            shop.giftFrame.Scrolling.Visible = true
        else
            marketplaceEffect.promptPurchase("devProduct", id)
        end
    end

    local qtyNames = {"x1", "x10", "x3"}

    for _, v in qtyNames do
        local instance = eggFrame:FindFirstChild(v)

        button.new(dictionary.merge(shop.defaultProps, {instance = instance, callbacks = {click = function ()
            buyClicked(v)
        end}, multis = {hover = 1.05, click = 0.95}}))
    end
end

function shop.updatePasses(passes)
    for i, v in passes do
        local passButton = main.ShopFrame.Pages.Passes:FindFirstChild(i)
        if passButton and v[1] then
            passButton.Buy.ImageLabel.Visible = false
            passButton.Buy.Price.Text = "Owned"
            passButton.Buy.Price.Position = UDim2.new(0.5, 0, 0.5, 0)
            passButton.Buy.Price.TextXAlignment = Enum.TextXAlignment.Center
        end
    end
end

function shop.pageButtonClicked(pageButton)
    for i, v in shop.pageButtons do
        if v == pageButton then
            v.instance.Image = shop.selectedPageButton
        else
            v.instance.Image = shop.defaultPageButton
        end
    end

    main.ShopFrame.Pages.UIPageLayout:JumpTo(main.ShopFrame.Pages:FindFirstChild(pageButton.page))
end

function shop.openToPage(page)
    shop.shopFrame:open()

    task.wait(0.25)

    for i, v in shop.pageButtons do
        if v.page == page then
            v.instance.Image = shop.selectedPageButton
        else
            v.instance.Image = shop.defaultPageButton
        end
    end

    main.ShopFrame.Pages.UIPageLayout:JumpTo(main.ShopFrame.Pages:FindFirstChild(page))
end

function shop.start(modules)
    frame = modules["Components"].frame
    button = modules["Components"].button
    giftFrame = modules["Components"].giftFrame
    productButton = modules["Components"].productButton
    marketplaceEffect = modules.marketplaceEffect
    library = modules.library

    if not frame.loadingFinished then
        frame.loaded:Wait()
    end

    shop.giftFrame = main.ShopFrame.GiftFrame
    shop.giftFrame.Visible = false
    shop.giftFrame.Scrolling.Visible = false
    shop.originalGiftSize = shop.giftFrame.Size
    button.new(dictionary.merge(shop.defaultProps, {instance = shop.giftFrame.Close, callbacks = {click = shop.closeGiftFrame}}))

    shop.giftFrameSize = value(UDim2.new(0, 0, 0, 0))
    hydrate(shop.giftFrame) {
        Size = spring(shop.giftFrameSize, 25, 0.8)
    }

    shop.shopFrame = frame.new(main.ShopFrame, shop.shopFrameUpdate)
    button.new(dictionary.merge(shop.defaultProps, {instance = main.ShopOpen, callbacks = {click = shop.openShop}}))

    shop.pageButtons = {}

    for i, v in main.ShopFrame.Buttons:GetChildren() do
        if not v:IsA("ImageButton") then
            continue
        end

        table.insert(shop.pageButtons, button.new(dictionary.merge(shop.defaultProps, {instance = v, callbacks = {click = shop.pageButtonClicked}, page = v.Name})))
    end

    for i, v in main.ShopFrame.Pages.Water:GetChildren() do
        if not v:IsA("ImageButton") then
            continue
        end

        productButton.new(v, "devProduct", shop.productButtonClicked)
    end

    for i, v in main.ShopFrame.Pages.Passes:GetChildren() do
        if not v:IsA("ImageButton") then
            continue
        end

        productButton.new(v, "pass", shop.productButtonClicked)
    end

    players.PlayerAdded:Connect(shop.playerJoined)
    players.PlayerRemoving:Connect(shop.playerLeft)

    for i, v in players:GetPlayers() do
        if v == plr then
            continue
        end

        local newFrame = giftFrame.new(v, shop.giftClicked)
        newFrame.frame.Parent = shop.giftFrame.Scrolling
    end

    giftBridge:Connect(function(content)
        if content.success then
            marketplaceEffect.promptPurchase("devProduct", content.id)
        end
    end)

    local lastRan = os.clock()
    runService.Heartbeat:Connect(function()
        if os.clock() - lastRan < 3 then
            return
        end

        for _, v in shop.giftFrame:GetChildren() do
            if not v:IsA("Frame") then
                continue
            end

            if not players:FindFirstChild(v.Name) then
                v:Destroy()
            end
        end
    end)

    for i, v in main.ShopFrame.Pages.Eggs:GetChildren() do
        if not v:IsA("Frame") then
            continue
        end

        shop.specialEgg(v)
    end

    --[[local count = 1
    for i, v in game.StarterGui.Main.DailyFrame.ScrollingFrame:GetChildren() do
        if not v:IsA("Frame") then
            continue
        end

        v.Name = count
        v.Day.Text = "Day "..count
        v.LayoutOrder = count
        v.Cash.Text = math.round((50 * count) ^ (1 + count / 30))

        count += 1
    end]]
end

return shop