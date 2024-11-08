local resources = require 'resources'
local client_ui = require 'client_ui'
local pogo_session = require 'pogo_session'
local launch_params = require 'launch_params'
local waiting_mode = require 'modes/waiting_mode'

---@class session_panel:class
local session_panel = class.create()

function session_panel:init(element, lobby)
    self._lobby = lobby
    element:create_element({
        width = resources.gui.logo.size_x * resources.scale,
        height = resources.gui.logo.size_y * resources.scale,
        background_image = resources.gui.logo,
        background_size = 'contain',
        margin_top = 8 * resources.scale,
        flex_shrink = 0,
    })
    local mission_panel, mission_header = element:create_screen_panel('Mission', '#75F5D3', '100%', 254 * resources.scale)
    if not syndication.invites then
        local copy_link_button = mission_header:create_screen_button('Copy Link')
        lobby.invite_link:register(function(link)
            if not link then
                copy_link_button.style.display = 'none'
            else
                copy_link_button.style.display = 'flex'
            end
        end)
        copy_link_button.event_clicked:register(function()
            if lobby.invite_link.value then
                system.set_clipboard(lobby.invite_link.value)
            end
        end)
    end
    local mission_frame = mission_panel:create_screen_frame('100%', '100%')
    mission_frame:build(function()
        local session = self._lobby.session.value
        if not session or session.connection.status.value ~= 'connected' then
            self:build_connection_panel(mission_frame, session)
        else
            local mode = session.current_mode.value
            if mode and not session.state.value.mode.complete then
                if class.instance_of(mode, waiting_mode) then
                    self:build_waiting_panel(mission_frame, session)
                else
                    self:build_loading_panel(mission_frame, mode)
                end
            else
                self:build_session_panel(mission_frame, session)
            end
        end
    end)
end

function session_panel:build_connection_panel(frame, session)
    local status_style = {
        color = '#75F5D3',
        font_size = 32 * resources.scale,
        font_family = 'commo'
    }
    if session and session.connection and session.connection.status.value ~= 'disconnected' then
        frame:create_text('Connecting...', status_style)
    else
        if session and session.connection and session.connection.status.value == 'disconnected' then
            frame:create_text('Disconnected', status_style)
            if session.connection.disconnect_reason then
                frame:create_text(session.connection.disconnect_reason, {
                    font_size = 16 * resources.scale,
                    font_family = 'command_prompt',
                    color = '#1B5A66'
                })
            end
        end
        local start_button = self:create_session_button(frame, 'START MISSION', '100%')
        start_button.event_clicked:register(function()
            self._lobby:create_session(launch_params.use_shadow_context)
        end)
    end
end

function session_panel:build_loading_panel(frame, mode)
    frame:create_text('Loading...', {
        color = '#75F5D3',
        font_size = 32 * resources.scale,
        font_family = 'commo'
    })
end

function session_panel:build_waiting_panel(frame, session)
    frame:create_text('Mission in Progress', {
        color = '#75F5D3',
        font_size = 32 * resources.scale,
        font_family = 'commo'
    })
    self:create_leave_button(frame, session, nil, '100%')
end

function session_panel:build_session_panel(frame, session)
    local pilots_panel = frame:create_screen_view('Pilots', false, '100%', 98 * resources.scale)
    pilots_panel.style.overflow_y = 'hidden'
    pilots_panel.style.padding = 0
    local local_player_is_pilot = false
    local pilot_count = 0
    for i = 1, pogo_session.PLAY_SLOT_COUNT do
        local pilot_row = pilots_panel:create_element({
            flex_direction = 'row',
            width = '100%',
            align_items = 'center',
        })
        local position_element = pilot_row:create_element({
            width = 11 * resources.scale,
            height = 18 * resources.scale,
            flex_shrink = 0,
            border_right_width = 1 * resources.scale,
            border_color = '#1B5A66',
            justify_content = 'center',
            align_items = 'center',
        })
        position_element:create_text(tostring(i), {
            font_size = 16 * resources.scale,
            color = '#1B5A66',
        })
        local player = session:get_player_in_play_slot(i)
        if player then
            pilot_count = pilot_count + 1
            local label_style = {
                width = '100%',
                font_size = 16 * resources.scale,
                text_wrap_mode = 'nowrap',
                padding_left = 2 * resources.scale,
                color = '#A4EDE4',
            }
            if player.id == session.connection.local_peer_id then
                local_player_is_pilot = true
                label_style.color = '#F2F7DE'
            end
            pilot_row:create_text(player.name, label_style)
        else
            local play_button = pilot_row:create_screen_button('Play Turret ' .. i, true, true)
            play_button.style.flex_grow = 1
            play_button.event_clicked:register(function()
                session:client_request_play_slot(i)
            end)
        end
    end
    local button_bar = frame:create_element({
        width = '100%',
        height = 37 * resources.scale,
        flex_direction = 'row',
        justify_content = 'center',
        align_items = 'center',
    })
    if session.connection.local_host then
        local start_button = self:create_session_button(button_bar, 'LUNCH', 55 * resources.scale, pilot_count > 0)
        start_button.event_clicked:register(function()
            session:start_mode('Asteroid Mining')
        end)
        self:create_leave_button(button_bar, session, 'END', 55 * resources.scale)
    else
        self:create_leave_button(button_bar, session, 'LEAVE MISSION', '100%')
    end
    local spectators_panel = frame:create_screen_view('Spectators', false, '100%', 80 * resources.scale)
    spectators_panel.style.align_items = 'flex_begin'
    local state = session.state.value
    if state then
        if local_player_is_pilot then
            local spectate_button = spectators_panel:create_screen_button('Spectate')
            spectate_button.event_clicked:register(function()
                session:client_request_spectate()
            end)
        end
        local spectators = {}
        for i = 1, #state.players do
            local player = state.players[i]
            if not player.play_slot then
                table.insert(spectators, player)
            end
        end
        table.sort(spectators, function(a, b) return a.name < b.name end)
        for i = 1, #spectators do
            local spectator = spectators[i]
            local style = {
                align_self = 'flex_begin',
                text_wrap_mode = 'nowrap',
                color = '#A4EDE4',
                flex_shrink = 0,
            }
            if spectator.id == session.connection.local_peer_id then
                style.color = '#F2F7DE'
            end
            spectators_panel:create_text(spectator.name, style)
        end

        if self._last_player_count then
            if #state.players > self._last_player_count then
                self:_play_lobby_audio(resources.audio.vo.lobby_player_joined)
            elseif #state.players < self._last_player_count then
                self:_play_lobby_audio(resources.audio.vo.lobby_player_left)
            end
        end
        self._last_player_count = #state.players
    end
end

function session_panel:_play_lobby_audio(path)
    local now = time.seconds_since_start()
    if not self._lobby_audio_timestamp or now - self._lobby_audio_timestamp > .1 then
        self._lobby_audio_timestamp = now
        audio_manager:play(path)
    end
end

function session_panel:create_leave_button(element, session, label, width)
    local leave_button = self:create_session_button(element, label or 'LEAVE MISSION', width)
    leave_button.event_clicked:register(function()
        if session.connection.local_host then
            self._lobby.connection:session_unlist(session.connection.id)
        end
        session.connection:close()
        self._lobby.session.value = nil
    end)
    return leave_button
end

function session_panel:create_session_button(element, label, width, enabled)
    return element:create_button(label, {
        width = width,
        height = 16 * resources.scale,
        padding = 4 * resources.scale,
        flex_shrink = 0,
        align_items = 'center',
        justify_content = 'center',
        color = '#D52090',
        font_size = 30 * resources.scale,
        font_family = 'commo',
        border_width = 1 * resources.scale,
        border_color = '#D52090',
        margin_top = 4 * resources.scale,
        margin_bottom = 4 * resources.scale,
        margin_left = 9 * resources.scale,
        margin_right = 9 * resources.scale,
        background_color = '#D520902B',
        hover = {
            background_color = '#D5209055',
        },
        active = {
            background_color = '#D520907F',
        }
    }, enabled)
end

return session_panel