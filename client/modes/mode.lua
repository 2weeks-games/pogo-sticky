local resources = require 'resources'

scenes.enable_box2d()
scenes.enable_gui()
scenes.enable_tiled()

local collision_layers = require 'collision_layers'
local player_input = require 'player_input'
---@class mode:class
local mode = class.create()

function mode:init(pixel_size_x, pixel_size_y, seed, mode_players, game_session)
    self.pixel_size_x, self.pixel_size_y = pixel_size_x, pixel_size_y
    self.scene = scenes.scene.new(resources.display)
    self.scene.mode = self
    self.generator = random.create_generator(seed)
    self.scene.pending_update:register(self._on_pending_update, self)
    self.game_session = game_session
    if self.game_session and not self.game_session.is_shadow then
        self.game_session:register_state_changed(self._on_session_state_changed, self)
    end

    self.inputs = {}
    for i = 1, #mode_players do
        self.inputs[i] = player_input.new()
    end

    local center_x, center_y = self:pixel_extents()
    self.camera_entity = self.scene:create_entity('camera')
    self.camera_entity:create_transform(nil, vec3.pack(center_x, center_y, 1)):look_at_local(center_x, center_y)
    self.camera_entity:create_camera('orthographic', -center_x, center_x, -center_y, center_y)
    self.scene:set_active_camera(self.camera_entity)
    self.event_complete = event.new()

    mode.set_current(self)
end

function mode:_on_state_complete(is_complete)
    if is_complete then
        self.scene:clear()
    end
end

function mode:complete(complete_state)
    self.event_complete:dispatch(complete_state)
end

function mode:destroy()
    if self.game_session then
        self.game_session:unregister_state_changed(self._on_session_state_changed, self)
    end
    self.scene:clear()
end

function mode:pixel_extents()
    return self.pixel_size_x // 2, self.pixel_size_y // 2
end

function mode:_on_pending_update(pending)
    if pending then
        system.queue_update()
    end
end

function mode:_on_session_state_changed(key, value)
end

function mode:set_viewport(vx0, vy0, vx1, vy1)
    local size_x, size_y = vx1 - vx0, vy1 - vy0
    self.scene:set_viewport_size(size_x, size_y)
    local scale_x, scale_y = size_x / self.pixel_size_x, size_y / self.pixel_size_y
    local scale = math.min(scale_x, scale_y)
    local ortho_half_x, ortho_half_y = (size_x / scale) / 2, (size_y / scale) / 2
    self.camera_entity.camera:set_orthographic(-ortho_half_x, ortho_half_x, -ortho_half_y, ortho_half_y)
end

function mode:debug_key_down(key)
end

function mode:debug_key_up(key)
end

-- Globals
local _current_mode

function mode.get_current()
    return _current_mode
end

function mode.set_current(current_mode)
    _current_mode = current_mode
end

return mode