if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

local sceneHooksDoneAt = {}

function FCOChangeStuff.EnableCharacterFragment(where)
    if not where or where == "" then return end
    local settings = FCOChangeStuff.settingsVars.settings
    local whereToScene = {
        ["bank"] = nil,
        ["guildbank"] = nil,
    }
    local whereToSceneByName = {
        ["bank"]      = "bank",
        ["guildbank"] = "guildBank",
    }
    --[[
    local whereToFragment = {
        ["bank"] = BANK_FRAGMENT,
    }
    ]]
    local whereToAddNewFragments = {
        ["bank"] = {
            CHARACTER_WINDOW_FRAGMENT,
            CHARACTER_WINDOW_STATS_FRAGMENT,
            LEFT_PANEL_BG_FRAGMENT,
        }
    }
    whereToAddNewFragments["guildBank"] = whereToAddNewFragments["bank"]

    local sceneToHook = whereToScene[where]
    local sceneToHookName
    if not sceneToHook then
        sceneToHookName = whereToSceneByName[where]
    end
    if not sceneToHookName or sceneToHookName == "" then return end
    sceneToHook = SCENE_MANAGER:GetScene(sceneToHookName)
    if not sceneToHook then return end
    --local fragmentToHook = whereToFragment[where]
    --if not fragmentToHook then return end
    local fragmentsToAddNew = whereToAddNewFragments[where]
    if not fragmentsToAddNew then return end

    local function removeFragments()
        for _, fragmentToAddNew in ipairs(fragmentsToAddNew) do
            sceneToHook:RemoveFragment(fragmentToAddNew)
        end
    end
    local function sceneStateChange(oldState, newState, whereWasItDone)
        if whereWasItDone and sceneHooksDoneAt[whereWasItDone] == true then
            if whereWasItDone == "bank" and not settings.showCharacterPanelAtBank then
                removeFragments()
                return
            end
            if whereWasItDone == "guildbank" and not settings.showCharacterPanelAtGuildBank then
                removeFragments()
                return
            end
        end
        if newState == SCENE_SHOWN then
            for _, fragmentToAddNew in ipairs(fragmentsToAddNew) do
                sceneToHook:AddFragment(fragmentToAddNew)
            end
        elseif newState == SCENE_HIDDEN then
            removeFragments()
        end
    end
    if where == "bank" and settings.showCharacterPanelAtBank == true
       or where == "guildbank" and settings.showCharacterPanelAtGuildBank  == true
    then
        sceneHooksDoneAt[where] = true
        sceneToHook:RegisterCallback("StateChange", function(oldState, newState) sceneStateChange(oldState, newState, where) end)
    end
end

--Enable the bank modifications
function FCOChangeStuff.bankChanges()
    FCOChangeStuff.EnableCharacterFragment("bank")
    FCOChangeStuff.EnableCharacterFragment("guildbank")
end