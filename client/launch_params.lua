
local pogo_preferences = require 'pogo_preferences'
local pogo_lobby = require 'pogo_lobby'
local pilot_creator = require 'gui/pilot_creator'
local launch_params = {}

-- This should be false when checked in. Set to true to enable local raw input for debugging
launch_params.debug = false

function launch_params.load()
    syndication.init_promise:wait()
    local user_info = syndication.request_user_info()

    if pogo_preferences.lobby_id and pogo_preferences.lobby_id ~= '' then
        launch_params.lobby_id = pogo_preferences.lobby_id
    end

    local url_params = url.get_search_params(system.get_url())
    if url_params.lobby_id then
    	launch_params.lobby_id = url_params.lobby_id
    end
    if url_params.session_id then
        launch_params.session_id = url_params.session_id
    end
    if syndication.discord and syndication.discord.guild_id then
        launch_params.lobby_id = syndication.discord.guild_id
     end
     if syndication.invites then
        local invite_contents = syndication.invites.get_startup_invite()
        local success, invite_data = pcall(lua_data.read, invite_contents)
        if success and invite_data.lobby_id then
            launch_params.lobby_id = invite_data.lobby_id
        end
        if success and invite_data.session_id then
            launch_params.session_id = invite_data.session_id
        end
    end

    local logged_in, name = user_info:wait()
    if logged_in then
        launch_params.user_name = name
    end

	local args = environment.parse_arguments(
		{
            'mode-duration-override'
        },
		{
			'auto-create',
			'auto-join',
			'participant',
			'shadow-context',
		}
	)
	launch_params.use_shadow_context = args['shadow-context']
    launch_params.mode_duration_override = args['mode-duration-override']
    if launch_params.mode_duration_override then
        launch_params.mode_duration_override = tonumber(launch_params.mode_duration_override)
    end

    if args['auto-create'] then
		launch_params.lobby = pogo_lobby.new(nil, launch_params.user_name or pogo_preferences.pilot_initials)
        local lobby_connection = launch_params.lobby.connection
        local session = launch_params.lobby:create_session(launch_params.use_shadow_context)
        local session_connection = session.connection
        event.wait(session_connection.event_connected)
        threads.run_thread('initial_session_broadcast', function()
            while session_connection.status.value == 'connected' do
                system.broadcast(lua_data.write_text({
                    app = 'kdc',
                    lobby_id = lobby_connection.id,
                    session_id = session_connection.id,
                }))
                time.wait(1.0)
            end
        end)
        -- jump right into game mode
        threads.run_thread('start_mode', function()
            time.wait(0.1)
            session:start_mode('Pogo Sticking')
        end)
    elseif args['auto-join'] or args['participant'] then
        local join_signal = signal.new()
        system.set_broadcast_handler(function(address, message)
            local parsed, data = pcall(lua_data.read, message)
            if parsed and data.app == 'kdc' then
                launch_params.lobby_id = data.lobby_id
                launch_params.session_id = data.session_id
                if args['auto-join'] then
					launch_params.lobby = pogo_lobby.new(launch_params.lobby_id, launch_params.user_name or pogo_preferences.pilot_initials)
                    launch_params.lobby:join_session(launch_params.session_id, launch_params.use_shadow_context)
                end
				system.set_broadcast_handler()
                join_signal:complete()
            end
        end)
        join_signal:wait()
    else
        if launch_params.lobby_id and launch_params.user_name then
            launch_params.lobby = pogo_lobby.new(launch_params.lobby_id, launch_params.user_name)
            if launch_params.session_id then
                launch_params.lobby:join_session(launch_params.session_id, launch_params.use_shadow_context)
            end
        end
    end
end

return launch_params