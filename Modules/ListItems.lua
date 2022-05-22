local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

-- Status label
local SetStatusLabelTip = function(text)
	local statusLabel = private.GetChild(private.status.ruleScrollFrame, "statusLabel")
	statusLabel:SetText(text)
	statusLabel:SetColor(1, 1, 1)
end

local RestoreStatusLabelTip = function(text)
	local statusLabel = private.GetChild(private.status.ruleScrollFrame, "statusLabel")
	statusLabel:SetText(text or "")
	statusLabel:SetColor(1, 0, 0)
end

local DisableGuildTabFromListItemID = function(ruleName, listName, itemID, guildKey, tab, enabled)
	ruleName = ruleName or private.status.ruleName
	listName = listName or private.status.listName
	addon.db.global.rules[private.status.ruleName].lists[private.status.listName].itemIDs[itemID].guilds[guildKey][tab] =
		enabled
end

local LoadGuildSettingsList = function(itemID, itemName, iconTexture)
	local scrollContainer = private.GetChild(private.status.ruleScrollFrame, "guildSettingsScrollContainer")
	local scrollFrame = private.GetChild(scrollContainer, "guildSettingsScrollFrame")

	scrollFrame:ReleaseChildren()

	local itemIDLabel = AceGUI:Create("Label")
	itemIDLabel:SetUserData("elementName", "itemIDLabel")
	itemIDLabel:SetFullWidth(true)
	itemIDLabel:SetImage(iconTexture)
	itemIDLabel:SetFontObject(GameFontNormal)
	itemIDLabel:SetColor(1, 0.82, 0)
	itemIDLabel:SetText(itemName)

	private.AddChildren(scrollFrame, { itemIDLabel })

	for guildKey, enabled in pairs(addon.db.global.rules[private.status.ruleName].guilds) do
		if enabled then
			local guildGroup = AceGUI:Create("InlineGroup")
			guildGroup:SetUserData("elementName", "guildGroup")
			guildGroup:SetUserData("children", {})
			guildGroup:SetTitle(guildKey)
			guildGroup:SetLayout("Flow")
			guildGroup:SetFullWidth(true)

			private.AddChildren(scrollFrame, { guildGroup })

			for i = 1, addon.db.global.guilds[guildKey].tabsPurchased do
				local tabCheckBox = AceGUI:Create("CheckBox")
				tabCheckBox:SetUserData("elementName", "tabCheckBox" .. i)
				tabCheckBox:SetLabel(L.TabID(i))
				tabCheckBox:SetRelativeWidth(1 / 3)
				tabCheckBox:SetValue(
					addon.db.global.rules[private.status.ruleName].lists[private.status.listName].itemIDs[itemID].guilds[guildKey][i]
				)
				tabCheckBox:SetCallback("OnValueChanged", function(_, _, _, checked)
					DisableGuildTabFromListItemID(_, _, itemID, guildKey, i, checked)
				end)

				private.AddChildren(guildGroup, { tabCheckBox })
			end

			scrollFrame:DoLayout()
		end
	end
end

local RemoveItemIDFromList = function(ruleName, listName, itemID)
	ruleName = ruleName or private.status.ruleName
	listName = listName or private.status.listName

	wipe(addon.db.global.rules[ruleName].lists[listName].itemIDs[itemID])
end

local itemNames = {}
private.LoadItemIDList = function()
	local itemIDs = addon.db.global.rules[private.status.ruleName].lists[private.status.listName].itemIDs
	local scrollContainer = private.GetChild(private.status.ruleScrollFrame, "itemIDScrollContainer")
	local scrollFrame = private.GetChild(scrollContainer, "itemIDScrollFrame")

	scrollFrame:ReleaseChildren()
	wipe(itemNames)

	for itemID, settings in pairs(itemIDs) do
		if settings.enabled then
			addon.CacheItem(itemID, function(itemID, itemIDs, itemNames)
				local itemName, itemLink, _, _, _, _, _, _, _, iconTexture = GetItemInfo(itemID)
				itemNames[itemLink] = { itemID = itemID, itemName = itemName, iconTexture = iconTexture }
			end, itemID, itemIDs, itemNames)
		end
	end

	for itemLink, itemInfo in addon.pairs(itemNames) do
		local itemLinkLabel = AceGUI:Create("InteractiveLabel")
		itemLinkLabel:SetUserData("elementName", "itemNameLabel" .. itemInfo.itemID)
		itemLinkLabel:SetRelativeWidth(14 / 15)
		itemLinkLabel:SetText(itemLink)
		itemLinkLabel:SetImage(itemInfo.iconTexture)
		itemLinkLabel:SetCallback("OnClick", function()
			LoadGuildSettingsList(itemInfo.itemID, itemInfo.itemName, itemInfo.iconTexture)
		end)
		itemLinkLabel:SetCallback("OnEnter", function()
			private.ShowHyperlinkTip(itemLink, itemLinkLabel.frame, "ANCHOR_LEFT")
		end)
		itemLinkLabel:SetCallback("OnLeave", function()
			private.HideTooltip()
		end)

		local removeItemIDLabel = AceGUI:Create("InteractiveLabel")
		removeItemIDLabel:SetUserData("elementName", "removeItemIDLabel" .. itemInfo.itemID)
		removeItemIDLabel:SetRelativeWidth(1 / 15)
		removeItemIDLabel:SetColor(1, 0, 0)
		removeItemIDLabel:SetText("x")
		removeItemIDLabel:SetCallback("OnClick", function()
			if not IsControlKeyDown() then
				return
			end
			RemoveItemIDFromList(_, _, itemInfo.itemID)
			private.LoadItemIDList()
		end)

		local statusLabelText
		removeItemIDLabel:SetCallback("OnEnter", function()
			statusLabelText = private.GetChild(private.status.ruleScrollFrame, "statusLabel").label:GetText()
			SetStatusLabelTip(L["Control+click to remove from list"])
		end)
		removeItemIDLabel:SetCallback("OnLeave", function()
			RestoreStatusLabelTip(statusLabelText)
		end)

		private.AddChildren(scrollFrame, { itemLinkLabel, removeItemIDLabel })
	end
end
