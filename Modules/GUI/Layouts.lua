local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

AceGUI:RegisterLayout("BankOfficer_GuildBankTab", function(content, children)
	local width = content:GetWidth() / 14
	for slot, child in pairs(children) do
		if slot <= 98 then
			local frame = child.frame
			child:ClearAllPoints()
			child:SetWidth(width)
			child:SetHeight(width)
			child:SetImageSize(width, width)

			local row = ceil(slot / 14)
			local col = mod(slot, 14)
			col = col > 0 and col or 14
			local offsetX = (col - 1) * width
			local offsetY = (row - 1) * width

			child:SetPoint("TOPLEFT", offsetX, -offsetY)
		end
	end

	content.obj:LayoutFinished(nil, #children > 0 and width * 7 or 0)
end)
