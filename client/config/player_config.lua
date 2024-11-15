--[[
	Config values for the player
]]

local player_config = {
	health = 3,
	health_cooldown = 3.0,
	speed_x = 8.1 / 60.0,
	speed_y = 8.1 / 60.0,
	max_speed_x = 3.0,
	max_speed_y_pos = 8.0,
	max_speed_y_neg = 4.0,
	jump_impulse_y = 8.0 * 12.0,
	pogo_impulse_y = 0.8 * 2.0,
	stomp_impulse_y = -1.0 * 6.0,
	jump_cooldown = 0.5,
	pogo_cooldown = 0.1,
	stomp_cooldown = 1.0,
	rotation_speed = 0.0,
	linear_damping = 0.0,
	angular_damping = 10.0,
	density = 1.0,
	restitution = 0.0,
	on_top_height = 20.0,
	health_steal_ticks = 2,
	ai_intelligence = 0.5,
	colors = {
		'#ff8080ff',
		'#80ff80ff',
		'#8080ffff',
		'#ff80ffff',
		'#80ffffff',
		'#ffff80ff',
		'#ffffffff',
	},
	color_dormant = '#7f7f7f80',
}

return player_config
