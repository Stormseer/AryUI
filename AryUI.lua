-- AryUI.lua — full final file with nested module subpanels in the options menu
-- Drop this into your AryUI addon folder (keep your modules/ files as-is).

-- Base addon table
AryUI = AryUI or {}
AryUI.modules = AryUI.modules or {}

-- Core defaults
local defaults = {
    tooltipOffsetX = -350,
    tooltipOffsetY = 165,
}

-- Utility: apply defaults to a table
local function ApplyDefaults(db, src)
    for k, v in pairs(src) do
        if db[k] == nil then
            db[k] = v
        end
    end
end

-- Forward declare panel creator
local panel
local function CreateOptionsPanel() end


-------------------------------------------------------------
-- SavedVariables + module init
-------------------------------------------------------------
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "AryUI" then return end

    if not AryUIDB then AryUIDB = {} end
    ApplyDefaults(AryUIDB, defaults)

    -- let modules register their defaults first (e.g. chatBackground)
    for _, module in ipairs(AryUI.modules) do
        if module.RegisterDefaults then
            module:RegisterDefaults()
        end
    end

    -- then call module OnLoad
    for _, module in ipairs(AryUI.modules) do
        if module.OnLoad then
            module:OnLoad()
        end
    end

    -- finally build the options panel now that DB/modules are ready
    CreateOptionsPanel()
end)


-------------------------------------------------------------
-- Slash Command
-------------------------------------------------------------
SLASH_ARYUI1 = "/aryui"
SlashCmdList["ARYUI"] = function()
    CreateOptionsPanel()
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory("AryUI")
    elseif InterfaceOptionsFrame_OpenToCategory then
        -- call twice to ensure selection (legacy behavior)
        InterfaceOptionsFrame_OpenToCategory(AryUIOptionsPanel or "AryUI")
        InterfaceOptionsFrame_OpenToCategory(AryUIOptionsPanel or "AryUI")
    end
end


-------------------------------------------------------------
-- UI Helpers
-------------------------------------------------------------
local function CreateHeader(parent, text, offsetY)
    local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 16, offsetY)
    header:SetText(text)
    return header
end

-- Generic slider + editbox helper.
-- Note: This helper by default floors values (integer behavior).
-- For floating sliders (alpha) we override its scripts after creation.
local function CreateSliderWithBox(name, parent, label, minVal, maxVal, initial, x, y, onChanged)
    -- Slider (OptionsSliderTemplate creates Low/High/Text globals)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(initial)

    -- Set low/high/text labels (these globals exist because of the template)
    if _G[name .. "Low"] then _G[name .. "Low"]:SetText(tostring(minVal)) end
    if _G[name .. "High"] then _G[name .. "High"]:SetText(tostring(maxVal)) end
    if _G[name .. "Text"] then _G[name .. "Text"]:SetText(label .. ": " .. initial) end

    -- Edit box
    local box = CreateFrame("EditBox", name .. "EditBox", parent, "InputBoxTemplate")
    box:SetAutoFocus(false)
    box:SetSize(60, 24)
    box:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    box:SetText(tostring(initial))

    -- Default integer slider behavior
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        box:SetText(value)
        if _G[name .. "Text"] then _G[name .. "Text"]:SetText(label .. ": " .. value) end
        if onChanged then onChanged(value) end
    end)

    box:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText()) or minVal
        val = math.max(minVal, math.min(maxVal, val))
        val = math.floor(val)
        slider:SetValue(val)
        self:ClearFocus()
    end)

    box:SetScript("OnEscapePressed", function(self)
        self:SetText(slider:GetValue())
        self:ClearFocus()
    end)

    return slider, box
end


-------------------------------------------------------------
-- CreateOptionsPanel() — builds main panel + subpanels per module
-------------------------------------------------------------
function CreateOptionsPanel()
    if panel then return end

    -- Main panel (used as "root" for legacy InterfaceOptions)
    local mainPanel = CreateFrame("Frame", "AryUIOptionsPanel", UIParent)
    mainPanel.name = "AryUI"

    local mainCategory -- for modern Settings API

    -- Register main category
    if Settings and Settings.RegisterCanvasLayoutCategory then
        mainCategory, mainPanel.layout = Settings.RegisterCanvasLayoutCategory(mainPanel, mainPanel.name, mainPanel.name)
        mainCategory.ID = mainPanel.name
        Settings.RegisterAddOnCategory(mainCategory)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(mainPanel)
    end

    -- Helper to create a subpanel and register it appropriately
    local function CreateModuleSubpanel(subName, buildFunc)
        local subPanelName = "AryUIOptionsPanel_" .. subName:gsub("%s+", "")
        local subpanel = CreateFrame("Frame", subPanelName, UIParent)
        subpanel.name = subName

        -- Legacy: set parent and register so it appears as a child entry
        if InterfaceOptions_AddCategory then
            subpanel.parent = mainPanel.name
            InterfaceOptions_AddCategory(subpanel)
        end

        -- Modern: register a canvas subcategory under mainCategory if available
        if Settings and Settings.RegisterCanvasLayoutSubcategory and mainCategory then
            local subcat = Settings.RegisterCanvasLayoutSubcategory(mainCategory, subpanel, subName)
            Settings.RegisterAddOnCategory(subcat)
        end

        -- Build its contents
        if buildFunc then
            buildFunc(subpanel)
        end

        return subpanel
    end

    -- Small title helper for subpanels
    local function MakeTitle(parent, titleText)
        local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText(titleText)
        return title
    end

    ---------------------------------------------------------
    -- Tooltip Anchor subpanel
    ---------------------------------------------------------
    CreateModuleSubpanel("Tooltip Anchor", function(p)
        MakeTitle(p, "Tooltip Anchor Settings")

        CreateSliderWithBox(
            "AryUISubTooltipX",
            p,
            "Tooltip Offset X",
            -1000, 1000,
            AryUIDB.tooltipOffsetX,
            16, -60,
            function(value) AryUIDB.tooltipOffsetX = value end
        )

        CreateSliderWithBox(
            "AryUISubTooltipY",
            p,
            "Tooltip Offset Y",
            -1000, 1000,
            AryUIDB.tooltipOffsetY,
            16, -130,
            function(value) AryUIDB.tooltipOffsetY = value end
        )
    end)

    ---------------------------------------------------------
    -- Chat Background subpanel
    ---------------------------------------------------------
    CreateModuleSubpanel("Chat Background", function(p)
        MakeTitle(p, "Chat Background Module")

        -- Enable checkbox
        local enableCB = CreateFrame("CheckButton", "AryUIChatBackgroundEnable_Sub", p, "ChatConfigCheckButtonTemplate")
        enableCB:SetPoint("TOPLEFT", 16, -52)
        enableCB.Text:SetText("Enable Chat Background")
        enableCB:SetChecked(AryUIDB.chatBackground and AryUIDB.chatBackground.enabled)
        enableCB:SetScript("OnClick", function(self)
            if not AryUIDB.chatBackground then AryUIDB.chatBackground = {} end
            AryUIDB.chatBackground.enabled = self:GetChecked()
            if AryUIDB.chatBackground.enabled then
                if AryUI.ChatBackgroundModule and AryUI.ChatBackgroundModule.CreateFrame then
                    AryUI.ChatBackgroundModule:CreateFrame()
                    if AryUI.ChatBackgroundModule.ApplySettings then AryUI.ChatBackgroundModule:ApplySettings() end
                end
            else
                if AryUIChatBackground then AryUIChatBackground:Hide() end
            end
        end)

        -- Lock Position checkbox (you chose offset 0,5)
        local lockCB = CreateFrame("CheckButton", "AryUIChatBackgroundLock_Sub", p, "ChatConfigCheckButtonTemplate")
        lockCB:SetPoint("TOPLEFT", enableCB, "BOTTOMLEFT", 0, 5)
        lockCB.Text:SetText("Lock Frame Position")
        lockCB:SetChecked(AryUIDB.chatBackground and AryUIDB.chatBackground.lockPosition)
        lockCB:SetScript("OnClick", function(self)
            if not AryUIDB.chatBackground then AryUIDB.chatBackground = {} end
            AryUIDB.chatBackground.lockPosition = self:GetChecked()
            if AryUI.ChatBackgroundModule and AryUI.ChatBackgroundModule.UpdateMovability then
                AryUI.ChatBackgroundModule:UpdateMovability()
            end
        end)

        -- Width
        CreateSliderWithBox(
            "AryUISubCBWidth",
            p,
            "Background Width",
            20, 1000,
            (AryUIDB.chatBackground and AryUIDB.chatBackground.width) or 300,
            16, -120,
            function(value)
                AryUIDB.chatBackground.width = value
                if AryUI.ChatBackgroundModule and AryUI.ChatBackgroundModule.ApplySettings then AryUI.ChatBackgroundModule:ApplySettings() end
            end
        )

        -- Height
        CreateSliderWithBox(
            "AryUISubCBHeight",
            p,
            "Background Height",
            20, 1000,
            (AryUIDB.chatBackground and AryUIDB.chatBackground.height) or 150,
            16, -190,
            function(value)
                AryUIDB.chatBackground.height = value
                if AryUI.ChatBackgroundModule and AryUI.ChatBackgroundModule.ApplySettings then AryUI.ChatBackgroundModule:ApplySettings() end
            end
        )

        -- Opacity (alpha) slider: create, then override for decimal precision
        local alphaSlider, alphaBox = CreateSliderWithBox(
            "AryUISubCBAlpha",
            p,
            "Background Opacity",
            0, 1,
            (AryUIDB.chatBackground and AryUIDB.chatBackground.alpha) or 0.60,
            16, -260,
            function() end
        )
        alphaSlider:SetValueStep(0.01)
        alphaSlider:SetObeyStepOnDrag(true)
        -- override OnValueChanged for float precision
        alphaSlider:SetScript("OnValueChanged", function(self, value)
            value = tonumber(string.format("%.2f", value)) or 0.00
            alphaBox:SetText(string.format("%.2f", value))
            if _G["AryUISubCBAlphaText"] then _G["AryUISubCBAlphaText"]:SetText("Background Opacity: " .. string.format("%.2f", value)) end
            AryUIDB.chatBackground.alpha = value
            if AryUI.ChatBackgroundModule and AryUI.ChatBackgroundModule.ApplySettings then AryUI.ChatBackgroundModule:ApplySettings() end
        end)
        alphaBox:SetScript("OnEnterPressed", function(self)
            local val = tonumber(self:GetText())
            if not val then
                self:SetText(string.format("%.2f", AryUIDB.chatBackground.alpha or 0.60))
                self:ClearFocus()
                return
            end
            val = math.max(0, math.min(1, val))
            val = tonumber(string.format("%.2f", val))
            alphaSlider:SetValue(val)
            self:ClearFocus()
        end)
        alphaBox:SetScript("OnEscapePressed", function(self)
            self:SetText(string.format("%.2f", alphaSlider:GetValue()))
            self:ClearFocus()
        end)

        -- Frame strata controls
        local strataLabel = p:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        strataLabel:SetPoint("TOPLEFT", 16, -320)
        strataLabel:SetText("Frame Strata")

        local strataDrop = CreateFrame("Frame", "AryUISubCBStrataDrop", p, "UIDropDownMenuTemplate")
        strataDrop:SetPoint("TOPLEFT", strataLabel, "BOTTOMLEFT", -16, -5)

        local strataOptions = {
            "BACKGROUND", "LOW", "MEDIUM", "HIGH",
            "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP"
        }

        UIDropDownMenu_SetWidth(strataDrop, 140)
        UIDropDownMenu_SetText(strataDrop, (AryUIDB.chatBackground and AryUIDB.chatBackground.strata) or "MEDIUM")

        UIDropDownMenu_Initialize(strataDrop, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            for _, strata in ipairs(strataOptions) do
                info.text = strata
                info.func = function()
                    AryUIDB.chatBackground.strata = strata
                    UIDropDownMenu_SetText(strataDrop, strata)
                    if AryUI.ChatBackgroundModule and AryUI.ChatBackgroundModule.ApplySettings then AryUI.ChatBackgroundModule:ApplySettings() end
                end
                info.checked = (AryUIDB.chatBackground and AryUIDB.chatBackground.strata == strata)
                UIDropDownMenu_AddButton(info)
            end
        end)
    end)

    ---------------------------------------------------------
    -- Vault Report subpanel
    ---------------------------------------------------------
    CreateModuleSubpanel("Vault Report", function(p)
        MakeTitle(p, "Vault Report Module")

        local enableVR = CreateFrame("CheckButton", "AryUIVaultReportEnable_Sub", p, "ChatConfigCheckButtonTemplate")
        enableVR:SetPoint("TOPLEFT", 16, -52)
        enableVR.Text:SetText("Enable VaultReport")
        enableVR:SetChecked(AryUIDB.vaultReport and AryUIDB.vaultReport.enabled)
        enableVR:SetScript("OnClick", function(self)
            if not AryUIDB.vaultReport then AryUIDB.vaultReport = {} end
            AryUIDB.vaultReport.enabled = self:GetChecked()
            if AryUI.VaultReportModule and AryUI.VaultReportModule.Toggle then
                AryUI.VaultReportModule:Toggle(self:GetChecked())
            end
        end)

        local testBtn = CreateFrame("Button", "AryUIVaultReportTest_Sub", p, "UIPanelButtonTemplate")
        testBtn:SetSize(100, 24)
        testBtn:SetPoint("TOPLEFT", enableVR, "BOTTOMLEFT", 0, -14)
        testBtn:SetText("Open Vault")
        testBtn:SetScript("OnClick", function()
            if AryUI.VaultReportModule and AryUI.VaultReportModule.OpenVault then
                AryUI.VaultReportModule:OpenVault()
            end
        end)
    end)

    -- expose the main panel globally so legacy code can reference it by name
    panel = mainPanel
end
