local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")

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

    -- Cleanup: run once, then go dormant
    f:UnregisterAllEvents()
    f:SetScript("OnEvent", nil)
end)