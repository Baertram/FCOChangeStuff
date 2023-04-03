if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

------------------------------------------------------------------------------------------------------------------------
-- Slash commands --
------------------------------------------------------------------------------------------------------------------------


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
end
