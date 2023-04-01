function widget:GetInfo()
	return {
		name    = 'Block Input',
		desc    = 'Blocks input from reaching the game when the menu is displayed.',
		author  = 'GoogleFrog',
		date    = '2016',
		license = 'GNU GPL v3',
		layer   = 2000,
		enabled = true,
	}
end

local blockInput = true

--------------------------------------------------------------------------
--------------------------------------------------------------------------

function widget:IsAbove(x,y)
	return blockInput
end

function widget:MousePress(x,y,button)
	return blockInput
end

function widget:MouseRelease(x,y,button)
	return blockInput
end

function widget:MouseMove(x,y,dx,dy,button)
	return blockInput
end

function widget:MouseWheel(up,value)
	return blockInput
end

function widget:KeyPress(key, mods, isRepeat, label, unicode)
	return blockInput
end

function widget:KeyRelease()
	return blockInput
end

--------------------------------------------------------------------------
--------------------------------------------------------------------------

local function SetGameInputBlock(newBlock)
	blockInput = newBlock
end

function widget:Initialize()
	WG.SetGameInputBlock = SetGameInputBlock
end

