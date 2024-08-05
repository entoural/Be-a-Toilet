local arrayUtilities = {}

function arrayUtilities.shuffleArray(array)
    local length = #array
    for i = length, 2, -1 do
        local j = math.random(i)
        array[i], array[j] = array[j], array[i]
    end
    return array
end


return arrayUtilities