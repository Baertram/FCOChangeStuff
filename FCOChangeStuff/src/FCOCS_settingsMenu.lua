if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

function FCOChangeStuff.buildAddonMenu()
    local settings = FCOChangeStuff.settingsVars.settings
    if not settings or not FCOChangeStuff.LAM then return false end
    local defaults = FCOChangeStuff.settingsVars.defaults
    local addonVars = FCOChangeStuff.addonVars

    local panelData = {
        type 				= 'panel',
        name 				= addonVars.addonNameMenu,
        displayName 		= addonVars.addonNameMenuDisplay,
        author 				= addonVars.addonAuthor,
        version 			= tostring(addonVars.addonVersion),
        registerForRefresh 	= true,
        registerForDefaults = true,
        slashCommand        = "/fcoccss",
        website             = addonVars.addonWebsite,
        feedback            = addonVars.addonFeedback,
        donation            = addonVars.addonDonation,
    }

    local savedVariablesOptions = {
        [1] = 'Each character',
        [2] = 'Account wide'
    }


    local colorMagic = GetItemQualityColor(ITEM_QUALITY_MAGIC)
    local colorArcane = GetItemQualityColor(ITEM_QUALITY_ARCANE)
    local colorArtifact = GetItemQualityColor(ITEM_QUALITY_ARTIFACT)
    local colorLegendary = GetItemQualityColor(ITEM_QUALITY_LEGENDARY)
    local qualityDropDownChoices = {
        [1] = "Off",
        [ITEM_QUALITY_MAGIC] 	 = colorMagic:Colorize(GetString(_G["SI_ITEMQUALITY"  .. tostring(ITEM_QUALITY_MAGIC)])),
        [ITEM_QUALITY_ARCANE] 	 = colorArcane:Colorize(GetString(_G["SI_ITEMQUALITY"  .. tostring(ITEM_QUALITY_ARCANE)])),
        [ITEM_QUALITY_ARTIFACT]  = colorArtifact:Colorize(GetString(_G["SI_ITEMQUALITY"  .. tostring(ITEM_QUALITY_ARTIFACT)])),
        [ITEM_QUALITY_LEGENDARY] = colorLegendary:Colorize(GetString(_G["SI_ITEMQUALITY"  .. tostring(ITEM_QUALITY_LEGENDARY)])),
    }
    FCOChangeStuff.qualityChoices = qualityDropDownChoices
    local qualityDropDownChoicesValues = {
        -1,
        ITEM_QUALITY_MAGIC,
        ITEM_QUALITY_ARCANE,
        ITEM_QUALITY_ARTIFACT,
        ITEM_QUALITY_LEGENDARY,
    }

    FCOChangeStuff.FCOSettingsPanel = FCOChangeStuff.LAM:RegisterAddonPanel(FCOChangeStuff.addonVars.addonName .. "_LAM", panelData)

    local optionsTable =
    {	-- BEGIN OF OPTIONS TABLE

        {
            type = 'description',
            text = 'Change some UI stuff to be hidden or shown in other ways',
        },
        {
            type = 'dropdown',
            name = 'Settings save type',
            tooltip = 'Use account wide settings for all your characters, or save them seperatley for each character?',
            choices = savedVariablesOptions,
            getFunc = function() return savedVariablesOptions[FCOChangeStuff.settingsVars.defaultSettings.saveMode] end,
            setFunc = function(value)
                for i,v in pairs(savedVariablesOptions) do
                    if v == value then
                        FCOChangeStuff.settingsVars.defaultSettings.saveMode = i
                    end
                end
            end,
            requiresReload = true,
        },

        --==============================================================================
        {
            type = 'header',
            name = 'Main menu',
        },
        {
            type = "checkbox",
            name = 'Hide crown store button',
            tooltip = 'Hide the crown store button in the main menu',
            getFunc = function() return settings.hideCrownStoreButtonInMainMenu end,
            setFunc = function(value) settings.hideCrownStoreButtonInMainMenu = value
                --FCOChangeStuff.hideStuff()
            end,
            default = defaults.hideCrownStoreButtonInMainMenu,
            width="full",
        },
        {
            type = "checkbox",
            name = 'Hide crown store points',
            tooltip = 'Hide your crown store points info in the main menu',
            getFunc = function() return settings.hideCrownStorePointsInMainMenu end,
            setFunc = function(value) settings.hideCrownStorePointsInMainMenu = value
                --FCOChangeStuff.hideStuff()
            end,
            default = defaults.hideCrownStorePointsInMainMenu,
            width="full",
        },
        {
            type = "checkbox",
            name = 'Hide crown crates button',
            tooltip = 'Hide the crown crates button in the main menu',
            getFunc = function() return settings.hideCrownCratesButtonInMainMenu end,
            setFunc = function(value) settings.hideCrownCratesButtonInMainMenu = value
                --FCOChangeStuff.hideStuff()
            end,
            default = defaults.hideCrownCratesButtonInMainMenu,
            width="full",
        },
        {
            type = "checkbox",
            name = "Hide 'ESO Plus' membership info",
            tooltip = "Hide the 'ESO Plus' membership info in the main menu",
            getFunc = function() return settings.hideCrownStoreMembershipInMainMenu end,
            setFunc = function(value) settings.hideCrownStoreMembershipInMainMenu = value
                --FCOChangeStuff.hideStuff()
            end,
            default = defaults.hideCrownStoreMembershipInMainMenu,
            width="full",
        },

        --==============================================================================
        {
            type = 'header',
            name = 'Map',
        },
        {
            type = "checkbox",
            name = 'Reopen map upon mounting',
            tooltip = 'If you mount the map will be closed. This option will reopen the map if you were looking at it, as you started to mount.',
            getFunc = function() return settings.reOpenMapOnMounting end,
            setFunc = function(value) settings.reOpenMapOnMounting = value
                FCOChangeStuff.mapStuff("mount")
            end,
            default = defaults.reOpenMapOnMounting,
            width="full",
        },
        {
            type = "checkbox",
            name = 'En-/Disable all filters button',
            tooltip = 'Show two buttons at the worldmap filters: Enable all/Disable all',
            getFunc = function() return settings.showEnDisableAllFilterButtons end,
            setFunc = function(value) settings.showEnDisableAllFilterButtons = value
                FCOChangeStuff.mapStuff("filter")
            end,
            default = defaults.showEnDisableAllFilterButtons,
            width="full",
        },
        {
            type = "checkbox",
            name = 'Player pin: Ping pong effect',
            tooltip = 'If you open the map the player pin will ping pong in it\'s size between big and small. This will work with a keybind (check the controls) as well, even on \'Votans Minimap\'',
            getFunc = function() return settings.pingPongPlayerPinOnMapOpen end,
            setFunc = function(value) settings.pingPongPlayerPinOnMapOpen = value
                FCOChangeStuff.mapStuff("playerpinpingpong")
            end,
            default = defaults.pingPongPlayerPinOnMapOpen,
            width="full",
        },
        {
            type = "checkbox",
            name = 'Hide zone story',
            tooltip = 'Hides the zone story window at the map',
            getFunc = function() return settings.hideMapZoneStory end,
            setFunc = function(value) settings.hideMapZoneStory = value
                FCOChangeStuff.mapStuff("hidezonestory")
            end,
            default = defaults.hideMapZoneStory,
            width="full",
        },
        {
            type = "checkbox",
            name = 'BeamMeUp addon can show zone guide',
            tooltip = 'Allows the addon BeamMeUp to show the zone guid via it\'s toggle again',
            getFunc = function() return settings.hideMapZoneStoryBeamMeUpAllowedToShow end,
            setFunc = function(value) settings.hideMapZoneStoryBeamMeUpAllowedToShow = value
            end,
            default = defaults.hideMapZoneStoryBeamMeUpAllowedToShow,
            disabled = function() return not settings.hideMapZoneStory end,
            width="full",
        },

        --==============================================================================
        {
            type = 'header',
            name = 'Group',
        },
        {
            type = "checkbox",
            name = 'Show real Champion Points',
            tooltip = 'Show the real gained CPs at the level column of your group members & friends list instead of the "maximum value" that ZOs allows to be effective at the moment.',
            getFunc = function() return settings.showRealCPs end,
            setFunc = function(value) settings.showRealCPs = value
                FCOChangeStuff.CPStuff()
            end,
            default = defaults.showRealCPs,
            width="full",
            --requiresReload = true,
        },
        --==============================================================================
        {
            type = 'header',
            name = 'Stable',
        },
        {
            type = "checkbox",
            name = 'Hide feed button: Speed',
            tooltip = 'Hide the stable\'s feed for speed button so you do not accidantly click it',
            getFunc = function() return settings.stableFeedSettings[RIDING_TRAIN_SPEED] end,
            setFunc = function(value) settings.stableFeedSettings[RIDING_TRAIN_SPEED] = value
            end,
            default = defaults.stableFeedSettings[RIDING_TRAIN_SPEED],
            disabled = function() return FCOChangeStuff.stableSkills[RIDING_TRAIN_SPEED].maxed or FCOChangeStuff.checkIfOtherStableButtonsAreMaxedOut(RIDING_TRAIN_SPEED) end,
            width="full",
            --requiresReload = true,
        },
        {
            type = "checkbox",
            name = 'Hide feed button: Stamina',
            tooltip = 'Hide the stable\'s feed for stamina button so you do not accidantly click it',
            getFunc = function() return settings.stableFeedSettings[RIDING_TRAIN_STAMINA] end,
            setFunc = function(value) settings.stableFeedSettings[RIDING_TRAIN_STAMINA] = value
            end,
            default = defaults.stableFeedSettings[RIDING_TRAIN_STAMINA],
            disabled = function() return FCOChangeStuff.stableSkills[RIDING_TRAIN_STAMINA].maxed or FCOChangeStuff.checkIfOtherStableButtonsAreMaxedOut(RIDING_TRAIN_STAMINA) end,
            width="full",
            --requiresReload = true,
        },
        {
            type = "checkbox",
            name = 'Hide feed button: Carry',
            tooltip = 'Hide the stable\'s feed for carry button so you do not accidantly click it',
            getFunc = function() return settings.stableFeedSettings[RIDING_TRAIN_CARRYING_CAPACITY] end,
            setFunc = function(value) settings.stableFeedSettings[RIDING_TRAIN_CARRYING_CAPACITY] = value
            end,
            default = defaults.stableFeedSettings[RIDING_TRAIN_CARRYING_CAPACITY],
            disabled = function() return FCOChangeStuff.stableSkills[RIDING_TRAIN_CARRYING_CAPACITY].maxed or FCOChangeStuff.checkIfOtherStableButtonsAreMaxedOut(RIDING_TRAIN_CARRYING_CAPACITY) end,
            width="full",
            --requiresReload = true,
        },
        --==============================================================================
        {
            type = 'header',
            name = 'Main menu',
        },
        {
            type = "checkbox",
            name = 'Show addon settings button',
            tooltip = 'Show a button at the main menu which directly opens the LAM addon settings.\n\nThis button won\'t be shown if you got "Votan\'s settings menu" addon enabled!',
            getFunc = function() return settings.showAddonSettingsMainMenuButton end,
            setFunc = function(value) settings.showAddonSettingsMainMenuButton = value
            end,
            default = defaults.showAddonSettingsMainMenuButton,
            width="full",
            disabled = function() return VOTANS_MENU_SETTINGS and VOTANS_MENU_SETTINGS:IsMenuButtonEnabled() end,
            requiresReload = true,
        },
        --==============================================================================
        {
            type = 'header',
            name = 'Crafting',
        },
        {
            type = "checkbox",
            name = 'Create: Add armor type switch button',
            tooltip = 'Add a button to the crafting stations create panel to switch between light & medium armor',
            getFunc = function() return settings.smithingCreationAddArmorTypeSwitchButton end,
            setFunc = function(value) settings.smithingCreationAddArmorTypeSwitchButton = value
                FCOChangeStuff.smithingCreateAddArmorTypeSwitchButton()
            end,
            default = defaults.smithingCreationAddArmorTypeSwitchButton,
            width="full",
        },
--[[
        {
            type = "checkbox",
            name = 'Improvement with 100%',
            tooltip = 'Automatically try to set the improvement mats used to the maximum so you get a 100% chance',
            getFunc = function() return settings.improvementWith100Percent end,
            setFunc = function(value) settings.improvementWith100Percent = value
                if value then
                    FCOChangeStuff.smithingImproveTrySet100PercentChance()
                end
            end,
            default = defaults.improvementWith100Percent,
            width="full",
        },
]]
        {
            type = "dropdown",
            name = 'Block improvement to quality >=',
            tooltip = 'Block the improvement of items to the chosen, or higher, qualities (=improved item\'s new quality).\n\nAll qualities below the chosen one can be the result of your improvement. But the chosen quality and above (if any above exists) are blocked and wont be allowed.\nA chat message tells you that the item was blocked.',
            choices = qualityDropDownChoices,
            choicesValues = qualityDropDownChoicesValues,
            getFunc = function() return settings.improvementBlockQuality end,
            setFunc = function(value)
                settings.improvementBlockQuality = value
            end,
            default = defaults.improvementBlockQuality,
            width="half",
        },
        {
            type = "checkbox",
            name = 'Allow with SHIFT key',
            tooltip = 'Allow the improvement of the item if you hold the SHIFT key down as you try to improve the item.\n\nAttention: The standard keybinding to start the improvement cannot be used if you press the SHIFT key as SHIFT+E is another keybind then E!\n\nYou need to hold the SHIFT key until the improvement of the item starts! So you need to hold it while clicking on the improve button, and if the dialog asking you \'Are sure to improve the item?\' is used you also need to hold the SHIFT key if you press the dialog\'s  \'Accept\' button!',
            getFunc = function() return settings.improvementBlockQualityExceptionShiftKey end,
            setFunc = function(value) settings.improvementBlockQualityExceptionShiftKey = value
            end,
            default = defaults.improvementBlockQualityExceptionShiftKey,
            disabled = function() return settings.improvementBlockQuality == -1 end,
            width="half",
        },

        {
            type = "checkbox",
            name = 'Change sound volume',
            tooltip = 'Change the sound volume of the game as you start the interaction with a crafting station.\nThe volume will be reset to the value before again as you leave the crafting station.',
            getFunc = function() return settings.changeSoundAtCrafting end,
            setFunc = function(value) settings.changeSoundAtCrafting = value
                FCOChangeStuff.soundLowerAtCraftingCheck()
            end,
            default = defaults.changeSoundAtCrafting,
            width="full",
        },
        {
            type = "slider",
            name = "Crafting sound volume",
            tooltip = "Set the general game volume to this volume level during your craft activities.",
            min = 0,
            max = 100,
            decimals = 0,
            autoSelect = true,
            getFunc = function() return settings.changeSoundAtCraftingVolume end,
            setFunc = function(volumeLevel)
                settings.changeSoundAtCraftingVolume = volumeLevel
            end,
            default = defaults.changeSoundAtCraftingVolume,
            width="full",
            disabled = function() return not settings.changeSoundAtCrafting end,
        },

        --==============================================================================
        {
            type = 'header',
            name = 'Inventory',
        },
        {
            type = "checkbox",
            name = 'Remove \"New item\" icon & animation',
            tooltip = 'Remove the animation and icon for new items in the inventories',
            getFunc = function() return settings.removeNewItemIcon end,
            setFunc = function(value) settings.removeNewItemIcon = value
            end,
            default = defaults.removeNewItemIcon,
            width="full",
        },
        {
            type = "checkbox",
            name = 'Remove \"Not sellable item\" icon & animation',
            tooltip = 'Remove the animation and icon for items which are not sellable at a vendor',
            getFunc = function() return settings.removeSellItemIcon end,
            setFunc = function(value) settings.removeSellItemIcon = value
            end,
            default = defaults.removeSellItemIcon,
            width="full",
        },
        --==============================================================================
        {
            type = 'header',
            name = 'Chat',
        },
        {
            type = "checkbox",
            name = 'Disable notification animation',
            tooltip = 'Disable the animation which makes the notifications button glow if new notifications are unread.',
            getFunc = function() return settings.disableChatNotificationAnimation end,
            setFunc = function(value) settings.disableChatNotificationAnimation = value
                FCOChangeStuff.chatDisableNotificationAnimation()
            end,
            default = defaults.disableChatNotificationAnimation,
            width="full",
        },
        {
            type = "checkbox",
            name = 'Disable new notification sound',
            tooltip = 'Disable the sound for new notifications.',
            getFunc = function() return settings.disableChatNotificationSound end,
            setFunc = function(value) settings.disableChatNotificationSound = value
                FCOChangeStuff.chatDisableNotificationSound()
            end,
            default = defaults.disableChatNotificationSound,
            width="full",
        },
        {
            type = "checkbox",
            name = 'Blacklist chat texts',
            tooltip = 'Enter chat texts in the edit box below. Each row (split by a carriage return) is one text which will be searched in the incoming chat messages. If the text is found the whole chat message will be not shown to you!\n\nEnabling/Disabling this function needs you to reload the UI!',
            getFunc = function() return settings.enableChatBlacklist end,
            setFunc = function(value) settings.enableChatBlacklist = value
            end,
            default = defaults.enableChatBlacklist,
            requiresReload = true,
            width="full",
        },
        {
            type = "editbox",
            name = "Chat blacklist key words/text",
            tooltip = "Enter the text messages, or parts/words of the messages here, which should be blacklisted in the chat.\nEach new word/phrase needs to be seperated via the carriage return (line feed/return key)!",
            isMultiline = true,
            getFunc = function()
                return settings.chatKeyWords
            end,
            setFunc = function(value)
                settings.chatKeyWords = value
                FCOChangeStuff.blacklistKeyWords = { zo_strsplit("\n", value) }
            end,
            default = defaults.chatKeyWords,
            disabled = function() return not settings.enableChatBlacklist end,
        },
        {
            type = "checkbox",
            name = 'Blacklist whispers',
            tooltip = 'Should incoming whisper messages be checked against your blacklist too?',
            getFunc = function() return settings.enableChatBlacklistForWhispers end,
            setFunc = function(value) settings.enableChatBlacklistForWhispers = value
            end,
            default = defaults.enableChatBlacklistForWhispers,
            disabled = function() return not settings.enableChatBlacklist end,
            width="full",
        },
        {
            type = "checkbox",
            name = 'Blacklist group',
            tooltip = 'Should incoming group messages be checked against your blacklist too?',
            getFunc = function() return settings.enableChatBlacklistForGroup end,
            setFunc = function(value) settings.enableChatBlacklistForGroup = value
            end,
            default = defaults.enableChatBlacklistForGroup,
            disabled = function() return not settings.enableChatBlacklist end,
            width="full",
        },
        {
            type = "checkbox",
            name = 'Blacklist guilds',
            tooltip = 'Should incoming guild and officer messages be checked against your blacklist too?',
            getFunc = function() return settings.enableChatBlacklistForGuilds end,
            setFunc = function(value) settings.enableChatBlacklistForGuilds = value
            end,
            default = defaults.enableChatBlacklistForGuilds,
            disabled = function() return not settings.enableChatBlacklist end,
            width="full",
        },
        {
            type = "checkbox",
            name = 'Show info in chat',
            tooltip = 'Show the time, posting person, text and found keyword of the blacklisted text in the system chat (addon output)?',
            getFunc = function() return settings.blacklistedTextToChat end,
            setFunc = function(value) settings.blacklistedTextToChat = value
            end,
            default = defaults.blacklistedTextToChat,
            disabled = function() return not settings.enableChatBlacklist end,
            width="full",
        },
        {
            type = "checkbox",
            name = 'Reminder: Whisper & flagged offline',
            tooltip = 'Show a reminder message on screen if you are whispering to someone and are flagged as offline',
            getFunc = function() return settings.enableChatWhisperAndFlaggedAsOfflineReminder end,
            setFunc = function(value) settings.enableChatWhisperAndFlaggedAsOfflineReminder = value
                FCOChangeStuff.chatWhisperAndFlaggedAsOffline()
            end,
            default = defaults.enableChatWhisperAndFlaggedAsOfflineReminder,
            width="full",
        },

        --==============================================================================
        {
            type = 'header',
            name = 'Skill lines',
        },
        {
            type = "checkbox",
            name = 'Enable skill line context menu',
            tooltip = 'Enables the context menu at skill line headers (e.g. \"Bow\").',
            getFunc = function() return settings.enableSkillLineContextMenu end,
            setFunc = function(value) settings.enableSkillLineContextMenu = value
            end,
            default = defaults.enableSkillLineContextMenu,
            width="full",
        },
        --==============================================================================
        {
            type = 'header',
            name = 'Login/Reloadui',
        },
        {
            type = "checkbox",
            name = 'Remove enlightened sound',
            tooltip = 'Silence the enlightened sound upon login/reloadui',
            getFunc = function() return settings.noEnlightenedSound end,
            setFunc = function(value) settings.noEnlightenedSound = value
                FCOChangeStuff.noEnlightenedSound()
            end,
            default = defaults.noEnlightenedSound,
            width="full",
        },
        {
            type = "checkbox",
            name = 'Hide crown store advertisements',
            tooltip = 'Hide the crown store advertisements popup after login',
            getFunc = function() return settings.noShopAdvertisementPopup end,
            setFunc = function(value) settings.noShopAdvertisementPopup = value
                FCOChangeStuff.noShopAdvertisement()
            end,
            default = defaults.noShopAdvertisementPopup,
            width="full",
        },
        --==============================================================================
        {
            type = 'header',
            name = 'Battleground',
        },
        {
            type = "checkbox",
            name = 'Make HUD movable',
            tooltip = 'Enable the mouse drag&drop move of the battleground HUD',
            getFunc = function() return settings.enableBGHUDMoveable end,
            setFunc = function(value) settings.enableBGHUDMoveable = value
                FCOChangeStuff.BGHUDMoveable()
            end,
            default = defaults.enableBGHUDMoveable,
            width="full",
        },
        {
            type = "button",
            name = 'Reset x & y',
            tooltip = 'Reset the x & y coordinates of the battleground HUD to their default values',
            func = function(value)
                FCOChangeStuff.BGHUDReset()
            end,
            isDangerous = true,
            width = "full",
            warning = "Do you really want to reset the x & y coordinates?",
        },
        --==============================================================================
        {
            type = 'header',
            name = 'Keybinds',
        },
        {
            type = "checkbox",
            name = 'Compass quest givers',
            tooltip = 'Enable/Disable keybind to toggle the setings for compass quest givers',
            getFunc = function() return settings.enableKeybindCompassQuestGivers end,
            setFunc = function(value) settings.enableKeybindCompassQuestGivers = value
            end,
            default = defaults.enableKeybindCompassQuestGivers,
            width="full",
        },
    } -- optionsTable
    -- END OF OPTIONS TABLE
    FCOChangeStuff.LAM:RegisterOptionControls(FCOChangeStuff.addonVars.addonName .. "_LAM", optionsTable)
end
