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

function player_health:init(entity)
	class.super(player_health).init(self, entity)
	self.entity = entity
	self.health = reactive.create_ref()
	self.health.value = player_config.health
	self.health:register_next(self._on_health_changed, self)
	self.health:register_next(self.entity.scene.mode.on_health_changed, self.entity.scene.mode)
	self.shield = reactive.create_ref()
	self.shield.value = 0
	self.shield:register_next(self._on_health_changed, self)
	self.cooldown = 0.0
	self.entity.scene.event_tick:register(self._on_scene_tick, self)
end

function player_health:destroy()
	self.entity.scene.event_tick:unregister(self._on_scene_tick, self)
end

function player_health:_set_text_color()
	if self.health.value <= 0 then
		self.entity.gui_entity.gui_text:set_color(player_config.color_dormant)
	else
		self.entity.gui_entity.gui_text:set_color(self.entity.color)
	end
end

function player_health:_on_health_changed()
	local str = tostring(self.health.value) 
	if self.shield.value > 0 then
		str = str .. "+" .. tostring(self.shield.value)
	end
	self.entity.gui_entity.gui_text:set_text(str)
	self:_set_text_color()
end

function player_health:_on_scene_tick()
	if self.entity.scene.mode.finished then return end

	-- update cooldown
	self.cooldown = math.max(0.0, self.cooldown - self.entity.scene.tick_rate)
	if self.cooldown > 0.0 then
		local str = tostring(self.health.value)
		for i = 0, 2 do
			if self.cooldown > self.entity.scene.tick_rate + i then str = str .. "." end
		end
		self.entity.gui_entity.gui_text:set_text(str)
		self:_set_text_color()
	end
	
	-- move health gui to below player
	self.entity.gui_entity.transform:set_world_translation(self.entity.transform:get_world_translation() + vec2.pack(0, -18))
end

return player_health