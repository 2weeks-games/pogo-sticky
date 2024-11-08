local frame_queue = class.create()

-- Todo: compute buffer min/max based on variance of frame times so it functions like a jitter buffer
frame_queue.buffer_minimum = 2
frame_queue.buffer_maximum = 3

function frame_queue:init(mode, state, is_local, shadow_mode)
	self._mode = mode
	self._state = state
	self._is_local = is_local
	self._queue_state = 'buffering'
	self._queue = {}
	self._state:get_field_ref('tick'):register_next(self._on_state_tick, self)
	if shadow_mode then
		self._shadow_mode = shadow_mode
		self._trace_events = {}
		self:_hook_traces(self._mode, false)
		self:_hook_traces(self._shadow_mode, true)
	end
end

function frame_queue:update()
	local timestamp = time.seconds_since_start()
	if self._queue_state == 'buffering' then
		if self._is_local or #self._queue >= self.buffer_minimum then
			self._queue_state = 'playing'
			self._next_tick_timestamp = timestamp
		end
	end
	if self._queue_state ~= 'playing' then
		return
	end
	local extra_frames = #self._queue - self.buffer_maximum
	if extra_frames > 0 then
		self._next_tick_timestamp = self._next_tick_timestamp - extra_frames * self._mode.scene.tick_rate
	end
	while not self._state.complete and self._next_tick_timestamp <= timestamp do
		if #self._queue == 0 then
			self._queue_state = 'buffering'
			return
		end
		local frame = table.remove(self._queue, 1)
		self:_update_inputs(self._mode, frame)
		self._mode.scene:update(self._mode.scene.tick_rate)
		if self._shadow_mode and not self._state.complete then
			self:_update_inputs(self._shadow_mode, frame)
			self._shadow_mode.scene:update(self._shadow_mode.scene.tick_rate)
		end
		self._next_tick_timestamp = self._next_tick_timestamp + self._mode.scene.tick_rate
	end
end

function frame_queue:_update_inputs(mode, frame)
	for player_id, input in pairs(mode.inputs) do
		local input_state = frame.inputs[player_id]
		input:set_state(input_state, mode.scene.tick_timestamp)
	end
end

function frame_queue:_on_state_tick(tick)
	local frame = { inputs = {} }
	for player_id, player_state in pairs(self._state.players) do
		local input_copy = {}
		for key, value in pairs(player_state.inputs) do
			input_copy[key] = value
		end
		frame.inputs[player_id] = input_copy
	end
	table.insert(self._queue, frame)
end

function frame_queue:_hook_traces(mode, is_mirror)
	local function trace(event_name, params)
		if not is_mirror then
			table.insert(self._trace_events, { event_name = event_name, params = params })
		else
			local source_event = table.remove(self._trace_events, 1)
			if not source_event then
				error('shadow context produced unexpected trace event')
			end
			if source_event.event_name ~= event_name then
				error('shadow context has mismatched trace event')
			end
			local mirror_parameters = params
			for key, value in pairs(mirror_parameters) do
				local source_value = source_event.params[key]
				if source_value ~= value then
					error("shadow context event " .. event_name .. " param[" .. key .. "] ~= '" .. tostring(source_value) .. "' (got '" .. tostring(value) .. "')")
				end
			end
			for key in pairs(source_event.params) do
				if mirror_parameters[key] == nil then
					error("shadow context event " .. event_name .. " missing param[" .. key .. "]")
				end
			end
		end
	end
	local function hook_method(instance, method_name, hook)
		local original = instance[method_name]
		local function wrapper(...)
			return hook(original, ...)
		end
		if type(instance) ~= 'userdata' then
			instance[method_name] = wrapper
		else
			local type_metatable = getmetatable(instance)
			local function index_hook(instance, key)
				local metatable = getmetatable(instance)
				local field_map = metatable.__field_map[instance]
				local field = field_map and field_map[key]
				if field then
					return field
				end
				return metatable.__wrapped_index(instance, key)
			end
			if not type_metatable.__wrapped_index then
				type_metatable.__wrapped_index = type_metatable.__index
				type_metatable.__index = index_hook
			end
			local instance_fields = type_metatable.__field_map[instance]
			instance_fields[method_name] = wrapper
		end
	end
	local function hook_component(component_type, component)
		local component_name = class.name(component_type)
		if component_name == 'transform' then
			hook_method(component, 'compute_world_matrix', function(original, ...)
				original(...)
				local translation, rotation, scale = mat4.decompose(component.world_matrix.value)
				trace('transform:compute_world_matrix', { translation = translation, rotation = rotation, scale = scale })
			end)
		elseif component_name == 'box2d_physics' then
			hook_method(component.body, 'create_fixture', function(original, body, ...)
				local shape, fixture_def = ...
				local fixture = original(body, ...)
				local trace_args = {
					id = body.id,
					type = shape:get_type(),
					radius = shape:get_radius(),
				}
				if fixture_def then
					for key, value in pairs(fixture_def) do
						trace_args[key] = value
					end
				end
				trace('box2d_body:create_fixture', trace_args)
				return fixture
			end)
			hook_method(component.body, 'set_transform', function(original, body, ...)
				local x, y, a = ...
				trace(' box2d_body:set_transform', { id = body.id, x = x, y = y, a = a })
				original(body, ...)
			end)
			hook_method(component.body, 'get_transform', function(original, body, ...)
				local x, y, a = original(body, ...)
				trace('box2d_body:get_transform', { id = body.id, x = x, y = y, a = a })
				return x, y, a
			end)
			hook_method(component.body, 'set_linear_velocity', function (original, body, ...)
				trace('box2d_body:set_linear_velocity', { id = body.id, ... })
				original(body, ...)
			end)
		end
	end
	local function hook_entity(entity)
		for name in pairs(class.type(entity)) do
			if name:sub(1, #'import') == 'import' then
				hook_method(entity, name, function(original, ...)
					error('import methods are not deterministic due to nondeterministic load order')
				end)
			end
		end
		hook_method(entity, 'create_component', function(original, entity, ...)
			local component_type = ...
			local component_name = class.name(component_type)
			trace('entity:create_component', { component_name = component_name })
			if component_name == 'transform' then
				local _, parent, translation, rotation, scale
			end
			local component = original(entity, ...)
			hook_component(component_type, component)
			return component
		end)
		for component_type, component in pairs(entity._components) do
			hook_component(component_type, component)
		end
	end
	hook_method(mode.scene, 'update', function(original, scene, ...)
		local elapsed_seconds = ...
		trace('scene:update', { elapsed_seconds = elapsed_seconds })
		return original(scene, ...)
	end)
	hook_method(mode.scene, 'create_entity', function(original, scene, ...)
		local name, parent_entity, starting_position, position_is_world = ...
		trace('scene:create_entity', {
			name = name,
			parent_entity_name = parent_entity and parent_entity.name,
			starting_position = starting_position,
			position_is_world = position_is_world
		})
		local entity = original(scene, ...)
		hook_entity(entity)
		return entity
	end)
	local world = mode.scene:get_box2d_world()
	hook_method(world, 'step', function (original, world, ...)
		local tick_rate = ...
		trace('world:step', { tick_rate })
		return original(world, ...)
	end)
	hook_method(world, 'destroy_body', function (original, world, ...)
		local body = ...
		trace('world:destroy_body', { id = body.id })
		return original(world, ...)
	end)
	-- hook the random number generator
	local generator = mode.generator
	mode.generator = {
		next = function(self, ...)
			local result = generator:next(...)
			trace('generator:next', { result = result, ... })
			return result
		end
	}
	-- Hook any existing entities
	for entity in pairs(mode.scene._entities) do
		hook_entity(entity)
	end
end

return frame_queue