-- AryUI/modules/VaultReport.lua
-- VaultReport module — intercepts right-clicks safely with an overlay so Blizzard's
-- right-click handler for the ExpansionLandingPageMinimapButton does not run,
-- while preserving left-click behavior.

local module = {}

------------------------------------------------------------
-- MODULE REGISTRATION
------------------------------------------------------------
local function RegisterModule()
    AryUI = AryUI or {}
    AryUI.modules = AryUI.modules or {}
    for _, m in ipairs(AryUI.modules) do
        if m == module then return end
    end
    tinsert(AryUI.modules, module)
    AryUI.VaultReportModule = module
end

if AryUI and AryUI.modules then
    RegisterModule()
else
    local regFrame = CreateFrame("Frame")
    regFrame:RegisterEvent("ADDON_LOADED")
    regFrame:SetScript("OnEvent", function(self, event, addon)
        if addon == "AryUI" then
            RegisterModule()
            self:UnregisterEvent("ADDON_LOADED")
            self:SetScript("OnEvent", nil)
        end
    end)
end

------------------------------------------------------------
-- DEFAULTS
------------------------------------------------------------
local defaults = {
    vaultReport = {
        enabled = true,
    }
}

function module:RegisterDefaults()
    AryUIDB = AryUIDB or {}
    AryUIDB.vaultReport = AryUIDB.vaultReport or {}
    for k, v in pairs(defaults.vaultReport) do
        if AryUIDB.vaultReport[k] == nil then
            AryUIDB.vaultReport[k] = v
        end
    end
end

------------------------------------------------------------
-- SPECIAL FRAME MANAGEMENT
------------------------------------------------------------
local function EnsureUISpecialFrame(name)
    if not name then return end
    for _, v in ipairs(UISpecialFrames) do
        if v == name then return end
    end
    tinsert(UISpecialFrames, name)
end

local function RemoveUISpecialFrame(name)
    if not name then return end
    for i = #UISpecialFrames, 1, -1 do
        if UISpecialFrames[i] == name then
            tremove(UISpecialFrames, i)
        end
    end
end

local function SanitizeUISpecialFrames()
    for i = #UISpecialFrames, 1, -1 do
        local name = UISpecialFrames[i]
        local frame = _G[name]
        if not frame or not frame:IsShown() then
            tremove(UISpecialFrames, i)
        end
    end
end

-- Delayed sanitization to handle race conditions where Blizzard re-inserts frames
local function DelayedSanitize()
    SanitizeUISpecialFrames()
    if C_Timer and C_Timer.After then
        C_Timer.After(0.05, SanitizeUISpecialFrames)
        C_Timer.After(0.25, SanitizeUISpecialFrames)
    end
end

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------
local function HideExpansionSummaryIfShown()
    if ExpansionLandingPage and ExpansionLandingPage:IsShown() then
        pcall(function() ExpansionLandingPage:Hide() end)
    end
    if ToggleExpansionLandingPage and ExpansionLandingPage and ExpansionLandingPage:IsShown() then
        pcall(ToggleExpansionLandingPage)
    end
end

local function CloseAll()
    if GarrisonLandingPage and GarrisonLandingPage:IsShown() then
        if GarrisonLandingPage_Toggle then pcall(GarrisonLandingPage_Toggle) end
    end

    if WeeklyRewardsFrame and WeeklyRewardsFrame:IsShown() then
        pcall(HideUIPanel, WeeklyRewardsFrame)
        if WeeklyRewardsFrame.GetName then
            RemoveUISpecialFrame(WeeklyRewardsFrame:GetName())
        end
    end

    if ExpansionLandingPage and ExpansionLandingPage:IsShown() then
        if ToggleExpansionLandingPage then
            pcall(ToggleExpansionLandingPage)
        else
            pcall(function() ExpansionLandingPage:Hide() end)
        end
    end

    DelayedSanitize()
end

-- Hook WeeklyRewardsFrame OnHide to ensure its name is removed from UISpecialFrames
local function EnsureWRFOnHideHook()
    if not WeeklyRewardsFrame or not WeeklyRewardsFrame.IsObjectType or not WeeklyRewardsFrame:IsObjectType("Frame") then
        return
    end
    if WeeklyRewardsFrame.__AryUI_OnHideHooked then return end
    WeeklyRewardsFrame.__AryUI_OnHideHooked = true

    WeeklyRewardsFrame:HookScript("OnHide", function()
        if WeeklyRewardsFrame.GetName then
            local nm = WeeklyRewardsFrame:GetName()
            if nm then RemoveUISpecialFrame(nm) end
        end
        DelayedSanitize()
    end)
end

local function OpenVault()
    pcall(function()
        if C_AddOns and C_AddOns.LoadAddOn then
            C_AddOns.LoadAddOn("Blizzard_WeeklyRewards")
        elseif LoadAddOn then
            LoadAddOn("Blizzard_WeeklyRewards")
        end
    end)

    if not WeeklyRewardsFrame then
        return
    end

    EnsureWRFOnHideHook()

    if not WeeklyRewardsFrame:IsShown() then
        pcall(function()
            WeeklyRewardsFrame:Show()
            if WeeklyRewardsFrame.GetName then
                EnsureUISpecialFrame(WeeklyRewardsFrame:GetName())
            end
        end)
    end
end

------------------------------------------------------------
-- CLICK HANDLER
------------------------------------------------------------
local function onButtonClick(self, button)
    if not (AryUIDB and AryUIDB.vaultReport and AryUIDB.vaultReport.enabled) then
        return
    end

    local WRF = WeeklyRewardsFrame

    if button == "LeftButton" then
        if WRF and WRF:IsShown() then
            pcall(HideUIPanel, WRF)
            if WRF.GetName then
                RemoveUISpecialFrame(WRF:GetName())
            end
            HideExpansionSummaryIfShown()
            DelayedSanitize()
        end

    elseif button == "RightButton" then
        if WRF and WRF:IsShown() then
            pcall(HideUIPanel, WRF)
            if WRF.GetName then
                RemoveUISpecialFrame(WRF:GetName())
            end
            HideExpansionSummaryIfShown()
            DelayedSanitize()
        else
            CloseAll()
            OpenVault()
        end
    end
end

------------------------------------------------------------
-- ATTACHMENT (safe right-click interception via overlay)
------------------------------------------------------------
local function AttachToExpansionButton()
    local btn = ExpansionLandingPageMinimapButton
    if not (btn and btn.IsObjectType and btn:IsObjectType("Button")) then
        return false
    end

    -- If overlay already exists and is a Button, reuse it
    if btn.__AryUI_RightOverlay and btn.__AryUI_RightOverlay:IsObjectType("Button") then
        return true
    end

    -- Capture Blizzard's original OnClick handler (may be nil)
    local originalOnClick = btn:GetScript("OnClick")

    -- Create a real BUTTON overlay so we can RegisterForClicks
    local overlay = CreateFrame("Button", nil, btn)
    overlay:SetAllPoints(btn)
    overlay:EnableMouse(true)
    -- Register both so we can forward left and handle right
    overlay:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    overlay:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            -- Our custom right-click behavior (open/close weekly rewards)
            onButtonClick(btn, "RightButton")

            -- don't forward the right-click to Blizzard (so expansion summary won't toggle)
            return
        end

        if button == "LeftButton" then
            -- Forward the left-click to Blizzard's original handler if it exists.
            -- Use pcall to avoid breaking if original handler errors.
            if originalOnClick then
                pcall(originalOnClick, btn, "LeftButton")
                return
            end

            -- If no original handler, try to simulate a click (best-effort)
            if btn.Click then
                pcall(function() btn:Click("LeftButton") end)
            end
        end
    end)

    -- Ensure the overlay sits above the original button
    overlay:SetFrameStrata(btn:GetFrameStrata() or "MEDIUM")
    overlay:SetFrameLevel((btn:GetFrameLevel() or 1) + 10)

    -- Store overlay for later cleanup
    btn.__AryUI_RightOverlay = overlay
    module._attachedTo = btn
    return true
end

local fallback
local function CreateFallbackButton()
    if fallback and fallback:IsShown() then return fallback end

    fallback = CreateFrame("Button", "AryUIVaultReportFallbackButton", UIParent, "UIPanelButtonTemplate")
    fallback:SetSize(80, 24)
    fallback:SetPoint("TOPRIGHT", -20, -120)
    fallback:SetText("Vault")
    fallback:SetScript("OnClick", function(self, button)
        onButtonClick(self, button or "LeftButton")
    end)
    fallback:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("VaultReport")
        GameTooltip:AddLine("Left click: close vault", 1,1,1,true)
        GameTooltip:AddLine("Right click: open vault", 1,1,1,true)
        GameTooltip:Show()
    end)
    fallback:SetScript("OnLeave", function() GameTooltip:Hide() end)

    module._attachedTo = fallback
    return fallback
end

function module:Attach()
    -- Try attaching to the real button first, if present
    if AttachToExpansionButton() then return end

    -- Otherwise create a fallback button if enabled
    if AryUIDB and AryUIDB.vaultReport and AryUIDB.vaultReport.enabled then
        CreateFallbackButton()
    end
end

------------------------------------------------------------
-- MODULE LIFECYCLE
------------------------------------------------------------
function module:OnLoad()
    self:RegisterDefaults()
    if AryUIDB and AryUIDB.vaultReport and AryUIDB.vaultReport.enabled then
        self:Attach()
    end
end

function module:Toggle(enabled)
    AryUIDB = AryUIDB or {}
    AryUIDB.vaultReport = AryUIDB.vaultReport or {}
    AryUIDB.vaultReport.enabled = enabled
    if enabled then
        self:Attach()
        if fallback then fallback:Show() end
    else
        if fallback then fallback:Hide() end
        -- if a Blizzard button had an overlay we leave it removed; reattach when toggled on again
        if module._attachedTo and module._attachedTo.__AryUI_RightOverlay then
            module._attachedTo.__AryUI_RightOverlay:Hide()
        end
    end
end

function module:OpenVault()
    OpenVault()
end
