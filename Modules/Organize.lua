local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

function private:OrganizeBank()
	local tab = 1
	local db = private.db.global.organize[private.guildKey][tab]

	for slot = 1, (MAX_GUILDBANK_SLOTS_PER_TAB or 98) do
		local slotInfo = db[slot]

		if slotInfo and slotInfo.itemID then
			-- Get guild bank slot info
			local itemID = GetItemInfoInstant(GetGuildBankItemLink(tab, slot) or 0)
			local _, itemCount = GetGuildBankItemInfo(tab, slot)

			-- Get database stack info
			local func = loadstring("return " .. slotInfo.stack)
			if type(func) == "function" then
				local success, userFunc = pcall(func)

				-- Compare slot to database
				if not itemID or itemID ~= slotInfo.itemID or itemCount < userFunc() then
					-- Restock
				end
			end
		end
	end
end
