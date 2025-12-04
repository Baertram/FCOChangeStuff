if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

local defR, defG, defB, deafA = ZO_SUCCEEDED_TEXT:UnpackRGBA()

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

        removeLearnableItemIcon = false,
        learnableItemIconColor = { r=defR, g=defG, b=defB, a=deafA },
        learnableItemIconPos = {
            [BAG_BACKPACK] =            { x=0, y=0, width=32, height=32 },
            [BAG_BANK] =                { x=0, y=0, width=32, height=32 },
            [BAG_HOUSE_BANK_ONE] =      { x=0, y=0, width=32, height=32 }, --Counts for all house banks
            [BAG_GUILDBANK] =           { x=0, y=0, width=32, height=32 },
            --[BAG_FURNITURE_VAULT] =     { x=0, y=0, width=32, height=32  }, --does that even show any learnable items?
            [990] =                     { x=0, y=0, width=32, height=32 }, --Trading house search! custom bagId of this addon
        },
        favoriteMountsContextMenu = false,
        excludedMountCollectionIdsEntries = {},

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
    --Favoritable mounts: Excluded collectibleIds defaults
    local excludedMountIdsShifterBoxDefaults = {
        [5870] = true, --Curious Play wooden horse
        [5880] = true, --Curious Play dragon
        [7291] = true, --Nightmar Play wooden horse
        [9829] = true, --Stopfwell guar
    }
    for mountCollectibleIdToExclude, isEnabled in pairs(excludedMountIdsShifterBoxDefaults) do
        if isEnabled == true then
            defaults.excludedMountCollectionIdsEntries[mountCollectibleIdToExclude] = zo_strformat(SI_UNIT_NAME, GetCollectibleName(mountCollectibleIdToExclude)) or "Mount collectibleId: " ..tostring(mountCollectibleIdToExclude)
        end
    end


    FCOChangeStuff.settingsVars.defaults = defaults

    local serverName = GetWorldName()
    local svTab = FCOChangeStuff_Settings
    local svDefaultSubTab = "Default"
    local svAccountWideSubTab = "$AccountWide"
    local account = GetDisplayName()
    local currentCharId = GetCurrentCharacterId()

    --=============================================================================================================
    --	LOAD USER SETTINGS
    --=============================================================================================================
    --Load the user's settings from SavedVariables file -> Account wide of basic version 999 at first
    FCOChangeStuff.settingsVars.defaultSettings = ZO_SavedVars:NewAccountWide(FCOChangeStuff.addonVars.addonSavedVariablesName, 999, "SettingsForAll", defaultsSettings)

    --Migrate SV from non-server dependent to Server dependent
    local migrationDoneReloadUInow = false
    --Account wide
    if not FCOChangeStuff.settingsVars.defaultSettings.accountWideMigratedToServer then
        local oldAccountWide = (svTab[svDefaultSubTab] and svTab[svDefaultSubTab][account] and svTab[svDefaultSubTab][account]["$AccountWide"] and ZO_ShallowTableCopy(svTab[svDefaultSubTab][account]["$AccountWide"]["Settings"])) or defaults
        if oldAccountWide ~= nil then
            d("[FCOCS]Old accountWide SV found")
            local newAccountWide = ZO_SavedVars:NewAccountWide(FCOChangeStuff.addonVars.addonSavedVariablesName, FCOChangeStuff.addonVars.addonSavedVarsVersion, "Settings", oldAccountWide, serverName)
            if newAccountWide ~= nil then
                d(">migrated to new server dependent accountWide SV")
                FCOChangeStuff.settingsVars.defaultSettings.accountWideMigratedToServer = true
                migrationDoneReloadUInow = true
                --Delete old SVs without server
                svTab[svDefaultSubTab][account]["$AccountWide"]["Settings"] = nil
            end
        end
    end

    --CharacterID of current logged in char
    local oldCharacterIDSettings = (svTab[svDefaultSubTab] and svTab[svDefaultSubTab][account] and svTab[svDefaultSubTab][account][tostring(currentCharId)] and ZO_ShallowTableCopy(svTab[svDefaultSubTab][account][tostring(currentCharId)]["Settings"])) or nil
    if oldCharacterIDSettings ~= nil then
        d("[FCOCS]Old characterID SV found")
        local newCharacterID = ZO_SavedVars:NewCharacterIdSettings(FCOChangeStuff.addonVars.addonSavedVariablesName, FCOChangeStuff.addonVars.addonSavedVarsVersion, "Settings", oldCharacterIDSettings, serverName)
        if newCharacterID ~= nil then
            d(">migrated to new server dependent characterID SV")
            migrationDoneReloadUInow = true
            --Delete old SVs without server
            svTab[svDefaultSubTab][account][tostring(currentCharId)]["Settings"] = nil
        end
    end

    if migrationDoneReloadUInow == true then
        d("[FCOCS]Migration to server was done - Reloading UI now!")
        ReloadUI("ingame")
    end

    --Check, by help of basic version 999 settings, if the SettingsForAll should be loaded for each character or account wide
    --Use the current addon version to read the settings now
    if (FCOChangeStuff.settingsVars.defaultSettings.saveMode == 1) then
        --FCOChangeStuff.settingsVars.settings = ZO_SavedVars:NewCharacterIdSettings(FCOChangeStuff.addonVars.addonSavedVariablesName, FCOChangeStuff.addonVars.addonSavedVarsVersion , "Settings", defaults )
        FCOChangeStuff.settingsVars.settings = ZO_SavedVars:NewAccountWide(FCOChangeStuff.addonVars.addonSavedVariablesName, FCOChangeStuff.addonVars.addonSavedVarsVersion, "Settings", defaults, serverName)
    else
        --FCOChangeStuff.settingsVars.settings = ZO_SavedVars:NewAccountWide(FCOChangeStuff.addonVars.addonSavedVariablesName, FCOChangeStuff.addonVars.addonSavedVarsVersion, "Settings", defaults)
        FCOChangeStuff.settingsVars.settings = ZO_SavedVars:NewCharacterIdSettings(FCOChangeStuff.addonVars.addonSavedVariablesName, FCOChangeStuff.addonVars.addonSavedVarsVersion, "Settings", defaults, serverName)
    end
    --=============================================================================================================
end
