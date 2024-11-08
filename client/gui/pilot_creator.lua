local resources = require 'resources'
local pogo_preferences = require 'pogo_preferences'

---@class pilot_creator:class
local pilot_creator = class.create()

local banned_initials = {
	["ASS"] = true, ["FUC"] = true, ["FUK"] = true, ["FUQ"] = true, ["FUX"] = true, ["FCK"] = true,
	["COC"] = true, ["COK"] = true, ["COQ"] = true, ["KOX"] = true, ["KOC"] = true, ["KOK"] = true,
	["KOQ"] = true, ["CAC"] = true, ["CAK"] = true, ["CAQ"] = true, ["KAC"] = true, ["KAK"] = true,
	["KAQ"] = true, ["DIC"] = true, ["DIK"] = true, ["DIQ"] = true, ["DIX"] = true, ["DCK"] = true,
	["PNS"] = true, ["PSY"] = true, ["FAG"] = true, ["FGT"] = true, ["NGR"] = true, ["NIG"] = true,
	["CNT"] = true, ["KNT"] = true, ["SHT"] = true, ["DSH"] = true, ["TWT"] = true, ["BCH"] = true,
	["CUM"] = true, ["CLT"] = true, ["KUM"] = true, ["KLT"] = true, ["SUC"] = true, ["SUK"] = true,
	["SUQ"] = true, ["SCK"] = true, ["LIC"] = true, ["LIK"] = true, ["LIQ"] = true, ["LCK"] = true,
	["JIZ"] = true, ["JZZ"] = true, ["GAY"] = true, ["GEY"] = true, ["GEI"] = true, ["GAI"] = true,
	["VAG"] = true, ["VGN"] = true, ["SJV"] = true, ["FAP"] = true, ["PRN"] = true, ["LOL"] = true,
	["JEW"] = true, ["JOO"] = true, ["GVR"] = true, ["PUS"] = true, ["PIS"] = true, ["PSS"] = true,
	["SNM"] = true, ["TIT"] = true, ["FKU"] = true, ["FCU"] = true, ["FQU"] = true, ["HOR"] = true,
	["SLT"] = true, ["JAP"] = true, ["WOP"] = true, ["KIK"] = true, ["KYK"] = true, ["KYC"] = true,
	["KYQ"] = true, ["DYK"] = true, ["DYQ"] = true, ["DYC"] = true, ["KKK"] = true, ["JYZ"] = true,
	["PRK"] = true, ["PRC"] = true, ["PRQ"] = true, ["MIC"] = true, ["MIK"] = true, ["MIQ"] = true,
	["MYC"] = true, ["MYK"] = true, ["MYQ"] = true, ["GUC"] = true, ["GUK"] = true, ["GUQ"] = true,
	["GIZ"] = true, ["GZZ"] = true, ["SEX"] = true, ["SXX"] = true, ["SXI"] = true, ["SXE"] = true,
	["SXY"] = true, ["XXX"] = true, ["WAC"] = true, ["WAK"] = true, ["WAQ"] = true, ["WCK"] = true,
	["POT"] = true, ["THC"] = true, ["VAJ"] = true, ["VJN"] = true, ["NUT"] = true, ["STD"] = true,
	["LSD"] = true, ["POO"] = true, ["AZN"] = true, ["PCP"] = true, ["DMN"] = true, ["ORL"] = true,
	["ANL"] = true, ["ANS"] = true, ["MUF"] = true, ["MFF"] = true, ["PHK"] = true, ["PHC"] = true,
	["PHQ"] = true, ["XTC"] = true, ["TOK"] = true, ["TOC"] = true, ["TOQ"] = true, ["MLF"] = true,
	["RAC"] = true, ["RAK"] = true, ["RAQ"] = true, ["RCK"] = true, ["SAC"] = true, ["SAK"] = true,
	["SAQ"] = true, ["PMS"] = true, ["NAD"] = true, ["NDZ"] = true, ["NDS"] = true, ["WTF"] = true,
	["SOL"] = true, ["SOB"] = true, ["FOB"] = true, ["SFU"] = true, ["   "] = true
}

function pilot_creator:init(element)
	local default_initials = 'AAA'
	if pogo_preferences.pilot_initials and not banned_initials[pogo_preferences.pilot_initials] then
		default_initials = pogo_preferences.pilot_initials
	end
	self._initials = reactive.create_ref(default_initials)

	local function shift_letter(index, delta)
		local char = self._initials.value:sub(index, index)
		repeat
			if char == ' ' then
				if delta > 0 then
					char = 'A'
				else
					char = 'Z'
				end
			elseif char == 'A' and delta < 0 then
				char = ' '
			elseif char == 'Z' and delta > 0 then
				char = ' '
			else
				local char_code = char:byte()
				char_code = char_code + delta
				char = string.char(char_code)
			end
			self._initials.value = self._initials.value:sub(1, index - 1) .. char .. self._initials.value:sub(index + 1)
		until not banned_initials[self._initials.value]
	end

	local function add_letter_spinner(element, index)
		local column = element:create_element({
			flex_direction = 'column',
			align_items = 'center',
		})
		column:create_screen_button(resources.gui.arrow_up).event_clicked:register(function()
			shift_letter(index, 1)
		end)
		local letter_container = column:create_element({
			background_color = '#1B5A6640',
			justify_content = 'center',
			align_items = 'center',
			height = 24 * resources.scale,
			width = '100%'
		})
		letter_container:create_text(self._initials.value:sub(index, index), {
			font_size = 16 * resources.scale,
			color = '#F2F7DE',
			font_family = 'command_prompt',
		})
		column:create_screen_button(resources.gui.arrow_down).event_clicked:register(function()
			shift_letter(index, -1)
		end)
	end
	local spinners = element:create_element({
		justify_content = 'center',
	})
	spinners:build(function()
		add_letter_spinner(spinners, 1)
		add_letter_spinner(spinners, 2)
		add_letter_spinner(spinners, 3)
	end)
end

function pilot_creator:get_initials()
	return self._initials.value
end

return pilot_creator