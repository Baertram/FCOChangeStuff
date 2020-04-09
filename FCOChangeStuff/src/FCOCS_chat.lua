if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS
FCOChangeStuff.chatHookDone = false

local myPlayerName = ""
local myPlayerNameRaw = ""
local myAccountName = ""
local secondsSinceMidnight = 0
local FCOCS_OnChatEventOriginal
local origNewNotificationSound

--Each time a chat message comes in this function will be called
local function FCOCS_ChatMessageChannel(messageType, fromNameFormatted, msgText)
--d("FCOCS_ChatMessageChannel: [" .. tostring(fromNameFormatted) .. "] " .. tostring(msgText))
    --Do not check for friend amd don't parse message text if a monster/NPC is speaking.
    local settings = FCOChangeStuff.settingsVars.settings
    local messageText = string.gsub(msgText, '([%[%]%%%(%)%{%}%$%^%+])', '[%%%1]')
    local keyWords = FCOChangeStuff.blacklistKeyWords or { zo_strsplit("\n", settings.chatKeyWords) }
    if keyWords == nil or #keyWords == 0 then return false end
    local textFound = false
    local keyWordFound = ""
    for _,keyWord in ipairs(keyWords) do
        keyWord = string.gsub(keyWord, '([%[%]%%%(%)%{%}%$%^%+])', '[%%%1]')
        local lowerMsg = string.lower(messageText) or "noMsgText"
        local lowerKeyword = string.lower(keyWord) or "noKeyWord"
        if string.match(lowerMsg, lowerKeyword) then
            textFound = true
            keyWordFound = keyWord
            break -- end the for...loop...
        end
    end
    --Text was found, hide the chat text now
    if textFound then
        --Show chat output for blacklisted text?
        if settings.blacklistedTextToChat then
            local chatChannelTexts = {
                [CHAT_CHANNEL_GUILD_1] = "Guild 1",
                [CHAT_CHANNEL_GUILD_2] = "Guild 2",
                [CHAT_CHANNEL_GUILD_3] = "Guild 3",
                [CHAT_CHANNEL_GUILD_4] = "Guild 4",
                [CHAT_CHANNEL_GUILD_5] = "Guild 5",
                [CHAT_CHANNEL_OFFICER_1] = "Officer 1",
                [CHAT_CHANNEL_OFFICER_2] = "Officer 2",
                [CHAT_CHANNEL_OFFICER_3] = "Officer 3",
                [CHAT_CHANNEL_OFFICER_4] = "Officer 4",
                [CHAT_CHANNEL_OFFICER_5] = "Officer 5",
                [CHAT_CHANNEL_PARTY] = "Group",
                [CHAT_CHANNEL_SAY] = "Say",
                [CHAT_CHANNEL_USER_CHANNEL_1] = "User channel 1",
                [CHAT_CHANNEL_USER_CHANNEL_2] = "User channel 2",
                [CHAT_CHANNEL_USER_CHANNEL_3] = "User channel 3",
                [CHAT_CHANNEL_USER_CHANNEL_4] = "User channel 4",
                [CHAT_CHANNEL_USER_CHANNEL_5] = "User channel 5",
                [CHAT_CHANNEL_USER_CHANNEL_6] = "User channel 6",
                [CHAT_CHANNEL_USER_CHANNEL_7] = "User channel 7",
                [CHAT_CHANNEL_USER_CHANNEL_8] = "User channel 8",
                [CHAT_CHANNEL_USER_CHANNEL_9] = "User channel 9",
                [CHAT_CHANNEL_WHISPER] = "Whisper",
                [CHAT_CHANNEL_YELL] = "Yell",
                [CHAT_CHANNEL_ZONE] = "Zone",
                [CHAT_CHANNEL_ZONE_LANGUAGE_1] = "ZoneEN",
                [CHAT_CHANNEL_ZONE_LANGUAGE_2] = "ZoneFR",
                [CHAT_CHANNEL_ZONE_LANGUAGE_3] = "ZoneDE",
                [CHAT_CHANNEL_ZONE_LANGUAGE_4] = "ZoneJP",
            }
            local chatChannelText = chatChannelTexts[messageType] or "<unknown>"
            local isENClient = (GetCVar("Language.2") == "en") or false
            local lCLOCK_FORMAT = (isENClient and TIME_FORMAT_PRECISION_TWELVE_HOUR) or TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR
            local lTIME_FORMAT = (isENClient and TIME_FORMAT_STYLE_CLOCK_TIME) or TIME_FORMAT_STYLE_COLONS
            local postingTime = ZO_FormatTime(secondsSinceMidnight, lTIME_FORMAT, lCLOCK_FORMAT)
            d(zo_strformat("<<1>>: [FCOCS]Blacklisted \"<<2>>\" in message \"<<3>>\", posted by \"<<4>>\" in channel \"<<5>>\"", postingTime, keyWordFound, msgText, fromNameFormatted, chatChannelText))
        end
--d("<<<return FOUND=true")
        --Abort the output of the chat message
        return true
    end
    --Show the text message
    return false
end

--The blacklist method
--messageType, fromName, text, isFromCustomerService, fromDisplayName
local function FCOCS_FilterChatMessage(eventType, messageType, fromName, chatText, isFromCustomerService, fromDisplayName)
    if eventType ~= EVENT_CHAT_MESSAGE_CHANNEL then
        return false
    end
--d(">eventType = chat message channel")
    --Format message poster
    local postingPerson   = zo_strformat(SI_UNIT_NAME, fromName)
    --d("MyPlayerName: " .. myPlayerName .. " (" .. myPlayerNameRaw .. "), MyAccountName: " .. myAccountName .. " / fromName: " .. postingPerson .. " (" .. fromName .. ")")
    --Is the chat message sent by myself? Abort then
    if fromName == myAccountName or postingPerson == myAccountName or fromName == myPlayerNameRaw or postingPerson == myPlayerName then
        return false
    end
--d(">not from myself")
    --Do not filter chat messages from NPCs/Monsters
    if    messageType ~= CHAT_CHANNEL_SYSTEM
      and messageType ~= CHAT_CHANNEL_MONSTER_SAY
      and messageType ~= CHAT_CHANNEL_MONSTER_YELL
      and messageType ~= CHAT_CHANNEL_MONSTER_EMOTE
      and messageType ~= CHAT_CHANNEL_MONSTER_WHISPER
      and messageType ~= CHAT_CHANNEL_EMOTE
      and messageType ~= CHAT_CHANNEL_WHISPER_SENT
    then
--d(">>chat channel is allowed")
        local settings = FCOChangeStuff.settingsVars.settings
        --Chat blacklist is enabled for whispers?
        if not settings.enableChatBlacklistForWhispers and messageType == CHAT_CHANNEL_WHISPER then return false end
        --Chat blacklist is enabled for group?
        if not settings.enableChatBlacklistForGroup and messageType == CHAT_CHANNEL_PARTY then return false end
        --Chat blacklist is enabled for guilds?
        if not settings.enableChatBlacklistForGuilds and (
               messageType == CHAT_CHANNEL_GUILD_1
            or messageType == CHAT_CHANNEL_GUILD_2
            or messageType == CHAT_CHANNEL_GUILD_3
            or messageType == CHAT_CHANNEL_GUILD_4
            or messageType == CHAT_CHANNEL_GUILD_5
            or messageType == CHAT_CHANNEL_OFFICER_1
            or messageType == CHAT_CHANNEL_OFFICER_2
            or messageType == CHAT_CHANNEL_OFFICER_3
            or messageType == CHAT_CHANNEL_OFFICER_4
            or messageType == CHAT_CHANNEL_OFFICER_5
        ) then return false end
--d(">>got here, settings ok")
        --Filter the chta messages now
        local blacklistChatmessage = FCOCS_ChatMessageChannel(messageType, postingPerson, chatText) or false
        return blacklistChatmessage
    end
    return false
end

--The chat event method
--control, formattedEventText, category, targetChannel, fromDisplayName, rawMessageText
local function FCOCS_OnChatEvent(control, ...)
    --Setting enabled?
    secondsSinceMidnight = 0
    local settings = FCOChangeStuff.settingsVars.settings
    if settings.enableChatBlacklist and settings.chatKeyWords ~= nil and settings.chatKeyWords ~= "" then
--d("[FCOCS]OnChatEvent - With Blacklist")
        if settings.blacklistedTextToChat then
            --Get the current time
            secondsSinceMidnight = GetSecondsSinceMidnight()
        end
        --Filter the incoming chat message now
        local chatMessageWasBlacklisted = FCOCS_FilterChatMessage(...) or false
        if chatMessageWasBlacklisted then
            --Abort the chat event function so no text is shown in the chat
            return true
        end
    end
    --Call the original chat event method now to show the text in the chat
--d("[FCOCS]OnOrigChatEvent")
    FCOCS_OnChatEventOriginal(control, ...)
end

--Enable the chat blacklist event
function FCOChangeStuff.chatBlacklist()
    local settings = FCOChangeStuff.settingsVars.settings
    if not settings.enableChatBlacklist then return false end
    --Was the chat hook already done once?
    if not FCOChangeStuff.chatHookDone then
        --Set some addon wide varibales which do not change
        myPlayerName    = GetUnitName("player")
        myPlayerNameRaw = GetRawUnitName("player")
        myAccountName   = GetDisplayName()

        --Save the original chat event method
        FCOCS_OnChatEventOriginal = CHAT_SYSTEM.OnChatEvent
        --Overwrite it with our own now
        CHAT_SYSTEM.OnChatEvent = FCOCS_OnChatEvent
        FCOChangeStuff.chatHookDone = true
    end
end

--Do the chat whisper and CSA check
local function chatWhisperCheck()
    --* GetPlayerStatus()
    --** _Returns:_ *[PlayerStatus|#PlayerStatus]* _status_
    --* PLAYER_STATUS_AWAY
    --* PLAYER_STATUS_DO_NOT_DISTURB
    --* PLAYER_STATUS_OFFLINE
    --* PLAYER_STATUS_ONLINE
    local playerStatus = GetPlayerStatus()
    if playerStatus ~= PLAYER_STATUS_OFFLINE then return end
    --Player is flagged as offline
    local alertTextWhisperButFlagegdOffline = "--- YOUR STATUS IS: \'OFFLINE\'! NO INCOMING WHISPERs POSSIBLE! ---"
    if alertTextWhisperButFlagegdOffline ~= "" then
        --Show CSA mesage now on screen
        local params = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_SMALL_TEXT, SOUNDS.NONE)
        params:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_DISPLAY_ANNOUNCEMENT )
        params:SetText(alertTextWhisperButFlagegdOffline)
        CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(params)
    end
end

--Enable the reminder for "offline" whispers
function FCOChangeStuff.chatWhisperAndFlaggedAsOffline()
    --Register the event for the chat
    if FCOChangeStuff.chatWhisperAsOfflineHookDone then return end
    FCOChangeStuff.chatWhisperAsOfflineHookDone = true
    ZO_PreHook(CHAT_SYSTEM, "StartTextEntry", function(ctrl, text, channel, target, showVirtualKeyboard)
        local settings = FCOChangeStuff.settingsVars.settings
        if not settings.enableChatWhisperAndFlaggedAsOfflineReminder then return false end
        --Get the current chat channel
        local currentChannel = 0
        if CHAT_SYSTEM and CHAT_SYSTEM.currentChannel then
            currentChannel = CHAT_SYSTEM.currentChannel
        end
        --d("[FCOCS]StartTextEntry, text: " ..tostring(text) .. ", channel: " ..tostring(channel) .. ", currentChannel: " ..tostring(currentChannel))
        --If we are whispering
        if currentChannel == CHAT_CHANNEL_WHISPER then
            chatWhisperCheck()
        end
        return false
    end)
end


--Disable the chat's notification animation and sound
function FCOChangeStuff.chatDisableNotificationAnimation()
    local settings = FCOChangeStuff.settingsVars.settings
    if settings.disableChatNotificationAnimation then
        CHAT_SYSTEM.notificationPulseTimeline:Stop()
        ZO_ChatWindowNotificationsEcho:SetHidden(true)
    else
        ZO_ChatWindowNotificationsEcho:SetHidden(false)
        if CHAT_SYSTEM.currentNumNotifications and CHAT_SYSTEM.currentNumNotifications > 0 then
            CHAT_SYSTEM.notificationPulseTimeline:PlayFromStart()
        end
    end
end

--Disable the chat's notification animation and sound
function FCOChangeStuff.chatDisableNotificationSound()
    local settings = FCOChangeStuff.settingsVars.settings
    if settings.disableChatNotificationSound then
        origNewNotificationSound = SOUNDS["NEW_NOTIFICATION"]
        SOUNDS["NEW_NOTIFICATION"] = SOUNDS["NONE"]
    else
        SOUNDS["NEW_NOTIFICATION"] = origNewNotificationSound
    end
end

--Disable the chat's notification animation and sound
function FCOChangeStuff.chatDisableNotificationStuff()
    FCOChangeStuff.chatDisableNotificationAnimation()
    FCOChangeStuff.chatDisableNotificationSound()
end
