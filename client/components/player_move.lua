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
local player_move = component.derive('player_move')
local player_config = require 'config/player_config'
local resources = require 'resources'
local collision_layers = require 'collision_layers'
local sprite_layers = require 'sprite_layers'
local animated_sprite = require 'components/animated_sprite'

function player_move:init(entity, variant, location, rotation, aim_component)
	class.super(player_move).init(self, entity)
	local scale = self.entity.scene:get_box2d_scale(1)
	self.contact_timer = 0
	self.jump_cooldown = 0.0
	self.speed_x = player_config.speed_x
	self.speed_y = player_config.speed_y
	self.max_speed_x = player_config.max_speed_x
	self.max_speed_y_pos = player_config.max_speed_y_pos
	self.max_speed_y_neg = player_config.max_speed_y_neg
	self.rotation_speed = player_config.rotation_speed

	self:set_aim_component(aim_component)

	-- Root body
	self.entity:create_transform()
	self.entity.transform:set_world_translation(location)
	self.entity.transform:set_world_rotation(quat.from_euler(0, 0, rotation))
	--self.entity:create_sprite(resources.turrets[variant].body, sprite_layers.turret, vec2.pack(62, 42), vec2.pack(31, 0))
	self.entity.physics = self.entity:create_box2d_physics('dynamic', {
		angle = 0.0,
		linear_velocity = vec2.pack(0, 0),
		angular_velocity = 0,
		linear_damping = player_config.linear_damping,
		angular_damping = player_config.angular_damping,
		allow_sleep = false,
	})
	self.entity.physics.body:create_fixture(
		--box2d.create_box_shape(self.entity.scene:get_box2d_scale(22, 22)), {
		box2d.create_polygon_shape(10*scale,-20*scale, -10*scale,-20*scale, -10*scale,20*scale, 10*scale,20*scale), {
		density = player_config.density,
		restitution = player_config.restitution,
		is_sensor = false,
		--filter_category = collision_layers.turret,
		--filter_mask = 0
	})
	self.entity.size_x = 4
	self.entity.size_y = 6
	self.entity.physics.body:create_fixture(
		box2d.create_polygon_shape(2*scale,-3*scale, -2*scale,-3*scale, -2*scale,3*scale, 2*scale,3*scale), {
		is_sensor = true,
	})
	self.entity.scene.bodies[self.entity.physics.body.id] = self.entity

	-- track contacts
	if self.entity.scene.contact_counts == nil then
		self.entity.scene.contact_counts = {}
	end
	self.entity.scene.contact_counts[self.entity.physics.body.id] = 0
	self.entity.physics.event_begin_contact:register(self._on_begin_contact)
	self.entity.physics.event_end_contact:register(self._on_end_contact)

	-- Store variant for position-specific logic
	self.variant = variant

	-- Aim transform which rotates under the body
	--self._aim_transform = self.entity.scene:create_entity('turret_aim', self.entity).transform
	--self._aim_transform.aim_point = vec2.pack(location)

	self.entity.scene.event_tick:register(self._on_scene_tick, self)
end

function player_move:destroy ()
	self.entity.scene.event_tick:unregister(self._on_scene_tick, self)
end

function player_move:set_aim_component (aim_component)
	self._aim_component = aim_component
end

function player_move:get_aim_component ()
	return self._aim_component
end

function player_move:get_aim_transform ()
	return self._aim_transform
end

local function get_entity(self, a)
	return self.entity.scene.bodies[a.body.id]
end

--local function contains(val, table)
--	for i = 1,#table do
--		if (table[i] == val) then
--			return true
--		end
--	end
--	return false
--end

local function increment_contact_count(self, a, b, inc)
	if a == nil or b == nil then return end
	local player = a.name == 'player' and a or b.name == 'player' and b or nil
	local ground = a.name == 'ground' and a or b.name == 'ground' and b or nil
	if player and ground then
		self.entity.scene.contact_counts[player.physics.body.id] = self.entity.scene.contact_counts[player.physics.body.id] + inc
		--print(self.entity.scene.contact_counts[id])
	end
end

local function steal_health(self, a, b, inc)
	if a == nil or b == nil then return end
	local player1 = a.name == 'player' and a or nil
	local player2 = b.name == 'player' and b or nil

	if player1 and player2 then
		--print("begin p" .. player1.player_move.variant .. " p" .. player2.player_move.variant .. " time " .. time.seconds_since_start())
		-- this method is called for both players in the collision
		-- so just return if player1 is not on top
		local p1x, p1y = vec2.unpack(player1.transform:get_world_translation())
		local p2x, p2y = vec2.unpack(player2.transform:get_world_translation())
		local xo = p1x - p2x
		local yo = p1y - p2y
		-- check for some x overlap
		-- this would be more accurate if we could get the player's actual width depending on their rotation
		-- for example, if the player is laying on their side, then the width would be longer
		--print("p1 " .. p1x .. "," .. p1y .. " " .. player1.size_x .. "x" .. player1.size_y .. " p2 " .. p2x .. "," .. p2y .. " overlap " .. xo .. "," .. yo .. " time " .. time.seconds_since_start())
		--if math.abs(xo) > player1.size_x * 0.45 then
		if math.abs(xo) > 20 then
			--print("  x diff too big " .. xo)
			return
		end
		-- check for player1 above player2
		--if p1y < p2y + player2.size_y * 0.25 then return end
		if yo < -20.0 then
			--print("  y diff < 0 " .. yo)
			return
		end
		-- check for health cooldown
		if player2.player_health.cooldown > 0.0 then
			--print("  health cooldown " .. player2.player_health.cooldown)
			return
		end
		-- check for health
		if player2.player_health.health.value <= 0 then
			--print("  health <= 0 " .. player2.player_health.health.value)
			return
		end

		player1.player_health.health.value = player1.player_health.health.value + inc
		player2.player_health.health.value = player2.player_health.health.value - inc
		--print("p" .. player1.player_move.variant .. " health " .. player1.player_health.health.value
			--.. " p" .. player2.player_move.variant .. " health " .. player2.player_health.health.value)
		player2.player_health.cooldown = 0.5
	end
end

function player_move:_on_begin_contact(a, b)
	a = get_entity(self, a)
	b = get_entity(self, b)
	increment_contact_count(self, a, b, 1)
	steal_health(self, a, b, 1)
end

function player_move:_on_end_contact(a, b)
	a = get_entity(self, a)
	b = get_entity(self, b)
	increment_contact_count(self, a, b, -1)
end

local function apply_impulse(body, impulseX, impulseY)
	local mass = body:get_mass()
	impulseX = impulseX * mass
	impulseY = impulseY * mass
	body:apply_linear_impulse(vec2.pack(impulseX, impulseY), body:get_world_point())
end

function player_move:_jump(contact_count)
	if contact_count > 0 and self.jump_cooldown == 0.0 then
		local value, elapsed = self.entity.player_input:get_key_state('up')
		local size_y = self.entity.scene.size_y
		if value then
			--print("up " .. tostring(value) .. " " .. tostring(elapsed))
			apply_impulse(self.entity.physics.body, 0, player_config.jump_impulse_y)
			self.jump_cooldown = 0.5
		elseif self.contact_timer > 0.05 then
			--print("lil jump")
			apply_impulse(self.entity.physics.body, 0, player_config.pogo_impulse_y)
			self.jump_cooldown = 0.1
		end
	end
end

-- Events
function player_move:_on_scene_tick ()
	if self.entity.scene.mode.finished then
		self.entity.physics.body:set_linear_velocity(vec2.pack(0, 0))
		return
	end
	local alive = self.entity.player_health.health.value > 0

	--self._aim_transform.aim_point = vec2.pack(self._aim_transform.aim_point, self._aim_component:get_current_world_aim())
	--self._aim_transform:look_at_world_2d(self._aim_transform.aim_point)

	local contact_count = self.entity.scene.contact_counts[self.entity.physics.body.id]
	if contact_count > 0 then
		self.contact_timer = self.contact_timer + self.entity.scene.tick_rate
	end
	self.jump_cooldown = math.max(0.0, self.jump_cooldown - self.entity.scene.tick_rate)
	--print("contact " .. self.contact_timer .. " jump " .. self.jump_cooldown)

	if alive then
		-- jump and pogo
		self:_jump(contact_count)
	end

	local body = self.entity.physics.body
	local velx, vely = vec2.unpack(body:get_linear_velocity())
	local avel = body:get_angular_velocity()
	if alive then
		-- move left / right
		local left_down = self.entity.player_input:get_key_state('left')
		local right_down = self.entity.player_input:get_key_state('right')
		if left_down then
			velx = velx - self.speed_x
			avel = avel + self.rotation_speed
		elseif right_down then
			velx = velx + self.speed_x
			avel = avel - self.rotation_speed
		end
	end
	velx = math.min(velx, self.max_speed_x)
	velx = math.max(velx, -self.max_speed_x)
	vely = math.min(vely, self.max_speed_y_pos)
	vely = math.max(vely, -self.max_speed_y_neg)
	body:set_linear_velocity(vec2.pack(velx, vely))
	body:set_angular_velocity(avel)
	--print("velx: " .. velx .. " vely: " .. vely .. " avel: " .. avel)

	-- warp to other side of screen if off screen
	local scene = self.entity.scene
	local scale = self.entity.scene:get_box2d_scale(1)
	local size_x, size_y = scene.size_x / scale, scene.size_y / scale
	local x, y = vec2.unpack(self.entity.transform:get_world_translation())
	local new_x, new_y = x, y
	if x > size_x * 0.5 then
		new_x = new_x - size_x
	elseif x < size_x * -0.5 then
		new_x = new_x + size_x
	end
	if y > size_y * 0.5 then
		new_y = new_y - size_y
	elseif y < size_y * -0.5 then
		new_y = new_y + size_y
	end
	if new_x ~= x or new_y ~= y then
		self.entity.transform:set_world_translation(vec2.pack(new_x, new_y))
	end
	--print(x .. " " .. y .. " " .. new_x .. " " .. new_y)
end

return player_move
