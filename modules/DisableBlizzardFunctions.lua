local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")

local function placeboRemoveQuests() 
    local numShownEntries, numQuests = C_QuestLog.GetNumQuestLogEntries()
    if numShownEntries <= numQuests then
        return
    end

    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local quest = C_QuestLog.GetInfo(i)

        if quest and quest.isHidden then
            C_QuestLog.RemoveQuestWatch(quest.questID)
        end
    end
end


f:SetScript("OnEvent", function()
    -- Disable aura warning alpha logic
    if BuffFrame and BuffFrame.AuraContainer then
        BuffFrame.AuraContainer.GetAuraWarningAlphaForDuration = nil
    end

    if DebuffFrame and DebuffFrame.AuraContainer then
        DebuffFrame.AuraContainer.GetAuraWarningAlphaForDuration = nil
    end

    -- Disable floating combat text elements
    SetCVar("floatingCombatTextCombatDamage", 0)
    SetCVar("floatingCombatTextCombatHealing", 0)
    SetCVar("floatingCombatTextCombatLogPeriodicSpells", 0)
    SetCVar("floatingCombatTextPetMeleeDamage", 0)
    SetCVar("floatingCombatTextPetSpellDamage", 0)

    hooksecurefunc("CompactUnitFrame_UpdateVisible", function(Frame)
    if Frame.Skinned or not Frame.centerStatusIcon then return end
    Frame.background:SetIgnoreParentAlpha(true)
    Frame.Skinned = true
    end)

    hooksecurefunc("CompactUnitFrame_UpdateCenterStatusIcon", function(Frame)
    if Frame.outOfRange ~= nil then Frame:SetAlphaFromBoolean(Frame.outOfRange, 0.35, 1) end
    end)

    C_Timer.After(3, placeboRemoveQuests)

    -- Cleanup: run once, then go dormant
    f:UnregisterAllEvents()
    f:SetScript("OnEvent", nil)
end)

--[[ Hides the cooldown text on all of the buff frames in the cooldown manager. 
local function HideCooldownText(cooldownFrame)
  if not cooldownFrame then return end
  
  -- Hide countdown numbers
  cooldownFrame:SetHideCountdownNumbers(true)
  cooldownFrame:SetDrawEdge(false)
  
  -- Hide any FontStrings in the cooldown
  for _, region in ipairs({ cooldownFrame:GetRegions() }) do
    if region:GetObjectType() == "FontString" then
      region:Hide()
      region:SetAlpha(0)
    end
  end
end

EventUtil.RegisterOnceFrameEventAndCallback("PLAYER_ENTERING_WORLD", function()
  
  -- Hook the SetCooldown function which is called when cooldowns are updated
  hooksecurefunc(getmetatable(CreateFrame("Cooldown")).__index, "SetCooldown", function(self)
    -- Check if this cooldown belongs to BuffIconCooldownViewer
    local parent = self:GetParent()
    if parent and parent:GetParent() == BuffIconCooldownViewer then
      HideCooldownText(self)
    end
  end)
  
  -- Also process existing ones
  for _, CdFrame in ipairs({ BuffIconCooldownViewer:GetChildren() }) do
    if CdFrame.Cooldown then
      HideCooldownText(CdFrame.Cooldown)
    end
  end
end)
--]]