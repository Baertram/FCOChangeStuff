if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

local strlower = string.lower
local strgmatch = string.gmatch

------------------------------------------------------------------------------------------------------------------------
-- Slash commands --
------------------------------------------------------------------------------------------------------------------------

function FCOChangeStuff.ParseSlashCommands(args, lowerString)
    lowerString = lowerString or false
    local options = {}
    --local searchResult = {} --old: searchResult = { string.match(args, "^(%S*)%s*(.-)$") }
    for param in strgmatch(args, "([^%s]+)%s*") do
        if (param ~= nil and param ~= "") then
            if lowerString == true then
                options[#options+1] = strlower(param)
            else
                options[#options+1] = param
            end
        end
    end
    return options
end

function FCOChangeStuff.slashCommands()
    --Group leave commands
    local function leaveGroup()
        if IsUnitGrouped("player") then
            GroupLeave()
        end
    end
    SLASH_COMMANDS["/gl"] 		    = leaveGroup
    SLASH_COMMANDS["/groupleave"]   = leaveGroup
    SLASH_COMMANDS["/ungroup"]      = leaveGroup

    --ReloadUI commands
    local function reloadTheUI()
        ReloadUI("ingame")
    end
    SLASH_COMMANDS["/rl"]           = reloadTheUI
    SLASH_COMMANDS["/rlui"]         = reloadTheUI
    SLASH_COMMANDS["/reload"]       = reloadTheUI

    --Logout charakter
    local function logoutNow()
        Logout()
    end
    SLASH_COMMANDS["/lo"]           = logoutNow

    --Quit the game
    local function quitNow()
        Quit()
    end
    SLASH_COMMANDS["/q"]            = quitNow

    SLASH_COMMANDS["/esc"] =        function() ZO_SceneManager_ToggleGameMenuBinding() end

    SLASH_COMMANDS["/fcocstpgl"] = function() FCOChangeStuff.PortToGroupLeader() end
    SLASH_COMMANDS["/tpgl"] = function() FCOChangeStuff.PortToGroupLeader() end
    SLASH_COMMANDS["/tppl"] = function() FCOChangeStuff.PortToGroupLeader() end
    SLASH_COMMANDS["/fcocstpgm"] = function(params) FCOChangeStuff.PortToGroupMember(params) end
    SLASH_COMMANDS["/tpgm"] = function(params) FCOChangeStuff.PortToGroupMember(params) end
    SLASH_COMMANDS["/tpp"] = function(params) FCOChangeStuff.PortToGroupMember(params) end
    SLASH_COMMANDS["/fcocstpfr"] = function(params) FCOChangeStuff.PortToFriend(params) end
    SLASH_COMMANDS["/tpfr"] = function(params) FCOChangeStuff.PortToFriend(params) end
    SLASH_COMMANDS["/fcocstpg"] = function(params) FCOChangeStuff.PortToGuildMember(params) end
    SLASH_COMMANDS["/tpg"] = function(params) FCOChangeStuff.PortToGuildMember(params) end
end
