local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)
local AceGUI = LibStub("AceGUI-3.0")

AceGUI:RegisterLayout("BankOfficer_GuildBankTab", function(content, children)
	local width = content:GetWidth() / 14
	for slot, child in pairs(children) do
		local frame = child.frame
		child:ClearAllPoints()
		if slot <= 98 then
			child:SetWidth(width)
			child:SetHeight(width)
		end

		local col = ceil(slot / 7)
		local row = mod(slot, 7)
		row = row > 0 and row or slot / col

		local offsetX = (col - 1) * width
		local offsetY = (row - 1) * width

		if slot <= 98 then
			child:SetPoint("TOPLEFT", offsetX, -offsetY)
		else
			child:SetPoint("TOPLEFT", 0, -(width * 7))
		end
	end

	content.obj:LayoutFinished(nil, (#children > 0 and width * 7 or 0) + 20)
end)
