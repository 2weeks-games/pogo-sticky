local launch_params = require 'launch_params'

---@class game_screen:class
local game_screen = class.create()

function game_screen:init(element, mode)
    local session = mode.game_session.pogo_session
    local viewport = element:create_viewport(function(display, vx0, vy0, vx1, vy1)
        mode:set_viewport(vx0, vy0, vx1, vy1)
        session:update()
        mode.scene:render()
    end, { width = '100%', height = '100%' })
    viewport.event_keyboard_key_down:register(function (key_name, is_repeat, modifers)
        if not is_repeat then
            session:on_local_keyboard_key_down(key_name)
        end
    end)
    viewport.event_keyboard_key_up:register(function (key_name)
        session:on_local_keyboard_key_up(key_name)
        if launch_params.debug then
            mode:debug_key_up(key_name)
        end
    end)
    local function scene_from_virtual(...)
        local screen_x, screen_y = element.root:screen_from_virtual(...)
        local ray_start = mode.scene:ray_from_screen_position(screen_x, screen_y)
        local scene_x, scene_y = vec2.unpack(ray_start)
        return math.floor(0.5 + scene_x), math.floor(0.5 + scene_y)
    end
    viewport.event_mouse_hover_move:register(function(x, y)
        session:on_local_mouse_move(scene_from_virtual(x, y))
    end)
    viewport.event_pointer_down:register(function(operation)
        if operation.type == 'mouse_button' then
            session:on_local_mouse_button_down(operation.id, scene_from_virtual(operation.x, operation.y))
            operation.event_update:register(function()
                session:on_local_mouse_move(scene_from_virtual(operation.x, operation.y))
            end)
            operation.event_complete:register(function()
                session:on_local_mouse_button_up(operation.id, scene_from_virtual(operation.x, operation.y))
            end)
        end
    end)
    element.root:set_keyboard_focus(viewport)
end
return game_screen