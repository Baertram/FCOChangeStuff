if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

------------------------------------------------------------------------------------------------------------------------
-- Bank --
------------------------------------------------------------------------------------------------------------------------

local sceneHooksDoneAt = {}

--[[
local bankingBagIdToInvType = {
    [BAG_BACKPACK]          = INVENTORY_BACKPACK,
    [BAG_BANK]              = INVENTORY_BANK,
    [BAG_GUILDBANK]         = INVENTORY_GUILD_BANK,
    [BAG_HOUSE_BANK_ONE]    = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_TWO]    = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_THREE]  = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_FOUR]   = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_FIVE]   = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_SIX]    = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_SEVEN]  = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_EIGHT]  = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_NINE]   = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_TEN]    = INVENTORY_HOUSE_BANK,
}
]]
local bankingBagIdToMenuBar = {
    [BAG_BACKPACK]          = ZO_PlayerInventoryMenuBar,
    [BAG_BANK]              = ZO_PlayerBankMenuBar,
    [BAG_GUILDBANK]         = ZO_GuildBankMenuBar,
    [BAG_HOUSE_BANK_ONE]    = ZO_HouseBankMenuBar,
    [BAG_HOUSE_BANK_TWO]    = ZO_HouseBankMenuBar,
    [BAG_HOUSE_BANK_THREE]  = ZO_HouseBankMenuBar,
    [BAG_HOUSE_BANK_FOUR]   = ZO_HouseBankMenuBar,
    [BAG_HOUSE_BANK_FIVE]   = ZO_HouseBankMenuBar,
    [BAG_HOUSE_BANK_SIX]    = ZO_HouseBankMenuBar,
    [BAG_HOUSE_BANK_SEVEN]  = ZO_HouseBankMenuBar,
    [BAG_HOUSE_BANK_EIGHT]  = ZO_HouseBankMenuBar,
    [BAG_HOUSE_BANK_NINE]   = ZO_HouseBankMenuBar,
    [BAG_HOUSE_BANK_TEN]    = ZO_HouseBankMenuBar,
}
local houseBankDescriptors = {
    [SI_BANK_DEPOSIT] = SI_BANK_WITHDRAW,            --Withdraw
    [SI_BANK_WITHDRAW] = SI_BANK_DEPOSIT,            --Deposit
}
local bankingBagIdToDescriptors = {
    [BAG_BACKPACK]          = {
        [SI_BANK_DEPOSIT] = SI_BANK_WITHDRAW,        --Withdraw
        [SI_BANK_WITHDRAW] = SI_BANK_DEPOSIT,        --Deposit
    },
    [BAG_BANK]              = {
        [SI_BANK_DEPOSIT] = SI_BANK_WITHDRAW,     --Withdraw
        [SI_BANK_WITHDRAW] = SI_BANK_DEPOSIT,     --Deposit
    },
    [BAG_GUILDBANK]         = {
        [SI_BANK_DEPOSIT] = SI_BANK_WITHDRAW,        --Withdraw
        [SI_BANK_WITHDRAW] = SI_BANK_DEPOSIT,        --Deposit
    },
    [BAG_HOUSE_BANK_ONE]    = houseBankDescriptors,
    [BAG_HOUSE_BANK_TWO]    = houseBankDescriptors,
    [BAG_HOUSE_BANK_THREE]  = houseBankDescriptors,
    [BAG_HOUSE_BANK_FOUR]   = houseBankDescriptors,
    [BAG_HOUSE_BANK_FIVE]   = houseBankDescriptors,
    [BAG_HOUSE_BANK_SIX]    = houseBankDescriptors,
    [BAG_HOUSE_BANK_SEVEN]  = houseBankDescriptors,
    [BAG_HOUSE_BANK_EIGHT]  = houseBankDescriptors,
    [BAG_HOUSE_BANK_NINE]   = houseBankDescriptors,
    [BAG_HOUSE_BANK_TEN]    = houseBankDescriptors,
}

local PI = PLAYER_INVENTORY
local SM = SCENE_MANAGER


------------------------------------------------------------------------------------------------------------------------
function FCOChangeStuff.EnableCharacterFragment(where)
    if not where or where == "" then return end
    local settings = FCOChangeStuff.settingsVars.settings
    local whereToScene = {
        ["bank"] = nil,
        ["guildbank"] = nil,
    }
    local whereToSceneByName = {
        ["bank"]      = "bank",
        ["guildbank"] = "guildBank",
    }
    --[[
    local whereToFragment = {
        ["bank"] = BANK_FRAGMENT,
    }
    ]]
    local whereToAddNewFragments = {
        ["bank"] = {
            CHARACTER_WINDOW_FRAGMENT,
            CHARACTER_WINDOW_STATS_FRAGMENT,
            LEFT_PANEL_BG_FRAGMENT,
        }
    }
    whereToAddNewFragments["guildBank"] = whereToAddNewFragments["bank"]

    local sceneToHook = whereToScene[where]
    local sceneToHookName
    if not sceneToHook then
        sceneToHookName = whereToSceneByName[where]
    end
    if not sceneToHookName or sceneToHookName == "" then return end
    sceneToHook = SM:GetScene(sceneToHookName)
    if not sceneToHook then return end
    --local fragmentToHook = whereToFragment[where]
    --if not fragmentToHook then return end
    local fragmentsToAddNew = whereToAddNewFragments[where]
    if not fragmentsToAddNew then return end

    local function removeFragments()
        for _, fragmentToAddNew in ipairs(fragmentsToAddNew) do
            sceneToHook:RemoveFragment(fragmentToAddNew)
        end
    end
    local function sceneStateChange(oldState, newState, whereWasItDone)
        if whereWasItDone and sceneHooksDoneAt[whereWasItDone] == true then
            if whereWasItDone == "bank" and not settings.showCharacterPanelAtBank then
                removeFragments()
                return
            end
            if whereWasItDone == "guildbank" and not settings.showCharacterPanelAtGuildBank then
                removeFragments()
                return
            end
        end
        if newState == SCENE_SHOWN then
            for _, fragmentToAddNew in ipairs(fragmentsToAddNew) do
                sceneToHook:AddFragment(fragmentToAddNew)
            end
        elseif newState == SCENE_HIDDEN then
            removeFragments()
        end
    end
    if where == "bank" and settings.showCharacterPanelAtBank == true
       or where == "guildbank" and settings.showCharacterPanelAtGuildBank  == true
    then
        sceneHooksDoneAt[where] = true
        sceneToHook:RegisterCallback("StateChange", function(oldState, newState) sceneStateChange(oldState, newState, where) end)
    end
end

------------------------------------------------------------------------------------------------------------------------


local function getMenuBar(bankBagId)
    local menuBar = bankingBagIdToMenuBar[bankBagId]
    return menuBar
end

local function getMenuBarAndNotSelectedDescriptor(bankBagId)
--d("getMenuBarAndNotSelectedDescriptor")
    local menuBar = getMenuBar(bankBagId)
    if not menuBar then return end
--d(">Found menubar")
    local selectedDescriptor = menuBar.m_object.m_clickedButton.m_buttonData.descriptor
    if not selectedDescriptor then return end
--d(">Found selectedDescriptor:" .. GetString(selectedDescriptor))
    local nonSelectedDescriptor = bankingBagIdToDescriptors[bankBagId][selectedDescriptor]
    return menuBar, nonSelectedDescriptor
end

--[[
local function getMenuBarAndSelectedFilterTab(bankBagId)
d("getMenuBarAndSelectedTab - bankBagId: " ..tostring(bankBagId))
    local layoutData = PI.appliedLayout
    if not layoutData then return end
d(">1")
    local invType = bankingBagIdToInvType[bankBagId]
    if not invType then return end
d(">invType: " ..tostring(invType))
    local menuBar = PI.inventories[invType].filterBar
    if not menuBar or not menuBar.IsHidden or menuBar:IsHidden() then return end
    local selectedTab = layoutData.selectedTab or ITEM_TYPE_DISPLAY_CATEGORY_ALL
d(">selectedTab: " ..tostring(selectedTab))
    return menuBar, selectedTab
end
]]

local function getMenuBarAndDescriptor()
    --d("getMenuBarAndDescriptor")
    local bankBagId
    if IsBankOpen() then bankBagId = GetBankingBag()
    elseif IsGuildBankOpen() then
        if ZO_SelectGuildBankDialog:IsHidden() then
            bankBagId = BAG_GUILDBANK
        end
    end
    --d(">bankBagId: " ..tostring(bankBagId))
    if not bankBagId or bankBagId <= 0 then return end
    --Get the bank menubar and descriptor (selected filter tab) of the bank bagId
    local menuBar, descriptorNew = getMenuBarAndNotSelectedDescriptor(bankBagId)
    --d(">descriptor to select new: " ..tostring(descriptorNew))
    if not menuBar or not descriptorNew then return end
    return menuBar, descriptorNew
end

function FCOChangeStuff.switchBankMenuBarDescriptor()
--d("[FCOChangeStuff]SwitchBankMenuBarDescriptor()")
    local categoryBar, category = getMenuBarAndDescriptor()
    if not categoryBar or not category then return end
    ZO_MenuBar_SelectDescriptor(categoryBar, category, true)
end

------------------------------------------------------------------------------------------------------------------------
--Enable the bank modifications
function FCOChangeStuff.bankChanges()
    FCOChangeStuff.EnableCharacterFragment("bank")
    FCOChangeStuff.EnableCharacterFragment("guildbank")
end
