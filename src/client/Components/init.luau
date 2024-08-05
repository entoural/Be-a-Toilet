local components = {}
components.executePriority = 5

for i, v in script:GetChildren() do
	components[v.Name] = require(v)
end

function components.init()
	for i, v in components do
		if typeof(v) == "function" or typeof(v) == "number" then
			continue
		end
		if v.retrieveDependencies then
			v.retrieveDependencies(components)
		end
	end
end




return components