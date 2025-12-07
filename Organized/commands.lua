local Commands = {}

-- Command API
function Commands.addCommand(self, name, func)
	if type(name) ~= "string" or type(func) ~= "function" then
		error("AddCommand expects (string, function)")
	end
	self.Commands[name:lower()] = func
end

function Commands.removeCommand(self, name)
	if type(name) ~= "string" then return end
	self.Commands[name:lower()] = nil
end

-- Run a command string (returns ok, result/message)
function Commands.run(self, text)
	if not text then return false, "no text" end
	local tokens = {}
	for part in tostring(text):gmatch("%S+") do table.insert(tokens, part) end
	if #tokens == 0 then return false, "empty" end
	local cmdName = tokens[1]:lower()
	local cmd = self.Commands[cmdName]
	if not cmd then
		return false, ("unknown command: %s"):format(cmdName)
	end
	table.remove(tokens, 1)
	local ok, err = pcall(cmd, tokens, text)
	return ok, err
end

return Commands
