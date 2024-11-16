require 'gui/pogo_elements'
local launch_params = require 'launch_params'
local pogo_lobby = require 'pogo_lobby'
local title_screen = require 'gui/title_screen'
local connecting_screen = require 'gui/connecting_screen'
local lobby_screen = require 'gui/lobby_screen'
local game_screen = require 'gui/game_screen'
local waiting_mode = require 'modes/waiting_mode'

---@class pogo_root:class
local pogo_root = class.create()

function pogo_root:init()
    self._lobby = reactive.create_ref(launch_params.lobby)
    self._invite_link = reactive.create_ref()
end

function pogo_root:start_lobby_music()
    --audio_manager:play_music('assets/audio/music/KDC_MainMenu_01.mp3', true, 0.3)
end

function pogo_root:build(element)
    if not self._lobby.value then
        self._screen = title_screen.new(element)
        self._screen.event_lobby_selected:register(function(lobby_id, name)
            self._lobby.value = pogo_lobby.new(lobby_id, name)
            if launch_params.session_id then
                self._lobby.value:join_session(launch_params.session_id, launch_params.use_shadow_context)
			else
				launch_params.skip_to_mode(self._lobby.value, lobby_id, 'Pogo Sticking')
			end
        end)
        experiment.ribbon_on()
        self:start_lobby_music()
        return
    end
    local lobby = self._lobby.value
    if lobby.connection.status.value ~= 'connected' then
        self._screen = connecting_screen.new(element, lobby.connection)
        self._screen.event_reset:register(function ()
            self._lobby.value = nil
        end)
        experiment.ribbon_on()
        self:start_lobby_music()
        return
    end
    local session = lobby.session.value
    local mode = session and session.current_mode.value
    if not mode or mode.scene.pending_loads.value > 0 or session.state.value.mode.complete or class.instance_of(mode, waiting_mode) then
        self._screen = lobby_screen.new(element, lobby)
        experiment.ribbon_on()
        self:start_lobby_music()
    else
        self._screen = game_screen.new(element, mode)
        experiment.ribbon_off()
    end
end

function pogo_root.run(element)
    scenes.set_gui_cache_root(element.root)
    pogo_root.instance = pogo_root.new()
    element:build(pogo_root.build, pogo_root.instance)
end

return pogo_root
