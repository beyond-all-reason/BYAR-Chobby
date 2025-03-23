ErrorPopup = PriorityPopup:extends()

function ErrorPopup:init(errorMessage)

    local window = Window:New{
        name = "error_popup",
        classname = "main_window",
        caption = "Error",
        width = 316,
        height = 240,
        resizable = false,
        draggable = false,
        parent = lobbyInterfaceHolder,
        objectOverrideFont = Configuration:GetFont(3),
    }
    local function Close()
        self:ClosePopup()
    end

    Label:New{
        caption = errorMessage,
        x = 20,
        y = 20,
        right = 20,
        bottom = 76,
        valign = "top",
        autosize = false,
        objectOverrideFont = Configuration:GetFont(1),
        parent = window
    }

    Button:New{
        caption = "Close",
        x = (316 - 135) / 2,
        bottom = 1,
        width = 135,
        height = 70,
        objectOverrideFont = Configuration:GetFont(3),
        parent = window,
        classname = "negative_button",
        OnClick = {
            Close
        }
    }

    self:super("init", window, Close, Close)
end