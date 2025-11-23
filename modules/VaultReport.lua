local module = {}
table.insert(AryUI.modules, module)

-- Defaults
local defaults = {
    vaultReport = {
        enabled = true,
    }
}

function module:RegisterDefaults()
    AryUIDB.vaultReport = AryUIDB.vaultReport or {}
    for k, v in pairs(defaults.vaultReport) do
        if AryUIDB.vaultReport[k] == nil then
            AryUIDB.vaultReport[k] = v
        end
    end
end

-- Utility: avoid inserting duplicate special frames
local function EnsureUISpecialFrame(name)
    if not name then return end
    for _, v in ipairs(UISpecialFrames) do
        if v == name then return end
    end
    tinsert(UISpecialFrames, name)
end

-- Close everything that might be in the way (preserves original behavior)
local function CloseAll()
    if GarrisonLandingPage and GarrisonLandingPage:IsShown() then
        if GarrisonLandingPage_Toggle then
            GarrisonLandingPage_Toggle()
        elseif GarrisonLandingPage.Hide then
            GarrisonLandingPage:Hide()
        end
    end

    if WeeklyRewardsFrame and WeeklyRewardsFrame:IsShown() then
        HideUIPanel(WeeklyRewardsFrame)
    end

    if ExpansionLandingPage and ExpansionLandingPage:IsShown() then
        if ToggleExpansionLandingPage then
            ToggleExpansionLandingPage()
        else
            ExpansionLandingPage:Hide()
        end
    end

    if GenericTraitFrame and GenericTraitFrame:IsShown() then
        -- do nothing extra — original code invoked DragonridingPanelSkillsButtonMixin:OnClick()
        -- we are preserving CloseAll but not triggering dragonriding UI on middle-click anymore
        -- keep this block available in case a different behavior is desired later
    end
end

local function OpenVault()
    if C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, "Blizzard_WeeklyRewards")
    else
        pcall(LoadAddOn, "Blizzard_WeeklyRewards")
    end

    if WeeklyRewardsFrame then
        WeeklyRewardsFrame:Show()
        EnsureUISpecialFrame(WeeklyRewardsFrame:GetName())
    end
end

-- Main click handler — left/right only (middle-click removed)
local function onButtonClick(self, button)
    if not AryUIDB or not AryUIDB.vaultReport or not AryUIDB.vaultReport.enabled then
        return
    end

    local WRF = WeeklyRewardsFrame

    if button == "LeftButton" then
        if WRF and WRF:IsShown() then HideUIPanel(WRF) end

    elseif button == "RightButton" then
        CloseAll()
        if WRF and WRF:IsShown() then
            CloseAll()
        else
            OpenVault()
        end
    end
end

-- Try to attach to the known expansion landing page minimap button
local function TryAttach()
    local btn = ExpansionLandingPageMinimapButton
    if btn and btn:IsObjectType("Button") then
        pcall(btn.RegisterForClicks, btn, "LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
        btn:HookScript("OnClick", onButtonClick)
        module._attachedTo = btn
        return true
    end

    return false
end

-- Fallback clickable button
local fallback
local function CreateFallbackButton()
    if fallback and fallback:IsShown() then return fallback end

    fallback = CreateFrame("Button", "AryUIVaultReportFallbackButton", UIParent, "UIPanelButtonTemplate")
    fallback:SetSize(80, 24)
    fallback:SetPoint("TOPRIGHT", -20, -120)
    fallback:SetText("Vault")
    fallback:SetScript("OnClick", function(self, button)
        local b = button or "LeftButton"
        onButtonClick(self, b)
    end)
    module._attachedTo = fallback
    return fallback
end

function module:Attach()
    if TryAttach() then
        return
    end
    -- create fallback only if enabled
    CreateFallbackButton()
end

function module:OnLoad()
    self:RegisterDefaults()
    if AryUIDB.vaultReport and AryUIDB.vaultReport.enabled then
        self:Attach()
    end
end

function module:Toggle(enabled)
    AryUIDB.vaultReport.enabled = enabled
    if enabled then
        self:Attach()
        if fallback then fallback:Show() end
    else
        if fallback then fallback:Hide() end
    end
end

function module:OpenVault()
    OpenVault()
end

AryUI.VaultReportModule = module
