--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "Chili Visual Novel",
    desc      = "Displays pink-haired anime babes",
    author    = "KingRaptor (L.J. Lim)",
    date      = "2016.05.20",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
  }
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function GetDirectory(filepath)
    return filepath and filepath:gsub("(.*/)(.*)", "%1")
end

local function SplitString(str, sep)
  local sep, fields = sep or ":", {}
  local pattern = string.format("([^%s]+)", sep)
  string.gsub(str, pattern, function(c) fields[#fields+1] = c end)
  return fields
end

-- support for parent directory syntax
local function MakePath(entries, endSlash)
  local toBuild = {}
  for i=1,#entries do
    local entry = entries[i]
    local items = SplitString(entry, "/")
    for j=1,#items do
      local item = items[j]
      if item == ".." then
        toBuild[#toBuild] = nil
      else
        toBuild[#toBuild + 1] = item
      end
    end
  end
  local ret = table.concat(toBuild, "/")
  if endSlash then ret = ret .. "/" end
  return ret
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

assert(debug)
local source = debug and debug.getinfo(1).source
local DIR = GetDirectory(source)

local config = VFS.Include(MakePath({DIR, "..", "Configs/vn_config.lua"}, false))
config.VN_DIR = MakePath({DIR, "..", "..", config.VN_DIR}, true)

local BG_BLACK = string.sub(DIR, 1, -9) .. "Images/vn/bg_black.png"
local BG_WHITE = string.sub(DIR, 1, -9) .. "Images/vn/bg_white.png"

local Chili
local Window
local Panel
local Button
local StackPanel
local ScrollPanel
local Image
local Label
local TextBox
local screen0

-- Chili elements
local mainWindow
local textPanel
local textbox, nameLabel
local nvlPanel, nvlStack
local portraitPanel, portrait
local background, backgroundBlack, overlay
local menuButton, menuStack
local buttonSave, buttonLoad, buttonLog, buttonQuit
local logPanel
local panelChoiceDialog

local timer = Spring.GetTimer()
--//=============================================================================

options_path = 'Settings/HUD Panels/Visual Novel'
options = {
  textSpeed = {
    name = "Text Speed",
    type = 'number',
    min = 0,
    max = 100,
    step = 5,
    value = 30,
    desc = 'Characters/second (0 = instant)',
  },
  waitTime = {
    name = "Wait time",
    type = 'number',
    min = 0,
    max = 4,
    step = 0.5,
    value = 1.5,
    desc = 'Wait time at end of each script line before auto-advance',
  },
}

local waitTime = nil -- tick down in Update()
local waitAction  -- will we actually care what this is?

-- {[1]} = {target = target, type = type, startX = x, startY = y, endX = x, endY = y, startAlpha = alpha, endAlpha = alpha, time = time, timeElapsed = time ...}}
-- every Update(dt), increment time by dt and move stuff accordingly
-- elements are removed from table once timeElapsed >= time
local animations = {}
local nvlControls = {}

-- Stuff that is defined in script and should not change during play
local defs = {
  storyInfo = {}, -- entire contents of story_info.lua
  storyDir = "",
  scripts = {}, -- {[scriptName] = {list of actions}}
  characters = {},  -- {[charactername] = {data}}
  images = {} -- {[image name] = {data}}
}

-- Variable stuff (anything that needs save/load support)
local data = {
  storyID = nil,
  images = {},  -- {[id] = Chili.Image}
  subscreens = {},
  vars = {},
  textLog = {}, -- {[1] = <AddText args table>, [2] = ...}
  backgroundFile = "",  -- path as specified in script (before prepending dir)
  portraitFile = "",  -- ditto
  currentText = nil, -- the full line (textbox will not contain the full line until text writing has reached the end)
  currentMusic = nil,  -- PlayMusic arg
  nvlMode = false,
  nvlText = {},  -- {[1] = <AddText args table>, [2] = ...}

  --currentScript = nil,
  --currentLine = 1,
  scriptCallstack = {}
}

scriptFunctions = {}  -- not local so script can access it

local imagesToPreload = {
  BG_BLACK, BG_WHITE
}

local menuVisible = false
local uiHidden = false
local autoAdvance = false
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function CountElements(tbl)
  local num = 0
  for i,v in pairs(tbl) do
    num = num + 1
  end
  return num
end

local function GetFilePath(givenPath)
  if givenPath == nil then
    return ""
  end

  return MakePath({defs.storyDir, givenPath})
end

-- This forces the background to the back after toggling GUI (so bg doesn't draw in front of UI elements)
local function ResetMainLayers(force)
  backgroundBlack:SetLayer(99)
end

local function PreloadImage(file)
  file = GetFilePath(file)
  imagesToPreload[#imagesToPreload + 1] = file
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function AdvanceScript() end  -- redefined in a bit

function PreloadImagesInScript(scriptName)
  for i=1,#defs.scripts[scriptName] do
    local item = defs.scripts[scriptName][i]
    local file = nil
    
    if type(item) == "function" then
      -- do nothing
    elseif item[1] == "AddImage" then
      local args = item[2]
      local imageDef = defs.images[args.defID] and Spring.Utilities.CopyTable(defs.images[args.defID], true) or {}
      file = imageDef.file or args.file
    elseif item[1] == "AddBackground" then
      local argsType = type(args)
      file = (argsType == 'string' and args) or (argsType == 'table' and args.file)
    end
    
    if file then
      PreloadImage(file)
    end
  end
end

local function GetCurrentScriptAndLine()
  local currentStackItem = data.scriptCallstack[#data.scriptCallstack]
  if currentStackItem == nil then
    --Spring.Log(widget:GetInfo().name, LOG.WARNING, "No script loaded #54")
    return nil, 1
  end
  local currentScript = currentStackItem[1]
  local line = currentStackItem[2]
  return currentScript, line
end

-- returns the script command for the current script at the specified line (or the current line if no line is specified)
local function GetScriptLineItem(script, line)
  local currentScript, currentLine = GetCurrentScriptAndLine()
  script = script or currentScript
  line = line or currentLine
  if not script then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "Attempt to get item for nonexistent script")
    return nil
  elseif not defs.scripts[script] then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "Attempt to get item for invalid script " .. script)
    return nil
  end
  local item = defs.scripts[currentScript][currentLine]
  return item
end

local function PushScriptStack(newScript, startingLine)
  data.scriptCallstack[#data.scriptCallstack + 1] = {newScript, startingLine or 1}
  PreloadImagesInScript(newScript)
end

local function PopScriptStack()
  if #data.scriptCallstack == 1 then
    Spring.Log(widget:GetInfo().name, LOG.WARNING, "Reached bottom of script call stack")
    return false
  elseif #data.scriptCallstack <= 0 then
    Spring.Log(widget:GetInfo().name, LOG.WARNING, "No script loaded, cannot pop stack")
    return false
  end
  data.scriptCallstack[#data.scriptCallstack] = nil
  return true
end

-- Runs the action for the current line in the script
local function PlayScriptLine(line)
  if (data.storyID == nil) then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "No story loaded")
    return
  end
  
  local item = GetScriptLineItem(nil, line)
  if item then
    if type(item) == 'function' then
      item()
      AdvanceScript(false)
    else
      local action = item[1]
      local args = item[2]
      if (type(args) == 'table') then
        args = Spring.Utilities.CopyTable(item[2], true)
      elseif args == nil then
        args = {}
      end
      scriptFunctions[action](args)
      if config.autoAdvanceActions[action] and (type(args) ~= 'table' or (not args.wait)) then
        AdvanceScript(false)
      end
      if (action ~= "AddText" and type(args) == 'table' and args.wait) then
        waitTime = args.wait or options.waitTime.value
      end
      
      -- automatically hide text box while in wait mode, show otherwise
      if not data.nvlMode then
        if (action == 'AddText' or (not waitTime)) and textPanel.hidden then
          textPanel:SetVisibility(true)
          ResetMainLayers()
        elseif not textPanel.hidden and (type(waitTime) == 'number' and (waitTime > 0)) then
          textPanel:SetVisibility(false)
        end
      end
    end
  elseif line > #defs.scripts[GetCurrentScriptAndLine()] then
    if PopScriptStack() then
      AdvanceScript()
    else
      -- nothing to do
    end
  end
end

local function StartScript(scriptName)
  if mainWindow.hidden then
    mainWindow:SetVisibility(true)
    mainWindow:SetLayer(1)
  end
  ResetMainLayers()
  data.scriptCallstack = {{scriptName, 1}}
  PreloadImagesInScript(scriptName)
  PlayScriptLine()
end

local function ResizeNVLEntryPanel(textControl, nvlControlsEntry)
    textControl:Invalidate()
    local panel = nvlControlsEntry.panel
    local height = textControl.height + panel.padding[2] + panel.padding[4]
    if (panel.height < height) then
      panel:Resize(nil, height, true, true)
      panel:SetVisibility(false)  -- force refresh
      panel:SetVisibility(true)
      --Spring.Echo("force resizing", textControl.height, panel.height)
    end
end

-- Text scrolling behaviour, advance to next script line at end if so desired
local function AdvanceText(time, toEnd)
  local nvlControlsEntry = nvlControls[#nvlControls]
  local nvl = false
  local textControl = textbox
  if data.nvlMode and nvlControlsEntry then
    textControl = nvlControlsEntry.text
    nvl = true
  end
  
  local wantedLength = string.len(data.currentText or "")
  local currLength = string.len(textControl.text or "")
  if currLength < wantedLength then
    local oldHeight = textControl.height
    if (toEnd) then
      textControl:SetText(data.currentText)
      textControl:UpdateLayout()
    else
      local charactersToAdd = math.floor(time * options.textSpeed.value + 0.5)
      local newLength = currLength + charactersToAdd
      if newLength > wantedLength then newLength = wantedLength end
      local newText = string.sub(data.currentText, 1, newLength)
      textControl:SetText(newText)
    end
    if nvl then
      ResizeNVLEntryPanel(textControl, nvlControlsEntry)
    end
  else
    if toEnd then
      AdvanceScript(true)
    else
      if autoAdvance then
        waitTime = waitTime or options.waitTime.value
      else
        local item = GetScriptLineItem()
        if item and type(item) ~= "function" then
          local args = item[2]
          if (type(args) == 'table') and args.wait == false then
            waitTime = waitTime or 0
          end
        end
      end
    end
  end
end

local function ShakeImage(anim, proportion)
  local target = anim.image and data.images[anim.image] or background
  anim.baseX = anim.baseX or target.x
  anim.baseY = anim.baseY or target.y
  anim.offsetX = anim.offsetX or (math.random() > 0.5 and 1 or -1)
  anim.offsetY = anim.offsetY or (math.random() > 0.5 and 1 or -1)
  
  if (proportion >= 1) then	-- animation end, reset to normal
    target:SetPos(anim.baseX, anim.baseY)
    return
  end
  proportion = 0.2 + proportion * 0.8
  
  local strengthX = anim.strengthX or 32
  local strengthY = anim.strengthY or 24
  
  -- invert direction each frame
  local newOffsetX, newOffsetY = 0, 0
  if strengthX > 0 then
    newOffsetX = math.random(1, strengthX) * ((anim.offsetX > 1) and -1 or 1)
  end
  if strengthY > 0 then
    newOffsetY = math.random(1, strengthY) * ((anim.offsetY > 1) and -1 or 1)
  end
  newOffsetX = math.floor(newOffsetX * (1 - proportion) + 0.5)
  newOffsetY = math.floor(newOffsetY * (1 - proportion) + 0.5)
  anim.offsetX = newOffsetX
  anim.offsetY = newOffsetY
  target:SetPos(anim.baseX + newOffsetX, anim.baseY + newOffsetY)
end

-- Advance animations a frame
local function AdvanceAnimations(dt)
  local toRemove = {}
  for i=1, #animations do
    local anim = animations[i]
    local done = false
    local target = anim.image and data.images[anim.image]
    if anim.image == "background" then
      target = background
    elseif anim.image == "overlay" then
      target = overlay
    end
    local color, color2
    
    anim.timeElapsed = (anim.timeElapsed or 0) + dt
    if anim.timeElapsed >= anim.time then
      anim.timeElapsed = anim.time
      done = true
    end
    
    -- do animations
    local proportion = anim.timeElapsed/anim.time
    if (proportion <= 0) then
      proportion = 0  -- animation at zero point, do nothing for now
    elseif (anim.type == "shake") then
      ShakeImage(anim, proportion)
    elseif target == nil then
      toRemove[#toRemove+1] = i
    else
      if (target.classname == "label") or (target.classname == "textbox") then
        target.font.color = target.font.color or {1,1,1,1}
        target.font.color2 = target.font.color2 or Spring.Utilities.CopyTable(target.font.color) or {1, 1, 1, 1}
        color = target.font.color
        color2 = target.font.color2
      else
        target.color = target.color or {1,1,1,1}
        target.color2 = target.color2 or Spring.Utilities.CopyTable(target.color) or {1,1,1,1}
        color = target.color
        color2 = target.color2
      end
      
      local dissolve = anim.type == "dissolve"
      
      anim.startX = anim.startX or target.x
      anim.startY = anim.startY or target.y
      anim.startWidth = anim.startWidth or target.width
      anim.startHeight = anim.startHeight or target.height
      anim.startColor = anim.startColor or target.color or {1, 1, 1, 1}
      anim.startAlpha = anim.startAlpha or (target.color and target.color[4]) or 1
      if dissolve then
        anim.startAlpha2 = anim.startAlpha2 or (target.color and 1 - target.color[4]) or 0
        target.file2 = target.oldFile
      end
      
      local newX, newY, newW, newH
      if anim.endX then
        newX = math.floor(anim.endX * proportion + anim.startX * (1 - proportion) + 0.5)
      end
      if anim.endY then
        newY = math.floor(anim.endY * proportion + anim.startY * (1 - proportion) + 0.5)
      end
      if anim.endWidth then
        newW = math.floor(anim.endWidth * proportion + anim.startWidth * (1 - proportion) + 0.5)
      end
      if anim.endHeight then
        newH = math.floor(anim.endHeight * proportion + anim.startHeight * (1 - proportion) + 0.5)
      end
      
      if anim.endColor then
        for i=1,4 do
          color[i] = anim.endColor[i] * math.sin(proportion * math.pi * 0.5) + anim.startColor[i] * math.cos(proportion * math.pi * 0.5)
        end
        if (dissolve) then
          for i=1,4 do
            color2[i] = anim.endColor[i] * math.cos(proportion * math.pi * 0.5) + anim.startColor[i] * math.sin(proportion * math.pi * 0.5)
          end
        end
      elseif anim.endAlpha then
        color[4] = anim.endAlpha * math.sin(proportion * math.pi * 0.5) + anim.startAlpha * math.cos(proportion * math.pi * 0.5)
        if dissolve then
          color2[4] = anim.endAlpha * math.cos(proportion * math.pi * 0.5) + anim.startAlpha * math.sin(proportion * math.pi * 0.5)
        end
      end
      target:SetPos(newX, newY, newW, newH)
      target:Invalidate()
    end
    
    if done then
      if color then
        if anim.endColor then
          for i=1,4 do
            color[i] = anim.endColor[i]
          end
        end
        color[4] = anim.endAlpha or color[4]
      end
      toRemove[#toRemove+1] = i
    end
  end
  for i=#toRemove,1,-1 do
    local anim = animations[toRemove[i]]
    local target = anim.image and data.images[anim.image] or background
    if anim.type == "dissolve" then
      target.file2 = nil
      target.color2 = nil
    end
    table.remove(animations, toRemove[i])
    if (anim.removeTargetOnDone) then
      data.images[target.id] = nil
      target:Dispose()
    else
      target:Invalidate()
    end
  end
end

-- Go to next line in script
AdvanceScript = function(skipAnims)
  --Spring.Echo("Advancing script")
  --AdvanceText(0, true)
  if panelChoiceDialog ~= nil then
    return
  end
  waitTime = nil
  if skipAnims then
    AdvanceAnimations(99999)
  end
  local currentStackItem = data.scriptCallstack[#data.scriptCallstack]
  currentStackItem[2] = currentStackItem[2] + 1
  PlayScriptLine(currentStackItem[2])
end


local function RemoveChoiceDialogPanel()
  if (panelChoiceDialog == nil) then return end
  panelChoiceDialog:Dispose()
  panelChoiceDialog = nil
  ResetMainLayers()
end

local function CreateChoiceDialogPanel(choices)
  if (panelChoiceDialog ~= nil) then
    RemoveChoiceDialogPanel()
  end
  panelChoiceDialog = Panel:New{
    parent = mainWindow,
    name = "vn_panelChoiceDialog",
    x = (mainWindow.width - DIALOG_PANEL_WIDTH)/2,
    y = "40%",
    height = #choices * DIALOG_BUTTON_HEIGHT + 10,
    width = DIALOG_PANEL_WIDTH,
  }
  panelChoiceDialog:SetLayer(1)
  
  local stackChoiceDialog= StackPanel:New{
    parent = panelChoiceDialog;
    name = "vn_stackChoiceDialog",
    orientation = 'vertical',
    autosize = false,
    resizeItems = true,
    centerItems = false,
    x = 0, y = 0, right = 0, bottom = 0
  }
  
  for i=1,#choices do
    local choice = choices[i]
    local text = choice.text
    local func = choice.action
    
    Button:New {
      parent = stackChoiceDialog,
      caption = text,
      width = "100%",
      height = DIALOG_BUTTON_HEIGHT,
      font = {size = DIALOG_FONT_SIZE},
      OnClick = { function() RemoveChoiceDialogPanel(); func(); ResetMainLayers(); end },
    }
  end
end

-- Register an animation to play
local function AddAnimation(args, image)
  local anim = args.animation
  anim.image = args.id
  anim.time = anim.time or 1
  image.color = args.startColor or image.color or {1, 1, 1, 1}
  
  if anim.type == "dissolve" and (not anim.startColor) then
    anim.startAlpha = anim.startAlpha or 0
  end
  if anim.type == "dissolve" and (not anim.endColor) then
    anim.endAlpha = anim.endAlpha or 1
  end
  
  image.color[4] = anim.startAlpha or 1
  
  anim.startX = anim.startX or args.x
  anim.startY = anim.startY or args.y
  
  if (type(anim.startX) == 'string') then
    anim.startX = image.parent.width * tonumber(anim.startX)
  end
  if (type(anim.startY) == 'string') then
    anim.startY = image.parent.width * tonumber(anim.startY)
  end
  if (type(anim.endX) == 'string') then
    anim.endX = image.parent.width * tonumber(anim.endX)
  end
  if (type(anim.endY) == 'string') then
    anim.endY = image.parent.width * tonumber(anim.endY)
  end
  
  anim.timeElapsed = anim.delay and -anim.delay or 0
  
  animations[#animations + 1] = Spring.Utilities.CopyTable(anim, true)
end

local function SetPortrait(image)
  if not portrait then return end
  image = image and GetFilePath(image) or BLANK_IMAGE_PATH
  portrait.file = image
  portrait:Invalidate()
end

local function AddNVLTextBox(name, text, size, instant)
  local panel = Panel:New {
    parent = nvlStack,
    width="100%",
    height = 36,
    backgroundColor = {1, 1, 1, 0},
    --autosize = instant,
  }

  local textBox = TextBox:New {
    parent = panel,
    text = text,
    align = "left",
    x = NVL_NAME_WIDTH + 4 + 4 + 8,
    y = 4,
    right = 4,
    height = 32,
    font    = {
      size = size
    }
  }
  
  local name = Label:New {
    parent = panel,
    align = "left",
    caption = name or "",  -- todo i18n
    x = 4,
    y = 4,
    width = NVL_NAME_WIDTH,
    height = 32,
    font    = {
      size = DEFAULT_FONT_SIZE;
      shadow = true;
      color = speaker and speaker.color
    }
  }
  
  --textBox:UpdateLayout()
  
  -- hax to fix panel height
  if instant then
    local font = textBox.font
    local padding = textBox.padding
    local width  = textBox.width - padding[1] - padding[3]
    local height = textBox.height - padding[2] - padding[4]
    if textBox.autoHeight then
      height = 1e9
    end
    local wrappedText = font:WrapText(textBox.text, width, height)
    local textHeight,textDescender,numLines = font:GetTextHeight(wrappedText)
    textHeight = textHeight-textDescender

    if (numLines>1) then
      textHeight = numLines * font:GetLineHeight()
    else
      --// AscenderHeight = LineHeight w/o such deep chars as 'g','p',...
      textHeight = math.min( math.max(textHeight, font:GetAscenderHeight()), font:GetLineHeight())
    end
    local panelHeight = math.max(textHeight + 12, 32)
    panel.height = panelHeight
    panel:Invalidate()
  end
  
  --nvlStack:AddChild(panel)
  nvlControls[#nvlControls + 1] = {panel = panel, name = name, text = textBox}
  
  if not instant then
    textBox:SetText("")
  else
    --ResizeNVLEntryPanel(textBox, nvlControls[#nvlControls])
  end
  
  return panel, name, textBox
end

local function SubstituteVars(str)
  return string.gsub(str, "%{%{(.-)%}%}", function(a) return data.vars[a] or "" end)
end

local function AddText(args)
  -- TODO get i18n string
  local instant = args.instant or options.textSpeed.value <= 0
  if Spring.GetPressedKeys()[306] then  -- ctrl
    instant = true
  end
  args.text = SubstituteVars(args.text)
  
  if (args.append) then
    args.text = (data.currentText or "") .. args.text
  end
  data.currentText = args.text
  
  local speaker = {}
  local speakerName = args.name
  if (args.speakerID) then
    speaker = defs.characters[args.speakerID]
    speakerName = speakerName or speaker.name or ""
  end
  
  args.size = args.size or DEFAULT_FONT_SIZE
  
  local textControl = textbox
  local label = nameLabel
  if data.nvlMode then
    if append then
      local lastNVLControl = nvlControls[#nvlControls] or AddNVLTextBox(args.name or speaker.name, args.text, args.size, instant)
      label = lastNVLControl.name
      textControl = lastNVLControl.text
    else
      _,label,textControl = AddNVLTextBox(args.name or speaker.name, args.text, args.size, instant)
    end
  end
  
  if args.size ~= textControl.font.size then
    textControl.font.size = args.size
    --textBox:Invalidate()
  end
  
  if instant then
    textControl:SetText(args.text)
  elseif (not args.append) then
    textControl:SetText("")
  end
  
  if (args.speakerID) then
    local color = speaker.color
    label.font.color = color
    label:SetCaption(speakerName)
    if args.setPortrait ~= false then
      SetPortrait(speaker.portrait)
    end
  else
    label:SetCaption(args.name or "")
    if args.setPortrait ~= false then
      SetPortrait(nil)
    end
  end
  label:Invalidate()
  
  if not args.noLog then
    if args.append and #data.textLog > 0 then
      data.textLog[#data.textLog] = args
    else
      data.textLog[#data.textLog + 1] = args
    end
  end
  if data.nvlMode then
    if args.append and #data.textLog > 0 then
      data.nvlText[#data.nvlText] = args
    else
      data.nvlText[#data.nvlText + 1] = args
    end
  end
  
  if instant and (args.wait == false) then
    AdvanceScript()
  end
end

local function AddImage(args, isText)
  if not args.id then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "Attempting to add image with nil id")
    return
  end
  local image = data.images[args.id]
  if image then
    Spring.Log(widget:GetInfo().name, LOG.WARNING, "Image " .. args.id .. " already exists, modifying instead")
    return scriptFunctions.ModifyImage(args)
  end
  
  local imageDef = defs.images[args.defID] and Spring.Utilities.CopyTable(defs.images[args.defID], true) or {}
  args = Spring.Utilities.MergeTable(args, imageDef, false)
  
  args.x = args.x or 0
  args.y = args.y or 0
  args.anchor = args.anchor or {0, 0}
  
  if isText then
    args.size = args.size or DEFAULT_FONT_SIZE
    image = Label:New {
      id = args.id,
      parent = background,
      caption = SubstituteVars(args.text),
      height = args.height or (args.size + 8),
      width = args.width,
      align = args.align,
      valign = args.valign,
      autosize = (args.autosize == nil and true) or false,
      savespace = false,
      font = {size = args.size, color = args.color, shadow = args.shadow}
    }
  else
    image = Image:New{
      id = args.id,
      parent = background,
      file = GetFilePath(args.file),
      height = args.height,
      width = args.width,
    }
  end
  
  if (type(args.x) == 'string') then
    args.x = image.parent.width * tonumber(args.x)
  end
  if (type(args.y) == 'string') then
    args.y = image.parent.height * tonumber(args.y)
  end
  image.x = args.x - args.anchor[1]
  image.y = args.y - args.anchor[2]
  image.anchor = args.anchor
  image.color = args.color or image.color
  
  if (args.animation) then
    AddAnimation(args, image)
  end
  
  data.images[args.id] = image
  if (args.layer) then
    image:SetLayer(args.layer)
    image.layer = args.layer
  else
    image.layer = CountElements(data.images)
  end
  
  image:Invalidate()
end

local function RemoveImage(id)
  local image = data.images[id]
  if not image then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "Attempt to remove nonexistent image " .. id)
    return
  end
  image:Dispose()
  data.images[id] = nil
end

-- disposes of existing stuff
local function Cleanup()
  for imageID, image in pairs(data.images) do
    image:Dispose()
  end
  if nvlPanel.visible and nvlPanel.parent then
    nvlPanel:SetVisibility(false)
  end
  scriptFunctions.ClearNVL()
  animations = {}
  --for screenID, screen in pairs(data.subscreens) do
  --  screen:Dispose()
  --end
  
  background.file = BG_BLACK
  background.color = {1,1,1,1}
  overlay.file = BG_WHITE
  overlay.color = {0,0,0,0}
  background:Invalidate()
  overlay:Invalidate()
  
  scriptFunctions.StopMusic()
  SetPortrait(nil)
  textbox:SetText("")
  nameLabel:SetCaption("")
  RemoveChoiceDialogPanel()
  
  data.images = {}
  data.subscreens = {}
  data.vars = {}
  data.textLog = {}
  data.backgroundFile = ""
  data.portraitFile = ""
  data.currentText = nil
  data.currentMusic = nil
  data.nvlMode = false
  data.scriptCallstack = {}
end

local function CloseStory()
  Cleanup()
  data.storyID = nil
  defs = {
    storyInfo = {},
    storyDir = "",
    scripts = {},
    characters = {},
    images = {}
  }
  if (not mainWindow.hidden) then
    mainWindow:SetVisibility(false)
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

scriptFunctions = {
  AddBackground = function(args)
    local argsType = type(args)
    local image = (argsType == 'string' and args) or (argsType == 'table' and args.file)
    background.oldFile = background.file
    background.file = GetFilePath(image)
    data.backgroundFile = image
    background.color = args.color or background.color
    if (argsType == 'table' and args.animation) then
      args.id = "background"
      AddAnimation(args, background)
    end
    background:Invalidate()
  end,
  
  AddImage = function(args)
    AddImage(args, false)
  end,
  
  AddText = function(args)
    AddText(args)
  end,
  
  AddTextAsImage = function(args)
    AddImage(args, true)
  end,
  
  CallScript = function(args)
    local argsType = type(args)
    local script = (argsType == 'string' and args) or (argsType == 'table' and args.script)
    local line = (argsType == 'table' and args.line) or 1
    PushScriptStack(script, line)
    PlayScriptLine()
  end,
  
  ClearNVL = function()
    for i=1,#nvlControls do
       local controls = nvlControls[i]
       controls.panel:Dispose()
    end
    nvlControls = {}
    data.nvlText = {}
  end,
  
  ClearText = function()
    nameLabel:SetCaption("")
    nameLabel:Invalidate()
    textbox:SetText("")
    data.currentText = nil
    SetPortrait(nil)
  end,
  
  ChoiceDialog = function(args)
    CreateChoiceDialogPanel(args)
  end,
  
  CustomAction = function(args)
    local argsType = type(args)
    local func = (argsType == 'function' and args) or (argsType == 'table' and args.func)
    func()
  end,
  
  Exit = function()
    mainWindow:SetVisibility(false)
    if WG.Music then
      --WG.Music.StartTrack()
    end
  end,
  
  JumpScript = function(script)
    StartScript(script)
  end,
  
  ModifyImage = function(args)
    local image = data.images[args.id]
    if args.id == "background" then
      image = background
    elseif args.id == "overlay" then
      image = overlay
    elseif not image then
      Spring.Log(widget:GetInfo().name, LOG.ERROR, "Attempt to modify nonexistent image " .. args.id)
      return
    end
    
    local imageDef = defs.images[args.defID] and Spring.Utilities.CopyTable(defs.images[args.defID], true) or {anchor = {0, 0}}
    args = Spring.Utilities.MergeTable(args, imageDef, false)
    
    if args.file then
      image.oldFile = image.file
      image.file = GetFilePath(args.file)
    end
    
    if (type(args.x) == 'string') then
      args.x = screen0.width * tonumber(args.x)
    end
    if (type(args.y) == 'string') then
      args.y = screen0.height * tonumber(args.y)
    end
    local anchor = args.anchor or image.anchor or {0, 0}
    image.anchor = anchor
    
    local wantedX, wantedY
    if args.x then
      wantedX = args.x - anchor[1]
    end
    if args.y then
      wantedY = args.y - anchor[2]
    end
    
    image:SetPos(wantedX, wantedY, args.width, args.height)
    
    if args.color then
      image.color = args.color
      image:Invalidate()
    end
    
    if (args.animation) then
      AddAnimation(args, image)
    end
  end,
  
  PlayMusic = function(args)
    local argsType = type(args)
    local argsTable = argsType == 'table' and args or {}
    local track = (argsType == 'string' and args) or (argsTable.track)
    if not track then return end
    
    local trackFull = GetFilePath(track)
    local intro = (argsTable.intro and GetFilePath(argsTable.intro)) or trackFull
    local loop = (argsTable.loop ~= false) or true
    local volume = argsTable.volume
    
    if loop and WG.Music and WG.Music.StartLoopingTrack then
      WG.Music.StartLoopingTrack(intro, trackFull)
    elseif WG.Music then
      WG.Music.StartTrack(trackFull)
    elseif WG.MusicHandler then -- chobby music player
      WG.MusicHandler.LoopTrack(trackFull, intro, volume)
    else
      Spring.StopSoundStream()
      Spring.PlaySoundStream(trackFull, 1)
    end
    data.currentMusic = (argsType == 'table') and args or {track = track}
  end,
  
  PlaySound = function(args)
    if(type(args) == 'table') then
      Spring.PlaySoundFile(GetFilePath(args.file), args.volume or 1, args.channel)
    else
      Spring.PlaySoundFile(GetFilePath(args))
    end
  end,
  
  -- TODO: implement separate hideImage?
  RemoveImage = function(args)
    local argsType = type(args)
    local id = (argsType == 'string' and args) or (argsType == 'table' and args.id)
    RemoveImage(id)
  end,
  
  SetPortrait = function(args)
    local file = (type(args) == 'string' and args) or (type(args) == 'table' and args.file)
    SetPortrait(file)
  end,
  
  SetNVLMode = function(args)
    local bool = (type(args) == 'boolean' and args) or (type(args) == 'table' and args.mode)
    if (bool == data.nvlMode and not (type(args) == 'table' and args.force)) then return end
    data.nvlMode = bool
    if not uiHidden then
      if (bool) then
        textPanel:SetVisibility(false)
        nvlPanel:SetVisibility(true)
      else
        textPanel:SetVisibility(true)
        nvlPanel:SetVisibility(false)
      end
      ResetMainLayers()
    end
  end,
  
  SetVars = function(args)
    for i,v in pairs(args) do
      data.vars[i] = v
    end
  end,
  
  ShakeScreen = function(args)
    args.type = "shake"
    args.id = "background"
    AddAnimation({animation = args}, background)
  end,
  
  StopMusic = function(args)
    if WG.Music and WG.Music.StopTrack then
      WG.Music.StopTrack(args and (not args.continue) or true)
    elseif WG.MusicHandler then
      WG.MusicHandler.StopTrack()
    else
      Spring.StopSoundStream()
    end
    data.currentMusic = nil
  end,
  
  UnsetVars = function(args)
    for i=1,#args do
       data.vars[args[i]] = nil
    end
  end,
  
  Wait = function(args)
    local time = (type(args) == 'number' and args) or (type(args) == 'table' and args.time)
    if time then
      waitTime = time
    end
  end,
}

-- Show/hide the menu buttons
local function ToggleMenu()
  if menuVisible then
    menuStack:SetVisibility(false)
  else
    menuStack:SetVisibility(true)
  end
  ResetMainLayers()
  menuVisible = not menuVisible
end

local function ToggleUI()
  if uiHidden then
    if data.nvlMode then
      nvlPanel:SetVisibility(true)
    else
      textPanel:SetVisibility(true)
    end
    menuButton:SetVisibility(true)
    if menuVisible then
      menuStack:SetVisibility(true)
    end
    if panelChoiceDialog ~= nil then
      panelChoiceDialog:SetVisibility(true)
    end
  else
    if data.nvlMode then
      nvlPanel:SetVisibility(false)
    else
      textPanel:SetVisibility(false)
    end
    menuButton:SetVisibility(false)
    if menuVisible then
      menuStack:SetVisibility(false)
    end
    if panelChoiceDialog ~= nil then
      panelChoiceDialog:SetVisibility(false)
    end
  end
  ResetMainLayers(true)
  uiHidden = not uiHidden
end

local function RemoveLogPanel()
  if (logPanel == nil) then return end
  mainWindow:RemoveChild(logPanel)
  logPanel:Dispose()
  logPanel = nil
  ResetMainLayers()
end

-- Dialog log panel
local function CreateLogPanel()
  -- already have log panel, close it
  if (logPanel ~= nil) then
    RemoveLogPanel()
    return
  end
  
  logPanel = Panel:New {
    parent = mainWindow,
    name = "vn_logPanel",
    width = "80%",
    height = "80%",
    x = "10%",
    y = "10%",
    children = {
      Label:New {
        caption = "LOG",
        width = 64,
        height = 16,
        y = 4,
        x = 64,
        align = "center"
      }
    }
  }
  logPanel:SetLayer(1)
  local logScroll = ScrollPanel:New {
    parent = logPanel,
    name = "vn_logScroll",
    x = 0,
    y = 24,
    width = "100%",
    bottom = 32,
  }
  --[[
  local logStack = StackPanel:New {
    parent = logscroll,
    name = "vn_logstack",
    orientation = 'vertical',
    autosize = true,
    resizeItems = true,
    centerItems = false,
    width = "100%",
    height = 500,
  }
  ]]--
  local logButtonClose = Button:New {
    parent = logPanel,
    name = "vn_logButtonClose",
    caption = "Close",
    right = 4,
    bottom = 4,
    width = 48,
    height = 28,
    OnClick = { function()
        RemoveLogPanel()
      end
    }
  }
  
  local count = 0
  for i=#data.textLog,#data.textLog-50,-1 do
    count = count + 1
    local entry = data.textLog[i]
    if (not entry) then
      break
    end
    local speaker = entry.speakerID and defs.characters[entry.speakerID]
    local color = speaker and speaker.color or nil
      
    logScroll:AddChild(Panel:New {
      width="100%",
      height = LOG_PANEL_HEIGHT,
      y = (LOG_PANEL_HEIGHT + 4)*(count-1),
      children = {
        Label:New {
          align = "left",
          caption = entry.name or (speaker and speaker.name) or "",  -- todo i18n
          x = 4,
          y = 4,
          right = 4,
          height = 20,
          font    = {
            size = 16;
            shadow = true;
            color = speaker and speaker.color
          },
        },
        TextBox:New {
          text = entry.text,
          align = "left",
          x = 4,
          y = 28,
          right = 4,
          height = 32,
        }
      },
    })
  end
end

local function GetDefs()
  return defs
end

local function GetData()
  return data
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- save/load handling

local function ImageToTable(image)
  local imgTable = {
    id = image.id,
    file = image.file,
    height = image.height,
    width = image.width,
    x = image.x,
    y = image.y,
    anchor = image.anchor,
    layer = image.layer,
    color = image.color
  }
  return imgTable
end

local function TableToImage(table)
  local image = Image:New {
    id = table.id,
    file = table.file,
    height = table.height,
    width = table.width,
    x = table.x,
    y = table.y,
    anchor = table.anchor,
    layer = table.layer,
    color = table.color,
  }
  return image
end

local function SaveGame(filename)
  filename = filename or "save.lua"
  local saveData = Spring.Utilities.CopyTable(data, true)
  
  -- force all image animations forward
  AdvanceAnimations(99999)
  
  -- we can't save userdata so change all the images to tables first
  local imagesSaved = {}
  for imageID, image in pairs(saveData.images) do
    imagesSaved[imageID] = ImageToTable(image)
  end
  saveData.imagesSaved = imagesSaved
  saveData.images = nil
  
  WG.SaveTable(saveData, defs.storyDir, filename, nil, {concise = true, prefixReturn = true, endOfFile = true})
  Spring.Log(widget:GetInfo().name, LOG.INFO, "Saved game to " .. filename)
end

local function LoadGame(filename)
  filename = filename or "save.lua"
  local path = defs.storyDir .. filename
  if not VFS.FileExists(path) then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "Unable to find save file " .. filename)
    return
  end
  
  AdvanceAnimations(99999)
  Cleanup()
  
  data = VFS.Include(path)
  scriptFunctions.AddBackground({file = data.backgroundFile, wait = true})
  scriptFunctions.SetNVLMode({mode = data.nvlMode, force = true})
  
  -- readd images from saved data
  data.images = {}
  for imageID, imageSaved in pairs(data.imagesSaved) do
    local image = TableToImage(imageSaved)
    background:AddChild(image)
    data.images[imageID] = image
  end
  for imageID, image in pairs(data.images) do
    image:SetLayer(image.layer)
  end
  data.imagesSaved = nil
  
  if data.nvlMode then
    for i=1,#data.nvlText do
      local text =  Spring.Utilities.CopyTable(data.nvlText[i], true)
      text.noLog = true
      text.append = false
      text.instant = true
      text.wait = true
      scriptFunctions.AddText(text)
    end
  else
    if data.currentText then
      local lastText = data.textLog[#data.textLog]
      if type(lastText) == 'table' then
        lastText = Spring.Utilities.CopyTable(lastText, true)
        lastText.noLog = true
        lastText.append = false
        lastText.instant = true
        lastText.wait = true
        scriptFunctions.AddText(lastText)
      end
    end
  end
  scriptFunctions.PlayMusic({track = data.currentMusic, wait = true})
  
  RemoveChoiceDialogPanel()
  local scriptItem = GetScriptLineItem()
  if scriptItem and scriptItem[1] == "ChoiceDialog" then
    PlayScriptLine()
  end
  --for screenID, screen in pairs(data.subscreens) do
  --  mainWindow:AddChild(screen)
  --end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function LoadStory(storyID, dir)
  if (data.storyID ~= nil) then
    CloseStory()
  end
  
  defs.storyDir = MakePath({dir or config.VN_DIR, storyID}, true)
  local storyPath = defs.storyDir .. "story_info.lua"
  if not VFS.FileExists(storyPath, VFS.RAW_FIRST) then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "VN story " .. storyPath .. " does not exist")
    return
  end
  
  defs.storyInfo = VFS.Include(storyPath)
  defs.storyInfo.scripts = defs.storyInfo.scripts or {}
  for i=1,#defs.storyInfo.scripts do
    defs.storyInfo.scripts[i] = defs.storyDir .. defs.storyInfo.scripts[i]
  end
  local autoloadScripts = VFS.DirList(defs.storyDir .. "scripts", "*.lua", VFS.RAW_FIRST)
  for i=1,#autoloadScripts do
    defs.storyInfo.scripts[#defs.storyInfo.scripts + 1] = autoloadScripts[i]
  end
  data.storyID = storyID
  
  for _,path in ipairs(defs.storyInfo.scripts) do
    if VFS.FileExists(path, VFS.RAW_FIRST) then
      local loadedScripts = VFS.Include(path)
      for scriptName,data in pairs(loadedScripts) do
        defs.scripts[scriptName] = data
      end
    else
      -- warning/error message
    end
  end
  for _,charDefPath in ipairs(defs.storyInfo.characterDefs) do
    local path = defs.storyDir .. charDefPath
    if VFS.FileExists(path, VFS.RAW_FIRST) then
      local loadedCharDefs = VFS.Include(path)	--Spring.Utilities.json.decode(VFS.LoadFile(path, VFS.ZIP))
      for charName,data in pairs(loadedCharDefs) do
        defs.characters[charName] = data
      end
    else
      -- warning/error message
    end
  end
  for _,imagesPath in ipairs(defs.storyInfo.imageDefs) do
    local path = defs.storyDir .. imagesPath
    if VFS.FileExists(path, VFS.RAW_FIRST) then
      local imageDefs = VFS.Include(path)	--Spring.Utilities.json.decode(VFS.LoadFile(path, VFS.ZIP))
      for imageName,data in pairs(imageDefs) do
        defs.images[imageName] = data
      end
    else
      -- warning/error message
    end
  end
  
  mainWindow.caption = defs.storyInfo.name
  mainWindow:Invalidate()
  
  Spring.Log(widget:GetInfo().name, LOG.INFO, "VN story " .. defs.storyInfo.name .. " loaded")
end

local function StartStory(storyID)
  LoadStory(storyID)
  StartScript(defs.storyInfo.startScript)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local textTime = 0

function widget:Update()
  local currentTime = Spring.GetTimer()
    local dt = Spring.DiffTimers(currentTime, timer)
  timer = currentTime
  
  if (GetCurrentScriptAndLine() == nil) then
    return
  end
  
  if (waitTime and type(waitTime) == "number") then
    waitTime = waitTime - dt
    if waitTime <= 0 then
      waitTime = nil
      AdvanceScript()
    end
  end
  AdvanceAnimations(dt)
  textTime = textTime + dt
  
  if textTime > TEXT_INTERVAL and not mainWindow.hidden then
    if Spring.GetPressedKeys()[306] then  -- ctrl
      AdvanceScript(true)
    else
      AdvanceText(textTime, false)
    end
    textTime = 0
  end
end

-- image preloader
function widget:DrawGenesis()
  if #imagesToPreload > 0 then
    for i=1,#imagesToPreload do
      local file = imagesToPreload[v]
      if file then
        --Spring.Echo(file)
        gl.Texture(file)
        gl.Texture(false)
        v = v + 1
      end
    end
    imagesToPreload = {}
  end
end

function widget:Initialize()
  -- chili stuff here
  if not (WG.Chili) then
    Spring.Log(widget:GetInfo().name, LOG.ERROR, "Chili not loaded")
    widgetHandler:RemoveWidget()
    return
  end

  -- chili setup
  Chili = WG.Chili
  Window = Chili.Window
  Panel = Chili.Panel
  ScrollPanel = Chili.ScrollPanel
  --Grid = Chili.Grid
  Label = Chili.Label
  TextBox = Chili.TextBox
  Image = Chili.Image
  Button = Chili.Button
  StackPanel = Chili.StackPanel
  screen0 = Chili.Screen0
  
  -- create windows
  mainWindow = Window:New{
    name = "vn_mainWindow",
    caption = "Chili VN",
    --fontSize = 50,
    x = screen0.width*0.5 - WINDOW_WIDTH/2,
    y = screen0.height/2 - WINDOW_HEIGHT/2 - 8,
    width  = WINDOW_WIDTH + 16,
    height = WINDOW_HEIGHT + 32,
    padding = {8, 8, 8, 8};
    --autosize   = true;
    parent = screen0,
    draggable = true,
    resizable = false,
  }
  
  menuButton = Button:New{
    parent = mainWindow,
    name = "vn_menuButton",
    caption = "MENU",
    y = 24,
    right = 4,
    width = MENU_BUTTON_WIDTH_LARGE,
    height = MENU_BUTTON_HEIGHT_LARGE,
    OnClick = {ToggleMenu}
  }
  
  buttonSave = Button:New{
    name = "vn_menuButton",
    caption = "SAVE",
    width = MENU_BUTTON_WIDTH,
    height = MENU_BUTTON_HEIGHT,
    OnClick = {function() SaveGame() end}
  }
  
  buttonLoad = Button:New{
    name = "vn_buttonLoad",
    caption = "LOAD",
    width = MENU_BUTTON_WIDTH,
    height = MENU_BUTTON_HEIGHT,
    OnClick = {function() LoadGame() end}
  }
  
  buttonAuto = Button:New{
    name = "vn_buttonAuto",
    caption = "AUTO",
    width = MENU_BUTTON_WIDTH,
    height = MENU_BUTTON_HEIGHT,
    OnClick = {function() autoAdvance = not autoAdvance end}
  }
  
  buttonLog = Button:New{
    name = "vn_buttonLog",
    caption = "LOG",
    width = MENU_BUTTON_WIDTH,
    height = MENU_BUTTON_HEIGHT,
    OnClick = {function() CreateLogPanel() end}
  }
  
  buttonOptions = Button:New{
    name = "vn_buttonOptions",
    caption = "OPT",
    width = MENU_BUTTON_WIDTH,
    height = MENU_BUTTON_HEIGHT,
    OnClick = {function() if WG.crude then WG.crude.OpenPath(options_path); WG.crude.ShowMenu(); end end}
  }
  
  buttonQuit = Button:New{
    name = "vn_buttonQuit",
    caption = "QUIT",
    width = MENU_BUTTON_WIDTH,
    height = MENU_BUTTON_HEIGHT,
    OnClick = {function() Cleanup(); mainWindow:SetVisibility(false)
      if WG.Music then
        --WG.Music.StartTrack()
      end
    end}
  }
  
  local menuChildren
  if ALLOW_SAVE_LOAD then
    menuChildren = {buttonSave, buttonLoad, buttonAuto, buttonLog, buttonOptions, buttonQuit}
  else
    menuChildren = {buttonAuto, buttonLog, buttonOptions, buttonQuit}
  end
  menuStack = StackPanel:New{
    parent = mainWindow,
    orientation = 'vertical',
    autosize = false,
    resizeItems = true,
    centerItems = false,
    y = MENU_BUTTON_HEIGHT_LARGE + 24 + 8,
    right = 4,
    height = #menuChildren * (MENU_BUTTON_HEIGHT + 4) + 4,
    width = MENU_BUTTON_WIDTH + 4,
    padding = {0, 0, 0, 0},
    children = menuChildren,
  }
  menuStack:SetVisibility(false)
  
  textPanel = Panel:New {
    parent = mainWindow,
    name = "vn_textPanel",
    width = "100%",
    height = TEXT_PANEL_HEIGHT,
    x = 0,
    bottom = 0,
  }
  --function textPanel:HitTest() return self end
  
  if USE_PORTRAIT then
    portraitPanel = Panel:New {
      parent = textPanel,
      name = "vn_portraitPanel",
      width = PORTRAIT_WIDTH + 6,
      height = PORTRAIT_HEIGHT + 6,
      x = 0,
      padding = {3, 3, 3, 3},
      y = 4,
    }
    portrait = Image:New{
      parent = portraitPanel,
      name = "vn_portrait",
      width = "100%",
      height = "100%"
    }
  end
  
  nameLabel = Label:New{
    parent = textPanel,
    name = "vn_nameLabel",
    caption = "",
    x = (USE_PORTRAIT and PORTRAIT_WIDTH + 8 or 0) + 8,
    y = 4,
    right = 4,
    font = {
      size = 24;
      shadow = true;
    },
  }
  textbox = TextBox:New{
    parent = textPanel,
    name = "vn_textbox",
    text    = "",
    align   = "left",
    x = (USE_PORTRAIT and PORTRAIT_WIDTH + 16 or 52),
    bottom = 0,
    right = "5%",
    height = "75%",
    padding = {5, 5, 5, 5},
    font    = {
      size = DEFAULT_FONT_SIZE;
      shadow = true;
    },
  }
  
  nvlPanel = Panel:New {
    parent = mainWindow,
    name = "vn_nvlPanel",
    width = "100%",
    height = "80%",
    x = 0,
    y = "10%",
    backgroundColor = {1, 1, 1, 0.3}
  }
  nvlStack = StackPanel:New {
    parent = nvlPanel,
    name = "vn_nvlStack",
    orientation = 'vertical',
    autosize = false,
    resizeItems = false,
    centerItems = false,
    width = "100%",
    height = "100%",
  }
  
  backgroundBlack = Image:New{
    parent = mainWindow,
    name = "vn_background_black",
    x = 0,
    y = 24,
    right = 0,
    height = WINDOW_HEIGHT,
    keepAspect = false,
    itemMargin = {0, 0, 0, 0},
    file = BG_BLACK,
    color = {0, 0, 0, 1},
    OnClick = {function(self, x, y, mouse)
        if mouse == 1 then
          if not uiHidden then
            AdvanceText(0, true)
          else
            ToggleUI()
          end
        elseif mouse == 3 then
          ToggleUI()
        end
      end
    },
    OnMouseDown = {function(self) return true end},
  }
  
  overlay = Image:New{
    parent = backgroundBlack,
    name = "vn_overlay",
    x = 0,
    y = 0,
    right = 0,
    bottom = 0,
    padding = {0, 0, 0, 0},
    itemMargin = {0, 0, 0, 0},
    file = BG_WHITE,
    color = {0, 0, 0, 0},
    keepAspect = false,
  }
  
  background = Image:New{
    parent = backgroundBlack,
    name = "vn_background",
    x = 0,
    y = 0,
    right = 0,
    bottom = 0,
    padding = {0, 0, 0, 0},
    itemMargin = {0, 0, 0, 0},
    file = BG_BLACK,
    keepAspect = false,
  }
  
  nvlPanel:SetVisibility(false)
  mainWindow:SetVisibility(false)
  
  WG.VisualNovel = {
    GetDefs = GetDefs,
    GetData = GetData,
    StartScript = StartScript,
    AdvanceScript = AdvanceScript,
    StartStory = StartStory,
    LoadStory = LoadStory,
    CloseStory = CloseStory,
    Cleanup = Cleanup,
    
    scriptFunctions = scriptFunctions,
  }
  
  --StartStory("test")
end

function widget:Shutdown()
  --CloseStory()
  WG.VisualNovel = nil
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
