local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

-- Lists
local function GetScans()
	local scans = {}
	local order = {}

	for scanID, scan in addon.pairs(addon.db.global.scans) do
		if scan.type then
			scans[scanID] = date(addon.db.global.settings.dateFormat, scanID)
			tinsert(order, scanID)
		end
	end

	return scans, order
end

-- Database
local function DeleteScan()
	wipe(addon.db.global.scans[private.status.scanID])

	local scanGroup = private.status.scanGroup
	scanGroup:SetGroupList(GetScans())
	scanGroup:SetGroup()
	private.status.scanScrollFrame:ReleaseChildren()

	if addon.tcount(addon.db.global.scans, _, "type") == 0 then
		private.scanFrame:Hide()
	end
end

local function ConfirmDeleteScan()
	private.CreateCoroutine(function()
		private.RequestConfirmation(L.DeleteScan(private.status.scanID))

		if not coroutine.yield() then
			return
		end

		DeleteScan()
	end)

	coroutine.resume(private.co)
end

-- LoadListScan
local function CreateItemLabel(itemLabels, itemID, restock, numRestocks)
	local itemName, itemLink = GetItemInfo(itemID)
	itemLabels[itemName] = { itemID = itemID, itemLink = itemLink, restock = restock }

	if addon.tcount(itemLabels) == numRestocks then
		for _, itemInfo in addon.pairs(itemLabels) do
			local itemLabel = AceGUI:Create("InteractiveLabel")
			itemLabel:SetUserData("elementName", "itemLabel" .. itemInfo.itemID)
			itemLabel:SetFullWidth(true)
			itemLabel:SetText(format("%dx %s", itemInfo.restock, itemInfo.itemLink))
			itemLabel:SetCallback("OnEnter", function()
				private.ShowHyperlinkTip(itemInfo.itemLink, itemLabel.frame, "ANCHOR_LEFT")
			end)
			itemLabel:SetCallback("OnLeave", function()
				private.HideTooltip()
			end)
			private.AddChildren(private.status.scanScrollFrame, { itemLabel })
		end
	end
end

local function LoadListScan()
	local scrollFrame = private.status.scanScrollFrame

	local spacer = AceGUI:Create("Label")
	spacer:SetUserData("elementName", "spacer")
	spacer:SetText(" ")
	spacer:SetFullWidth(true)

	-- TODO: verify user has TSM
	local exportTSMButton = AceGUI:Create("Button")
	exportTSMButton:SetUserData("elementName", "exportTSMButton")
	exportTSMButton:SetText("Export to TSM") --TODO: localize
	exportTSMButton:SetCallback("OnClick", function()
		print("export")
	end)

	private.AddChildren(scrollFrame, { spacer, exportTSMButton })
end

-- Load
local itemLabels = {}
local function SelectScan(_, _, scanID)
	local scrollFrame = private.status.scanScrollFrame
	private.status.scanID = scanID

	scrollFrame:ReleaseChildren()
	if not scanID then
		return
	end

	local scanType = addon.db.global.scans[scanID].type
	if scanType == "list" then
		wipe(itemLabels)
		local restocks = addon.db.global.scans[private.status.scanID].restocks
		local numRestocks = addon.tcount(restocks)
		for itemID, restock in pairs(restocks) do
			addon.CacheItem(itemID, CreateItemLabel, itemLabels, itemID, restock, numRestocks, private)
		end
		LoadListScan()
	elseif scanType == "tab" then
	end

	local deleteScanButton = AceGUI:Create("Button")
	deleteScanButton:SetUserData("elementName", "deleteScanButton")
	deleteScanButton:SetText(DELETE)
	deleteScanButton:SetCallback("OnClick", function()
		ConfirmDeleteScan()
	end)

	private.AddChildren(scrollFrame, { deleteScanButton })
end

private.LoadScanFrame = function(scanID)
	if addon.tcount(addon.db.global.scans, _, "type") == 0 then
		return
	end

	private.scanFrame:Show()

	local scanGroup = private.status.scanGroup
	scanGroup:SetGroupList(GetScans())
	scanGroup:SetGroup(scanID or private.status.scanID)
end

-- Initialize
private.InitializeScanFrame = function()
	local frame = AceGUI:Create("Window")
	frame:SetUserData("children", {})
	frame:SetTitle(format("%s %s", L[addonName], L["Scan Frame"]))
	frame:SetLayout("Fill")
	frame:SetWidth(700)
	frame:SetHeight(700)
	frame:Hide()
	private.scanFrame = frame
	_G["BankOfficerScanFrame"] = frame.frame
	tinsert(UISpecialFrames, "BankOfficerScanFrame")

	local scanGroup = AceGUI:Create("DropdownGroup")
	scanGroup:SetUserData("elementName", "scanGroup")
	scanGroup:SetUserData("children", {})
	scanGroup:SetLayout("Fill")
	scanGroup:SetCallback("OnGroupSelected", SelectScan)
	private.status.scanGroup = scanGroup
	private.AddChildren(frame, { scanGroup })

	local scrollContainer = AceGUI:Create("SimpleGroup")
	scrollContainer:SetUserData("elementName", "scrollContainer")
	scrollContainer:SetUserData("children", {})
	scrollContainer:SetFullWidth(true)
	scrollContainer:SetFullHeight(true)
	scrollContainer:SetLayout("Fill")
	private.AddChildren(scanGroup, { scrollContainer })

	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetUserData("elementName", "scrollFrame")
	scrollFrame:SetUserData("children", {})
	scrollFrame:SetLayout("Flow")
	private.status.scanScrollFrame = scrollFrame
	private.AddChildren(scrollContainer, { scrollFrame })
end
