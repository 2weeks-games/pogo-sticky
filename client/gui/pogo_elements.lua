local resources = require 'resources'

function gui.element:create_computer_screen()
    local background = self:create_element({
        position = 'absolute',
        width = '100%',
        height = '100%',
        background_image = resources.gui.stars,
        background_size = 'cover'
    })
    local screen = background:create_element({
        position = 'absolute',
        bottom = 0,
        width = '100%',
        height = 480 * resources.scale,
        align_items = 'stretch',
        color = '#FFD557'
    })
    local screen_left = screen:create_element({ width = 58 * resources.scale, height = '100%', background_size = '100%', background_image = resources.gui.monitor_left })
    local screen_middle = screen:create_element({ flex_grow = 1, flex_direction = 'column', align_items = 'stretch' })
    local screen_right = screen:create_element({ width = 58 * resources.scale, height = '100%', background_size = '100%', background_image = resources.gui.monitor_right })

    local screen_top = screen_middle:create_element({ justify_content = 'center', height = 34 * resources.scale, width = '100%', background_size = '100%', background_image = resources.gui.monitor_top })
    local screen_top_badge = screen_top:create_element({ width = 77 * resources.scale, height = '100%', background_size = '100%', background_image = resources.gui.monitor_top_badge })
	local screen_center = screen_middle:create_element({ flex_grow = 1 })
	local screen_content = screen_center:create_element({ position = 'absolute', width = '100%', height = '100%', opacity = 0.75, background_image = resources.gui.grid, background_size = 7 * resources.scale })
	local screen_overlay = screen_center:create_element({ position = 'absolute', width = '100%', height = '100%', opacity = 0.75, pointer_events = 'none' })
    local screen_bottom = screen_middle:create_element({ justify_content = 'center', height = 81 * resources.scale, width = '100%', background_size = '100%', background_image = resources.gui.monitor_bottom })
    local screen_bottom_center = screen_bottom:create_element({ width = 532 * resources.scale, height = '100%', background_size = '100%', background_image = resources.gui.monitor_bottom_center })
    
	local how_to_play_panel = screen_overlay:create_how_to_play_screen()
	local screen_help_button = screen:create_button(nil, {
		width = 33 * resources.scale,
		height = 34 * resources.scale,
		padding = 0,
		background_image = resources.gui.monitor_help_button,
		background_size = 'contain',
		position = 'absolute',
		right = 39 * resources.scale,
		bottom = 32 * resources.scale,
		background_blend_mode = 'multiply',
		background_color = vec4.pack(1, 1, 1, 1),
		hover = {
			background_color = vec4.pack(0.9, 0.9, 0.9, 1),
		},
		active = {
			background_color = vec4.pack(0.75, 0.75, 0.75, 1),
		}
	})
	screen_help_button.event_clicked:register(function()
		if how_to_play_panel.style.display == 'flex' then
			how_to_play_panel.style.display = 'none'
		else
			how_to_play_panel.style.display = 'flex'
		end
	end)
	
	return screen_content
end

function gui.element:create_how_to_play_screen()
	local how_to_play_panel = self:create_element({
		position = 'absolute',
		left = 64,
		top = 32,
		width = '90%',
		height = '90%',
		flex_direction = 'column',
		align_items = 'center',
		background_color = '#000000',
		border_width = 2,
		border_color = vec4.pack(1, 1, 1, 1),
		border_radius = 4,
		display = 'none',
	})
	how_to_play_panel:build(function(panel)
		local info_panel_width = 350
		local info_panel_height = 520
		local how_to_play_contents = panel:create_element({ flex_direction = 'row', align_items = 'center' })

		-- Panel 1
		how_to_play_contents:create_element({
			flex_direction = 'column',
			width = info_panel_width,
			height = info_panel_height,
			align_items = 'center',
			background_color = '#FFC54A',
			background_image = resources.how_to_play_01,
			border_width = 2,
			border_color = vec4.pack(1, 1, 1, 1),
			border_radius = 4,
			margin = vec4.pack(16, 16, 0, 0),
		})

		-- Panel 2
		how_to_play_contents:create_element({
			flex_direction = 'column',
			width = info_panel_width,
			height = info_panel_height,
			align_items = 'center',
			background_color = '#FFC54A',
			background_image = resources.how_to_play_02,
			border_width = 2,
			border_color = vec4.pack(1, 1, 1, 1),
			border_radius = 4,
			margin = vec4.pack(16, 16, 0, 0),
		})

		-- Panel 3
		how_to_play_contents:create_element({
			flex_direction = 'column',
			width = info_panel_width,
			height = info_panel_height,
			align_items = 'center',
			background_color = '#FFC54A',
			background_image = resources.how_to_play_03,
			border_width = 2,
			border_color = vec4.pack(1, 1, 1, 1),
			border_radius = 4,
			margin = vec4.pack(16, 16, 0, 0),
		})

		-- Panel 4
		how_to_play_contents:create_element({
			flex_direction = 'column',
			width = info_panel_width,
			height = info_panel_height,
			align_items = 'center',
			background_color = '#FFC54A',
			background_image = resources.how_to_play_04,
			border_width = 2,
			border_color = vec4.pack(1, 1, 1, 1),
			border_radius = 4,
			margin = vec4.pack(16, 16, 0, 0),
		})

		-- Horizontal divider
		panel:create_element({
			width = '70%',
			height = 4,
			background_color = color or gui.styles.colors.cornflowerblue:pack(.5),
			margin = vec4.pack(16, 0, 16, 0),
		})

		panel:create_screen_button("Let's go!").event_clicked:register(function()
			panel.style.display = 'none'
		end)
	end)
	return how_to_play_panel
end

function gui.element:create_screen_panel(label, label_color, width, height)
	local container = self:create_element({
		width = width,
		height = height,
		flex_direction = 'column',
	})
    local header = container:create_element({
        width = '100%',
        height = 22 * resources.scale,
        flex_shrink = 0,
		border_width = 1 * resources.scale,
		border_color = '#1B5A66',
		background_color = '#1B5A6640',
        align_items = 'center',
        padding_left = 3 * resources.scale,
		padding_right = 3 * resources.scale,
    })
	header:create_text(label, {
		color = label_color,
		font_family = 'commo',
		font_size = 36 * resources.scale,
        padding_top = -8 * resources.scale,
		flex_shrink = 0,
		flex_grow = 1,
        height = '100%',
	})
	local panel = container:create_element({
		width = '100%',
		height = '100%',
		border_left_width = 1 * resources.scale,
		border_right_width = 1 * resources.scale,
		border_bottom_width = 1 * resources.scale,
		border_color = '#1B5A66',
		padding = 3 * resources.scale,
		flex_direction = 'column'
	})
	return panel, header
end

function gui.element:create_screen_frame(width, height)
	local container = self:create_element({
		width = width,
		height = height,
		border = 2 * resources.scale,
		background_color = '#1B5A6640',
	})
	local function place_frame_element(vertical, horizontal)
		local background = resources.gui['screen_frame_' .. vertical .. '_' .. horizontal]
		container:create_element({
			position = 'absolute',
			[vertical] = -1 * resources.scale,
			[horizontal] = -1 * resources.scale,
			width = background.size_x * resources.scale,
			height = background.size_y * resources.scale,
			background_image = background,
			background_size = 'contain',
		})
	end
	place_frame_element('top', 'left')
	place_frame_element('top', 'right')
	place_frame_element('bottom', 'left')
	place_frame_element('bottom', 'right')
	return container:create_element({
		width = '100%',
		height = '100%',
		padding = 3 * resources.scale,
		flex_direction = 'column',
		align_items = 'center'
	})
end

function gui.element:create_screen_view(label, fill_background, width, height)
	local container = self:create_element({
		width = width,
		height = height,
		flex_direction = 'column',
	})
	local header = container:create_element({
        width = '100%',
        height = 22 * resources.scale,
        flex_shrink = 0,
		border_width = 1 * resources.scale,
		border_color = '#1B5A66',
		background_color = '#1B5A6640',
        align_items = 'center',
    })
	header:create_text(label, {
		color = '#1B5A66',
		font_family = 'commo',
		font_size = 36 * resources.scale,
        padding_top = -8 * resources.scale,
        padding_left = 3 * resources.scale,
		flex_shrink = 0,
        height = '100%',
	})
	return container:create_element({
		width = '100%',
		height = '100%',
		border_left_width = 1 * resources.scale,
		border_right_width = 1 * resources.scale,
		border_bottom_width = 1 * resources.scale,
		border_color = '#1B5A66',
		background_color = fill_background and '#1B5A6640' or nil,
		padding = 4 * resources.scale,
		flex_direction = 'column',
		align_items = 'center',
		overflow_y = 'scroll'
	})
end

function gui.element:create_screen_button(contents, enabled, hover)
    local default_color = gui.styles.color_from_dimension('#D52090')
    local r, g, b = vec4.unpack(default_color)
    local background_color = vec4.pack(r, g, b, 0.17)
	local text
	local style = {
        border_width = 1 * resources.scale,
        border_color = hover and '#00000000' or default_color,
		flex_shrink = 0,
		font_family = 'command_prompt',
	}
	if type(contents) == 'string' then
		text = contents
        style.font_size = 16 * resources.scale
        style.color = hover and '#00000000' or default_color
        style.padding = vec2.pack(1 * resources.scale, 2 * resources.scale)
        style.background_color = hover and 'transparent' or background_color
        style.hover = {
			color = default_color,
			border_color = default_color,
            background_color = vec4.pack(r, g, b, 0.33),
        }
        style.active = {
			color = default_color,
			border_color = default_color,
            background_color = vec4.pack(r, g, b, 0.5),
        }
	else
		style.padding = 0
		style.background_image = contents
		style.width = contents.size_x * resources.scale
		style.height = contents.size_y * resources.scale
		style.background_size = 'contain'
        style.hover = {
			color = default_color,
			border_color = default_color,
            background_color = vec4.pack(1, 1, 1, 1.25),
        }
        style.active = {
			color = default_color,
			border_color = default_color,
            background_color = vec4.pack(1, 1, 1, 1.5),
        }
	end
    return self:create_button(text, style, enabled)
end

function gui.element:create_screen_checkbox(value)
	local default_color = gui.styles.color_from_dimension('#D52090')
    local rgb = vec3.pack(default_color)
    local background_color = vec4.pack(rgb, 0.17)
    local hover_color = vec4.pack(rgb * 0.9, 1)
    local active_color = vec4.pack(rgb * 0.75, 1)
    return self:create_checkbox(value, {
        border_color = default_color,
        background_color = background_color,
        border_width = 2 * resources.scale,
        margin = 2 * resources.scale,
        padding = 4 * resources.scale,
        width = 6 * resources.scale,
        height = 6 * resources.scale,
        hover = {
            border_color = hover_color,
        },
        active = {
            border_color = active_color,
        },
        check = {
            background_color = default_color,
            hover = {
                background_color = hover_color,
            },
            active = {
                background_color = active_color,
            }
        }
    })
end