--[[
	Config values for the overall game
]]

local game_config = {
	max_players = 4,
	scene_pixel_size_x = 960,
	scene_pixel_size_y = 540,
	box2d_size_x = 8,
	box2d_size_y = 8,
	box2d_gravity = vec2.pack(0, -9.8),
}

return game_config

