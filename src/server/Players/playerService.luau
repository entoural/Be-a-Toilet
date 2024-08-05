-- Services
local players = game:GetService("Players")
local ms = game:GetService("MarketplaceService")
local rs = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local ss = game:GetService("ServerStorage")
local badgeService = game:GetService("BadgeService")

local dataService
local library
local monetization
local main

local packages = rs:WaitForChild("Packages")
local sift = require(packages.Sift)
local array = sift.Array
local bridgeNet = require(packages.BridgeNet2)
local updateInventoryBridge = bridgeNet.ReferenceBridge("updatedInventory")
local equippedUpdate = bridgeNet.ReferenceBridge("equippedUpdate")
local tutorialBridge = bridgeNet.ReferenceBridge("Tutorial")
local rewardsBridge = bridgeNet.ReferenceBridge("rewards")
local passesBridge = bridgeNet.ReferenceBridge("passesUpdate")
local signal = require(packages.GoodSignal)
local fusion = require(packages.Fusion)

local Value = fusion.Value
local New = fusion.New
local Observer = fusion.Observer
local Children = fusion.Children
local OnChange = fusion.OnChange

-- Service
local playerService = {}
playerService.players = {}
playerService.playerJoined = signal.new()
playerService.playerLeft = signal.new()

function format(int)
	return string.format("%02i", int)
end

function convertToHMS(seconds)
	local minutes = (seconds - seconds%60)/60
	seconds = seconds - minutes*60
	local hours = (minutes - minutes%60)/60
	minutes = minutes - hours*60
	return format(hours)..":"..format(minutes)..":"..format(seconds)
end

-- Player Object --
local player = {}
player.__index = player

function player.new(plr: Player)
	local self = setmetatable({}, player)
	self.player = plr
	self.id = self.player.UserId

	self.profile = dataService.retrieveProfile(plr)
	self.data = self.profile.Data

	self.data.Logins += 1

	self.character = plr.Character or nil
	self.characterPropertyConnection = nil
	self.diedConnection = nil
	self.lastSize = Value(1)
	self.lastKilledBy = Value(nil)
	self.deployedToilet = nil
	self.equipped = nil
	self.tutorialCompleted = self.data.Logins > 1
	self.joined = os.time()
	self.ownedPasses = {}
	self.autoDelete = {}
	self.claimedRewards = {}
	self.autoHatching = Value(nil)
	self.lastHatched = Value(0)
    self.deployed = Value(false)
    self.shielded = Value(false)
	self.giftTarget = Value(nil)
	self.beingKilled = Value(false)

	self.characterAdded = signal.new()

	local leaderstats = New "Folder" {
		Name = "leaderstats",
		Parent = plr
	}

	self.size = New "IntValue" {
		Name = "Size",
		Value = 1,
		Parent = leaderstats
	}

	self.kills = New "IntValue" {
		Name = "Kills",
		Value = 0,
		Parent = leaderstats
	}

	self.timeSurvived = New "StringValue" {
		Name = "Time",
		Value = "N/A",
		Parent = leaderstats
	}

	self.infoPack = New "Folder" {
		Name = "InfoPack",
		[Children] = {
			New "IntValue" {
				Value = self.data.Water,
				Name = "Water"
			},
			New "BoolValue" {
				Value = false,
				Name = "Deployed"
			},
			New "IntValue" {
				Value = 0,
				Name = "Kills",

				[OnChange "Value"] = function(newValue)
					self.kills.Value = newValue
				end
			},
			New "IntValue" {
				Value = 0,
				Name = "TimeSurvived",

				[OnChange "Value"] = function(newValue)
					--self.timeSurvived.Value = convertToHMS(newValue)
					self.timeSurvived.Value = newValue
				end
			}
		},
		Parent = plr
	}

	for _, v in playerService.players do
		if self.player:IsFriendsWith(v.id) and not table.find(v.data.FriendsJoined, self.id) then
			table.insert(v.data.FriendsJoined, self.id)
			rewardsBridge:Fire(v.player, {friends =  v.data.FriendsJoined, claimed = v.data.RewardsClaimed})
		end
	end

	self.equipped = if self.data.EquippedId and self.data.EquippedId[1] then self.data.EquippedId[1] else "Default"

	for i, _ in library.passes do
		self.ownedPasses[i] = {false, "Unowned"}
	end

	for i, v in self.data.OwnedPasses do
		self.ownedPasses[i] = v
	end

	task.spawn(monetization.checkPasses, self)

	pcall(function()
		badgeService:AwardBadge(self.id, 321550957376207)
	end)

	plr.CharacterAdded:Connect(function(char)
		self.hasBeenTeleported = true
		self.beingKilled:set(false)

		if self.characterPropertyConnection ~= nil then
			self.characterPropertyConnection:Disconnect()
		end
		if self.diedConnection then
			self.diedConnection:Disconnect()
		end

		self.diedConnection = char:WaitForChild("Humanoid").Died:Connect(function()
			self.diedConnection:Disconnect()
			self.lastSize:set(self.size.Value)
            self.deployed:set(false)
            self.shielded:set(false)
			self.deployedToilet = nil
			self.size.Value /= 2
			self.infoPack.Kills.Value = 0

			task.wait(0.5)
			if not plr or plr.Parent ~= players then
				return
			end
			plr:LoadCharacter()
		end)

		for i, v in char:GetDescendants() do
			if v:IsA("BasePart") then
				v.CollisionGroup = "Characters"
			end
		end

		task.wait()

		self.character = char
		self.characterAdded:Fire(char)
	end)

	local deployObserver = Observer(self.deployed)
	deployObserver:onChange(function()
		self.infoPack.Deployed.Value = self.deployed:get()
	end)

	plr:LoadCharacter()

	return self
end

function player:equipToilet(newId: string)
	local result = array.filter(self.data.Inventory, function(item, _)
		return item[2] == newId
	end)

	if #result >= 2 then
		self.data.Inventory = array.removeIndices(self.data.Inventory, table.unpack(array.removeIndices(self.data.Inventory), 1))
	end

	if result and result[1] then
		for i, v in self.data.Inventory do
			if v[2] == newId then
				self.data.EquippedId = {v[1], v[2]}
				self.equipped = v[1]
			end
		end
	else
		self.data.EquippedId = nil
		self.equipped = "Default"

		if self.deployed:get() and self.character then
			self.character.Humanoid.Health = 0
		end
	end

	--[[self.data.EquippedId = if result and result[1] then {self.data.Inventory[result[1][1], newId} else nil
	self.equipped = if result and result[1] then self.data.Inventory[result[1][1] else "Default"]]

	equippedUpdate:Fire(self.player, {self.data.EquippedId})
end

function player:deleteToilets(list: {string})
	for _, v in list do
		if not typeof(v) == "string" then
			continue
		end

		if self.data.EquippedId and v == self.data.EquippedId[2] then
			self.data.EquippedId = nil
			self.equipped = "Default"

			if self.deployed:get() and self.character then
				self.character.Humanoid.Health = 0
			end
		end

		for i, toilet in self.data.Inventory do
			if toilet[2] == v then
				table.remove(self.data.Inventory, i)
			end
		end
	end
end

function player:setWater(newAmount)
    self.data.Water = newAmount
    self.infoPack.Water.Value = newAmount
end

function player:addWater(amount)
	self.data.Water += amount
    self.infoPack.Water.Value += amount
end

function player:removeWater(amount)
	self.data.Water -= amount
    self.infoPack.Water.Value -= amount
end

function player:getWater()
	return self.infoPack.Water.Value
end

function playerService.start(modules: {})dataService = modules.dataService
	monetization = modules.monetization
	main = modules.main
	library = modules.library

	for _, plr in players:GetPlayers() do
		playerService.players[plr] = player.new(plr)
		playerService.playerJoined:Fire(plr, playerService.players)
	end

	players.PlayerAdded:Connect(function(plr)
		playerService.players[plr] = player.new(plr)
		playerService.playerJoined:Fire(plr, playerService.players)
	end)

	players.PlayerRemoving:Connect(function(plr)
		if playerService.players[plr] then
			playerService.players[plr] = nil
		end
		dataService.release(plr)

		--playerService.playerLeft:Fire(plr, playerService.Players, plr.leaderstats.Stage.value)
	end)

	updateInventoryBridge:Connect(function(plr, content)
		if content and content.id then
			playerService.players[plr]:equipToilet(content.id)
		end

		if content and content.deleteList then
			playerService.players[plr]:deleteToilets(content.deleteList)
		end

		updateInventoryBridge:Fire(plr, {newInventory = playerService.players[plr].data.Inventory, equipped = playerService.players[plr].data.EquippedId})
		equippedUpdate:Fire(plr, {playerService.players[plr].data.EquippedId})
	end)

	equippedUpdate:Connect(function(plr, content)
		if content and content[1] then
			playerService.players[plr]:equipToilet(content[1])
		else
			equippedUpdate:Fire(plr, {playerService.players[plr].data.EquippedId})
		end
	end)

	passesBridge:Connect(function(plr)
		passesBridge:Fire(plr, playerService.players[plr].ownedPasses)
	end)

	tutorialBridge:Connect(function(plr, content)
		if not content then
			tutorialBridge:Fire(plr, playerService.players[plr].data.Logins <= 1)
		else
			playerService.players[plr].tutorialCompleted = true
		end
	end)

	local lastUpdate = os.time()
	runService.Heartbeat:Connect(function()
		if os.time() - lastUpdate < 3 then
			return
		end
		lastUpdate = os.time()

		for i, v in playerService.players do
			equippedUpdate:Fire(v.player, {v.data.EquippedId})
		end
	end)

	task.spawn(function()
		while task.wait(1) do
			for _, v in playerService.players do
				if not v.deployed:get() then
					v.infoPack.TimeSurvived.Value = 0
					v.timeSurvived.Value = "N/A"
				else
					v.infoPack.TimeSurvived.Value += 1
				end
			end
		end
	end)
end

return playerService