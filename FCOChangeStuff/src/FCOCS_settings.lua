if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

------------------------------------------------------------------------------------------------------------------------
-- Settings
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
        pingPongPlayerPinOnMapOpenScaling = 25,
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
        repositionActionSlotTimers = false,
        repositionActionSlotTimersOffset = {
            x = 0,
            y = 0,
        },
        showActionSlotTimersTimeLeftNumber = false,
        spinStop = false,
        spinStopAtScenes = {
            inventory = true,
            collectionsBook = true,
            allOthers = true,
            stats = false,
        },
        collectibleTooltipShowFragmentCombinedItem = false,
        enableKeybindInnocentAttack = false,
        doNotInterruptHarvestOnMenuOpen = false,
        hidePOIsInCities = false,
        suppressDialog = {
            ["CONFIRM_TRADING_HOUSE_CANCEL_LISTING"] = false,
        },
        mailContextMenus = true,
        overwriteMailFields = {
            ["recipients"] = true,
            ["subjects"] = true,
            ["texts"] = true,
        },
        saveMailFields = {
            ["recipients"] = true,
            ["subjects"] = true,
            ["texts"] = true,
        },
        autoLoadMailFields = {
            ["recipients"] = false,
            ["subjects"] = false,
            ["texts"] = false,
        },
        autoLoadMailFieldsAt = {
            mailOpen = {
                ["recipients"] = false,
                ["subjects"] = false,
                ["texts"] = false,
            },
            mailWasSend = {
                ["recipients"] = false,
                ["subjects"] = false,
                ["texts"] = false,
            },
        },
        mailLastUsed = {
            ["recipients"] = "",
            ["subjects"] = "",
            ["texts"] = "",
        },
        mailFavorites = {
            ["recipients"] = false,
            ["subjects"] = false,
            ["texts"] = false,
        },
        mailTextsSaved = {
            ["recipients"] = {},
            ["subjects"] = {},
            ["texts"] = {},
        },
        mailFavoritesSaved = {
            ["recipients"] = {},
            ["subjects"] = {},
            ["texts"] = {},
        },

        mailProfiles = {},
        enableMailProfiles = false,
        --splitMailProfilesIntoAlphabet = false, --not supported as deletion would not be possible anymore!

        splitMailFavoritesIntoAlphabet = false,
        mailFavoritesContextMenusAtEditFields = false,
        mailLastUsedContextMenusAtEditFields = false,
        mailContextMenuSubmenusForceOpenToTheLeft = true,

        showScrollUpDownButtonsAtVerticalScrollbar = false,

        addGuildHistoryNavigationFirstAndLastPage = false,

        -- Golden pursuits
        hidePromotionalEventTracker = false,
        dontAutoPinGoldenPursuits = false,
        dontAutoPinFinishedGoldenPursuits = nil,

        --Quest tracker
        questTrackerMovable = false,
        questTrackerPos = { x=1, y=-1 },

        --Stats scene
        hideStatsPanelMundusRow = false,

        easyDestroy = false,

        --TODO 20231114 for debugging LibAddonMenu dropdwn.lua test for multiselection
        --[[
        _testMultiSelect = { "abc", "q" },
        _testMultiSelectChoicesValues = { 1, 15 },
        orderBoxTest1 = {
			[1] = {
				value 		= BAG_BACKPACK,
				uniqueKey 	= 1,
				text  		= "Entry 1",
				--tooltip 	= locVars["FCOIS_LibFilters_PanelIds"][LF_INVENTORY],

			},
			[2] = {
				value 		= BAG_BANK,
				uniqueKey 	= 2,
				text  		= "Entry 2",
				--tooltip 	= locVars["FCOIS_LibFilters_PanelIds"][LF_BANK_WITHDRAW],
			},
            [3] = {
				value 		= BAG_GUILDBANK,
				uniqueKey 	= 3,
				text  		= "Entry 3",
				--tooltip 	= locVars["FCOIS_LibFilters_PanelIds"][LF_GUILDBANK_WITHDRAW],
			},
			[4] = {
				value 		= BAG_HOUSE_BANK_ONE,
				uniqueKey 	= 4,
				text  		= "Entry 4",
				--tooltip 	= locVars["FCOIS_LibFilters_PanelIds"][LF_HOUSE_BANK_WITHDRAW],
			},
        },
        ]]
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
