-- // ================================
-- // KDC - Input manager
local player_config = require 'config/player_config'

local component = scenes.components.component

local input_manager = component.derive('input_manager')

local entity_offset = vec2.pack(24, 16)

function input_manager:init(entity, player_input)
    class.super(input_manager).init(self, entity)

    self._player_input = player_input
    self.event_input_tap = event.new()
    self.event_input_hold_start = event.new()
    self.event_input_hold_end = event.new()

    self.entity.scene.event_tick:register(self._on_scene_tick, self)
end

function input_manager:destroy()
    self.entity.scene.event_tick:unregister(self._on_scene_tick, self)
end

-- Events
function input_manager:_on_scene_tick ()

    local value, elapsed = self._player_input:get_key_state('arm')
    if value then
        if elapsed == 0 then
            self:_on_fire_down()
        elseif self._fire_state then
            self:_on_fire_held(elapsed)
        end
    elseif self._fire_state then
        self:_on_fire_up()
    end
end

-- Private
function input_manager:_on_fire_down()
    -- Record input down info so we can respond appropriately
    self._fire_state = {
        is_long_press = false,
    }
end

function input_manager:_on_fire_held(elapsed)
    if elapsed >= player_config.input.arm_long_press_time then
        if self._fire_state.is_long_press == true then return end

        self._fire_state.is_long_press = true
        self.event_input_hold_start:dispatch()
    end
end

function input_manager:_on_fire_up()
    -- On a short press, fire the hook
    if not self._fire_state.is_long_press then
        self.event_input_tap:dispatch()
    else
        self.event_input_hold_end:dispatch()
    end

    self._fire_state = nil
end

return input_manager
