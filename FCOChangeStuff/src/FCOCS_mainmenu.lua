if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

function FCOChangeStuff.hideCrownStoreButtonInMainMenu(value)
    value = value or false
    --Hide Crown store button
    if ZO_MainMenuCategoryBarButton1 then
        ZO_MainMenuCategoryBarButton1:SetHidden(value)
    end
end


function FCOChangeStuff.hideCrownStoreReminingCrownsInMainMenu(value)
    value = value or false
    --Hide Crown store coins label
    if ZO_MainMenuCategoryBarButton1RemainingCrowns then
        ZO_MainMenuCategoryBarButton1RemainingCrowns:SetHidden(value)
    end
end

function FCOChangeStuff.hideCrownCratesButtonInMainMenu(value)
    value = value or false
    --Hide Crown crates button
    if ZO_MainMenuCategoryBarButton2 then
        ZO_MainMenuCategoryBarButton2:SetHidden(value)
    end
end

function FCOChangeStuff.hideCrownStoreMembershipInMainMenu(value)
    value =  value or false
    --Hide Crown store membership label
    if ZO_MainMenuCategoryBarButton1Membership then
        ZO_MainMenuCategoryBarButton1Membership:SetHidden(value)
    end
end

function FCOChangeStuff.hideDividerRightToCrownStuff()
    local settings = FCOChangeStuff.settingsVars.settings
    local value = settings.hideCrownStoreButtonInMainMenu and settings.hideCrownStorePointsInMainMenu and settings.hideCrownStoreMembershipInMainMenu and settings.hideCrownCratesButtonInMainMenu
    ZO_MainMenuCategoryBarPaddingBar1:SetHidden(value)
end

--======== MAIN MENU ============================================================
function FCOChangeStuff.hideStuff()
    local settings = FCOChangeStuff.settingsVars.settings
    FCOChangeStuff.hideCrownStoreButtonInMainMenu(          settings.hideCrownStoreButtonInMainMenu)
    FCOChangeStuff.hideCrownStoreReminingCrownsInMainMenu(  settings.hideCrownStorePointsInMainMenu)
    FCOChangeStuff.hideCrownStoreMembershipInMainMenu(      settings.hideCrownStoreMembershipInMainMenu)
    FCOChangeStuff.hideCrownCratesButtonInMainMenu(         settings.hideCrownCratesButtonInMainMenu)
    FCOChangeStuff.hideDividerRightToCrownStuff()
end

--Callback function for main menu scene -> Hide the no wanted buttons
--Callback function for HUD scene
HUD_SCENE:RegisterCallback("StateChange", function(oldState, newState)
    if newState == SCENE_HIDING then
        --Slightly delayed so the controls exist
        --zo_callLater(function()
            FCOChangeStuff.hideStuff()
        --end, 150)
    end
end)

--Callback function to open the addon settings
function FCOCS.openLAMAddonSettings(buttonData)
    if WINDOW_MANAGER:IsSecureRenderModeEnabled() then return end
    if SCENE_MANAGER:IsShowing(GAME_MENU_SCENE) then
        SCENE_MANAGER:ShowBaseScene()
    else
        local LAM = FCOChangeStuff.LAM
        if LAM and LAM.OpenToPanel then
            LAM:OpenToPanel(LAM.currentAddonPanel)
        end
    end
end


function FCOChangeStuff.addAddonSettingsMainMenuButton()
    if not FCOChangeStuff.settingsVars.settings.showAddonSettingsMainMenuButton then return false end
    --Create the libMainMenu 2.0 object
    FCOChangeStuff.LMM2 = LibMainMenu2
    if FCOChangeStuff.LMM2 == nil then return end

    FCOChangeStuff.LMM2:Init()
    --The name of the button, descriptor
    local descriptor = FCOChangeStuff.addonVars.addonName
    -- Add to main menu
    local categoryLayoutInfo =
    {
        binding         = "FCOCS_ADDON_SETTINGS_MENU",
        categoryName    = SI_BINDING_NAME_FCOCS_ADDON_SETTINGS_MENU,
        callback        = FCOChangeStuff.openLAMAddonSettings,
        visible         = function(buttonData)
            if VOTANS_MENU_SETTINGS and VOTANS_MENU_SETTINGS:IsMenuButtonEnabled() then
                return false
            else
                return true
            end
        end,
        normal          = "esoui/art/charactercreate/rotate_right_up.dds",
        pressed         = "esoui/art/charactercreate/rotate_right_down.dds",
        highlight       = "esoui/art/charactercreate/rotate_right_over.dds",
        disabled        = "esoui/art/charactercreate/rotate_right_disabled.dds",
    }
    FCOChangeStuff.LMM2:AddMenuItem(descriptor, categoryLayoutInfo)
end

function FCOChangeStuff.addMainMenuButtons()
    FCOChangeStuff.addAddonSettingsMainMenuButton()
end