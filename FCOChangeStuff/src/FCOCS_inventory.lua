if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

--======== INVENTORY- NEW ITEM ============================================================
--Remove the new item icon and animation
local function FCOCS_noNewItemIcon()
    --PreHook the function "OnInventoryItemAdded" in the inventory to change the "brandNew" boolean variable
    ZO_PreHook(PLAYER_INVENTORY, "OnInventoryItemAdded", function(self, inventoryType, bagId, slotIndex, newSlotData)
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

--Load the inventory changes
function FCOChangeStuff.inventoryChanges()
    FCOChangeStuff.noNewItemIcon()
    FCOChangeStuff.noNotSellableItemIcon()
end
