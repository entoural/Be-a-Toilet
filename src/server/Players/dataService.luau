local sss = game:GetService("ServerScriptService")
local profileService = require(sss:WaitForChild("ServerPackages").ProfileService)
local players = game:GetService("Players")

local dataService = {}

--dataService.defaultData = {rebirths = 0, fastestTime = nil}
dataService.profiles = {}

local profileStore = profileService.GetProfileStore(
	"BeAToiletDSR1",
	{
		Logins = 0,
		Water = 150,
		LargestSize = 0,
		Logs = {},
		FriendsJoined = {},
		Purchases = {},
		OwnedPasses = {},
		RewardsClaimed = {["Friends"] = false, ["Group"] = false, ["Roblox Follow"] = false, ["Twitter Follow"] = false},
		Inventory = {},
		EquippedId = {},
		--[[streakInfo = {started = os.time() - 86400 * 30 + 30, length = 29, lastClaimedSpin = os.time()},]]
		streakInfo = {started = nil, length = 0, lastClaimedSpin = os.time()},
		Boosts = {size = {}, speed = {}, shield = {}},
		SpecialEggs = {["Tech Egg"] = 0, ["Mystery Egg"] = 0},
		Spins = 0
	}
)

function dataService.release(plr)
	dataService.profiles[plr]:Release()
	dataService.profiles[plr] = nil
	plr:Kick()
end

function dataService.retrieveProfile(plr)
	local profile = profileStore:LoadProfileAsync("PlayerData_"..plr.UserId)
	if profile ~= nil then
		profile:AddUserId(plr.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			dataService.release(plr)
		end)
		if plr:IsDescendantOf(players) then
			dataService.profiles[plr] = profile
		else
			profile:Release()
		end
		return profile
	else
		plr:Kick("Failed to load your profile! Try again later")
	end
end

function dataService.removeProfile(plr)
	local profile = dataService.profiles[plr]
	if profile then
		profile:Release()
	end
end

return dataService