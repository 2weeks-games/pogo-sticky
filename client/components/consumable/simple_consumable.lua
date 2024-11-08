--[[
    Consumable that can be consumed once and then is destroyed
]]


local consumable_component = require 'components/consumable/consumable_component'

local simple_consumable = scenes.components.component.derive('simple_consumable', consumable_component)

function simple_consumable:init(entity, consume_handler)
    class.super(simple_consumable).init(self, entity)

    self._consume_handler = consume_handler
end

function simple_consumable:consume(player)
    class.super(simple_consumable).consume(self, player)

    if self._consume_handler then
        self._consume_handler(self, player)
    end

    self.entity:destroy()
end

return simple_consumable
