local resources = require 'resources'
local sprite_layers = require 'sprite_layers'
local floater = require 'components/floater'
local component = scenes.components.component
local transform = scenes.components.transform
local entity_health_and_death = component.derive('entity_health_and_death')

function entity_health_and_death:init(entity, hp_max, kill_value)
    class.super(entity_health_and_death).init(self, entity)

    self.hp_max = hp_max or 1
    self.hp_current = hp_max
    self.dead = false
    self.generator = self.entity.scene.kaiju_mode.generator

    self.event_took_damage = event.new()
    self.event_death = event.new()
end

function entity_health_and_death:destroy()
end

function entity_health_and_death:apply_damage(payload, position, desired_size, desired_color, desired_lifetime)
    self.hp_current = self.hp_current - payload.damage
    self.event_took_damage:dispatch(payload.damage)

    -- create a damage floater
    local floater_color = desired_color or '#FFFFFF'
    local floater_size = desired_size or 32
    local floater_lifetime = desired_lifetime or 0.4
    local floater_pos = position or self.entity.transform:get_world_translation()
    local floater_entity = self.entity.scene:create_entity()
    floater_entity:create_transform(nil, floater_pos + vec2.pack(self.generator:next(-4, 4), 16 + self.generator:next(-4, 4)))
    floater_entity:create_gui_text(tostring(payload.damage), resources.commo_font, floater_size, sprite_layers.damage_floaters, { grid_align = 1, color = floater_color })
    floater_entity:create_component(floater, vec2.pack(0, 10), floater_lifetime, 0.1)

    if not self.dead and self.hp_current <= 0 then
        self.dead = true
        self.event_death:dispatch()
    end
end

return entity_health_and_death
