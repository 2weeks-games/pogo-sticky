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
local player_ai = require 'components/player_ai'
local player_move = require 'components/player_move'
local player_health = require 'components/player_health'
local player_aim_component = require 'components/player_aim'
local player_config = require 'config/player_config'
local game_config = require 'config/game_config'

---@class game_mode:mode
local game_mode = class.create(mode)

function game_mode:init(seed, mode_players, game_session)
	class.super(game_mode).init(self, game_config.scene_pixel_size_x, game_config.scene_pixel_size_y,
		seed, mode_players, game_session)

	-- setup
	self.scene.size_x = game_config.box2d_size_x
	self.scene.size_y = game_config.box2d_size_y
	local pixels_per_meter = self.pixel_size_y / self.scene.size_y
	self.scene.bodies = {}

	-- create box2d world
	self.scene:set_box2d_debug_draw_enabled(true)
	local b2world = self.scene:get_box2d_world()
	self.scene:set_box2d_world_scale(1.0 / pixels_per_meter)
	b2world:set_gravity(game_config.box2d_gravity)

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
	self:create_block(s_2 *-0.3, s_2 *-0.45, s_2 * 0.2, s_2 * 0.05)
	self:create_block(s_2 * 0.3, s_2 *-0.45, s_2 * 0.2, s_2 * 0.05)
	self:create_block(s_2 *-0.3, s_2 * 0.2, s_2 * 0.0375, s_2 * 0.0375)
	self:create_block(s_2 *-0.2, s_2 *-0.2, s_2 * 0.0375, s_2 * 0.0375)
	self:create_block(s_2 * 0.2, s_2 *-0.1, s_2 * 0.0375, s_2 * 0.0375)
	self:create_block(s_2 * 0.25,s_2 * 0.1, s_2 * 0.0375, s_2 * 0.0375)

	--self.background = self.scene:create_entity('background')
	--self.background:create_sprite(resources.background_tex, sprite_layers.background, vec2.pack(960, 540), vec2.pack(960/2, 540/2))

	-- create players
	local player_spawns = {
		{ position = vec2.pack(s_2 *-0.1, s_2 * 0.4), angle = 0 },
		{ position = vec2.pack(s_2 * 0.1, s_2 * 0.3), angle = 0 },
		{ position = vec2.pack(s_2 *-0.4, s_2 * 0.2), angle = 0 },
		{ position = vec2.pack(s_2 * 0.4, s_2 * 0.1), angle = 0 },
	}
	self.mode_players = mode_players
	local num_players = math.min(#mode_players, game_config.max_players)
	self.players = {}
	self.player_huds = {}
	self._players_by_player = {}
	if true then
		for i = 1, num_players do
			local mode_player = self.mode_players[i]
			if mode_player.play_slot and mode_player.play_slot > 0 and mode_player.play_slot <= #player_spawns then
				local spawn = player_spawns[mode_player.play_slot]
				local player = self:spawn_player(mode_player, spawn.position, spawn.angle, true, self.inputs[i])
				player.index = i
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

function game_mode:on_health_changed()
	local hud_sort = {}
	for i = 1, #self.players do
		local player = self.players[i]
		hud_sort[player.index] = {index = player.index, health = player.player_health.health.value}
	end

	--print("table before:")
	--for index, val in pairs(hud_sort) do print (index, val.index, val.health) end
	table.sort(hud_sort, function(a, b) return a.health > b.health end)
	--print("table after:")
	--for index, val in pairs(hud_sort) do print (index, val.index, val.health) end

	local pos_x, pos_y = self.pixel_size_x * 0.5 - 40, self.pixel_size_y * 0.5 - 10
	local rank = 1
	for i, val in pairs(hud_sort) do
		local player = self.players[val.index]
		local mode_player = self.mode_players[val.index]
		local gui_entity = self.player_huds[val.index]
		local color = player.color
		if val.health <= 0 then color = player_config.color_dormant end
		gui_entity.gui_text:set_text(rank .. " " .. mode_player.name .. " " .. player.player_health.health.value)
		gui_entity.gui_text:set_color(color)
		gui_entity.transform:set_world_translation(vec2.pack(pos_x, pos_y))
		pos_y = pos_y - 20
		rank = rank + 1
	end
end

function game_mode:_on_scene_update(elapsed_seconds)
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
	local player_entity = self.scene:create_entity('player')
	player_entity.color = color
	local input = player_entity:create_component(input_manager, player_input)
	player_entity:create_component(player_move, mode_player.play_slot, position, rotation, player_aim, input)
	player_entity:create_component(player_health, gui_entity)
	player_entity:create_component(game_framework.components.buffable)
	if mode_player.is_ai then
		player_entity:create_component(player_ai, player_input, mode_player.play_slot)
	end

	return player_entity
end

function game_mode:spawn_player_hud(player_entity, mode_player)
	-- gui entity
	local color = player_entity.color
	local gui_entity = self.scene:create_entity('player_hud')
	gui_entity:create_transform()
	gui_entity.transform:set_world_translation(vec2.pack(0, 0))
	gui_entity:create_gui_text("", resources.commo_font, 32, sprite_layers.damage_floaters, { grid_align = 1, color = color })

	return gui_entity
end

return game_mode
