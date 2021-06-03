if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

FCOChangeStuff.addonVars = {}
local addonVars = FCOChangeStuff.addonVars
addonVars.addonVersion		        = 0.195
addonVars.addonSavedVarsVersion	    = "0.02"
addonVars.addonName				    = "FCOChangeStuff"
addonVars.addonNameMenu  		    = "FCO ChangeStuff"
addonVars.addonNameMenuDisplay	    = "|c00FF00FCO |cFFFF00 ChangeStuff|r"
addonVars.addonSavedVariablesName    = "FCOChangeStuff_Settings"
addonVars.settingsName   		    = "FCO ChangeStuff"
addonVars.addonAuthor			    = "Baertram"
addonVars.addonWebsite               = "https://www.esoui.com/downloads/info1542-FCOChangeStuff.html"
addonVars.addonFeedback              = "https://www.esoui.com/portal.php?uid=2028"
addonVars.addonDonation              = "https://www.esoui.com/portal.php?id=136&a=faq&faqid=131"

FCOChangeStuff.settingsVars = {}
FCOChangeStuff.settingsVars.defaultSettings = {}
FCOChangeStuff.settingsVars.settings = {}
FCOChangeStuff.settingsVars.defaults = {}

FCOChangeStuff.worldMapShown			= false

FCOChangeStuff.ctrlVars = {}
FCOChangeStuff.ctrlVars.smithingCreatePanel                 = ZO_SmithingTopLevelCreationPanel
FCOChangeStuff.ctrlVars.smithingCreatePanelPatternListTitle = ZO_SmithingTopLevelCreationPanelPatternListTitle
FCOChangeStuff.ctrlVars.smithingCreatePanelPatternListList  = ZO_SmithingTopLevelCreationPanelPatternListList

FCOChangeStuff.playerActivatedDone = false
FCOChangeStuff.gameMenuSceneActive = false

FCOChangeStuff.otherAddons = {}
FCOChangeStuff.otherAddons.PerfectPixel = false

local function disableOldSettings()
    --The 100% improvement was added into base game code with update to API100023 "Summerset"
    FCOChangeStuff.settingsVars.settings.improvementWith100Percent = false
end

--Keybinds callback function
function FCOChangeStuff.keybinds(keybindType)
    if keybindType == nil or keybindType == "" then return end
    local settings = FCOChangeStuff.settingsVars.settings
    --Toggle the settings quest giver on compass
    if keybindType == "FCOCS_TOGGLE_SETTINGS_COMPASS_QUEST_GIVERS" then
        if settings.enableKeybindCompassQuestGivers then
            --Get the current setting
            local currentSettingCompassQustGivers = tonumber(GetSetting(SETTING_TYPE_UI, UI_SETTING_COMPASS_QUEST_GIVERS))
            if currentSettingCompassQustGivers and currentSettingCompassQustGivers ~= "" then
                --Invert the number between 0 and 1
                if currentSettingCompassQustGivers == 0 then currentSettingCompassQustGivers = 1
                elseif currentSettingCompassQustGivers == 1 then currentSettingCompassQustGivers = 0 end
                if currentSettingCompassQustGivers then
                    --Set the new setting
                    SetSetting(SETTING_TYPE_UI, UI_SETTING_COMPASS_QUEST_GIVERS, tostring(currentSettingCompassQustGivers))
                end
            end
        end
    end
end

--Player activated function
function FCOChangeStuff.Player_Activated(...)
    --Save the currently used audio volume levels
    FCOChangeStuff.saveVolumeLevels(SETTING_TYPE_AUDIO, AUDIO_SETTING_AUDIO_VOLUME)

    --Reset the counter for the group list
    FCOChangeStuff.runGroupListCounter = 0

    --Disable some old/deprecated settings
    disableOldSettings()

    --Do stuff directly after login/reloadui
    FCOChangeStuff.afterLoginOrReloaduiFunctions()
    --Hide the other stuff
    FCOChangeStuff.hideStuff()
    --change map stuff
    FCOChangeStuff.mapStuff("all")
    --change group list stuff
    FCOChangeStuff.CPStuff()
    --Hook the stable scene
    FCOChangeStuff.hookStableScene()
    --Add the crafting modifications
    FCOChangeStuff.craftingModifications()
    --Add the slash commands
    FCOChangeStuff.slashCommands()
    --Add main menu buttons
    FCOChangeStuff.addMainMenuButtons()
    --Inventory hacks (new item, not sellable item)
    FCOChangeStuff.inventoryChanges()
    --Bank hacks
    FCOChangeStuff.bankChanges()
    --Chat blacklist: Only loaded after ReloadUI
    --Prepare the keywords once
    local settings = FCOChangeStuff.settingsVars.settings
    FCOChangeStuff.blacklistKeyWords = { zo_strsplit("\n", settings.chatKeyWords) }
    --Prepare the chat blacklist messages hook
    FCOChangeStuff.chatBlacklist()
    --Chat notification stuff
    FCOChangeStuff.chatDisableNotificationStuff()
    --Chat CSA message if whisper but status is offline
    FCOChangeStuff.chatWhisperAndFlaggedAsOffline()
    --Prepare the battleground changes
    --Save the standard anchor of the BGHUD
    FCOChangeStuff.BGHUDStandardSave()
    --Apply the modifications for the BG now
    FCOChangeStuff.bgModifications()
    --Apply the mount related stuff
    FCOChangeStuff.mountChanges()
    --Apply the group election stuff
    FCOChangeStuff.GroupElectionStuff()
    --Apply the sound related stuff
    --FCOChangeStuff.soundChanges()
    --Apply the tooltip related stuff
    FCOChangeStuff.tooltipChanges()
    --Apply the snap cursor changes
    FCOChangeStuff.snapCursor("-ALL-")
    --Apply the skill window changes
    FCOChangeStuff.skillChanges()

    FCOChangeStuff.playerActivatedDone = true
end

function FCOChangeStuff.addonLoaded(eventName, addon)
    if addon == "PerfectPixel" then
        FCOChangeStuff.otherAddons.PerfectPixel = true
    end
    if addon ~= addonVars.addonName then return end
    EVENT_MANAGER:UnregisterForEvent(eventName)

    --Register for the zone change/player ready event
    EVENT_MANAGER:RegisterForEvent(addonVars.addonName, EVENT_PLAYER_ACTIVATED, FCOChangeStuff.Player_Activated)

    --Save the original CP function
    FCOChangeStuff.originalUnitCPEffectiveFunc  = GetUnitEffectiveChampionPoints
    FCOChangeStuff.originalUnitCPFunc           = GetUnitChampionPoints
    FCOChangeStuff.originalCPFunc               = GetLevelOrChampionPointsStringNoIcon

    --Get the SavedVariables
    FCOChangeStuff.getSettings()

    --Check and set the enlightened sound
    FCOChangeStuff.noEnlightenedSound()

    --LibShifterBox
    FCOChangeStuff.LSB = LibShifterBox
    --Create the settings panel object of libAddonMenu 2.0
    FCOChangeStuff.LAM = LibAddonMenu2
    --Build the LAM settings panel
    FCOChangeStuff.buildAddonMenu()

    --EVENTS
    --Crafting station interact
    EVENT_MANAGER:RegisterForEvent(addonVars.addonName, EVENT_CRAFTING_STATION_INTERACT, FCOChangeStuff.OnEventCraftingStationOpened)
end

function FCOChangeStuff.initialize()
    EVENT_MANAGER:RegisterForEvent(addonVars.addonName, EVENT_ADD_ON_LOADED, FCOChangeStuff.addonLoaded)
end

--Load the addon
FCOChangeStuff.initialize()