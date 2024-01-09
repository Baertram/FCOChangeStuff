if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

local addonNameShortColored

local EM = EVENT_MANAGER
local tos = tostring
local strf = string.find
local strlow = string.lower

local playerTag = "player"
local ownDisplayName = GetDisplayName()

local parseSlashCommands = FCOChangeStuff.ParseSlashCommands

local LCM = LibCustomMenu



--FCOCS - Teleport functions
function FCOChangeStuff.CanTeleport()
    local canTeleportNow = (not IsUnitDead(playerTag) and CanLeaveCurrentLocationViaTeleport()) or false
--("[FCOCS]CanTeleport: " ..tos(canTeleportNow))
    return canTeleportNow
end
local canTeleport = FCOChangeStuff.CanTeleport

local portToDisplayname
local wasUnmounted = false
local function onMountStateChangedTeleport(mounted, displayName, portType, guildIndex)
--d("[FCOCS]onMountStateChangedTeleport-mounted: " ..tos(mounted) ..", displayName: " ..tos(displayName) .. ", portType: " ..tos(portType) .. ", guildIndex: " ..tos(guildIndex))
    EM:UnregisterForEvent("FCOCS_EVENT_MOUNTED_STATE_CHANGED_teleport", EVENT_MOUNTED_STATE_CHANGED)
    if mounted == false then
--d(">porting now after unmounting")
        portToDisplayname = portToDisplayname or FCOChangeStuff.PortToDisplayname
        wasUnmounted = true
        portToDisplayname(displayName, portType, guildIndex)
    end
end

local function jumpToDisplayNameByPortTypeNow(displayName, portType)
    if portType == "groupLeader" then
        JumpToGroupLeader()
    elseif portType == "group" then
        JumpToGroupMember(displayName)
    elseif portType == "friend" then
        JumpToFriend(displayName)
    elseif portType == "guild" then
        JumpToGuildMember(displayName)
    end
end

function FCOChangeStuff.PortToDisplayname(displayName, portType, guildIndex)
    local isCurrentlyMounted = IsMounted()
--d("[FCOCS]PortToDisplayname-displayName: " ..tos(displayName) .. ", portType: " ..tos(portType) .. ", guildIndex: " ..tos(guildIndex) ..", isMounted: " ..tos(isCurrentlyMounted))
    if displayName == nil or displayName == "" then return end
    portToDisplayname = portToDisplayname or FCOChangeStuff.PortToDisplayname
    if not canTeleport() then return end

    CancelCast()

    --Start the teleporting now
    if wasUnmounted == true or isCurrentlyMounted == false then
        wasUnmounted = false
        local teleportToName = (
                (portType == "groupLeader" and tos(displayName) .. " (Group leader)")
                        or (portType == "group" and tos(displayName) .. " (Group member)")
                        or (portType == "friend" and tos(displayName) .. " (Friend)")
                        or (portType == "guild" and ((guildIndex ~= nil and tos(displayName) .. " (Guild #" .. tos(guildIndex)..")") or (tos(displayName) .. " (Guild)")))
        )
                or tos(displayName)
        addonNameShortColored = FCOChangeStuff.addonVars.addonNameShortColored
        d("["..addonNameShortColored.."]Teleporting to: " .. teleportToName)

        jumpToDisplayNameByPortTypeNow(displayName, portType)

        return true
    else
        --Player get's unmounted on first call, so repeat the port again with a delay
        --zo_callLater(function() portToDisplayname(displayName, portType) end, 1250)
        -->No delay here, use mount state changed event and recall the teleport then
        EM:RegisterForEvent("FCOCS_EVENT_MOUNTED_STATE_CHANGED_teleport", EVENT_MOUNTED_STATE_CHANGED, function(eventId, mounted)
            onMountStateChangedTeleport(mounted, displayName, portType, guildIndex)
        end)

        jumpToDisplayNameByPortTypeNow(displayName, portType)
        CancelCast()

        return false
    end
end
portToDisplayname = FCOChangeStuff.PortToDisplayname

local function isDisplayName(str)
    return IsDecoratedDisplayName(str)
end

local currentlySelectedGuildData = {}
local function resetGuildToOldData()
    --EM:UnregisterForEvent("FCOCS_EVENT_GUILD_DATA_LOADED", EVENT_GUILD_DATA_LOADED)
--d("[FCOCS]resetGuildToOldData: " ..tos(currentlySelectedGuildData.guildIndex))
    if ZO_IsTableEmpty(currentlySelectedGuildData) then return end
    if currentlySelectedGuildData.guildIndex ~= nil then
        GUILD_SELECTOR:SelectGuildByIndex(currentlySelectedGuildData.guildIndex)
        currentlySelectedGuildData = {}
    end
end

local repeatListCheck = false

local function checkGuildIndex(displayName)
    local numGuilds = GetNumGuilds()
--d("[FCOCS]checkGuildIndex-displayName: " .. tos(displayName) .. ", numGuilds: " .. tos(numGuilds))
    if numGuilds == 0 then return nil end
    local args = parseSlashCommands(displayName, false)
    if ZO_IsTableEmpty(args) or #args < 2 then return nil end
    local possibleGuildIndex = tonumber(args[1])
--d(">possibleGuildIndex: " ..tos(possibleGuildIndex))
    if type(possibleGuildIndex) == "number" and possibleGuildIndex >= 1 and possibleGuildIndex <= MAX_GUILDS then
        return possibleGuildIndex
    end
    return nil
end

local function isPlayerInAnyOfYourGuilds(displayName, possibleDisplayNameNormal, possibleDisplayName, p_guildIndex, p_guildIndexIteratorStart)
--d("[FCOCS]isPlayerInAnyOfYourGuilds-displayName: " ..tos(displayName) ..", possibleDisplayName: " ..tos(possibleDisplayNameNormal) .."/"..tos(possibleDisplayName) ..", p_guildIndex: " ..tos(p_guildIndex) .. ", p_guildIndexIteratorStart: " ..tos(p_guildIndexIteratorStart))

    local numGuilds = GetNumGuilds()
    if numGuilds == 0 then return nil, nil, nil end
--d(">numGuilds: " ..tos(numGuilds))

    --Save the currently selected guildId/index
    currentlySelectedGuildData = {}
    currentlySelectedGuildData.guildIndex = nil
    local currentGuildId = GUILD_SELECTOR.guildId
    if currentGuildId ~= nil then
        for iteratedGuildIndex=1, numGuilds, 1 do
            local guildIdOfIterated = GetGuildId(iteratedGuildIndex)
            if guildIdOfIterated == currentGuildId then
                currentlySelectedGuildData.guildIndex = iteratedGuildIndex
--d(">currentGuildID: " ..tos(currentGuildId) ..", currentIndex: " ..tos(iteratedGuildIndex))
                break
            end
        end
    end

    local guildIndexFound
    local guildMemberDisplayname
    local isStrDisplayName = isDisplayName(possibleDisplayNameNormal)

    ------------------------------------------------------------------------------------------------------------------------
    --Function called as guild member data was loaded
    local function onGuildDataLoaded(pl_guildIndex)
--d("[FCOCS]onGuildDataLoaded-Index: " ..tos(pl_guildIndex))
        local guildsList = GUILD_ROSTER_MANAGER.lists[1].list -- Keyboard
        if ZO_IsTableEmpty(guildsList.data) then
--d("<<[3- ABORT NOW]guildsList.data is empty")
            resetGuildToOldData()
            return true
        end
        for k, v in ipairs(guildsList.data) do
            local data = v.data
            if guildMemberDisplayname == nil and data.online == true then
                if data.displayName ~= ownDisplayName then

                    d(">k: " ..tos(k) .. "data.displayName: " ..tos(data.displayName) .. "; charName: " ..tos(data.characterName))
                    local guildCharName = strlow(data.characterName)
                    local guildDisplayName = strlow(data.displayName)

                    if guildDisplayName ~= nil and strf(guildDisplayName, possibleDisplayName, 1, true) ~= nil then
                        guildMemberDisplayname = data.displayName
--d(">>>found online guild by displayName: " ..tos(guildMemberDisplayname))
                        guildIndexFound = pl_guildIndex
                        return true
                    elseif guildCharName ~= nil and strf(guildCharName, possibleDisplayName, 1, true) ~= nil then
                        guildMemberDisplayname = data.displayName
--d(">>>found online guild by charName: " ..tos(guildMemberDisplayname) .. ", charName: " .. tos(guildCharName))
                        guildIndexFound = pl_guildIndex
                        return true
                    end
                end
            end
        end
        return false
    end
    ------------------------------------------------------------------------------------------------------------------------


    --Check all -> up to 5 guilds
    local guildIndexIteratorStart = p_guildIndexIteratorStart or 1
    for guildIndex=guildIndexIteratorStart, numGuilds, 1 do
        if p_guildIndex == nil or p_guildIndex == guildIndex then
            if guildMemberDisplayname ~= nil then
--d("<<[1-ABORT NOW]guildMemberDisplayname was found: " ..tos(guildMemberDisplayname))
                resetGuildToOldData()
                return guildMemberDisplayname, guildIndexFound, nil
            end

            --Select the guild
--d(">>GuildIndex set to: " .. tos(guildIndex))
            GUILD_SELECTOR:SelectGuildByIndex(guildIndex)
            if not isStrDisplayName or (isStrDisplayName and (possibleDisplayNameNormal == ownDisplayName) or (GUILD_ROSTER_MANAGER:FindDataByDisplayName(possibleDisplayNameNormal) == nil)) then
--d(">>is no @displayName or no guild member")
                --Loop all guilds and check if any displayname partially matches the entered text from slash command


                local guildsList = GUILD_ROSTER_MANAGER.lists[1].list -- Keyboard
                if guildsList == nil or ZO_IsTableEmpty(guildsList.data) then
--d(">>>guilds list was never created yet! Switching scene states now...")
                    --Do once: Open and close the guilds list scene to create/update the data
                    --local sceneGroup = SCENE_MANAGER:GetSceneGroup("guildsSceneGroup")
                    --sceneGroup:SetActiveScene("guildHome")
                    GUILD_ROSTER_SCENE:SetState(SCENE_SHOWING)
                    GUILD_ROSTER_SCENE:SetState(SCENE_SHOWN)
                    GUILD_ROSTER_SCENE:SetState(SCENE_HIDING)
                    GUILD_ROSTER_SCENE:SetState(SCENE_HIDDEN)
    --    d(">>>>guilds scene states update")
                end



                --Update of the guild roster needs some time now...
                --So how are we able to delay the check until data was loaded properly?
                --[[
                --EVENT_GUILD_DATA_LOADED -> NO, is not used after guildIndex is switched...
                EM:RegisterForEvent("FCOCS_EVENT_GUILD_DATA_LOADED", EVENT_GUILD_DATA_LOADED, function()
                    if onGuildDataLoaded(guildIndex) == true then
                        isStrDisplayName = isDisplayName(guildMemberDisplayname)
                        if not isStrDisplayName then guildMemberDisplayname = nil end
                        if guildMemberDisplayname ~= nil then
                            resetGuildToOldData()
                            return guildMemberDisplayname, guildIndexFound, nil
                        end
                    end
                end)
                ]]
                --Update the guild roster data
                GUILD_ROSTER_KEYBOARD:RefreshData()
--d(">>>Refreshing guild list data")

                --Check guild data update
                if onGuildDataLoaded(guildIndex) == true then
                    isStrDisplayName = isDisplayName(guildMemberDisplayname)
                    if not isStrDisplayName then guildMemberDisplayname = nil end
                    if guildMemberDisplayname ~= nil then
--d("<<[2- ABORT NOW]guildMemberDisplayname was found: " ..tos(guildMemberDisplayname))
                        resetGuildToOldData()
                        return guildMemberDisplayname, guildIndexFound, nil
                    end
                end


                --[[
                guildsList = GUILD_ROSTER_MANAGER.lists[1].list -- Keyboard
                if ZO_IsTableEmpty(guildsList.data) then
                    d(">2no guilds list data found")
                    repeatListCheck = true
                    resetGuildToOldData()
                    return nil, nil, guildIndex --return the current guildIndex so the next call will go on with that guildIndex as start
                end
                for k, v in ipairs(guildsList.data) do
                    local data = v.data
                    if guildMemberDisplayname == nil and data.online == true then
                        if data.displayName ~= ownDisplayName then

                            d(">k: " ..tos(k) .. "v.data.displayName: " ..tos(v.data.displayName))
                            local guildCharName = strlow(data.characterName)
                            local guildDisplayName = strlow(data.displayName)

                            if guildDisplayName ~= nil and strf(guildDisplayName, possibleDisplayName, 1, true) ~= nil then
                                guildMemberDisplayname = data.displayName
                                d(">>>found online guild: " ..tos(guildMemberDisplayname))
                                guildIndexFound = guildIndex
                                break
                            elseif guildCharName ~= nil and strf(guildCharName, possibleDisplayName, 1, true) ~= nil then
                                guildMemberDisplayname = data.displayName
                                d(">>>found online guild by charName: " ..tos(guildMemberDisplayname) .. ", charName: " .. tos(guildCharName))
                                guildIndexFound = guildIndex
                                break
                            end
                        end
                    end
                end
                ]]
            else
                guildMemberDisplayname = possibleDisplayNameNormal
                guildIndexFound = guildIndex
            end
            isStrDisplayName = isDisplayName(guildMemberDisplayname)
            if not isStrDisplayName then guildMemberDisplayname = nil end
        end --if p_guildIndex == nil or p_guildIndex == guildIndex then
    end -- for guildIndex, numGuilds, 1 do
    resetGuildToOldData()
    return guildMemberDisplayname, guildIndexFound, nil
end

--Check if the displayName is a @displayName, partial displayName or any other name like a character name -> Try to find a matching display name via
--friends list, group or guild member list then
-->If it's a partial name the first found name will be teleported to!
local function checkDisplayName(displayName, portType, p_guildIndex, p_guildIndexIteratorStart)
    repeatListCheck = false
    --displayName could be any passed in string from slash command
    --or from the chat message a character name with spaces in there too!
    --Check if the string passed in is a displayname
    local isAccountName = isDisplayName(displayName)
    local args
    if isAccountName == true then
        args = parseSlashCommands(displayName, false)
    else
        --Could be a character name with spaces so check the whole string
        args = {
            [1] = displayName
        }
    end
    --Only consider the first
    if ZO_IsTableEmpty(args) then return end
    local displayNameOffset = (portType == "guild" and p_guildIndex ~= nil and 2) or 1
    local possibleDisplayNameNormal = tostring(args[displayNameOffset])
    if type(possibleDisplayNameNormal) ~= "string" then return end
    local possibleDisplayName = strlow(possibleDisplayNameNormal)

--d(">possibleDisplayNameNormal: " ..tos(possibleDisplayNameNormal) .. "; portType: " ..tos(portType) .."; p_guildIndex: " ..tos(p_guildIndex))

    ------------------------------------------------------------------------------------------------------------------------
    if portType == "friend" then
        local friendsDisplayname
        local isStrDisplayName = isDisplayName(possibleDisplayNameNormal)
        if not isStrDisplayName or (isStrDisplayName and not IsFriend(possibleDisplayNameNormal)) then
            --d(">>is no @displayName or no friend")
            --Loop all friends and check if any displayname partially matches the entered text from slash command
            local friendsList = FRIENDS_LIST.list
            if friendsList == nil then return end
            --d(">>>friends scene data update")
            --Open and close the friends list scene to create/update the data
            FRIENDS_LIST_SCENE:SetState(SCENE_SHOWING)
            FRIENDS_LIST_SCENE:SetState(SCENE_SHOWN)
            FRIENDS_LIST_SCENE:SetState(SCENE_HIDING)
            FRIENDS_LIST_SCENE:SetState(SCENE_HIDDEN)
            FRIENDS_LIST:RefreshData()
            friendsList = FRIENDS_LIST.list
            if ZO_IsTableEmpty(friendsList.data) then
                --d(">no friends list data yet")
                repeatListCheck = true
                return
            end
            for k, v in ipairs(friendsList.data) do
                local data = v.data
                if friendsDisplayname == nil and data.online == true then
                    --d(">k: " ..tos(k) .. "v.data.displayName: " ..tos(v.data.displayName))
                    local friendCharName = strlow(data.characterName)
                    local friendDisplayName = strlow(data.displayName)

                    if friendDisplayName ~= nil and strf(friendDisplayName, possibleDisplayName, 1, true) ~= nil then
                        friendsDisplayname = data.displayName
                        --d(">>>found online friend: " ..tos(friendsDisplayname))
                        break
                    elseif friendCharName ~= nil and strf(friendCharName, possibleDisplayName, 1, true) ~= nil then
                        friendsDisplayname = data.displayName
                        --d(">>>found online friend by charName: " ..tos(friendsDisplayname) .. ", charName: " .. tos(friendCharName))
                    end
                end
            end
            if friendsDisplayname ~= nil and not IsFriend(friendsDisplayname) then
                friendsDisplayname = nil
            end
        else
            friendsDisplayname = possibleDisplayNameNormal
        end
        isStrDisplayName = isDisplayName(friendsDisplayname)
        if not isStrDisplayName then friendsDisplayname = nil end
        return friendsDisplayname

    ------------------------------------------------------------------------------------------------------------------------
    elseif portType == "guild" then
--d(">>guild check")
        return isPlayerInAnyOfYourGuilds(displayName, possibleDisplayNameNormal, possibleDisplayName, p_guildIndex, p_guildIndexIteratorStart)
    end
end

function FCOChangeStuff.PortToGroupLeader()
    if not canTeleport() then return end
    local unitTag, groupLeaderTag
    if not IsUnitGrouped("player") or IsUnitGroupLeader(playerTag) then return end
    groupLeaderTag = GetGroupLeaderUnitTag()
    if groupLeaderTag == nil or groupLeaderTag == "" then
        return
    else
        unitTag = groupLeaderTag
        --[[
        local groupPlayerIndex = GetGroupIndexByUnitTag(playerTag)
        for groupIndex=0, GetGroupSize(), 1 do
            if groupIndex == groupPlayerIndex then
            else
            end
        end
        ]]
    end
    if unitTag == nil then return end
    portToDisplayname(GetUnitDisplayName(unitTag), "groupLeader")
end

function FCOChangeStuff.PortToGroupMember(displayName)
    if displayName == nil or displayName == "" or not canTeleport() then return end
    if not IsUnitGrouped("player") then return end
    displayName = checkDisplayName(displayName, "group")
    portToDisplayname(displayName, "group")
end

function FCOChangeStuff.PortToFriend(displayName)
    if displayName == nil or displayName == "" or not canTeleport() then return end
    displayName = checkDisplayName(displayName, "friend")

    --[[
    if displayName == nil and repeatListCheck == true then
        repeatListCheck = false
        --Delay the call to the same function so the friendsListd ata is build properly
        zo_callLater(function() FCOChangeStuff.PortToFriend(displayName) end, 250)
        return
    end
    ]]

    portToDisplayname(displayName, "friend")
end

function FCOChangeStuff.PortToGuildMember(displayName, guildIndex, guildIndexIteratorStart)
    if displayName == nil or displayName == "" or not canTeleport() then return end
    if not canTeleport() then return end
    local numGuilds = GetNumGuilds()
    if numGuilds == 0 then return end

    --Check if 1st param is a number 1 to 5, then it is the guild number to search
    guildIndex = guildIndex or checkGuildIndex(displayName)
    local p_guildIndexFound, p_GuildIndexIteratorStart
    displayName, p_guildIndexFound, p_GuildIndexIteratorStart = checkDisplayName(displayName, "guild", guildIndex, guildIndexIteratorStart)

    --[[
    if displayName == nil and repeatListCheck == true then
        repeatListCheck = false
        --Delay the call to the same function so the friendsListd ata is build properly
        zo_callLater(function() FCOChangeStuff.PortToGuildMember(displayName, guildIndex, p_GuildIndexIteratorStart) end, 250)
        return
    end
    ]]

    portToDisplayname(displayName, "guild", p_guildIndexFound or guildIndex)
end

local function getPortTypeFromName(playerName, rawName)
--d("[FCOCS]getPortTypeFromChatName-playerName: " ..tos(playerName) ..", rawName: " ..tos(rawName))
    if IsIgnored(playerName) then return nil, nil end

    local playerTypeStr = "player"
    local portType = nil
    local guildIndexFound

    --Friend
    if IsFriend(playerName) then
--d(">player is a friend!")
        --port to friend
        portType = "friend"
        playerTypeStr = "Friend"
    end

    --Group member
    local localPlayerIsGrouped = IsUnitGrouped("player")
--d(">Are we grouped: " ..tos(localPlayerIsGrouped))
    if portType == nil and localPlayerIsGrouped == true then
        if IsPlayerInGroup(rawName) then
--d(">>player is in group!")
            --port to group member
            portType = "group"
            playerTypeStr = "Group member"
        end
    end

    --Guild
    if portType == nil then
--d(">check guilds:")
        local guildMemberDisplayname
        guildMemberDisplayname, guildIndexFound, _ = checkDisplayName(playerName, "guild", nil, nil)
--d(">guildMemberDisplayname: " ..tos(guildMemberDisplayname) .. "; guildIndexFound: " ..tos(guildIndexFound))
        --port to guild member
        if guildMemberDisplayname ~= nil then
            portType = "guild"
            if guildIndexFound ~= nil then
                playerTypeStr = "Guild #" .. tos(guildIndexFound) .. " member"
            else
                playerTypeStr = "Guild member"
            end
        end
    end

--[[
        --Group leader
        if localPlayerIsGrouped == true then
            if not IsUnitGroupLeader("player") then
d(">>port to group leader")
                --port to group leader
                portType = "groupLeader"
                playerTypeStr = "Group leader"
            end
        end
]]
    return portType, playerTypeStr, guildIndexFound
end

local function FCOChangeStuff_PlayerContextMenuCallback(playerName, rawName)
--d("[FCOCS]PlayerContextMenuCallback-playerName: " ..tos(playerName) ..", rawName: " ..tos(rawName))
    local settings = FCOChangeStuff.settingsVars.settings
    local wasAdded = 0
    local playerNameStr = " \'" .. tos(playerName) .. "\'"

    addonNameShortColored = FCOChangeStuff.addonVars.addonNameShortColored


    if settings.showIgnoredInfoInContextMenuAtChat == true then
--d("[1]IsIgnored check")
        if IsIgnored(playerName) then
            AddMenuItem("[|c00FF00!WARNING!|r] You ignore this player!", function()  end)
            wasAdded = wasAdded +1
        end
    end

    if settings.teleportContextMenuAtChat == true then
--d("[2]Teleport to check")
        local portType, playerTypeStr, guildIndexFound = getPortTypeFromName(playerName, rawName)
--d(">portType: " ..tos(portType) .. "; playerTypeStr: " ..tos(playerTypeStr))
        if portType ~= nil then
            AddMenuItem(GetString(SI_GAMEPAD_HELP_UNSTUCK_TELEPORT_KEYBIND_TEXT) .. ": " .. playerTypeStr .. playerNameStr, function()
                portToDisplayname(playerName, portType, guildIndexFound)
            end)
            wasAdded = wasAdded +1
        end
    end

    if settings.sendMailContextMenuAtChat == true then
--d("[3]Mail to check")
        AddMenuItem(GetString(SI_SOCIAL_MENU_SEND_MAIL) .. playerNameStr , function()
            MAIL_SEND:ComposeMailTo(playerName)
        end)
        wasAdded = wasAdded +1
    end

    if wasAdded >= 1 then
        ShowMenu()
    end
end

local ignorePlayerStr = GetString(SI_CHAT_PLAYER_CONTEXT_ADD_IGNORE)
local ignoreDialogInitialized = false

local function doIgnorePlayerNow(playerName)
    if playerName == nil or playerName == "" then return end
    if IsIgnored(playerName) then return end
    FCOChangeStuff.preventerVars.doNotShowAskBeforeIgnoreDialog = true
    ZO_PlatformIgnorePlayer(playerName)
end

local function initializeFCOCSIgnorePlayerDialog()
--d("[FCOCS]initializeFCOCSIgnorePlayerDialog")
    ZO_Dialogs_RegisterCustomDialog("FCOCS_IGNORE_PLAYER_DIALOG", {
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = ignorePlayerStr .. "?",
        },
        mainText = function(dialog)
            return { text = ignorePlayerStr .. " \'" .. tos(dialog and dialog.data and dialog.data.playerName) .. "\'" }
        end,
        buttons =
        {
             -- Confirm Button
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_DIALOG_CONFIRM),
                callback = function(dialog, data)
                    doIgnorePlayerNow((data and data.playerName) or (dialog and dialog.data and dialog.data.playerName))
                end,
            },

            -- Cancel Button
            {
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
            },
        },
        --[[
        noChoiceCallback = function()
        end,
        ]]
    })
    ignoreDialogInitialized = true
end

local function ignorePlayerDialog(playerName)
--d("[FCOCS]ignorePlayerDialog - playerName: " ..tos(playerName))
    if ignoreDialogInitialized == false then
        initializeFCOCSIgnorePlayerDialog()
    end
    ZO_Dialogs_ShowPlatformDialog("FCOCS_IGNORE_PLAYER_DIALOG", { playerName = playerName })
end


function FCOChangeStuff.TeleportChanges()
--d("[FCOCS]FCOChangeStuff.TeleportChanges")
    local settings = FCOChangeStuff.settingsVars.settings

    if settings.ignoreWithDialogContextMenuAtChat == true then
        --Fix Ignore player to be down at report player in chat context menu!

        --Is the SecurePosthook still calling LibCustomMenu hooks properly at original first called IsGroupModificationAvailable -> InsertEntries
        --and at ZO_Menu_GetNumMenuItems at the end then?
        --> No :-( So no Posthook or Prehook possible
        --[[
        SecurePostHook(CHAT_SYSTEM, "ShowPlayerContextMenu", function(chatSystem, playerName, rawName)
    --d("[FCOCS]Chat_SYSTEM.ShowPlayerContextMenu - SecurePostHook; playerName: " ..tos(playerName) .. ", rawName: " ..tos(rawName))
            --FCOCS_ChatSystemShowPlayerContextMenu_IsHooked = playerName

            ClearMenu()

            -- Add to/Remove from Group
            if IsGroupModificationAvailable() then
                local localPlayerIsGrouped = IsUnitGrouped("player")
                local localPlayerIsGroupLeader = IsUnitGroupLeader("player")
                local otherPlayerIsInPlayersGroup = IsPlayerInGroup(rawName)
                if not localPlayerIsGrouped or (localPlayerIsGroupLeader and not otherPlayerIsInPlayersGroup) then
                    AddMenuItem(GetString(SI_CHAT_PLAYER_CONTEXT_ADD_GROUP), function()
                    local SENT_FROM_CHAT = false
                    local DISPLAY_INVITED_MESSAGE = true
                    TryGroupInviteByName(playerName, SENT_FROM_CHAT, DISPLAY_INVITED_MESSAGE) end)
                elseif otherPlayerIsInPlayersGroup and localPlayerIsGroupLeader then
                    AddMenuItem(GetString(SI_CHAT_PLAYER_CONTEXT_REMOVE_GROUP), function() GroupKickByName(rawName) end)
                end
            end

            -- Whisper
            AddMenuItem(GetString(SI_CHAT_PLAYER_CONTEXT_WHISPER), function() CHAT_SYSTEM:StartTextEntry(nil, CHAT_CHANNEL_WHISPER, playerName) end)

            -- Add Friend
            if not IsFriend(playerName) then
                AddMenuItem(GetString(SI_CHAT_PLAYER_CONTEXT_ADD_FRIEND), function() ZO_Dialogs_ShowDialog("REQUEST_FRIEND", { name = playerName }) end)
            end

            -- Report player
            AddMenuItem(zo_strformat(SI_CHAT_PLAYER_CONTEXT_REPORT, rawName), function()
                ZO_HELP_GENERIC_TICKET_SUBMISSION_MANAGER:OpenReportPlayerTicketScene(playerName)
            end)

            -- Ignore
            local function IgnoreSelectedPlayer(p_playerName)
                --Ask before ignore dialog show
                ignorePlayerDialog(p_playerName)
            end
            if not IsIgnored(playerName) then
                AddMenuItem(GetString(SI_CHAT_PLAYER_CONTEXT_ADD_IGNORE), function() IgnoreSelectedPlayer(playerName) end)
            end

            if ZO_Menu_GetNumMenuItems() > 0 then
                ShowMenu()
            end

            --Call original function to let LibCustomMenu work properly!
            --return true --supress original func
        end)
        ]]

        --Try to Posthook the ZO_Menu_GetNumMenuItems funtion to check if it's the menu that opens at character and replace the ignore entry with the one that
        --calls the security dialog
        local function IgnoreSelectedPlayer(p_playerName)
            --Ask before ignore dialog show
            ignorePlayerDialog(p_playerName)
        end

        local playerNameAtContextMenuChat = nil
        ZO_PreHook(CHAT_SYSTEM, "ShowPlayerContextMenu", function(chatSystem, playerName, rawName)
            playerNameAtContextMenuChat = playerName
--d[FCOCS]CHAT_SYSTEM.ShowPlayerContextMenu-playerNameAtContextMenuChat: " ..tos(playerNameAtContextMenuChat))
            return false
        end)

        SecurePostHook("ClearMenu", function()
--d("[FCOCS]ClearMenu-playerNameAtContextMenuChat: " ..tos(playerNameAtContextMenuChat))
            playerNameAtContextMenuChat = nil
        end)


        SecurePostHook("ZO_Menu_GetNumMenuItems", function()
--d("[FCOCS]ZO_Menu_GetNumMenuItems-playerNameAtContextMenuChat: " ..tos(playerNameAtContextMenuChat))
            if playerNameAtContextMenuChat == nil then return end
            local menuItems = ZO_Menu.items
            if #menuItems == 0 then return end

            --Get the index of ZO_Menu.items of the entry "Ignore player" -> SI_CHAT_PLAYER_CONTEXT_ADD_IGNORE
            local ignorePlayerContextMenuIndex, ignorePlayerContextMenuDataOrig
            for k, v in ipairs(menuItems) do
                if ignorePlayerContextMenuIndex == nil then
                    local item = v.item
                    if item.name and item.name == ignorePlayerStr then
                        ignorePlayerContextMenuIndex = k
                        ignorePlayerContextMenuDataOrig = ZO_ShallowTableCopy(v)
                        break
                    end
                end
            end
            if ignorePlayerContextMenuIndex ~= nil and ignorePlayerContextMenuDataOrig ~= nil then
--d(">found ignore enry at index: " ..tos(ignorePlayerContextMenuIndex))
                local playerNameAtContextMenuChatCopy = playerNameAtContextMenuChat

                local ignorePlayerContextMenuDataWithIgnoreDialogCallback = ZO_ShallowTableCopy(ignorePlayerContextMenuDataOrig)
                ignorePlayerContextMenuDataWithIgnoreDialogCallback.item.callback = function()
                    if not IsIgnored(playerNameAtContextMenuChatCopy) then
                        IgnoreSelectedPlayer(playerNameAtContextMenuChatCopy)
                    end
                end
                ZO_Menu.items[ignorePlayerContextMenuIndex] = ignorePlayerContextMenuDataWithIgnoreDialogCallback
            end
            playerNameAtContextMenuChat = nil
        end)


        --Should add the "Ask before ignore" dialog on every "AddIgnore" call, e.g. from Friends list etc.
        local addIgnoreOrig = AddIgnore
        ZO_PreHook("AddIgnore", function(playerName)
--d("[FCOCS]PreHook AddIgnore-PlayerName: " ..tos(playerName))
            if FCOChangeStuff.preventerVars.doNotShowAskBeforeIgnoreDialog == true then
                FCOChangeStuff.preventerVars.doNotShowAskBeforeIgnoreDialog = false
                --Do not show dialog again, just call original func
                addIgnoreOrig(playerName)
            else
                --Ask before ignore dialog show
                ignorePlayerDialog(playerName)
            end
            return true --Suppress original function call
        end)
    end


    if settings.showIgnoredInfoInContextMenuAtChat == true or settings.teleportContextMenuAtChat == true or settings.sendMailContextMenuAtChat == true then
--d(">teleport context menu at chat, or send mail")
        --Add "Teleport to" and "Send mail to" and "!WARNING! Player is ignored" to chat character/displayName context menu entries
        LCM:RegisterPlayerContextMenu(FCOChangeStuff_PlayerContextMenuCallback, LCM.CATEGORY_LATE)
    end
end