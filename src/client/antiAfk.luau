local players = game:GetService("Players")
local teleportService = game:GetService("TeleportService")

local plr = players.LocalPlayer

local antiAfk = {}

function antiAfk.init()
    --[[plr.Idled:Connect(function(timeIdled)
        print("idleFired", timeIdled)
        if timeIdled < 60 * 17 then return end

        teleportService:Teleport(game.PlaceId)
    end)]]
end

return antiAfk