local component = scenes.components.component
local transform = scenes.components.transform
local animated_sprite = component.derive('animated_sprite')

function animated_sprite:init(entity, sheet, layer, size, pivot, anim_data, ...)
    class.super(animated_sprite).init(self, entity)

    -- self.entity:create_transform()
    self.frame_size_x, self.frame_size_y = vec2.unpack(anim_data.frame_size)
    self.frame_count = anim_data.frame_count
    self.frame_duration = 1 / anim_data.frame_rate
    self.playback_mode = anim_data.playback_mode or 'loop'
    self.hold_frames = anim_data.hold_frames
    self.current_frame = 1
    self.time_since_last_frame = 0
    self.time_on_current_frame = 0
    if type(sheet) == 'string' then
        local promise_01 = self.entity:import_sprite(sheet, layer, size, pivot)
        promise_01:on_fulfilled(function(sprite) self:complete_init(sprite) end)
    else
        local sprite = self.entity:create_sprite(sheet, layer, size, pivot)
        self:complete_init(sprite)
    end
end

function animated_sprite:complete_init(sprite)
    -- relative to total size
    self.sprite = sprite

    self.tex_size_x = self.sprite.asset.size_x
    self.tex_size_y = self.sprite.asset.size_y

    self:calculate_frames()

    self.sprite:set_uvs(self:get_frame_rect(self.current_frame))
    self.entity.scene.event_update:register(self._on_scene_update, self)
end

function animated_sprite:destroy()
    self.entity.scene.event_update:unregister(self._on_scene_update, self)
end

-- calculate the number of frames per row and column
function animated_sprite:calculate_frames()
    self.frames_per_row = math.floor(self.tex_size_x / self.frame_size_x)
    self.frames_per_column = math.floor(self.tex_size_y / self.frame_size_y)
    return self.frames_per_row, self.frames_per_column
end

-- get the rectangle values for a specific frame
function animated_sprite:get_frame_rect(frame_index)
    -- Calculate the row and column of the frame
    local row = math.floor((frame_index - 1) / self.frames_per_row)
    local col = (frame_index - 1) % self.frames_per_row

    -- Calculate the top-left corner of the frame
    local u0 = col * self.frame_size_x
    local v0 = row * self.frame_size_y

    -- Calculate the bottom-right corner of the frame
    local u1 = col * self.frame_size_x + self.frame_size_x
    local v1 = row * self.frame_size_y + self.frame_size_y

    -- Convert pixel values to percentages
    local u0_percent = u0 / self.tex_size_x
    local v0_percent = v0 / self.tex_size_y
    local u1_percent = u1 / self.tex_size_x
    local v1_percent = v1 / self.tex_size_y

    return u0_percent, v0_percent, u1_percent, v1_percent
end

-- function animated_sprite:_on_scene_update(elapsed_seconds)
--     self.time_since_last_frame = self.time_since_last_frame + elapsed_seconds

--     while self.time_since_last_frame >= self.frame_duration do
--         self.time_since_last_frame = self.time_since_last_frame - self.frame_duration
--         self.current_frame = self.current_frame + 1

--         if self.playback_mode == 'one_shot' and self.current_frame > self.frame_count then
--             -- hold on last frame
--         elseif self.playback_mode == 'loop' and self.current_frame > self.frame_count then
--             self.current_frame = 1
--         -- TODO: add ping-pong playback logic
--         end

--         self.sprite:set_uvs(self:get_frame_rect(self.current_frame))
--     end
-- end

function animated_sprite:_on_scene_update(elapsed_seconds)
    self.time_since_last_frame = self.time_since_last_frame + elapsed_seconds

    -- Loop until the animation has caught up with the elapsed time
    while self.time_since_last_frame >= self.frame_duration do
        -- Get the hold time for the current frame, if it exists
        local hold_time = self:get_hold_time_for_frame(self.current_frame)

        -- If there's a hold time and we haven't finished holding the frame, stop advancing
        if hold_time and self.time_on_current_frame < hold_time then
            self.time_on_current_frame = self.time_on_current_frame + self.time_since_last_frame
            if self.time_on_current_frame < hold_time then
                -- If we're still holding the frame, break the loop
                self.time_since_last_frame = 0
                break
            else
                -- Otherwise, proceed to the next frame and reset the hold timer
                self.time_on_current_frame = 0
            end
        end

        -- Subtract the frame duration from the elapsed time
        self.time_since_last_frame = self.time_since_last_frame - self.frame_duration

        -- Advance the frame index
        self.current_frame = self.current_frame + 1

        -- Playback logic (one-shot, loop, etc.)
        if self.playback_mode == 'one_shot' and self.current_frame > self.frame_count then
            -- Hold on the last frame in one-shot mode
            self.current_frame = self.frame_count
        elseif self.playback_mode == 'loop' and self.current_frame > self.frame_count then
            -- Loop back to the first frame
            self.current_frame = 1
        -- TODO: add ping-pong playback logic
        end

        -- Update the sprite UVs to show the new frame
        self.sprite:set_uvs(self:get_frame_rect(self.current_frame))
    end
end

-- Helper function to get hold time for a specific frame
function animated_sprite:get_hold_time_for_frame(frame_index)
    if self.hold_frames then
        for _, hold_data in ipairs(self.hold_frames) do
            if hold_data[1] == frame_index then
                return hold_data[2]  -- Return the hold time if frame matches
            end
        end
    end
    return nil  -- No hold time for this frame
end

return animated_sprite
