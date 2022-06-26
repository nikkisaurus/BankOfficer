local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

--[[ Script handlers ]]
function private.OrganizeSlot_OnClick(slot, _, mouseButton, ...)
	if mouseButton == "LeftButton" then
		private.OrganizeSlot_OnReceiveDrag(slot.frame, "OnReceiveDrag", mouseButton, ...)
	elseif mouseButton == "RightButton" then
		print("open context menu")
	end
end

function private.OrganizeSlot_OnDragStart(slot)
	slot = slot.obj
	local itemInfo = private.db.global.organize[private.status.guildKey][private.status.tab][slot:GetUserData("slotID")]
	local isEmpty = not itemInfo or not itemInfo.itemID
	if isEmpty then
		return
	end

	PickupItem(itemInfo.itemID)
	slot.image:SetDesaturated(true)

	if IsControlKeyDown() and not IsAltKeyDown() and not IsShiftKeyDown() then
		return
	end

	private.status.clearSlot = slot
end

function private.OrganizeSlot_OnReceiveDrag(slot)
	slot = slot.obj
	local itemInfo = private.db.global.organize[private.status.guildKey][private.status.tab][slot:GetUserData("slotID")]
	local isEmpty = not itemInfo or not itemInfo.itemID

	local cursorType, itemID = GetCursorInfo()
	ClearCursor()

	if cursorType == "item" then
		local _, _, _, _, _, _, _, _, _, _, _, _, _, bindType = GetItemInfo(itemID)

		if bindType ~= 1 then
			if private.status.clearSlot then
				if not isEmpty then
					private:SaveOrganizeSlotItem(private.status.clearSlot, itemInfo.itemID)
					private.status.clearSlot = nil
				else
					private:ClearOrganizeSlot(private.status.clearSlot)
				end
			end
			private:SaveOrganizeSlotItem(slot, itemID)
		end
	end
end

function private.OrganizeSlot_OnDragStop(slot)
	slot = slot.obj
	slot.image:SetDesaturated(false)
end

--[[ Private ]]
function private:ClearOrganizeSlot(slot)
	if not slot then
		return
	end
	private.status.clearSlot = nil
	private.db.global.organize[private.status.guildKey][private.status.tab][slot:GetUserData("slotID")] = nil
	private:LoadOrganizeSlotItem(slot)
end

function private:LoadOrganizeSlotItem(slot)
	local itemInfo = private.db.global.organize[private.status.guildKey][private.status.tab][slot:GetUserData("slotID")]
	local isEmpty = not itemInfo or not itemInfo.itemID
	slot:SetImage(isEmpty and [[INTERFACE/ADDONS/BANKOFFICER/MEDIA/UI-SLOT-BACKGROUND]] or GetItemIcon(itemInfo.itemID))
end

function private:SaveOrganizeSlotItem(slot, itemID)
	local db = private.db.global.organize[private.status.guildKey][private.status.tab]
	local slotID = slot:GetUserData("slotID")

	db[slotID] = {
		itemID = itemID,
	}

	private:LoadOrganizeSlotItem(slot)
end
