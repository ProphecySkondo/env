-- Default configuration for Light command bar
return {
	Keybind = Enum.KeyCode.K,           -- toggle key (can be changed with ChangeSetting)
	PlaceholderText = "type here...",   -- textbox placeholder
	OpenOnInit = false,                 -- open when initialized
	Parent = nil,                       -- override parent (defaults to PlayerGui)
	BarSize = UDim2.new(0, 640, 0, 56),
	BarPosition = UDim2.new(0.5, -320, 0.5, -28),
	LightColor = Color3.fromRGB(240, 240, 245), -- main light gray
	AccentColor = Color3.fromRGB(220, 220, 225), -- subtle gradient
	ShowShadows = true,                 -- soft shadow layers
	MaxSuggestions = 6,                 -- maximum number of dropdown items
}
