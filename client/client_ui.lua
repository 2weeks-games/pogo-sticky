local client_ui = {}

function client_ui.format_countdown_time(seconds)
    -- Calculate minutes and remaining seconds
    local minutes = math.floor(seconds / 60)
    local remaining_seconds = math.floor(seconds % 60)

    -- Format the time as "minutes:seconds"
    return string.format("%d:%02d", minutes, remaining_seconds)
end

function client_ui.format_number_with_commas(number)
    local formatted = tostring(number)
    local k

    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then
            break
        end
    end

    return formatted
end

return client_ui
