local resources = require 'resources'
local collision_layers = require 'collision_layers'
local sprite_layers = require 'sprite_layers'
local component = scenes.components.component
local transform = scenes.components.transform
local controlled_turret = component.derive('controlled_turret')
local animated_sprite = require 'components/animated_sprite'

-- Constants
local RATE_OF_FIRE_UPGRADE_MAX = 4
local HOOK_SPEED_UPGRADE_MAX = 4
local HOOK_SIZE_UPGRADE_MAX = 4

function controlled_turret:init (entity, variant, location, rotation, aim_component, input_manager)
    class.super(controlled_turret).init(self, entity)
    local scale = 0.01 * self.entity.scene.size_x

    self:set_aim_component(aim_component)
    self._input_manager = input_manager

    -- Root body
    self.entity:create_transform()
    self.entity.transform:set_world_translation(location)
    self.entity.transform:set_world_rotation(quat.from_euler(0, 0, rotation))
    --self.entity:create_sprite(resources.turrets[variant].body, sprite_layers.turret, vec2.pack(62, 42), vec2.pack(31, 0))
    self.entity_physics = self.entity:create_box2d_physics('dynamic', {
		angle = 0.0,
		linear_velocity = vec2.pack(0, 0),
		angular_velocity = 0,
		linear_damping = 0.0,
		--angular_damping = 10.0,
		allow_sleep = false,
	})
    self.entity_physics.body:create_fixture(
		--box2d.create_box_shape(self.entity.scene:get_box2d_scale(22, 22)), {
		box2d.create_polygon_shape(1*scale,0*scale, -1*scale,0*scale, -1*scale,4*scale, 1*scale,4*scale), {
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

    -- Store variant for position-specific logic
    self.variant = variant

    -- Aim transform which rotates under the body
--    self._aim_transform = self.entity.scene:create_entity('turret_aim', self.entity).transform
--    self._aim_transform.aim_point = vec2.pack(location)
--
--    -- Weapons
--    self.weapon_basic = self.entity:create_component(tw_basic, self, input_manager)
--    self.weapon_beam = self.entity:create_component(tw_beam, self)
--
--    -- Scoring system
--    self.entity:create_component(scoring_system)
--
--    -- Powerup timing
--    self.recent_powerup_time_remaining = 0
--    self.recent_powerup_delay = 3.0
--
--    -- Upgrade tracking
--    self._rate_of_fire_upgrades = 0
--    self._hook_speed_upgrades = 0
--    self._hook_size_upgrades = 0

    self.entity.scene.event_tick:register(self._on_scene_tick, self)
end

function controlled_turret:destroy ()
    self.entity.scene.event_tick:unregister(self._on_scene_tick, self)
end

function controlled_turret:set_aim_component (aim_component)
    self._aim_component = aim_component
end

function controlled_turret:get_aim_component ()
    return self._aim_component
end

function controlled_turret:get_aim_transform ()
    return self._aim_transform
end

function controlled_turret:_move(key, impulseX, impulseY)
    local value, elapsed = self._aim_component._player_input:get_key_state(key)
	if value and elapsed == 0.0 then
		--print(key .. " " .. tostring(value) .. " " .. tostring(elapsed))
		local body = self.entity_physics.body
        local mass = body:get_mass()
		impulseX = impulseX * self.entity.scene.size_x * mass
		impulseY = impulseY * self.entity.scene.size_y * mass
		body:apply_linear_impulse(vec2.pack(impulseX, impulseY),
			body:get_world_point())
	end
end

-- Events
function controlled_turret:_on_scene_tick ()
    --self._aim_transform.aim_point = vec2.pack(self._aim_transform.aim_point, self._aim_component:get_current_world_aim())
    --self._aim_transform:look_at_world_2d(self._aim_transform.aim_point)

    -- Powerup timing
    --if self.recent_powerup_time_remaining > 0 then
    --    self.recent_powerup_time_remaining = self.recent_powerup_time_remaining - self.entity.scene.tick_rate
    --end

	--self:_move('left', -1, 0)
	--self:_move('right', 1, 0)
	self:_move('up', 0, 500)
	--self:_move('down', 0, -1)

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
	body:set_linear_velocity(vec2.pack(velx, vely))
	body:set_angular_velocity(avel)
    print("velx: " .. velx .. " vely: " .. vely .. " avel: " .. avel)

    -- warp to other side of screen if off screen
    local scene = self.entity.scene
    local level_size_x, level_size_y = scene.size_x, scene.size_y
    local x, y = vec2.unpack(self.entity.transform:get_world_translation(location))
	local new_x, new_y = x, y
	if x > level_size_x * 0.5 then
		new_x = new_x - level_size_x
	elseif x < level_size_x * -0.5 then
		new_x = new_x + level_size_x
	end
	if y > level_size_y * 0.5 then
		new_y = new_y - level_size_y
	elseif y < level_size_y * -0.5 then
		new_y = new_y + level_size_y
	end
    if new_x ~= x or new_y ~= y then
        self.entity.transform:set_world_translation(vec2.pack(new_x, new_y))
    end
end

return controlled_turret