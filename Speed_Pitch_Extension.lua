--
-- =============================================================================
-- VLC Media Player extension
-- Change Speed and Pitch
--
-- Author: Michal Daňhel
-- Copyright: Copyright (C) 2026 Michal Daňhel
-- Version: 1.0
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- EXTENSION - FUNCTIONS
-- -----------------------------------------------------------------------------

function descriptor()
	return {
		title = "Change Speed and Pitch",
        version = "1.0",
        author = "Michal Daňhel",
        url = "https://addons.videolan.org/p/2366154",
        description = "This extension can change playback speed and pitch shift, quickly and easily."
                   .. "\n\n"
                   .. "I created this extension for myself because I need to fine-tune a DJ set to lock straight when I am working."
                   .. "\n\n"
                   .. "This allows my mind to go to a \"Flow state\" ... 🎵 ... ⚡🎵 ... ⚡🎵🎵 ... 😍",
		capabilities = {}
	}
end

function activate()
	create_main_dialog()
end

function deactivate()
    -- Cleaning: Remove filter scaletempo_pitch when closing extension
    local aout = vlc.object.aout()
    if aout then
        local active_filters = vlc.var.get(aout, "audio-filter") or ""
        active_filters = string.gsub(active_filters, ":scaletempo_pitch", "")
        active_filters = string.gsub(active_filters, "scaletempo_pitch", "")
        vlc.var.set(aout, "audio-filter", active_filters)
    end
end

function close()
	vlc.deactivate()
end

-- -----------------------------------------------------------------------------
-- FUNCTIONS: HELPERS
-- -----------------------------------------------------------------------------

-- Safely converts text to a number (replaces any commas and dots for standard LUA parsing)
function parse_number(text, default_value)
    local safe_text = string.gsub(text, ",", ".")
    return tonumber(safe_text) or default_value
end

-- -----------------------------------------------------------------------------
-- UI INITIALIZATION & LAYOUT
-- -----------------------------------------------------------------------------
--
----------+----------+----------+---------------------------+---------------------------+--------------------------+----------+
--        | Column 1 | Column 2 | Column 3                  | Column 4                  | Column 5                 | Column 6 |
----------+----------+----------+---------------------------+---------------------------+--------------------------+----------+
--  Row 1 | [Image]  | [Border] | [Border]                                                                         | [Border] |
--  Row 2 |          |          | [Label: rate_title]                                                              |          |
--  Row 3 |          |          | [Label: rate_step_label]  | [Input: input_rate_step]  |                          |          |
--  Row 4 |          |          | [Button: rate_click(-1)]  | [Input: input_rate]       | [Button: rate_click(1)]  |          |
--  Row 5 |          |          | [Button: rate_reset()]                                                           |          |
--  Row 6 |          |          |                           |                           |                          |          |
--  Row 7 |          |          | [Label: pitch_title]                                                             |          |
--  Row 8 |          |          | [Label: pitch_step_label] | [Input: input_pitch_step] |                          |          |
--  Row 9 |          |          | [Button: pitch_click(-1)] | [Input: input_pitch]      | [Button: pitch_click(1)] |          |
-- Row 10 |          |          | [Button: pitch_reset()]                                                          |          |
-- Row 11 |          |          | [Border]                                                                         |          |
----------+----------+----------+---------------------------+---------------------------+--------------------------+----------+
--
function create_main_dialog()
	main_dialog = vlc.dialog(descriptor().title)

    --
    -- Borders
    --

    main_dialog:add_label("&nbsp;&nbsp;", 2, 1, 1, 1)
    main_dialog:add_label("&nbsp;", 3, 1, 3, 1)
    main_dialog:add_label("&nbsp;", 6, 1, 1, 1)
    main_dialog:add_label("&nbsp;", 3, 11, 3, 1)

    --
    -- Image
    --

    local user_dir = vlc.config.userdatadir()
    if user_dir then
        user_dir = string.gsub(user_dir, "\\", "/")
    end
    local image_path = user_dir .. "/lua/extensions/Speed_Pitch_Extension.jpg"

    main_dialog:add_image(image_path, 1, 1, 1, 11, 180, 240)

    --
    -- Rate
    --

    default_rate = 1.0
    default_rate_step = 0.01
    rate = default_rate
    rate_step = default_rate_step

    -- Reads current value from VLC
    local input = vlc.object.input()
    if input then
        rate = vlc.var.get(input, "rate") or default_rate
    end
    --
    main_dialog:add_label("<b>Playback speed</b>", 3, 2, 3, 1)
    --
    main_dialog:add_label("Step size:", 3, 3, 1, 1)
	input_rate_step = main_dialog:add_text_input(string.format("%.2f", rate_step), 4, 3, 1, 1)
    --
	main_dialog:add_button("<< Slower", function() rate_click(-1) end, 3, 4, 1, 1)
    input_rate = main_dialog:add_text_input(string.format("%.2f", rate), 4, 4, 1, 1)
	main_dialog:add_button("Faster >>", function() rate_click(1) end, 5, 4, 1, 1)
    --
    button_rate_reset = main_dialog:add_button("Reset", function() rate_reset() end, 3, 5, 3, 1)

    --
    -- Pitch
    --

    default_pitch = 0.0
    default_pitch_step = 0.1
    pitch = default_pitch
    pitch_step = default_pitch_step

    -- Gets link to audio output
    local aout = vlc.object.aout()
    if aout then
        -- Loads active filters
        local active_filters = vlc.var.get(aout, "audio-filter") or ""
        
        -- Activate scaletempo_pitch filter, if not
        if not string.find(active_filters, "scaletempo_pitch") then
            if active_filters == "" then
                vlc.var.set(aout, "audio-filter", "scaletempo_pitch")
            else
                vlc.var.set(aout, "audio-filter", active_filters .. ":scaletempo_pitch")
            end
            vlc.msg.dbg("[Speed_Pitch_Extension] Filter scaletempo_pitch activated.")
        end
        
        -- Reads current value from VLC
        pitch = vlc.var.get(aout, "pitch-shift") or 0.0
    else
        vlc.msg.dbg("[Speed_Pitch_Extension] The audio output is not active. Play the track first.")
    end

    --
    main_dialog:add_label("<b>Pitch shift</b>", 3, 7, 3, 1)
    --
    main_dialog:add_label("Step size:", 3, 8, 1, 1)
	input_pitch_step = main_dialog:add_text_input(string.format("%.1f", pitch_step), 4, 8, 1, 1)
    --
	main_dialog:add_button("<< Lower", function() pitch_click(-1) end, 3, 9, 1, 1)
    input_pitch = main_dialog:add_text_input(string.format("%.1f", pitch), 4, 9, 1, 1)
	main_dialog:add_button("Higher >>", function() pitch_click(1) end, 5, 9, 1, 1)
    --
    button_pitch_reset = main_dialog:add_button("Reset", function() pitch_reset() end, 3, 10, 3, 1)
end

-- -----------------------------------------------------------------------------
-- FUNCTIONS: LOGIC, EVENT HANDLERS, CALLBACKS
-- -----------------------------------------------------------------------------

function rate_reset()
    local input = vlc.object.input()
    if input then
        rate = default_rate
        rate_step = default_rate_step

        -- Update
        vlc.var.set(input, "rate", rate)
        input_rate:set_text(string.format("%.2f", rate))
        input_rate_step:set_text(string.format("%.2f", rate_step))

        vlc.msg.dbg("[Speed_Pitch_Extension] Playback speed reseted.")
    else
        vlc.msg.dbg("[Speed_Pitch_Extension] Audio input is not active to reset playback speed.")
    end
end

function rate_click(dir)
	local input = vlc.object.input()
	if input then
        rate = parse_number(input_rate:get_text(), default_rate)
		rate_step = parse_number(input_rate_step:get_text(), default_rate_step)

		-- Calculates new value
		rate = rate + (dir * rate_step)

		-- Update
		vlc.var.set(input, "rate", rate)
        input_rate:set_text(string.format("%.2f", rate))

        vlc.msg.dbg("[Speed_Pitch_Extension] Playback speed adjusted with click to: " .. rate)
    else
        vlc.msg.dbg("[Speed_Pitch_Extension] Audio input is not active to change playback speed.")
    end
end

function pitch_reset()
    local input = vlc.object.input()
    local aout = vlc.object.aout()
    if input and aout then
        pitch = default_pitch
        pitch_step = default_pitch_step

        -- Update
        vlc.var.set(aout, "pitch-shift", pitch)
        input_pitch:set_text(string.format("%.1f", pitch))
        input_pitch_step:set_text(string.format("%.1f", pitch_step))

        vlc.msg.dbg("[Speed_Pitch_Extension] Pitch shift reseted.")
    else
        vlc.msg.dbg("[Speed_Pitch_Extension] Audio input is not active to reset pitch shift.")
    end
end

function pitch_click(dir)
    local input = vlc.object.input()
    local aout = vlc.object.aout()

	if input and aout then
        -- Safety measure: If the filter didn't turn on at startup (because nothing was playing), we'll turn it on now
        local active_filters = vlc.var.get(aout, "audio-filter") or ""
        if not string.find(active_filters, "scaletempo_pitch") then
            if active_filters == "" then
                vlc.var.set(aout, "audio-filter", "scaletempo_pitch")
            else
                vlc.var.set(aout, "audio-filter", active_filters .. ":scaletempo_pitch")
            end
        end

        -- Loads values
        pitch = parse_number(input_pitch:get_text(), default_pitch)
        pitch_step = parse_number(input_pitch_step:get_text(), default_pitch_step)

        -- Calculates new value
        pitch = pitch + (dir * pitch_step)

        -- Limits
        if pitch > 12.0 then pitch = 12.0 end
        if pitch < -12.0 then pitch = -12.0 end

        -- Update
        vlc.var.set(aout, "pitch-shift", pitch)
        input_pitch:set_text(string.format("%.1f", pitch))

        vlc.msg.dbg("[Speed_Pitch_Extension] Pitch shift adjusted with click to: " .. pitch)
    else
        vlc.msg.dbg("[Speed_Pitch_Extension] Audio input is not active to change pitch shift.")
    end
end
