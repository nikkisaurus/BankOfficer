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
	local statusLabel = private.status.listStatusLabel

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
			return statusLabel:SetText(L["Cannot add soulbound item to list rule"])
		elseif private.ListContainsItemID(ruleName, listName, itemID) then
			addItemIDEditBox:HighlightText()
			return statusLabel:SetText(L["ItemID exists in list rule"])
		end

		addon.db.global.rules[ruleName].lists[listName].itemIDs[itemID] = true
		addItemIDEditBox:SetText("")
		addItemIDEditBox:ClearFocus()
	end, ruleName, listName, itemID, statusLabel)
end

private.AddList = function(ruleName, listName)
	local ruleName = ruleName or private.status.ruleName
	local listName = listName or private.status.listName
	local statusLabel = private.status.listStatusLabel

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
	listName = listName or private.status.listName
	ruleName = ruleName or private.status.ruleName
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

	return addon.db.global.rules[ruleName].lists[listName].itemIDs[itemID]
end

private.ListExists = function(listName, ruleName)
	return addon.db.global.rules[ruleName].lists[listName].min
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
	private.status.listStatusLabel = statusLabel

	private.AddChildren(private.status.ruleScrollFrame, { addListLabel, addListEditBox, addListButton, statusLabel })
end

-- List
local function LoadListItemIDs()
	--itemIDScrollFrame
	--local listScrollContainer = AceGUI:Create("SimpleGroup")
	--listScrollContainer:SetUserData("elementName", "listScrollContainer")
	--listScrollContainer:SetUserData("children", {})
	--listScrollContainer:SetFullWidth(true)
	--listScrollContainer:SetFullHeight(true)
	--listScrollContainer:SetLayout("Fill")
	--private.AddChildren(private.GetChild(scrollFrame, "listTabGroup"), { listScrollContainer })

	--local listScrollFrame = AceGUI:Create("ScrollFrame")
	--listScrollFrame:SetUserData("elementName", "listScrollFrame")
	--listScrollFrame:SetUserData("children", {})
	--listScrollFrame:SetLayout("Fill")
	--private.AddChildren(listScrollContainer, { listScrollFrame })
end

private.LoadList = function(e)
	local ruleName = private.status.ruleName
	local listInfo = addon.db.global.rules[ruleName].lists[private.status.listName]

	local minRestockEditBox = AceGUI:Create("EditBox")
	minRestockEditBox:SetUserData("elementName", "minRestockEditBox")
	minRestockEditBox:SetRelativeWidth(1 / 3)
	minRestockEditBox:SetLabel(L["Minimum Restock"])
	minRestockEditBox:DisableButton(true)
	minRestockEditBox:SetText(listInfo.min or "")
	minRestockEditBox:SetCallback("OnEnterPressed", minRestockEditBox_OnEnterPressed)

	local duplicateListButton = AceGUI:Create("Button")
	duplicateListButton:SetUserData("elementName", "duplicateListButton")
	duplicateListButton:SetRelativeWidth(1 / 3)
	duplicateListButton:SetText(L["Duplicate"])
	duplicateListButton:SetCallback("OnClick", DuplicateList)

	local deleteListButton = AceGUI:Create("Button")
	deleteListButton:SetUserData("elementName", "deleteListButton")
	deleteListButton:SetRelativeWidth(1 / 3)
	deleteListButton:SetText(DELETE)
	deleteListButton:SetCallback("OnClick", ConfirmDeleteList)

	local addItemIDEditBox = AceGUI:Create("EditBox")
	addItemIDEditBox:SetUserData("elementName", "addItemIDEditBox")
	addItemIDEditBox:SetRelativeWidth(1 / 2)
	addItemIDEditBox:SetLabel(L["Add ItemID"])
	addItemIDEditBox:DisableButton(true)
	addItemIDEditBox:SetCallback("OnEnterPressed", AddItemIDToList)

	local itemIDScrollContainer = AceGUI:Create("SimpleGroup")
	itemIDScrollContainer:SetUserData("elementName", "itemIDScrollContainer")
	itemIDScrollContainer:SetUserData("children", {})
	itemIDScrollContainer:SetLayout("Fill")
	itemIDScrollContainer:SetHeight(200)
	itemIDScrollContainer:SetRelativeWidth(1 / 2)

	local itemIDScrollFrame = AceGUI:Create("ScrollFrame")
	itemIDScrollFrame:SetUserData("elementName", "itemIDScrollFrame")
	itemIDScrollFrame:SetUserData("children", {})
	itemIDScrollFrame:SetLayout("Flow")

	local addGuildDropdown = AceGUI:Create("Dropdown")
	addGuildDropdown:SetUserData("elementName", "addGuildDropdown")
	addGuildDropdown:SetRelativeWidth(1 / 2)
	addGuildDropdown:SetLabel(L["Apply list rule to guilds"])
	addGuildDropdown:SetList(private.GetGuildList())
	addGuildDropdown:SetMultiselect(true)
	addGuildDropdown:SetCallback("OnValueChanged", addGuildDropdown_OnValueChanged)

	local addGuildScrollContainer = AceGUI:Create("SimpleGroup")
	addGuildScrollContainer:SetUserData("elementName", "addGuildScrollContainer")
	addGuildScrollContainer:SetUserData("children", {})
	addGuildScrollContainer:SetLayout("Fill")
	addGuildScrollContainer:SetHeight(200)
	addGuildScrollContainer:SetRelativeWidth(1 / 2)

	local addGuildScrollFrame = AceGUI:Create("ScrollFrame")
	addGuildScrollFrame:SetUserData("elementName", "addGuildScrollFrame")
	addGuildScrollFrame:SetUserData("children", {})
	addGuildScrollFrame:SetLayout("Flow")

	local statusLabel = AceGUI:Create("Label")
	statusLabel:SetUserData("elementName", "statusLabel")
	statusLabel:SetFullWidth(true)
	statusLabel:SetColor(1, 0, 0)
	statusLabel:SetText(" ")
	private.status.listStatusLabel = statusLabel

	private.AddChildren(private.status.ruleScrollFrame, {
		minRestockEditBox,
		duplicateListButton,
		deleteListButton,
		addItemIDEditBox,
		addGuildDropdown,
		itemIDScrollContainer,
		addGuildScrollContainer,
		statusLabel,
	})
	private.AddChildren(itemIDScrollContainer, { itemIDScrollFrame })
	private.AddChildren(addGuildScrollContainer, { addGuildScrollFrame })

	LoadListItemIDs()
end
