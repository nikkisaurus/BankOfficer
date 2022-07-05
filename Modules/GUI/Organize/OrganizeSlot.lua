local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

--[[ Locals ]]
-- Menus
local function GetEasyMenu(slot)
	local itemInfo =
		private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab][slot:GetUserData(
			"slotID"
		)]
	local isEmpty = not itemInfo or not itemInfo.itemID

	if isEmpty then
		return {
			{
				text = L["Edit Slot"],
				func = function()
					private:EditOrganizeSlot(slot, itemInfo, isEmpty)
				end,
			},
		}
	else
		local menu = {
			{ text = "", isTitle = true, notCheckable = true },
			{
				text = L["Edit Slot"],
				func = function()
					private:EditOrganizeSlot(slot, itemInfo)
				end,
			},
			{
				text = L["Duplicate Slot"],
				func = function()
					private:PickupOrganizeSlotItem(slot, itemInfo.itemID, true)
				end,
			},
			{
				text = L["Clear Slot"],
				func = function()
					private:ClearOrganizeSlot(slot)
				end,
			},
		}

		BankOfficer.CacheItem(itemInfo.itemID, function(menu, itemID)
			menu[1].text = (GetItemInfo(itemID))
		end, menu, itemInfo.itemID)

		return menu
	end
end

--[[ Script handlers ]]
function private.OrganizeSlot_OnClick(slot, _, mouseButton, ...)
	local itemInfo =
		private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab][slot:GetUserData(
			"slotID"
		)]
	local isEmpty = not itemInfo or not itemInfo.itemID

	if mouseButton == "LeftButton" then
		local cursorType, itemID = GetCursorInfo()
		if private.status.organize.editMode == "clear" then
			private:ClearOrganizeSlot(slot)
		elseif cursorType == "item" then
			private.OrganizeSlot_OnReceiveDrag(slot.frame, "OnReceiveDrag", mouseButton, ...)
		elseif not isEmpty then
			private:PickupOrganizeSlotItem(slot, itemInfo.itemID)
		end
	elseif mouseButton == "RightButton" then
		EasyMenu(GetEasyMenu(slot), private.organizeContextMenu, slot.frame, 0, 0, "MENU")
	end
end

function private.OrganizeSlot_OnDragStart(slot)
	slot = slot.obj
	local itemInfo =
		private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab][slot:GetUserData(
			"slotID"
		)]
	local isEmpty = not itemInfo or not itemInfo.itemID
	if isEmpty then
		return
	end

	private:PickupOrganizeSlotItem(slot, itemInfo.itemID)
end

function private.OrganizeSlot_OnReceiveDrag(slot)
	slot = slot.obj
	local itemInfo =
		private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab][slot:GetUserData(
			"slotID"
		)]
	local isEmpty = not itemInfo or not itemInfo.itemID

	local cursorType, itemID = GetCursorInfo()
	if private.status.organize.editMode ~= "duplicate" then
		ClearCursor()
	end

	if cursorType == "item" then
		local _, _, _, _, _, _, _, _, _, _, _, _, _, bindType = GetItemInfo(itemID)

		if bindType ~= 1 then
			if private.status.organize.clearSlot then
				if not isEmpty then
					private:SaveOrganizeSlotItem(private.status.organize.clearSlot, itemInfo.itemID)
					private.status.organize.clearSlot = nil
				else
					private:ClearOrganizeSlot(private.status.organize.clearSlot)
				end
			end
			private:SaveOrganizeSlotItem(slot, itemID)
		end
	end
end

function private.OrganizeSlot_OnDragStop(slot)
	slot = slot.obj
	if not slot then
		return
	end
	slot.image:SetDesaturated(false)
end

--[[ Private ]]
function private:ClearOrganizeSlot(slot)
	if not slot then
		return
	end
	private.OrganizeSlot_OnDragStop(slot)
	private.status.organize.clearSlot = nil
	private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab][slot:GetUserData("slotID")] =
		nil
	private:LoadOrganizeSlotItem(slot)
end

function private:EditOrganizeSlot(slot, itemInfo, isEmpty)
	if isEmpty then
	else
	end
end

function private:LoadOrganizeSlotItem(slot)
	if not private.status.organize.guildKey or not private.status.organize.tab then
		return
	end

	local itemInfo =
		private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab][slot:GetUserData(
			"slotID"
		)]
	local isEmpty = not itemInfo or not itemInfo.itemID
	--slot:SetNormalTexture(isEmpty and self.media .. [[UI-SLOT-BACKGROUND]] or GetItemIcon(itemInfo.itemID))
	--slot:SetText(isEmpty and "" or itemInfo.stack)
end

function private:PickupOrganizeSlotItem(slot, itemID, duplicate)
	if not itemID then
		return
	end

	PickupItem(itemID)

	local isDuplicate = private.status.organize.editMode == "duplicate" or duplicate
	slot.image:SetDesaturated(not isDuplicate)
	private.status.organize.clearSlot = not isDuplicate and slot
end

function private:SaveOrganizeSlotItem(slot, itemID)
	local db = private.db.global.organize[private.status.organize.guildKey][private.status.organize.tab]
	local slotID = slot:GetUserData("slotID")

	db[slotID] = {
		itemID = itemID,
		stack = [[function()\n    return 1\nend]],
	}

	private:LoadOrganizeSlotItem(slot)
	slot.image:SetDesaturated(false)
end
