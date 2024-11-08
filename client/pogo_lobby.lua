local pogo_preferences = require 'pogo_preferences'
local pogo_session = require 'pogo_session'

local LOCAL_ENVIRONMENT = false

---@class pogo_lobby:class
local pogo_lobby = class.create()

function pogo_lobby:init(lobby_id, name)
	self.id = lobby_id
	self.name = name
	self.state = reactive.create_ref()
	self.session = reactive.create_ref()
	self.leaderboards = reactive.create_table()
	self.invite_link = reactive.create_ref()
	local lobby_options = { name = name }
    if syndication.discord then
        lobby_options.endpoint = syndication.discord.client_id .. '.discordsays.com/.proxy/lobbies'
        lobby_options.protocol = 'wss'
    end
	if LOCAL_ENVIRONMENT then
		lobby_options.endpoint = 'localhost:8787'
		lobby_options.protocol = 'ws'
	end

	if not lobby_id or lobby_id == '' then
		self.connection = lobbies.create_lobby(lobby_options)
	else
		self.connection = lobbies.join_lobby(lobby_id, lobby_options)
	end
	self.connection.event_connected:register(self._on_lobby_connected, self)
	self.connection.event_disconnected:register(self._on_lobby_disconnected, self)
end

function pogo_lobby:create_session(use_shadow_context)
	local session = pogo_session.new(self, nil, use_shadow_context)
	self.session.value = session
	return session
end

function pogo_lobby:join_session(id, use_shadow_context)
	local session = pogo_session.new(self, id, use_shadow_context)
	self.session.value = session
	return session
end

function pogo_lobby:_on_session_changed(session)
	if not session then
		if self._running_session and self._running_session.connection.status.value == 'connected' then
			syndication.signal_inactive()
			syndication.request_resume()
			if self._running_session.connection.local_host then
				self.connection:session_unlist(self._running_session.connection.id)
			end
		end
		self._running_session = nil
		self:_update_url()
		return
	end
	self._running_session = session
	local function on_running_session_connected()
		if session == self._running_session then
			if self._running_session.connection.local_host then
				self.connection:session_list(self._running_session.connection.id, self.name)
			end
			self:_update_url()
		end
	end
	if session.connection.status.value == 'connected' then
		on_running_session_connected()
	else
		session.connection.event_connected:register(on_running_session_connected)
	end
	session.state:register(function(state)
		if not state then
			return
		end
		state:get_field_ref('mode'):register_next(function(mode)
			if not mode then
				session:set_ready(false)
				syndication.signal_inactive()
				syndication.request_resume():on_fulfilled(function()
					if session == self._running_session then
						session:set_ready(true)
					end
				end)
			end
		end)
	end)
end

function pogo_lobby:_on_lobby_connected()
	local function setup_leaderboard(name)
		self.connection:leaderboard_subscribe(name):on_fulfilled(function(leaderboard)
			self.leaderboards[name] = leaderboard
		end)
	end
	setup_leaderboard('1P')
	setup_leaderboard('2P')
	setup_leaderboard('3P')
	setup_leaderboard('4P')
	self.local_participant = self.connection.participants[self.connection.local_participant_id]
	pogo_preferences.lobby_id = self.connection.id
	self.session:register(self._on_session_changed, self)
end

function pogo_lobby:_update_url()
	local current_url = system.get_url()
	local origin = url.get_origin(current_url)
	local path = url.get_pathname(current_url)
	local url = origin .. path
	local invite_link = nil
	if self.connection.status.value == 'connected' then
		url = url .. '?lobby_id=' .. self.connection.id
		local session_connection = self.session.value and self.session.value.connection
		if session_connection and session_connection.status.value == 'connected' then
			url = url .. '&session_id=' .. session_connection.id
			if not syndication.invites then
				invite_link = url
			else
				local invite_contents = lua_data.write_text({
					lobby_id = self.connection.id,
					session_id = session_connection.id,
				})
				invite_link = syndication.invites.create_invite(invite_contents, true)
			end
		end
	end
	system.set_url(url)
	self.invite_link.value = invite_link
	if not invite_link and syndication.invites then
		syndication.invites.hide_invite()
	end
end

function pogo_lobby:_on_lobby_disconnected()
	self:_update_url()
end

return pogo_lobby