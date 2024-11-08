local resources = require 'resources'
local leaderboard_panel = require 'gui/leaderboard_panel'
local lobby_panel = require 'gui/lobby_panel'
local mission_panel = require 'gui/mission_panel'
local mission_stats_panel = require 'gui/mission_stats_panel'
---@class lobby_screen:class
local lobby_screen = class.create()

function lobby_screen:init(element, lobby)
    self._lobby = lobby
	local screen = element:create_computer_screen()
	screen:build(function()
        local columns = screen:create_element({
            width = '100%',
            height = '100%',
            align_items = 'stretch',
            font_family = 'command_prompt',
            font_size = 16 * resources.scale,
        })
        local lobby_column = columns:create_element({
            flex_direction = 'column',
            width = 308 * resources.scale,
            flex_grow = 1,
            margin_top = 14 * resources.scale,
            margin_left = 14 * resources.scale,
            margin_bottom = 14 * resources.scale,
        })
        lobby_column:build(function()
            local session = self._lobby.session.value
            local session_state = session and session.state.value
            if session_state and session_state.mode and session_state.mode.complete_state then
                self._mission_stats_panel = mission_stats_panel.new(lobby_column, session_state.mode.complete_state, session)
            else
                self._lobby_panel = lobby_panel.new(lobby_column, self._lobby)
            end
        end)
        local mission_column = columns:create_element({
            flex_direction = 'column',
            align_items = 'center',
            flex_shrink = 0,
            column_gap = 18 * resources.scale,
            width = 187 * resources.scale,
            margin_left = 6 * resources.scale,
            margin_right = 6 * resources.scale,
            margin_bottom = 14 * resources.scale,
        })
        self._session_panel = mission_panel.new(mission_column, self._lobby)
        local leaderboard_column = columns:create_element({
            flex_direction = 'column',
            width = 308 * resources.scale,
            flex_grow = 1,
            margin_top = 14 * resources.scale,
            margin_right = 14 * resources.scale,
            margin_bottom = 14 * resources.scale,
        })
        self._leaderboard_panel = leaderboard_panel.new(leaderboard_column, self._lobby)
    end)
end

return lobby_screen