local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = private.L
local AceGUI = LibStub("AceGUI-3.0")

local Type = "BankOfficer_OrganizeGroup"
local Version = 1

local SLOTBUTTON_HIGHLIGHTTEXTURE = [[INTERFACE\BUTTONS\ButtonHilight-Square]]
local SLOTBUTTON_TEXTURE = [[INTERFACE\ADDONS\BANKOFFICER\MEDIA\UI-SLOT-BACKGROUND]]

local methods = {
    OnAcquire = function(widget)
        widget.frame:SetSize(200, 200)
        widget.frame:Show()
    end,

    LoadSlots = function(widget, guildKey, tab)
        local container = widget.container
        container:ReleaseChildren()
        for slot = 1, 98 do
            local button = AceGUI:Create("BankOfficer_OrganizeSlot")
            button:SetUserData("guildKey", guildKey)
            button:SetUserData("tab", tab)
            button:SetUserData("slotID", slot)
            button:LoadSlot()
            container:AddChild(button)
        end
    end,

    OnWidthSet = function(widget, width)
        widget.parent:Fire("OnWidthSet", width)
    end,

    SetLabel = function(widget, info)
        local guildKey, tab = strsplit(":", info)
        tab = tonumber(tab)
        widget:SetUserData("guildKey", guildKey)
        widget:SetUserData("tab", tab)
        widget:LoadSlots(guildKey, tab)
    end,

    SetText = function(widget, ...) end,
}

local function Constructor()
    local frame = AceGUI:Create("SimpleGroup")
    frame:SetFullWidth(true)
    frame:SetAutoAdjustHeight(true)
    frame:SetLayout("BankOfficer_GuildBankTab")
    --     local overstock = AceGUI:Create("CheckBox")
    --     overstock:SetLabel(L["Restock from this tab"])
    --     overstock:SetCallback("OnValueChanged", function(_, _, checked)
    --         private.db.global.guilds[guildKey].restockTabs[tab] = checked
    --     end)
    --     overstock:SetValue(private.db.global.guilds[guildKey].restockTabs[tab])
    --     tabGroup:AddChild(overstock)

    local widget = {}

    for key, value in pairs(frame) do
        widget[key] = value
    end

    for method, func in pairs(methods) do
        widget[method] = func
    end

    widget.type = Type
    widget.container = frame

    AceGUI:RegisterAsWidget(widget)

    return widget
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
