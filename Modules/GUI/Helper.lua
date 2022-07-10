local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

--[[ Tooltips ]]
private.tooltip = CreateFrame("GameTooltip", "BankOfficerTooltip", UIParent, "GameTooltipTemplate")

--[[ Embed Methods ]]
local methods = {

	All = {
		OnNotifyChange = function(widget, func)
			widget:SetUserData("OnNotifyChange", func)
		end,

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

		NotifyChange = function(widget)
			local notifyWidget = widget:GetUserData("OnNotifyChange")
			if notifyWidget then
				notifyWidget()
			end

			for _, child in pairs(widget.children) do
				local notifyChild = child:GetUserData("OnNotifyChange")
				if notifyChild then
					notifyChild()
				end
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

--[[ Add frame to UISpecialFrames ]]
function private:AddSpecialFrame(frame, frameName)
	_G[frameName] = frame
	tinsert(UISpecialFrames, frameName)
	self[frameName] = frame
end

private.CacheItemCo = function(itemID)
	C_Timer.NewTicker(0.1, function(self)
		if GetItemInfo(itemID) then
			self:Cancel()
			return
		end
	end)
	coroutine.yield(itemID)
end

function private:CacheItem(itemID)
	local co = coroutine.create(private.CacheItemCo)
	local _, cachedItemID = coroutine.resume(co, itemID)
	while not cachedItemID do
		_, cachedItemID = coroutine.resume(co, itemID)
	end
end

function private:ValidateItem(itemID)
	local _, itemLink = GetItemInfo(itemID)
	if itemLink then
		local itemString = select(3, strfind(itemLink, "|H(.+)|h"))
		local _, itemId = strsplit(":", itemString)
		return tonumber(itemId)
	end
end
