--
--	 __________					 _________ __  .__		__		   
--	 \______   \____   ____   ____ /   _____//  |_|__| ____ |  | _____.__.
--	  |	 ___/  _ \ / ___\ /  _ \\_____  \\   __\  |/ ___\|  |/ <   |  |
--	  |	|  (  <_> ) /_/  >  <_> )		\|  | |  \  \___|	< \___  |
--	  |____|   \____/\___  / \____/_______  /|__| |__|\___  >__|_ \/ ____|
--					/_____/			   \/			  \/	 \/\/	 
--

local component = scenes.components.component
local transform = scenes.components.transform
local player_ai = component.derive('player_ai')
local player_config = require 'config/player_config'
local resources = require 'resources'
local collision_layers = require 'collision_layers'
local sprite_layers = require 'sprite_layers'
local animated_sprite = require 'components/animated_sprite'

local jump_hold_duration = 0.5
local stomp_hold_duration = 0.2

function player_ai:init(entity, input, play_slot)
	class.super(player_ai).init(self, entity)
	self.session = self.entity.scene.mode.game_session.pogo_session
	self.generator = self.entity.scene.mode.generator
	self.play_slot = play_slot
	self.keys_down = {}
	self.cooldown = (2.0 + 2.0 * self.generator:next()) * (1.0 - player_config.ai_intelligence)
	self.input = input
	
	self.entity.scene.event_tick:register(self._on_scene_tick, self)
end

function player_ai:destroy()
	self.entity.scene.event_tick:unregister(self._on_scene_tick, self)
end

function player_ai:key_to_state(key, down)
	if key == 'Left' then
		return {left = down}
	elseif key == 'Right' then
		return {right = down}
	elseif key == 'Up' then
		return {up = down}
	elseif key == 'Down' then
		return {down = down}
	end
	return {}
end

function player_ai:press_key(key)
	if self.keys_down[key] == nil then self.keys_down[key] = -1.0 end

	if self.keys_down[key] < 0.0 then
		--self.session:on_local_keyboard_key_down(key)
		self.input:set_state(self:key_to_state(key, true), self.entity.scene.tick_timestamp)
		self.keys_down[key] = 0.0
		self.cooldown = (2.0 + 8.0 * self.generator:next()) * (1.0 - player_config.ai_intelligence)
	end
end

function player_ai:release_key(key)
	if self.keys_down[key] == nil then self.keys_down[key] = -1.0 end

	if self.keys_down[key] >= 0.0 then
		self.input:set_state(self:key_to_state(key, false), self.entity.scene.tick_timestamp)
		--self.session:on_local_keyboard_key_up(key)
		self.keys_down[key] = -1.0
		self.cooldown = (4.0 + 16.0 * self.generator:next()) * (1.0 - player_config.ai_intelligence)
	end
end

function player_ai:is_key_pressed(key)
	if self.keys_down[key] == nil then self.keys_down[key] = -1.0 end

	return self.keys_down[key] >= 0.0
end

-- Events
function player_ai:_on_scene_tick()
	--if true then return end

	if self.entity.scene.mode.finished then return end
	local alive = self.entity.player_health.health.value > 0
	local tick_rate = self.entity.scene.tick_rate
	local r = self.generator:next()
	--print("ai tick " .. self.play_slot .. " r " .. r)
	
	-- tick
	self.cooldown = math.max(0.0, self.cooldown - tick_rate)
	
	-- handle movement
	if alive and self.cooldown == 0.0 then
		local left_pressed = self:is_key_pressed('Left')
		local right_pressed = self:is_key_pressed('Right')
		if r < tick_rate * 2.0 then
			if left_pressed then
				self:release_key('Left')
			elseif right_pressed then
				self:release_key('Right')
			elseif r < tick_rate * 1.0 then
				self:press_key('Left')
			else
				self:press_key('Right')
			end
		end
		if left_pressed or right_pressed then
			if self.entity.player_move:can_jump() then
				self:press_key('Up')
				--print(self.entity.username .. " AI jump")
			elseif self.entity.player_move:can_stomp() and self.entity.player_move.no_contact_timer > 0.5 then
				self:press_key('Down')
				--print(self.entity.username .. " AI stomp")
			end
		end
	end

	-- update keys
	for k, v in pairs(self.keys_down) do
		if v >= 0.0 then
			self.keys_down[k] = v + tick_rate
			
			-- release keys
			if k == 'Up' and self.keys_down[k] >= jump_hold_duration then
				self:release_key(k)
			elseif k == 'Down' and self.keys_down[k] >= stomp_hold_duration then
				self:release_key(k)
			end
		end
	end
end

return player_ai

