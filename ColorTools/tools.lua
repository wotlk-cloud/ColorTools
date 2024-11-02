local CPF, OSF = ColorPickerFrame, OpacitySliderFrame

-- Make the color picker movable.
local mover = CreateFrame('Frame', nil, CPF)
mover:SetPoint('TOPLEFT', CPF, 'TOP', -60, 0)
mover:SetPoint('BOTTOMRIGHT', CPF, 'TOP', 60, -15)
mover:EnableMouse(true)
mover:SetScript('OnMouseDown', function() CPF:StartMoving() end)
mover:SetScript('OnMouseUp', function() CPF:StopMovingOrSizing() end)
CPF:SetUserPlaced(true)
CPF:EnableKeyboard(false)

local fauxHeader = CPF:CreateTexture(nil, 'OVERLAY')
fauxHeader:SetTexture([[Interface\DialogFrame\UI-DialogBox-Header]])
fauxHeader:SetAllPoints(ColorPickerFrameHeader)

local hex = CreateFrame('EditBox', nil, CPF)
hex:SetAutoFocus(false)
hex:SetFontObject(ChatFontNormal)
hex:SetMaxLetters(6)
hex:SetJustifyH('CENTER')
hex:SetFrameLevel(10)
hex:SetPoint('TOPLEFT', CPF, 'TOP', -30, 0)
hex:SetPoint('BOTTOMRIGHT', CPF, 'TOP', 30, -15)
hex:SetScript('OnEscapePressed', function(self) self:ClearFocus() end)
hex:SetScript('OnEditFocusGained', function(self)
	self:HighlightText(0, self:GetNumLetters())
end)
hex:SetScript('OnEditFocusLost', function(self)
	self:HighlightText(self:GetNumLetters())
end)

-- Saturation slider.
local saturation = CreateFrame('Slider', 'ColorTools_SatSlider', CPF, 'OptionsSliderTemplate')
saturation:SetMinMaxValues(0, 1)
saturation:SetValueStep(.05)
saturation:SetOrientation('VERTICAL')
saturation:SetThumbTexture([[Interface\Buttons\UI-SliderBar-Button-Vertical]])
saturation:SetHeight(OSF:GetHeight())
saturation:SetWidth(OSF:GetWidth())
saturation:SetPoint('LEFT', OSF, 'RIGHT', 5, 0)
_G['ColorTools_SatSliderLow']:ClearAllPoints()
_G['ColorTools_SatSliderHigh']:ClearAllPoints()
_G['ColorTools_SatSliderText']:ClearAllPoints()

-- Copy values.
local red, green, blue, opacity

local copy = CreateFrame('Button', nil, CPF, 'OptionsButtonTemplate')
copy:SetText('Copy')
copy:SetPoint('BOTTOMLEFT', CPF, 'TOPLEFT', 10, -2)
copy:SetScript('OnClick', function()
	red, green, blue = CPF:GetColorRGB()
	opacity = OSF:GetValue()
	
	copy:SetText(format('|cff%02x%02x%02xCopy', red * 255, green * 255, blue * 255))
end)

local paste = CreateFrame('Button', nil, CPF, 'OptionsButtonTemplate')
paste:SetText('Paste')
paste:SetPoint('BOTTOMRIGHT', CPF, 'TOPRIGHT', -10, -2)
paste:SetScript('OnClick', function()
	CPF:SetColorRGB(red, green, blue)
	OSF:SetValue(opacity)
end)

local editboxes = {
	Red = 0,
	Green = 1,
	Blue = 2,
	Alpha = 3
}

local UpdateCPFHSV = function()
	local s = saturation:GetValue()
	local h, _, v = CPF:GetColorHSV()
	CPF:SetColorHSV(h, s, v)
end

local UpdateCPFRGB = function(editbox)
	local r, g, b
	-- hex value
	if #editbox:GetText() == 6 then 
		local rgb = editbox:GetText()
		r, g, b = tonumber('0x'..strsub(rgb, 0, 2)), tonumber('0x'..strsub(rgb, 3, 4)), tonumber('0x'..strsub(rgb, 5, 6))
	-- numerical value
	else
		r, g, b = tonumber(editboxes.Red:GetText()), tonumber(editboxes.Green:GetText()), tonumber(editboxes.Blue:GetText())
	end
	
	-- lazy way to prevent most errors with invalid entries (letters)
	if r and g and b then
		-- % based
		if r <= 1 and g <= 1 and b <= 1 then
			CPF:SetColorRGB(r, g, b)
		-- 0 - 255 based
		else
			CPF:SetColorRGB(r / 255, g / 255, b / 255)
		end
	else
		print('|cffFF0000ColorTools|r: Error converting fields to numbers. Please check the values.')
	end
	
	-- update opacity
	OSF:SetValue(tonumber(editboxes.Alpha:GetText()) / 100)
end

local UpdateRGBFields = function()
	local _, s = CPF:GetColorHSV()
	saturation:SetValue(s)
	
	local r, g, b = CPF:GetColorRGB()
	editboxes.Red:SetText(r * 255)
	editboxes.Green:SetText(g * 255)
	editboxes.Blue:SetText(b * 255)
	
	hex:SetText(format('%02x%02x%02x', r * 255, g * 255, b * 255))
end

local UpdateAlphaField = function()
	editboxes.Alpha:SetText(OSF:GetValue() * 100)
end

saturation:SetScript('OnValueChanged', UpdateCPFHSV)
hex:SetScript('OnEnterPressed', function(self) 
	UpdateCPFRGB(self)
	self:ClearFocus() 
end)

for type, offsetFactor in pairs(editboxes) do
	local editbox = CreateFrame('EditBox', nil, CPF)
	editbox:SetHeight(15)
	editbox:SetWidth(35)
	--if offsetFactor == 1 then
		--editbox:SetPoint('TOP', ColorSwatch, 'BOTTOM', 0, -10)
	--else
		editbox:SetPoint('TOP', ColorSwatch, 'BOTTOM', 0, -(25 * offsetFactor))
	--end
	editbox:SetBackdrop({
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]], 
	})
	editbox:SetBackdropColor(0, 0, 0, .5)
	
	editbox:SetFontObject(ChatFontNormal)
	editbox:SetAutoFocus(false)
	editbox:SetMaxLetters(3)
	editbox:SetJustifyH('CENTER')
	
	editbox:SetScript('OnEscapePressed', function(self) self:ClearFocus() end)
	editbox:SetScript('OnEnterPressed', function(self) 
		UpdateCPFRGB(self)
		self:ClearFocus() 
	end)
	editbox:SetScript('OnEditFocusGained', function(self)
		self:HighlightText(0, self:GetNumLetters())
	end)
	editbox:SetScript('OnEditFocusLost', function(self)
		self:HighlightText(self:GetNumLetters())
	end)
	
	local title = editbox:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
	title:SetText(strmatch(type, '^%S'))
	title:SetPoint('RIGHT', editbox, 'LEFT', -3, 0)
	
	editboxes[type] = editbox
end

CPF:HookScript('OnShow', function()
	CPF:SetWidth(350)

	ColorPickerOkayButton:ClearAllPoints()
	ColorPickerOkayButton:SetPoint('BOTTOMLEFT', CPF, 'BOTTOMLEFT', 10, 10)
	ColorPickerCancelButton:ClearAllPoints()
	ColorPickerCancelButton:SetPoint('BOTTOMRIGHT', CPF, 'BOTTOMRIGHT', -10, 10)
		
	UpdateRGBFields()
end)
CPF:HookScript('OnColorSelect', UpdateRGBFields)
OSF:HookScript('OnShow', UpdateAlphaField)
OSF:HookScript('OnValueChanged', UpdateAlphaField)