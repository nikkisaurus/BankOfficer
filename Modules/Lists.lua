local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

-- Database
local function AddList(addListButton)
	local scrollFrame = addListButton.parent
	local scrollChildren = scrollFrame:GetUserData("children")
	local ruleGroup = scrollFrame.parent.parent.parent
	local ruleName = ruleGroup:GetUserData("selectedRule")

	local listName = scrollChildren["addListEditBox"]:GetText()
	local statusLabel = scrollChildren["statusLabel"]

	if not listName or listName == "" then
		return statusLabel:SetText(L["Missing list name"])
	elseif private.ListExists(listName, ruleName) then
		return statusLabel:SetText(L.ListExists(listName))
	end

	addon.db.global.rules[ruleName].lists[listName].min = 1
	local treeGroup = scrollFrame.parent.parent
	treeGroup:SetTree(private.GetTreeList(ruleGroup))
	treeGroup:SelectByPath("lists", listName)
end

local function DeleteList(treeGroup, ruleName, listName)
	wipe(addon.db.global.rules[ruleName].lists[listName])
	treeGroup:SetTree(private.GetTreeList(treeGroup.parent))
	treeGroup:SelectByPath("lists")
end

local function ConfirmDeleteList(scrollFrame, listName)
	local treeGroup = scrollFrame.parent.parent
	local ruleName = treeGroup.parent:GetUserData("selectedRule")

	private.CreateCoroutine(function()
		private.RequestConfirmation(L.DeleteList(ruleName, listName))

		local confirmed = coroutine.yield()
		if not confirmed then
			return
		end

		DeleteList(treeGroup, ruleName, listName)
	end)

	coroutine.resume(private.co)
end

local function DuplicateList(scrollFrame, listName)
	local ruleGroup = scrollFrame.parent.parent.parent
	local ruleName = ruleGroup:GetUserData("selectedRule")
	local newListName = addon.EnumerateString(listName, private.ListExists, ruleName)

	addon.db.global.rules[ruleName].lists[newListName] = addon.CloneTable(
		addon.db.global.rules[ruleName].lists[listName]
	)

	local treeGroup = private.GetChild(ruleGroup, "treeGroup")
	treeGroup:SetTree(private.GetTreeList(ruleGroup))
	treeGroup:SelectByPath("lists", newListName)
end

private.ListExists = function(listName, ruleName)
	return addon.db.global.rules[ruleName].lists[listName].min
end

-- Lists
local function addListEditBox_OnEnterPressed(addListEditBox)
	AddList(addListEditBox)
	addListEditBox:ClearFocus()
end

private.LoadListsContent = function(scrollFrame)
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
	addListButton:SetCallback("OnClick", AddList)

	local statusLabel = AceGUI:Create("Label")
	statusLabel:SetUserData("elementName", "statusLabel")
	statusLabel:SetFullWidth(true)
	statusLabel:SetColor(1, 0, 0)
	statusLabel:SetText()

	private.AddChildren(scrollFrame, { addListLabel, addListEditBox, addListButton, statusLabel })
end

-- List
private.LoadList = function(scrollFrame, listName)
	local duplicateListButton = AceGUI:Create("Button")
	duplicateListButton:SetUserData("elementName", "duplicateListButton")
	duplicateListButton:SetText(L["Duplicate"])
	duplicateListButton:SetCallback("OnClick", function()
		DuplicateList(scrollFrame, listName)
	end)

	local deleteListButton = AceGUI:Create("Button")
	deleteListButton:SetUserData("elementName", "deleteListButton")
	deleteListButton:SetText(DELETE)
	deleteListButton:SetCallback("OnClick", function()
		ConfirmDeleteList(scrollFrame, listName)
	end)

	private.AddChildren(scrollFrame, { duplicateListButton, deleteListButton })
end
