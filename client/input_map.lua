local input_map = {}

function input_map.map_keyboard_key(key_name)
    if key_name == 'H' then
        return 'left'
    elseif key_name == 'L' then
        return 'right'
    elseif key_name == 'J' then
        return 'down'
    elseif key_name == 'K' then
        return 'up'
    end
end

function input_map.map_mouse_button(button)
    if button == 1 then
        return 'arm'
    end
end

return input_map
