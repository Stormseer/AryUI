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

-----
local debugCooldownText = false

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

-- CooldownIDs to hide text for
local hideCooldownIDs = {
  [26467] = true,  -- Frostfire Empowerment
  [93744] = true,  -- Freezing
  [91122] = true,  -- Arcane Salvo
}

EventUtil.RegisterOnceFrameEventAndCallback("PLAYER_ENTERING_WORLD", function()
  if debugCooldownText then
    print("=== Hooking SetCooldown with cooldownID filter ===")
  end

  -- Hook the SetCooldown function
  hooksecurefunc(getmetatable(CreateFrame("Cooldown")).__index, "SetCooldown", function(self)
    local parent = self:GetParent()
    if parent and parent:GetParent() == BuffIconCooldownViewer then
      -- Check if this parent has a cooldownID we want to hide
      if parent.cooldownID and hideCooldownIDs[parent.cooldownID] then
        if debugCooldownText then
            print("Hiding cooldown text for cooldownID: " .. parent.cooldownID)
        end
        HideCooldownText(self)
      end
    end
  end)

  -- Also process existing ones
  C_Timer.After(1, function()
    local children = { BuffIconCooldownViewer:GetChildren() }
    for i, CdFrame in ipairs(children) do
      if CdFrame.Cooldown and CdFrame.cooldownID and hideCooldownIDs[CdFrame.cooldownID] then
        if debugCooldownText then
            print("Processing existing cooldownID: " .. CdFrame.cooldownID)
        end
        HideCooldownText(CdFrame.Cooldown)
      end
    end
  end)
end)

if debugCooldownText then
    EventUtil.RegisterOnceFrameEventAndCallback("PLAYER_ENTERING_WORLD", function()
    C_Timer.After(3, function()
        print("=== Finding cooldownIDs ===")
        local children = { BuffIconCooldownViewer:GetChildren() }

        for i, child in ipairs(children) do
        if child.cooldownID then
            print("Child " .. i .. " has cooldownID: " .. child.cooldownID)

            -- Try to get the spell name
            if child.GetNameText then
            local name = child:GetNameText()
            if name then
                print("  Name: " .. name)
            end
            end
        end
        end
    end)
    end)
end