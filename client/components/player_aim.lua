--[[
    Player Aim Component
    Provides aiming information to other parts of the game
]]

local component = scenes.components.component
local transform = scenes.components.transform
local mode = require 'modes/mode'
local resources = require 'resources'
local sprite_layers = require 'sprite_layers'

local player_aim = component.derive('player_aim')

local SHOW_NETWORK_CURSOR = false

-- Public

function player_aim:init(entity, player_input, variant)
    class.super(player_aim).init(self, entity)
    self._player_input = player_input

    self.entity:create_transform()
    self.entity.transform:set_world_translation(vec2.pack())
    if not self:is_local_aim() or SHOW_NETWORK_CURSOR then
        self.entity:create_sprite(resources.turrets[variant].cursor, sprite_layers.cursors, vec2.pack(64, 64))
    end

    if self:is_local_aim() then
        self.local_cursor = self.entity.scene:create_entity()
        self.local_cursor:create_transform()
        self.local_cursor:create_sprite(resources.turrets[variant].cursor, sprite_layers.cursors, vec2.pack(64, 64))
    end

    self.entity.scene.event_tick:register(self._on_scene_tick, self)
end

function player_aim:is_local_aim()
    local session = self.entity.scene.kaiju_mode.game_session.pogo_session
    return session and session.connection.local_host ~= nil
end

function player_aim:destroy()
    self.entity.scene.event_tick:unregister(self._on_scene_tick, self)
end

function player_aim:get_current_world_aim()
    local p = self.entity.transform:get_world_translation()
    local aim_x, aim_y = vec3.unpack(p)
    return aim_x, aim_y
end

-- Private

function player_aim:_on_scene_tick()
    local network_x, network_y = self._player_input:get('mouse_x'), self._player_input:get('mouse_y')
    if network_x and network_y then
        self.entity.transform:set_world_translation(vec3.pack(network_x, network_y, 0))
    end
    if self.local_cursor then
        local session = self.entity.scene.kaiju_mode.game_session.pogo_session
        self.local_cursor.transform:set_world_translation(vec3.pack(session.local_x, session.local_y, 0))
    end
end

return player_aim
