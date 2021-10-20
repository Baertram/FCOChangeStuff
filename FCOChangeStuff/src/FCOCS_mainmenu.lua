if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

local FCOCSmainMenuButtonWasAdded = false

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

    if not FCOCSmainMenuButtonWasAdded == true then
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
        FCOCSmainMenuButtonWasAdded = true
    end
end

local spinScenes = {}
function FCOChangeStuff.cameraSpinChanges()
    --Stop player from spinning ?
    --Some code taken from "No Thank You"
    local settings = FCOChangeStuff.settingsVars.settings

	local spinFragments = {
		FRAME_PLAYER_FRAGMENT,
		FRAME_EMOTE_FRAGMENT_INVENTORY,
		FRAME_EMOTE_FRAGMENT_SKILLS,
		FRAME_EMOTE_FRAGMENT_JOURNAL,
		FRAME_EMOTE_FRAGMENT_MAP,
		FRAME_EMOTE_FRAGMENT_SOCIAL,
		FRAME_EMOTE_FRAGMENT_AVA,
		FRAME_EMOTE_FRAGMENT_SYSTEM,
		FRAME_EMOTE_FRAGMENT_LOOT,
		FRAME_EMOTE_FRAGMENT_CHAMPION,
	}

	local blacklistedScenes = {
		market = true,
		crownCrateGamepad = true,
		crownCrateKeyboard = true,
		keyboard_housing_furniture_scene = true,
		gamepad_housing_furniture_scene = true,
		dyeStampConfirmationGamepad = true,
		dyeStampConfirmationKeyboard = true,
		outfitStylesBook = true,
		stats = false,
		inventory = false,
	}

	local function updateSpinScenes(disableFragments)
		for _, scene in pairs(spinScenes) do
			if scene.toRestore then
				for _, fragment in ipairs(scene.toRestore) do
					scene:AddFragment(fragment)
				end
			end
		end
		spinScenes = {}
		if disableFragments then
			--[[
            if settings.spinStop then
				blacklistedScenes["stats"]     = not settings.noCameraSpinStats
				blacklistedScenes["inventory"] = not settings.noCameraSpinInv
			end
			]]
			for name, scene in pairs(SCENE_MANAGER.scenes) do
				if not blacklistedScenes[name] then
					local sceneToSave = true
					for _, fragmentToRemove in ipairs(spinFragments) do
						if scene:HasFragment(fragmentToRemove) then
							scene:RemoveFragment(fragmentToRemove)
							if sceneToSave then
								sceneToSave = false
								spinScenes[name] = scene
								spinScenes[name].toRestore = {}
							end
							table.insert(spinScenes[name].toRestore, fragmentToRemove)
						end
					end
				end
			end
		end
	end
	updateSpinScenes(settings.spinStop)
end

function FCOChangeStuff.addMainMenuButtons()
    FCOChangeStuff.addAddonSettingsMainMenuButton()

    FCOChangeStuff.cameraSpinChanges()
end
