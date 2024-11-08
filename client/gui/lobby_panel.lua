local resources = require 'resources'
local pogo_session = require 'pogo_session'
local launch_params = require 'launch_params'

---@class lobby_panel:class
local lobby_panel = class.create()

function lobby_panel:init(element, lobby)
    self._lobby = lobby
    local lobby_panel = element:create_screen_panel('LOBBY', '#75F5D3', '100%', '100%')
    lobby_panel:build(function()
        local missions_panel = lobby_panel:create_screen_view('Missions', false, '100%', '100%')
        missions_panel.style.align_items = 'stretch'
        
        missions_panel:build(function()
            local missions = {}
            for id, session in pairs(lobby.connection.sessions) do
                table.insert(missions, session)
            end
            table.sort(missions, function(a, b) return a.name < b.name end)
            local current_session = self._lobby.session.value and self._lobby.session.value.connection
            for i = 1, #missions do
                local mission = missions[i]
                local row_style = {
                    flex_direction = 'row',
                    align_items = 'center',
                }
                if (i % 2) == 0 then
                    row_style.background_color = '#1B5A6640'
                end
                local mission_row = missions_panel:create_element(row_style)
                local label_style = {
                    width = '100%',
                    font_size = 16 * resources.scale,
                    text_wrap_mode = 'nowrap',
                    color = '#A4EDE4',
                }
                if mission.host_id == self._lobby.connection.local_participant_id then
                    label_style.color = '#F2F7DE'
                end
                mission_row:create_text(mission.name and (mission.name .. "'s Mission") or "Unnamed Mission", label_style)
                if current_session and current_session.status.value ~= 'connecting' and mission.id == current_session.id then
                    mission_row:create_screen_button('Joined', false)
                elseif not current_session or current_session.status.value == 'connected'  or current_session.status.value == 'disconnected' then
                    local join_button = mission_row:create_screen_button('Join')
                    join_button.event_clicked:register(function()
                        if current_session then
                            current_session:close()
                        end
                        self._lobby:join_session(mission.id, launch_params.use_shadow_context)
                    end)
                end
            end
        end)

        local spacer = lobby_panel:create_element({ height = 12 * resources.scale, flex_shrink = 0 })
        local pilots_panel = lobby_panel:create_screen_view('Pilots', false, '100%', '100%')
        pilots_panel:build(function()
            local pilots = {}
            for id, participant in pairs(self._lobby.connection.participants) do
                table.insert(pilots, participant)
            end
            table.sort(pilots, function(a, b) return a.name < b.name end)
            for i = 1, #pilots do
                local style = {
                    align_self = 'flex_begin',
                    text_wrap_mode = 'nowrap',
                    color = '#A4EDE4',
                }
                if pilots[i].id == self._lobby.connection.local_participant_id then
                    style.color = '#F2F7DE'
                end
                pilots_panel:create_text(pilots[i].name, style)
            end
        end)
    end)
end

return lobby_panel