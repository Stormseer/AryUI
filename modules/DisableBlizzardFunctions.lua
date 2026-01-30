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