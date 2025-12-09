--[[--
This is a debug plugin to test Plugin functionality.

@module koplugin.HelloWorld
--]]--

local Dispatcher = require("dispatcher")  -- luacheck:ignore
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local FocusManager = require("ui/widget/focusmanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")
local logger = require("logger")


local CopperMindBuilder = WidgetContainer:extend{
    name = "coppermind_builder",
    is_doc_only = false,
}

function CopperMindBuilder:onDictButtonsReady(dict_popup, buttons)

    table.insert(buttons, 1, {{
        id = "coppermind",
        text = _("Search on Coppermind"),
        font_bold = false,
        callback = function()
            local button = dict_popup.button_table.button_by_id["coppermind"]
            if not button then return end
            logger.dbg("Coppermind: Search",dict_popup.lookupword )

        end
    }})

end

function CopperMindBuilder:onDispatcherRegisterActions()
    Dispatcher:registerAction("helloworld_action", {category="none", event="HelloWorld", title=_("Hello World"), general=true,})
end

function CopperMindBuilder:init()
    self:onDispatcherRegisterActions()
    self.ui.menu:registerToMainMenu(self)
end

function CopperMindBuilder:addToMainMenu(menu_items)
    menu_items.hello_world = {
        text = _("Hello World"),
        -- in which menu this should be appended
        sorting_hint = "more_tools",
        -- a callback when tapping
        callback = function()
            CopperMindBuilder.onHelloWorld(self)
        end,
    }
end

function CopperMindBuilder:onHelloWorld()
    local popup = InfoMessage:new{
        text = _("Hello World"),
    }
    UIManager:show(popup)
end

return CopperMindBuilder
