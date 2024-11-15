return {
	box2d_size_x = 8,
	box2d_size_y = 8,
	box2d_gravity = vec2.pack(0, -9.8),
	powerup_cooldown = 20.0,
	player_spawns = {
		{ x = -0.46,	y = 0.4,	angle = 0 },
		{ x = -0.45,	y = 0.-2,	angle = 0 },
		{ x = 0.46,		y = 0.4,	angle = 0 },
		{ x = 0.45,		y = 0.-2,	angle = 0 },
	},
	blocks = {
		-- bottom left
		{ x = -0.3,		y = -0.45,		w = 0.21,	h = 0.05 },
		-- bottom right
		{ x =  0.3,		y = -0.45,		w = 0.21,	h = 0.05 },
		-- left
		{ x = -0.51,	y = 0.085,		w = 0.01,	h = 0.165 },
		{ x = -0.46125,	y = 0.2125,		w = 0.0375,	h = 0.0375 },
		{ x = -0.46125,	y = -0.2125,	w = 0.0375,	h = 0.0375 },
		{ x = -0.225,	y = -0.01,		w = 0.075,	h = 0.0375 },
		-- right
		{ x = 0.51,	y = 0.085,			w = 0.01,	h = 0.165 },
		{ x = 0.46125,	y = 0.2125,		w = 0.0375,	h = 0.0375 },
		{ x = 0.46125,	y = -0.2125,	w = 0.0375,	h = 0.0375 },
		{ x = 0.225,	y = -0.01,		w = 0.075,	h = 0.0375 },
	},
	powerup_types = {
		--{ type = 'health' },
		{ type = 'shield' },
		--{ type = 'speed' },
		--{ type = 'jump' },
		--{ type = 'bounce' },
	},
}