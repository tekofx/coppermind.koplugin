--[[--
This is a debug plugin to test Plugin functionality.

@module koplugin.HelloWorld
--]]--

local Blitbuffer = require("ffi/blitbuffer")
local Dispatcher = require("dispatcher")  -- luacheck:ignore

--UI Imports
local Device = require("device")
local Font = require("ui/font")
local Screen = Device.screen
local Size = require("ui/size")
local UIManager = require("ui/uimanager")

--Widgets imports
local Button = require("ui/widget/button")
local ButtonTable = require("ui/widget/buttontable")
local CenterContainer = require("ui/widget/container/centercontainer")
local FrameContainer = require("ui/widget/container/framecontainer")
local InfoMessage = require("ui/widget/infomessage")
local TextWidget = require("ui/widget/textwidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local WidgetContainer = require("ui/widget/container/widgetcontainer")

--Network imports
local http = require("socket.http")
local ltn12 = require("ltn12")
local rapidjson = require("rapidjson")

--Utils imports
local logger = require("logger")
local _ = require("gettext")


local CopperMindBuilder = WidgetContainer:extend{
    name = "coppermind_builder",
    is_doc_only = false,
}


--[[--
Triggered when selected word
--]]--
function CopperMindBuilder:onDictButtonsReady(dict_popup, buttons)
    table.insert(buttons, 1, {{
        id = "coppermind",
        text = _("Search on Coppermind"),
        font_bold = false,
        callback = function()
            local button = dict_popup.button_table.button_by_id["coppermind"]
            if not button then return end
            local response_body = {}
            http.request{
                url = "https://es.coppermind.net/w/api.php?action=opensearch&format=json&formatversion=2&search=sazed&namespace=0|3000&limit=10",
                sink = ltn12.sink.table(response_body)
            }

            local response_text = table.concat(response_body)
            local success, data = pcall(rapidjson.decode, response_text)

            logger.dbg("Response:", data)
            dict_popup:onClose()
            local size = Screen:getSize()
            local width = math.floor(size.w * 0.9)

            if success and type(data) == "table" and #data > 1 then
                local titles = data[2]
                local buttons = {
                    TextWidget:new{
                        text=_("Found entries"),
                        face = Font:getFace("xx_smallinfofont")

                    }

                }
                for i, title in ipairs(titles) do
                    if i > 0 then
                            table.insert(buttons, VerticalSpan:new{ width = 10 })
                        end
                    table.insert(buttons, Button:new{
                        text = title,
                        width = width,
                        callback = function()
                            logger.dbg("Selected:", title)
                        end
                    })
                end
                local buttonsTable = VerticalGroup:new{
                    unpack(buttons)
                }
                UIManager:show(
                    CenterContainer:new{
                        dimen = size,
                        FrameContainer:new{
                            padding = Size.padding.default,
                            background = Blitbuffer.COLOR_WHITE,
                            bordersize = Size.border.window,
                            radius = Size.radius.window,
                            buttonsTable
                        }
                    })
            end



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
