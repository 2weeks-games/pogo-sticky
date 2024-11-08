local mode = require 'modes/mode'
local waiting_mode = class.create(mode)

function waiting_mode:init(state)
	class.super(waiting_mode).init(self, 960, 540, 0, {})
end

return waiting_mode