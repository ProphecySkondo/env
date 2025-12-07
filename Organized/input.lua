local UserInputService = game:GetService("UserInputService")

local InputHandler = {}

-- Keybind binding (ensures single binding)
function InputHandler.bindKey(self, keycode)
	-- unbind previous
	if self._keyConn then
		self._keyConn:Disconnect()
		self._keyConn = nil
	end
	if not keycode then return end

	self._keyConn = UserInputService.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.KeyCode == keycode then
			self:Toggle()
		end
	end)
end

-- Setup input connections (FocusLost, TextChanged, Tab, Navigation)
function InputHandler.setupInputConnections(self)
	-- connect FocusLost to execute commands and hide
	if self.Input and not self._inputConn then
		self._inputConn = self.Input.FocusLost:Connect(function(enter)
			if enter and self.Input.Text ~= "" then
				-- execute command text
				local ok, res = self:Run(self.Input.Text)
				-- you can handle ok/res here or choose to fire an event
				self.Input.Text = ""
				self.Auto.Text = ""
			end
			wait(0.12)
			self:Close()
		end)
	end

	-- Text change -> update autocomplete and suggestions
	if self.Input and not self._textChangedConn then
		self._textChangedConn = self.Input:GetPropertyChangedSignal("Text"):Connect(function()
			self:_updateAuto()
			self:_updateSuggestions()
		end)
	end

	-- Tab completion / extra input handling
	if not self._tabConn then
		self._tabConn = UserInputService.InputBegan:Connect(function(key, gp)
			if gp then return end
			if not self.Input or not self.Input:IsFocused() then return end
			-- Tab completion existing behavior
			if key.KeyCode == Enum.KeyCode.Tab and self.Auto and self.Auto.Text ~= "" then
				local current = self.Input.Text or ""
				local trimmed = current:match("^%s*(.-)%s*$") or ""
				-- if there's a space -> complete second token only
				if trimmed:find("%s") then
					local tokens = {}
					for part in trimmed:gmatch("%S+") do table.insert(tokens, part) end
					local first = tokens[1] and tokens[1]:lower() or ""
					local parts = {}
					for part in self.Auto.Text:gmatch("%S+") do table.insert(parts, part) end
					if #parts >= 2 then
						self.Input.Text = first .. " " .. parts[2]
						self.Auto.Text = ""
					else
						self.Input.Text = self.Auto.Text
						self.Auto.Text = ""
					end
				else
					-- no space -> complete command
					self.Input.Text = self.Auto.Text
					self.Auto.Text = ""
				end
			end
		end)
	end

	-- Keyboard navigation for suggestions (Up/Down/Enter)
	if not self._navConn then
		self._navConn = UserInputService.InputBegan:Connect(function(input, gp)
			if gp then return end
			if not self.Input or not self.Input:IsFocused() then return end
			if self.Suggestions and self.Suggestions.Visible then
				if input.KeyCode == Enum.KeyCode.Down then
					-- move down
					if #self._suggestionItems > 0 then
						self._selectedIndex = math.clamp((self._selectedIndex or 0) + 1, 1, #self._suggestionItems)
						self:_highlightSelection()
					end
				elseif input.KeyCode == Enum.KeyCode.Up then
					-- move up
					if #self._suggestionItems > 0 then
						self._selectedIndex = math.clamp((self._selectedIndex or 0) - 1, 1, #self._suggestionItems)
						self:_highlightSelection()
					end
				elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
					-- if selection exists, apply it, else run normally
					if self._selectedIndex and self._selectedIndex >= 1 and self._selectedIndex <= #self._suggestionItems then
						local chosen = self._suggestionItems[self._selectedIndex]
						if chosen and chosen.data then
							local item = chosen.data
							-- reuse click logic
							if item.kind == "command" then
								self.Input.Text = item.value .. " "
							elseif item.kind == "player" then
								local current = tostring(self.Input.Text or "")
								local trimmed = current:match("^%s*(.-)%s*$") or ""
								local tokens = {}
								for p in trimmed:gmatch("%S+") do table.insert(tokens, p) end
								if #tokens >= 1 then
									if #tokens == 1 then
										self.Input.Text = tokens[1] .. " " .. item.value
									else
										tokens[2] = item.value
										self.Input.Text = table.concat(tokens, " ")
									end
								else
									self.Input.Text = item.value
								end
							else
								self.Input.Text = item.value
							end
							self.Input:CaptureFocus()
							self:SuspendSuggestions()
							return
						end
					end

					-- otherwise execute the command if Enter pressed with no suggestion chosen
					if self.Input.Text ~= "" then
						local ok, res = self:Run(self.Input.Text)
						self.Input.Text = ""
						self.Auto.Text = ""
						self:SuspendSuggestions()
					end
				end
			else
				-- if suggestions not visible but Enter pressed, execute
				if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
					if self.Input and self.Input:IsFocused() and (self.Input.Text or "") ~= "" then
						local ok, res = self:Run(self.Input.Text)
						self.Input.Text = ""
						self.Auto.Text = ""
						self:SuspendSuggestions()
					end
				end
			end
		end)
	end
end

return InputHandler
