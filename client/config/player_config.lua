--[[
    Config values for the player
]]

local player_config = {
    hook = {
        fire_delay = .2,
        close_delay = .075,
        retract_delay = .3,
        consume_delay = .1,
        reset_delay = .1,

        resting_offset = 20,

        extend_speed = 420,
        -- Small adjustment to the hook's extend distance to make the closing position accurate.
        -- Negative values make the hook stop short of the clicked point, larger values make it overshoot.
        extend_distance_bias = -15,

        close_angle = 50 * math.pi / 180,

        consume_radius = 64
    },
    input = {
        arm_long_press_time = .25
    }
}

return player_config
