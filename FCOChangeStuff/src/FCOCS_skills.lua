if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

--======== SKILLS ============================================================

--Constant values

--The global variable for the skills
--SKILLS_WINDOW

--Categories in the skills window (left side -> Top labels with the categories which one can expand/collapse)
--SKILLS_WINDOW.navigationTree.rootNode.children

--Entries below the categories
--SKILLS_WINDOW.navigationTree.rootNode.children[n].children[n].control

--Entry can be made disabled:
--SKILLS_WINDOW.navigationTree.rootNode.children[n].children[n].control:SetEnabled(false)
--SKILLS_WINDOW.navigationTree.rootNode.children[n].children[n].control:SetMouseEnabled(false)
-->But this needs to be checked and done each time the parent node get's expanded
-->How is one able to enable/disable the entries (context mouse menu is not working if MouseEnabled(false)


--Abilities selected by help of the navigation tree on the left
--SKILLS_WINDOW.abilityList


local function changeSkillLineTypeEntry(ctrl, newStatus, isContextMenu)
    isContextMenu = isContextMenu or false
    if ctrl == nil then return false end
    if newStatus == nil and isContextMenu then return false end
    --Save the enabled state of the skilllineindex now
    local settings = FCOChangeStuff.settingsVars.settings
    if not settings.enableSkillLineContextMenu then return false end

    --Get the data of the entry
    local data = ctrl.node.data or ctrl.data
    --Check the data
    if data ~= nil then
        local foundError = false
        local skillLineTypeData = data
        local skillLineIndex = skillLineTypeData.skillLineIndex
        local skillType = skillLineTypeData.skillTypeData.skillType
        if skillLineIndex ~= nil and skillType ~= nil then

            --Called from the context menu? Change the savedvars
            if isContextMenu then
                --Enable/Disable the control (SkillLineType)
                ctrl:SetEnabled(newStatus)
                --Update the savedvars
                if settings.skillLineIndexState[skillLineIndex] == nil then
                    settings.skillLineIndexState[skillLineIndex] = {}
                end
                local newStatusSavedVars = nil
                if newStatus == false then
                    newStatusSavedVars = false
                end
                settings.skillLineIndexState[skillLineIndex][skillType] = newStatusSavedVars


            --Not called from the context menu? Read the savedvars and change the visible controls in teh skills_window
            else
                --Get the skillineindex
                local skillLineIndexSavedData = settings.skillLineIndexState[skillLineIndex]
                if skillLineIndexSavedData ~= nil then
                    local skillLineIndexState = skillLineIndexSavedData[skillType]
                    if skillLineIndexState ~= nil then
                        --Set the enabled state of the entry according to the settings
                        ctrl:SetEnabled(skillLineIndexState)
                        newStatus = skillLineIndexState
                    else
                        foundError = true
                    end
                else
                    foundError = true
                end
                --Fallback: Enable the skill line type entry
                if foundError then
                    ctrl:SetEnabled(true)
                    if newStatus == nil then
                        newStatus = false
                    end
                end
            end
        end

        --Set the status icon of the control
        if not foundError and newStatus ~= nil and ctrl.statusIcon ~= nil then
            local statusIcon = ctrl.statusIcon
            --Only if the status icon is not showing a special status texture already!
            if not statusIcon:HasIcon() then
                local statusIconTextureVar = "/esoui/art/buttons/cancel_up.dds"
                if newStatus == true then
                    statusIcon:ClearIcons()
                    statusIcon:SetColor(0, 0, 0, 1)
                    statusIcon:Hide()
                else
                    statusIcon:AddIcon(statusIconTextureVar)
                    statusIcon:SetColor(1, 0, 0, 1)
                    statusIcon:Show()
                end

            end
        end
    end
end

    --Set the skillline type's status (enabled/disabled) now and update icons etc.
local function FCOCS_SetSkillLineTypeStatus(ctrl, status)
    if ctrl == nil or status == nil then return false end
    local contextMenuEntryText = ""
    local newStatus = not status
    if status then
        contextMenuEntryText = "Mark skill line as \'non relevant\'"
    else
        contextMenuEntryText = "Mark skill line as \'relevant\' again"
    end
    --Add the context menu entry
    AddCustomMenuItem(contextMenuEntryText,
        function()
            changeSkillLineTypeEntry(ctrl, newStatus, true)
        end)
end

--Add the new context menu entry to the skill category subitem entries (e.g. Bow)
local function FCOCS_AddSkillTypeContextMenuEntry(ctrl)
    local settings = FCOChangeStuff.settingsVars.settings
    if not settings.enableSkillLineContextMenu then return false end
    if SKILLS_WINDOW.control:IsHidden() then return end
    if ctrl ~= nil then
--d("FCOCS_AddSkillTypeContextMenuEntry - Control name: " .. ctrl:GetName())
    --Is the skills window shown?
        --Call this function later as the original menu will be build in OnMouseUp function and we are in the PreHook of this function here!
        --So all menu entries will be overwritten again and we must add this entry later
        zo_callLater(function()
            ClearMenu(ctrl)
            --Add context menu entry now
            --AddMenuItem(localizationVars.fco_notes_loc["context_menu_add_personal_guild_note"],
            if ctrl.enabled ~= nil then
                FCOCS_SetSkillLineTypeStatus(ctrl, ctrl.enabled)
            end
            ShowMenu(ctrl)
        end, 50)
    end
end

--PreHook the skill lines on mouse click event
function FCOCS.preHookSkillLinesOnMouseDown()
    local settings = FCOChangeStuff.settingsVars.settings
    --Get each header entry of the skills window and prehook the mouse button click on it
    if SKILLS_WINDOW and SKILLS_WINDOW.skillLinesTree and SKILLS_WINDOW.skillLinesTree.rootNode and SKILLS_WINDOW.skillLinesTree.rootNode.children then
        local skillsWindowSkillTypesHeader = SKILLS_WINDOW.skillLinesTree.rootNode.children
        for skillTypesHeaderIndex, skillTypeHeaderData in ipairs(skillsWindowSkillTypesHeader) do
            --Get each entry below the skilltype
            if skillTypeHeaderData and skillTypeHeaderData.children then
                --Get each skilltype entry below the skilltype header
                for skillTypeIndex, skillTypeData in ipairs(skillTypeHeaderData.children) do
                    if skillTypeData and skillTypeData.control then
                        local skillTypeEntryCtrl = skillTypeData.control
--d(">skillTypeEntryCtrl: " ..tostring(skillTypeEntryCtrl:GetName()))
                        --PreHook the OnMouseUp event now
                        ZO_PreHookHandler(skillTypeEntryCtrl, "OnMouseUp", function(ctrl, button, upInside)
                            if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
                                FCOCS_AddSkillTypeContextMenuEntry(ctrl)
                            end
                        end)
                        --Change the visible controls now
                        changeSkillLineTypeEntry(skillTypeEntryCtrl, nil, false)
                    end
                end
            end
        end
    end
end

ZO_PreHook("ZO_Skills_OnEffectivelyShown", function(ctrl)
    local settings = FCOChangeStuff.settingsVars.settings
    if not settings.enableSkillLineContextMenu then return false end
--d("[ZO_Skills_OnEffectivelyShown]ctrl: " .. tostring(ctrl:GetName()))
    zo_callLater(function() FCOCS.preHookSkillLinesOnMouseDown() end, 150)
end)
