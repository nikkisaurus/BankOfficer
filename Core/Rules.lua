local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

-- Lists
local RULE_TYPES = {
	tab = L["Tab"],
	list = L["List"],
}

local function GetRules()
	local rules = {}

	for ruleName, rule in pairs(addon.db.global.rules) do
		if rule.type then
			rules[ruleName] = ruleName
		end
	end

	rules["__new"] = L["Add Rule"]

	return rules
end

local function GetTreeList()
	local list = {
		{
			value = "settings",
			text = SETTINGS,
		},
	}

	--TODO Add tabs based on type

	return list
end

-- Database

local function DeleteRule(ruleGroup, ruleName)
	wipe(addon.db.global.rules[ruleName])
	ruleGroup:SetGroupList(GetRules())
	ruleGroup:SetGroup()
	ruleGroup:ReleaseChildren()
end

local function ConfirmDeleteRule(deleteRuleButton)
	local ruleGroup = deleteRuleButton.parent.parent
	local ruleName = ruleGroup.dropdown:GetValue()

	private.CreateCoroutine(function()
		private.RequestConfirmation(L.DeleteRule(ruleName))

		local confirmed = coroutine.yield()
		if not confirmed then
			return
		end

		DeleteRule(ruleGroup, ruleName)
	end)

	coroutine.resume(private.co)
end

local function RenameRule(ruleNameEditBox)
	local ruleGroup = ruleNameEditBox.parent.parent
	local ruleName = ruleGroup.dropdown:GetValue()
	local newRuleName = ruleNameEditBox:GetText()
	local statusLabel = private.GetChild(ruleNameEditBox.parent, "statusLabel")

	if not newRuleName or newRuleName == "" then
		return statusLabel:SetText(L["Missing rule name"])
	elseif ruleName == newRuleName then
		return
	elseif private.RuleExists(newRuleName) then
		return statusLabel:SetText(L.RuleExists(ruleName))
	elseif newRuleName == "__new" then
		return statusLabel:SetText(L["Invalid rule name"])
	end

	addon.db.global.rules[newRuleName] = addon:CloneTable(addon.db.global.rules[ruleName])
	DeleteRule(ruleGroup, ruleName)
	ruleGroup:SetGroupList(GetRules())
	ruleGroup:SetGroup(newRuleName)
end

private.RuleExists = function(ruleName)
	return addon.db.global.rules[ruleName].type
end

local function SaveRule(saveButton)
	local ruleGroup = saveButton.parent
	local ruleNameEditBox = private.GetChild(ruleGroup, "ruleNameEditBox")
	local ruleName = ruleNameEditBox:GetText()
	local ruleTypeDropdown = private.GetChild(ruleGroup, "ruleTypeDropdown")
	local statusLabel = private.GetChild(ruleGroup, "statusLabel")

	if not ruleName or ruleName == "" then
		return statusLabel:SetText(L["Missing rule name"])
	elseif private.RuleExists(ruleName) then
		return statusLabel:SetText(L.RuleExists(ruleName))
	elseif ruleName == "__new" then
		return statusLabel:SetText(L["Invalid rule name"])
	end

	addon.db.global.rules[ruleName].type = ruleTypeDropdown:GetValue()
	ruleGroup:SetGroupList(GetRules())
	ruleGroup:SetGroup(ruleName)
end

local function UpdateRule(ruleName, key, value)
	addon.db.global.rules[ruleName][key] = value
	--TODO Refresh tree list
end

-- AddRuleContent
local function ruleNameEditBox_OnEnterPressed(ruleNameEditBox)
	ruleNameEditBox:ClearFocus()
end

local function AddRuleContent(ruleGroup)
	ruleGroup:SetLayout("Flow")
	local ruleNameEditBox = AceGUI:Create("EditBox")
	ruleNameEditBox:SetUserData("elementName", "ruleNameEditBox")
	ruleNameEditBox:SetLabel(NAME)
	ruleNameEditBox:DisableButton(true)
	ruleNameEditBox:SetCallback("OnEnterPressed", ruleNameEditBox_OnEnterPressed)

	local ruleTypeDropdown = AceGUI:Create("Dropdown")
	ruleTypeDropdown:SetUserData("elementName", "ruleTypeDropdown")
	ruleTypeDropdown:SetList(RULE_TYPES)
	ruleTypeDropdown:SetLabel(TYPE)
	ruleTypeDropdown:SetValue("list")

	local saveButton = AceGUI:Create("Button")
	saveButton:SetUserData("elementName", "saveButton")
	saveButton:SetText(ADD)
	saveButton:SetCallback("OnClick", SaveRule)

	local statusLabel = AceGUI:Create("Label")
	statusLabel:SetUserData("elementName", "statusLabel")
	statusLabel:SetFullWidth(true)
	statusLabel:SetColor(1, 0, 0)
	statusLabel:SetText()

	private.AddChildren(ruleGroup, { ruleNameEditBox, ruleTypeDropdown, saveButton, statusLabel })
end

-- RuleContent
local function treeGroup_OnGroupSelected(treeGroup)
	local ruleGroup = treeGroup.parent
	local ruleName = ruleGroup.dropdown:GetValue()
	local rule = addon.db.global.rules[ruleName]

	if not rule or not rule.type then
		return
	end

	local ruleNameEditBox = AceGUI:Create("EditBox")
	ruleNameEditBox:SetUserData("elementName", "ruleNameEditBox")
	ruleNameEditBox:SetText(ruleName)
	ruleNameEditBox:SetLabel(NAME)
	ruleNameEditBox:DisableButton(true)
	ruleNameEditBox:SetCallback("OnEnterPressed", RenameRule)

	local ruleTypeDropdown = AceGUI:Create("Dropdown")
	ruleTypeDropdown:SetUserData("elementName", "ruleTypeDropdown")
	ruleTypeDropdown:SetList(RULE_TYPES)
	ruleTypeDropdown:SetLabel(TYPE)
	ruleTypeDropdown:SetValue(rule.type)
	ruleTypeDropdown:SetCallback("OnValueChanged", function(_, _, ruleType)
		UpdateRule(ruleName, "type", ruleType)
	end)

	local deleteRuleButton = AceGUI:Create("Button")
	deleteRuleButton:SetUserData("elementName", "deleteRuleButton")
	deleteRuleButton:SetText(DELETE)
	deleteRuleButton:SetCallback("OnClick", ConfirmDeleteRule)

	local statusLabel = AceGUI:Create("Label")
	statusLabel:SetUserData("elementName", "statusLabel")
	statusLabel:SetFullWidth(true)
	statusLabel:SetColor(1, 0, 0)
	statusLabel:SetText()

	private.AddChildren(treeGroup, { ruleNameEditBox, ruleTypeDropdown, deleteRuleButton, statusLabel })
end

local function RuleContent(ruleGroup)
	ruleGroup:SetLayout("Fill")

	local treeGroup = AceGUI:Create("TreeGroup")
	treeGroup:SetUserData("elementName", "treeGroup")
	treeGroup:SetUserData("children", {})
	treeGroup:SetLayout("Flow")
	treeGroup:SetTree(GetTreeList())
	treeGroup:SetCallback("OnGroupSelected", treeGroup_OnGroupSelected)
	private.AddChildren(ruleGroup, { treeGroup })
	treeGroup:SelectByPath("settings")
end

-- Load
local function SelectRule(ruleGroup, _, rule)
	ruleGroup:ReleaseChildren()

	if rule == "__new" then
		AddRuleContent(ruleGroup)
	else
		RuleContent(ruleGroup)
	end
end

private.LoadRules = function(tabGroup)
	tabGroup:SetLayout("Fill")
	local ruleGroup = AceGUI:Create("DropdownGroup")
	ruleGroup:SetUserData("children", {})
	ruleGroup:SetGroupList(GetRules())
	ruleGroup:SetCallback("OnGroupSelected", SelectRule)
	return ruleGroup
end
