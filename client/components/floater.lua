local floater = scenes.components.component.derive('floater')

function floater:init(entity, velocity, duration, fade_duration, fade_up_duration)
	class.super(floater).init(self, entity)
	self._velocity, self._duration, self._fade_duration = velocity, duration, fade_duration
	self._fade_up_total_duration = fade_up_duration or 0
	self._fade_up_duration = 0
	self.transform = entity:require_component(scenes.components.transform)
	entity.scene.event_tick:register(self._on_scene_tick, self)

	-- Establish alpha if there's a fade up
	if self._fade_up_total_duration > 0 then
		local alpha = self._fade_up_duration / self._fade_up_total_duration
		self:_set_alpha(alpha)
	end
end

function floater:destroy()
	class.super(floater).destroy(self)
	self.entity.scene.event_tick:unregister(self._on_scene_tick, self)
end

function floater:_on_scene_tick()
	self.transform.local_translation.value = self.transform.local_translation.value + self._velocity * self.entity.scene.tick_rate
	self._duration = self._duration - self.entity.scene.tick_rate
	self._fade_up_duration = self._fade_up_duration + self.entity.scene.tick_rate
	if self._duration <= 0 then
		self.entity:destroy()
	elseif self._fade_up_duration <= self._fade_up_total_duration then
		local alpha = self._fade_up_duration / self._fade_up_total_duration
		self:_set_alpha(alpha)
	elseif self._duration < self._fade_duration then
		local alpha = self._duration / self._fade_duration
		self:_set_alpha(alpha)
	end
end

function floater:_set_alpha (alpha)
	for child in pairs(self.transform.children) do
		local sprite = child.entity.sprite
		if sprite then
			local r, g, b = vec4.unpack(sprite.color.value)
			sprite.color.value = vec4.pack(r, g, b, alpha)
		end
	end
end

return floater