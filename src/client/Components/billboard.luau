local runService = game:GetService("RunService")
local players = game:GetService("Players")

local plr = players.LocalPlayer
local library
local spring

local billboardController = {}
billboardController.executePriority = 6

local billboard = {}
billboard.__index = billboard
billboard.activationRange = 10

billboardController.billboards = {}

function billboardController.new(instance: BillboardGui, props: {}, callback: () -> nil, requestOpenCallback: () -> boolean, ...)
    local self = setmetatable({}, billboard)

    self.instance = instance
    self.position = instance.Adornee.Position
    self.size = instance.Size
    self.callback = callback
    self.validate = requestOpenCallback
    self.args = ...
    self.opened = false

    self.instance.Size = UDim2.new(0, 0, 0, 0)

    if props then
        for i, v in props do
            self[i] = v
        end
    end

    table.insert(library.billboardIgnoreParts, self.instance.Adornee)
    table.insert(billboardController.billboards, self)
    return self
end

function billboard:close(bypassCallback)
    self.opened = false
    spring.stop(self.instance)
    spring.target(self.instance, 1, 3, {Size = UDim2.new(0, 0, 0, 0)})
    if self.callback and not bypassCallback then
        self.callback()
    end
end

function billboard:open()
    if self.validate and not self.validate(self.args) then
        return
    end

    self.opened = true
    spring.stop(self.instance)
    spring.target(self.instance, 0.5, 2, {Size = self.size})
    if self.callback then
        self.callback(true, self.args)
    end
end

function billboard:isOnScreen()
    --[[local _, OnScreen = workspace.CurrentCamera:WorldToScreenPoint(self.instance.Adornee.Position)

    if OnScreen then
        if #workspace.CurrentCamera:GetPartsObscuringTarget({workspace.CurrentCamera.CFrame.Position, self.instance.Adornee.Position}, library.billboardIgnoreParts) == 0 then
            return true
        end
    end]]

    return true
end

function billboardController.start(modules: {})
    spring = modules["Util"]["spring"]
    library = modules.library

    runService.Heartbeat:Connect(function()
        if #billboardController.billboards == 0 then
            return
        end

        for i, v in billboardController.billboards do
            if not plr.Character then
                if v.opened then
                    v:close()
                end
                continue
            end

            local distance = (plr.Character:GetPivot().Position - v.position).Magnitude
            if distance > v.activationRange and v.opened or (v.opened and v.validate and not v.validate()) or (v.opened and not v:isOnScreen()) then
                v:close()
            elseif distance <= v.activationRange and not v.opened and v:isOnScreen() then
                v:open()
            end
        end
    end)
end


return billboardController