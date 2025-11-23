-- Base addon table
AryUI = AryUI or {}
AryUI.modules = AryUI.modules or {}

-- Default SavedVariables (core defaults)
local defaults = {
    tooltipOffsetX = -350,
    tooltipOffsetY = 165,
}

-- Apply defaults helper
local function ApplyDefaults(db, src)
    for k, v in pairs(src) do
        if db[k] == nil then
            db[k] = v
        end
    end
end

local panel          -- options frame
local function CreateOptionsPanel() end -- forward declaration


-------------------------------------------------------------
-- SavedVariables + module init
-------------------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "AryUI" then
        -- Init DB
        if not AryUIDB then AryUIDB = {} end
        ApplyDefaults(AryUIDB, defaults)

        -- Let modules register their defaults first
        for _, module in ipairs(AryUI.modules) do
            if module.RegisterDefaults then
                module:RegisterDefaults()
            end
        end

        -- Then call OnLoad for modules
        for _, module in ipairs(AryUI.modules) do
            if module.OnLoad then
                module:OnLoad()
            end
        end

        -- Now build options panel (DB and modules ready)
        CreateOptionsPanel()
    end
end)


-------------------------------------------------------------
-- Slash Command: /aryui
-------------------------------------------------------------
SLASH_ARYUI1 = "/aryui"
SlashCmdList["ARYUI"] = function()
    CreateOptionsPanel()

    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory("AryUI")
    elseif InterfaceOptionsFrame_OpenToCategory then
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

-- Hybrid Slider + EditBox control
-- Note: This generic helper floors the slider values (suitable for integer sliders).
-- For float sliders (alpha) we override the scripts after creation.
local function CreateSliderWithBox(name, parent, label, minVal, maxVal, initial, x, y, onChanged)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(initial)

    _G[name .. "Low"]:SetText(tostring(minVal))
    _G[name .. "High"]:SetText(tostring(maxVal))
    _G[name .. "Text"]:SetText(label .. ": " .. initial)

    -- Edit box next to slider
    local box = CreateFrame("EditBox", name .. "EditBox", parent, "InputBoxTemplate")
    box:SetAutoFocus(false)
    box:SetSize(60, 24)
    box:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    box:SetText(tostring(initial))

    -- Slider changed → update box + callback (integer)
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        box:SetText(value)
        _G[name .. "Text"]:SetText(label .. ": " .. value)
        if onChanged then onChanged(value) end
    end)

    -- Box changed → update slider + callback
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
-- Options Panel (Settings API compatible)
-------------------------------------------------------------
function CreateOptionsPanel()
    -- Prevent rebuilding
    if panel then return end

    panel = CreateFrame("Frame", "AryUIOptionsPanel", UIParent)
    panel.name = "AryUI"

    -- Register with new Settings API (Retail) OR fallback to Classic
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category, layout = Settings.RegisterCanvasLayoutCategory(panel, panel.name, panel.name)
        category.ID = panel.name
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("AryUI Settings")


    ---------------------------------------------------------
    -- TOOLTIP MODULE SECTION
    ---------------------------------------------------------
    local headerTT = CreateHeader(panel, "Tooltip Anchor Module", -60)

    -- Tooltip X
    CreateSliderWithBox(
        "AryUITooltipX",
        panel,
        "Tooltip Offset X",
        -1000, 1000,
        AryUIDB.tooltipOffsetX,
        16, -100,
        function(value)
            AryUIDB.tooltipOffsetX = value
        end
    )

    -- Tooltip Y
    CreateSliderWithBox(
        "AryUITooltipY",
        panel,
        "Tooltip Offset Y",
        -1000, 1000,
        AryUIDB.tooltipOffsetY,
        16, -170,
        function(value)
            AryUIDB.tooltipOffsetY = value
        end
    )


    ---------------------------------------------------------
    -- CHAT BACKGROUND MODULE SECTION
    ---------------------------------------------------------
    local headerCB = CreateHeader(panel, "Chat Background Module", -240)

    -- Enable Toggle
    local enableCB = CreateFrame("CheckButton", "AryUIChatBackgroundEnable", panel, "ChatConfigCheckButtonTemplate")
    enableCB:SetPoint("TOPLEFT", headerCB, "BOTTOMLEFT", 0, -10)
    enableCB.Text:SetText("Enable Chat Background")
    enableCB:SetChecked(AryUIDB.chatBackground.enabled)

    enableCB:SetScript("OnClick", function(self)
        AryUIDB.chatBackground.enabled = self:GetChecked()
        if AryUIDB.chatBackground.enabled then
            AryUI.ChatBackgroundModule:CreateFrame()
            AryUI.ChatBackgroundModule:ApplySettings()
        else
            if AryUIChatBackground then AryUIChatBackground:Hide() end
        end
    end)

    -- Lock Position Checkbox (you set this offset)
    local lockCB = CreateFrame("CheckButton", "AryUIChatBackgroundLock", panel, "ChatConfigCheckButtonTemplate")
    lockCB:SetPoint("TOPLEFT", enableCB, "BOTTOMLEFT", 0, 5) -- your chosen offset (0, 5)
    lockCB.Text:SetText("Lock Frame Position")
    lockCB:SetChecked(AryUIDB.chatBackground.lockPosition)

    lockCB:SetScript("OnClick", function(self)
        AryUIDB.chatBackground.lockPosition = self:GetChecked()
        if AryUI.ChatBackgroundModule and AryUI.ChatBackgroundModule.UpdateMovability then
            AryUI.ChatBackgroundModule:UpdateMovability()
        end
    end)

    -- Width
    CreateSliderWithBox(
        "AryUICBWidth",
        panel,
        "Background Width",
        20, 1000,
        AryUIDB.chatBackground.width,
        16, -330,
        function(value)
            AryUIDB.chatBackground.width = value
            AryUI.ChatBackgroundModule:ApplySettings()
        end
    )

    -- Height
    CreateSliderWithBox(
        "AryUICBHeight",
        panel,
        "Background Height",
        20, 1000,
        AryUIDB.chatBackground.height,
        16, -400,
        function(value)
            AryUIDB.chatBackground.height = value
            AryUI.ChatBackgroundModule:ApplySettings()
        end
    )

    -- Background Alpha (Opacity) - float slider with two-decimal precision
    local alphaSlider, alphaBox = CreateSliderWithBox(
        "AryUICBAlpha",
        panel,
        "Background Opacity",
        0, 1,
        AryUIDB.chatBackground.alpha,
        16, -470,
        function(value)
            -- placeholder (real handling done below)
        end
    )

    -- Configure the alpha slider for floats
    alphaSlider:SetValueStep(0.01)
    alphaSlider:SetObeyStepOnDrag(true)

    -- Override the OnValueChanged to allow decimals
    alphaSlider:SetScript("OnValueChanged", function(self, value)
        value = tonumber(string.format("%.2f", value))
        if not value then value = 0.00 end
        alphaBox:SetText(string.format("%.2f", value))
        _G["AryUICBAlphaText"]:SetText("Background Opacity: " .. string.format("%.2f", value))
        AryUIDB.chatBackground.alpha = value
        if AryUI.ChatBackgroundModule and AryUI.ChatBackgroundModule.ApplySettings then
            AryUI.ChatBackgroundModule:ApplySettings()
        end
    end)

    -- Editbox for alpha accepts decimals
    alphaBox:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText())
        if not val then
            self:SetText(string.format("%.2f", AryUIDB.chatBackground.alpha))
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


    -- Strata label (you set this to -510)
    local strataLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    strataLabel:SetPoint("TOPLEFT", 16, -510) -- your chosen offset
    strataLabel:SetText("Frame Strata")

    -- Dropdown
    local strataDrop = CreateFrame("Frame", "AryUICBStrataDrop", panel, "UIDropDownMenuTemplate")
    strataDrop:SetPoint("TOPLEFT", strataLabel, "BOTTOMLEFT", -16, -5)

    local strataOptions = {
        "BACKGROUND", "LOW", "MEDIUM", "HIGH",
        "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP"
    }

    UIDropDownMenu_SetWidth(strataDrop, 140)
    UIDropDownMenu_SetText(strataDrop, AryUIDB.chatBackground.strata)

    UIDropDownMenu_Initialize(strataDrop, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, strata in ipairs(strataOptions) do
            info.text = strata
            info.func = function()
                AryUIDB.chatBackground.strata = strata
                UIDropDownMenu_SetText(strataDrop, strata)
                AryUI.ChatBackgroundModule:ApplySettings()
            end
            info.checked = (AryUIDB.chatBackground.strata == strata)
            UIDropDownMenu_AddButton(info)
        end
    end)


    ---------------------------------------------------------
    -- VAULT REPORT MODULE SECTION
    ---------------------------------------------------------
    local headerVR = CreateHeader(panel, "Vault Report Module", -580)

    -- Enable Toggle
    local enableVR = CreateFrame("CheckButton", "AryUIVaultReportEnable", panel, "ChatConfigCheckButtonTemplate")
    enableVR:SetPoint("TOPLEFT", headerVR, "BOTTOMLEFT", 0, -10)
    enableVR.Text:SetText("Enable VaultReport")
    enableVR:SetChecked(AryUIDB.vaultReport and AryUIDB.vaultReport.enabled)

    enableVR:SetScript("OnClick", function(self)
        local enabled = self:GetChecked()
        if not AryUIDB.vaultReport then AryUIDB.vaultReport = {} end
        AryUIDB.vaultReport.enabled = enabled
        if AryUI.VaultReportModule and AryUI.VaultReportModule.Toggle then
            AryUI.VaultReportModule:Toggle(enabled)
        end
    end)

    -- Test/Open Vault Button
    local testBtn = CreateFrame("Button", "AryUIVaultReportTest", panel, "UIPanelButtonTemplate")
    testBtn:SetSize(100, 24)
    testBtn:SetPoint("TOPLEFT", enableVR, "BOTTOMLEFT", 0, -14)
    testBtn:SetText("Open Vault")
    testBtn:SetScript("OnClick", function()
        if AryUI.VaultReportModule and AryUI.VaultReportModule.OpenVault then
            AryUI.VaultReportModule:OpenVault()
        end
    end)
end
