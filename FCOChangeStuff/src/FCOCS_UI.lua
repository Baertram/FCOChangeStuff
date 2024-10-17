if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS


local origPromotionalEventTrackerUpdate
local origPromotionalEventTrackerUpdateOverwritten = false

local function updatePromotionalEventTrackerVisibilityState(doHide)
    PROMOTIONAL_EVENT_TRACKER:GetFragment():SetHiddenForReason("NoTrackedPromotionalEvent", doHide, DEFAULT_HUD_DURATION, DEFAULT_HUD_DURATION)
end

function FCOChangeStuff.PromotionalEventTrackerUIChanges(hideNow)
    if PROMOTIONAL_EVENT_TRACKER == nil then return end
    origPromotionalEventTrackerUpdate = origPromotionalEventTrackerUpdate or PROMOTIONAL_EVENT_TRACKER.Update

    if not FCOChangeStuff.settingsVars.settings.hidePromotionalEventTracker then return end

    if not origPromotionalEventTrackerUpdateOverwritten then
        function PROMOTIONAL_EVENT_TRACKER.Update()
            if FCOChangeStuff.settingsVars.settings.hidePromotionalEventTracker == true then
                updatePromotionalEventTrackerVisibilityState(true) -- Always hide
            else
                return origPromotionalEventTrackerUpdate()
            end
        end
        origPromotionalEventTrackerUpdateOverwritten = true
    end

    if hideNow == true then
        updatePromotionalEventTrackerVisibilityState(true)
    end
end

function FCOChangeStuff.UIChanges()
    FCOChangeStuff.PromotionalEventTrackerUIChanges()
end