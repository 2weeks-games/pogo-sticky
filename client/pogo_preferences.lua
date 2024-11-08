local game_defaults = {
    pilot_initials = 'AAA',
    lobby_id = '',
}

local preferences_dir = file_system.get_user_directory('2weeks', "Pogo Sticky")
local preferences_path = preferences_dir .. 'pogo_preferences.lua'

local pogo_preferences = preferences.load(preferences_path, game_defaults)

return pogo_preferences