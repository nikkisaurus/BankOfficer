local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

-- Lists
local listTabs = {
	{
		value = "General",
		text = GENERAL,
	},
	{
		value = "itemIDs",
		text = L["ItemIDs"],
	},
	{
		value = "guilds",
		text = L["Guilds"],
	},
}

-- Database
local function AddItemIDToList(addItemIDEditBox, _, itemID)
	itemID = tonumber(itemID)
	local ruleName = private.status.ruleName
	local listName = private.status.listName
	local statusLabel = private.GetChild(private.status.ruleScrollFrame, "statusLabel")

	if not itemID then
		addItemIDEditBox:HighlightText()
		return statusLabel:SetText(L["Invalid itemID"])
	end

	addon.CacheItem(itemID, function(ruleName, listName, itemID, statusLabel)
		local itemName, _, _, _, _, _, _, _, _, _, _, _, _, bindType = GetItemInfo(itemID)
		if not itemName then
			addItemIDEditBox:HighlightText()
			return statusLabel:SetText(L["Invalid itemID"])
		elseif bindType == 1 then
			addItemIDEditBox:HighlightText()
			return statusLabel:SetText(L["Cannot add soulbound item to rule"])
		elseif private.ListContainsItemID(ruleName, listName, itemID) then
			addItemIDEditBox:HighlightText()
			return statusLabel:SetText(L["ItemID exists in list rule"])
		end

		addon.db.global.rules[ruleName].lists[listName].itemIDs[itemID].enabled = true
		statusLabel:SetText("")
		addItemIDEditBox:SetText("")
		addItemIDEditBox:ClearFocus()
		private.LoadItemIDList()
	end, ruleName, listName, itemID, statusLabel)
end

private.AddList = function(ruleName, listName)
	ruleName = ruleName or private.status.ruleName
	listName = listName or private.status.listName
	local statusLabel = private.GetChild(private.status.ruleScrollFrame, "statusLabel")

	if not listName or listName == "" then
		return statusLabel:SetText(L["Missing list name"])
	elseif private.ListExists(listName, ruleName) then
		return statusLabel:SetText(L.ListExists(listName))
	end

	addon.db.global.rules[ruleName].lists[listName].min = 1

	local treeGroup = private.status.ruleTreeGroup
	treeGroup:SetTree(private.GetTreeList())
	treeGroup:SelectByPath("lists", listName)
end

local function DeleteList(ruleName, listName)
	ruleName = ruleName or private.status.ruleName
	listName = listName or private.status.listName
	local treeGroup = private.status.ruleTreeGroup

	wipe(addon.db.global.rules[ruleName].lists[listName])
	treeGroup:SetTree(private.GetTreeList())
	treeGroup:SelectByPath("lists")
end

local function ConfirmDeleteList(ruleName, listName)
	ruleName = ruleName or private.status.ruleName
	listName = listName or private.status.listName

	private.CreateCoroutine(function()
		private.RequestConfirmation(L.DeleteList(ruleName, listName))

		if not coroutine.yield() then
			return
		end

		DeleteList(ruleName, listName)
	end)

	coroutine.resume(private.co)
end

local function DuplicateList(ruleName, listName)
	ruleName = ruleName or private.status.ruleName
	listName = listName or private.status.listName
	local newListName = addon.EnumerateString(listName, private.ListExists, ruleName)

	addon.db.global.rules[ruleName].lists[newListName] = addon.CloneTable(
		addon.db.global.rules[ruleName].lists[listName]
	)

	local treeGroup = private.status.ruleTreeGroup
	treeGroup:SetTree(private.GetTreeList(ruleGroup))
	treeGroup:SelectByPath("lists", newListName)
end

private.ListContainsItemID = function(ruleName, listName, itemID)
	ruleName = ruleName or private.status.ruleName
	listName = listName or private.status.listName

	return addon.db.global.rules[ruleName].lists[listName].itemIDs[itemID].enabled
end

private.ListExists = function(listName, ruleName)
	return addon.db.global.rules[ruleName].lists[listName].min
end

local function RenameList(ruleName, listName, newListName)
	ruleName = ruleName or private.status.ruleName
	listName = listName or private.status.listName
	local statusLabel = private.GetChild(private.status.ruleScrollFrame, "statusLabel")
	local treeGroup = private.status.ruleTreeGroup

	if not newListName or newListName == "" then
		return statusLabel:SetText(L["Missing rule name"])
	elseif listName == newListName then
		return
	elseif private.ListExists(newListName, ruleName) then
		return statusLabel:SetText(L.ListExists(newListName))
	end

	addon.db.global.rules[ruleName].lists[newListName] = addon.CloneTable(
		addon.db.global.rules[ruleName].lists[listName]
	)

	DeleteList(ruleName, listName)

	treeGroup:SetTree(private.GetTreeList())
	treeGroup:SelectByPath("lists", newListName)
end

-- Lists
local function addListEditBox_OnEnterPressed(addListEditBox, _, listName)
	private.AddList(private.status.ruleName, listName, addListEditBox)
	addListEditBox:ClearFocus()
end

local function minRestockEditBox_OnEnterPressed(minRestockEditBox, _, value)
	value = tonumber(value)
	local minRestock = value or 1

	addon.db.global.rules[private.status.ruleName].lists[private.status.listName].min = minRestock
	if minRestock ~= value then
		minRestockEditBox:SetText(minRestock)
	end

	minRestockEditBox:ClearFocus()
end

private.LoadListsContent = function()
	local addListLabel = AceGUI:Create("Label")
	addListLabel:SetUserData("elementName", "addListLabel")
	addListLabel:SetFullWidth(true)
	addListLabel:SetFontObject(GameFontNormal)
	addListLabel:SetColor(1, 0.82, 0)
	addListLabel:SetText(L["Add List"])

	local addListEditBox = AceGUI:Create("EditBox")
	addListEditBox:SetUserData("elementName", "addListEditBox")
	addListEditBox:DisableButton(true)
	addListEditBox:SetCallback("OnEnterPressed", addListEditBox_OnEnterPressed)

	local addListButton = AceGUI:Create("Button")
	addListButton:SetUserData("elementName", "addListButton")
	addListButton:SetText(L["Add"])
	addListButton:SetCallback("OnClick", function()
		addListEditBox_OnEnterPressed(addListEditBox, _, addListEditBox:GetText())
	end)

	local statusLabel = AceGUI:Create("Label")
	statusLabel:SetUserData("elementName", "statusLabel")
	statusLabel:SetFullWidth(true)
	statusLabel:SetColor(1, 0, 0)
	statusLabel:SetText()

	private.AddChildren(private.status.ruleScrollFrame, { addListLabel, addListEditBox, addListButton, statusLabel })
end

-- List

private.LoadList = function()
	local ruleName = private.status.ruleName
	local listInfo = addon.db.global.rules[ruleName].lists[private.status.listName]

	local listNameEditBox = AceGUI:Create("EditBox")
	listNameEditBox:SetUserData("elementName", "listNameEditBox")
	listNameEditBox:SetFullWidth(true)
	listNameEditBox:DisableButton(true)
	listNameEditBox:SetLabel(NAME)
	listNameEditBox:SetText(private.status.listName)
	listNameEditBox:SetCallback("OnEnterPressed", function(_, _, value)
		RenameList(ruleName, private.status.listName, value)
	end)

	local addItemIDEditBox = AceGUI:Create("EditBox")
	addItemIDEditBox:SetUserData("elementName", "addItemIDEditBox")
	addItemIDEditBox:SetRelativeWidth(1 / 2)
	addItemIDEditBox:SetLabel(L["Add ItemID"])
	addItemIDEditBox:DisableButton(true)
	addItemIDEditBox:SetCallback("OnEnterPressed", AddItemIDToList)

	local minRestockEditBox = AceGUI:Create("EditBox")
	minRestockEditBox:SetUserData("elementName", "minRestockEditBox")
	minRestockEditBox:SetRelativeWidth(1 / 2)
	minRestockEditBox:SetLabel(L["Minimum Restock"])
	minRestockEditBox:DisableButton(true)
	minRestockEditBox:SetText(listInfo.min or "")
	minRestockEditBox:SetCallback("OnEnterPressed", minRestockEditBox_OnEnterPressed)

	local itemIDScrollContainer = AceGUI:Create("SimpleGroup")
	itemIDScrollContainer:SetUserData("elementName", "itemIDScrollContainer")
	itemIDScrollContainer:SetUserData("children", {})
	itemIDScrollContainer:SetLayout("Fill")
	itemIDScrollContainer:SetHeight(400)
	itemIDScrollContainer:SetRelativeWidth(1 / 2)

	local itemIDScrollFrame = AceGUI:Create("ScrollFrame")
	itemIDScrollFrame:SetUserData("elementName", "itemIDScrollFrame")
	itemIDScrollFrame:SetUserData("children", {})
	itemIDScrollFrame:SetLayout("Flow")

	local guildSettingsScrollContainer = AceGUI:Create("SimpleGroup")
	guildSettingsScrollContainer:SetUserData("elementName", "guildSettingsScrollContainer")
	guildSettingsScrollContainer:SetUserData("children", {})
	guildSettingsScrollContainer:SetLayout("Fill")
	guildSettingsScrollContainer:SetHeight(400)
	guildSettingsScrollContainer:SetRelativeWidth(1 / 2)

	local guildSettingsScrollFrame = AceGUI:Create("ScrollFrame")
	guildSettingsScrollFrame:SetUserData("elementName", "guildSettingsScrollFrame")
	guildSettingsScrollFrame:SetUserData("children", {})
	guildSettingsScrollFrame:SetLayout("Flow")

	local duplicateListButton = AceGUI:Create("Button")
	duplicateListButton:SetUserData("elementName", "duplicateListButton")
	duplicateListButton:SetRelativeWidth(1 / 2)
	duplicateListButton:SetText(L["Duplicate"])
	duplicateListButton:SetCallback("OnClick", function()
		DuplicateList()
	end)

	local deleteListButton = AceGUI:Create("Button")
	deleteListButton:SetUserData("elementName", "deleteListButton")
	deleteListButton:SetRelativeWidth(1 / 2)
	deleteListButton:SetText(DELETE)
	deleteListButton:SetCallback("OnClick", function()
		ConfirmDeleteList()
	end)

	local statusLabel = AceGUI:Create("Label")
	statusLabel:SetUserData("elementName", "statusLabel")
	statusLabel:SetFullWidth(true)
	statusLabel:SetColor(1, 0, 0)
	statusLabel:SetText(" ")

	private.AddChildren(private.status.ruleScrollFrame, {
		listNameEditBox,
		addItemIDEditBox,
		minRestockEditBox,
		itemIDScrollContainer,
		guildSettingsScrollContainer,
		statusLabel,
		duplicateListButton,
		deleteListButton,
	})
	private.AddChildren(itemIDScrollContainer, { itemIDScrollFrame })
	private.AddChildren(guildSettingsScrollContainer, { guildSettingsScrollFrame })

	private.LoadItemIDList()
end
