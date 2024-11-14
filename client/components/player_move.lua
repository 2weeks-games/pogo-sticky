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
	self._aim_component = aim_component

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
	self.entity.physics.ground_contact_count = 0
	self.entity.physics.player_contacts = {}
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

local function get_entity(self, a)
	return self.entity.scene.bodies[a.body.id]
end

--local function toint(val)
--	return string.format("%.0f", val)
--end

local function is_on_top(player1, player2)
	-- this method is called for both players in the collision
	-- so just return false if player1 is not on top
	--print("begin p" .. player1.player_move.variant .. " p" .. player2.player_move.variant .. " time " .. time.seconds_since_start())
	local p1x, p1y = vec2.unpack(player1.transform:get_world_translation())
	local p2x, p2y = vec2.unpack(player2.transform:get_world_translation())
	local xo = p1x - p2x
	local yo = p1y - p2y
	-- check for some x overlap
	-- this would be more accurate if we could get the player's actual width depending on their rotation
	-- for example, if the player is laying on their side, then the width would be longer
	--print(player1.username .. " " .. toint(p1x) .. "," .. toint(p1y) .. " "
	--	.. player2.username .. " " .. toint(p2x) .. "," .. toint(p2y) .. " overlap "
	--	.. toint(xo) .. "," .. toint(yo) .. " time " .. time.seconds_since_start())
	----if math.abs(xo) > player1.size_x * 0.45 then
	--if math.abs(xo) > 20 then
	--	--print("  x diff too big " .. xo)
	--	return false
	--end
	-- check for player1 above player2
	--if p1y < p2y + player2.size_y * 0.25 then return end
	if yo < player_config.on_top_height then
		--print("  y diff < 0 " .. yo)
		return false
	end
	--print("  y diff good " .. toint(yo))
	return true
end

local function increment_contact_count(self, a, b, inc)
	if a == nil or b == nil then return end
	local player = a.name == 'player' and a or b.name == 'player' and b or nil
	local other = player == a and b or player == b and a or nil
	--if a.username and a.username == 'Nat' or b.username and b.username == 'Nat' then
	--	print("contact between " .. (a.name == 'player' and a.username or a.name) .. " and "
	--		.. (b.name == 'player' and b.username or b.name) .. " inc " .. inc)
	--end
	if player and other then
		if other.name == 'player' then
			if inc > 0 then
				if not player.physics.player_contacts[other] then
					player.physics.player_contacts[other] = {elapsed = 0.0, on_top = is_on_top(player, other)}
					--print("  contact begin " .. player.username .. " " .. other.username .. " " .. time.seconds_since_start())
				end
			else
				--print("  contact end " .. player.username .. " " .. other.username .. " " .. time.seconds_since_start())
				player.physics.player_contacts[other] = nil
			end
		elseif other.name == 'ground' then
			player.physics.ground_contact_count = player.physics.ground_contact_count + inc
		end 
	end
end

function player_move:_on_begin_contact(a, b)
	a = get_entity(self, a)
	b = get_entity(self, b)
	increment_contact_count(self, a, b, 1)
end

function player_move:_on_end_contact(a, b)
	a = get_entity(self, a)
	b = get_entity(self, b)
	increment_contact_count(self, a, b, -1)
end

function player_move:_steal_health(player2, inc)
	local player1 = self.entity
	if player1 and player2 then
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
		player2.player_health.cooldown = player_config.health_cooldown
	end
end

local function apply_impulse(body, impulseX, impulseY)
	local mass = body:get_mass()
	impulseX = impulseX * mass
	impulseY = impulseY * mass
	body:apply_linear_impulse(vec2.pack(impulseX, impulseY), body:get_world_point())
end

function player_move:_jump()
	if self.jump_cooldown > 0.0 then return end
	local on_top = false
	for k, v in pairs(self.entity.physics.player_contacts) do
		if v.on_top then
			on_top = true
			break
		end
	end

	if self.entity.physics.ground_contact_count > 0 or on_top then
		local value, elapsed = self.entity.player_input:get_key_state('up')
		local size_y = self.entity.scene.size_y
		if value then
			--print("up " .. tostring(value) .. " " .. tostring(elapsed))
			apply_impulse(self.entity.physics.body, 0, player_config.jump_impulse_y)
			self.jump_cooldown = player_config.jump_cooldown
		elseif self.contact_timer > 0.05 then
			--print("lil jump")
			apply_impulse(self.entity.physics.body, 0, player_config.pogo_impulse_y)
			self.jump_cooldown = player_config.pogo_cooldown
		end
	end
end

function player_move:_move_x(alive)
	local body = self.entity.physics.body
	local velx, vely = vec2.unpack(body:get_linear_velocity())
	local avel = body:get_angular_velocity()
	if alive then
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
end

function player_move:_update_player_contacts()
	--self.entity.gui_entity.gui_text:set_text("")
	for k, v in pairs(self.entity.physics.player_contacts) do
		v.elapsed = v.elapsed + self.entity.scene.tick_rate
		if not is_on_top(self.entity, k) then
			v.on_top = false
		end
		--if v.on_top then print(self.entity.username .. " on top " .. k.username .. " " .. string.format("%.2f", v.elapsed) .. " health " .. k.player_health.health.value .. " cooldown " .. string.format("%.2f", k.player_health.cooldown) .. " time " .. string.format("%.2f", time.seconds_since_start())) end
		if v.on_top and v.elapsed >= player_config.health_steal_ticks * self.entity.scene.tick_rate then
			self:_steal_health(k, 1)
		end
		--if self.variant == 1 then self.entity.gui_entity.gui_text:set_text(tostring(v.on_top) .. " " .. string.format("%.1f", v.elapsed)) end
		--print("contact " .. k.player_move.variant .. " " .. v.elapsed)
	end
end

function player_move:_on_scene_tick ()
	if self.entity.scene.mode.finished then
		self.entity.physics.body:set_linear_velocity(vec2.pack(0, 0))
		return
	end
	local alive = self.entity.player_health.health.value > 0

	--self._aim_transform.aim_point = vec2.pack(self._aim_transform.aim_point, self._aim_component:get_current_world_aim())
	--self._aim_transform:look_at_world_2d(self._aim_transform.aim_point)

	if self.entity.physics.ground_contact_count > 0 then
		self.contact_timer = self.contact_timer + self.entity.scene.tick_rate
	end
	self.jump_cooldown = math.max(0.0, self.jump_cooldown - self.entity.scene.tick_rate)
	--print("contact " .. self.contact_timer .. " jump " .. self.jump_cooldown)

	-- update player contacts
	self:_update_player_contacts()

	-- jump and pogo
	if alive then
		self:_jump()
	end

	-- move left / right
	self:_move_x(alive)
end

return player_move
