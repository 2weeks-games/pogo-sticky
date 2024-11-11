--
--	 __________					 _________ __  .__		__		   
--	 \______   \____   ____   ____ /   _____//  |_|__| ____ |  | _____.__.
--	  |	 ___/  _ \ / ___\ /  _ \\_____  \\   __\  |/ ___\|  |/ <   |  |
--	  |	|  (  <_> ) /_/  >  <_> )		\|  | |  \  \___|	< \___  |
--	  |____|   \____/\___  / \____/_______  /|__| |__|\___  >__|_ \/ ____|
--					/_____/			   \/			  \/	 \/\/	 
--

local resources = require 'resources'
local collision_layers = require 'collision_layers'
local sprite_layers = require 'sprite_layers'
local component = scenes.components.component
local transform = scenes.components.transform
local player_move = component.derive('player_move')
local animated_sprite = require 'components/animated_sprite'

-- Constants
local RATE_OF_FIRE_UPGRADE_MAX = 4
local HOOK_SPEED_UPGRADE_MAX = 4
local HOOK_SIZE_UPGRADE_MAX = 4

function player_move:init (entity, variant, location, rotation, aim_component, input_manager)
	class.super(player_move).init(self, entity)
	local scale = self.entity.scene:get_box2d_scale(1)
	self.contact_timer = 0
	self.jump_cooldown = 0.0
	self.health = reactive.create_ref()
	self.health.value = 8
	self.health:register_next(self._on_health_changed, self)
	self.speed_x = 8.1 / 60.0
	self.speed_y = 8.1 / 60.0
	self.max_speed_x = 81.0
	self.max_speed_y = 9.0
	self.rotation_speed = 0.0

	self:set_aim_component(aim_component)
	self._input_manager = input_manager

	-- Root body
	self.entity:create_transform()
	self.entity.transform:set_world_translation(location)
	self.entity.transform:set_world_rotation(quat.from_euler(0, 0, rotation))
	--self.entity:create_sprite(resources.turrets[variant].body, sprite_layers.turret, vec2.pack(62, 42), vec2.pack(31, 0))
	self.entity:create_gui_text(tostring(self.health), resources.commo_font, 32, sprite_layers.damage_floaters, { grid_align = 1 })
	self.entity_physics = self.entity:create_box2d_physics('dynamic', {
		angle = 0.0,
		linear_velocity = vec2.pack(0, 0),
		angular_velocity = 0,
		linear_damping = 0.0,
		angular_damping = 10.0,
		allow_sleep = false,
	})
	self.entity_physics.body:create_fixture(
		--box2d.create_box_shape(self.entity.scene:get_box2d_scale(22, 22)), {
		box2d.create_polygon_shape(10*scale,0*scale, -10*scale,0*scale, -10*scale,40*scale, 10*scale,40*scale), {
		density = 1.0,
		restitution = 0.0,
		is_sensor = false,
		--filter_category = collision_layers.turret,
		--filter_mask = 0
	})
	self.entity_physics.body:create_fixture(
		box2d.create_polygon_shape(2*scale,-1*scale, -2*scale,-1*scale, -2*scale,5*scale, 2*scale,5*scale), {
		is_sensor = true,
	})
	if self.entity.scene.contact_counts == nil then
		self.entity.scene.contact_counts = {}
	end
	self.entity.scene.contact_counts[self.entity_physics.body.id] = 0
	self.entity_physics.event_begin_contact:register(self._on_begin_contact)
	self.entity_physics.event_end_contact:register(self._on_end_contact)

	-- Store variant for position-specific logic
	self.variant = variant

	-- Aim transform which rotates under the body
--	self._aim_transform = self.entity.scene:create_entity('turret_aim', self.entity).transform
--	self._aim_transform.aim_point = vec2.pack(location)
--
--	-- Weapons
--	self.weapon_basic = self.entity:create_component(tw_basic, self, input_manager)
--	self.weapon_beam = self.entity:create_component(tw_beam, self)
--
--	-- Scoring system
--	self.entity:create_component(scoring_system)
--
--	-- Powerup timing
--	self.recent_powerup_time_remaining = 0
--	self.recent_powerup_delay = 3.0
--
--	-- Upgrade tracking
--	self._rate_of_fire_upgrades = 0
--	self._hook_speed_upgrades = 0
--	self._hook_size_upgrades = 0

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

local function is_ground_body(body, bodies)
	for i = 1,#bodies do
		if (bodies[i] == body) then
			return true
		end
	end
	return false
end

local function increment_contact_count(self, a, b, inc)
	local a_is_ground = is_ground_body(a.body, self.entity.scene.ground_bodies)
	local b_is_ground = is_ground_body(b.body, self.entity.scene.ground_bodies)
	local other = a_is_ground and a or b_is_ground and b or nil
	if other ~= nil then
		local id = a == other and b.body.id or a.body.id
		self.entity.scene.contact_counts[id] = self.entity.scene.contact_counts[id] + inc
		--print(self.entity.scene.contact_counts[id])
	end
end

function player_move:_on_begin_contact(a, b)
	increment_contact_count(self, a, b, 1)
end

function player_move:_on_end_contact(a, b)
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
		local value, elapsed = self._aim_component._player_input:get_key_state('up')
		local size_y = self.entity.scene.size_y
		if value then
			--print("up " .. tostring(value) .. " " .. tostring(elapsed))
			apply_impulse(self.entity_physics.body, 0, size_y)
			self.jump_cooldown = 0.5
			self.health.value = self.health.value + 1
		elseif self.contact_timer > 0.05 then
			--print("lil jump")
			apply_impulse(self.entity_physics.body, 0, size_y * 0.2)
			self.jump_cooldown = 0.1
		end
	end
end

-- Events
function player_move:_on_health_changed()
	self.entity.gui_text:set_text(tostring(self.health.value))
end

function player_move:_on_scene_tick ()
	--self._aim_transform.aim_point = vec2.pack(self._aim_transform.aim_point, self._aim_component:get_current_world_aim())
	--self._aim_transform:look_at_world_2d(self._aim_transform.aim_point)

	local contact_count = self.entity.scene.contact_counts[self.entity_physics.body.id]
	if contact_count > 0 then
		self.contact_timer = self.contact_timer + self.entity.scene.tick_rate
	end
	self.jump_cooldown = math.max(0.0, self.jump_cooldown - self.entity.scene.tick_rate)
	--print("contact " .. self.contact_timer .. " jump " .. self.jump_cooldown)

	-- jump and pogo
	self:_jump(contact_count)

	-- move left / right
	local body = self.entity_physics.body
	local velx, vely = vec2.unpack(body:get_linear_velocity())
	local avel = body:get_angular_velocity()
	local left_down = self._aim_component._player_input:get_key_state('left')
	local right_down = self._aim_component._player_input:get_key_state('right')
	if left_down then
		velx = math.max(velx - self.speed_x, -self.max_speed_x)
		avel = avel + self.rotation_speed
	elseif right_down then
		velx = math.min(velx + self.speed_x, self.max_speed_x)
		avel = avel - self.rotation_speed
	end
	vely = math.min(vely, self.max_speed_y)
	vely = math.max(vely, -self.max_speed_y)
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
