local resources = require 'resources'
local client_ui = require 'client_ui'
local pogo_session = require 'pogo_session'

---@class mission_stats_panel:class
local mission_stats_panel = class.create()

function mission_stats_panel:init(element, stats, session)
    local stats_panel = element:create_screen_panel('MISSION STATS', '#75F5D3', '100%', '100%')
    stats_panel:build(function()
        local total_credits = 0
        local pilot_scores_panel = stats_panel:create_screen_view('Pilot Credits', false, '100%', nil)
        for i = 1, pogo_session.PLAY_SLOT_COUNT do
            local pilot_row = pilot_scores_panel:create_element({
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
            local player_stats = stats.players[i]
            if player_stats then
                local label_style = {
                    width = '100%',
                    font_size = 16 * resources.scale,
                    text_wrap_mode = 'nowrap',
                    padding_left = 2 * resources.scale,
                    color = '#A4EDE4',
                }
                if session and player_stats.name == session.name then
                    label_style.color = '#F2F7DE'
                end
                local credits = client_ui.format_number_with_commas(player_stats.credits)
                pilot_row:create_text(player_stats.name .. ': ' .. credits, label_style)
                total_credits = total_credits + player_stats.credits
            end
        end
        local total_credits_panel = stats_panel:create_screen_view('Total Credits', false, '100%', nil)
        total_credits_panel:create_text(client_ui.format_number_with_commas(total_credits), {
            font_size = 24 * resources.scale,
            color = '#A4EDE4',
        })
        local boss_damage_panel = stats_panel:create_screen_view('Boss Damage', false, '100%', nil)
        boss_damage_panel:create_text(client_ui.format_number_with_commas(stats.boss_damage), {
            font_size = 24 * resources.scale,
            color = '#A4EDE4',
        })
        local total_score_panel = stats_panel:create_screen_view('Total Score', false, '100%', nil)
        total_score_panel:create_text(client_ui.format_number_with_commas(stats.total_score), {
            font_size = 40 * resources.scale,
            color = '#A4EDE4',
        })
    end)
end

return mission_stats_panel
