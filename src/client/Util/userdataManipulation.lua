local util = {}

util.multUDim2 = function(first: UDim2, second: UDim2 | number)
	if typeof(second) == "UDim2" then
		local xScale = first.X.Scale * second.X.Scale
		local xOffset = first.X.Offset * second.X.Offset
		local yScale = first.Y.Scale * second.Y.Scale
		local yOffset = first.Y.Offset * second.Y.Offset
		return UDim2.new(xScale, xOffset, yScale, yOffset)
	elseif typeof(second) == "number" then
		local xScale = first.X.Scale * second
		local xOffset = first.X.Offset * second
		local yScale = first.Y.Scale * second
		local yOffset = first.Y.Offset * second
		return UDim2.new(xScale, xOffset, yScale, yOffset)
	end
end

return util