if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

local playerInv = PLAYER_INVENTORY
local companionEquipmentInv = COMPANION_EQUIPMENT_KEYBOARD

------------------------------------------------------------------------------------------------------------------------
-- Inventory --
------------------------------------------------------------------------------------------------------------------------


--[[
function ZO_InventoryManager:OnInventoryItemAdded(inventoryType, bagId, slotIndex, newSlotData, suppressItemAlert)
    local inventory = self.inventories[inventoryType]
    newSlotData.searchData =
    {
        type = ZO_TEXT_SEARCH_TYPE_INVENTORY,
        bagId = bagId,
        slotIndex = slotIndex,
    }

    newSlotData.inventory = inventory

    TEXT_SEARCH_MANAGER:MarkDirtyByFilterTargetAndPrimaryKey(BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, bagId, suppressItemAlert or self.suppressItemAddedAlert)

    -- play a brief flash animation on all the filter tabs that match this item's filterTypes
    if newSlotData.brandNew then
        if INVENTORY_FRAGMENT:IsShowing() then
            self:PlayItemAddedAlert(newSlotData, inventory)
        else
            table.insert(self.newItemList, newSlotData)
        end
    end
end
]]

--======== INVENTORY- NEW ITEM ============================================================
--Remove the new item icon and animation
local noNewItemIconHooked = false
local function FCOCS_noNewItemIcon()
    if not noNewItemIconHooked then
        --PreHook the function "OnInventoryItemAdded" in the inventory to change the "brandNew" boolean variable
        ZO_PreHook(playerInv, "OnInventoryItemAdded", function(self, inventoryType, bagId, slotIndex, newSlotData, suppressItemAlert)
            --d("[FCOCS]OnInventoryItemAdded - newSlotData.brandNew: " ..tostring(newSlotData.brandNew) .. ", suppressItemAlert: " ..tostring(suppressItemAlert))
            --Setting enabled?
            if not FCOChangeStuff.settingsVars.settings.removeNewItemIcon then return false end
            --If it's a new item and marked as brandNew, mark it as not brandNew to block the animation and icon and flash of filter tabs
            if newSlotData ~= nil and newSlotData.brandNew == true then
                newSlotData.brandNew = false
                playerInv.suppressItemAlert = true
            end
            return false -- call original function code of "OnInventoryItemAdded" now!
        end)

        ZO_PreHook(playerInv, "PlayItemAddedAlert", function()
            --d("[FCOCS]PlayItemAddedAlert - suppressed: " ..tostring(PLAYER_INVENTORY.suppressItemAddedAlert))
            if not FCOChangeStuff.settingsVars.settings.removeNewItemIcon then return false end
            playerInv.suppressItemAddedAlert = true
            --Clear the table
            playerInv.newItemList = {}
            return true --abort original function
        end)
        ZO_PreHook(companionEquipmentInv, "PlayItemAddedAlert", function()
            --d("[FCOCS]COMPANION_EQUIPMENT_KEYBOARD PlayItemAddedAlert - suppressed: " ..tostring(COMPANION_EQUIPMENT_KEYBOARD.suppressItemAddedAlert))
            if not FCOChangeStuff.settingsVars.settings.removeNewItemIcon then return false end
            --companionEquipmentInv.suppressItemAddedAlert = true
            --Clear the table
            --companionEquipmentInv.newItemList = {}
            return true --abort original function
        end)

        noNewItemIconHooked = true
    end
end

--Remove the not sellable item icon and animation
local noSellableItemHookDone = false
local function FCOCS_noNotSellableItemIcon()
    --ZO_UpdateSellInformationControlIcon(inventorySlot, slotData)
    --[[
    function ZO_UpdateSellInformationControlIcon(inventorySlot, slotData)
        local sellInformationControl = GetControl(inventorySlot, "SellInformation")
        local sellInformationTexture = GetItemSellInformationIcon(slotData.sellInformation)

        if sellInformationTexture then
            sellInformationControl:SetTexture(sellInformationTexture)
            sellInformationControl:SetHidden(not ZO_Store_IsShopping())
        else
            sellInformationControl:SetHidden(true)
        end
    end
    ]]
    --PreHook the function "OnInventoryItemAdded" in the inventory to change the "brandNew" boolean variable
    if not noSellableItemHookDone then
        ZO_PreHook("ZO_UpdateSellInformationControlIcon", function(inventorySlot, slotData)
            --Setting enabled?
            local settingsRemoveSellIconEnabled = FCOChangeStuff.settingsVars.settings.removeSellItemIcon
            return settingsRemoveSellIconEnabled -- abort/call the origiinal sell icon function
        end)
        noSellableItemHookDone = true
    end
end

local noNewItemsListHookDone = false
local function FCOCS_noNewItemItemsList()
    --As the new items table will be parsed and a new flash will be raised we will clear the list here!
    --[[
    INVENTORY_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
d("[FCOCS]INVENTORY_FRAGMENT - SHOWN - Clearing the newItems list!")
            if not FCOChangeStuff.settingsVars.settings.removeNewItemIcon then return false end
            PLAYER_INVENTORY.suppressItemAddedAlert = true
            PLAYER_INVENTORY.newItemList = {}
        end
    end)
    ]]
    if not noNewItemsListHookDone and INVENTORY_FRAGMENT.callbackRegistry.StateChange[1] and INVENTORY_FRAGMENT.callbackRegistry.StateChange[1][1] ~= nil then
--d("!!![FCOCS]Hooked the original inv. fragment state change function")
        local ORIG_inventroyFragmentOriginalStateChangeFunc = INVENTORY_FRAGMENT.callbackRegistry.StateChange[1][1]
        local new_inventroyFragmentOriginalStateChangeFunc = function(oldState, newState)
    --d("[FCOCS]INVENTORY_FRAGMENT - newState: " ..tostring(newState))
            if newState == SCENE_FRAGMENT_SHOWING then
                if FCOChangeStuff.settingsVars.settings.removeNewItemIcon then
                    --d(">clearing new items list and suppressing it!")
                    PLAYER_INVENTORY.suppressItemAddedAlert = true
                    PLAYER_INVENTORY.newItemList = {}
                end
            end
            ORIG_inventroyFragmentOriginalStateChangeFunc(oldState, newState)
        end
        INVENTORY_FRAGMENT.callbackRegistry.StateChange[1][1] = new_inventroyFragmentOriginalStateChangeFunc
        noNewItemsListHookDone = true
    end
end

--Remove the new item icon and animation
function FCOChangeStuff.noNewItemIcon()
    FCOCS_noNewItemIcon()
    FCOCS_noNewItemItemsList()
end

--Remove the not sellable item icon
function FCOChangeStuff.noNotSellableItemIcon()
    FCOCS_noNotSellableItemIcon()
end

local preHookNewMenuCategoryFlashWasDone = false
local function OnStop()
    playerInv.flashingSlots = {}
    playerInv.listeningControls = {}
end
function FCOChangeStuff.noNewMenuCategoryFlashAnimation()
    --Setting enabled?
    if preHookNewMenuCategoryFlashWasDone == true or not FCOChangeStuff.settingsVars.settings.removeNewItemIcon then return false end

    ZO_PreHook("ZO_Inventory_NewItemCategory_FlashAnimation_OnUpdate", function(timeline, progress)
        --Not enabeld in the settings? Behave normal
        if not FCOChangeStuff.settingsVars.settings.removeNewItemIcon then return false end

        --Hide the flashing controls
        for _, control in pairs(playerInv.listeningControls) do
            control:SetAlpha(0)
        end
        --Remove all controls from any new flashing
        OnStop()
        --Prevent the call to the original function
        return true

        --Calls: playerInv:UpdateCategoryFlashAnimation(timeline, progress) from file esoui/ingame/inventory/inventory.lua
        --[[
    local FLASH_ANIMATION_MIN_ALPHA = 0
    local FLASH_ANIMATION_MAX_ALPHA = 0.5
    function ZO_InventoryManager:UpdateCategoryFlashAnimation(timeline, progress)
        local remainingPlaybackLoops = self.categoryFlashAnimationTimeline:GetPlaybackLoopsRemaining()
        local currentAlpha
        local alphaDelta = progress * (FLASH_ANIMATION_MAX_ALPHA - FLASH_ANIMATION_MIN_ALPHA)
        if remainingPlaybackLoops % 2 then
            -- Fading out
            currentAlpha = alphaDelta + FLASH_ANIMATION_MIN_ALPHA
        else
            -- Fading in
            currentAlpha = FLASH_ANIMATION_MAX_ALPHA - alphaDelta
        end

        for _, control in pairs(self.listeningControls) do
            control:SetAlpha(currentAlpha)
        end
    end
        ]]
    end)
    preHookNewMenuCategoryFlashWasDone = true
end


--======================================================================================================================
-- Scrollbars
--======================================================================================================================
--The scrollBar conrols at the inventory etc.
-->Add each parent "list" (ZO_ScrollList) control here where the scrollbar buttons "scroll to top" and "scroll to bottom" should be added
-->The original "Scroll up" and "Scroll down" buttons will be moved a bit and the new buttons inserted above/below them.
local verticalScrollbarParentControls = {
    [1] = ZO_PlayerInventoryList, --.scrollbar is the scrollbar. Anchor new top and bottom buttons to exisitng "Up" and "Down" childControls
}
FCOChangeStuff.verticalScrollbarParentControls = verticalScrollbarParentControls


local function ppScrollBarAdjustments(scrollButtonCtrl, isVertical, topOrLeft)
    --PerfectPixel hacks
    if PerfectPixel ~= nil and scrollButtonCtrl ~= nil then
        if isVertical == true then
            scrollButtonCtrl:ClearAnchors()
            if topOrLeft == true then
                scrollButtonCtrl:SetAnchor(BOTTOMLEFT, scrollButtonCtrl:GetParent():GetNamedChild("Up"), BOTTOMLEFT, 0, 0)
            else
                scrollButtonCtrl:SetAnchor(TOPLEFT, scrollButtonCtrl:GetParent():GetNamedChild("Down"), TOPLEFT, 0, 0)
                ZO_Scroll_UpdateScrollBar(scrollButtonCtrl:GetParent():GetParent()) --list, update the scrollbar's height according to the shown buttons
            end
        else
            --not supported yet
            return
        end
    end
end


local function createOrUpdateScrollBarButton(scrollbar, isVertical, topOrLeft, doShow, doCreate)
    doCreate = doCreate or false
    if scrollbar == nil or isVertical == nil or topOrLeft == nil then return end
    local scrollbarTypeStr = (isVertical == true and "vertical") or "horizontal"
    if scrollbar == nil or scrollbar.FCOChangeStuffScrollbarButtons == nil or scrollbar.FCOChangeStuffScrollbarButtons[scrollbarTypeStr] == nil then return end
--d("[FCOCS]createOrUpdateScrollBarButton-".. tostring(scrollbar:GetName()) .. ", scrollbarType: " ..tostring(scrollbarTypeStr) .. ", topOrLeft: " ..tostring(topOrLeft) .. ", doShow: " ..tostring(doShow) .. ", doCreate: " ..tostring(doCreate))

    --Create the scrollbar buttons?
    local scrollButtonCtrl
    if doCreate == true then
--d(">create scrollbar button")
        if isVertical == true then
            if topOrLeft == true then
                scrollButtonCtrl = CreateControlFromVirtual(scrollbar:GetName() .. "_FCOCS_ScrollToTopButton", scrollbar, "FCOCS_VerticalScroll_ToTop_Template", nil)
            else
                scrollButtonCtrl = CreateControlFromVirtual(scrollbar:GetName() .. "_FCOCS_ScrollToBottomButton", scrollbar, "FCOCS_VerticalScroll_ToBottom_Template", nil)
            end
            if scrollButtonCtrl ~= nil then
                scrollbar.FCOChangeStuffScrollbarButtons[scrollbarTypeStr][topOrLeft] = scrollButtonCtrl
                scrollButtonCtrl:SetHidden(not doShow)
                if doShow == true then
                    ppScrollBarAdjustments(scrollButtonCtrl, isVertical, topOrLeft)
                end
                return scrollButtonCtrl
            end
        else
            --not supported yet
            return
        end

    else
        --Update the scrollbar buttons?
--d(">update scrollbar button")
        scrollButtonCtrl = scrollbar.FCOChangeStuffScrollbarButtons[scrollbarTypeStr][topOrLeft]
        if scrollButtonCtrl == nil then return end
--d("<found existing scrollbar button: " ..tostring(scrollButtonCtrl))
        if doShow == true then
            ppScrollBarAdjustments(scrollButtonCtrl, isVertical, topOrLeft)
        end
        scrollButtonCtrl:SetHidden(not doShow)
        return scrollButtonCtrl
    end
end

local function addScrollbarButton(scrollbar, isVertical, topOrLeft)
    if scrollbar == nil or isVertical == nil or topOrLeft == nil then return end
--d("[FCOCS]addScrollbarButton-".. tostring(scrollbar:GetName()) .. ", isVertical: " ..tostring(isVertical) .. ", topOrLeft: " ..tostring(topOrLeft))
    scrollbar.FCOChangeStuffScrollbarButtons = scrollbar.FCOChangeStuffScrollbarButtons or {}
    local scrollbarTypeStr = (isVertical == true and "vertical") or "horizontal"
    scrollbar.FCOChangeStuffScrollbarButtons[scrollbarTypeStr] = scrollbar.FCOChangeStuffScrollbarButtons[scrollbarTypeStr] or {}

    createOrUpdateScrollBarButton(scrollbar, isVertical, topOrLeft, true, true)
end

local verticalScrollbarHacksWereDone = false
function FCOChangeStuff.verticalScrollbarHacks()
    local showScrollUpDownButtonsAtVerticalScrollbar = FCOChangeStuff.settingsVars.settings.showScrollUpDownButtonsAtVerticalScrollbar

    for i, scrollbarParentCtrl in ipairs(verticalScrollbarParentControls) do
        if scrollbarParentCtrl ~= nil and scrollbarParentCtrl.useScrollbar == true and scrollbarParentCtrl.scrollbar ~= nil then
            local scrollbarCtrl = scrollbarParentCtrl.scrollbar
            if scrollbarCtrl.FCOChangeStuffScrollbarButtons == nil or scrollbarCtrl.FCOChangeStuffScrollbarButtons["vertical"] == nil then
                --Vertical scrollbar buttons were not added yet
                if showScrollUpDownButtonsAtVerticalScrollbar == true then
                    --Add them now
                    --Top
                    addScrollbarButton(scrollbarCtrl, true, true)
                    --Bottom
                    addScrollbarButton(scrollbarCtrl, true, false)
                end
            else
                --Vertical scrollbar buttons were added already
                if not showScrollUpDownButtonsAtVerticalScrollbar then
                    --Remove them now
                    --Top
                    createOrUpdateScrollBarButton(scrollbarCtrl, true, true, false)
                    --Bottom
                    createOrUpdateScrollBarButton(scrollbarCtrl, true, false, false)
                end
            end
        end
    end
    verticalScrollbarHacksWereDone = true
end


function FCOChangeStuff.ScrollScrollList(scrollBarButton, scrollToTopOrBottom)
--d("[FCOCS]ScrollScrollList")
    if scrollBarButton == nil or scrollToTopOrBottom == nil then return end

    local parent = scrollBarButton:GetParent()
    FCOChangeStuff._scrollBarButtonParent = parent

    if parent ~= nil and parent.GetParent ~= nil then
--d("parent found!")
        local scrollList = parent:GetParent()
        if scrollList ~= nil then
            if scrollToTopOrBottom == true then
--d(">Scroll up!")
                ZO_ScrollList_ResetToTop(scrollList)
            elseif scrollToTopOrBottom == false then
                local numEntries = #scrollList.data or 0
                local controlHeight = scrollList.uniformControlHeight or 60
                local downOffset = numEntries * controlHeight
--d(">Scroll down! entries: " ..tostring(numEntries) .. ", rowHeight: " ..tostring(controlHeight) .. ", offset: " ..tostring(downOffset))
                if downOffset <= 0 then return end
                downOffset = downOffset + controlHeight
                ZO_ScrollList_ScrollAbsolute(scrollList, downOffset)
            end
            return true
        end
    end
    return false
end



--Load the inventory changes
function FCOChangeStuff.inventoryChanges()
    FCOChangeStuff.noNewItemIcon()
    FCOChangeStuff.noNotSellableItemIcon()
    FCOChangeStuff.noNewMenuCategoryFlashAnimation()

    FCOChangeStuff.verticalScrollbarHacks()
end
