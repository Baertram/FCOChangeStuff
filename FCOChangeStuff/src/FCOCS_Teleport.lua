if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

local EM = EVENT_MANAGER
local tos = tostring
local strf = string.find
local strlow = string.lower

local playerTag = "player"
local ownDisplayName = GetDisplayName()

local parseSlashCommands = FCOChangeStuff.ParseSlashCommands


function FCOChangeStuff.CanTeleport()
    return (not IsUnitDead(playerTag) and CanLeaveCurrentLocationViaTeleport()) or false
end
local canTeleport = FCOChangeStuff.CanTeleport

local portToDisplayname
local function onMountStateChangedTeleport(eventId, mountState, displayName, portType)
d("[FCOCS]onMountStateChangedTeleport-mountState: " ..tos(mountState) ..", displayName: " ..tos(displayName) .. ", portType: " ..tos(portType))
    EM:UnregisterForEvent("FCOCS_EVENT_MOUNTED_STATE_CHANGED_teleport", EVENT_MOUNTED_STATE_CHANGED)
    if mountState ~= MOUNTED_STATE_NOT_MOUNTED then return end
    portToDisplayname(displayName, portType)
end

function FCOChangeStuff.PortToDisplayname(displayName, portType, guildIndex)
    if displayName == nil or displayName == "" then return end
    portToDisplayname = portToDisplayname or FCOChangeStuff.PortToDisplayname
    if not canTeleport() then return end

    local isCurrentlyMounted = IsMounted()
    CancelCast()

    if portType == "groupLeader" then
        JumpToGroupLeader()
    elseif portType == "group" then
        JumpToGroupMember(displayName)
    elseif portType == "friend" then
        JumpToFriend(displayName)
    elseif portType == "guild" then
        JumpToGuildMember(displayName)
    end

    if isCurrentlyMounted then
        --Player get's unmounted on first call, so repeat the port again with a delay
        --zo_callLater(function() portToDisplayname(displayName, portType) end, 1250)
        -->No delay here, use mount state changed event and recall the teleport then
        EM:RegisterForEvent("FCOCS_EVENT_MOUNTED_STATE_CHANGED_teleport", EVENT_MOUNTED_STATE_CHANGED, function(...) onMountStateChangedTeleport(..., displayName, portType) end)
        return
    else
        --Start the teleporting now
        local teleportToName = (
                   (portType == "groupLeader" and tos(displayName) .. " (Group leader)")
                or (portType == "group" and tos(displayName) .. " (Group member)")
                or (portType == "friend" and tos(displayName) .. " (Friend)")
                or (portType == "guild" and ((guildIndex ~= nil and tos(displayName) .. " (Guild #" .. tos(guildIndex)..")") or (tos(displayName) .. " (Guild)")))
                )
                or tos(displayName)
        d("[FCOChangeStuff]Teleporting to: " .. teleportToName)
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

    ------------------------------------------------------------------------------------------------------------------------
    else
        --Coming from chat context menu of zoneChat e.g.? Try to find out if it's a group member, friend or guild member
        --or any random char (we cannot port to them!!!)
        --todo
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

function FCOChangeStuff.TeleportChanges()
    if FCOChangeStuff.settingsVars.settings.teleportContextMenuAtChat == true then
        --todo 2024-01-02 Add context menu entries at friends/guilds/chat character or account links
    end
end