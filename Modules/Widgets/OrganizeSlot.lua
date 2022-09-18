local addonName, private = ...
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = private.L
local AceGUI = LibStub("AceGUI-3.0")

local Type = "BankOfficer_OrganizeSlot"
local Version = 1

local SLOTBUTTON_HIGHLIGHTTEXTURE = [[INTERFACE\BUTTONS\ButtonHilight-Square]]
local SLOTBUTTON_TEXTURE = [[INTERFACE\ADDONS\BANKOFFICER\MEDIA\UI-SLOT-BACKGROUND]]

--[[ Locals ]]
-- Menus
local function GetEasyMenu(widget)
    local tab = private.db.global.guilds[widget:GetUserData("guildKey")].organize[widget:GetUserData("tab")]
    local slotInfo = tab and tab[widget:GetUserData("slotID")]
    local isEmpty = not slotInfo or not slotInfo.itemID

    if isEmpty then
        return {
            { text = widget:GetSlotTitle(), isTitle = true, notCheckable = true },
            {
                text = L["Edit Slot"],
                func = function()
                    widget:EditSlot()
                end,
            },
        }
    else
        return {
            { text = (GetItemInfo(slotInfo.itemID)), isTitle = true, notCheckable = true },
            { text = widget:GetSlotTitle(), isTitle = true, notCheckable = true },
            {
                text = L["Edit Slot"],
                func = function()
                    widget:EditSlot()
                end,
            },
            {
                text = L["Duplicate Slot"],
                func = function()
                    widget:PickupItem(true)
                end,
            },
            {
                text = L["Clear Slot"],
                func = function()
                    widget:ClearSlot()
                end,
            },
        }
    end
end

--[[ Script handlers ]]
local function frame_onClick(frame, mouseButton)
    local widget = frame.obj
    local tab = private.db.global.guilds[widget:GetUserData("guildKey")].organize[widget:GetUserData("tab")]
    local slotInfo = tab and tab[widget:GetUserData("slotID")]
    local isEmpty = not slotInfo or not slotInfo.itemID

    if mouseButton == "LeftButton" then
        local cursorType, itemID = GetCursorInfo()
        local template = private.db.global.templates[private.organizeEditMode]

        if template then
            widget:UpdateSlotInfo(template)
        elseif private.organizeEditMode == "clear" then
            widget:ClearSlot()
        elseif cursorType == "item" then
            if private.organizeOriginSlot then
                if isEmpty then
                    private.organizeOriginSlot:ClearSlot()
                else
                    private.organizeOriginSlot:UpdateSlotInfo(slotInfo)
                end
            end
            widget:LoadCursorItem(itemID)
        elseif not isEmpty then
            widget:PickupItem(private.organizeEditMode == "duplicate")
        end
    elseif mouseButton == "RightButton" then
        if not isEmpty then
            addon:CacheItem(slotInfo.itemID, function(itemID, private, widget)
                EasyMenu(GetEasyMenu(widget), private.organizeContextMenu, widget.frame, 0, 0, "MENU")
            end, private, widget)
        end
    end
end

local function frame_OnDragStart(frame)
    local widget = frame.obj

    local tab = private.db.global.guilds[widget:GetUserData("guildKey")].organize[widget:GetUserData("tab")]
    local slotInfo = tab and tab[widget:GetUserData("slotID")]
    local isEmpty = not slotInfo or not slotInfo.itemID
    if private.organizeEditMode or isEmpty then
        return
    end

    widget:PickupItem()
end

local function frame_OnEnter(frame)
    local widget = frame.obj

    local tab = private.db.global.guilds[widget:GetUserData("guildKey")].organize[widget:GetUserData("tab")]
    local slotInfo = tab and tab[widget:GetUserData("slotID")]
    local isEmpty = not slotInfo or not slotInfo.itemID
    local tooltip = private.tooltip

    tooltip:SetOwner(frame, "ANCHOR_RIGHT", 0, 0)
    if not isEmpty then
        private:CacheItem(slotInfo.itemID)
        local _, itemLink = GetItemInfo(slotInfo.itemID)
        tooltip:SetHyperlink(itemLink)
        tooltip:AddLine(widget:GetSlotTitle(), 1, 1, 1)
    else
        tooltip:AddLine(widget:GetSlotTitle())
    end
    tooltip:Show()
end

local function frame_OnLeave(frame)
    private.tooltip:ClearLines()
    private.tooltip:Hide()
end

local function frame_OnReceiveDrag(frame)
    local widget = frame.obj

    local tab = private.db.global.guilds[widget:GetUserData("guildKey")].organize[widget:GetUserData("tab")]
    local slotInfo = tab and tab[widget:GetUserData("slotID")]
    local isEmpty = not slotInfo or not slotInfo.itemID
    if private.organizeEditMode then
        return
    end

    local cursorType, itemID = GetCursorInfo()
    if cursorType == "item" then
        if private.organizeOriginSlot then
            if isEmpty then
                private.organizeOriginSlot:ClearSlot()
            else
                print("Swap")
                private.organizeOriginSlot:UpdateSlotInfo(slotInfo)
            end
        end
        widget:LoadCursorItem(itemID)
    end
end

--[[ Methods ]]
local methods = {
    OnAcquire = function(widget)
        widget.label:SetFont([[Fonts\ARIALN.TTF]], 14, "OUTLINE, MONOCHROME")
        widget.label:SetJustifyH("RIGHT")

        local padding = widget.frame:GetWidth() * 0.1
        widget.label:SetPoint("LEFT", padding, 0)
        widget.label:SetPoint("RIGHT", -padding, 0)
        widget.label:SetPoint("BOTTOM", 0, padding)
    end,

    OnRelease = function(widget)
        widget.frame:SetNormalTexture(private.media .. [[UI-SLOT-BACKGROUND]])
        widget.frame:SetText(" ")
    end,

    OnWidthSet = function(widget, width)
        if widget.frame:GetHeight() ~= width then
            widget:SetHeight(width)

            local fontHeight = width * 0.35

            widget.label:SetFont([[Fonts\ARIALN.TTF]], (fontHeight <= 0 and 1 or fontHeight), "OUTLINE, MONOCHROME")

            local padding = width * 0.1
            widget.label:SetPoint("LEFT", padding, 0)
            widget.label:SetPoint("RIGHT", -padding, 0)
            widget.label:SetPoint("BOTTOM", 0, padding)
        end
    end,

    ClearSlot = function(widget)
        local slotID = widget:GetUserData("slotID")
        private.db.global.guilds[widget:GetUserData("guildKey")].organize[widget:GetUserData("tab")][slotID] = nil
        private.organizeOriginSlot = nil
        widget:LoadSlot()
    end,

    EditSlot = function(widget)
        private.organizeEditSlot = {
            guildKey = widget:GetUserData("guildKey"),
            tab = widget:GetUserData("tab"),
            slotID = widget:GetUserData("slotID"),
        }
        private:RefreshOptions()
    end,

    GetSlotTitle = function(widget, slotID)
        return L["Slot"] .. " " .. (slotID or widget:GetUserData("slotID") or "")
    end,

    LoadCursorItem = function(widget, itemID)
        local cursorInfo = private.organizeDuplicateInfo or private.organizeCursorInfo

        if cursorInfo then
            widget:UpdateSlotInfo(cursorInfo)
            private.organizeCursorInfo = nil
        else
            addon:CacheItem(itemID, function(itemID, private, widget)
                local _, _, _, _, _, _, _, _, _, _, _, _, _, bindType = GetItemInfo(itemID)

                if bindType and bindType ~= 1 then
                    widget:UpdateSlotInfo({ itemID = itemID, stack = private.defaults.stack })
                end
            end, private, widget)
        end

        if private.organizeEditMode ~= "duplicate" then
            ClearCursor()
        end

        widget:LoadSlot()
    end,

    LoadSlot = function(widget)
        local guildKey = widget:GetUserData("guildKey")
        local tab = widget:GetUserData("tab")
        local slotID = widget:GetUserData("slotID")

        local tab = private.db.global.guilds[guildKey].organize[tab]
        local slotInfo = tab and tab[slotID]
        local isEmpty = not slotInfo or not slotInfo.itemID

        -- Set icon
        widget.frame:SetNormalTexture(
            isEmpty and (private.media .. [[UI-SLOT-BACKGROUND]]) or GetItemIcon(slotInfo.itemID)
        )

        -- Set stack
        if not isEmpty then
            local func = loadstring("return " .. slotInfo.stack)
            if type(func) == "function" then
                local success, userFunc = pcall(func)
                widget.frame:SetText(success and type(userFunc) == "function" and userFunc())
            end
        else
            widget.frame:SetText(" ")
        end
    end,

    PickupItem = function(widget, duplicate)
        local tab = private.db.global.guilds[widget:GetUserData("guildKey")].organize[widget:GetUserData("tab")]
        local slotInfo = tab and tab[widget:GetUserData("slotID")]
        local isEmpty = not slotInfo or not slotInfo.itemID
        if isEmpty then
            return
        end

        if duplicate and not private.organizeDuplicateInfo then
            private.organizeDuplicateInfo = addon.CloneTable(slotInfo)
        end

        PickupItem(slotInfo.itemID)
        private.organizeCursorInfo = private.organizeDuplicateInfo or slotInfo

        widget.image:SetDesaturated(not duplicate)
        private.organizeOriginSlot = not duplicate and widget
    end,

    SetLabel = function(widget) end,

    SetText = function(widget) end,

    UpdateSlotInfo = function(widget, info)
        if not private.db.global.guilds[widget:GetUserData("guildKey")].organize[widget:GetUserData("tab")] then
            private.db.global.guilds[widget:GetUserData("guildKey")].organize[widget:GetUserData("tab")] = {}
        end
        private.db.global.guilds[widget:GetUserData("guildKey")].organize[widget:GetUserData("tab")][widget:GetUserData(
            "slotID"
        )] =
            addon.CloneTable(info)
        widget:LoadSlot()
    end,
}

--[[ Constructor ]]
local function Constructor()
    local frame = CreateFrame("Button", Type .. AceGUI:GetNextWidgetNum(Type), UIParent)
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:SetText(" ")
    frame:SetPushedTextOffset(0, 0)
    frame:SetScript("OnClick", frame_onClick)
    -- frame:SetScript("OnEnter", frame_OnEnter)
    -- frame:SetScript("OnLeave", frame_OnLeave)

    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame_OnDragStart)
    frame:SetScript("OnReceiveDrag", frame_OnReceiveDrag)

    frame:SetNormalTexture(SLOTBUTTON_TEXTURE)
    frame:SetHighlightTexture(SLOTBUTTON_HIGHLIGHTTEXTURE)

    if not addon:IsHooked("ClearCursor") then
        addon:SecureHook("ClearCursor", function()
            local numSlots = AceGUI:GetWidgetCount(Type)
            for i = 1, numSlots do
                local button = _G[Type .. i]
                if button then
                    button.obj.image:SetDesaturated(false)
                end
            end
            private.organizeDuplicateInfo = nil
        end)
    end

    local contextMenu =
        CreateFrame("Frame", Type .. AceGUI:GetNextWidgetNum(Type) .. "ContextMenu", frame, "UIDropDownMenuTemplate")

    local widget = {
        frame = frame,
        image = frame:GetNormalTexture(),
        label = frame:GetFontString(),
        contextMenu = contextMenu,
        type = Type,
    }

    frame.obj = widget

    for method, func in pairs(methods) do
        widget[method] = func
    end

    AceGUI:RegisterAsWidget(widget)

    return widget
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
