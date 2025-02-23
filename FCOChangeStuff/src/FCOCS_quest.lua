if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

------------------------------------------------------------------------------------------------------------------------
-- Quest --
------------------------------------------------------------------------------------------------------------------------
local questTracker = ZO_FocusedQuestTrackerPanel
local questTrackerOnMoveHooked = false

function FCOChangeStuff.QuestTrackerLoadPosition()
    local questTrackerSavedPosition = FCOChangeStuff.settingsVars.settings.questTrackerPos
    if questTrackerSavedPosition.x > -1  and questTrackerSavedPosition.y > -1 then
        questTracker:ClearAnchors()
        questTracker:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, questTrackerSavedPosition.x, questTrackerSavedPosition.y)
    end
end

function FCOChangeStuff.QuestTrackerMovable(isMovable)
    isMovable = isMovable or false
    questTracker:SetMovable(isMovable)

    if not questTrackerOnMoveHooked then
        ZO_PostHookHandler(questTracker, "OnMoveStop", function(questTrackerCtrl)
            local settings = FCOChangeStuff.settingsVars.settings
            settings.questTrackerPos.x =  questTrackerCtrl:GetLeft()
            settings.questTrackerPos.y =  questTrackerCtrl:GetTop()
        end)
        questTrackerOnMoveHooked = true
    end

end


function FCOChangeStuff.QuestTrackerChanges()
    local settings = FCOChangeStuff.settingsVars.settings
    FCOChangeStuff.QuestTrackerMovable(settings.questTrackerMovable)
end

------------------------------------------------------------------------------------------------------------------------
--Enable the quest modifications
function FCOChangeStuff.questChanges()
    FCOChangeStuff.QuestTrackerChanges()
    FCOChangeStuff.QuestTrackerLoadPosition()
end
