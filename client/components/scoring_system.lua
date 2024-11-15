-- // ================================
-- // KDC - Scoring system
local resources = require 'resources'
local sprite_layers = require 'sprite_layers'
local floater = require 'components/floater'

local component = scenes.components.component
local transform = scenes.components.transform
local scoring_system = component.derive('scoring_system')

-- Constants
local CORE_THRESHOLD_MID = 20
local CORE_THRESHOLD_HIGH = 50
local POINTS_THRESHOLD_HIGH = 50
local FLOATER_LEFT_PAD = 16

function scoring_system:init (entity, ...)
    class.super(scoring_system).init(self, entity)

    self.generator = entity.scene.mode.generator

    self.delay_cores = 0.2
    self.accumulation_cores = 0
    self.recent_cores_timer = 0

    self.delay_points = 0.2
    self.accumulation_points = 0
    self.recent_points_timer = 0

    self.recent_drain = reactive.create_ref(false)
    self._recent_drain_timer_max = 0.2
    self._recent_drain_timer = 0

    self.cores = reactive.create_ref(0)
    self.credits = reactive.create_ref(0)

    self.entity.scene.event_update:register(self._on_scene_update, self)
end

function scoring_system:destroy ()
    self.entity.scene.event_update:unregister(self._on_scene_update, self)
end

-- Events
function scoring_system:_on_scene_update (elapsed_seconds)
    -- recent drain
    if self._recent_drain_timer > 0 then
        self._recent_drain_timer = self._recent_drain_timer - elapsed_seconds
        if self._recent_drain_timer <= 0 then
            self.recent_drain.value = false
        end
    end


    -- cores
    if self.recent_cores_timer > 0 then
        self.recent_cores_timer = self.recent_cores_timer - elapsed_seconds
        if self.recent_cores_timer <= 0 then
            self:_display_accumulated_cores(self.accumulation_cores)

            self.recent_cores_timer = 0
            self.accumulation_cores = 0
        end
    end

    -- points
    if self.recent_points_timer > 0 then
        self.recent_points_timer = self.recent_points_timer - elapsed_seconds
        if self.recent_points_timer <= 0 then
            self:_display_accumulated_credits(self.accumulation_points)

            self.recent_points_timer = 0
            self.accumulation_points = 0
        end
    end
end

-- Public
function scoring_system:increase_cores (amount)
    self.cores.value = self.cores.value + amount
    self.accumulation_cores = self.accumulation_cores + amount
    self.recent_cores_timer = self.delay_cores
end

function scoring_system:drain_cores (amount)
    self.cores.value = math.max(self.cores.value - amount, 1)
    self.recent_drain.value = true
    self._recent_drain_timer = self._recent_drain_timer_max

    -- if amount >= 10 then
    --     audio_manager:play('assets/audio/sfx/cores_increase_02.mp3')
    -- else
    --     audio_manager:play('assets/audio/sfx/cores_increase_01.mp3')
    -- end
end

function scoring_system:increase_credits (amount)
    self.credits.value = self.credits.value + amount
    self.accumulation_points = self.accumulation_points + amount
    self.recent_points_timer = self.delay_points
end

-- Private
function scoring_system:_display_accumulated_cores (value)
    local offset_x, offset_y = 180, 40

    if self.cores.value > 10 then
        local tens_places = math.floor(math.log(value) / math.log(10))
        offset_x = offset_x + (tens_places * FLOATER_LEFT_PAD)
    end

    local floater_y_direction = 0.5

    -- Flip y offset and direction if one of the top positions
    if self.variant == 3 or self.variant == 4 then
        offset_y, floater_y_direction = -offset_y, -floater_y_direction
    end

    local random_pos = self.entity.transform:get_world_translation() + vec2.pack(offset_x, offset_y)

    local floater_entity = self.entity.scene:create_entity()
    floater_entity:create_transform(nil, random_pos)
    floater_entity:create_gui_text("+" .. tostring(value), resources.commo_font, 32, sprite_layers.damage_floaters, { grid_align = 1, color = '#FF99CE', })
    floater_entity:create_component(floater, vec2.pack(0, floater_y_direction), 0.8, 0.16)

    -- SFX
    if value >= CORE_THRESHOLD_HIGH then
        --audio_manager:play('assets/audio/sfx/cores_increase_03.mp3')
    elseif value >= CORE_THRESHOLD_MID then
        --audio_manager:play('assets/audio/sfx/cores_increase_02.mp3')
    else
        --audio_manager:play('assets/audio/sfx/cores_increase_01.mp3')
    end
end

function scoring_system:_display_accumulated_credits (value)
    local offset_x, offset_y = 174, 20

    if self.credits.value > 10 then
        local tens_places = math.floor(math.log(self.cores.value) / math.log(10))
        offset_x = offset_x + (tens_places * FLOATER_LEFT_PAD)
    end

    local floater_y_direction = 0.5

    -- Flip y offset and direction if one of the top positions
    if self.variant == 3 or self.variant == 4 then
        offset_y, floater_y_direction = -offset_y, -floater_y_direction
    end

    local random_pos = self.entity.transform:get_world_translation() + vec2.pack(offset_x, offset_y)

    local floater_entity = self.entity.scene:create_entity()
    floater_entity:create_transform(nil, random_pos)
    floater_entity:create_gui_text("+" .. tostring(value), resources.commo_font, 32, sprite_layers.damage_floaters, { grid_align = 1, color = '#FFD557', })
    floater_entity:create_component(floater, vec2.pack(0, floater_y_direction), 0.8, 0.16)

    -- SFX
    if value >= POINTS_THRESHOLD_HIGH then
        --audio_manager:play('assets/audio/sfx/treasure_02.mp3')
    else
        --audio_manager:play('assets/audio/sfx/treasure_01.mp3')
    end
end

return scoring_system
