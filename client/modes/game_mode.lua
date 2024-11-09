--
--	 __________					 _________ __  .__		__		   
--	 \______   \____   ____   ____ /   _____//  |_|__| ____ |  | _____.__.
--	  |	 ___/  _ \ / ___\ /  _ \\_____  \\   __\  |/ ___\|  |/ <   |  |
--	  |	|  (  <_> ) /_/  >  <_> )		\|  | |  \  \___|	< \___  |
--	  |____|   \____/\___  / \____/_______  /|__| |__|\___  >__|_ \/ ____|
--					/_____/			   \/			  \/	 \/\/	 
--

local resources = require 'resources'
local sprite_layers = require 'sprite_layers'
local client_ui = require 'client_ui'
local mode = require 'modes/mode'

local animated_sprite = require 'components/animated_sprite'
local entity_shake = require 'components/entity_shake'
local input_manager = require 'components/input_manager'
local player_move = require 'components/player_move'
local player_aim_component = require 'components/player_aim'
local player_config = require 'config/player_config'

local wall_thickness = 5
local contact_count = 0
local contact_timer = 0.0
local jump_cooldown = 0.0
local restitution = 0.0
local ground_bodies = {}

---@class game_mode:mode
local game_mode = class.create(mode)

function game_mode:init(seed, mode_players, game_session)
	class.super(game_mode).init(self, 960, 540, seed, mode_players, game_session)

	-- create box2d world
	self.scene.size_x = 8.0
	self.scene.size_y = 8.0
	local pixels_per_meter = self.pixel_size_y / self.scene.size_y
	local gravity = vec2.pack(0, -9.8)
	self.scene.ground_bodies = {}

	self.scene:set_box2d_debug_draw_enabled(true)
	local b2world = self.scene:get_box2d_world()
	self.scene:set_box2d_world_scale(1.0 / pixels_per_meter)
	b2world:set_gravity(gravity)

	-- create camera
	self.camera_entity.transform.local_translation.value = vec3.pack(0, 0, 1)
	self.camera_entity.transform:look_at_local(vec3.pack(0, 0, 0))
	self.camera_entity:create_component(entity_shake)

	-- create background
	self.background = self.scene:create_entity('background')
	self.background:create_transform()
	self.background:create_sprite(resources.background_tex, sprite_layers.background, vec2.pack(960, 540), vec2.pack(960/2, 540/2))

	-- create blocks
	local s_2 = self.scene.size_y * pixels_per_meter
	--self:create_block(s_2 * 0, s_2 *-0.45, s_2 * 1.0, s_2 * 0.1)
	self:create_block(s_2 *-0.3, s_2 *-0.45, s_2 * 0.2, s_2 * 0.05)
	self:create_block(s_2 * 0.3, s_2 *-0.45, s_2 * 0.2, s_2 * 0.05)
	self:create_block(s_2 *-0.3, s_2 * 0.2, s_2 * 0.0375, s_2 * 0.0375)
	self:create_block(s_2 *-0.2, s_2 *-0.2, s_2 * 0.0375, s_2 * 0.0375)
	self:create_block(s_2 * 0.2, s_2 *-0.1, s_2 * 0.0375, s_2 * 0.0375)
	self:create_block(s_2 * 0.25,s_2 * 0.1, s_2 * 0.0375, s_2 * 0.0375)

	--self.player = self.scene:create_entity('player')
	--self.player:create_transform()
	--self.player:create_sprite(resources.drone_blue_01_tex, sprite_layers.enemies, vec2.pack(55, 55), vec2.pack(55/2, 55/2))
	--self.player:create_box2d_physics('dynamic')
	--self.player.box2d_physics.body:create_fixture(box2d.create_circle_shape(self.scene:get_box2d_scale(20)), {
	--	is_sensor = true,
	--	--filter_category = collision_layers.enemy,
	--	--filter_mask = collision_layers.weapon + collision_layers.kill_plane
	--})

	--self.background = self.scene:create_entity('background')
	--self.background:create_sprite(resources.background_tex, sprite_layers.background, vec2.pack(960, 540), vec2.pack(960/2, 540/2))

--	self.combat_music = false

	-- // Turrets
	local turret_spawns = {
		{ position = vec2.pack(0, s_2 * 0.45), angle = 0 },
		{ position = vec2.pack(240, -270), angle = 0 },
		{ position = vec2.pack(-240, 270), angle = 0 },
		{ position = vec2.pack(240, 270), angle = 0 },
	}

	self.mode_players = mode_players
	self.turrets = {}
	self.turret_huds = {}
	self._turrets_by_player = {}
	if true then
		for i = 1, #self.mode_players do
			local player = self.mode_players[i]
			if player.play_slot and player.play_slot > 0  and player.play_slot <= #turret_spawns then
				local spawn = turret_spawns[player.play_slot]
				local turret = self:spawn_turret(player.play_slot, spawn.position, spawn.angle, true, self.inputs[i])
				if turret then
					self._turrets_by_player[player] = turret
					table.insert(self.turrets, turret)
					--table.insert(self.turret_huds, self:_spawn_turret_hud(player.play_slot, spawn.position, turret))
				end
			end
		end
	end

--	-- Music
--	self.combat_music = audio_manager:play_music('assets/audio/music/KDC_Test_combat_3.mp3', true, 0.3)

	self.scene.event_update:register(self._on_scene_update, self)
end

function game_mode:destroy()
	class.super(game_mode).destroy(self)
	self.scene.event_update:unregister(self._on_scene_update, self)
end

function game_mode:_on_scene_update (elapsed_seconds)
end

function game_mode:create_block(x, y, w, h)
	local scale = self.scene:get_box2d_scale(1)
	local ground_height = self.scene.size_y * 0.01

	local block = self.scene:create_entity('block')
	block:create_transform()
	block.transform:set_world_translation(vec2.pack(x, (y - ground_height)))
	block:create_box2d_physics('static')
	block.box2d_physics.body:create_fixture(box2d.create_box_shape(w * scale, (h - ground_height) * scale))

	local ground = self.scene:create_entity('ground')
	ground:create_transform()
	ground.transform:set_world_translation(vec2.pack(x, (y + h - ground_height)))
	ground:create_box2d_physics('static')
	ground.box2d_physics.body:create_fixture(box2d.create_box_shape(w * scale, ground_height * scale))
	table.insert(ground_bodies, ground.box2d_physics.body)
end

function game_mode:spawn_turret(variant, position, rotation, is_hook_controlled, player_input)
	-- Mouse-controlled aim
	local player_aim_entity = self.scene:create_entity('player_aim')
	local player_aim = player_aim_entity:create_component(player_aim_component, player_input, variant)

	local turret_entity = self.scene:create_entity('turret')
	local input = turret_entity:create_component(input_manager, player_input)
	local turret = turret_entity:create_component(player_move, variant, position, rotation, player_aim, input)
	turret_entity:create_component(game_framework.components.buffable)

	turret.speed_x = 8.1 / 60.0
	turret.speed_y = 8.1 / 60.0
	turret.max_speed_x = 81.0
	turret.max_speed_y = 9.0
	turret.rotation_speed = 0.0

	return turret_entity
end

--local dynamic_polygon_body = world:create_dynamic_body({
--	position = vec2.pack(level_size_x * 0.5, level_size_y * 0.9),
--	angle = 0.0,
--	linear_velocity = vec2.pack(0, 0),
--	angular_velocity = 0,
--	linear_damping = 0.5,
--	angular_damping = 10.0,
--	allow_sleep = false
--})
--dynamic_polygon_body:create_fixture(
--	box2d.create_polygon_shape(1,0, -1,0, -1,4, 1,4), {
--	density = 1.0,
--	restitution = restitution,
--})
--local dynamic_polygon_sensor = dynamic_polygon_body:create_fixture(
--	box2d.create_polygon_shape(2,-1, -2,-1, -2,5, 2,5), {
--	is_sensor = true,
--})
--
--local function screen_to_world(x, y)
--	local u, v = x / display_size_x, y / display_size_y
--	return u * level_size_x, -v * level_size_y + level_size_y
--end
--
--local function find_fixture(x, y)
--	local fixtures = world:query_aabb(x, y, x, y)
--	for i = 1, #fixtures do
--		local fixture = fixtures[i]
--		if fixture:test_point(x, y) and fixture.body:is_dynamic() then
--			return fixture
--		end
--	end
--end
--
--function is_ground_body(body)
--	for i = 1,#ground_bodies do
--		if (ground_bodies[i] == body) then
--			return true
--		end
--	end
--	return false
--end
--
--world:set_begin_contact_handler(function(fixture_a, fixture_b)
--	if fixture_a == dynamic_polygon_sensor or fixture_b == dynamic_polygon_sensor then
--		local sensor = fixture_a == dynamic_polygon_sensor and fixture_a or fixture_b
--		local fixture = fixture_a == dynamic_polygon_sensor and fixture_b or fixture_a
--		--local sensor_pos_x, sensor_pos_y = vec2.unpack(sensor.body:get_world_point())
--		--local fixture_pos_x, fixture_pos_y = vec2.unpack(fixture.body:get_world_point())
--		if is_ground_body(fixture.body) then
--			contact_count = contact_count + 1
--		end
--	end
--end)
--world:set_end_contact_handler(function(fixture_a, fixture_b)
--	if fixture_a == dynamic_polygon_sensor or fixture_b == dynamic_polygon_sensor then
--		local sensor = fixture_a == dynamic_polygon_sensor and fixture_a or fixture_b
--		local fixture = fixture_a == dynamic_polygon_sensor and fixture_b or fixture_a
--		--local sensor_pos_x, sensor_pos_y = vec2.unpack(sensor.body:get_world_point())
--		--local fixture_pos_x, fixture_pos_y = vec2.unpack(fixture.body:get_world_point())
--		if is_ground_body(fixture.body) then
--		--if sensor_pos_y > fixture_pos_y then
--			contact_count = contact_count - 1
--		end
--	end
--end)
--
--keyboard.set_key_down_handler(function(key)
--	--print('key down: ' .. key .. ' (' .. type(key) .. ')')
--	input[key] = true
--	--system.queue_update()
--end)
--
--keyboard.set_key_up_handler(function(key)
--	--print('key up: ' .. key .. ' (' .. type(key) .. ')')
--	local inputWas = input[key]
--	input[key] = false
--	if inputWas then
--		if key == 'Up' or key == 'K' then
--		end
--		input[key] = false
--	end
--	--system.queue_update()
--end)
--
--function jump(body, impulse_factor)
--	local impulse = body:get_mass() * impulse_factor
--	body:apply_linear_impulse(vec2.pack(0, impulse),
--		body:get_world_point())
--end
--
--function move_player(body)
--	--print("contact " .. tostring(contact_count))
--	if contact_count > 0 and jump_cooldown == 0.0 then
--		if input['Up'] or input['K'] then
--			--print("jump")
--			jump(dynamic_polygon_body, 5)
--			jump_cooldown = 0.5
--		elseif contact_timer > 0.05 then
--			--print("lil jump")
--			jump(dynamic_polygon_body, 0.5)
--			jump_cooldown = 0.5
--		end
--	end
--
--	local velx, vely = vec2.unpack(body:get_linear_velocity())
--	local avel = body:get_angular_velocity()
--	if input['Down'] or input['J'] then
--	elseif input['Left'] or input['H'] then
--		velx = math.max(velx - speed_x, -max_speed_x)
--		avel = avel + rotation_speed
--	elseif input['Right'] or input['L'] then
--		velx = math.min(velx + speed_x, max_speed_x)
--		avel = avel - rotation_speed
--	elseif input['Space'] or input['F'] then
--	end
--	body:set_linear_velocity(vec2.pack(velx, vely))
--	body:set_angular_velocity(avel)
--
--	-- teleport to the other side of the screen
--	local x, y, angle = body:get_transform()
--	local new_x, new_y = x, y
--	if x > level_size_x then
--		new_x = new_x - level_size_x
--	elseif x < 0 then
--		new_x = new_x + level_size_x
--	end
--	if y > level_size_y then
--		new_y = new_y - level_size_y
--	elseif y < 0 then
--		new_y = new_y + level_size_y
--	end
--	if new_x ~= x or new_y ~= y then
--		body:set_transform(vec2.pack(new_x, new_y), angle)
--	end
--end
--
----mouse.set_button_down_handler(display, function (button, x, y)
----	local wx, wy = screen_to_world(x, y)
----	local fixture = find_fixture(wx, wy)
----	if fixture then
----		if button == 1 then
----			mouse_joint = world:create_mouse_joint(wall_body, fixture.body, wx, wy)
----		elseif button == 3 then
----			world:destroy_body(fixture.body)
----		end
----	end
----end)
----mouse.set_button_up_handler(display, function (button, x, y)
----	if button == 1 and mouse_joint then
----		if mouse_joint:is_valid() then
----			world:destroy_joint(mouse_joint)
----		end
----		mouse_joint = nil
----	end
----end)
--
--while true do
--	if mouse_joint and mouse_joint:is_valid() then
--		local wx, wy = screen_to_world(mouse.get_position())
--		mouse_joint:set_mouse_joint_target(wx, wy)
--	end
--
--	jump_cooldown = math.max(jump_cooldown - physics_step, 0.0)
--	if contact_count > 0 then
--		contact_timer = contact_timer + physics_step
--	end
--	
--	move_player(dynamic_polygon_body)
--	
--	local elapsed = time.seconds_since_start()
--	while (physics_elapsed + physics_step < elapsed) do
--		world:step(physics_step)
--		physics_elapsed = physics_elapsed + physics_step
--	end
--
--	display:clear(0, 0, 0, 1)
--	world:debug_draw(display, 0, 0, level_size_x, level_size_y, 0, 0, drawable_size_x, drawable_size_y)
--	display:present()
--	system.queue_update()
--	coroutine.yield()
--end




return game_mode
