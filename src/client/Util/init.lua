local utilities = {}

utilities.executePriority = 1

for i, v in script:GetChildren() do
	utilities[v.Name] = require(v)
end

for i, v in utilities do
	if i == "executePriority" then
		continue
	end
	if v.retrieveDependencies then
		v.retrieveDependencies(utilities)
	end
end

return utilities