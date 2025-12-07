-- Light class module - accepts all dependencies
return function(Config, Utils, GuiBuilder, Suggestions, Commands, Dragging, InputHandler)
	local TweenService = game:GetService("TweenService")

	local Light = {}
	Light.__index = Light

	-- Create new instance
	local function newInstance(config)
		local obj = setmetatable({}, Light)
		obj._config = {}
		for k,v in pairs(Config) do obj._config[k] = v end
		if config then
			for k,v in pairs(config) do obj._config[k] = v end
		end

		-- runtime state
		obj._open = false
		obj._bindings = {}
		obj._dragging = false
		obj._dragConn = nil
		obj._inputConn = nil
		obj._keyConn = nil
		obj._textChangedConn = nil
		obj._tabConn = nil
		obj._navConn = nil
		obj.Gui = nil
		obj.Bar = nil
		obj.Input = nil
		obj.Auto = nil
		obj.Shadows = {}
		obj.Suggestions = nil
		obj._suggestionItems = {}
		obj._selectedIndex = 0
		obj._shadowOffsets = {20, 15, 10, 7, 5, 3, 2}

		-- Commands
		obj.Commands = {}

		return obj
	end

	-- Builds the GUI
	function Light:buildGui()
		GuiBuilder.buildGui(self)
	end

	-- Internal: update placeholder
	function Light:_applyPlaceholder()
		GuiBuilder.applyPlaceholder(self)
	end

	-- Command API
	function Light:AddCommand(name, func)
		Commands.addCommand(self, name, func)
	end

	function Light:RemoveCommand(name)
		Commands.removeCommand(self, name)
	end

	-- Suggestions
	function Light:_renderSuggestions(list)
		Suggestions.renderSuggestions(self, list)
	end

	function Light:_highlightSelection()
		Suggestions.highlightSelection(self)
	end

	function Light:_hideSuggestions()
		Suggestions.hideSuggestions(self)
	end

	function Light:SuspendSuggestions()
		Suggestions.suspendSuggestions(self)
	end

	function Light:_updateSuggestions()
		Suggestions.updateSuggestions(self)
	end

	function Light:_updateAuto()
		Suggestions.updateAuto(self)
	end

	-- Run a command string (returns ok, result/message)
	function Light:Run(text)
		return Commands.run(self, text)
	end

	-- Open / show
	function Light:Open()
		if not self.Gui then self:buildGui() end
		if self._open then return end
		self._open = true
		self.Bar.Visible = true
		for _, sh in ipairs(self.Shadows) do sh.Visible = true end
		if self.Input then
			self.Input:CaptureFocus()
			self.Input.Text = ""
			self.Auto.Text = ""
		end
		-- simple fade-in
		TweenService:Create(self.Bar, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { BackgroundTransparency = 0 }):Play()
	end

	-- Close / hide
	function Light:Close()
		if not self._open then return end
		self._open = false
		-- fade-out
		local t = TweenService:Create(self.Bar, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
		t:Play()
		t.Completed:Wait()
		self.Bar.Visible = false
		for _, sh in ipairs(self.Shadows) do sh.Visible = false end
		self:_hideSuggestions()
	end

	function Light:Toggle()
		if self._open then self:Close() else self:Open() end
	end

	-- Keybind binding (ensures single binding)
	function Light:_bindKey(keycode)
		InputHandler.bindKey(self, keycode)
	end

	-- Dragging behavior
	function Light:_enableDragging()
		Dragging.enableDragging(self)
	end

	-- Change a setting at runtime
	-- supported keys: "Keybind" (Enum.KeyCode or string), "PlaceholderText", "OpenOnInit", "ShowShadows", "BarPosition", "BarSize", "Parent"
	function Light:ChangeSetting(key, value)
		key = tostring(key)
		if key == "Keybind" then
			-- accept Enum.KeyCode or string like "M"
			local kc = value
			if type(kc) == "string" then
				-- try to look up Enum.KeyCode
				local ok, e = pcall(function() return Enum.KeyCode[kc] end)
				if ok and e then kc = e else kc = nil end
			end
			if typeof(kc) == "EnumItem" then
				self._config.Keybind = kc
				self:_bindKey(kc)
				return true
			else
				return false, "invalid Keybind value"
			end
		elseif key == "PlaceholderText" then
			self._config.PlaceholderText = tostring(value)
			self:_applyPlaceholder()
			return true
		elseif key == "OpenOnInit" then
			self._config.OpenOnInit = not not value
			return true
		elseif key == "ShowShadows" then
			self._config.ShowShadows = not not value
			-- rebuild if needed
			if self.Gui then
				self:Destroy()
				self:Init(self._config)
			end
			return true
		elseif key == "BarPosition" then
			if typeof(value) == "UDim2" then
				self._config.BarPosition = value
				if self.Bar then self.Bar.Position = value end
				return true
			else
				return false, "BarPosition must be UDim2"
			end
		elseif key == "BarSize" then
			if typeof(value) == "UDim2" then
				self._config.BarSize = value
				if self.Bar then self.Bar.Size = value end
				return true
			else
				return false, "BarSize must be UDim2"
			end
		elseif key == "Parent" then
			self._config.Parent = value
			-- If already built, move Gui
			if self.Gui and typeof(value) == "Instance" then
				self.Gui.Parent = value
			end
			return true
		else
			-- generic set
			self._config[key] = value
			return true
		end
	end

	function Light:GetSetting(key)
		return self._config[key]
	end

	-- Initializes the module instance (call from LocalScript)
	-- optional config table allowed
	function Light:Init(config)
		-- if already initialized, allow re-init with new config values
		if config then
			for k,v in pairs(config) do self._config[k] = v end
		end

		self:buildGui()
		self:_applyPlaceholder()
		self:_enableDragging()
		self:_bindKey(self._config.Keybind)

		-- Setup all input connections
		InputHandler.setupInputConnections(self)

		if self._config.OpenOnInit then
			self:Open()
		else
			-- ensure hidden on start
			self.Bar.Visible = false
			for _, sh in ipairs(self.Shadows) do sh.Visible = false end
			self:_hideSuggestions()
		end

		return true
	end

	-- Destroy GUI and disconnect events
	function Light:Destroy()
		if self._keyConn then
			self._keyConn:Disconnect()
			self._keyConn = nil
		end
		if self._dragConn then
			self._dragConn:Disconnect()
			self._dragConn = nil
		end
		if self._inputConn then
			self._inputConn:Disconnect()
			self._inputConn = nil
		end
		if self._textChangedConn then
			self._textChangedConn:Disconnect()
			self._textChangedConn = nil
		end
		if self._tabConn then
			self._tabConn:Disconnect()
			self._tabConn = nil
		end
		if self._navConn then
			self._navConn:Disconnect()
			self._navConn = nil
		end
		if self.Gui then
			self.Gui:Destroy()
			self.Gui = nil
		end
		self.Bar = nil
		self.Input = nil
		self.Auto = nil
		self.Shadows = {}
		self._open = false
		self.Commands = {}
	end

	-- Export factory function
	Light.new = newInstance

	return Light
end
