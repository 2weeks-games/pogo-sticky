local component = scenes.components.component
local transform = scenes.components.transform
local entity_shake = component.derive('entity_shake')

function entity_shake:init(entity, ...)
    class.super(entity_shake).init(self, entity)

    self.active_shake = false

    self.entity.scene.event_update:register(self._on_scene_update, self)
end

function entity_shake:destroy()
    self.entity.scene.event_update:unregister(self._on_scene_update, self)
end

function entity_shake:_on_scene_update(elapsed_seconds)
    if self.active_shake then
        if self.shake_elapsed_time < self.shake_duration then
            self.shake_elapsed_time = self.shake_elapsed_time + elapsed_seconds
            -- Apply random shake
            -- TODO: Check whether this should be using a generator
            local eased_intensity = self.shake_intensity
            if self.shake_elapsed_time > self.ease_start then
                eased_intensity = self.ease_out_quad(self.shake_elapsed_time - self.ease_start, self.shake_intensity, 0, self.ease_duration)
            end
            local generator = self.entity.scene.kaiju_mode.generator
            local random_x = self.current_pos_x + (generator:next() * 2 - 1) * eased_intensity
            local random_y = self.current_pos_y + (generator:next() * 2 - 1) * eased_intensity
            self.entity.transform.local_translation.value = vec3.pack(random_x, random_y, self.current_pos_z)
        else
            self.active_shake = false
            self.entity.transform.local_translation.value = self.original_position
        end
    end
end

function entity_shake:shake(intensity, duration, ease_duration)
    self.shake_intensity = intensity
    self.shake_duration = duration
    self.ease_duration = ease_duration or duration
    self.ease_start = duration - self.ease_duration >= 0 and (duration - self.ease_duration) or 0
    self.shake_elapsed_time = 0
    self.original_position = self.entity.transform.local_translation.value
    self.current_pos_x, self.current_pos_y, self.current_pos_z = vec3.unpack(self.entity.transform.local_translation.value)
    self.active_shake = true
end

-- TODO: Move easing functions to a utility file
function entity_shake.ease_out_quad(current_time, start_value, end_value, duration)
    local t = current_time / duration
    return start_value + (end_value - start_value) * (1 - (1 - t) * (1 - t))
end

return entity_shake
