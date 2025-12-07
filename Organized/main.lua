-- Main entry point - loads all modules from GitHub and initializes
local BASE_URL = "https://raw.githubusercontent.com/ProphecySkondo/env/master/Organized/"

-- Loader function
local function loadModule(name)
	local url = BASE_URL .. name .. ".lua"
	local success, result = pcall(function()
		return loadstring(game:HttpGet(url))()
	end)
	if not success then
		error("Failed to load module: " .. name .. " - " .. tostring(result))
	end
	return result
end

-- Load all modules in dependency order
local Config = loadModule("config")
local Utils = loadModule("utils")
local GuiBuilder = loadModule("gui")(Utils)
local Suggestions = loadModule("suggestions")(Utils)
local Commands = loadModule("commands")
local Dragging = loadModule("dragging")
local InputHandler = loadModule("input")
local Light = loadModule("light")(Config, Utils, GuiBuilder, Suggestions, Commands, Dragging, InputHandler)

-- Factory: return singleton instance bound to current LocalPlayer
local moduleInstance = Light.new()

-- Example: Add some default commands
moduleInstance:AddCommand("help", function(args, fullText)
	print("Available commands:")
	for name, _ in pairs(moduleInstance.Commands) do
		print("  - " .. name)
	end
end)

moduleInstance:AddCommand("clear", function(args, fullText)
	if moduleInstance.Input then
		moduleInstance.Input.Text = ""
		moduleInstance.Auto.Text = ""
	end
end)

-- Initialize the module
moduleInstance:Init()

return moduleInstance
