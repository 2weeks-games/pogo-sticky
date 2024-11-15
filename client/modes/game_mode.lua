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
local player_ai = require 'components/player_ai'
local player_move = require 'components/player_move'
local player_health = require 'components/player_health'
local player_aim_component = require 'components/player_aim'
local player_config = require 'config/player_config'
local game_config = require 'config/game_config'
local powerup = require 'components/consumable/powerup'

---@class game_mode:mode
local game_mode = class.create(mode)

function game_mode:init(seed, mode_players, game_session)
	local num_levels = 2
	local level = require ('levels/level' .. string.format('%02d', seed % num_levels + 1))
	class.super(game_mode).init(self, game_config.scene_pixel_size_x, game_config.scene_pixel_size_y,
		seed, mode_players, game_session)

	-- setup
	self.scene.size_x = level.box2d_size_x
	self.scene.size_y = level.box2d_size_y
	local pixels_per_meter = self.pixel_size_y / self.scene.size_y
	self.scene.bodies = {}
	self.finished = false
	self.seed = seed
	self.powerup_cooldown = 1.0
	self.powerup_cooldown_duration = level.powerup_cooldown
	self.scene.powerup_types = level.powerup_types

	-- create box2d world
	self.scene:set_box2d_debug_draw_enabled(true)
	local b2world = self.scene:get_box2d_world()
	self.scene:set_box2d_world_scale(1.0 / pixels_per_meter)
	b2world:set_gravity(level.box2d_gravity)

	-- create camera
	self.camera_entity.transform.local_translation.value = vec3.pack(0, 0, 1)
	self.camera_entity.transform:look_at_local(vec3.pack(0, 0, 0))
	self.camera_entity:create_component(entity_shake)

	-- create background
	self.background = self.scene:create_entity('background')
	self.background:create_transform()
	self.background:create_sprite(resources.background_tex, sprite_layers.background, vec2.pack(960, 540), vec2.pack(960 / 2, 540 / 2))

	-- create blocks
	local s_2 = self.scene.size_y * pixels_per_meter
	for k, v in pairs(level.blocks) do
		self:create_block(v.x * s_2, v.y * s_2, v.w * s_2, v.h * s_2)
	end

	-- create players
	self.mode_players = mode_players
	local num_players = math.min(#mode_players, game_config.max_players)
	self.players = {}
	self.player_huds = {}
	self._players_by_player = {}
	if true then
		for i = 1, num_players do
			local mode_player = self.mode_players[i]
			if mode_player.play_slot and mode_player.play_slot > 0 and mode_player.play_slot <= #level.player_spawns then
				local spawn = level.player_spawns[mode_player.play_slot]
				local position = vec2.pack(spawn.x * s_2, spawn.y * s_2)
				local player = self:spawn_player(mode_player, position, spawn.angle, true, self.inputs[i])
				player.index = i
				player.username = mode_player.name
				if player then
					self._players_by_player[player] = player
					table.insert(self.players, player)
					self.player_huds[mode_player.play_slot] = self:spawn_player_hud(player, mode_player)
				end
			end
		end
	end

	-- music
	--self.combat_music = audio_manager:play_music('assets/audio/music/KDC_Test_combat_3.mp3', true, 0.3)

	self:on_health_changed()
	self.scene.event_update:register(self._on_scene_update, self)
end

function game_mode:destroy()
	class.super(game_mode).destroy(self)
	self.scene.event_update:unregister(self._on_scene_update, self)
end

function game_mode:set_finished()
	self.finished = true
	local b2world = self.scene:get_box2d_world()
	b2world:set_gravity(vec2.pack(0, 0))
end

function game_mode:on_health_changed()
	local hud_sort = {}
	local pos_x, pos_y = self.pixel_size_x * 0.5 - 40, self.pixel_size_y * 0.5 - 10
	local living_count = 0
	local rank = 1

	for i = 1, #self.players do
		local player = self.players[i]
		hud_sort[player.index] = {index = player.index, health = player.player_health.health.value}
		if player.player_health.health.value > 0 then
			living_count = living_count + 1
		end
	end
	
	-- mode now finished
	if living_count <= 1 then
		self:set_finished()
		pos_x, pos_y = self.pixel_size_x * 0.0 - 20, self.pixel_size_y * 0.25 - 10
	end

	--print("table before:")
	--for index, val in pairs(hud_sort) do print (index, val.index, val.health) end
	table.sort(hud_sort, function(a, b) return a.health > b.health end)
	--print("table after:")
	--for index, val in pairs(hud_sort) do print (index, val.index, val.health) end

	for i, val in pairs(hud_sort) do
		local player = self.players[val.index]
		local gui_entity = self.player_huds[val.index]
		local color = player.color
		if val.health <= 0 then color = player_config.color_dormant end
		gui_entity.gui_text:set_text(rank .. " " .. player.username .. " " .. player.player_health.health.value)
		gui_entity.gui_text:set_color(color)
		gui_entity.transform:set_world_translation(vec2.pack(pos_x, pos_y))
		pos_y = pos_y - 20
		rank = rank + 1
	end
end

function game_mode:_on_scene_update(elapsed_seconds)
	-- warp entities and clamp velocity
	local scene = self.scene
	local scale = self.scene:get_box2d_scale(1)
	local size_x, size_y = scene.size_x / scale, scene.size_y / scale
	for k, v in pairs(self.scene._entities) do
		if v.transform and v.movable then
			-- warp entities
			local x, y = vec2.unpack(v.transform:get_world_translation())
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
				v.transform:set_world_translation(vec2.pack(new_x, new_y))
			end
			--print(x .. " " .. y .. " " .. new_x .. " " .. new_y)

			-- clamp velocity
			local body = v.physics.body
			local speed_factor = v.player_move and v.player_move.speed_factor or 1.0
			local stomping = v.player_move and v.player_move.stomping or false
			local velx, vely = vec2.unpack(body:get_linear_velocity())
			velx = math.min(velx, player_config.max_speed_x * speed_factor)
			velx = math.max(velx, -player_config.max_speed_x * speed_factor)
			vely = math.min(vely, player_config.max_speed_y_pos * speed_factor)
			if not stomping then
				vely = math.max(vely, -player_config.max_speed_y_neg * speed_factor)
			end
			body:set_linear_velocity(vec2.pack(velx, vely))

			--if v.gui_entity then
			--	v.gui_entity.gui_text:set_text(tostring(stomping))
			--end
		end
	end

	-- spawn powerup
	self.powerup_cooldown = math.max(self.powerup_cooldown - self.scene.tick_rate, 0)
	if self.powerup_cooldown == 0 then
		local pixels_per_meter = 1.0 / self.scene:get_box2d_scale(1)
		local s_2 = self.scene.size_y * pixels_per_meter
		self:spawn_powerup(0.0 * s_2, 0.25 * s_2)
		self.powerup_cooldown = self.powerup_cooldown_duration
	end

	-- finished
	if self.finished then
		if self.players[1].player_input:get_key_state('arm') then
			local session = self.game_session.pogo_session
			session:start_mode('Pogo Sticking')
			self:destroy()
		end
	end
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
	self.scene.bodies[ground.box2d_physics.body.id] = ground
end

function game_mode:spawn_powerup(x, y)
	local scale = self.scene:get_box2d_scale(1)

	local e = self.scene:create_entity('powerup')
	e.movable = true
	e:create_transform()
	e.transform:set_world_translation(vec2.pack(x, y))
	--e:create_component(animated_sprite, resources.powerup_tex, sprite_layers.powerups, vec2.pack(64, 64), vec2.pack(32, 32), 0.1)
	e:create_component(powerup)

	e.physics = e:create_box2d_physics('dynamic', {
		linear_damping = 0.5,
		angular_damping = 10.0,
	})
	e.physics.body:create_fixture(
		box2d.create_box_shape(10*scale, 10*scale), {
		density = 1.0,
		restitution = 0.0,
		is_sensor = false,
		--filter_category = collision_layers.turret,
		--filter_mask = 0
	})
--	e.physics.body:create_fixture(
--		box2d.create_box_shape(11*scale, 11*scale), {
--		is_sensor = true,
--	})
	self.scene.bodies[e.physics.body.id] = e
end

function game_mode:spawn_player(mode_player, position, rotation, is_hook_controlled, player_input)
	-- mouse aim
	local player_aim_entity = self.scene:create_entity('player_aim')
	local player_aim = player_aim_entity:create_component(player_aim_component, player_input, mode_player.play_slot)

	-- gui entity
	local color = player_config.colors[mode_player.play_slot]
	if not mode_player.is_ai then
		color = '#ffffff'
	end
	local gui_entity = self.scene:create_entity('player_health')
	gui_entity:create_transform()
	gui_entity.transform:set_world_translation(vec2.pack(0, 0))
	--gui_entity.transform:set_world_rotation(quat.from_euler(0, 0, rotation))
	gui_entity:create_gui_text(tostring(player_config.health), resources.commo_font, 32, sprite_layers.damage_floaters, { grid_align = 1, color = color })

	-- create player entity
	local e = self.scene:create_entity('player')
	e.player_input = player_input
	e.color = color
	e.gui_entity = gui_entity
	e.movable = true
	e:create_component(player_move, mode_player.play_slot, position, rotation, player_aim, input)
	e:create_component(player_health)
	e:create_component(game_framework.components.buffable)
	if mode_player.is_ai then
		e:create_component(player_ai, player_input, mode_player.play_slot)
	end

	return e
end

function game_mode:spawn_player_hud(player_entity, mode_player)
	-- gui entity
	local color = player_entity.color
	local e = self.scene:create_entity('player_hud')
	e:create_transform()
	e.transform:set_world_translation(vec2.pack(0, 0))
	e:create_gui_text("", resources.commo_font, 32, sprite_layers.damage_floaters, { grid_align = 1, color = color })

	return e
end

return game_mode
