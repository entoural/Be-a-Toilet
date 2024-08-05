local players = game:GetService("Players")

local playerService
local monetization
local part = workspace:WaitForChild("VIPPart")

local vip = {}

vip.debounces = {}

function vip.start(modules)
    playerService = modules.playerService
    monetization = modules.monetization

    part.Touched:Connect(function(hit)
        for _, v in playerService.players do
            if hit.Parent ~= v.character then
                continue
            end

            if not v.ownedPasses["VIP"][1] and not table.find(vip.debounces, v.player) then
                monetization.promptPass(v.player, "VIP")
                table.insert(vip.debounces, v.player)

                task.wait(30)
                if not v or v.player.Parent ~= players then
                    return
                end

                table.remove(vip.debounces, table.find(vip.debounces, v.player))
            end

            return
        end
    end)
end

return vip