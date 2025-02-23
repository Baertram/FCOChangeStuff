if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

------------------------------------------------------------------------------------------------------------------------
-- Quest --
------------------------------------------------------------------------------------------------------------------------
local questTrackerHeader1 = nil --ZO_FocusedQuestTrackerPanelContainerQuestContainerTrackedHeader1
local questTrackerOnMoveHooked = false

function FCOChangeStuff.QuestTrackerLoadPosition(onInit)
    if questTrackerHeader1 == nil then return end

    local settings = FCOChangeStuff.settingsVars.settings
    if settings.questTrackerMovable or onInit == true then
        local questTrackerSavedPosition = settings.questTrackerPos
        if questTrackerSavedPosition.x > -1  and questTrackerSavedPosition.y > -1 then
            questTrackerHeader1:ClearAnchors()
            questTrackerHeader1:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, questTrackerSavedPosition.x, questTrackerSavedPosition.y)
        end
    end
end

function FCOChangeStuff.QuestTrackerMovable(isMovable, loadPos)
    isMovable = isMovable or false
    questTrackerHeader1:SetMouseEnabled(isMovable)
    questTrackerHeader1:SetMovable(isMovable)

    if not questTrackerOnMoveHooked then
        local doNotSaveMovedPos = false
        questTrackerHeader1:SetHandler("OnMoveStop", function(questTrackerCtrl)
--d("[FCOCS]questTrackerHeader1:OnMoveStop")
            --if not isMoving then return end
            if doNotSaveMovedPos then
                doNotSaveMovedPos = false
                return
            end
            local settings = FCOChangeStuff.settingsVars.settings
            if settings.questTrackerMovable then
                settings.questTrackerPos.x =  questTrackerCtrl:GetLeft()
                settings.questTrackerPos.y =  questTrackerCtrl:GetTop()
            end
        end)

        ZO_PreHook(FOCUSED_QUEST_TRACKER, "AssistNext", function()
            doNotSaveMovedPos = true
        end)

        --Set callback function for quest tracker updated (e.g. if AssistNext function was called) and load the saved position again
        CALLBACK_MANAGER:RegisterCallback("QuestTrackerUpdatedOnScreen", function()
--d("[FCOCS]CALLBACK_MANAGER fired QuestTrackerUpdatedOnScreen")
            doNotSaveMovedPos = false
            if FCOChangeStuff.settingsVars.settings.questTrackerMovable then
                FCOChangeStuff.QuestTrackerLoadPosition()
            end
        end)

        questTrackerOnMoveHooked = true
    end

    if loadPos == true then
        FCOChangeStuff.QuestTrackerLoadPosition()
    end
end

function FCOChangeStuff.QuestTrackerChanges()
--d("[FCOCS]QuestTrackerChanges")
    FCOChangeStuff.QuestTrackerMovable(FCOChangeStuff.settingsVars.settings.questTrackerMovable)
end

------------------------------------------------------------------------------------------------------------------------
--Enable the quest modifications
function FCOChangeStuff.questChanges()
    questTrackerHeader1 = ZO_FocusedQuestTrackerPanelContainerQuestContainerTrackedHeader1
    FCOChangeStuff.QuestTrackerChanges()
    FCOChangeStuff.QuestTrackerLoadPosition(true)
end
