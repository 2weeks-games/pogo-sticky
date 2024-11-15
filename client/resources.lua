local resources = {}

function resources.init (display)
    if resources.initialized then return end

    resources.display = display
    resources.scale = 2

    local function load_pixel_texture(path, wrap_repeat)
        local texture = display:create_texture(images.decode(archive.load(path)))
        texture:filter_nearest()
        if wrap_repeat then
            texture:wrap_repeat()
        end
        return texture
    end

    -- preload sounds
    --audio_manager:load_sound('assets/audio/sfx/beam_hit_01.mp3')
    --audio_manager:load_sound('assets/audio/sfx/beam_hit_02.mp3')
    --audio_manager:load_sound('assets/audio/sfx/beam_hit_03.mp3')

    -- Audio paths
    --resources.audio = {
    --    vo = {
    --        lobby_player_joined = 'assets/audio/vo/VO_pilot_joined.mp3',
    --        lobby_player_left = 'assets/audio/vo/VO_pilot_left.mp3'
    --    }
    --}

    resources.commo_font = fonts.create(archive.load('assets/fonts/COMMO-REGULAR.ttf'))
    resources.command_prompt_font = fonts.create(archive.load('assets/fonts/command_prompt.ttf'))
    gui.font_cache.register('commo', resources.commo_font)
    gui.font_cache.register('command_prompt', resources.command_prompt_font)

    resources.gui = {}
    resources.gui.arrow_down = load_pixel_texture('assets/art/gui/arrow-down.png')
    resources.gui.arrow_left = load_pixel_texture('assets/art/gui/arrow-left.png')
    resources.gui.arrow_right = load_pixel_texture('assets/art/gui/arrow-right.png')
    resources.gui.arrow_up = load_pixel_texture('assets/art/gui/arrow-up.png')
    resources.gui.column_left = load_pixel_texture('assets/art/gui/column-left.png')
    resources.gui.column_right = load_pixel_texture('assets/art/gui/column-right.png')
    resources.gui.column_center = load_pixel_texture('assets/art/gui/column-center.png')
    resources.gui.launch_button = load_pixel_texture('assets/art/gui/launch-button.png')
    resources.gui.monitor_left = load_pixel_texture('assets/art/gui/monitor-left.png')
    resources.gui.monitor_right = load_pixel_texture('assets/art/gui/monitor-right.png')
    resources.gui.monitor_top = load_pixel_texture('assets/art/gui/monitor-top.png')
    resources.gui.monitor_bottom = load_pixel_texture('assets/art/gui/monitor-bottom.png')
    resources.gui.monitor_top_badge = load_pixel_texture('assets/art/gui/monitor-top-badge.png')
    resources.gui.monitor_bottom_center = load_pixel_texture('assets/art/gui/monitor-bottom-center.png')
    resources.gui.monitor_help_button = load_pixel_texture('assets/art/gui/monitor-help-button.png')
    resources.gui.rank_1 = load_pixel_texture('assets/art/gui/rank_1.png')
    resources.gui.rank_2 = load_pixel_texture('assets/art/gui/rank_2.png')
    resources.gui.rank_3 = load_pixel_texture('assets/art/gui/rank_3.png')
    resources.gui.screen_frame_top_left = load_pixel_texture('assets/art/gui/screen-frame-top-left.png')
    resources.gui.screen_frame_top_right = load_pixel_texture('assets/art/gui/screen-frame-top-right.png')
    resources.gui.screen_frame_bottom_left = load_pixel_texture('assets/art/gui/screen-frame-bottom-left.png')
    resources.gui.screen_frame_bottom_right = load_pixel_texture('assets/art/gui/screen-frame-bottom-right.png')
    resources.gui.stars = load_pixel_texture('assets/art/gui/stars.png')
    resources.gui.logo = load_pixel_texture('assets/art/gui/KDC_Logo.png')
    resources.gui.grid = load_pixel_texture('assets/art/gui/grid.png', true)
    resources.gui.lobby_player_icons = {
        load_pixel_texture('assets/art/gui/lobby-icon-p1.png'),
        load_pixel_texture('assets/art/gui/lobby-icon-p2.png'),
        load_pixel_texture('assets/art/gui/lobby-icon-p3.png'),
        load_pixel_texture('assets/art/gui/lobby-icon-p4.png')
    }
    resources.gui.lobby_spectator_icon = load_pixel_texture('assets/art/gui/lobby-icon-spectator.png')

    --resources.turret_cable = load_pixel_texture('assets/art/player/turret_cable.png')
    resources.turrets = {}
    for i = 1, 4 do
        resources.turrets[i] = {
            cursor = load_pixel_texture('assets/art/player/turret_cursor_' .. i .. '.png'),
            --body = load_pixel_texture('assets/art/player/turret_body_' .. i .. '.png'),
            --arm_left = load_pixel_texture('assets/art/player/turret_arm_left_' .. i .. '.png'),
            --arm_right = load_pixel_texture('assets/art/player/turret_arm_right_' .. i .. '.png'),
            --arm_base = load_pixel_texture('assets/art/player/turret_arm_base_' .. i .. '.png'),
        }
    end

    resources.background_tex = load_pixel_texture('assets/art/asteroid/asteroid.png')

    -- how-to-play
    --resources.how_to_play_01 = display:create_texture(images.decode(archive.load('assets/art/how_to_play/how_to_play_01.png')))
    --resources.how_to_play_02 = display:create_texture(images.decode(archive.load('assets/art/how_to_play/how_to_play_02.png')))
    --resources.how_to_play_03 = display:create_texture(images.decode(archive.load('assets/art/how_to_play/how_to_play_03.png')))
    --resources.how_to_play_04 = display:create_texture(images.decode(archive.load('assets/art/how_to_play/how_to_play_04.png')))

    -- utility
    --resources.cover_plane_tex = display:create_texture(images.decode(archive.load('assets/art/gui/cover_plane_black.png')))
    --resources.exclamation_tex = display:create_texture(images.decode(archive.load('assets/art/utility/exclamation.png')))

    -- warning
    --resources.warning_tex = display:create_texture(images.decode(archive.load('assets/art/warning/warning_01.png')))

    -- xp cores
    --resources.xp_core_small_pink_tex = display:create_texture(images.decode(archive.load('assets/art/cores/xp_core_small_pink.png')))
    --resources.xp_core_small_gold_tex = display:create_texture(images.decode(archive.load('assets/art/cores/xp_core_small_gold.png')))
    --resources.xp_core_med_pink_tex = display:create_texture(images.decode(archive.load('assets/art/cores/xp_core_med_pink.png')))
    --resources.xp_core_med_gold_tex = display:create_texture(images.decode(archive.load('assets/art/cores/xp_core_med_gold.png')))
    --resources.xp_core_large_pink_tex = display:create_texture(images.decode(archive.load('assets/art/cores/xp_core_large_pink.png')))
    --resources.xp_core_large_gold_tex = display:create_texture(images.decode(archive.load('assets/art/cores/xp_core_large_gold.png')))
    --resources.xp_core_large_purple_tex = display:create_texture(images.decode(archive.load('assets/art/cores/xp_core_large_purple.png')))

    --resources.core_xl_pink = display:create_texture(images.decode(archive.load('assets/art/cores/core_xl_pink.png')))
    --resources.core_xl_gold = display:create_texture(images.decode(archive.load('assets/art/cores/core_xl_gold.png')))

    ---- powerups
    --resources.powerup_01_tex = display:create_texture(images.decode(archive.load('assets/art/powerups/powerup_01.png')))
    --resources.powerup_02_tex = display:create_texture(images.decode(archive.load('assets/art/powerups/powerup_02.png')))

    ---- basic shot
    --resources.basic_yellow_01_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/basic/basic_yellow_01.png')))
    --resources.basic_flash_01 = display:create_texture(images.decode(archive.load('assets/art/weapons/basic/basic_flash_01.png')))

    --resources.shot_blue_01_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/basic/shot_blue_01.png')))
    --resources.shot_blue_02_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/basic/shot_blue_02.png')))
    --resources.shot_blue_03_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/basic/shot_blue_03.png')))
    --resources.shot_pink_01_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/basic/shot_pink_01.png')))
    --resources.shot_pink_02_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/basic/shot_pink_02.png')))
    --resources.shot_pink_03_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/basic/shot_pink_03.png')))
    --resources.shot_purple_01_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/basic/shot_purple_01.png')))
    --resources.shot_purple_02_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/basic/shot_purple_02.png')))
    --resources.shot_purple_03_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/basic/shot_purple_03.png')))
    --resources.shot_yellow_01_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/basic/shot_yellow_01.png')))
    --resources.shot_yellow_02_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/basic/shot_yellow_02.png')))
    --resources.shot_yellow_03_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/basic/shot_yellow_03.png')))

    ---- turbo shot
    --resources.turbo_shot_01 = display:create_texture(images.decode(archive.load('assets/art/weapons/basic/turbo_shot_01.png')))
    --resources.muzzle_flash_turbo_01 = display:create_texture(images.decode(archive.load('assets/art/weapons/basic/muzzle_flash_turbo_01.png')))

    ---- beam
    --resources.beam_blue_01_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/beam/beam_blue_01.png')))
    --resources.beam_fire_start_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/beam/beam_fire_start.png')))
    --resources.beam_fire_loop_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/beam/beam_fire_loop.png')))
    --resources.beam_fire_end_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/beam/beam_fire_end.png')))

    ---- hitsparks - basic
    --resources.hitspark_basic_blue_01_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/hitspark/hitspark_basic_blue_01.png')))
    --resources.hitspark_basic_green_01_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/hitspark/hitspark_basic_green_01.png')))
    --resources.hitspark_basic_yellow_01_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/hitspark/hitspark_basic_yellow_01.png')))

    ---- hitsparks - fancy
    --resources.hitspark_fancy_01_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/hitspark/hitspark_fancy_01.png')))
    --resources.hitspark_fancy_02_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/hitspark/hitspark_fancy_02.png')))
    --resources.hitspark_fancy_03_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/hitspark/hitspark_fancy_03.png')))
    --resources.hitspark_fancy_04_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/hitspark/hitspark_fancy_04.png')))
    --resources.hitspark_fancy_05_tex = display:create_texture(images.decode(archive.load('assets/art/weapons/hitspark/hitspark_fancy_05.png')))

    ---- drones
    --resources.drone_blue_01_tex = display:create_texture(images.decode(archive.load('assets/art/enemies/drone_blue_01.png')))
    --resources.drone_pink_01_tex = display:create_texture(images.decode(archive.load('assets/art/enemies/drone_pink_01.png')))
    --resources.drone_yellow_01_tex = display:create_texture(images.decode(archive.load('assets/art/enemies/drone_yellow_01.png')))

    ---- resources.drone_idle_01_tex = display:create_texture(images.decode(archive.load('assets/art/animated/drone_idle_01.png')))
    --resources.drone_death_01_tex = display:create_texture(images.decode(archive.load('assets/art/animated/drone_death_01.png')))
    --resources.drone_death_texture = display:create_texture(images.decode(archive.load('assets/art/debug/debug_dot_fade.png')))

    -- debug
    resources.debug_dot_fade_tex = display:create_texture(images.decode(archive.load('assets/art/debug/debug_dot_fade.png')))
    resources.debug_dot_tex = display:create_texture(images.decode(archive.load('assets/art/debug/debug_dot.png')))

    -- boss
    --resources.boss_sprite = load_pixel_texture('assets/art/enemies/boss_sprite_02.png')
    --resources.boss_cracks_01 = load_pixel_texture('assets/art/enemies/boss_cracks_01.png')
    --resources.boss_cracks_02 = load_pixel_texture('assets/art/enemies/boss_cracks_02.png')
    --resources.boss_cracks_03 = load_pixel_texture('assets/art/enemies/boss_cracks_03.png')
    --resources.boss_spawn_02 = display:create_texture(images.decode(archive.load('assets/art/enemies/boss_spawn_02.png')))
    --resources.boss_spawn_03 = display:create_texture(images.decode(archive.load('assets/art/enemies/boss_spawn_03.png')))

    resources.initialized = true
end

return resources
