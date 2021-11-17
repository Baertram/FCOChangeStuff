if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

local playerInv = PLAYER_INVENTORY

------------------------------------------------------------------------------------------------------------------------
-- Inventory --
------------------------------------------------------------------------------------------------------------------------


--======== INVENTORY- NEW ITEM ============================================================
--Remove the new item icon and animation
local function FCOCS_noNewItemIcon()
    --PreHook the function "OnInventoryItemAdded" in the inventory to change the "brandNew" boolean variable
    ZO_PreHook(playerInv, "OnInventoryItemAdded", function(self, inventoryType, bagId, slotIndex, newSlotData)
        --Setting enabled?
        if not FCOChangeStuff.settingsVars.settings.removeNewItemIcon then return false end
        --If it's a new item and marked as brandNew, mark it as not brandNew to block the animation and icon
        if newSlotData and newSlotData.brandNew then
            newSlotData.brandNew = false
        end
        return false -- call original function code of "OnInventoryItemAdded" now!
    end)
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

--Remove the new item icon and animation
function FCOChangeStuff.noNewItemIcon()
    FCOCS_noNewItemIcon()
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
