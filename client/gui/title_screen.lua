local pogo_preferences = require 'pogo_preferences'
local resources = require 'resources'
local launch_params = require 'launch_params'
local pilot_creator = require 'gui/pilot_creator'
local lobby_selector = require 'gui/lobby_selector'

---@class title_screen:class
local title_screen = class.create()

function title_screen:init(element)
	self.event_lobby_selected = event.new()
	local screen = element:create_computer_screen()
    screen:build(function()
        local container = screen:create_element({
            flex_direction = 'column',
            align_items = 'center',
            width = '100%',
            font_family = 'command_prompt',
            font_size = 16 * resources.scale,
        })
        container:create_element({
            width = resources.gui.logo.size_x * resources.scale,
            height = resources.gui.logo.size_y * resources.scale,
            background_image = resources.gui.logo,
            background_size = 'contain',
            padding = 20 * resources.scale
        })
        local panel = container:create_screen_panel('', '#75F5D3', 269 * resources.scale)
        local frame = panel:create_screen_frame('100%', '100%')
        local pilot_view = frame:create_screen_view('NAME', false, '100%')
        local initials_creator
        if not launch_params.user_name then
            initials_creator = pilot_creator.new(pilot_view)
        else
            pilot_view:create_text(launch_params.user_name, {
                color = '#F2F7DE',
                font_size = 16 * resources.scale,
            })
        end
        frame:create_element({
            height = 8 * resources.scale
        })

		local lobby
		if launch_params.lobby_id then
			--local lobby_view = frame:create_screen_view('DEPLOYMENT', false, '100%')
			--lobby = lobby_selector.new(lobby_view)
		end

        local launch_button_border = frame:create_element({
            width = resources.gui.launch_button.size_x * resources.scale,
            height = resources.gui.launch_button.size_y * resources.scale,
            background_image = resources.gui.launch_button,
            background_size = 'contain',
			margin_bottom = 3,
        })
        local launch_button = launch_button_border:create_button('PLAY', {
            width = '100%',
            height = '100%',
            align_items = 'center',
            justify_content = 'center',
            color = '#FF0000',
            font_size = 30 * resources.scale,
            font_family = 'commo',
            margin_top = 4 * resources.scale,
            margin_bottom = 4 * resources.scale,
            margin_left = 11 * resources.scale,
            margin_right = 12 * resources.scale,
            background_color = '#FF000040',
            hover = {
                background_color = '#FF000055',
            },
            active = {
                background_color = '#FF00007F',
            }
        })
        launch_button.event_clicked:register(function()
			local lobby_id = lobby and lobby.id.value
            local name = launch_params.user_name
            if not name then
                name = initials_creator:get_initials()
                pogo_preferences.pilot_initials = name
            end
			self.event_lobby_selected:dispatch(lobby_id, name)
        end)
    end)
end

return title_screen
