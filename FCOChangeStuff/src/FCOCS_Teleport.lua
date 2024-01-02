if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

local EM = EVENT_MANAGER
local tos = tostring
local strf = string.find
local strlow = string.lower

local playerTag = "player"
local ownDisplayName = GetDisplayName()

local parseSlashCommands = FCOChangeStuff.ParseSlashCommands

local LCM = LibCustomMenu


--ZO_Menu helper functions
local function UpdateMenuDimensions(menuEntry)
    if ZO_Menu.currentIndex > 0 then
        local textWidth, textHeight = menuEntry.item.nameLabel:GetTextDimensions()
        local checkboxWidth, checkboxHeight = 0, 0
        if menuEntry.checkbox then
            checkboxWidth, checkboxHeight = menuEntry.checkbox:GetDesiredWidth(), menuEntry.checkbox:GetDesiredHeight()
        end

        local entryWidth = textWidth + checkboxWidth + ZO_Menu.menuPad * 2
        local entryHeight = zo_max(textHeight, checkboxHeight)

        if entryWidth > ZO_Menu.width then
            ZO_Menu.width = entryWidth
        end

        ZO_Menu.height = ZO_Menu.height + entryHeight + menuEntry.itemYPad

        -- More adjustments will come later...this just needs to set the height
        -- HACK: Because anchor processing doesn't happen right away, and because GetDimensions
        -- does NOT return desired dimensions...this will actually need to remember the height
        -- that the label was set to.  And to remember it, we need to find the menu item in the
        -- appropriate menu...
        menuEntry.item.storedHeight = entryHeight
    end
end



--FCOCS - Teleport functions
function FCOChangeStuff.CanTeleport()
    local canTeleportNow = (not IsUnitDead(playerTag) and CanLeaveCurrentLocationViaTeleport()) or false
d("[FCOCS]CanTeleport: " ..tos(canTeleportNow))
    return canTeleportNow
end
local canTeleport = FCOChangeStuff.CanTeleport

local portToDisplayname
local wasUnmounted = false
local function onMountStateChangedTeleport(mounted, displayName, portType, guildIndex)
d("[FCOCS]onMountStateChangedTeleport-mounted: " ..tos(mounted) ..", displayName: " ..tos(displayName) .. ", portType: " ..tos(portType) .. ", guildIndex: " ..tos(guildIndex))
    EM:UnregisterForEvent("FCOCS_EVENT_MOUNTED_STATE_CHANGED_teleport", EVENT_MOUNTED_STATE_CHANGED)
    if mounted == false then
d(">porting now after unmounting")
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
d("[FCOCS]PortToDisplayname-displayName: " ..tos(displayName) .. ", portType: " ..tos(portType) .. ", guildIndex: " ..tos(guildIndex) ..", isMounted: " ..tos(isCurrentlyMounted))
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
        d("[FCOChangeStuff]Teleporting to: " .. teleportToName)

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
d("[FCOCS]resetGuildToOldData: " ..tos(currentlySelectedGuildData.guildIndex))
    if ZO_IsTableEmpty(currentlySelectedGuildData) then return end
    if currentlySelectedGuildData.guildIndex ~= nil then
        GUILD_SELECTOR:SelectGuildByIndex(currentlySelectedGuildData.guildIndex)
        currentlySelectedGuildData = {}
    end
end

local repeatListCheck = false

local function checkGuildIndex(displayName)
    local numGuilds = GetNumGuilds()
d("[FCOCS]checkGuildIndex-displayName: " .. tos(displayName) .. ", numGuilds: " .. tos(numGuilds))
    if numGuilds == 0 then return nil end
    local args = parseSlashCommands(displayName, false)
    if ZO_IsTableEmpty(args) or #args < 2 then return nil end
    local possibleGuildIndex = tonumber(args[1])
d(">possibleGuildIndex: " ..tos(possibleGuildIndex))
    if type(possibleGuildIndex) == "number" and possibleGuildIndex >= 1 and possibleGuildIndex <= MAX_GUILDS then
        return possibleGuildIndex
    end
    return nil
end

local function isPlayerInAnyOfYourGuilds(displayName, possibleDisplayNameNormal, possibleDisplayName, p_guildIndex, p_guildIndexIteratorStart)
    d("[FCOCS]isPlayerInAnyOfYourGuilds-displayName: " ..tos(displayName) ..", possibleDisplayName: " ..tos(possibleDisplayNameNormal) .."/"..tos(possibleDisplayName) ..", p_guildIndex: " ..tos(p_guildIndex) .. ", p_guildIndexIteratorStart: " ..tos(p_guildIndexIteratorStart))

    local numGuilds = GetNumGuilds()
    if numGuilds == 0 then return nil, nil, nil end

    --Save the currently selected guildId/index
    currentlySelectedGuildData.guildIndex = nil
    local currentGuildId = GUILD_SELECTOR.guildId
    if currentGuildId ~= nil then
        for iteratedGuildIndex=1, numGuilds, 1 do
            local guildIdOfIterated = GetGuildId(iteratedGuildIndex)
            if guildIdOfIterated == currentGuildId then
                currentlySelectedGuildData.guildIndex = iteratedGuildIndex
d(">currentGuildID: " ..tos(currentGuildId) ..", currentIndex: " ..tos(iteratedGuildIndex))
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
d("[FCOCS]onGuildDataLoaded-Index: " ..tos(pl_guildIndex))
        local guildsList = GUILD_ROSTER_MANAGER.lists[1].list -- Keyboard
        if ZO_IsTableEmpty(guildsList.data) then
            resetGuildToOldData()
            return true
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
                        guildIndexFound = pl_guildIndex
                        return true
                    elseif guildCharName ~= nil and strf(guildCharName, possibleDisplayName, 1, true) ~= nil then
                        guildMemberDisplayname = data.displayName
                        d(">>>found online guild by charName: " ..tos(guildMemberDisplayname) .. ", charName: " .. tos(guildCharName))
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
                resetGuildToOldData()
                return guildMemberDisplayname, guildIndexFound, nil
            end

            --Select the guild
d(">>GuildIndex set to: " .. tos(guildIndex))
            GUILD_SELECTOR:SelectGuildByIndex(guildIndex)
            if not isStrDisplayName or (isStrDisplayName and (possibleDisplayNameNormal == ownDisplayName) or (GUILD_ROSTER_MANAGER:FindDataByDisplayName(possibleDisplayNameNormal) == nil)) then
                d(">>is no @displayName or no guild member")
                --Loop all guilds and check if any displayname partially matches the entered text from slash command


                local guildsList = GUILD_ROSTER_MANAGER.lists[1].list -- Keyboard
                if guildsList == nil or ZO_IsTableEmpty(guildsList.data) then
                    d(">>>guilds list was never created yet!")
                    --Do once: Open and close the guilds list scene to create/update the data
                    --local sceneGroup = SCENE_MANAGER:GetSceneGroup("guildsSceneGroup")
                    --sceneGroup:SetActiveScene("guildHome")
                    GUILD_ROSTER_SCENE:SetState(SCENE_SHOWING)
                    GUILD_ROSTER_SCENE:SetState(SCENE_SHOWN)
                    GUILD_ROSTER_SCENE:SetState(SCENE_HIDING)
                    GUILD_ROSTER_SCENE:SetState(SCENE_HIDDEN)
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
        d(">>>guilds scene data update")
                --Update the guild roster data
                GUILD_ROSTER_KEYBOARD:RefreshData()

                if onGuildDataLoaded(guildIndex) == true then
                    isStrDisplayName = isDisplayName(guildMemberDisplayname)
                    if not isStrDisplayName then guildMemberDisplayname = nil end
                    if guildMemberDisplayname ~= nil then
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
    --Only consider the first
    local args = parseSlashCommands(displayName, false)
    if ZO_IsTableEmpty(args) then return end
    local displayNameOffset = (portType == "guild" and p_guildIndex ~= nil and 2) or 1
    local possibleDisplayNameNormal = tostring(args[displayNameOffset])
    if type(possibleDisplayNameNormal) ~= "string" then return end
    local possibleDisplayName = strlow(possibleDisplayNameNormal)

d(">possibleDisplayNameNormal: " ..tos(possibleDisplayNameNormal) .. "; portType: " ..tos(portType) .."; p_guildIndex: " ..tos(p_guildIndex))

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

        return isPlayerInAnyOfYourGuilds(displayName, possibleDisplayNameNormal, possibleDisplayName, p_guildIndex, p_guildIndexIteratorStart)
        --[[
        --Loop all guild member's displayNames and compare them (lowercase). If one matches -> port to it
        --Get number of guilds
        --EM:UnregisterForEvent("FCOCS_EVENT_GUILD_DATA_LOADED", EVENT_GUILD_DATA_LOADED)
        local numGuilds = GetNumGuilds()
        if numGuilds == 0 then return end

        --Save the currently selected guildId/index
        currentlySelectedGuildData.guildIndex = nil
        local currentGuildId = GUILD_SELECTOR.guildId
        if currentGuildId ~= nil then
            for iteratedGuildIndex=1, numGuilds, 1 do
                local guildIdOfIterated = GetGuildId(iteratedGuildIndex)
                if guildIdOfIterated == currentGuildId then
                    currentlySelectedGuildData.guildIndex = iteratedGuildIndex
d(">currentGuildID: " ..tos(currentGuildId) ..", currentIndex: " ..tos(iteratedGuildIndex))
                    break
                end
            end
        end

        local guildIndexFound
        local guildMemberDisplayname
        local isStrDisplayName = isDisplayName(possibleDisplayNameNormal)

        ------------------------------------------------------------------------------------------------------------------------
        --Function called as guild member data was loaded
        local function onGuildDataLoaded(p_guildIndex)
    d("[FCOCS]onGuildDataLoaded-Index: " ..tos(p_guildIndex))
            local guildsList = GUILD_ROSTER_MANAGER.lists[1].list -- Keyboard
            if ZO_IsTableEmpty(guildsList.data) then
                resetGuildToOldData()
                return true
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
                            guildIndexFound = p_guildIndex
                            return true
                        elseif guildCharName ~= nil and strf(guildCharName, possibleDisplayName, 1, true) ~= nil then
                            guildMemberDisplayname = data.displayName
                            d(">>>found online guild by charName: " ..tos(guildMemberDisplayname) .. ", charName: " .. tos(guildCharName))
                            guildIndexFound = p_guildIndex
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
                    resetGuildToOldData()
                    return guildMemberDisplayname, guildIndexFound, nil
                end

                --Select the guild
d(">>GuildIndex set to: " .. tos(guildIndex))
                GUILD_SELECTOR:SelectGuildByIndex(guildIndex)
                if not isStrDisplayName or (isStrDisplayName and (possibleDisplayNameNormal == ownDisplayName) or (GUILD_ROSTER_MANAGER:FindDataByDisplayName(possibleDisplayNameNormal) == nil)) then
                    d(">>is no @displayName or no guild member")
                    --Loop all guilds and check if any displayname partially matches the entered text from slash command


                    local guildsList = GUILD_ROSTER_MANAGER.lists[1].list -- Keyboard
                    if guildsList == nil or ZO_IsTableEmpty(guildsList.data) then
                        d(">>>guilds list was never created yet!")
                        --Do once: Open and close the guilds list scene to create/update the data
                        --local sceneGroup = SCENE_MANAGER:GetSceneGroup("guildsSceneGroup")
                        --sceneGroup:SetActiveScene("guildHome")
                        GUILD_ROSTER_SCENE:SetState(SCENE_SHOWING)
                        GUILD_ROSTER_SCENE:SetState(SCENE_SHOWN)
                        GUILD_ROSTER_SCENE:SetState(SCENE_HIDING)
                        GUILD_ROSTER_SCENE:SetState(SCENE_HIDDEN)
                    end

            d(">>>guilds scene data update")
                    --Update the guild roster data
                    GUILD_ROSTER_KEYBOARD:RefreshData()

                    if onGuildDataLoaded(guildIndex) == true then
                        isStrDisplayName = isDisplayName(guildMemberDisplayname)
                        if not isStrDisplayName then guildMemberDisplayname = nil end
                        if guildMemberDisplayname ~= nil then
                            resetGuildToOldData()
                            return guildMemberDisplayname, guildIndexFound, nil
                        end
                    end

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
    ]]
    ------------------------------------------------------------------------------------------------------------------------
    end
end

function FCOChangeStuff.PortToGroupLeader()
    if not canTeleport() then return end

    local unitTag
    local groupLeaderTag = GetGroupLeaderUnitTag()
    if groupLeaderTag == nil or groupLeaderTag == "" or IsUnitGroupLeader(playerTag) then
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
    displayName = checkDisplayName(displayName, "group")
    portToDisplayname(displayName, "group")
end

function FCOChangeStuff.PortToFriend(displayName)
    if displayName == nil or displayName == "" or not canTeleport() then return end
    displayName = checkDisplayName(displayName, "friend")

    if displayName == nil and repeatListCheck == true then
        repeatListCheck = false
        --Delay the call to the same function so the friendsListd ata is build properly
        zo_callLater(function() FCOChangeStuff.PortToFriend(displayName) end, 250)
        return
    end

    portToDisplayname(displayName, "friend")
end

function FCOChangeStuff.PortToGuildMember(displayName, guildIndex, guildIndexIteratorStart)
    if displayName == nil or displayName == "" or not canTeleport() then return end
    --Check if 1st param is a number 1 to 5, then it is the guild number to search
    guildIndex = guildIndex or checkGuildIndex(displayName)
    local p_guildIndexFound, p_GuildIndexIteratorStart
    displayName, p_guildIndexFound, p_GuildIndexIteratorStart = checkDisplayName(displayName, "guild", guildIndex, guildIndexIteratorStart)

    if displayName == nil and repeatListCheck == true then
        repeatListCheck = false
        --Delay the call to the same function so the friendsListd ata is build properly
        zo_callLater(function() FCOChangeStuff.PortToGuildMember(displayName, guildIndex, p_GuildIndexIteratorStart) end, 250)
        return
    end

    portToDisplayname(displayName, "guild", p_guildIndexFound or guildIndex)
end

local function getPortTypeFromName(playerName, rawName)
d("[FCOCS]getPortTypeFromChatName-playerName: " ..tos(playerName) ..", rawName: " ..tos(rawName))
    if IsIgnored(playerName) then return nil, nil end

    local playerTypeStr = "player"
    local portType = nil

    --Friend
    if IsFriend(playerName) then
        --port to friend
        portType = "friend"
        playerTypeStr = "Friend"
    end

    --Group member
    local localPlayerIsGrouped = IsUnitGrouped("player")
    if portType == nil and localPlayerIsGrouped == true then
        if IsPlayerInGroup(rawName) then
            --port to group member
            portType = "group"
            playerTypeStr = "Group member"
        end
    end

    --Group leader
    local localPlayerIsGroupLeader = IsUnitGroupLeader("player")
    if portType == nil and localPlayerIsGroupLeader == false then
        --port to group leader
        portType = "group"
        playerTypeStr = "Group leader"
    end

    --Guild
    if portType == nil then
        local guildMemberDisplayname, guildIndexFound, _ = checkDisplayName(playerName, portType, nil, nil)
        --port to friend
        if guildMemberDisplayname ~= nil then
            portType = "guild"
            if guildIndexFound ~= nil then
                playerTypeStr = "Guild #" .. tos(guildIndexFound) .. " member"
            else
                playerTypeStr = "Guild member"
            end
        end
    end
    return portType, playerTypeStr
end

local function FCOChangeStuff_PlayerContextMenuCallback(playerName, rawName)
d("[FCOCS]PlayerContextMenuCallback-playerName: " ..tos(playerName) ..", rawName: " ..tos(rawName))
    local portType, playerTypeStr = getPortTypeFromName(playerName, rawName)
    if portType == nil then return end

    AddMenuItem("[FCOChangeStuff]" .. GetString(SI_GAMEPAD_HELP_UNSTUCK_TELEPORT_KEYBIND_TEXT) .. ": " .. playerTypeStr .. "\'" .. tos(playerName) .. "\'", function()
        portToDisplayname(rawName, portType, nil)
    end, MENU_ADD_OPTION_LABEL)

    ShowMenu()
end

local ignorePlayerStr = GetString(SI_CHAT_PLAYER_CONTEXT_ADD_IGNORE)
local ignoreDialogInitialized = false

local function doIgnorePlayerNow(playerName)
    if playerName == nil or playerName == "" then return end
    if IsIgnored(playerName) then return end
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
    local settings = FCOChangeStuff.settingsVars.settings

    if settings.ignoreWithDialogContextMenuAtChat == true then
        --Fix Ignore player to be down at report player in chat context menu!
        ZO_PreHook(CHAT_SYSTEM, "ShowPlayerContextMenu", function(chatSystem, playerName, rawName)
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
            AddMenuItem(GetString(SI_CHAT_PLAYER_CONTEXT_WHISPER), function() self:StartTextEntry(nil, CHAT_CHANNEL_WHISPER, playerName) end)

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

            return true --supress original func
        end)
    end


    if settings.teleportContextMenuAtChat == true then
        --todo 2024-01-02 Add context menu entries at friends/guilds/chat character or account links

        --Currently guild member, friends list and group context menu got the "Port to" entries already
        --TODO: Added "Port to group leader" into group context menu entries
        -->LibCustomMenu provides functions for that?

        --Added "Teleport to" to chat character/displayName context menu entries
        LCM:RegisterPlayerContextMenu(FCOChangeStuff_PlayerContextMenuCallback, LCM.CATEGORY_LATE)
    end
end