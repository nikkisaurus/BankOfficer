local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = private.L

function private:ValidateItem(itemID)
	local _, itemLink = GetItemInfo(itemID)
	if itemLink then
		local itemString = select(3, strfind(itemLink, "|H(.+)|h"))
		local _, itemId = strsplit(":", itemString)
		return tonumber(itemId)
	end
end
