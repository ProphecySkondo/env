local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Utils = {}

-- Internal: safe parent
function Utils.parentFor(obj)
	if obj._config.Parent then
		return obj._config.Parent
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

-- helper: find best player match from partial (case-insensitive)
function Utils.findBestPlayerMatch(prefix)
	if not prefix or prefix == "" then return nil end
	prefix = prefix:lower()
	local exact = nil
	local starts = nil
	for _, p in ipairs(Players:GetPlayers()) do
		local name = (p.Name or ""):lower()
		local dname = (p.DisplayName or ""):lower()
		if name == prefix or dname == prefix then
			exact = p.Name
			break
		end
		if name:sub(1, #prefix) == prefix or dname:sub(1, #prefix) == prefix then
			if not starts then starts = p.Name end
		end
	end
	return exact or starts
end

return Utils
