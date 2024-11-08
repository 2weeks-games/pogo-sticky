---@class player_input:class
local player_input = class.create()

function player_input:init()
    self._state = {}
    self.update_timestamp = 0
end

function player_input:get(name)
    local input_state = self._state[name]
    if input_state then
        if type(input_state) == 'table' then
            return input_state.value
        else
            return input_state
        end
    else
        return nil
    end
end

-- Return the state of this input assuming it is a boolean on/off key value
function player_input:get_key_state(name)
    local input_state = self._state[name]
    if input_state then
        return input_state.value, self.update_timestamp - input_state.timestamp, input_state.timestamp
    else
        return nil, nil, nil
    end
end

function player_input:get_down(name)
    local input_state = self._state[name]
    if input_state and input_state.timestamp then
        return input_state.value and input_state.timestamp == self.update_timestamp
    else
        return false
    end
end

function player_input:get_up(name)
    local input_state = self._state[name]
    if input_state and input_state.elapsed then
        return not input_state.value and input_state.timestamp == self.update_timestamp
    else
        return false
    end
end

function player_input:set_state(state, timestamp)
    self.update_timestamp = timestamp
    if state then
        for key, value in pairs(state) do
            if type(value) == 'boolean' then
                self:_set_boolean_state(key, value)
            else
                self._state[key] = value
            end
        end
    end
end

-- Private

function player_input:_set_boolean_state(key, value)
    local key_state = self._state[key]
    if key_state then
        if value ~= key_state.value then
            key_state.value = value
            key_state.timestamp = self.update_timestamp
        end
    else
        self._state[key] = {
            value = value,
            timestamp = self.update_timestamp
        }
    end
end

return player_input