--//=============================================================================
--// Skin

local skin = {
  info = {
    name    = "Armada Blues",
    version = "0.5",
    author  = "Moose",
    --depend = {"Evolved",},
  }
}

--//=============================================================================
--//

skin.general = {
  focusColor  = {0.15, 0.65, 1.0, 1.0},
  borderColor = {1.0, 1.0, 1.0, 1.0},

  font = {
    font    = "fonts/n019003l.pfb",
    color        = {1,1,1,1},
    outlineColor = {0.05,0.05,0.05,0.9},
    outline = false,
    shadow  = true,
    size    = 14,
  },

  --padding         = {5, 5, 5, 5}, --// padding: left, top, right, bottom
}

skin.button = {
  TileImageBK = ":cl:tech_button_small2_bk.png",
  TileImageFG = ":cl:tech_button_small2_fg.png",
  tiles = {22, 22, 22, 22}, --// tile widths: left,top,right,bottom
  padding = {10, 10, 10, 10},

  backgroundColor = {0.55, 0.55, 0.55, 0.935},
  focusColor  = {0.15, 0.65, 0.85, 0.9},
  borderColor = {1, 1, 1, 0.0},

  DrawControl = DrawButton,
}

skin.button_bulb = {
  TileImageBK = ":cl:extra/tech_button_small_bk.png",
  TileImageFG = ":cl:extra/tech_button_small_fg.png",
  tiles = {4, 4, 4, 4}, --// tile widths: left,top,right,bottom
  padding = {5, 5, 5, 5},
  backgroundColor = {0.5, 0.5, 0.5, 0.935},
  focusColor  = {0.6, 0.7, 0.9, 0.9},
  borderColor = {1,1,1,0},

  DrawControl = DrawButton,
}

skin.button_slimbulb = {
  TileImageBK = ":cl:extra/tech_button_action_bk.png",
  TileImageFG = ":cl:extra/tech_button_action_fg.png",
  tiles = {2, 2, 2, 2}, --// tile widths: left,top,right,bottom
  padding = {10, 10, 10, 10},

  backgroundColor = {0.45, 0.45, 0.45, 0.9},
  focusColor  = {0.70, 0.80, 0.80, 0.75},
  borderColor = {1,1,1,0},

  DrawControl = DrawButton,
}

skin.button_small = {
  TileImageBK = ":cl:tech_button_small2_bk.png",
  TileImageFG = ":cl:tech_button_small2_fg.png",
  tiles = {22, 22, 22, 22}, --// tile widths: left,top,right,bottom
  padding = {10, 10, 10, 10},

  backgroundColor = {0.55, 0.55, 0.55, 0.65},
  focusColor  = {0.15, 0.65, 0.85, 0.6},
  borderColor = {1, 1, 1, 0.0},

  DrawControl = DrawButton,
}

skin.action_button = {
  TileImageBK = ":cl:tech_button_dark_small_bk.png",
  TileImageFG = ":cl:tech_button_bright_small_alt_fg.png",
  tiles = {20, 20, 20, 20}, --// tile widths: left,top,right,bottom
  padding = {10, 10, 10, 10},

  backgroundColor = {0.45, 1.0, 0.55, 0.75},
  focusColor  = {0.1, 1.0, 0.1, 1.0},
  borderColor = {0.0, 1.0, 0.0, 0.67},

  DrawControl = DrawButton,
}

skin.ready_button = {
  TileImageBK = ":cl:tech_button_bright_small_bk_grey.png",
  TileImageFG = ":cl:tech_button_bright_small_fg.png",
  tiles = {40, 40, 40, 40},--// tile widths: left,top,right,bottom
  padding = {10, 10, 10, 10},
  StyleReady = function(self)
    self.backgroundColor = {0.45, 1.0, 0.55, 0.75}
    self.focusColor  = {0.1, 1.0, 0.1, 1.0}
    self.borderColor = {0.0, 1.0, 0.0, 0.67}
    self:Invalidate()
  end,
  StyleUnready = function(self)
    self.backgroundColor = {0.85, 0.8, 0.55, 0.75}
    self.focusColor  = {1.0, 1.0, 0.1, 1.0}
    self.borderColor = {0.8, 0.8, 0.0, 0.67}
    self:Invalidate()
  end,
  StyleOff = function(self)
    self.backgroundColor = {0.3, 0.3, 0.3, 0.75}
    self.focusColor  = {0.8, 0.8, 0.8, 1.0}
    self.borderColor = {0.8, 0.8, 0.8, 0.67}
    self:Invalidate()
  end,

  DrawControl = DrawButton,
}

skin.option_button = {
  TileImageBK = ":cl:tech_button_dark_small_bk.png",
  TileImageFG = ":cl:tech_button_bright_small_alt_fg.png",
  tiles = {20, 20, 20, 20}, --// tile widths: left,top,right,bottom
  padding = {10, 10, 10, 10},

  backgroundColor = {0.65, 0.65, 0.65, 0.75},
  focusColor  = {0.05, 0.58, 1.0, 1.0},
  borderColor = {1.0, 1.0, 1.0, 0.0},

  DrawControl = DrawButton,
}

skin.playing_button = {
  clone = "option_button",
}

skin.link_button = {
  TileImageBK = ":cl:tech_button_bright_small_bk.png",
  TileImageFG = ":cl:tech_button_bright_small_fg.png",
  tiles = {20, 20, 20, 20}, --// tile widths: left,top,right,bottom: updated to match skin.action_button
  padding = {10, 10, 10, 10},

  backgroundColor = {0.75, 0.75, 0.75, 0.65},
  focusColor  = {0.15, 0.58, 0.90, 0.9},
  borderColor = {0.50, 0.50, 0.50, 0.15},

  DrawControl = DrawButton,
}

skin.button_simple = {
  TileImageBK = ":cl:tech_button_dark_small_bk.png",
  TileImageFG = ":cl:tech_button_dark_small_fg.png",
  tiles = {20, 20, 20, 20}, --// tile widths: left,top,right,bottom: updated to match skin.action_button
  padding = {10, 10, 10, 10},

  backgroundColor = {0.70, 0.70, 0.75, 0.65},
  focusColor  = {0.15, 0.65, 0.85, 0.8},
  borderColor = {0.40, 0.40, 0.50, 0.15},

  DrawControl = DrawButton,
}

skin.negative_button = {
  TileImageBK = ":cl:tech_button_dark_small_bk.png",
  TileImageFG = ":cl:tech_button_bright_small_alt_fg.png",
  tiles = {20, 20, 20, 20}, --// tile widths: left,top,right,bottom: updated to match skin.action_button
  padding = {10, 10, 10, 10},

  backgroundColor = {1.0, 0.45, 0.55, 0.95},
  focusColor  = {1.0, 0.1, 0.1, 1.0},
  borderColor = {1.0, 0.0, 0.0, 0.67},

  DrawControl = DrawButton,
}

skin.positive_button = {
  TileImageBK = ":cl:tech_button_dark_small_bk.png",
  TileImageFG = ":cl:tech_button_bright_small_alt_fg.png",
  tiles = {20, 20, 20, 20}, --// tile widths: left,top,right,bottom
  padding = {10, 10, 10, 10},

  backgroundColor = {0.45, 1.0, 0.55, 0.75},
  focusColor  = {0.1, 1.0, 0.1, 1.0},
  borderColor = {0.0, 1.0, 0.0, 0.67},

  DrawControl = DrawButton,
}

skin.battle_default_button = { --Blue
  TileImageBK = ":cl:tech_button_dark_small_bk.png",
  TileImageFG = ":cl:tech_button_bright_small_alt_fg.png",
  tiles = {20, 20, 20, 20}, --// tile widths: left,top,right,bottom
  padding = {10, 10, 10, 10},

  backgroundColor = {0.20, 0.20, 0.2, 0.65},
  focusColor  = {0.05, 0.55, 1.0, 0.8}, -- color when focusd
  borderColor = {0.40, 0.40, 0.50, 0.15},

  DrawControl = DrawButton,
}

skin.favourite_check = {
  TileImageFG = ":cl:star_on.png",
  TileImageBK = ":cl:star_off.png",
  tiles = {0, 0, 0, 0}, --// tile widths: left,top,right,bottom
  boxsize     = 24,

  DrawControl = DrawCheckbox,
}

skin.combobox = {
	TileImageBK = ":cl:combobox_ctrl.png",
	TileImageFG = ":cl:combobox_ctrl_fg.png",
	TileImageArrow = ":cl:combobox_ctrl_arrow.png",
	tiles   = {22, 22, 48, 22},
	padding = {10, 10, 24, 10},

	backgroundColor = {1, 1, 1, 0.7},
	borderColor = {1,1,1,0},

	DrawControl = DrawComboBox,
}


skin.combobox_window = {
	clone     = "window";
	TileImage = ":cl:combobox_wnd.png";
	tiles     = {2, 2, 2, 2};
	padding   = {4, 3, 3, 4};
}


skin.combobox_scrollpanel = {
	clone       = "scrollpanel";
	borderColor = {1, 1, 1, 0};
	padding     = {0, 0, 0, 0};
}


skin.combobox_item = {
	clone       = "button_small";
  backgroundColor = {0, 0, 0, 0.25},
	borderColor = {1, 1, 1, 0};
}


skin.checkbox = {
  TileImageFG = ":cl:tech_checkbox_checked.png",
  TileImageBK = ":cl:tech_checkbox_unchecked.png",
  tiles       = {3,3,3,3},
  boxsize     = 13,

  DrawControl = DrawCheckbox,
}

skin.editbox = {
  hintFont = table.merge({color = {1,1,1,0.7}}, skin.general.font),

  backgroundColor = {0.1, 0.1, 0.1, 0},
  cursorColor     = {0.15, 0.65, 0.85, 0.8},

  focusColor  = {1, 1, 1, 1},
  borderColor = {0.6, 0.6, 0.6, 0.6},

  TileImageBK = ":cl:panel2_bg.png",
  TileImageFG = ":cl:editbox_border.png",
  tiles       = {2, 2, 2, 2},
  cursorFramerate = 1, -- Per second

  DrawControl = DrawEditBox,
}

skin.textbox = {
  hintFont = table.merge({color = {1,1,1,0.7}}, skin.general.font),

  TileImageBK = ":cl:panel2_bg.png",
  bkgndtiles = {14,14,14,14},

  TileImageFG = ":cl:panel2_border.png",
  tiles       = {2, 2, 2, 2},

  borderColor     = {0.0, 0.0, 0.0, 0.0},
  focusColor      = {0.0, 0.0, 0.0, 0.0},

  DrawControl = DrawEditBox,
}

skin.imagelistview = {
  imageFolder      = "folder.png",
  imageFolderUp    = "folder_up.png",

  --DrawControl = DrawBackground,

  colorBK          = {1,1,1,0.3},
  colorBK_selected = {0.15, 0.65, 0.85, 0.8},

  colorFG          = {0, 0, 0, 0},
  colorFG_selected = {2, 2, 2, 2},

  imageBK  = ":cl:node_selected_bw.png",
  imageFG  = ":cl:node_selected.png",
  tiles    = {9, 9, 9, 9},

  DrawItemBackground = DrawItemBkGnd,
}
--[[
skin.imagelistviewitem = {
  imageFG = ":cl:glassFG.png",
  imageBK = ":cl:glassBK.png",
  tiles = {17,15,17,20},

  padding = {12, 12, 12, 12},

  DrawSelectionItemBkGnd = DrawSelectionItemBkGnd,
}
--]]

skin.panel = {
  TileImageBK = ":cl:tech_button.png",
  TileImageFG = ":cl:empty.png",
  tiles = {2, 2, 2, 2},

  DrawControl = DrawPanel,
}

skin.panel_light = {
  TileImageBK = ":cl:tech_overlaywindow.png",
  TileImageFG = ":cl:empty.png",
  tiles = {2, 2, 2, 2},

  backgroundColor = {0.4, 0.4, 0.4, 0.7},

  DrawControl = DrawPanel,
}

skin.overlay_panel = {
  TileImageBK = ":cl:tech_overlaywindow.png",
  TileImageFG = ":cl:empty.png",
  tiles = {2, 2, 2, 2},

  backgroundColor = {0.1, 0.1, 0.1, 0.7},

  DrawControl = DrawPanel,
}


skin.progressbar = {
  TileImageFG = ":cl:tech_progressbar_full.png",
  TileImageBK = ":cl:tech_progressbar_empty.png",
  tiles       = {10, 10, 10, 10},

  backgroundColor = {0,0,0,0.5},

  DrawControl = DrawProgressbar,
}

skin.scrollpanel = {
  BorderTileImage = ":cl:panel2_border.png",
  bordertiles = {2, 2, 2, 2},

  BackgroundTileImage = ":cl:panel2_bg.png",
  bkgndtiles = {14,14,14,14},

  TileImage = ":cl:tech_scrollbar.png",
  tiles     = {7,7,7,7},
  KnobTileImage = ":cl:tech_scrollbar_knob.png",
  KnobTiles     = {6,8,6,8},

  HTileImage = ":cl:tech_scrollbar.png",
  htiles     = {7,7,7,7},
  HKnobTileImage = ":cl:tech_scrollbar_knob.png",
  HKnobTiles     = {6,8,6,8},

  KnobColorSelected = {0.15, 0.65, 0.95, 1.0},

  padding = {5, 5, 5, 0},

  scrollbarSize = 14,
  DrawControl = DrawScrollPanel,
  DrawControlPostChildren = DrawScrollPanelBorder,
}

skin.scrollpanel_borderless = {
  BorderTileImage = ":cl:empty.png",
  bordertiles = {2, 2, 2, 2},

  BackgroundTileImage = ":cl:empty.png",
  bkgndtiles = {14,14,14,14},

  TileImage = ":cl:tech_scrollbar.png",
  tiles     = {7,7,7,7},
  KnobTileImage = ":cl:tech_scrollbar_knob.png",
  KnobTiles     = {6,8,6,8},

  HTileImage = ":cl:tech_scrollbar.png",
  htiles     = {7,7,7,7},
  HKnobTileImage = ":cl:tech_scrollbar_knob.png",
  HKnobTiles     = {6,8,6,8},

  KnobColorSelected = {0.15, 0.65, 0.95, 1.0},

  padding = {5, 5, 5, 0},

  scrollbarSize = 14,
  DrawControl = DrawScrollPanel,
  DrawControlPostChildren = function () end,
}

skin.trackbar = {
  TileImage = ":cn:trackbar.png",
  tiles     = {10, 14, 10, 14}, --// tile widths: left,top,right,bottom

  ThumbImage = ":cl:trackbar_thumb.png",
  StepImage  = ":cl:trackbar_step.png",

  hitpadding  = {4, 4, 5, 4},

  DrawControl = DrawTrackbar,
}

skin.treeview = {
  --ImageNode         = ":cl:node.png",
  ImageNodeSelected = ":cl:empty.png",
  tiles = {9, 9, 9, 9},

  ImageExpanded  = ":cl:treeview_node_expanded.png",
  ImageCollapsed = ":cl:treeview_node_collapsed.png",
  ImageHighlight = ":cl:treeview_node_collapsed_highlight.png",
  treeColor = {1,1,1,0.1},

  DrawNode = DrawTreeviewNode,
  DrawNodeTree = DrawTreeviewNodeTree,
}

skin.window = {
  TileImage = ":c:tech_dragwindow.png",
  tiles = {2, 2, 2, 2}, --// tile widths: left,top,right,bottom
  padding = {13, 13, 13, 13},
  hitpadding = {4, 4, 4, 4},

  captionColor = {1, 1, 1, 0.45},

  backgroundColor = {0.1, 0.1, 0.1, 0.7},

  boxes = {
    resize = {-21, -21, -10, -10},
    drag = {0, 0, "100%", 10},
  },

  NCHitTest = NCHitTestWithPadding,
  NCMouseDown = WindowNCMouseDown,
  NCMouseDownPostChildren = WindowNCMouseDownPostChildren,
  noClickThrough = true,

  DrawControl = DrawWindow,
  DrawDragGrip = function() end,
  DrawResizeGrip = DrawResizeGrip,
}

skin.startbox_window = {
  TileImage = ":c:tech_startboxwindow.png",
  tiles = {2, 2, 2, 2}, --// tile widths: left,top,right,bottom
  padding = {4, 4, 4, 4},
  hitpadding = {4, 4, 4, 4},

  captionColor = {1, 1, 1, 0.9},

  backgroundColor = {0.1, 0.1, 0.1, 0.2},

  boxes = {
    resize = {-16, -16, -1, -1},
    drag = {0, 0, "100%", 10},
  },

  NCHitTest = NCHitTestWithPadding,
  NCMouseDown = WindowNCMouseDown,
  NCMouseDownPostChildren = WindowNCMouseDownPostChildren,
  noClickThrough = true,

  DrawControl = DrawWindow,
  DrawDragGrip = function() end,
  DrawResizeGrip = DrawResizeGrip,
}

skin.main_window = {
  TileImage = ":c:tech_mainwindow_cool.png",
  tiles = {64, 256, 64, 256}, --// tile widths: left,top,right,bottom
  padding = {16, 16, 16, 16},
  hitpadding = {4, 4, 4, 4},

  captionColor = {1, 1, 1, 0.45},
  backgroundColor = {0.1, 0.1, 0.1, 0.9},

  boxes = {
    resize = {-21, -21, -10, -10},
    drag = {0, 0, "100%", 10},
  },

  NCHitTest = NCHitTestWithPadding,
  NCMouseDown = WindowNCMouseDown,
  NCMouseDownPostChildren = WindowNCMouseDownPostChildren,
  noClickThrough = true,

  DrawControl = DrawWindow,
  DrawDragGrip = function() end,
  DrawResizeGrip = DrawResizeGrip,
}

skin.main_window_small = {
  TileImage = ":c:tech_mainwindow_cool_small.png",
  tiles = {76, 40, 76, 40}, --// tile widths: left,top,right,bottom
  padding = {13, 13, 13, 13},
  hitpadding = {4, 4, 4, 4},

  captionColor = {1, 1, 1, 0.45},
  backgroundColor = {0.1, 0.1, 0.1, 0.7},

  boxes = {
    resize = {-23, -19, -12, -8},
    drag = {0, 0, "100%", 10},
  },

  NCHitTest = NCHitTestWithPadding,
  NCMouseDown = WindowNCMouseDown,
  NCMouseDownPostChildren = WindowNCMouseDownPostChildren,
  noClickThrough = true,

  DrawControl = DrawWindow,
  DrawDragGrip = function() end,
  DrawResizeGrip = DrawResizeGrip,
}

--[[ skin.tech_mainwindow_very_small = {
  TileImage = ":c:tech_mainwindow_very_small.png",
  tiles = {40, 30, 38, 38}, --// tile widths: left,top,right,bottom
  padding = {10, 6, 10, 6},
  hitpadding = {4, 4, 4, 4},

  captionColor = {1, 1, 1, 0.45},
  backgroundColor = {0.1, 0.1, 0.1, 0.7},

  boxes = {
    resize = {-23, -19, -12, -8},
    drag = {0, 0, "100%", 10},
  },

  NCHitTest = NCHitTestWithPadding,
  NCMouseDown = WindowNCMouseDown,
  NCMouseDownPostChildren = WindowNCMouseDownPostChildren,
  noClickThrough = true,

  DrawControl = DrawWindow,
  DrawDragGrip = function() end,
  DrawResizeGrip = DrawResizeGrip,
} ]]

skin.overlay_window = {
  TileImage = ":c:tech_overlaywindow.png",
  tiles = {2, 2, 2, 2}, --// tile widths: left,top,right,bottom
  padding = {13, 13, 13, 13},
  hitpadding = {4, 4, 4, 4},

  captionColor = {1, 1, 1, 0.45},

  backgroundColor = {0.1, 0.1, 0.1, 0.7},

  boxes = {
    resize = {-21, -21, -10, -10},
    drag = {0, 0, "100%", 10},
  },

  NCHitTest = NCHitTestWithPadding,
  NCMouseDown = WindowNCMouseDown,
  NCMouseDownPostChildren = WindowNCMouseDownPostChildren,

  DrawControl = DrawWindow,
  DrawDragGrip = function() end,
  DrawResizeGrip = DrawResizeGrip,
}

skin.line = {
  TileImage = ":cl:tech_line.png",
  tiles = {0, 0, 0, 0},
  TileImageV = ":cl:tech_line_vert.png",
  tilesV = {0, 0, 0, 0},
  borderColor = {125/255, 125/255, 125/255, 1},
  DrawControl = DrawLine,
}

skin.lineStandOut = {
  TileImage = ":cl:tech_line.png",
  tiles = {0, 0, 0, 0},
  TileImageV = ":cl:tech_line_vert.png",
  tilesV = {0, 0, 0, 0},
  borderColor = {1, 0.2, 0.2, 1},
  DrawControl = DrawLine,
}

skin.tabbar = {
  padding = {3, 1, 1, 0},
}

skin.tabbaritem = {
  -- yes these are reverted, but also a lie (see images), only one is used
  TileImageFG = ":cl:tech_tabbaritem_bk.png",
  TileImageBK = ":cl:tech_tabbaritem_bk.png",
  tiles = {12, 12, 12, 12}, --// tile widths: left,top,right,bottom
  padding = {1, 1, 1, 2},
  -- since it's color multiplication, it's easier to control white color (1, 1, 1) than black color (0, 0, 0) to get desired results
  backgroundColor = {0.3, 0.3, 0.3, 0.5},
  -- actually kill this anyway
  borderColor     = {0, 0, 0, 0},
  focusColor      = {0.5, 0.5, 0.5, 1.0},

  DrawControl = DrawTabBarItem,
}


skin.control = skin.general


--//=============================================================================
--//

return skin
