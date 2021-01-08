if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

------------------------------------------------------------------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------------------------------------------------------------------
--Read the SavedVariables
function FCOChangeStuff.getSettings()
    --The default values for the language and save mode
    local defaultsSettings = {
        language 	 		    = 1, --Standard: English
        saveMode     		    = 2, --Standard: Account wide settings
    }

    --Pre-set the deafult values
    local defaults = {
        alwaysUseClientLanguage			    = true,
        showRealCPs                         = false,
        reOpenMapOnMounting                 = false,
        showEnDisableAllFilterButtons       = false,
        hideCrownStoreButtonInMainMenu      = false,
        hideCrownStoreMembershipInMainMenu  = false,
        hideCrownCratesButtonInMainMenu     = false,
        hideCrownStorePointsInMainMenu      = false,
        stableFeedSettings          = {
            [RIDING_TRAIN_SPEED]                = false,
            [RIDING_TRAIN_STAMINA]              = false,
            [RIDING_TRAIN_CARRYING_CAPACITY]    = false,
        },
        showAddonSettingsMainMenuButton     = false,
        smithingCreationAddArmorTypeSwitchButton = true,
        improvementWith100Percent           = false,
        improvementBlockQuality             = -1,
        improvementBlockQualityExceptionShiftKey = false,
        removeNewItemIcon = false,
        removeSellItemIcon = false,
        enableChatBlacklist = false,
        chatKeyWords = "",
        enableChatBlacklistForWhispers = false,
        enableChatBlacklistForGroup = false,
        enableChatBlacklistForGuilds = false,
        blacklistedTextToChat = false,
        enableSkillLineContextMenu = false,
        skillLineIndexState = {},
        noShopAdvertisementPopup = false,
        noEnlightenedSound = false,
        enableBGHUDMoveable = false,
        BGHUDcoordinates = {
            ["x"] = 21,
            ["y"] = 0,
        },
        changeSoundAtCrafting = false,
        changeSoundAtCraftingVolume = 0,
        volumes = {
            [SETTING_TYPE_AUDIO] = {
                [AUDIO_SETTING_AUDIO_VOLUME] = 0,
            },
        },
        pingPongPlayerPinOnMapOpen = true,
        enableChatWhisperAndFlaggedAsOfflineReminder = false,
        enableKeybindCompassQuestGivers = false,
        hideMapZoneStory = false,
        hideMapZoneStoryBeamMeUpAllowedToShow = false,
        disableChatNotificationAnimation = false,
        disableChatNotificationSound = false,
        showCharacterPanelAtBank = false,
        showCharacterPanelAtGuildBank = false,
        disableSoundsLibShifterBox = false,
        disabledSoundEntries = {},
        muteMountSound = false,
        muteMountSoundDelay = 500,
        muteMountSoundVolume = 0,
        autoDeclineGroupElections = false,
        tooltipSizeHack = false,
        tooltipSizeItemBorder = 416,
        tooltipSizePopupBorder = 416,
        tooltipSizeComparativeBorder = 416,
        tooltipSizeItemScaleHackPercentage = 100,
        tooltipSizePopupScaleHackPercentage = 100,
        tooltipSizeComparativeScaleHackPercentage = 100,
        snapCursorToLootWindow = false,
    }
    FCOChangeStuff.settingsVars.defaults = defaults

    --=============================================================================================================
    --	LOAD USER SETTINGS
    --=============================================================================================================
    --Load the user's settings from SavedVariables file -> Account wide of basic version 999 at first
    FCOChangeStuff.settingsVars.defaultSettings = ZO_SavedVars:NewAccountWide(FCOChangeStuff.addonVars.addonSavedVariablesName, 999, "SettingsForAll", defaultsSettings)

    --Check, by help of basic version 999 settings, if the settings should be loaded for each character or account wide
    --Use the current addon version to read the settings now
    if (FCOChangeStuff.settingsVars.defaultSettings.saveMode == 1) then
        FCOChangeStuff.settingsVars.settings = ZO_SavedVars:NewCharacterIdSettings(FCOChangeStuff.addonVars.addonSavedVariablesName, FCOChangeStuff.addonVars.addonSavedVarsVersion , "Settings", defaults )
    elseif (FCOChangeStuff.settingsVars.defaultSettings.saveMode == 2) then
        FCOChangeStuff.settingsVars.settings = ZO_SavedVars:NewAccountWide(FCOChangeStuff.addonVars.addonSavedVariablesName, FCOChangeStuff.addonVars.addonSavedVarsVersion, "Settings", defaults)
    else
        FCOChangeStuff.settingsVars.settings = ZO_SavedVars:NewAccountWide(FCOChangeStuff.addonVars.addonSavedVariablesName, FCOChangeStuff.addonVars.addonSavedVarsVersion, "Settings", defaults)
    end
    --=============================================================================================================
end