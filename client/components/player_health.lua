--
--	 __________					 _________ __  .__		__		   
--	 \______   \____   ____   ____ /   _____//  |_|__| ____ |  | _____.__.
--	  |	 ___/  _ \ / ___\ /  _ \\_____  \\   __\  |/ ___\|  |/ <   |  |
--	  |	|  (  <_> ) /_/  >  <_> )		\|  | |  \  \___|	< \___  |
--	  |____|   \____/\___  / \____/_______  /|__| |__|\___  >__|_ \/ ____|
--					/_____/			   \/			  \/	 \/\/	 
--

local component = scenes.components.component
local player_health = component.derive('player_health')
local player_config = require 'config/player_config'
local resources = require 'resources'
local sprite_layers = require 'sprite_layers'

function player_health:init(entity, gui_entity)
	class.super(player_health).init(self, entity)
	self.entity = entity
	self.gui_entity = gui_entity
	self.health = reactive.create_ref()
	self.health.value = player_config.health
	self.health:register_next(self._on_health_changed, self)
	self.health:register_next(self.entity.scene.mode.on_health_changed, self.entity.scene.mode)
	--self.entity:create_gui_text(tostring(self.health), resources.commo_font, 32, sprite_layers.damage_floaters, { grid_align = 1 })
	self.cooldown = 0.0
	self.entity.scene.event_tick:register(self._on_scene_tick, self)
end

function player_health:destroy ()
	self.entity.scene.event_tick:unregister(self._on_scene_tick, self)
end

function player_health:_on_health_changed()
	self.gui_entity.gui_text:set_text(tostring(self.health.value))
	if self.health.value <= 0 then
		self.gui_entity.gui_text:set_color(player_config.color_dormant)
		--self.entity:destroy()
		--self.gui_entity:destroy()
	else
		self.gui_entity.gui_text:set_color(self.entity.color)
	end
end

function player_health:_on_scene_tick()
    self.cooldown = math.max(0.0, self.cooldown - self.entity.scene.tick_rate)
    self.gui_entity.transform:set_world_translation(self.entity.transform:get_world_translation() + vec2.pack(0, -18))
end

return player_health