local resources = require 'resources'
local launch_params = require 'launch_params'

---@class lobby_selector:class
local lobby_selector = class.create()

function lobby_selector:init(element)
	self.id = reactive.create_ref()
	element:create_text('Lobby ID: ' .. launch_params.lobby_id:sub(1, 16) .. '...')
	local toggle_group = element:create_element({ align_items = 'center', row_gap = 4 * resources.scale })
	toggle_group:create_text('Create New Lobby:')
	local join_checkbox = toggle_group:create_screen_checkbox(false)
	join_checkbox.checked:register(function(checked)
		if checked then
			self.id.value = nil
		else
			self.id.value = launch_params.lobby_id
		end
	end)
end

return lobby_selector