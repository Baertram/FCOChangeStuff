if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS
FCOChangeStuff.mailContextMenuButtons = {}

local EM = EVENT_MANAGER

local addonName, addonVars, addonPrefix

local tos = tostring
local strlow = string.lower
local strup = string.upper
local strsub = string.sub
local tins = table.insert
local tsort = table.sort

local addButton = FCOChangeStuff.AddButton
local throttledUpdate = FCOChangeStuff.ThrottledUpdate

local allowedMailContextMenuOwners = {}
local mailFavoritesContextMenusAtEditFieldsHooked = false

local uniqueSaveMailValuesUpdaterName = "FCOCS_saveMailUpdater"
local uniqueLoadMailValuesUpdaterName = "FCOCS_loadMailUpdater"

local mailSendEditFields = {
    ["recipients"] =    ZO_MailSendToField,
    ["subjects"] =      ZO_MailSendSubjectField,
    ["texts"] =         ZO_MailSendBodyField,
}

local favoriteIcon = "EsoUI/Art/Inventory/inventory_tabIcon_quickslot_up.dds"

local favoriteText = "|cFFD700" .. zo_iconTextFormatNoSpace(favoriteIcon, 24, 24, "|rFavorites", true)
local addAsFavoriteStr = "+|c00FF00Add|r |cFFFFFF%q|r |c00FF00as|r |cFFD700" .. zo_iconTextFormatNoSpace(favoriteIcon, 24, 24, "", true) .. "|rfavorite"
local deleteFavoriteStr = "-|cFF0000Delete|r |cFFFFFF%q|r |cFF0000from|r |cFFD700" .. zo_iconTextFormatNoSpace(favoriteIcon, 24, 24, "", true) .. "|rfavorite"

local maxLastSavedEntries = 10 --save this number of last send recipients/subjects/texts

------------------------------------------------------------------------------------------------------------------------
-- Mail --
------------------------------------------------------------------------------------------------------------------------

local mailContextMenutButtonsAdded = false

local function mailTextShortener(entryData)
    local stringLength = string.len(entryData)
    if stringLength > 50 then
        return strsub(entryData, 1, 50) .. "..."
    else
        local lineBreakPos = string.find(entryData, '\n', 1, false)
        if lineBreakPos ~= nil and lineBreakPos > 1 then
            if stringLength > 10 then
                return strsub(entryData, 1, lineBreakPos - 1) .. " <line break>..."
            end
        end
    end
    return entryData
end

local function checkIfTabNeedsToBeTruncated(tabToCheck, maxEntries)
    if tabToCheck == nil or maxEntries == nil then return end
    local numEntries = #tabToCheck
    if numEntries > maxEntries then
        for idx=maxEntries+1, numEntries, 1 do
            tabToCheck[idx] = nil
        end
    end
end

local function validateTextField(fieldType, textToValidate)
    if type(textToValidate) ~= "string" then return false end
    if textToValidate == "" then return true end

    --Validate recipient
    if fieldType == "recipients" then
        --Do not allow a single @
        if textToValidate == "@" then return false end
    end
    return true
end

local function isAnyFavoriteSettingEnabled()
    local settingsFavorites = FCOChangeStuff.settingsVars.settings.mailFavorites
    for fieldType, isEnabled in pairs(settingsFavorites) do
        if isEnabled == true then return true end
    end
    return false
end


local function updateHiddenStateOfContextMenuButtons(doHide)
    for k,v in pairs(FCOChangeStuff.mailContextMenuButtons) do
        if v ~= nil then v:SetHidden(doHide) end
    end
end

local function getCurrentText(fieldType)
    local editField = mailSendEditFields[fieldType]
    if editField == nil then return end
    return editField:GetText()
end

local function checkIfNotAlreadyIn(fieldType, isFavorite, entryName)
--d("[FCOCS]checkIfNotAlreadyIn-fieldType: " ..tos(fieldType) ..", isFavorite: " ..tos(isFavorite) .. ", entryName: " ..tos(entryName))
    local currentText
    if type(entryName) == "string" and entryName ~= "" then
        currentText = entryName
    else
--d(">>getting currentText new!")
        currentText = getCurrentText(fieldType)
    end
--d(">currentText: " ..tos(currentText))
    local tabToAdd
    if type(currentText) == "string" and currentText ~= "" then
        local settings = FCOChangeStuff.settingsVars.settings
        tabToAdd = (isFavorite == true and settings.mailFavoritesSaved[fieldType]) or settings.mailTextsSaved[fieldType]
        if tabToAdd ~= nil then
            if ZO_IsElementInNonContiguousTable(tabToAdd, currentText) == true then
--d("<<1 false is in already")
                return false, nil, tabToAdd
            else
--d("<<2 true is not in yet")
                return true, currentText, tabToAdd
            end
        end
    end
--d("<<3 false unknown")
    return false, nil, nil
end

local function removeSavedValue(fieldType, isFavorite, entryName)
    isFavorite = isFavorite or false
--d("[FCOCS]removeSavedValue-fieldType: " ..tos(fieldType) .. ", isFavorite: " ..tos(isFavorite))
    local isNotIn, _, tabToRemove = checkIfNotAlreadyIn(fieldType, isFavorite, entryName)
--d(">isNotIn: " ..tos(isNotIn) .. ", tabToRemove: " ..tos(tabToRemove))
    if isNotIn == true or tabToRemove == nil then return end
    local posInTab = ZO_IndexOfElementInNumericallyIndexedTable(tabToRemove, entryName)
--d(">posInTab: " ..tos(posInTab))
    if posInTab ~= nil then
        table.remove(tabToRemove, posInTab)
    end
end

local function setMailValue(fieldType, entryData, doOverride)
--d("[FCOCS]setMailValue: " .. tos(fieldType) .. ", doOverride: " ..tos(doOverride))
    if type(entryData) ~= "string" or entryData == "" then return end

    local editField = mailSendEditFields[fieldType]
    if editField == nil then return end
    if doOverride == nil then
        doOverride = (FCOChangeStuff.settingsVars.settings.overwriteMailFields[fieldType] == true and true) or false
    end
    if doOverride == true or editField:GetText() == "" then
--d(">doOverride: " ..tos(doOverride) ..", setText: " ..tos(entryData))
        editField:SetText(entryData)
    end
end

local function loadLastUsedValue(fieldType)
--d("[FCOCS]loadLastUsedValue-fieldType: " ..tos(fieldType))
    local lastUsedSettings = FCOChangeStuff.settingsVars.settings.mailLastUsed[fieldType]
    if type(lastUsedSettings) ~= "string" or lastUsedSettings == "" then return end
    setMailValue(fieldType, lastUsedSettings, true)
end

local function saveAsFavorit(fieldType, favoriteValue)
--d("[FCOCS]saveAsFavorit-fieldType: " ..tos(fieldType) .. ", favoriteText: " ..tos(favoriteValue))
    local isNotIn, currentText, tabToAdd = checkIfNotAlreadyIn(fieldType, true, favoriteValue)
    if isNotIn == true then
--d(">saving new favorite - " ..tos(fieldType) ..": " ..tos(currentText))
        --if validateMailText(fieldType, currentText) == true then
            tins(tabToAdd, currentText)
            tsort(tabToAdd)
            return true
        --end
    end
    return false
end

local function saveAsLastUsed(fieldType, lastUsedValue)
--d("[FCOCS]saveAsLastUsed-fieldType: " ..tos(fieldType) .. ", lastUsedText: " ..tos(lastUsedValue))
    local currentText = lastUsedValue or getCurrentText(fieldType)
--d(">saving last used - " ..tos(fieldType) ..": " ..tos(currentText))
    local isString = (type(currentText) == "string" and true) or false
    local isNotEmptyString = (isString == true and currentText ~= "" and true) or false
    --Save only "last used" if either non-empty string or empty string at the "text" field
    if isNotEmptyString == true or (isString == true and fieldType == "texts" and currentText == "") then
        FCOChangeStuff.settingsVars.settings.mailLastUsed[fieldType] = currentText
    end
end


local function saveMailValue(fieldType, isFavorite, isLastUsed)
    isFavorite = isFavorite or false
    isLastUsed = isLastUsed or false
--d("[FCOCS]saveMailValue-fieldType: " ..tos(fieldType) .. ", isFavorite: " ..tos(isFavorite) .. ", isLastUsed: " ..tos(isLastUsed))
    if isLastUsed == true then
        saveAsLastUsed(fieldType, nil)
    else
        saveAsFavorit(fieldType, nil)
    end
end

local function saveLastUsedValue(fieldType)
--d("[FCOCS]saveLastUsedValue-fieldType: " ..tos(fieldType))
    saveAsLastUsed(fieldType)
end

local function addToFavorites(fieldType, favoriteValue)
--d("[FCOCS]addToFavorites-fieldType: " ..tos(fieldType) .. ", favoriteText: " ..tos(favoriteValue))
    return saveAsFavorit(fieldType, favoriteValue)
end

local function afterMailWasSend(doSaveLast, doLoadLast)
--d("[FCOCS]afterMailWasSend-doSaveLast: " ..tos(doSaveLast) .. ", doLoadLast: " ..tos(doLoadLast))
    if not doSaveLast and not doLoadLast then return end

    local settings = FCOChangeStuff.settingsVars.settings
    local autoLoadMailFields = settings.autoLoadMailFields
    local autoLoadMailWasSendSettings = settings.autoLoadMailFieldsAt.mailWasSend
    for fieldType, isEnabled in pairs(autoLoadMailFields) do
--d(">fieldType: " ..tos(fieldType) .. ", enabled: " ..tos(isEnabled))
        if isEnabled == true then
            if doSaveLast == true then
                --Save currently used data
                saveLastUsedValue(fieldType)

            elseif doLoadLast == true then
                if autoLoadMailWasSendSettings[fieldType] == true then
                    loadLastUsedValue(fieldType)
                end
            end
        end
    end
end

local function checkAndSaveMailValuesOfEnabledFields(wasSuccess, sendMailResult)
--d("[FCOCS]checkAndSaveMailValuesOfEnabledFields-success: " ..tos(wasSuccess))
    wasSuccess = wasSuccess or false
    local settings = FCOChangeStuff.settingsVars.settings

    --Save the curently send email to, subject, text to load it directly to next
    --email message?
    if wasSuccess == true then
        afterMailWasSend(true, false)
    end

    local saveMailFields = settings.saveMailFields
    for fieldType, isEnabled in pairs(saveMailFields) do
        if isEnabled == true then
            if sendMailResult ~= nil and fieldType == "recipient" and sendMailResult == MAIL_SEND_RESULT_FAIL_INVALID_NAME then
--d("<invalid recipient for mail: Do not save!")
            else
                saveMailValue(fieldType)
            end
        end
    end
end

local function checkAndLoadMailValuesOfEnabledFields()
--d("[FCOCS]checkAndLoadMailValuesOfEnabledFields")
    local settings = FCOChangeStuff.settingsVars.settings
    local autoLoadMailFields = settings.autoLoadMailFields
    local openMailFields = settings.autoLoadMailFieldsAt.mailOpen
    for fieldType, isEnabled in pairs(openMailFields) do
        if isEnabled == true and autoLoadMailFields[fieldType] == true then
            loadLastUsedValue(fieldType)
        end
    end
end

local function checkMaxFavoritesAndCreateSubMenus(fieldType, noAdd)
    noAdd = noAdd or false

    local settings = FCOChangeStuff.settingsVars.settings
    local favEntries = settings.mailFavoritesSaved[fieldType]
    local splitMailFavoritesIntoAlphabet = settings.splitMailFavoritesIntoAlphabet
    local numFavorites = #favEntries

    AddCustomMenuItem(favoriteText, function() end, MENU_ADD_OPTION_HEADER)

    --Existing favorites
    if numFavorites > 0 then
        if splitMailFavoritesIntoAlphabet == true then
            --Too many entries in favorites, build submenus A-E, F-J, K-O, P-T, U-Z
            local aToE = {}
            local fToJ = {}
            local kToO = {}
            local pToT = {}
            local uToZ = {}
            local others = {}

            for _, favEntryData in ipairs(favEntries) do
                local firstChar = strlow(strsub(favEntryData, 1, 1))
                --Skip the @displayName character
                if firstChar == "@" then
                    firstChar = strlow(strsub(favEntryData, 2, 2))
                end

                local tabToAdd
                if (firstChar >= 'a' and firstChar <= 'e') or firstChar == 'ä' then
                    tabToAdd = aToE
                elseif firstChar >= 'f' and firstChar <= 'j' then
                    tabToAdd = fToJ
                elseif (firstChar >= 'k' and firstChar <= 'o')  or firstChar == 'ö' then
                    tabToAdd = kToO
                elseif firstChar >= 'p' and firstChar <= 't' then
                    tabToAdd = pToT
                elseif (firstChar >= 'u' and firstChar <= 'z')  or firstChar == 'ü' then
                    tabToAdd = uToZ
                else
                    tabToAdd = others
                end
                if tabToAdd == nil then tabToAdd = others end

                local shortText = mailTextShortener(favEntryData)
                local favEntryDataInSubmenu = {
                    label    = shortText,
                    callback = function()
                        setMailValue(fieldType, favEntryData)
                    end
                }
                tabToAdd[#tabToAdd + 1] = favEntryDataInSubmenu
            end

            if #aToE > 0 then
                AddCustomSubMenuItem("A - E", aToE)
            end
            if #fToJ > 0 then
                AddCustomSubMenuItem("F - J", fToJ)
            end
            if #kToO > 0 then
                AddCustomSubMenuItem("K - O", kToO)
            end
            if #pToT > 0 then
                AddCustomSubMenuItem("P - T", pToT)
            end
            if #uToZ > 0 then
                AddCustomSubMenuItem("U - Z", uToZ)
            end
            if #others > 0 then
                AddCustomSubMenuItem("Other", others)
            end

        else
            for _, favEntryData in ipairs(favEntries) do
                local shortText = mailTextShortener(favEntryData)
                local favEntryDataSubmenu = {
                    {
                        label    = "Select \'" .. shortText .. "\'",
                        callback = function()
                            setMailValue(fieldType, favEntryData)
                        end,
                    },
                    {
                        --label    = "|cff0000- Delete|r \'" .. shortText .. "\'",
                        label = string.format(deleteFavoriteStr, shortText),
                        callback = function()
                            removeSavedValue(fieldType, true, favEntryData)
                        end,
                    },
                }
                --AddCustomMenuItem(favEntryData, function() setMailValue(fieldType, favEntryData) end)
                AddCustomSubMenuItem(favEntryData, favEntryDataSubmenu)
            end
        end
    end

    --Add new favorite
    if not noAdd then
        local isNotIn, currentText, _ = checkIfNotAlreadyIn(fieldType, true, nil)
        if isNotIn == true then
            local shortText = mailTextShortener(currentText)
            currentText = string.format(addAsFavoriteStr, shortText)
            AddCustomMenuItem(currentText, function() addToFavorites(fieldType, nil) end, MENU_ADD_OPTION_LABEL)
        end
    end
end

local function checkIfEditBoxContextMenusNeedAnUpdate()
--d("[FCOCS]checkIfEditBoxContextMenusNeedAnUpdate")
    local settings = FCOChangeStuff.settingsVars.settings

    if settings.mailFavoritesContextMenusAtEditFields == true then
        if mailFavoritesContextMenusAtEditFieldsHooked == true then return end
--d(">>HOOKING....")
        for fieldType, editFieldCtrl in pairs(mailSendEditFields) do
--d(">fieldType: " ..tos(fieldType))
            if editFieldCtrl ~= nil then
                local function onMouseUpAtMailEditBox(editCtrl, button, upInside)
                    if not FCOChangeStuff.settingsVars.settings.mailFavoritesContextMenusAtEditFields then return end
                    if upInside and button == MOUSE_BUTTON_INDEX_RIGHT then
                        local currentText = editCtrl:GetText()
                        local isEmpty = (type(currentText) == "string" and currentText == "" and true) or false
--d(">currentText " ..tos(currentText))
                        ClearMenu()

                        --Favorites
                        if settings.mailFavorites[fieldType] == true then
                            --AddCustomMenuItem(favoriteText, function() end, MENU_ADD_OPTION_HEADER)

                            checkMaxFavoritesAndCreateSubMenus(fieldType, true)

                            AddCustomMenuItem("-", function()  end, MENU_ADD_OPTION_LABEL)

                            if validateTextField(fieldType, currentText) == true then
                                --Add new favorite or remove existing
                                local addOrDeleteAdded = false
                                local isNotIn, _, shortText
                                if isEmpty == true then
                                    isNotIn = true
                                else
                                    isNotIn, _, _ = checkIfNotAlreadyIn(fieldType, true, currentText)
                                    shortText = mailTextShortener(currentText)
                                end
                                if isEmpty == false and isNotIn == true then
                                    --Add new favorite
                                    currentText = string.format(addAsFavoriteStr, shortText)
                                    AddCustomMenuItem(currentText, function() addToFavorites(fieldType, nil) end, MENU_ADD_OPTION_LABEL)
                                    addOrDeleteAdded = true
                                else
                                    if isEmpty == false then
                                        --Remove existing favorite
                                        local deleteText = string.format(deleteFavoriteStr, shortText)
                                        AddCustomMenuItem(deleteText, function() removeSavedValue(fieldType, true, currentText) end, MENU_ADD_OPTION_LABEL)
                                        addOrDeleteAdded = true
                                    end
                                end
                                if addOrDeleteAdded == true then
                                    AddCustomMenuItem("-", function()  end, MENU_ADD_OPTION_LABEL)
                                end
                            end
                        end

                        --Generic entries
                        if isEmpty == false then
                            AddCustomMenuItem("Clear edit field", function() editFieldCtrl:SetText("") end, MENU_ADD_OPTION_LABEL)
                        end

                        ShowMenu(editCtrl)
                    end
                end


                local currentHandler = editFieldCtrl:GetHandler("OnMouseUp")
                if currentHandler == nil then
--d(">Setting handler at: " .. tos(editFieldCtrl:GetName()))
                    editFieldCtrl:SetHandler("OnMouseUp", onMouseUpAtMailEditBox)
                else
--d(">PostHooking existing handler at: " .. tos(editFieldCtrl:GetName()))
                    ZO_PostHookHandler(editFieldCtrl, "OnMouseUp", onMouseUpAtMailEditBox)
                end
                mailFavoritesContextMenusAtEditFieldsHooked = true
            --else
--d("<editFieldControl is NIL!")
            end
        end
    end
end

--[[
h5. SendMailResult
* MAIL_SEND_RESULT_CANCELED
* MAIL_SEND_RESULT_CANT_SEND_CASH_COD
* MAIL_SEND_RESULT_CANT_SEND_TO_SELF
* MAIL_SEND_RESULT_FAIL_BLANK_MAIL
* MAIL_SEND_RESULT_FAIL_DB_ERROR
* MAIL_SEND_RESULT_FAIL_IGNORED
* MAIL_SEND_RESULT_FAIL_INVALID_NAME
* MAIL_SEND_RESULT_FAIL_IN_PROGRESS
* MAIL_SEND_RESULT_FAIL_MAILBOX_FULL
* MAIL_SEND_RESULT_INVALID_ITEM
* MAIL_SEND_RESULT_MAILBOX_NOT_OPEN
* MAIL_SEND_RESULT_MAIL_DISABLED
* MAIL_SEND_RESULT_NOT_ENOUGH_ITEMS_FOR_COD
* MAIL_SEND_RESULT_NOT_ENOUGH_MONEY
* MAIL_SEND_RESULT_RECIPIENT_NOT_FOUND
* MAIL_SEND_RESULT_SUCCESS
* MAIL_SEND_RESULT_TOO_MANY_ATTACHMENTS
]]
local function onEventMailSendFailed(eventId, sendMailResult)
--d("[FCOCS]Mail send failed-result: " ..tos(sendMailResult))
    throttledUpdate = throttledUpdate or FCOChangeStuff.ThrottledUpdate
    throttledUpdate(uniqueSaveMailValuesUpdaterName, 50, checkAndSaveMailValuesOfEnabledFields, false, sendMailResult)
end

local function onEventMailSendSuccess(eventId, playerName)
--d("[FCOCS]Mail successfully send to: " ..tos(playerName))
    throttledUpdate = throttledUpdate or FCOChangeStuff.ThrottledUpdate
    throttledUpdate(uniqueSaveMailValuesUpdaterName, 50, checkAndSaveMailValuesOfEnabledFields, true)
end

local function onEventMailCloseMailbox(eventId)
--d("[FCOCS]Mail close")
    --This callback seems to fire twice each time?
    throttledUpdate = throttledUpdate or FCOChangeStuff.ThrottledUpdate
    throttledUpdate(uniqueSaveMailValuesUpdaterName, 50, checkAndSaveMailValuesOfEnabledFields, false)
end

local function onEventMailOpenMailbox(eventId)
--d("[FCOCS]Mail open")
    checkIfEditBoxContextMenusNeedAnUpdate()

    throttledUpdate = throttledUpdate or FCOChangeStuff.ThrottledUpdate
    throttledUpdate(uniqueSaveMailValuesUpdaterName, 50, checkAndLoadMailValuesOfEnabledFields)
end


local function eventCallBackFuncHandler(eventId, ...)
--d("[FCOCS]eventId: " ..tos(eventId))
    --if eventId == EVENT_MAIL_SEND_SUCCESS then
    --        return onEventMailSendSuccess(eventId, ...)
    if eventId == EVENT_MAIL_SEND_FAILED then
        return onEventMailSendFailed(eventId, ...)
    elseif eventId == EVENT_MAIL_CLOSE_MAILBOX then
        return onEventMailCloseMailbox(eventId, ...)
    elseif eventId == EVENT_MAIL_OPEN_MAILBOX then
        return onEventMailOpenMailbox(eventId, ...)
    end
    return
end

local function setMailEventHandlers(eventType, doEnable)
    doEnable = doEnable or false
    if eventType == EVENT_MAIL_SEND_SUCCESS or eventType == EVENT_MAIL_SEND_FAILED or eventType == EVENT_MAIL_CLOSE_MAILBOX then
        EM:UnregisterForEvent(addonName .. "-MAIL_SEND-" .. tos(eventType), eventType)
        if doEnable == true then
            local saveMailFields = FCOChangeStuff.settingsVars.settings.saveMailFields
            for k, v in pairs(saveMailFields) do
                if v == true then
--d(">registering mail_send/close event " ..tos(eventType))
                    EM:RegisterForEvent(addonName .. "-MAIL_SEND-" .. tos(eventType), eventType, function(eventId, ...) eventCallBackFuncHandler(eventId, ...) end)
                    return true
                end
            end
        else
            return true
        end
    elseif eventType == EVENT_MAIL_OPEN_MAILBOX then
        EM:UnregisterForEvent(addonName .. "-MAIL_OPEN-" .. tos(eventType), eventType)
        if doEnable == true then
            local autoLoadOnOpenMailFields = FCOChangeStuff.settingsVars.settings.autoLoadMailFieldsAt.mailOpen
            for k, v in pairs(autoLoadOnOpenMailFields) do
                if v == true then
--d(">registering onOpen event " ..tos(eventType))
                    EM:RegisterForEvent(addonName .. "-MAIL_OPEN-" .. tos(eventType), eventType, function(eventId, ...) eventCallBackFuncHandler(eventId, ...) end)
                    return true
                end
            end
        else
            return true
        end
    end
    return false
end

local function checkAndEnabledEventHandlersIfNeeded(doEnable)
    doEnable = doEnable or false
--d("[FCOCS]checkAndEnabledEventHandlersIfNeeded-doEnable:" ..tos(doEnable))
    --setMailEventHandlers(EVENT_MAIL_SEND_SUCCESS,   doEnable)
    setMailEventHandlers(EVENT_MAIL_SEND_FAILED,    doEnable)
    setMailEventHandlers(EVENT_MAIL_CLOSE_MAILBOX,  doEnable)

    setMailEventHandlers(EVENT_MAIL_OPEN_MAILBOX,   doEnable)
    --[[
    --ONly fires once!
    SCENE_MANAGER:CallWhen("mailSend", SCENE_SHOWN, function()
        onEventMailOpenMailbox(EVENT_MAIL_OPEN_MAILBOX)
    end)
    ]]
end


--MailBuddy support
local function loadMailBuddyData(fieldType, asFavorite)
    --d("[FCOCS]loadMailBuddyData - type: " ..tos(fieldType) .. ", favorite: " ..tos(asFavorite))
    asFavorite = asFavorite or false
    if not MailBuddy or not MailBuddy_SavedVars then return end
    if fieldType == nil or fieldType == "" then return end

    local mbSettings = MailBuddy.settingsVars.settings
    if mbSettings == nil then return end

    if fieldType == "recipients" then
        local mbRecipients = mbSettings.SetRecipient
        if mbRecipients == nil or #mbRecipients <= 0 then return end
        for _, recipient in ipairs(mbRecipients) do
            if type(recipient) == "string" and recipient ~= "" then
                if addToFavorites(fieldType, recipient) == true then
                    d(addonPrefix .. "\'MailBuddy\' recipient added: " ..tos(recipient))
                end
            end
        end

    elseif fieldType == "subjects" then
        --Add the fixed subjects PTS, RETURN and BOUNCE
        local mbFixedSubjects = {
            "RTS",
            "RETURN",
            "BOUNCE"
        }
        for _, subject in ipairs(mbFixedSubjects) do
            if type(subject) == "string" and subject ~= "" then
                if addToFavorites(fieldType, subject) == true then
                    d(addonPrefix .. "\'MailBuddy\' fixed subject added: " ..tos(subject))
                end
            end
        end
        --Now add the user added subjects
        local mbSubjects = mbSettings.SetSubject
        if mbSubjects == nil or #mbSubjects <= 0 then return end
        for _, subject in ipairs(mbSubjects) do
            if type(subject) == "string" and subject ~= "" then
                if addToFavorites(fieldType, subject) == true then
                    d(addonPrefix .. "\'MailBuddy\' subject added: " ..tos(subject))
                end
            end
        end

    elseif fieldType == "texts" then
        return --not supported
    end
end


local function getMailSettingsContextMenu()
    local contextMenuCallbackFunc = function()
        local settings = FCOChangeStuff.settingsVars.settings
        ClearMenu()
        AddCustomMenuItem("Settings", function() end, MENU_ADD_OPTION_HEADER)

        local overrideSubmenu = {
            {
                label    = "Overwrite \'to\' field, if not empty",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.overwriteMailFields["recipients"] = state
                end,
                checked  = function() return settings.overwriteMailFields["recipients"] end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },
            {
                label    = "Overwrite \'subject\' field, if not empty",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.overwriteMailFields["subjects"] = state
                end,
                checked  = function() return settings.overwriteMailFields["subjects"] end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },
            {
                label    = "Overwrite \'text\' field, if not empty",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.overwriteMailFields["texts"] = state
                end,
                checked  = function() return settings.overwriteMailFields["texts"] end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },
        }
        AddCustomSubMenuItem("Override fields", overrideSubmenu)

        local saveSubmenu = {
            {
                label    = "Save last \'to\' field, as mail sends/fails/closes",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.saveMailFields["recipients"] = state
                    checkAndEnabledEventHandlersIfNeeded(true)
                end,
                checked  = function() return settings.saveMailFields["recipients"] end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },
            {
                label    = "Save last \'subject\' field, as mail sends/fails/closes",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.saveMailFields["subjects"] = state
                    checkAndEnabledEventHandlersIfNeeded(true)
                end,
                checked  = function() return settings.saveMailFields["subjects"] end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },
            {
                label    = "Save last \'text\' field, as mail sends/fails/closes",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.saveMailFields["texts"] = state
                    checkAndEnabledEventHandlersIfNeeded(true)
                end,
                checked  = function() return settings.saveMailFields["texts"] end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },
        }
        AddCustomSubMenuItem("Save settings", saveSubmenu)

        local autoLoadSubmenu = {
            {
                label    = "Enabled: Auto load last \'to\' field",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.autoLoadMailFields["recipients"] = state
                end,
                checked  = function() return settings.autoLoadMailFields["recipients"] end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },
            {
                label    = "Enabled: Auto load last \'subject\' field",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.autoLoadMailFields["subjects"] = state
                end,
                checked  = function() return settings.autoLoadMailFields["subjects"] end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },
            {
                label    = "Enabled: Auto load last \'text\' field",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.autoLoadMailFields["texts"] = state
                end,
                checked  = function() return settings.autoLoadMailFields["texts"] end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },
        }
        AddCustomSubMenuItem("Auto load settings", autoLoadSubmenu)

        local autoLoadAtSubmenu = {
            {
                label    = "Auto load last \'to\', as mail opens",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.autoLoadMailFieldsAt.mailOpen["recipients"] = state
                end,
                checked  = function() return settings.autoLoadMailFieldsAt.mailOpen["recipients"] end,
                disabled = function() return not FCOChangeStuff.settingsVars.settings.autoLoadMailFields["recipients"] end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },
            {
                label    = "Auto load last \'to\', after mail was send (next mail)",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.autoLoadMailFieldsAt.mailWasSend["recipients"] = state
                end,
                checked  = function() return settings.autoLoadMailFieldsAt.mailWasSend["recipients"] end,
                disabled = function() return not FCOChangeStuff.settingsVars.settings.autoLoadMailFields["recipients"] end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },
            {
                label    = "Auto load last \'subject\', as mail opens",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.autoLoadMailFieldsAt.mailOpen["subjects"] = state
                end,
                checked  = function() return settings.autoLoadMailFieldsAt.mailOpen["subjects"] end,
                disabled = function() return not FCOChangeStuff.settingsVars.settings.autoLoadMailFields["subjects"] end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },
            {
                label    = "Auto load last \'subject\', after mail was send (next mail)",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.autoLoadMailFieldsAt.mailWasSend["subjects"] = state
                end,
                checked  = function() return settings.autoLoadMailFieldsAt.mailWasSend["subjects"] end,
                disabled = function() return not FCOChangeStuff.settingsVars.settings.autoLoadMailFields["subjects"] end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },
            {
                label    = "Auto load last \'text\', as mail opens",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.autoLoadMailFieldsAt.mailOpen["texts"] = state
                end,
                checked  = function() return settings.autoLoadMailFieldsAt.mailOpen["texts"] end,
                disabled = function() return not FCOChangeStuff.settingsVars.settings.autoLoadMailFields["texts"] end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },
            {
                label    = "Auto load last \'text\', after mail was send (next mail)",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.autoLoadMailFieldsAt.mailWasSend["texts"] = state
                end,
                checked  = function() return settings.autoLoadMailFieldsAt.mailWasSend["texts"] end,
                disabled = function() return not FCOChangeStuff.settingsVars.settings.autoLoadMailFields["texts"] end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },
        }
        AddCustomSubMenuItem("Auto load as...", autoLoadAtSubmenu)

        local favoritesSubmenu = {
            {
                label    = "Enabled: Favorites \'to\' field",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.mailFavorites["recipients"] = state
                end,
                checked  = function() return settings.mailFavorites["recipients"] end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },
            {
                label    = "Enabled: Favorites \'subject\' field",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.mailFavorites["subjects"] = state
                end,
                checked  = function() return settings.mailFavorites["subjects"] end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },
            {
                label    = "Enabled: Favorites \'text\' field",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.mailFavorites["texts"] = state
                end,
                checked  = function() return settings.mailFavorites["texts"] end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },
            {
                label    = "Split favorites by alphabet (create submenus)",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.splitMailFavoritesIntoAlphabet = state
                end,
                checked  = function() return settings.splitMailFavoritesIntoAlphabet end,
                disabled = function() return not isAnyFavoriteSettingEnabled() end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },

            {
                label    = "Show favorites context menu at editbox (recipient/subject/text)",
                callback = function(state)
                    FCOChangeStuff.settingsVars.settings.mailFavoritesContextMenusAtEditFields = state
                    checkIfEditBoxContextMenusNeedAnUpdate()
                end,
                checked  = function() return settings.mailFavoritesContextMenusAtEditFields end,
                disabled = function() return not isAnyFavoriteSettingEnabled() end,
                itemType = MENU_ADD_OPTION_CHECKBOX,
            },


        }
        AddCustomSubMenuItem("Favorites settings", favoritesSubmenu)


        --Import MailBuddy SavedVariables?
        if MailBuddy ~= nil and MailBuddy_SavedVars ~= nil then
            local mailBuddySubmenu = {
                {
                    label    = "Import 'MailBuddy' recipients as favorites",
                    callback = function(state)
                        loadMailBuddyData("recipients", true)
                    end,
                },
                {
                    label    = "Import 'MailBuddy' subjects as favorites",
                    callback = function(state)
                        loadMailBuddyData("subjects", true)
                    end,
                },
                --[[
                --Not supported
                {
                    label    = "Import 'MailBuddy' texts as favorites",
                    callback = function(state)
                        loadMailBuddyData("texts", true)
                    end,
                },
                ]]
            }
            AddCustomSubMenuItem("\'MailBuddy\' data import", mailBuddySubmenu)
        end


        ShowMenu(FCOChangeStuff.mailContextMenuButtons["settings"])
    end
    return contextMenuCallbackFunc()
end

local function updateMailContextMenuButtonContextMenus(fieldType)
    local contextMenuWasBuild = false
    local settings = FCOChangeStuff.settingsVars.settings
    local contextMenuCallbackFunc

    if FCOChangeStuff.mailContextMenuButtons[fieldType] ~= nil then
        contextMenuCallbackFunc = function()
            ClearMenu()

            --The last used entry
            local lastUsedEntry = settings.mailLastUsed[fieldType]
            if type(lastUsedEntry) == "string" and lastUsedEntry ~= ""  then
                AddCustomMenuItem("Last used", function() end, MENU_ADD_OPTION_HEADER)
                AddCustomMenuItem(lastUsedEntry, function() setMailValue(fieldType, lastUsedEntry) end, MENU_ADD_OPTION_LABEL)
            end

            --Favorites
            if settings.mailFavorites[fieldType] == true then
                checkMaxFavoritesAndCreateSubMenus(fieldType)
            end

            --Last 10 used
            local entries = settings.mailTextsSaved[fieldType]
            if #entries > 0 then
                AddCustomMenuItem("Last " ..tos(maxLastSavedEntries), function() end, MENU_ADD_OPTION_HEADER)
                local lastUsedEntryDataSubmenu = {}
                for idx, entryData in ipairs(entries) do
                    local shortText = mailTextShortener(entryData)
                    tins(lastUsedEntryDataSubmenu,
                        {
                            label    = tos(idx) ..". \'" .. shortText .. "\'",
                            callback = function()
                                setMailValue(fieldType, entryData)
                            end,
                        }
                    )
                    --AddCustomMenuItem(shortText, function() setMailValue(fieldType, entryData) end)
                end
                AddCustomSubMenuItem(strup(fieldType), lastUsedEntryDataSubmenu)
            end
            ShowMenu(FCOChangeStuff.mailContextMenuButtons[fieldType])
        end
        contextMenuWasBuild = true
    end

    if contextMenuWasBuild == true then
        return contextMenuCallbackFunc()
    end
end
FCOChangeStuff.updateMailContextMenuButtonContextMenus = updateMailContextMenuButtonContextMenus


local function addMailContextmenuButtons()
    addButton = addButton or FCOChangeStuff.AddButton

    --Add 1 button with mail settings
    local buttonDataMailSetings =
    {
        buttonName      = "FCOCS_MailSettingsContextMenu",
        parentControl   = ZO_MailSend,
        tooltip         = addonVars.addonNameMenuDisplay .." Mail settings",
        callback        = function()
            return getMailSettingsContextMenu()
        end,
        width           = 32,
        height          = 32,
        normal          = "/esoui/art/chatwindow/chat_options_up.dds",
        pressed         = "/esoui/art/chatwindow/chat_options_down.dds",
        highlight       = "/esoui/art/chatwindow/chat_options_over.dds",
        disabled        = "/esoui/art/chatwindow/chat_options_disabled.dds",
    }
    local button = addButton(TOPLEFT, ZO_MailSend, TOPLEFT, -35, -10, buttonDataMailSetings)
    button.type = "settings"
    FCOChangeStuff.mailContextMenuButtons["settings"] = button


    --Add 3 buttons at the mail subject, recipient and text (topleft of them) headlines for the context menus
    local buttonDataMailRecipients =
    {
        buttonName      = "FCOCS_MailRecipientsContextMenu",
        parentControl   = ZO_MailSendToLabel,
        tooltip         = "Mail recipients",
        callback        = function()
            return updateMailContextMenuButtonContextMenus("recipients")
        end,
        width           = 20,
        height          = 20,
        normal          = "/esoui/art/buttons/dropbox_arrow_normal.dds",
        pressed         = "/esoui/art/buttons/dropbox_arrow_mousedown.dds",
        highlight       = "/esoui/art/buttons/dropbox_arrow_mouseover.dds",
        disabled        = "/esoui/art/buttons/dropbox_arrow_disabled.dds",
    }
    button = addButton(RIGHT, ZO_MailSendToLabel, LEFT, -10, 0, buttonDataMailRecipients)
    button.type = "recipients"
    FCOChangeStuff.mailContextMenuButtons["recipients"] = button
    allowedMailContextMenuOwners[button] = true

    local buttonDataMailSubjects =
    {
        buttonName      = "FCOCS_MailSubjectsContextMenu",
        parentControl   = ZO_MailSendSubjectLabel,
        tooltip         = "Mail subjects",
        callback        = function()
            updateMailContextMenuButtonContextMenus("subjects")
        end,
        width           = 20,
        height          = 20,
        normal          = "/esoui/art/buttons/dropbox_arrow_normal.dds",
        pressed         = "/esoui/art/buttons/dropbox_arrow_mousedown.dds",
        highlight       = "/esoui/art/buttons/dropbox_arrow_mouseover.dds",
        disabled        = "/esoui/art/buttons/dropbox_arrow_disabled.dds",
    }
    button = addButton(RIGHT, ZO_MailSendSubjectLabel, LEFT, -10, 0, buttonDataMailSubjects)
    button.type = "subjects"
    FCOChangeStuff.mailContextMenuButtons["subjects"] = button
    allowedMailContextMenuOwners[button] = true

    local buttonDataMailTexts =
    {
        buttonName      = "FCOCS_MailTextsContextMenu",
        parentControl   = ZO_MailSendBody,
        tooltip         = "Mail texts",
        callback        = function()
            updateMailContextMenuButtonContextMenus("texts")
        end,
        width           = 20,
        height          = 20,
        normal          = "/esoui/art/buttons/dropbox_arrow_normal.dds",
        pressed         = "/esoui/art/buttons/dropbox_arrow_mousedown.dds",
        highlight       = "/esoui/art/buttons/dropbox_arrow_mouseover.dds",
        disabled        = "/esoui/art/buttons/dropbox_arrow_disabled.dds",
    }
    button = addButton(TOPRIGHT, ZO_MailSendBody, TOPLEFT, -10, 0, buttonDataMailTexts)
    button.type = "texts"
    FCOChangeStuff.mailContextMenuButtons["texts"] = button
    allowedMailContextMenuOwners[button] = true

    mailContextMenutButtonsAdded = true

    --add LibCustomMenu context menu to the mail subject, recipient and text buttons
    updateMailContextMenuButtonContextMenus()
end


local function OnZOMenuHide_RemoveFCOCSSubmenuOnMouseUpHandler()
--d("[FCOCS]OnZOMenuHide_RemoveFCOCSSubmenuOnMouseUpHandler")
    SetMenuHiddenCallback(nil)

    local owner = ZO_Menu.owner
    local items = ZO_Menu.items
    if owner == nil or not allowedMailContextMenuOwners[owner] or items == nil or #items <= 0 then return end
    for idx, menuLine in ipairs(items) do
        local item = menuLine.item
        if item:IsHandlerSet("OnMouseUp", "FCOCS_ContextMenu_SubmenuLines_OnMouseUpHandler") == true then
--d(">removing OnMouseUp handler from submenuEntry at line: " ..tos(idx))
            item:SetHandler("OnMouseUp", nil, "FCOCS_ContextMenu_SubmenuLines_OnMouseUpHandler")
        end
    end
end

local arrowStr = " |u16:0::|u"
local function cleanSubMenuLabelText(labelTextWithArrow)
    return string.gsub(labelTextWithArrow, arrowStr, "")
end


--======== Mail send panel ============================================================
function FCOChangeStuff.mailStuff()
    addonVars = FCOChangeStuff.addonVars
    addonName = addonVars.addonName
    addonPrefix = "[" .. addonName .. "]"

    local settings = FCOChangeStuff.settingsVars.settings

    if settings.mailContextMenus == true then
        if not mailContextMenutButtonsAdded then
            addMailContextmenuButtons()
        end
        updateHiddenStateOfContextMenuButtons(false)
        checkAndEnabledEventHandlersIfNeeded(true)
    else
        --Hide the buttons
        if mailContextMenutButtonsAdded == true then
            updateHiddenStateOfContextMenuButtons(true)
        end
        checkAndEnabledEventHandlersIfNeeded(false)
    end

    --Mail was successfully send - Before fields get cleared: Saved last used
    --and add data to "last 10"
    ZO_PreHook(MAIL_SEND, "OnMailSendSuccess", function()
--d("[FCOCS]PreHook: MAIL_SEND:OnMailSendSuccess")
        checkAndSaveMailValuesOfEnabledFields(true)
        return false --clear the fields via ZOs vanilla code
    end)

    --Mail was successfully send - After fields got cleared: Load last used
    SecurePostHook(MAIL_SEND, "OnMailSendSuccess", function()
--d("[FCOCS]PostHook: MAIL_SEND:OnMailSendSuccess")
        afterMailWasSend(false, true)
    end)



    --Enable the left click on ZO_MenuItemN if there is a submenu of the "Favorites"
    -->Select the current favorite
    SecurePostHook("ShowMenu", function(owner, initialRefCount, menuType)
        if not mailContextMenutButtonsAdded or not FCOChangeStuff.settingsVars.settings.mailContextMenus then return false end
        --Only needed for debugging
        --FCOCS._menuOwner = owner
        --FCOCS._menuItems = ZO_ShallowTableCopy(ZO_Menu.items)
        local items = ZO_Menu.items

        local wasOnMouseUpHandlerSet = false

        if owner == nil or not allowedMailContextMenuOwners[owner] or items == nil or #items <= 0 then return end
        local ownerType = owner.type
        local ownerRelatingMailEditBox = mailSendEditFields[ownerType]
        if not ownerRelatingMailEditBox or not ownerRelatingMailEditBox.SetText then return end

--d(">Allowed mail context menu opened")
        for idx, menuLine in ipairs(items) do
            local item = menuLine.item
            if item.enabled == true and item.nameLabel ~= nil then
--d(">line " .. tos(idx) .. " is enabled!")
                local checkBox = item.checkbox
                --checkbox = "maybe" submenu "arrow" showing to the right
                if checkBox ~= nil and checkBox:IsHidden() == false then
                    local menuItemName = item:GetName() -- ZO_CustomSubMenuItem1
                    if menuItemName ~= "" and string.find(menuItemName, "ZO_CustomSubMenuItem", 1, true) ~= nil then
--d(">found submenuEntry at line: " ..tos(idx))
                        item:SetHandler("OnMouseUp", function(itemCtrl, button, upInside, shift, ctrl, alt, cmd)
                            if upInside and button == MOUSE_BUTTON_INDEX_LEFT then
                                local currentLabelText = item.nameLabel:GetText()
                                local cleanLabelText = cleanSubMenuLabelText(currentLabelText)
--d(">>clicked label: " ..tos(currentLabelText) .. ", clean: " ..tos(cleanLabelText))
                                ZO_Menu_SetLastCommandWasFromMenu(true)
                                setMailValue(ownerType, cleanLabelText, nil)
                                ClearMenu()
                            end
                        end, "FCOCS_ContextMenu_SubmenuLines_OnMouseUpHandler")
                        wasOnMouseUpHandlerSet = true
                    end
                end
            end
        end

        if wasOnMouseUpHandlerSet == true then
            --Should be executed via ZO_Menu_OnHide(control)
            SetMenuHiddenCallback(OnZOMenuHide_RemoveFCOCSSubmenuOnMouseUpHandler)
        end
    end)

    --Context menus at the edit fields of recipient/subject/text
    checkIfEditBoxContextMenusNeedAnUpdate()
end
