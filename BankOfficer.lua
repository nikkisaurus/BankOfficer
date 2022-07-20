local addonName, private = ...
local BankOfficer = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

--[[ OnInitialize ]]
function BankOfficer:OnInitialize()
	private:InitializeDatabase()
	private:InitializeFrame()
	private:InitializeSlashCommands()
end

--[[ OnEnable ]]
function BankOfficer:OnEnable()
	if private.db.global.debug.enabled then
		C_Timer.After(1, private.StartDebug)
	end
	BankOfficer:RegisterEvent("GUILDBANKFRAME_OPENED")
	BankOfficer:RegisterEvent("GUILDBANKFRAME_CLOSED")
end

--[[ StartDebug ]]
function private:StartDebug()
	for frame, show in pairs(private.db.global.debug.frames) do
		if show then
			private[frame]:Show()
		end
	end
end
