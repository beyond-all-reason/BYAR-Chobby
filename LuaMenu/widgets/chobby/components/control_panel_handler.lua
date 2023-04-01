function GetControlPanelHandler(panelHolder)

	local externalFunctions = {}

	local CONTROL_SPACING = 3
	local CONTROL_SIDE_SPACING = 4

	-------------------------------------------------------------------
	-- Local variables
	-------------------------------------------------------------------

	local fontSizeScale = fontSizeScale or 3

	local controlWidth = 290
	local controlHeight = 70
	local columnCount = 2

	local updateFunction

	local controls = {}

	-------------------------------------------------------------------
	-- Local functions
	-------------------------------------------------------------------

	local function SetControlPositionAndSize(index)
		local row = math.floor((index - 1)/columnCount)
		local column = (index - row*columnCount - 1)

		controls[index].control:SetPos(
			column * (controlWidth + CONTROL_SIDE_SPACING),
			row * (controlHeight + CONTROL_SPACING),
			controlWidth,
			controlHeight
		)
	end

	-------------------------------------------------------------------
	-- External Functions
	-------------------------------------------------------------------
	function externalFunctions.UpdateLayout()
		if updateFunction then
			updateFunction()
		end

		if #controls > 2 then
			controlHeight = 38
		else
			controlHeight = 79
		end

		for i = 1, #controls do
			SetControlPositionAndSize(i)
		end
	end

	function externalFunctions.GetControlCount()
		return #controls
	end

	function externalFunctions.SetUpdateFunction(newUpdateFunction)
		updateFunction = newUpdateFunction
	end

	function externalFunctions.GetChildByName(name)
		return panelHolder:GetChildByName(name)
	end


	function externalFunctions.RemoveControl(name)
		if not panelHolder:GetChildByName(name) then
			return
		end

		local found = false
		for i = 1, #controls do
			if controls[i].control.name == name then
				panelHolder:RemoveChild(controls[i].control)
				table.remove(controls, i)
				found = true
				break
			end
		end
		if found then
			externalFunctions.UpdateLayout()
		end
	end

	function externalFunctions.AddControl(control, rank)
		-- High rank puts => more visible and less mobile.
		if panelHolder:GetChildByName(control.name) then
			return
		end

		rank = rank or 0
		local controlCount = externalFunctions.GetControlCount()
		local addPosition = 1
		while addPosition <= controlCount do
			if rank > controls[addPosition].rank then
				break
			end
			addPosition = addPosition + 1
		end

		for i = controlCount, addPosition, -1 do
			controls[i + 1] = controls[i]
		end

		panelHolder:AddChild(control)

		controls[addPosition] = {
			control = control,
			rank = rank,
		}

		externalFunctions.UpdateLayout()
	end

	-------------------------------------------------------------------
	-- Initialization
	-------------------------------------------------------------------

	return externalFunctions
end
