-- Suggestions module - accepts Utils as parameter
return function(Utils)
	local Players = game:GetService("Players")
	local Suggestions = {}

	-- Build and show suggestion items (list = { {text=..., kind="command"/"player", value=...}, ... })
	function Suggestions.renderSuggestions(self, list)
		-- clear existing suggestion items (keep UIListLayout / UIPadding)
		for _, child in ipairs(self.Suggestions:GetChildren()) do
			if not child:IsA("UIListLayout") and not child:IsA("UIPadding") and not child:IsA("UICorner") then
				child:Destroy()
			end
		end

		self._suggestionItems = {}
		self._selectedIndex = 0

		local maxItems = math.max(0, math.min(#list, self._config.MaxSuggestions or 6))

		-- spacing from stored listLayout (fallback to 4)
		local spacing = 4
		if self._listLayout and self._listLayout.Padding then
			spacing = self._listLayout.Padding.Offset or spacing
		end

		local totalHeight = 0
		for i = 1, maxItems do
			local item = list[i]
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 28)
			btn.BackgroundTransparency = 1
			btn.Text = item.text
			btn.Font = Enum.Font.Gotham
			btn.TextSize = 16
			btn.TextColor3 = Color3.fromRGB(30,30,30)
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.AutoButtonColor = false
			btn.ZIndex = 30
			btn.LayoutOrder = i
			btn.Parent = self.Suggestions

			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

			local hoverBg = Instance.new("Frame", btn)
			hoverBg.Size = UDim2.new(1, 0, 1, 0)
			hoverBg.BackgroundColor3 = Color3.fromRGB(245,245,245)
			hoverBg.BackgroundTransparency = 1
			hoverBg.BorderSizePixel = 0
			hoverBg.ZIndex = 28

			local caption = Instance.new("TextLabel", btn)
			caption.BackgroundTransparency = 1
			caption.Size = UDim2.new(0, 80, 1, 0)
			caption.Position = UDim2.new(1, -84, 0, 0)
			caption.Font = Enum.Font.Gotham
			caption.TextSize = 12
			caption.TextColor3 = Color3.fromRGB(120,120,120)
			caption.Text = (item.kind == "player") and "player" or (item.kind == "command" and "command" or "")
			caption.TextXAlignment = Enum.TextXAlignment.Right
			caption.ZIndex = 31

			-- click behavior
			btn.MouseButton1Click:Connect(function()
				if item.kind == "command" then
					self.Input.Text = item.value .. " "
					self.Input:CaptureFocus()
					self:SuspendSuggestions()
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
					self.Input:CaptureFocus()
					self:SuspendSuggestions()
				else
					self.Input.Text = item.value
					self.Input:CaptureFocus()
					self:SuspendSuggestions()
				end
			end)

			btn.MouseEnter:Connect(function()
				hoverBg.BackgroundTransparency = 0
				self._selectedIndex = i
				self:_highlightSelection()
			end)
			btn.MouseLeave:Connect(function()
				hoverBg.BackgroundTransparency = 1
				self._selectedIndex = 0
				self:_highlightSelection()
			end)

			table.insert(self._suggestionItems, {button = btn, data = item, bg = hoverBg})
			totalHeight = totalHeight + 28 + spacing
		end

		-- read padding offsets safely
		local paddingTop, paddingBottom = 12, 12
		local pad = self.Suggestions:FindFirstChildOfClass("UIPadding")
		if pad then
			paddingTop = (pad.PaddingTop and pad.PaddingTop.Offset) or paddingTop
			paddingBottom = (pad.PaddingBottom and pad.PaddingBottom.Offset) or paddingBottom
		end

		local height = math.max(0, (maxItems * 28) + ((maxItems - 1) * spacing) + paddingTop + paddingBottom)
		self.Suggestions.Size = UDim2.new(self.Suggestions.Size.X.Scale, self.Suggestions.Size.X.Offset, 0, height)
		self.Suggestions.Visible = (maxItems > 0)

		self._selectedIndex = 0
		self:_highlightSelection()
	end

	function Suggestions.highlightSelection(self)
		for i,entry in ipairs(self._suggestionItems) do
			if i == self._selectedIndex then
				entry.bg.BackgroundTransparency = 0
				entry.button.TextColor3 = Color3.fromRGB(10,10,10)
			else
				entry.bg.BackgroundTransparency = 1
				entry.button.TextColor3 = Color3.fromRGB(30,30,30)
			end
		end
	end

	function Suggestions.hideSuggestions(self)
		self.Suggestions.Visible = false
		self._suggestionItems = {}
		self._selectedIndex = 0
	end

	function Suggestions.suspendSuggestions(self)
		-- used to briefly hide suggestions after clicking to prevent immediate reopen
		self:_hideSuggestions()
	end

	-- Builds suggestion list based on current input and calls render
	function Suggestions.updateSuggestions(self)
		if not self.Input or not self.Suggestions then return end
		local txt = tostring(self.Input.Text or "")
		local trimmed = txt:match("^%s*(.-)%s*$") or ""
		if trimmed == "" then
			self:_hideSuggestions()
			self.Auto.Text = ""
			return
		end

		local tokens = {}
		for p in trimmed:gmatch("%S+") do table.insert(tokens, p) end
		local first = tokens[1] and tokens[1]:lower() or ""

		-- If user typing first token: show commands starting with typed prefix
		if #tokens == 1 then
			local suggestions = {}
			if first ~= "" then
				for name, _ in pairs(self.Commands) do
					if name:sub(1, #first) == first then
						table.insert(suggestions, { text = name, kind = "command", value = name })
					end
				end
			end

			-- sort alphabetically and limit
			table.sort(suggestions, function(a,b) return a.text < b.text end)
			self.Auto.Text = (suggestions[1] and suggestions[1].text) or ""
			self:_renderSuggestions(suggestions)
			return
		end

		-- If typing second token: suggest player names
		if #tokens >= 2 then
			local partial = tokens[2]
			local results = {}
			local partialLower = (partial or ""):lower()
			for _,p in ipairs(Players:GetPlayers()) do
				local name = p.Name or ""
				local dname = p.DisplayName or ""
				if name:lower():sub(1, #partialLower) == partialLower or dname:lower():sub(1, #partialLower) == partialLower then
					table.insert(results, { text = name, kind = "player", value = name })
				end
			end
			table.sort(results, function(a,b) return a.text < b.text end)
			self.Auto.Text = (results[1] and (first .. " " .. results[1].text)) or ""
			self:_renderSuggestions(results)
			return
		end

		self:_hideSuggestions()
		self.Auto.Text = ""
	end

	-- Autocomplete update (commands and player name suggestions)
	function Suggestions.updateAuto(self)
		if not self.Input or not self.Auto then return end
		local txt = self.Input.Text or ""
		local trimmed = txt:match("^%s*(.-)%s*$") or ""
		if trimmed == "" then
			self.Auto.Text = ""
			return
		end

		local tokens = {}
		for part in trimmed:gmatch("%S+") do table.insert(tokens, part) end
		local first = tokens[1] and tokens[1]:lower() or ""

		-- if typing the first token -> suggest commands (quick hint)
		if #tokens == 1 then
			if first == "" then self.Auto.Text = "" return end
			local best = nil
			for name, _ in pairs(self.Commands) do
				if name:sub(1, #first) == first then
					best = name
					break
				end
			end
			self.Auto.Text = best or ""
			return
		end

		-- if typing second token -> suggest player names
		if #tokens >= 2 then
			local partial = tokens[2]
			local match = Utils.findBestPlayerMatch(partial)
			if match then
				self.Auto.Text = first .. " " .. match
				return
			end
			self.Auto.Text = ""
			return
		end
	end

	return Suggestions
end
