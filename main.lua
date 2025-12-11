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
local HorizontalGroup = require("ui/widget/horizontalgroup")
local ListView = require("ui/widget/listview")
local InfoMessage = require("ui/widget/infomessage")
local IconButton = require("ui/widget/iconbutton")
local ScrollHtmlWidget = require("ui/widget/scrollhtmlwidget")
local TextWidget = require("ui/widget/textwidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local ViewHTML = require("ui/viewhtml")
local WidgetContainer = require("ui/widget/container/widgetcontainer")

--Network imports
local https = require("ssl.https")
local ltn12 = require("ltn12")
local rapidjson = require("rapidjson")

--Utils imports
local logger = require("logger")
local _ = require("gettext")


local CopperMindBuilder = WidgetContainer:extend{
    name = "coppermind_builder",
    is_doc_only = false,
}

local WikiSearchResults = WidgetContainer:extend{
    name = "wiki_search_results",
    is_doc_only = false,
}


function CopperMindBuilder:showSearchResults(dict_popup)
    local response_body = {}
    https.request{
        url = string.format("https://coppermind.net/w/api.php?action=opensearch&format=json&formatversion=2&search=%s&namespace=0|3000&limit=10",dict_popup.word ),
        sink = ltn12.sink.table(response_body),
    }
    local response_text = table.concat(response_body)
    local success, data = pcall(rapidjson.decode, response_text)
    dict_popup:onClose()
    local size = Screen:getSize()
    local width = math.floor(size.w * 0.9)
    local height = math.floor(size.w * 0.9)

    if success and type(data) == "table" and #data > 1 then
        local titles = data[2]
        local urls = data[4]
        local buttons = {}
        for i, title in ipairs(titles) do
            if i > 0 then
                    table.insert(buttons, VerticalSpan:new{ width = 5 })
                end
            table.insert(buttons, Button:new{
                text = title,
                width = width - 20,
                callback = function()
                    CopperMindBuilder.showWiki(self, urls[i])
                end
            })
        end

        local list_view = ListView:new{
            height = height,
            width = width,
            item_height = Size.padding.button,
            page_update_cb = function(curr_page_num, total_pages)
                logger.dbg("AAAAAAAAAAAAAAAAAAAA")

                -- This callback function will be called whenever a page
                -- turn event is triggered. You can use it to update
                -- information on the parent widget.
            end,
            items = {
                table.unpack(buttons)
            }
        }

        local bottomButtons = HorizontalGroup:new{
            IconButton:new {
                 icon = "chevron.left",
                 callback = function()
                     list_view:prevPage()
                 end
            },
            IconButton:new {
                 icon = "close",
                 callback = function()
                     UIManager:close(self.wiki_results_menu,"ui")
                 end
            },
            IconButton:new {
                 icon = "chevron.right",
                 callback = function()
                     list_view:nextPage()
                 end
            },
        }

        local verticalGroup = VerticalGroup:new{
            TextWidget:new{
                width = width,
                text=string.format("Found %d entries", #titles),
                face = Font:getFace("xx_smallinfofont")
            },
            list_view,
            bottomButtons
        }

       self.wiki_results_menu = CenterContainer:new{
            dimen = size,
            FrameContainer:new{
                padding = Size.padding.default,
                background = Blitbuffer.COLOR_WHITE,
                bordersize = Size.border.window,
                radius = Size.radius.window,
                verticalGroup
            }
        }

        UIManager:show(
            self.wiki_results_menu
        )
    end
end

function CopperMindBuilder:showWiki(url)
    local size = Screen:getSize()
    local width = math.floor(size.w * 0.9)
    local height = math.floor(size.h * 0.8)

    local response_body = {}
    local res, code = https.request{
        url = url,
        sink = ltn12.sink.table(response_body),
    }
    if res then
        local html = table.concat(response_body)
        UIManager:close(self.wiki_results_menu, "ui")
        local dialog = CenterContainer:new{
            dimen = size,
        }

        local scroll_widget = ScrollHtmlWidget:new{
            html_body = html,
            width = size.w,
            height = height,
            dialog = dialog, -- Set the dialog reference
        }

        dialog[1] =
            VerticalGroup:new{
                scroll_widget,
                IconButton:new {
                    icon = "close",
                    callback = function()
                        UIManager:close(dialog,"ui")
                    end
                },
        }

        UIManager:show(dialog)
    else
        logger.dbg("Error fetching html")
    end
end

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
            CopperMindBuilder:showSearchResults(dict_popup)
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
