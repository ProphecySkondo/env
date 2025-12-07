-- GuiBuilder module - accepts Utils as parameter
return function(Utils)
	local GuiBuilder = {}

	-- Builds the GUI
	function GuiBuilder.buildGui(self)
		-- Avoid rebuilding
		if self.Gui then return end

		local gui = Instance.new("ScreenGui")
		gui.Name = "LightController"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.Parent = Utils.parentFor(self)
		self.Gui = gui

		-- Optional soft shadows (subtle, light-appropriate)
		local shadows = {}
		local shadowOffsets = {unpack(self._shadowOffsets)}
		local shadowTransparencies = {0.95, 0.90, 0.85, 0.80, 0.75, 0.70, 0.65}
		if self._config.ShowShadows then
			for i = 1, #shadowOffsets do
				local offset = shadowOffsets[i]
				local shadow = Instance.new("Frame")
				shadow.Size = UDim2.new(0, self._config.BarSize.X.Offset + (offset * 2), 0, self._config.BarSize.Y.Offset + (offset * 2))
				shadow.Position = UDim2.new(self._config.BarPosition.X.Scale, self._config.BarPosition.X.Offset - offset, self._config.BarPosition.Y.Scale, self._config.BarPosition.Y.Offset - offset)
				shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
				shadow.BackgroundTransparency = math.clamp(0.95 - (i * 0.02), 0, 1)
				shadow.BorderSizePixel = 0
				shadow.ZIndex = 0
				shadow.Parent = gui

				local grad = Instance.new("UIGradient", shadow)
				grad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0))
				})
				grad.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, shadow.BackgroundTransparency),
					NumberSequenceKeypoint.new(1, 1)
				})
				Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 18 + offset)
				table.insert(shadows, shadow)
			end
		end
		self.Shadows = shadows

		-- Main bar (light gray)
		local bar = Instance.new("Frame")
		bar.Size = self._config.BarSize
		bar.Position = self._config.BarPosition
		bar.BackgroundColor3 = self._config.LightColor
		bar.BorderSizePixel = 0
		bar.ZIndex = 10
		bar.Parent = gui
		self.Bar = bar
		Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 18)

		-- subtle gradient
		local gradient = Instance.new("UIGradient", bar)
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, self._config.LightColor),
			ColorSequenceKeypoint.new(1, self._config.AccentColor)
		})
		gradient.Rotation = 90

		-- TextBox (no prefix label)
		local input = Instance.new("TextBox", bar)
		input.Name = "LightInput"
		input.Size = UDim2.new(1, -100, 1, -16)
		input.Position = UDim2.new(0, 20, 0, 8)
		input.BackgroundTransparency = 1
		input.PlaceholderText = tostring(self._config.PlaceholderText or "")
		input.PlaceholderColor3 = Color3.fromRGB(140, 140, 145)
		input.TextColor3 = Color3.fromRGB(30, 30, 35)
		input.Font = Enum.Font.GothamSemibold
		input.TextSize = 20
		input.TextXAlignment = Enum.TextXAlignment.Left
		input.ClearTextOnFocus = false
		input.TextStrokeTransparency = 1
		input.ZIndex = 20
		input.Parent = bar
		self.Input = input

		-- Autocomplete / helper line (keeps as small hint; dropdown is the main thing)
		local auto = Instance.new("TextLabel", bar)
		auto.BackgroundTransparency = 1
		auto.Position = UDim2.new(0, 20, 1, -2)
		auto.Size = UDim2.new(1, -100, 0, 22)
		auto.Font = Enum.Font.Gotham
		auto.TextSize = 18
		auto.TextXAlignment = Enum.TextXAlignment.Left
		auto.TextColor3 = Color3.fromRGB(110, 110, 115)
		auto.Text = ""
		auto.ZIndex = 20
		self.Auto = auto

		-- SUGGESTIONS DROPDOWN (child of bar so it moves with it)
		local suggestions = Instance.new("Frame", bar)
		suggestions.Name = "Suggestions"
		suggestions.Visible = false
		suggestions.BackgroundColor3 = Color3.fromRGB(255,255,255)
		suggestions.BackgroundTransparency = 0
		suggestions.BorderSizePixel = 0
		suggestions.Size = UDim2.new(1, -40, 0, 0) -- height will expand with items
		suggestions.Position = UDim2.new(0, 20, 1, 8)
		suggestions.ZIndex = 25
		Instance.new("UICorner", suggestions).CornerRadius = UDim.new(0, 8)

		-- layout inside suggestions (store it on self so other functions can read it)
		local listLayout = Instance.new("UIListLayout", suggestions)
		listLayout.FillDirection = Enum.FillDirection.Vertical
		listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, 4)
		self._listLayout = listLayout

		-- padding container (store on suggestions as child; we'll read it later via FindFirstChildOfClass)
		local padding = Instance.new("UIPadding", suggestions)
		padding.PaddingLeft = UDim.new(0, 6)
		padding.PaddingRight = UDim.new(0, 6)
		padding.PaddingTop = UDim.new(0, 6)
		padding.PaddingBottom = UDim.new(0, 6)

		self.Suggestions = suggestions
		self._suggestionItems = {}
		self._selectedIndex = 0

		-- Make all shadows and bar positions respect bar position when dragging
		for idx, sh in ipairs(self.Shadows) do
			local offset = self._shadowOffsets[idx] or 5
			sh.Position = UDim2.new(self.Bar.Position.X.Scale, self.Bar.Position.X.Offset - offset, self.Bar.Position.Y.Scale, self.Bar.Position.Y.Offset - offset)
		end

		-- Capture focus on open by default
		input.ClearTextOnFocus = false
	end

	-- Internal: update placeholder
	function GuiBuilder.applyPlaceholder(self)
		if self.Input then
			self.Input.PlaceholderText = tostring(self._config.PlaceholderText or "")
		end
	end

	return GuiBuilder
end
