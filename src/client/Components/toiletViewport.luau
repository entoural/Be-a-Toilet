local rs = game:GetService("ReplicatedStorage")

local packages = rs:WaitForChild("Packages")
local toilets = rs:WaitForChild("ToiletSkinModels")

local viewport

local toiletViewport = {}
toiletViewport.__index = toiletViewport

function toiletViewport.new(viewportFrame, name)
    local self = setmetatable({}, toiletViewport)
    self.viewportFrame = viewportFrame

    while not viewport do
        task.wait()
    end

    self.viewportFrame.CurrentCamera = self.viewportFrame:FindFirstChild("Camera")

    local toilet = toilets:FindFirstChild(name):Clone()
    toilet.Parent = self.viewportFrame
    self.viewportFrame.CurrentCamera.CameraSubject = toilet

    self.viewport = viewport.new(self.viewportFrame, self.viewportFrame:FindFirstChild("Camera"))

    local cf, size = toilet:GetBoundingBox()
    self.viewport:SetModel(toilet)

    local orientation = CFrame.new() * CFrame.Angles(0, -70, 0)
    local distance = self.viewport:GetFitDistance(cf.Position)
    self.viewportFrame.CurrentCamera.CFrame = CFrame.new(cf.Position) * orientation * CFrame.new(0, 0, distance)

    return viewportFrame
end

function toiletViewport.start(modules)
    viewport = modules.viewport
end

return toiletViewport