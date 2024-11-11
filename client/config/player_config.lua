--[[
    Config values for the player
]]

local player_config = {
    health = 8,
	speed_x = 8.1 / 60.0,
	speed_y = 8.1 / 60.0,
	max_speed_x = 81.0,
	max_speed_y = 9.0,
	rotation_speed = 0.0,
    linear_damping = 0.0,
    angular_damping = 10.0,
    density = 1.0,
    restitution = 0.0,
    input = {
        arm_long_press_time = .25
    }
}

return player_config
