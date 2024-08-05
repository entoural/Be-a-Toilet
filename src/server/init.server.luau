--!strict
type module = {ModuleScript}

-- Dictionary containing all of the modulescript instances to be required
local modules: module = {}

for i, v in script:GetDescendants() do
	if not v:IsA("ModuleScript") then
		continue
	end
	table.insert(modules, v)
end

-- Array containing all successfully required modules, ordered by execution priority
local required = {}

-- Dictionary containing all successfully required modules, indexed by their instance name, unordered
local dict = {}

for i, v in modules do
	local success, err = pcall(require, v)

	if success then
		table.insert(required, require(v))
		dict[v.Name] = require(v)
	else
		warn(err.." "..v.Name)
	end
end

table.sort(required, function(a, b)
	return (a.executePriority or 20) < (b.executePriority or 20)
end)

for i, v in required do
	if not v.init then
		continue
	end

	if v.initThread then
		task.spawn(v.init)
	else
		v.init()
	end
end

for i, v in required do
	if not v.start then
		continue
	end

	if v.startThread then
		task.spawn(v.start, dict)
	else
		v.start(dict)
	end
end