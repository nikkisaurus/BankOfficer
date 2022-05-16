local addonName = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName, true)

addon.GetOptionsTab_Args1 = function()
	return {}
end

addon.GetOptionsTab_Args2 = function()
	return {}
end
