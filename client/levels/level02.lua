return {
	box2d_size_x = 8,
	box2d_size_y = 8,
	box2d_gravity = vec2.pack(0, -9.8),
	player_spawns = {
		{ x = -0.46,	y = 0.4,	angle = 0 },
		{ x = -0.45,	y = 0.-2,	angle = 0 },
		{ x = 0.46,		y = 0.4,	angle = 0 },
		{ x = 0.45,		y = 0.-2,	angle = 0 },
	},
	blocks = {
		-- bottom
		{ x = -0.375,	y = -0.45,		w = 0.15,	h = 0.05 },
		{ x =  0.375,	y = -0.45,		w = 0.15,	h = 0.05 },
		{ x =  0.0,		y = -0.45,		w = 0.1,	h = 0.05 },
		-- top
		{ x =  0.0,		y = 0.45,		w = 0.1,	h = 0.05 },
		-- left
		{ x = -0.51,	y = 0.085,		w = 0.01,	h = 0.165 },
		{ x = -0.46125,	y = 0.2125,		w = 0.0375,	h = 0.0375 },
		{ x = -0.46125,	y = -0.2125,	w = 0.0375,	h = 0.0375 },
		{ x = -0.18,	y = -0.01,		w = 0.075,	h = 0.0375 },
		-- right
		{ x = 0.51,		y = 0.085,		w = 0.01,	h = 0.165 },
		{ x = 0.46125,	y = 0.2125,		w = 0.0375,	h = 0.0375 },
		{ x = 0.46125,	y = -0.2125,	w = 0.0375,	h = 0.0375 },
		{ x = 0.18,		y = -0.01,		w = 0.075,	h = 0.0375 },
	}
}