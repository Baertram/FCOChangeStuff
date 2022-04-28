if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

local orig_CreateOrUpdateSlotData = SHARED_INVENTORY.CreateOrUpdateSlotData

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
local function FCOCS_noNewItemIcon()
    if not FCOChangeStuff.settingsVars.settings.removeNewItemIcon then return false end


--[[
https://github.com/esoui/esoui/blob/master/esoui/ingame/inventory/sharedinventory.lua#L661

function ZO_SharedInventoryManager:CreateOrUpdateSlotData(existingSlotData, bagId, slotIndex, isNewItem)
if not slot then
        if hasItemInSlotNow then
            slot = {}
        end
    else
        hadItemInSlotBefore = slot.stackCount > 0
        wasSameItemInSlotBefore = hadItemInSlotBefore and hasItemInSlotNow and slot.uniqueId == newUniqueId
    end
    ..

 if wasSameItemInSlotBefore and slot.age ~= 0 then
        -- don't modify the age, keep it the same relative sort - for now?
        -- Age is only set to 0 before this point from ClearNewStatus, so if brandNew is false
        -- but age isn't 0, something has tried to set brandNew to false without calling ClearNewStatus,
        -- so we can still rely on it actually being new.
        slot.brandNew = true
    elseif isNewItem then
        slot.age = GetFrameTimeSeconds()
    else
        slot.age = 0
    end
    ...


    SHARED_INVENTORY = ZO_SharedInventoryManager:New()
]]

    function SHARED_INVENTORY:CreateOrUpdateSlotData(existingSlotData, bagId, slotIndex, isNewItem)
        local slot, result = orig_CreateOrUpdateSlotData(self, existingSlotData, bagId, slotIndex, isNewItem)
        if isNewItem == true or (slot and slot.brandNew) then
--d("[FCOCS]item is new: " .. GetItemLink(bagId, slotIndex))
            --Remove new indicator, and reset the age to 0
            slot.age = 0
            slot.brandNew = nil
            --Empty the new items table at the inventory
            playerInv.suppressItemAddedAlert = true
            playerInv.newItemList = {}
            --Companion
            --companionEquipmentInv.suppressItemAddedAlert = true
            --companionEquipmentInv.newItemList = {}
        end
        return slot, result
    end

    --[[
    --PreHook the function "OnInventoryItemAdded" in the inventory to change the "brandNew" boolean variable
    ZO_PreHook(playerInv, "OnInventoryItemAdded", function(self, inventoryType, bagId, slotIndex, newSlotData, suppressItemAlert)
--d("[FCOCS]OnInventoryItemAdded - newSlotData.brandNew: " ..tostring(newSlotData.brandNew) .. ", suppressItemAlert: " ..tostring(suppressItemAlert))
        --If it's a new item and marked as brandNew, mark it as not brandNew to block the animation and icon and flash of filter tabs
        if newSlotData ~= nil and newSlotData.brandNew == true then
            newSlotData.brandNew = false
            playerInv.suppressItemAlert = true
        end
        return false -- call original function code of "OnInventoryItemAdded" now!
    end)

    ZO_PreHook(playerInv, "PlayItemAddedAlert", function()
--d("[FCOCS]PlayItemAddedAlert - suppressed: " ..tostring(PLAYER_INVENTORY.suppressItemAddedAlert))
        playerInv.suppressItemAddedAlert = true
        --Clear the table
        playerInv.newItemList = {}
        return true --abort original function
    end)
    ZO_PreHook(companionEquipmentInv, "PlayItemAddedAlert", function()
--d("[FCOCS]COMPANION_EQUIPMENT_KEYBOARD PlayItemAddedAlert - suppressed: " ..tostring(COMPANION_EQUIPMENT_KEYBOARD.suppressItemAddedAlert))
        --companionEquipmentInv.suppressItemAddedAlert = true
        --Clear the table
        --companionEquipmentInv.newItemList = {}
        return true --abort original function
    end)
    ]]
end

--Remove the not sellable item icon and animation
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
    ZO_PreHook("ZO_UpdateSellInformationControlIcon", function(inventorySlot, slotData)
        --Setting enabled?
        local settingsRemoveSellIconEnabled = FCOChangeStuff.settingsVars.settings.removeSellItemIcon
        return settingsRemoveSellIconEnabled -- abort/call the origiinal sell icon function
    end)
end

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

--[[
    local hookDone = false
    if not hookDone and INVENTORY_FRAGMENT.callbackRegistry.StateChange[1] and INVENTORY_FRAGMENT.callbackRegistry.StateChange[1][1] ~= nil then
d("!!![FCOCS]Hooked the original inv. fragment state change function")
        local ORIG_inventroyFragmentOriginalStateChangeFunc = INVENTORY_FRAGMENT.callbackRegistry.StateChange[1][1]
        local new_inventroyFragmentOriginalStateChangeFunc = function(oldState, newState)
    --d("[FCOCS]INVENTORY_FRAGMENT - newState: " ..tostring(newState))
            if newState == SCENE_FRAGMENT_SHOWING then
d(">clearing new items list and suppressing it!")
                PLAYER_INVENTORY.suppressItemAddedAlert = true
                PLAYER_INVENTORY.newItemList = {}
            end
            ORIG_inventroyFragmentOriginalStateChangeFunc(oldState, newState)
        end
        INVENTORY_FRAGMENT.callbackRegistry.StateChange[1][1] = new_inventroyFragmentOriginalStateChangeFunc
        hookDone = true
    end
]]
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

--Load the inventory changes
function FCOChangeStuff.inventoryChanges()
    FCOChangeStuff.noNewItemIcon()
    FCOChangeStuff.noNotSellableItemIcon()
    FCOChangeStuff.noNewMenuCategoryFlashAnimation()
end
