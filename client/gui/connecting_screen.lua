local resources = require 'resources'

---@class connecting_screen:class
local connecting_screen = class.create()

function connecting_screen:init(element, connection)
	self.event_reset = event.new()
	local screen = element:create_computer_screen()
	screen:build(function()
        local container = screen:create_element({
            width = '100%',
            height = '100%',
            flex_direction = 'column',
            justify_content = 'center',
            align_items = 'center',
			color = '#75F5D3',
            font_family = 'commo'
        })
        if connection.status.value == 'disconnected' then
            container:create_text('Disconnected', { font_size = 48 * resources.scale })
            if connection.disconnect_reason then
                container:create_text(connection.disconnect_reason, { font_size = 24 * resources.scale })
            end
			container:create_screen_button('Reset').event_clicked:register(function()
                self.event_reset:dispatch()
            end)
        else
            container:create_text('Connecting...', { font_size = 48 * resources.scale })
        end
        --how_to_play_gui(contents)
    end)
end

return connecting_screen