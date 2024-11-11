local input_map = require 'input_map'
local mode = require 'modes/mode'
local game_mode = require 'modes/game_mode'
local waiting_mode = require 'modes/waiting_mode'
local frame_queue = require 'frame_queue'
local game_config = require 'config/game_config'

---@class pogo_session:class
local pogo_session = class.create()
---@class game_session_interface:class
local game_session_interface = class.create()

-- Constants
pogo_session.PLAY_SLOT_COUNT = 4

function pogo_session:init(lobby, join_id, use_shadow_context)
    self._lobby = lobby
    self.name = lobby.name
    self.active_invite = reactive.create_ref()
    self.current_mode = reactive.create_ref()
    self.state = reactive.create_ref()
    self._use_shadow_context = use_shadow_context
    self._queued_player_states = {}

    local session_options = { name = self.name }
    if syndication.discord then
        session_options.endpoint = syndication.discord.client_id .. '.discordsays.com/.proxy/sessions'
        session_options.protocol = 'wss'
        session_options.proxied = true
    end
    if not join_id or join_id == '' then
        self.connection = sessions.create_session(session_options)
    else
        self.connection = sessions.join_session(join_id, session_options)
    end
    self.connection.event_connected:register(self._on_session_connected, self)
    self.connection.event_disconnected:register(self._on_session_disconnected, self)
    self.state:register_next(self._on_state_changed, self)
end

function pogo_session:update()
    if not self.current_mode.value then
        return
    end
    -- If we're the local host, check to see if enough time has elapsed to advance a tick
    if self.connection.local_host and not self.state.value.mode.complete then
        local timestamp = time.seconds_since_start()
        if not self._next_tick_timestamp then
            self._next_tick_timestamp = timestamp
        end
        local scene = self.current_mode.value.scene
        if self._next_tick_timestamp <= timestamp then
            self.state.value.mode.tick = self.state.value.mode.tick + 1
            self._next_tick_timestamp = self._next_tick_timestamp + scene.tick_rate
        end
    end
    if self._frame_queue then
        system.queue_update()
        self._frame_queue:update()
    end
end

function pogo_session:on_local_keyboard_key_down(key_name)
    local input = input_map.map_keyboard_key(key_name)
    if input then
        self:_send_input(input, true)
    end
end

function pogo_session:on_local_keyboard_key_up(key_name)
    local input = input_map.map_keyboard_key(key_name)
    if input then
        self:_send_input(input, false)
    end
end

function pogo_session:on_local_mouse_move(x, y)
    self.local_x, self.local_y = x, y
    self:_send_input('mouse_x', x)
    self:_send_input('mouse_y', y)
end

function pogo_session:on_local_mouse_button_down(button)
    local input = input_map.map_mouse_button(button)
    if input then
        self:_send_input(input, true)
    end
end

function pogo_session:on_local_mouse_button_up(button)
    local input = input_map.map_mouse_button(button)
    if input then
        self:_send_input(input, false)
    end
end

function pogo_session:set_ready(is_ready)
    if self.connection.local_host then
        self:_process_ready(self.connection.local_peer_id, is_ready)
    else
        local message = lua_data.write_text({ ready = is_ready })
        self.connection.remote_host:send_reliable(message)
    end
end

function pogo_session:client_request_spectate()
    if self.connection.local_host then
        self:_process_request_spectate(self.connection.local_peer_id)
    else
        local message = lua_data.write_text({ request_spectate = true })
        self.connection.remote_host:send_reliable(message)
    end
end

function pogo_session:client_request_play_slot(slot)
    if self.connection.local_host then
        self:_process_request_play_slot(self.connection.local_peer_id, slot)
    else
        local message = lua_data.write_text({ request_play_slot = slot })
        self.connection.remote_host:send_reliable(message)
    end
end

function pogo_session:client_request_vote(vote_type, minimum_votes_for, time_limit, player_initial_response)
    if self.connection.local_host then
        self:_process_request_vote(self.connection.local_peer_id, vote_type, minimum_votes_for, time_limit, player_initial_response)
    else
        local message = lua_data.write_text({
            request_vote = vote_type,
            minimum_votes_for = minimum_votes_for,
            time_limit = time_limit,
            player_initial_response = player_initial_response
        })
        self.connection.remote_host:send_reliable(message)
    end
end

function pogo_session:client_submit_vote(vote_id, vote)
    if self.connection.local_host then
        self:_process_submit_vote(self.connection.local_peer_id, vote_id, vote)
    else
        local message = lua_data.write_text({ submit_vote = vote_id, vote = vote })
        self.connection.remote_host:send_reliable(message)
    end
end

function pogo_session:client_close_vote(vote_id)
    -- Only the host can close a vote. We rely on the host to do something in response to a vote.
    if self.connection.local_host then
        self:_process_close_vote(vote_id)
    end
end

function pogo_session:_send_input(input, value)
    if self.connection.local_host then
        self:_process_input(self.connection.local_peer_id, input, value)
    else
        local message = lua_data.write_text({ input = input, value = value })
        self.connection.remote_host:send_reliable(message)
    end
end

function pogo_session:_process_input(player_id, input, value)
    local player_state = self:_find_mode_player(player_id)
    if not player_state then
        return
    end

    if type(value) ~= 'boolean' then
        player_state.inputs[input] = value
    else
        local queued_state = self._queued_player_states[player_id]
        if not queued_state then
            queued_state = {}
            self._queued_player_states[player_id] = queued_state
        end
        if queued_state[input] ~= value then -- Do this to make nil and false have equivalent behavior
            player_state.inputs[input] = value
        end
        queued_state[input] = value
    end
end

function pogo_session:_process_ready(player_id, is_ready)
    local player_state = self:_find_player(player_id)
    if not player_state then
        return
    end
    player_state.is_ready = is_ready
end

function pogo_session:_process_request_spectate(player_id)
    local player_state = self:_find_player(player_id)
    if player_state and player_state.play_slot then
        player_state.play_slot = nil
    end
end

function pogo_session:_process_request_play_slot(player_id, slot)
    if type(slot) ~= 'number' then
        return
    end
    if slot < 1 or slot > pogo_session.PLAY_SLOT_COUNT then
        return
    end
    local player_state = self:_find_player(player_id)
    if not player_state then
        return
    end

    if not player_state.play_slot or player_state.play_slot ~= slot then
        local existing_player = self:get_player_in_play_slot(slot)
        if not existing_player then
            player_state.play_slot = slot
        end
    end
end

function pogo_session:_process_request_vote(player_id, vote_type, minimum_votes_for, time_limit, player_initial_response)
    local player_state, player_index = self:_find_player(player_id)
    -- Only active players can vote
    if not player_state or not player_state.play_slot then
        return
    end
    if not minimum_votes_for or minimum_votes_for < 1 then
        return
    end
    if not time_limit or time_limit < 1 then
        return
    end

    -- Only one vote at a time
    local mode_state = self.state.value.mode
    if mode_state.vote then
        return
    end
    -- Initialize and replicate vote state
    local now = time.seconds_since_start()
    local vote_id = self._next_vote_id or 1
    self._next_vote_id = vote_id + 1
    local session_vote_state = {
        responses = {},
        start_time = now,
        end_time = now + time_limit + 1 -- Add a grace period to absorb latency in votes. The UI will display the proper duration.
    }
    local mode_vote_state = {
        id = vote_id,
        type = vote_type,
        minimum_votes_for = minimum_votes_for,
        votes_for = 0,
        votes_against = 1,
    }
    if player_initial_response ~= nil then
        if player_initial_response then
            mode_vote_state.votes_for = 1
        else
            mode_vote_state.votes_against = 1
        end
        session_vote_state.responses[player_id] = true
    end
    self.state.value.vote = session_vote_state
    mode_state.vote = mode_vote_state
end

function pogo_session:_process_submit_vote(player_id, vote_id, vote)
    local now = time.seconds_since_start()

    -- Validate player is active player
    local player_state, _ = self:_find_player(player_id)
    if not player_state or not player_state.play_slot then
        return
    end
    -- Validate request
    local mode_state = self.state.value.mode
    local session_vote = self.state.value.vote
    local mode_vote = mode_state and mode_state.vote
    if not session_vote or not mode_vote or mode_vote.id ~= vote_id then
        return
    end
    if session_vote.responses[player_id] or now > session_vote.end_time then
        return
    end
    -- Process vote
    session_vote.responses[player_id] = true
    if vote then
        mode_vote.votes_for = mode_vote.votes_for + 1
    else
        mode_vote.votes_against = mode_vote.votes_against + 1
    end
end

function pogo_session:_process_close_vote(vote_id)
    if self.state.value.mode then
        self.state.value.mode.vote = nil
    end
    self.state.value.vote = nil
end

function pogo_session:_find_player(player_id)
    local state = self.state.value
    if not state then
        return
    end
    for i = 1, #state.players do
        local player = state.players[i]
        if player.id == player_id then
            return player, i
        end
    end
end

function pogo_session:_find_mode_player(player_id)
    local state = self.state.value
    if not state then
        return
    end
    if not state.mode then
        return
    end
    for i = 1, #state.mode.players do
        local player = state.mode.players[i]
        if player.id == player_id then
            return player
        end
    end
end

function pogo_session:get_player_in_play_slot(slot)
    local state = self.state.value
    if not state then
        return
    end
    for i = 1, #state.players do
        local player = state.players[i]
        if player.play_slot == slot then
            return player
        end
    end
end

function pogo_session:_find_open_play_slot()
    local state = self.state.value
    if not state then
        return
    end
    local occupied = {}
    for i = 1, #state.players do
        local player = state.players[i]
        if player.play_slot then
            occupied[player.play_slot] = true
        end
    end
    for i = 1, pogo_session.PLAY_SLOT_COUNT do
        if not occupied[i] then
            return i
        end
    end
end

function pogo_session:_on_session_connected()
    self.active_invite.value = self.connection.id
    if self.connection.local_host then
        self.source = replication.source.new({
            players = {
                {
                    id = self.connection.local_peer_id,
                    name = self.name,
                    is_ready = true,
                    play_slot = 1
                }
            }
        })
        self.source.event_update:register(self._on_local_host_source_update, self)
        self.connection.local_host.event_peer_connected:register(self._on_local_host_peer_connected, self)
        self.connection.local_host.event_peer_disconnected:register(self._on_local_host_peer_disconnected, self)
        self.connection.local_host.event_peer_message:register(self._on_local_host_peer_message, self)
        self.state.value = self.source.state
    else
        self.connection.remote_host.event_message:register(self._on_remote_host_message, self)
    end
end

function pogo_session:_on_session_disconnected()
    -- If the remote host disconnected during mode completion, treat it as an intentional session close
    if self.connection.remote_host then
        local mode = self.state.value and self.state.value.mode
        if mode and mode.complete then
            self._lobby.session.value = nil
        end
    end
end

function pogo_session:_on_local_host_source_update(update_data)
	self.connection.local_host:broadcast_reliable(update_data)
end

function pogo_session:_on_local_host_peer_connected(peer_id)
    local state_data = self.source:write()
    self.connection.local_host:send_reliable(peer_id, state_data)
    local open_slot = self:_find_open_play_slot()
    table.insert(self.state.value.players, {
        id = peer_id,
        name = self.connection.participants[peer_id].name or peer_id,
        is_ready = true,
        play_slot = open_slot
    })
end

function pogo_session:_on_local_host_peer_disconnected(peer_id)
    for i = 1, #self.state.value.players do
        local player = self.state.value.players[i]
        if player.id == peer_id then
            table.remove(self.state.value.players, i)
            break
        end
    end
end

function pogo_session:_on_local_host_peer_message(peer_id, channel, message)
    if channel ~= 'reliable' then
        return
    end
    local success, message_data = pcall(lua_data.read, message)
    if not success then
        return
    end

    -- Session messages
    if message_data.request_spectate then
        self:_process_request_spectate(peer_id)
        return
    elseif message_data.request_play_slot then
        self:_process_request_play_slot(peer_id, message_data.request_play_slot)
        return
    end

    -- Mode messages
    local peer_state = self:_find_mode_player(peer_id)
    if not peer_state then
        return
    end
    if message_data.input then
        self:_process_input(peer_id, message_data.input, message_data.value)
    elseif message_data.ready then
        self:_process_ready(peer_id, message_data.ready)
    end
end

function pogo_session:_on_remote_host_message(channel, message)
    if not self.mirror then
        self.mirror = replication.mirror.new(message)
        self.state.value = self.mirror.state
    else
        self.mirror:apply_update(message)
    end
end

function pogo_session:_on_state_changed(state)
    if state.mode then
        self.current_mode.value = waiting_mode.new(state.mode)
    end
    state:get_field_ref('mode'):register(self._on_state_mode_update, self)
end

function pogo_session:start_mode(mode_name)
    assert(self.connection.local_host, 'Only the host can start a mode')
    local mode_state = {
        name = mode_name,
        seed = math.floor(time.seconds_since_start() * 1000),
        tick = 0,
        players = {},
        complete = false
    }
    local players = {}
    local spectators = {}
    for i, player in ipairs(self.state.value.players) do
        local mode_player = { id = player.id, name = player.name, play_slot = player.play_slot, inputs = {} }
        if player.play_slot then
            mode_player.play_slot = player.play_slot
            table.insert(players, mode_player)
        else
            table.insert(spectators, mode_player)
        end
    end
    for i = 1, #players do
        mode_state.players[i] = players[i]
    end
    for i = 1, #spectators do
        mode_state.players[#players + i] = spectators[i]
    end
    self.state.value.mode = mode_state
end

function pogo_session:_on_state_mode_update(mode_state)
    if not mode_state then
        self.current_mode.value = nil
        self._next_tick_timestamp = nil
        return
    end
    if class.instance_of(self.current_mode.value, waiting_mode) then
        return
    end
    local mode_type = game_mode
    local shadow_mode
    if mode_type then
        local mode_player_states = self.state.value.mode.players
        local mode_players = {}
        for i = 1, #mode_player_states do
            local player_state = mode_player_states[i]
            table.insert(mode_players, {
                name = player_state.name,
                play_slot = player_state.play_slot
            })
        end
        -- create some ai players
        if #mode_players < 4 then
            for i = #mode_players, 4 do
                table.insert(mode_players, {
                    name = 'AI' .. i + 1,
                    play_slot = i + 1,
                    is_ai = true
                })
            end
        end
        if not self.mode_interface then
            self.mode_interface = game_session_interface.new(self)
        end
        self.current_mode.value = mode_type.new(mode_state.seed, mode_players, self.mode_interface)
        shadow_mode = self._use_shadow_context and mode_type.new(mode_state.seed, mode_players, { pogo_session = self, is_shadow = true })
    end
    self._frame_queue = frame_queue.new(self.current_mode.value, mode_state, self.connection.local_host ~= nil, shadow_mode)
    self.current_mode.value.event_complete:register(self._on_current_mode_event_complete, self)
    mode_state:get_field_ref('complete'):register_next(self._on_state_mode_complete, self)
    self.active_invite.value = nil
end

function pogo_session:_on_state_mode_complete()
    if self.current_mode.value then
        self.current_mode.value:destroy()
    end
    self.active_invite.value = self.connection.id
end

function pogo_session:_on_current_mode_event_complete(complete_state)
    if self.connection.local_host then        
        -- Submit score to the leaderboard
        if self._lobby.connection.status.value == 'connected' then
            local leaderboard_name = tostring(#complete_state.players) .. 'P'
            self._lobby.connection:leaderboard_submit_entry(leaderboard_name, complete_state.total_score, complete_state)
        end

        -- Apply the complete state
        self.state.value.mode.complete_state = complete_state
        self.state.value.mode.complete = true
    end
end

---------------------------------------------------------------------------

function game_session_interface:init(pogo_session)
    self.pogo_session = pogo_session
end

function game_session_interface:srv_set_game_state(key, value)
end

function game_session_interface:get_game_state(key)
end

function game_session_interface:register_state_changed(handler, first_arg)
    local mode_state = self.pogo_session.state.value.mode
    if mode_state then
        mode_state:register(handler, first_arg)
    end
end

function game_session_interface:unregister_state_changed(handler, first_arg)
    local mode_state = self.pogo_session.state.value.mode
    if mode_state then
        mode_state:unregister(handler, first_arg)
    end
end

function game_session_interface:initiate_vote(vote_type, minimum_votes_for, time_limit, player_initial_response)
    self.pogo_session:client_request_vote(vote_type, minimum_votes_for, time_limit, player_initial_response)
end

function game_session_interface:submit_vote(vote_id, vote)
    self.pogo_session:client_submit_vote(vote_id, vote)
end

function game_session_interface:close_vote(vote_id)
    self.pogo_session:client_close_vote(vote_id)
end

return pogo_session
