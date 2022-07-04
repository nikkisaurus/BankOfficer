local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

--[[ Tooltips ]]
private.tooltip = CreateFrame("GameTooltip", "BankOfficerTooltip", UIParent, "GameTooltipTemplate")

--[[ Embed Methods ]]
local methods = {

	All = {
		SetSize = function(widget, width, height)
			widget:SetWidth(width)
			widget:SetHeight(height)
		end,

		SetTooltip = function(widget, anchor, x, y, lines)
			widget:SetCallback("OnEnter", function()
				private.tooltip:SetOwner(widget.frame, anchor, x, y)
				for _, line in pairs(lines) do
					private.tooltip:AddLine(unpack(line))
				end
				private.tooltip:Show()
			end)

			widget:SetCallback("OnLeave", function()
				private.tooltip:ClearLines()
				private.tooltip:Hide()
			end)
		end,
	},

	Container = {
		AddChildren = function(widget, ...)
			for _, child in pairs({ ... }) do
				widget:AddChild(child)
			end
		end,
	},

	ScrollFrame = {
		DrawContent = function(widget, group)
			local func = private["Draw" .. group .. "Content"]
			if not func then
				return
			end
			func(private, widget)
		end,
	},
}

function private:EmbedMethods(widget, widgetTypes, release)
	for method, func in pairs(methods.All) do
		widget[method] = not release and func
	end

	for _, widgetType in pairs(widgetTypes) do
		for method, func in pairs(methods[widgetType]) do
			widget[method] = not release and func
		end
	end

	-- Unembed methods on release
	if widget.SetCallback then
		widget:SetCallback("OnRelease", function()
			self:EmbedMethods(widget, widgetTypes, true)
		end)
	end
end

--[[ Add frame to UISpecialFrames ]]
function private:AddSpecialFrame(frame, frameName)
	_G[frameName] = frame
	tinsert(UISpecialFrames, frameName)
	self[frameName] = frame
end

--[[ Get content container ]]
function private:GetContentContainer(parent)
	parent:SetLayout("Fill")

	local scrollContainer = AceGUI:Create("SimpleGroup")
	scrollContainer:SetLayout("Fill")
	parent:AddChild(scrollContainer)

	local scrollFrame = AceGUI:Create("ScrollFrame")
	self:EmbedMethods(scrollFrame, { "Container", "ScrollFrame" })
	scrollFrame:SetLayout("Flow")
	scrollContainer:AddChild(scrollFrame)
	parent:SetUserData("content", scrollFrame)

	return scrollFrame
end
