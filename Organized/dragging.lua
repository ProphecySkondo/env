local UserInputService = game:GetService("UserInputService")

local Dragging = {}

-- Dragging behavior
function Dragging.enableDragging(self)
	if not self.Bar then return end

	self.Bar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			self._dragging = true
			local startPos = self.Bar.Position
			local startMouse = inp.Position
			local con
			con = inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then
					self._dragging = false
					if self._dragConn then
						self._dragConn:Disconnect()
						self._dragConn = nil
					end
					con:Disconnect()
				end
			end)
			self._dragConn = UserInputService.InputChanged:Connect(function(i)
				if self._dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
					local delta = i.Position - startMouse
					local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
					self.Bar.Position = newPos
					-- move shadows to keep relative offsets
					for idx, shadow in ipairs(self.Shadows) do
						local offset = self._shadowOffsets[idx] or 5
						shadow.Position = UDim2.new(newPos.X.Scale, newPos.X.Offset - offset, newPos.Y.Scale, newPos.Y.Offset - offset)
					end
				end
			end)
		end
	end)
end

return Dragging
