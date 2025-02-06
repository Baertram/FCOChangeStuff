if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS


local preventFCOCSPostHook                    = false
local origPromotionalEventTrackerUpdateHooked = false

local function updatePromotionalEventTrackerVisibilityState(doHide)
    if doHide == nil then
        preventFCOCSPostHook = true
        --Call updater routine to show or hide accordningly but do not use the FCOCS SecurePostHook then!
        PROMOTIONAL_EVENT_TRACKER:Update()
        preventFCOCSPostHook = false
        return
    end
    PROMOTIONAL_EVENT_TRACKER:GetFragment():SetHiddenForReason("NoTrackedPromotionalEvent", doHide, DEFAULT_HUD_DURATION, DEFAULT_HUD_DURATION)
end

function FCOChangeStuff.PromotionalEventTrackerUIChanges(hideNow)
    if PROMOTIONAL_EVENT_TRACKER == nil then return end

    if not hideNow and not FCOChangeStuff.settingsVars.settings.hidePromotionalEventTracker then
        updatePromotionalEventTrackerVisibilityState(nil)
        return
    end

    if not origPromotionalEventTrackerUpdateHooked then
        SecurePostHook(PROMOTIONAL_EVENT_TRACKER, "Update", function(...)
            if preventFCOCSPostHook then return end

            if FCOChangeStuff.settingsVars.settings.hidePromotionalEventTracker == true then
                updatePromotionalEventTrackerVisibilityState(true) -- Always hide
            end
        end)
        origPromotionalEventTrackerUpdateHooked = true
    end

    if hideNow == true then
        updatePromotionalEventTrackerVisibilityState(true)
    end
end

function FCOChangeStuff.UIChanges()
    FCOChangeStuff.PromotionalEventTrackerUIChanges()
end