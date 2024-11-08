local client_ui = require 'client_ui'
local resources = require 'resources'

---@class leaderboard_panel:class
local leaderboard_panel = class.create()

local MAX_LEADERBOARD_ENTRIES = 25

local default_leaderboard_entries = {}
local function add_score(boss_damage, ...)
    local player_scores = { ... }
    local entry_data = {
        boss_damage = boss_damage,
        total_score = boss_damage,
        players = {}
    }
    for i = 1, #player_scores do
        local player_score = player_scores[i]
        entry_data.total_score = entry_data.total_score + player_score
        table.insert(entry_data.players, {
            credits = player_score,
            name = 'CPU',
        })
    end
    local leaderboard_list = default_leaderboard_entries[tostring(#player_scores) .. 'P']
    table.insert(leaderboard_list, {
        score = entry_data.total_score,
        timestamp = 0,
        entry_data = entry_data
    })
end

default_leaderboard_entries['1P'] = {}
add_score(12000, 4000)
add_score(11000, 4000)
add_score(10000, 4000)
add_score(9000, 4000)

default_leaderboard_entries['2P'] = {}
add_score(24000, 3000, 3000)
add_score(22000, 3000, 3000)
add_score(20000, 3000, 3000)
add_score(18000, 3000, 3000)

default_leaderboard_entries['3P'] = {}
add_score(48000, 3000, 3000, 3000)
add_score(44000, 3000, 3000, 3000)
add_score(40000, 3000, 3000, 3000)
add_score(36000, 3000, 3000, 3000)

default_leaderboard_entries['4P'] = {}
add_score(96000, 1000, 1000, 1000, 1000)
add_score(90000, 1000, 1000, 1000, 1000)
add_score(84000, 1000, 1000, 1000, 1000)
add_score(78000, 1000, 1000, 1000, 1000)

function leaderboard_panel:init(element, lobby)
	local container = element:create_element({
        width = '100%',
		height = '100%',
		flex_direction = 'column',
	})
    container:build(function()
        local default_leaderboard = '1P'
        local session_state = lobby.session.value and lobby.session.value.state.value
        if session_state then
            local player_slots = 0
            for i = 1, #session_state.players do
                if session_state.players[i].play_slot then
                    player_slots = player_slots + 1
                end
            end
            if player_slots >= 1 then
                default_leaderboard = tostring(player_slots) .. 'P'
            end
        end
        local active_leaderboard = reactive.create_ref(default_leaderboard)

        local header = container:create_element({
            width = '100%',
            height = 22 * resources.scale,
            flex_shrink = 0,
            border_width = 1 * resources.scale,
            border_color = '#1B5A66',
            background_color = '#1B5A6640',
            align_items = 'center',
        })
        header:create_text('LEADERBOARDS', {
            color = '#C15DF4',
            font_family = 'commo',
            font_size = 36 * resources.scale,
            padding_top = -8 * resources.scale,
            padding_left = 3 * resources.scale,
            flex_grow = 1,
            height = '100%',
        })
        local leaderboard_selectors = {}
        local function add_leaderboard_selector(name)
            local button = header:create_screen_button(name, name ~= active_leaderboard.value)
            button.style.background_color = 'transparent'
            leaderboard_selectors[name] = button
            button.event_clicked:register(function()
                active_leaderboard.value = name
                for name, selector in pairs(leaderboard_selectors) do
                    selector:set_enabled(name ~= active_leaderboard.value)
                end
            end)
        end
        add_leaderboard_selector('1P')
        add_leaderboard_selector('2P')
        add_leaderboard_selector('3P')
        add_leaderboard_selector('4P')
        local leaderboard_view = container:create_element({
            width = '100%',
            height = '100%',
            border_left_width = 1 * resources.scale,
            border_right_width = 1 * resources.scale,
            border_bottom_width = 1 * resources.scale,
            border_color = '#1B5A66',
            padding = 3 * resources.scale,
            flex_direction = 'column'
        })

        local rank_width = 46 * resources.scale
        local team_width = 119 * resources.scale
        local score_width = 129 * resources.scale
        leaderboard_view:build(function()
            local header = leaderboard_view:create_element({
                width = '100%',
                height = 21 * resources.scale,
                flex_shrink = 0,
                border_width = 1 * resources.scale,
                border_color = '#1B5A66',
                background_color = '#1B5A6640',
                align_items = 'center',
            })
            header:create_text('RANK', {
                color = '#1B5A66',
                font_family = 'commo',
                font_size = 33 * resources.scale,
                padding_top = -7 * resources.scale,
                padding_left = 3 * resources.scale,
                border_right_width = 1 * resources.scale,
                border_color = '#1B5A66',
                width = rank_width,
                height = '100%',
                flex_shrink = 0,
            })
            header:create_text('TEAM', {
                color = '#1B5A66',
                font_family = 'commo',
                font_size = 33 * resources.scale,
                padding_top = -7 * resources.scale,
                padding_left = 3 * resources.scale,
                border_right_width = 1 * resources.scale,
                border_color = '#1B5A66',
                width = team_width,
                flex_grow = 1,
                height = '100%',
            })
            header:create_text('SCORE', {
                color = '#1B5A66',
                font_family = 'commo',
                font_size = 33 * resources.scale,
                padding_top = -7 * resources.scale,
                padding_left = 3 * resources.scale,
                width = score_width,
                height = '100%',
            })
            local table_view = leaderboard_view:create_element({
                width = '100%',
                flex_shrink = 0,
                height = 282 * resources.scale,
                border_left_width = 1 * resources.scale,
                border_right_width = 1 * resources.scale,
                border_bottom_width = 1 * resources.scale,
                border_color = '#1B5A66',
                background_color = '#1B5A6640',
                overflow_y = 'scroll'
            })
            table_view:build(function()
                local leaderboard = lobby.leaderboards[active_leaderboard.value]
                if not leaderboard then
                    table_view:create_text('Loading...', {
                        color = '#1B5A66',
                        font_family = 'commo',
                        font_size = 33 * resources.scale,
                        padding_left = 3 * resources.scale,
                    })
                else
                    local min_height = 281 * resources.scale
                    local rank_column = table_view:create_element({
                        width = rank_width + 3 * resources.scale,
                        flex_shrink = 0,
                        border_right_width = 1 * resources.scale,
                        border_bottom_width = 1 * resources.scale,
                        border_color = '#1B5A66',
                        flex_direction = 'column',
                    })
                    local team_column = table_view:create_element({
                        width = team_width,
                        flex_grow = 1,
                        border_right_width = 1 * resources.scale,
                        border_bottom_width = 1 * resources.scale,
                        border_color = '#1B5A66',
                        flex_direction = 'column',
                    })
                    local score_column = table_view:create_element({
                        width = score_width,
                        border_bottom_width = 1 * resources.scale,
                        border_color = '#1B5A66',
                        flex_direction = 'column',
                    })

                    local entries = {}
                    local default_entries = default_leaderboard_entries[active_leaderboard.value]
                    if default_entries then
                        for i = 1, #default_entries do
                            table.insert(entries, default_entries[i])
                        end
                    end
                    for i = 1, #leaderboard.entries do
                        table.insert(entries, leaderboard.entries[i])
                    end
                    table.sort(entries, function(a, b)
                        if a.score == b.score then
                            return a.timestamp < b.timestamp
                        end
                        return a.score > b.score
                    end)

                    local local_participant = lobby.connection.participants[lobby.connection.local_participant_id]
                    for i = 1, math.min(MAX_LEADERBOARD_ENTRIES, #entries) do
                        local entry = entries[i]
                        local row_height, background_image, background_color, rank_text, score_color
                        if i <= 3 then
                            row_height = 33 * resources.scale
                            background_image = resources.gui['rank_' .. i]
                            if i == 1 then
                                score_color = '#FFD557'
                            elseif i == 2 then
                                score_color = '#FFA647'
                            else
                                score_color = '#EC7A09'
                            end
                        else
                            row_height = 19 * resources.scale
                            background_color = i % 2 == 0 and '#1B5A6640' or 'transparent'
                            rank_text = tostring(i)
                            score_color = '#A4EDE4'
                        end
                        local rank = rank_column:create_element({
                            width = '100%',
                            height = row_height,
                            flex_shrink = 0,
                            background_image = background_image,
                            background_size = 'contain',
                            background_color = background_color,
                            justify_content = 'center',
                            align_items = 'center',
                        })
                        if rank_text then
                            rank:create_text(rank_text, {
                                color = '#1B5A66',
                                font_family = 'command_prompt',
                                font_size = 16 * resources.scale,
                            })
                        end
                        local team = team_column:create_element({
                            width = '100%',
                            height = row_height,
                            flex_shrink = 0,
                            background_color = background_color,
                            align_items = 'center',
                        })
                        local players_text = ''
                        local team_color = score_color
                        if entry.entry_data then
                            local players = entry.entry_data.players or entry.entry_data.participants
                            for i = 1, #players do
                                local player = players[i]
                                if i > 1 then
                                    players_text = players_text .. ', '
                                end
                                players_text = players_text .. player.name
                                if player.name == local_participant.name then
                                    team_color = '#F2F7DE'
                                end
                            end
                        end
                        team:create_text(players_text, {
                            color = team_color,
                            font_family = 'command_prompt',
                            font_size = 16 * resources.scale,
                            padding_left = 4 * resources.scale,
                        })
                        local score = score_column:create_element({
                            width = '100%',
                            height = row_height,
                            flex_shrink = 0,
                            background_color = background_color,
                            justify_content = 'flex_end',
                            align_items = 'center',
                        })
                        score:create_text(client_ui.format_number_with_commas(entry.score), {
                            color = score_color,
                            font_family = 'command_prompt',
                            font_size = 16 * resources.scale,
                            padding_right = 10 * resources.scale,
                        })
                    end
                end
            end)
        end)
    end)
end

return leaderboard_panel