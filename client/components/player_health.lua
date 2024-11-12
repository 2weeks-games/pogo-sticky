--
--	 __________					 _________ __  .__		__		   
--	 \______   \____   ____   ____ /   _____//  |_|__| ____ |  | _____.__.
--	  |	 ___/  _ \ / ___\ /  _ \\_____  \\   __\  |/ ___\|  |/ <   |  |
--	  |	|  (  <_> ) /_/  >  <_> )		\|  | |  \  \___|	< \___  |
--	  |____|   \____/\___  / \____/_______  /|__| |__|\___  >__|_ \/ ____|
--					/_____/			   \/			  \/	 \/\/	 
--

local component = scenes.components.component
local resources = require 'resources'
local sprite_layers = require 'sprite_layers'
local player_health = component.derive('player_health')
local player_config = require 'config/player_config'

function player_health:init(entity)
	class.super(player_health).init(self, entity)
	self.health = reactive.create_ref()
	self.health.value = player_config.health
	self.health:register_next(self._on_health_changed, self)
	self.entity:create_gui_text(tostring(self.health), resources.commo_font, 32, sprite_layers.damage_floaters, { grid_align = 1 })
	self.cooldown = 0.0
	self.entity.scene.event_tick:register(self._on_scene_tick, self)
end

function player_health:destroy ()
	self.entity.scene.event_tick:unregister(self._on_scene_tick, self)
end

function player_health:_on_health_changed()
	self.entity.gui_text:set_text(tostring(self.health.value))
end

function player_health:_on_scene_tick()
    self.cooldown = math.max(0.0, self.cooldown - self.entity.scene.tick_rate)
end

return player_health