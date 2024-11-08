local resources = require 'resources'
local launch_params = require 'launch_params'
local pogo_root = require 'gui/pogo_root'

math.random = function()
    error("math.random is nondeterministic - access the scene generator")
end

local function init(display)
    resources.init(display)
    launch_params.load()
end

experiment.run(
    'Pogo Sticky',
    'https://2weeks.games/experiments/hello-game',
    pogo_root.run,
    {
        size_x = 1280,
        size_y = 720,
        init = init
    }
)
