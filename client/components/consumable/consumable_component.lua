--[[
    Base component for entities that can be consumed by player turrets
]]

local consumable_component = scenes.components.component.derive('components/consumable/consumable_component')

consumable_component.consumable_consumed = event.new()

function consumable_component:init(entity)
    class.super(consumable_component).init(self, entity)
end

function consumable_component:consume(player)
    self:_dispatch_consumed(player)
end

-- Protected

function consumable_component:_dispatch_consumed(player, ...)
    consumable_component.consumable_consumed:dispatch(self, player)
end

return consumable_component
