
local simple_consumable = require 'components/consumable/simple_consumable'
local powerup = scenes.components.component.derive('powerup', simple_consumable)
local player_health = require 'components/player_health'

function powerup:init(entity)
	class.super(powerup).init(self, entity)

	self.powerup_type = self:get_powerup_type()
	self._consume_handler = function(self, player)
		self:apply_powerup(player)
		self.entity:destroy()
	end
end

function powerup:apply_powerup(player)
	--print(player.username .. " got " .. self.powerup_type .. " powerup")
	if self.powerup_type == 'health' then
		player.player_health.health.value = player.player_health.health.value + 1
	elseif self.powerup_type == 'shield' then
		player.player_health.shield.value = player.player_health.shield.value + 1
	elseif self.powerup_type == 'slow' then
		for _, p in pairs(self.entity.scene.mode.players) do
			if p ~= player then
				p.player_move.speed_factor = 0.1
				p.player_move.speed_factor_cooldown = 10.0
			end
		end
	end
end

function powerup:get_powerup_type()
	local powerup_types = self.entity.scene.powerup_types
	assert(powerup_types, "powerup_types is not defined")
	local r = self.entity.scene.mode.generator:next()
	local index = math.floor(r * (#powerup_types - 1)) + 1
	return powerup_types[index].type
end

return powerup