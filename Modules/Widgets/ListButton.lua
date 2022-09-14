local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = private.L
local AceGUI = LibStub("AceGUI-3.0")

local Type = "BankOfficer_ListButton"
local Version = 1

local methods = {
	OnAcquire = function(widget)
		widget.frame:Show()
		widget.frame:SetSize(300, 20)
		widget.label:SetText("")
	end,

	OnRelease = function(widget)
		widget.frame:Hide()
	end,

	SetLabel = function(widget, text)
		widget.label:SetText(text)
	end,

	SetText = function(widget) end,

	SetDisabled = function(widget, disabled)
		if disabled then
			widget.button:Disable()
		else
			widget.button:Enable()
		end
	end,

	OnWidthSet = function(widget, width)
		local labelWidth = width - 14
		widget.label:SetWidth(labelWidth)
		widget:SetHeight(widget.label:GetStringHeight())
	end,
}

local function Constructor()
	local frame = CreateFrame("Frame", Type .. AceGUI:GetNextWidgetNum(Type), UIParent)
	frame:EnableMouse(true)

	local button = CreateFrame("Button", nil, frame)
	button:SetPoint("TOPLEFT")
	button:SetSize(12, 12)
	button:SetNormalFontObject(GameFontRed)
	button:SetHighlightFontObject(GameFontHighlight)
	button:SetPushedTextOffset(0, 0)
	button:SetText("x")

	button:SetScript("OnClick", function(self)
		self.obj:Fire("OnEnterPressed")
	end)

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	label:SetPoint("TOPLEFT", button, "TOPRIGHT", 4, 0)
	label:SetJustifyH("LEFT")
	label:SetJustifyV("TOP")

	frame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 10)
		GameTooltip:AddLine(self.obj.label:GetText())
		GameTooltip:Show()
	end)

	frame:SetScript("OnLeave", function(self)
		GameTooltip:ClearLines()
		GameTooltip:Hide()
	end)

	local widget = {
		frame = frame,
		button = button,
		label = label,
		type = Type,
	}

	frame.obj = widget
	button.obj = widget

	for method, func in pairs(methods) do
		widget[method] = func
	end

	AceGUI:RegisterAsWidget(widget)

	return widget
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
