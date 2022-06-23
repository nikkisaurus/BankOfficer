local addonName, private = ...
local BankOfficer, L, status = private:unpack()

function private:InitializeDatabase()
	BankOfficer.db = LibStub("AceDB-3.0"):New("BankOfficerDB", {
		global = {},
	}, true)
end
