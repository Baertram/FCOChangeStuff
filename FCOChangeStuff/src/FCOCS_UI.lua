if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS


local origPromotionalEventTrackerUpdate

local function updatePromotionalEventTrackerVisibilityState(doHide)
    if not doHide then
        --Nothing tracked? So do not show the Golden Pursuits UI
        local campaignKey, activityIndex = GetTrackedPromotionalEventActivityInfo()
        if campaignKey == 0 then
            doHide = true
        end
    end
    PROMOTIONAL_EVENT_TRACKER:GetFragment():SetHiddenForReason("NoTrackedPromotionalEvent", doHide, DEFAULT_HUD_DURATION, DEFAULT_HUD_DURATION)
end

local lastTrackedGoldenPursuitCampaignKey = nil

--[[
--ZO_PromotionalEventActivity_Entry_Keyboard.OnControlInitialized
--ZO_PromotionalEvents_KeyboardTLContentsActivityList1Row3TrackButton
-->ZO_PromotionalEventActivity_Entry_Keyboard:Initialize(control)
do
    SecurePostHook(ZO_PromotionalEventActivity_Entry_Keyboard, "Initialize", function(selfVar, control)
d("[FCOCS]ZO_PromotionalEventActivity_Entry_Keyboard:Initialize")
        --local trackButton = self.trackButton
        FCOCS._debugTrackButtons = FCOCS._debugTrackButtons or {}
        FCOCS._debugTrackButtons[selfVar] = selfVar
        --Add another posthook handler to the onclick so the tracked button defines the "lastTrackedGoldenPursuit"?

    end)
end
]]
function FCOChangeStuff.PromotionalEventTrackerUIChanges(hideNow)
    if PROMOTIONAL_EVENT_TRACKER == nil then return end
    if origPromotionalEventTrackerUpdate == nil then
        origPromotionalEventTrackerUpdate = PROMOTIONAL_EVENT_TRACKER.Update

        function PROMOTIONAL_EVENT_TRACKER.Update(selfVar)
            local settings = FCOChangeStuff.settingsVars.settings
            local dontAutoPinGoldenPursuits = settings.dontAutoPinGoldenPursuits

            --No setting enabled: Use vanilla code
            if not settings.hidePromotionalEventTracker and not settings.dontAutoPinFinishedGoldenPursuits then
                return origPromotionalEventTrackerUpdate(selfVar)
            end

            --Setting to always hide the golden pursuits UI enabled: Hide it now
            if settings.hidePromotionalEventTracker == true then
                updatePromotionalEventTrackerVisibilityState(true) -- Always hide UI tracker
                return
            end

            --ZOs vanilla code below: Do not hide if something tracked, BUT now also check if tracked is at 100% already and if that's the
            --case do not track that already finished anymore (if that setting in FCOCS is enabled)!
            local hidden = true
            if not IsPromotionalEventSystemLocked() then
                local campaignKey, activityIndex = GetTrackedPromotionalEventActivityInfo()
                if campaignKey ~= 0 then
                    --if no tracked campaignKey was found, then return here as we need to manually choose it!
                    if dontAutoPinGoldenPursuits == true then
                        if lastTrackedGoldenPursuitCampaignKey == nil then
d(">lastTrackedGoldenPursuit was not manually chosen! ABORT HERE")
                            updatePromotionalEventTrackerVisibilityState(true)
                            return
                        --A tracked campaignKey was chosen manually: But the current campaignKey does not match? Abort here
                        elseif lastTrackedGoldenPursuitCampaignKey ~= campaignKey then
d(">lastTrackedGoldenPursuit: " ..tostring(lastTrackedGoldenPursuitCampaignKey) .. " does not equal campaignKey: " .. tostring(campaignKey) .. " ABORT HERE!")
                            updatePromotionalEventTrackerVisibilityState(true)
                            return
                        end
                    end

                    local campaignData = PROMOTIONAL_EVENT_MANAGER:GetCampaignDataByKey(campaignKey)
                    if campaignData then
                        local activityData = campaignData:GetActivityData(activityIndex)
                        if activityData then
                            local doUpdateTracked = true

                            local progress = activityData:GetProgress()
                            local completionThreshold = activityData:GetCompletionThreshold()
d(">progress: " ..tostring(progress) .. ", completionThreshold: " .. tostring(completionThreshold))

                            --[[
                            --Reset last tracked if current one tracked got fullfilled
                            if progress >= completionThreshold then
d(">resetting lastTrackedGoldenPursuitCampaignKey so next can be tracked")
                                lastTrackedGoldenPursuitCampaignKey = nil
                            end
                            ]]

                            if doUpdateTracked then
                                selfVar:SetSubLabelText(activityData:GetDisplayName())

                                local progressText = zo_strformat(SI_PROMOTIONAL_EVENT_TRACKER_PROGRESS_FORMATTER, ZO_CommaDelimitNumber(progress), ZO_CommaDelimitNumber(completionThreshold))
                                selfVar.progressLabel:SetText(progressText)
                                hidden = false
                            end
                        end
                    end
                end
            end
            updatePromotionalEventTrackerVisibilityState(hidden)
        end
    end


------------------------------------------------------------------------------------------
    --Called with "hide now" then hidde/show the UI
    if hideNow ~= nil then
        updatePromotionalEventTrackerVisibilityState(hideNow)
    end
end

function FCOChangeStuff.TogglePromotionalEventTrackerUI()
    FCOChangeStuff.settingsVars.settings.hidePromotionalEventTracker = not FCOChangeStuff.settingsVars.settings.hidePromotionalEventTracker
    updatePromotionalEventTrackerVisibilityState(FCOChangeStuff.settingsVars.settings.hidePromotionalEventTracker)
end

function FCOChangeStuff.UIChanges()
    ZO_PreHook("TryAutoTrackNextPromotionalEventCampaign", function()
        --Do not auto track next campaign
d("[FCOCS]TryAutoTrackNextPromotionalEventCampaign Prehook")
        --Reset the manually chosen campaign ID
        lastTrackedGoldenPursuitCampaignKey = nil

        if FCOChangeStuff.settingsVars.settings.dontAutoPinGoldenPursuits then
d("<<ABORTED!")
            return true
        end
        return false
    end)

    --Radiobutton group of the golden pursuits "TrackedButtons". On change callback set the currently selected/tracked campaignId
    --and if any update happens check if the same campaignId was used. If not: Abort update of the tracked UI and hide it
    SecurePostHook(PROMOTIONAL_EVENTS_KEYBOARD, "OnDeferredInitialize", function()
        SecurePostHook(PROMOTIONAL_EVENTS_KEYBOARD.trackedActivityRadioButtonGroup, "onSelectionChangedCallback", function()
d("[FCOCS]PROMOTIONAL_EVENTS_KEYBOARD.trackedActivityRadioButtonGroup:onSelectionChangedCallback")
            --Reset to nil as we always could have unchecked all trackers!
            lastTrackedGoldenPursuitCampaignKey = nil

            --Setting to not auto Pin golden pursuits is disabled? Abort here now
            if not FCOChangeStuff.settingsVars.settings.dontAutoPinGoldenPursuits then return end

            --Get the selected radiobuton group button and get it's campaignKey -> Save to lastTrackedGoldenPursuitCampaignKey for comparison
            --in the PROMOTIONAL_EVENTS_KEYBOARD.Update function etc.
            local selectedButton = PROMOTIONAL_EVENTS_KEYBOARD.trackedActivityRadioButtonGroup.m_clickedButton
            if selectedButton and selectedButton.parentObject and selectedButton.parentObject.activityData
                    and selectedButton.parentObject.activityData.dataSource and selectedButton.parentObject.activityData.dataSource.campaignData
                    and selectedButton.parentObject.activityData.dataSource.campaignData.campaignKey then
                lastTrackedGoldenPursuitCampaignKey = selectedButton.parentObject.activityData.dataSource.campaignData.campaignKey
d(">set lastTrackedGoldenPursuit to: " ..tostring(lastTrackedGoldenPursuitCampaignKey))
            else
                --Security check if anything is still tracked and just the buttons did not update?!
                lastTrackedGoldenPursuitCampaignKey = GetTrackedPromotionalEventActivityInfo()
                if lastTrackedGoldenPursuitCampaignKey == 0 then lastTrackedGoldenPursuitCampaignKey = nil end
            end
        end)
    end)

    FCOChangeStuff.PromotionalEventTrackerUIChanges()
end