local spring
local multUDim2

local burst = {}
burst.debounces = {}

function burst.new(instance: Instance)
    if burst.debounces[instance] then
        return
    end

    local origSize = instance.Size
    local burstSize = multUDim2(origSize, 1.15)

    task.spawn(function()
        burst.debounces[instance] = true
        spring.target(instance, 0.5, 4, {Size = burstSize})

        task.wait(0.2)

        spring.target(instance, 1.3, 4, {Size = origSize})
        task.wait(0.4)
        instance.Size = origSize
        burst.debounces[instance] = nil
    end)
end

function burst.start(modules)
    spring = modules.Util.spring
    multUDim2 = modules.Util.userdataManipulation.multUDim2
end

return burst