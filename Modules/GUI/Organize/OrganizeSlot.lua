local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

--[[ Menus ]]
local function GetEasyMenu(slot, itemInfo, isEmpty)
	local menu
	if isEmpty then
		menu = {
			{
				text = L["Edit Slot"],
				func = function()
					private:EditOrganizeSlot(slot, itemInfo, isEmpty)
				end,
			},
		}
	else
		BankOfficer.CacheItem(itemInfo.itemID, function(private, slot, itemInfo)
			local itemName = GetItemInfo(itemInfo.itemID)

			menu = {

				{ text = itemName, isTitle = true, notCheckable = true },
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
		end, private, slot, itemInfo)
	end

	return menu
end

--[[ Script handlers ]]
function private.OrganizeSlot_OnClick(slot, _, mouseButton, ...)
	local itemInfo = private.db.global.organize[private.status.guildKey][private.status.tab][slot:GetUserData("slotID")]
	local isEmpty = not itemInfo or not itemInfo.itemID

	if mouseButton == "LeftButton" then
		local cursorType, itemID = GetCursorInfo()
		if private.status.editMode == "clear" then
			private:ClearOrganizeSlot(slot)
		elseif cursorType == "item" then
			private.OrganizeSlot_OnReceiveDrag(slot.frame, "OnReceiveDrag", mouseButton, ...)
		elseif not isEmpty then
			private:PickupOrganizeSlotItem(slot, itemInfo.itemID)
		end
	elseif mouseButton == "RightButton" then
		EasyMenu(GetEasyMenu(slot, itemInfo, isEmpty), private.organizeContextMenu, slot.frame, 0, 0, "MENU")
	end
end

function private.OrganizeSlot_OnDragStart(slot)
	slot = slot.obj
	local itemInfo = private.db.global.organize[private.status.guildKey][private.status.tab][slot:GetUserData("slotID")]
	local isEmpty = not itemInfo or not itemInfo.itemID
	if isEmpty then
		return
	end

	private:PickupOrganizeSlotItem(slot, itemInfo.itemID)
end

function private.OrganizeSlot_OnReceiveDrag(slot)
	slot = slot.obj
	local itemInfo = private.db.global.organize[private.status.guildKey][private.status.tab][slot:GetUserData("slotID")]
	local isEmpty = not itemInfo or not itemInfo.itemID

	local cursorType, itemID = GetCursorInfo()
	if private.status.editMode ~= "duplicate" then
		ClearCursor()
	end

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
	private.status.clearSlot = nil
	private.db.global.organize[private.status.guildKey][private.status.tab][slot:GetUserData("slotID")] = nil
	private:LoadOrganizeSlotItem(slot)
end

function private:EditOrganizeSlot(slot, itemInfo, isEmpty)
	local parent = slot.parent.parent

	if isEmpty then
	else
		private:CacheItem(itemInfo.itemID, function()
			print(GetItemInfo(itemInfo.itemID))
		end)
		--BankOfficer.CacheItem(itemInfo.itemID, function(private, editSlotGroup, slot, itemInfo)
		--	local itemName = GetItemInfo(itemInfo.itemID)

		--	local name = AceGUI:Create("Label")
		--	name:SetFullWidth(true)
		--	name:SetText(itemName)
		--	name:SetImage(GetItemIcon(itemInfo.itemID))
		--	name:SetImageSize(24, 24)
		--	name:SetFontObject(GameFontNormal)

		--	local itemID = AceGUI:Create("EditBox")
		--	itemID:SetText(tostring(itemInfo.itemID))
		--	itemID:SetLabel(L["Item ID"])
		--	itemID:SetCallback("OnEnterPressed", function(self, _, value)
		--		local newItemID = tonumber(value)
		--		if not newItemID or newItemID == 0 then
		--			return
		--		end

		--		local _, _, _, _, _, _, _, _, _, _, _, _, _, bindType = GetItemInfo(newItemID)
		--		if bindType ~= 1 then
		--			private:SaveOrganizeSlotItem(slot, newItemID)
		--			editSlotGroup:ReleaseChildren()
		--			itemInfo.itemID = newItemID
		--			private:EditOrganizeSlot(slot, itemInfo)
		--			editSlotGroup.parent:DoLayout()
		--		end
		--	end)

		--	editSlotGroup:AddChildren(name, itemID)
		--end, private, editSlotGroup, slot, itemInfo)
	end
end

function private:LoadOrganizeSlotItem(slot)
	local itemInfo = private.db.global.organize[private.status.guildKey][private.status.tab][slot:GetUserData("slotID")]
	local isEmpty = not itemInfo or not itemInfo.itemID
	slot:SetImage(isEmpty and self.media .. [[UI-SLOT-BACKGROUND]] or GetItemIcon(itemInfo.itemID))
end

function private:PickupOrganizeSlotItem(slot, itemID, duplicate)
	if not itemID then
		return
	end

	PickupItem(itemID)

	local isDuplicate = private.status.editMode == "duplicate" or duplicate
	slot.image:SetDesaturated(not isDuplicate)
	private.status.clearSlot = not isDuplicate and slot
end

function private:SaveOrganizeSlotItem(slot, itemID)
	local db = private.db.global.organize[private.status.guildKey][private.status.tab]
	local slotID = slot:GetUserData("slotID")

	db[slotID] = {
		itemID = itemID,
	}

	private:LoadOrganizeSlotItem(slot)
	slot.image:SetDesaturated(false)
end
