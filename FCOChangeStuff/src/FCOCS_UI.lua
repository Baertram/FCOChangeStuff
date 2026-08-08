if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

local addonVars = FCOChangeStuff.addonVars
local addButton = FCOChangeStuff.AddButton

--======================================================================================================================
--PROMOTIONAL EVENT TRACKER (Golden Pursuits)
--======================================================================================================================
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
--d(">lastTrackedGoldenPursuit was not manually chosen! ABORT HERE")
                            updatePromotionalEventTrackerVisibilityState(true)
                            return
                        --A tracked campaignKey was chosen manually: But the current campaignKey does not match? Abort here
                        elseif lastTrackedGoldenPursuitCampaignKey ~= campaignKey then
--d(">lastTrackedGoldenPursuit: " ..tostring(lastTrackedGoldenPursuitCampaignKey) .. " does not equal campaignKey: " .. tostring(campaignKey) .. " ABORT HERE!")
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
--d(">progress: " ..tostring(progress) .. ", completionThreshold: " .. tostring(completionThreshold))

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




--======================================================================================================================
--STATS PANEL / INVENTORY CHARACTER, LEFT SIDE
--======================================================================================================================
local statsSceneStateChangeCallbackRegistered = false

local origHeights              = {}
local origRowHeightInv = 24
--[[
local origDividerHeight = 4
local origHeaderHeight = 25.380004882812
local origRowHeight = 24
]]
local changedYet = false
local statsPanelMundusControls = {}

local function changeStatsPanelMundusRow(doHide, ctrlsToProcess, recursiveCall)
--d("[FCOCS]changeStatsPanelMundusRow - doHide: " ..tostring(doHide) .. ", ctrlsToProcess: " ..tostring(ctrlsToProcess) .. "; recursiveCall: " .. tostring(recursiveCall))
    for _, ctrlData in ipairs(ctrlsToProcess) do
        local ctrl = ctrlData.ctrl
        if ctrl ~= nil and ctrl.SetHidden and ctrl.SetHeight then
            if doHide == true and origHeights[ctrl] == nil then
                origHeights[ctrl] = ctrl:GetHeight()
--d(">origHeight: " ..tostring(origHeights[ctrl]))
            end
            if ctrlData.process then
--d(">ctrlData.process")
                ctrl:SetHidden(doHide)
                ctrl:SetHeight(doHide and 0 or origHeights[ctrl])
                if doHide and ctrl:GetHeight() > 0 then
                   ctrl:SetHeight(1)
                end
            end
            if ctrlData.processChildren then
                local numChildren = ctrl:GetNumChildren()
                if numChildren > 0 then
--d(">numChildren: " ..tostring(numChildren))
                    local childCtrlsToProcess = {}
                    for i=1, numChildren, 1 do
                        local childCtrl = ctrl:GetChild(i)
                        if childCtrl ~= nil then
--d(">child: " ..tostring(childCtrl:GetName()))
                            childCtrlsToProcess[i] = { ctrl=childCtrl, process=true, processChildren=true }
                        end
                    end
                    if not ZO_IsTableEmpty(childCtrlsToProcess) then
                        changeStatsPanelMundusRow(doHide, childCtrlsToProcess, true)
                    end
                end
            end
        end
    end

end

--Inventory, left side panel
local function changeInventoryCharacterLeftSideMundusRow(doHide)
    ZO_CharacterWindowStatsScrollScrollChildZO_MundusStonesStatsEntry:SetHeight(doHide and 0 or origRowHeightInv)
    ZO_CharacterWindowStatsScrollScrollChildZO_MundusStonesStatsEntry:SetHidden(doHide)
end

function FCOChangeStuff.StatsPanelUIChanges(doHide)
    if doHide == nil then
        doHide = FCOChangeStuff.settingsVars.settings.hideStatsPanelMundusRow
    end

    --Character Stats
    if not statsSceneStateChangeCallbackRegistered and doHide == true then
        STATS_SCENE:RegisterCallback("StateChange", function(oldState, newState)
            if newState == SCENE_SHOWING then
                if not changedYet then
                    statsPanelMundusControls = {
                        [1] =  { ctrl=ZO_StatsPanelPaneScrollChildDivider3,     process=true, processChildren=false },
                        [2] =  { ctrl=ZO_StatsPanelPaneScrollChildHeader3,      process=true, processChildren=false },
                        [3] =  { ctrl=ZO_StatsPanelPaneScrollChildMundusRow1,   process=true, processChildren=true }
                    }
                end

                --d("[FCOCS]STATS_SCENE - newState: " ..tostring(newState) .. ", doHide: " .. tostring(doHide) .. "; setting: " ..tostring(FCOChangeStuff.settingsVars.settings.hideStatsPanelMundusRow))
                if FCOChangeStuff.settingsVars.settings.hideStatsPanelMundusRow == true then
                    --[[
                    --Hide divider
                    ZO_StatsPanelPaneScrollChildDivider3:SetHeight(0)
                    ZO_StatsPanelPaneScrollChildDivider3:SetHidden(true)
                    --Hide header --> SI_STATS_MUNDUS_TITLE
                    ZO_StatsPanelPaneScrollChildHeader3:SetHeight(0)
                    ZO_StatsPanelPaneScrollChildHeader3:SetHidden(true)
                    --Hide row
                    ZO_StatsPanelPaneScrollChildMundusRow1:SetHeight(0)
                    ZO_StatsPanelPaneScrollChildMundusRow1:SetHidden(true)
                    ]]
                    changeStatsPanelMundusRow(true, statsPanelMundusControls)
                    changedYet = true
                else
                    if changedYet == true then
                        --[[
                        --Show divider
                        ZO_StatsPanelPaneScrollChildDivider3:SetHeight(origDividerHeight)
                        ZO_StatsPanelPaneScrollChildDivider3:SetHidden(false)
                        --Show header --> SI_STATS_MUNDUS_TITLE
                        ZO_StatsPanelPaneScrollChildHeader3:SetHeight(origHeaderHeight)
                        ZO_StatsPanelPaneScrollChildHeader3:SetHidden(false)
                        --Show row
                        ZO_StatsPanelPaneScrollChildMundusRow1:SetHeight(origRowHeight)
                        ZO_StatsPanelPaneScrollChildMundusRow1:SetHidden(false)
                        ]]
                        changeStatsPanelMundusRow(false, statsPanelMundusControls)
                    end
                end
            end
        end)
        statsSceneStateChangeCallbackRegistered = true
    end

    --Inventory, character screen at the left side
    changeInventoryCharacterLeftSideMundusRow(doHide)
end


------------------------------------------------------------------------------------------------------------------------
--- HUD Editor
------------------------------------------------------------------------------------------------------------------------
local LCM = LibCustomMenu

--CLASSES
local HM_Class      = ZO_HUDManager
--local HME_Class = ZO_HUDManager_Element
local HEK_Class_KB  = ZO_HUDEditor_Keyboard
local HEEK_Class_KB = ZO_HUDEditorElement_Keyboard


--OBJECTS
local HM            = HUD_MANAGER
local HEK_KB        = HUD_EDITOR_KEYBOARD

local suppressCallbacks = true
local onText = GetString(SI_SCREEN_NARRATION_TOGGLE_ON)
local offText = GetString(SI_SCREEN_NARRATION_TOGGLE_OFF)
local HUDEditorContextMenuText = GetString(SI_GAME_MENU_EDIT_HUD)
local visibleText = GetString(SI_HUD_EDITOR_CUSTOM_OPTION_VISIBLE)

--Custom border color for the hidden state, at the HUD editor
ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD.selectedHidden = ZO_ShallowTableCopy(ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD.selected)
ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD.unselectedHidden = ZO_ShallowTableCopy(ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD.unselected)
local defaultSelectedHidden = ZO_ColorDef:New("FF0000")
local defaultUnselectedHidden = ZO_ColorDef:New("F00000")
ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD.selectedHidden.edge = defaultSelectedHidden
ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD.unselectedHidden.edge = defaultUnselectedHidden

local function getElementObject(elementCtrl)
    return elementCtrl and elementCtrl.object or nil
end
local function getElementData(elementCtrl, elementObject)
    if not elementCtrl and not elementObject then return end
    elementObject = elementObject or getElementObject(elementCtrl)
    return (elementObject and elementObject:GetElementData()) or nil
end

local function getElementDisplayName(elementCtrl, elementObject)
    if not elementCtrl and not elementObject then return "n/a" end
    elementObject = elementObject or getElementObject(elementCtrl)
    local elementData = getElementData(elementCtrl, elementObject)
    if not elementData then return "n/a" end
    return elementData:GetDisplayName()
end

local function getElementRealTLCName(elementCtrl, elementObject)
    if not elementCtrl and not elementObject then return nil, nil, nil end
    elementObject = elementObject or getElementObject(elementCtrl)
    local elementData = getElementData(elementCtrl, elementObject)
    if elementData == nil or elementObject == nil then return nil, nil, nil end
    local TLCName = ((elementData.saveKey) or (elementData.control and elementData.control.GetName and elementData.control:GetName())) or nil
    return TLCName, elementObject, elementData
end

local function getHUDElementHiddenState(elementName)
    return (elementName ~= nil and elementName ~= "" and FCOChangeStuff.settingsVars.settings.HUDEditHiddenControls[elementName]) or nil
end

local function setHUDElementHiddenState(elementName, newState, elementCtrl)
    if elementName == nil or elementName == "" then return end
    FCOChangeStuff.settingsVars.settings.HUDEditHiddenControls[elementName] = newState

    --Attention this will also change the HUD editor popup dialog "Visible" setting and might change the SavedVariables
    --of ZOs vanilla ZO_Ingame_SavedVariables -> $AccountWide -> ZO_HUDManager too!
    --> Reason: The IsHidden function maybe returning the default value for the Visible customOptions! So opening the HUD editor for that element
    --> after using the contextMenu to hide the control, might switch the SVs for that control to "Visible" -> False :-(

    --> Workaround idea: PreHook into ZO_HUDEditor_Keyboard:ApplyInfoBoxValues(overrideElement), check if "selectedElement" is in the table
    --> FCOChangeStuff.settingsVars.settings.HUDEditHiddenControls[elementCtrl] and skip customOptions update for "Visible" state then
    if elementCtrl then
        elementCtrl:SetHidden(newState)
    end

    return true
end


local function hideElementUIInHUDOrEditor(elementCtrl, elementName, hideInHUDEditor)
--d("[FCOCS]hideElementUIInHUDEditor - hideInHUDEditor: " ..tostring(hideInHUDEditor))
    if not elementCtrl or hideInHUDEditor == nil then return end
    if hideInHUDEditor == false then hideInHUDEditor = nil end
    local elementName = getElementRealTLCName(elementCtrl, nil)
    if setHUDElementHiddenState(elementName, hideInHUDEditor, elementCtrl) == true then
        d("[FCOCS]HUD Editor element '" .. tostring((hideInHUDEditor == true and SCENE_HIDDEN) or SCENE_SHOWN) .. "': '" ..tostring(getElementDisplayName(elementCtrl) .."' - " .. tostring(elementName)))
        return true
    end
end

--[[
local function getCustomOptionsByKey(elementObject, keyName)
    if not elementObject then return end
    local options = elementObject:GetCustomOptions()
    if ZO_IsTableEmpty(options) then return end
    for _, optionData in ipairs(options) do
        if optionData.key == keyName then
            return optionData
        end
    end
    return nil
end
]]

local function showHUDElementContextMenu(elementCtrl)
    ClearMenu()

    local elementName, elementObject, elementData = getElementRealTLCName(elementCtrl, nil)
    if not elementObject or not elementData then return end

    --Does not work as element will not be selected via right click with the mouse, only upln left click as InfoBox dialog opens!
    --local selectedElement = HUD_EDITOR_KEYBOARD:GetSelectedElement()
    --if not selectedElement then return end
    --[[
    local optionsDataOfKeyVisible = getCustomOptionsByKey(elementObject, "Visible")
    if optionsDataOfKeyVisible ~= nil then
        visibleText = optionsDataOfKeyVisible.name
    end
    ]]

    --Hide control in HUD editor (not on real HUD!)
    if LCM then
        AddCustomMenuItem(HUDEditorContextMenuText .. " - " .. elementName, nil, MENU_ADD_OPTION_HEADER)
    end
    local isHCurrentlyHiddenInHUDEditor = getHUDElementHiddenState(elementName)
--d(">isHiddenInHUDEditor: " ..tostring(isHCurrentlyHiddenInHUDEditor))
    AddMenuItem(((LCM == nil and elementName .. " - ") or "") .. visibleText .. ": " .. ((isHCurrentlyHiddenInHUDEditor and onText) or offText),
            function() hideElementUIInHUDOrEditor(elementCtrl, elementName, not isHCurrentlyHiddenInHUDEditor) end)
    ShowMenu()
end

local function onMouseUpShowContextMenuAtHUDEditElementHandler(elementCtrl, button, upInside)
--d("[FCOCS]HUDElement_OnMouseUpHook - button: " ..tostring(button) .. ", upInside: " ..tostring(upInside))
    if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
        showHUDElementContextMenu(elementCtrl)
    end
end

local function updateHUDEditorElementHiddenState(elementCtrl)
    --local elementObject = elementCtrl.object
    if elementCtrl ~= nil then
        local elementName = getElementRealTLCName(elementCtrl, nil)
        local HUDEditorUserChosenHiddenState = getHUDElementHiddenState(elementName)
        if HUDEditorUserChosenHiddenState == true then
            --Hide the elementCtrl now
            elementCtrl:SetHidden(true)
            return true
        --else do nothing as it is automatically shown
        end
    end
end

local function updateHUDEditorElementBorderColor(elementObject)
    if elementObject.elementData == nil then return end
    local optionsDataOfKeyVisible = elementObject:GetCustomOptionValue("Visible")
--d(">>optionsDataOfKeyVisible: " ..tostring(optionsDataOfKeyVisible))
    FCOChangeStuff._optionsDataOfKeyVisible = optionsDataOfKeyVisible
    if optionsDataOfKeyVisible ~= nil then
        local changeBorderColor = false
        local borderColors = elementObject.selected and ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD.selected or ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD.unselected
        local typeOfVisibleOption = type(optionsDataOfKeyVisible)
        if typeOfVisibleOption == "boolean" then
            if optionsDataOfKeyVisible == true then
                changeBorderColor = true
            else
                changeBorderColor = true
                --Change the borderColor to use a red outline
                borderColors = elementObject.selected and ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD.selectedHidden or ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD.unselectedHidden
            end
        elseif typeOfVisibleOption == "string" then
            --"Automatic" ?
        elseif typeOfVisibleOption == "number" then
            if optionsDataOfKeyVisible == 0 then
                changeBorderColor = true
                --Change the borderColor to use a red outline
                borderColors = elementObject.selected and ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD.selectedHidden or ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD.unselectedHidden
            elseif optionsDataOfKeyVisible == 1 then
                changeBorderColor = true
            end
        end
        if changeBorderColor == true and borderColors ~= nil then
            elementObject.control:SetEdgeColor(borderColors.edge:UnpackRGBA())
        end
    end
end

function FCOChangeStuff.HUDUI_UpdateColor(svValueName, resetToDefault)
    if svValueName == "HUDEditHiddenBorderColor" then
        local borderColorHiddenHUDElements = FCOChangeStuff.settingsVars.settings[svValueName]
        if borderColorHiddenHUDElements ~= nil then
            if resetToDefault == true then
                ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD.selectedHidden.edge = defaultSelectedHidden
                ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD.unselectedHidden.edge = defaultUnselectedHidden
            else
                ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD.selectedHidden.edge = ZO_ColorDef:New(borderColorHiddenHUDElements.r, borderColorHiddenHUDElements.g, borderColorHiddenHUDElements.b, borderColorHiddenHUDElements.a)
                ZO_HUD_EDITOR_ELEMENT_COLORS_KEYBOARD.unselectedHidden.edge = ZO_ColorDef:New(borderColorHiddenHUDElements.r, borderColorHiddenHUDElements.g, borderColorHiddenHUDElements.b, borderColorHiddenHUDElements.a)
            end
        end
    end
end

local HEEKOnMouseUpFunctionHooked = false
local HEEKRefreshColorsHooked = false
local HEKDropdownLibScrollableMenuHooked = false
local infoBoxShownAtSceneChangeHookDone = false
local infoBoxSettingsButton

local function getHUDEditorInfoBoxSettingsContextMenu()

end

local buttonDataHUDEditInfoBoxSettings =
{
    buttonName      = "HUDEditInfoBoxSettingsContextMenu",
    parentControl   = HEK_KB.infoBox,
    tooltip         = addonVars.addonNameMenuDisplay .." HUD Editor settings",
    callback        = function()
        return getHUDEditorInfoBoxSettingsContextMenu()
    end,
    width           = 32,
    height          = 32,
    normal          = "/esoui/art/chatwindow/chat_options_up.dds",
    pressed         = "/esoui/art/chatwindow/chat_options_down.dds",
    highlight       = "/esoui/art/chatwindow/chat_options_over.dds",
    disabled        = "/esoui/art/chatwindow/chat_options_disabled.dds",
    visible         = function() return FCOChangeStuff.settingsVars.settings.showHUDEditorInfoBoxSettingsButton end
}

local function HUDManagerAndHUDEditorKeyboard_Hooks(fromSceneChange)
    local settings = FCOChangeStuff.settingsVars.settings

    ----------------------------
    --ContextMenu button for settings, top left at the InfoBox
    if fromSceneChange == true and not infoBoxShownAtSceneChangeHookDone then
        if buttonDataHUDEditInfoBoxSettings.parentControl == nil then
            buttonDataHUDEditInfoBoxSettings.parentControl = HEK_KB.infoBox
        end

        ZO_PostHookHandler(buttonDataHUDEditInfoBoxSettings.parentControl, "OnEffectivelyShown", function()
            if infoBoxSettingsButton == nil and settings.showHUDEditorInfoBoxSettingsButton == true then
                addButton = addButton or FCOChangeStuff.AddButton
                infoBoxSettingsButton = addButton(TOPLEFT, buttonDataHUDEditInfoBoxSettings.parentControl, TOPLEFT, 10, 10, buttonDataHUDEditInfoBoxSettings)
FCOChangeStuff._infoBoxSettingsButton = infoBoxSettingsButton
                infoBoxSettingsButton.type = "settings"
            end
            infoBoxSettingsButton:SetDrawTier(DT_HIGH)
            infoBoxSettingsButton:SetDrawLayer(DL_CONTROLS)
            infoBoxSettingsButton:SetDrawLevel(ZO_HUD_EDITOR_KEYBOARD_INFO_BOX_INTERACTABLE_ELEMENT_LEVEL)
            infoBoxSettingsButton:SetMouseOverBlendMode(TEX_BLEND_MODE_ADD)
            local textureControl = GetControl(infoBoxSettingsButton, "Texture")
            textureControl:SetColor(1, 1, 1, 1)
        end)
        infoBoxShownAtSceneChangeHookDone = true
    end


    ----------------------------
    --LibScrollableMenu usage at InfoBox
    if not HEKDropdownLibScrollableMenuHooked and HEK_KB.infoBoxSelector ~= nil and LibScrollableMenu ~= nil and AddCustomScrollableComboBoxDropdownMenu ~= nil then
        --Add LibScrollableMenu to existing "HUD Edit InfoBox" dropdown, to enable the search editBox header
        --HEK_KB.infoBoxSelectorDropdown -> ZO_ComboBox_ObjectFromContainer(HEK.infoBoxSelector)
        local options = { enableFilter = true, headerCollapsible = true, visibleRowsDropdown = 15, automaticRefresh = true }
        AddCustomScrollableComboBoxDropdownMenu(HEK_KB.infoBox, HEK_KB.infoBoxSelector, options)
        HEKDropdownLibScrollableMenuHooked = true

        --The function to add the entries to the dropdown, in vanilla, is: ZO_HUDEditor_Keyboard:RefreshInfoBox()
        --> Hook into it to color hidden HUDEditor controls red (and add a [ ] around them, for visually impaired players)
        local function OnElementSelectorDropdownEntryMouseEnter(control)
            control.m_data.object:OnMouseEnter()
        end

        local function OnElementSelectorDropdownEntryMouseExit(control)
            control.m_data.object:OnMouseExit()
        end

        local contextMenuCallbackFunc = function(comboBox, control, data)
            ClearCustomScrollableMenu()
            --Get currently clicked contextMenu opening entry data
            if data ~= nil then
                local elementName = data.name
                local elementCtrl = data._elementCtrl
                local object = data.object
                if object and elementCtrl then
                    local elementNameForSVCHeck = data._elementRealTLCName or getElementRealTLCName(nil, object)
                    if getHUDElementHiddenState(elementNameForSVCHeck) == true then
                        --Unhide element in HUDEditor again
                        AddCustomScrollableMenuEntry("Unhide at HUD Editor", function()
                            if hideElementUIInHUDOrEditor(elementCtrl, elementName, false) == true then
                                RefreshCustomScrollableMenu(control, LSM_UPDATE_MODE_MAINMENU, comboBox)
                            end
                        end, LSM_ENTRY_TYPE_NORMAL)
                    else
                        --Hide element in HUDEditor again
                        AddCustomScrollableMenuEntry("Hide at HUD Editor", function()
                            if hideElementUIInHUDOrEditor(elementCtrl, elementName, true) == true then
                                RefreshCustomScrollableMenu(control, LSM_UPDATE_MODE_MAINMENU, comboBox)
                            end
                        end, LSM_ENTRY_TYPE_NORMAL)
                    end
                    ShowCustomScrollableMenu(nil)
                end
            end
        end
        local selectFunction = function(comboBox, entryText, entry) entry.object:Select() end
        local function CreateItemEntryForLSM(elementCtrl)
            --local elementNameOrig = getElementDisplayName(elementCtrl, elementCtrl.object) --elementCtrl.object:GetElementData():GetDisplayName()
            local elementNameForSVCheck = getElementRealTLCName(elementCtrl, elementCtrl.object)

            local entry = {
                --ZOs vanilla needed
                object = elementCtrl.object,

                --LibScrollableMenu needed
                name = function() --Use function to let RefreshCustomScrollableMenu update the entry directly after the change - via contextMenu
                    local elementNameOrigNow = getElementDisplayName(elementCtrl, elementCtrl.object) --elementCtrl.object:GetElementData():GetDisplayName()
                    local elementNameForHiddenInHudEditorCheck = getElementRealTLCName(elementCtrl, elementCtrl.object)
                    if getHUDElementHiddenState(elementNameForHiddenInHudEditorCheck) == true then
                        return "|cFF0000- " .. elementNameOrigNow .. "|r -"
                    end
                    return elementNameOrigNow
                end,
                --label = elementNameOrig, --optional, might be nil. If nil name will be used instead
                tooltip = function() --Use function to let RefreshCustomScrollableMenu update the entry directly after the change - via contextMenu
                    local elementNameOrigNow = getElementDisplayName(elementCtrl, elementCtrl.object) --elementCtrl.object:GetElementData():GetDisplayName()
                    local elementNameForHiddenInHudEditorCheck = getElementRealTLCName(elementCtrl, elementCtrl.object)
                    return elementNameOrigNow .. " - " .. tostring(elementNameForHiddenInHudEditorCheck)
                end,

                callback = function(comboBox, ...) return selectFunction(comboBox, ...) end,

                --LSM ContextMenu
                -----Added to determine contextMenu things later
                ---element = element,
                _elementCtrl = elementCtrl,
                _elementRealTLCName = elementNameForSVCheck,

                contextMenuCallback = contextMenuCallbackFunc,
            }
            return entry
        end

        SecurePostHook(HEK_Class_KB, "RefreshInfoBox", function(selfVar)
            local selectedElement = selfVar:GetSelectedElement()
            if selectedElement then
                local itemsTable = {}

                local comboBoxObject = selfVar.infoBoxSelectorDropdown
                comboBoxObject:ClearItems()
                local selectedEntry = nil
                for _, element in ipairs(selfVar.elementControls) do
                    local elementEntry = CreateItemEntryForLSM(element)
                    itemsTable[#itemsTable + 1] = elementEntry

                    if selectedElement == elementEntry.object then
                        selectedEntry = elementEntry
                    end
                    comboBoxObject:SetItemOnEnter(elementEntry, OnElementSelectorDropdownEntryMouseEnter)
                    comboBoxObject:SetItemOnExit(elementEntry, OnElementSelectorDropdownEntryMouseExit)
                end
                if #itemsTable > 0 then
                    comboBoxObject:AddItems(itemsTable)

                    local IGNORE_CALLBACK = true
                    if selectedEntry then
                        comboBoxObject:SelectItem(selectedEntry, IGNORE_CALLBACK)
                    else
                        --In theory there should always be a selected entry, but have this as a fallback just in case
                        comboBoxObject:SelectFirstItem()
                    end
                end
            end
        end)
    end

    ----------------------------
    --ContextMenu at HUD Edit elements
    if settings.HUDEditContextMenu == true then
        if not HEEKOnMouseUpFunctionHooked then
            SecurePostHook(HEEK_Class_KB, "OnMouseUp", function(selfVar, elementCtrl, button, upInside)
                local elementData = elementCtrl.object ~= nil and elementCtrl.object:GetElementData()
                if not elementData or not FCOChangeStuff.settingsVars.settings.HUDEditContextMenu then return end
                --d("[FCOCS]HUDElementKeyboard:OnMouseUp - name: " ..tostring(elementData and elementData.displayName or "N/A"))
                onMouseUpShowContextMenuAtHUDEditElementHandler(elementCtrl, button, upInside)
            end)
            HEEKOnMouseUpFunctionHooked = true
        end

        if not HEEKRefreshColorsHooked then
            --Update edge color for element controls in the HUD editor where the mouse is moved over/away
            SecurePostHook(HEEK_Class_KB, "RefreshColors", function(elementObject)
                local elementData = elementObject:GetElementData()
                --d("[FCOCS]RefreshColors - name: " .. tostring(getElementDisplayName(nil, elementObject)))
                updateHUDEditorElementBorderColor(elementObject)
            end)
            --Update edge color for all looped element controls in the HUD editor -> Looped at Scene Shown via PopulateElementControls
            --> Only fires if Scene is re-opened, but not on first open of the scene :(
            SecurePostHook(HEK_Class_KB, "PopulateElementControls", function(selfVar, dataToSelect)
                --d("[FCOCS]PopulateElementControls - dataToSelect: " ..tostring(dataToSelect))
                local numUserHiddenHUDEditorElements = 0
                for _, element in ipairs(selfVar.elementControls) do
                    --Update the edge color for hidden elements in the UI
                    updateHUDEditorElementBorderColor(element.object)
                    --Hide elements in the HUD editor, if user chose to
                    if updateHUDEditorElementHiddenState(element) == true then
                        numUserHiddenHUDEditorElements = numUserHiddenHUDEditorElements + 1
                    end
                end
                if numUserHiddenHUDEditorElements > 0 then
                    d("[FCOCS]There are '" .. tostring(numUserHiddenHUDEditorElements) .."' user-hidden elements!")
                end

            end)
            HEEKRefreshColorsHooked = true
        end
    end --ContextMenu at HUD Editor elements
end

local HUDMovableControlsContextMenuAdded = false
function FCOChangeStuff.HUDUIStuff()
    if HUDMovableControlsContextMenuAdded == true or HM_Class == nil or HM == nil then return end

    --Register the hooks once here if settings are enabled already
    HUDManagerAndHUDEditorKeyboard_Hooks()

    --Register the hooks again later at the scene shown state
    HUD_EDITOR_SCENE_KEYBOARD:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            HUDManagerAndHUDEditorKeyboard_Hooks(true)
        end
    end)
    HUDMovableControlsContextMenuAdded = true
end
------------------------------------------------------------------------------------------------------------------------


function FCOChangeStuff.UIChanges()
    ZO_PreHook("TryAutoTrackNextPromotionalEventCampaign", function()
        --Do not auto track next campaign
--d("[FCOCS]TryAutoTrackNextPromotionalEventCampaign Prehook")
        --Reset the manually chosen campaign ID
        lastTrackedGoldenPursuitCampaignKey = nil

        if FCOChangeStuff.settingsVars.settings.dontAutoPinGoldenPursuits then
--d("<<ABORTED!")
            return true
        end
        return false
    end)

    --Radiobutton group of the golden pursuits "TrackedButtons". On change callback set the currently selected/tracked campaignId
    --and if any update happens check if the same campaignId was used. If not: Abort update of the tracked UI and hide it
    SecurePostHook(PROMOTIONAL_EVENTS_KEYBOARD, "OnDeferredInitialize", function()
        SecurePostHook(PROMOTIONAL_EVENTS_KEYBOARD.trackedActivityRadioButtonGroup, "onSelectionChangedCallback", function()
--d("[FCOCS]PROMOTIONAL_EVENTS_KEYBOARD.trackedActivityRadioButtonGroup:onSelectionChangedCallback")
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
--d(">set lastTrackedGoldenPursuit to: " ..tostring(lastTrackedGoldenPursuitCampaignKey))
            else
                --Security check if anything is still tracked and just the buttons did not update?!
                lastTrackedGoldenPursuitCampaignKey = GetTrackedPromotionalEventActivityInfo()
                if lastTrackedGoldenPursuitCampaignKey == 0 then lastTrackedGoldenPursuitCampaignKey = nil end
            end
        end)
    end)

    local settings = FCOChangeStuff.settingsVars.settings

    FCOChangeStuff.PromotionalEventTrackerUIChanges()
    FCOChangeStuff.StatsPanelUIChanges(settings.hideStatsPanelMundusRow)

    FCOChangeStuff.HUDUIStuff()
end