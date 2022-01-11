if FCOCS == nil then FCOCS = {} end
local FCOChangeStuff = FCOCS

------------------------------------------------------------------------------------------------------------------------
-- Collectibles --
------------------------------------------------------------------------------------------------------------------------

local currentlyOnwedTexture = "/esoui/art/buttons/accept_up.dds"
local currentlyNotOnwedTexture = "/esoui/art/buttons/cancel_up.dds"

local wasCollectibleFragmentsTooltipHooked = false
local function hookCollectibleFragmentsTooltip()
--d("[FCOCS]hookCollectibleFragmentsTooltip-wasCollectibleFragmentsTooltipHooked: " ..tostring(wasCollectibleFragmentsTooltipHooked))
	if wasCollectibleFragmentsTooltipHooked then return end

	local function hookCoolectibleTooltip(tooltipControl, gameDataType, ...) --itemTooltipRef, collectibleId, SHOW_NICKNAME, SHOW_PURCHASABLE_HINT, SHOW_BLOCK_REASON
		--d("[FCOCS]ItemTooltip:OnAddGameData-gameDataType: " ..tostring(gameDataType))
		--local fragmentsScrollListParentCategory = ZO_CollectionsBook_TopLevelCategoriesScrollChildContainer4
		--[[
			function ZO_CollectibleData:CombinedFragmentUnlocked()
			if self:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_COMBINATION_FRAGMENT) then
				local unlockedCollectibleId = GetCombinationUnlockedCollectible(self.referenceId)
						-- or does GetCombinationUnlockedCollectible not return the id if not unlocked
				return ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(unlockedCollectibleId):IsUnlocked()
			end
			end
		]]

		--Add at latest
		if gameDataType ~= TOOLTIP_GAME_DATA_MYTHIC_OR_STOLEN then return end
		if not FCOChangeStuff.settingsVars.settings.collectibleTooltipShowFragmentCombinedItem then return end
		local row = moc()
		if not row or not row.dataEntry or not row.dataEntry.data then return end
		--d(">1")
		local collectibleIdOfFragment
		local referenceId
		local collectibleFragmentAtCollectionsFragmentUI = row.dataEntry.data
		if not collectibleFragmentAtCollectionsFragmentUI then return end
		if not collectibleFragmentAtCollectionsFragmentUI.dataSource then
			--Check if we are at the impressaria store
			if collectibleFragmentAtCollectionsFragmentUI.meetsRequirementsToBuy ~= nil and collectibleFragmentAtCollectionsFragmentUI.slotIndex ~= nil then
				local storeItemLink = GetStoreItemLink(collectibleFragmentAtCollectionsFragmentUI.slotIndex)
				--d(">Store item detected: " .. storeItemLink)
				collectibleIdOfFragment = GetCollectibleIdFromLink(storeItemLink)
				referenceId = GetCollectibleReferenceId(collectibleIdOfFragment)
			else
				return
			end
		else
			--local categoryData = collectibleFragmentAtCollectionsFragmentUI.categoryData
			local dataSource = collectibleFragmentAtCollectionsFragmentUI.dataSource
			collectibleIdOfFragment = dataSource.collectibleId
			referenceId = dataSource.referenceId
		end
		--d(">2")
		if not collectibleIdOfFragment then return end
		--d(">3-collectibleId: " ..tostring(collectibleIdOfFragment))
		--Fragments category was selected?
		if ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleIdOfFragment):IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_COMBINATION_FRAGMENT) then
			if not referenceId then return end
			--d(">4-referenceId: " ..tostring(referenceId))
			local unlockedCollectibleId = GetCombinationUnlockedCollectible(referenceId)
			if unlockedCollectibleId ~= nil and unlockedCollectibleId ~= 0 then
				local collectibleCategoryName = ZO_CachedStrFormat(SI_COLLECTIBLE_NAME_FORMATTER, GetCollectibleCategoryNameByCollectibleId(unlockedCollectibleId))
				--d(">5-unlockedCollectibleId: " ..tostring(unlockedCollectibleId))
				local name, _, icon, _, unlocked = GetCollectibleInfo(unlockedCollectibleId)
				--local collectibleNameClean = ZO_CachedStrFormat(SI_COLLECTIBLE_NAME_FORMATTER, GetCollectibleName(unlockedCollectibleId))
				--local collectibleTexture = GetCollectibleIcon(unlockedCollectibleId)
				local inheritColor = not unlocked
				local collectibleNameClean = ZO_CachedStrFormat(SI_COLLECTIBLE_NAME_FORMATTER, name)
				collectibleNameClean = ((unlocked == true and "|c00FF00") or "|cFF0000") .. collectibleNameClean .. "|r"
				local textureColorDummy = ((unlocked == true and "") or "|c000000|r")
				local textureColorDummyOwned = ((unlocked == true and "|c00FF00:     |r") or "|cFF0000:     |r")
				local collectibleNameWithTextureClean = zo_iconTextFormatNoSpace(icon, 48, 48, textureColorDummy, inheritColor) .. collectibleNameClean
				local collectibleUnlockedStateTexture = zo_iconTextFormatNoSpace((unlocked and currentlyOnwedTexture) or currentlyNotOnwedTexture, 24, 24, textureColorDummyOwned, true)
				local knownText = (unlocked and GetString(SI_COLLECTIBLEUNLOCKSTATE2)) or GetString(SI_COLLECTIBLE_ACTION_COMBINE)
				--d(">is unlocked: " ..tostring(unlocked))
				--d(">Found collectible for fragment: " ..tostring(collectibleNameClean))
				ItemTooltip:AddLine(knownText .. collectibleUnlockedStateTexture, "ZoFontWinH3", ZO_SELECTED_TEXT:UnpackRGB())
				ItemTooltip:AddLine("["..collectibleCategoryName.."] " .. collectibleNameWithTextureClean, "ZoFontGameMedium", ZO_HIGHLIGHT_TEXT:UnpackRGB())
			end
		end
	end

	--[[
	local SHOW_NICKNAME = true
	local SHOW_PURCHASABLE_HINT = true
	local SHOW_BLOCK_REASON = true
	ItemTooltip:SetCollectible(self.collectibleData:GetId(), SHOW_NICKNAME, SHOW_PURCHASABLE_HINT, SHOW_BLOCK_REASON, self:GetActorCategory())
	]]
	--SecurePostHook(ItemTooltip, "SetCollectible", hookCoolectibleTooltip) --throws table expected got userdata error....
	ZO_PreHookHandler(ItemTooltip, 'OnAddGameData', hookCoolectibleTooltip)

	wasCollectibleFragmentsTooltipHooked = true
end



function FCOChangeStuff.collectibleChanges()
	if FCOChangeStuff.settingsVars.settings.collectibleTooltipShowFragmentCombinedItem then
		hookCollectibleFragmentsTooltip()
	end
end