--========================================--
-- AryUI - Main AddOn File (fixed)
--========================================--

AryUI = AryUI or {}
AryUI.modules = AryUI.modules or {}

------------------------------------------------------------
-- APPLY GLOBAL DEFAULTS
------------------------------------------------------------
local globalDefaults = {
    tooltipOffsetX = -350,
    tooltipOffsetY = 165,
}

local function ApplyDefaults(target, defaults)
    for k, v in pairs(defaults) do
        if target[k] == nil then
            target[k] = v
        end
    end
end

------------------------------------------------------------
-- SLASH COMMAND
------------------------------------------------------------
SLASH_ARYUI1 = "/aryui"
SlashCmdList["ARYUI"] = function()
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory("AryUI")
    else
        if AryUIOptionsPanel then
            InterfaceOptionsFrame_OpenToCategory(AryUIOptionsPanel)
            InterfaceOptionsFrame_OpenToCategory(AryUIOptionsPanel)
        end
    end
end

------------------------------------------------------------
-- OPTIONS PANEL HELPERS
------------------------------------------------------------
local panel = nil

local function CreateHeader(parent, text, offsetY)
    local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 16, offsetY)
    header:SetText(text)
    return header
end

-- Generic slider with attached edit box
local function CreateSliderWithBox(name, parent, label, minVal, maxVal, initial, x, y, onChanged)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValue(initial)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)

    if _G[name .. "Low"] then _G[name .. "Low"]:SetText(tostring(minVal)) end
    if _G[name .. "High"] then _G[name .. "High"]:SetText(tostring(maxVal)) end
    if _G[name .. "Text"] then _G[name .. "Text"]:SetText(label .. ": " .. initial) end

    local box = CreateFrame("EditBox", name .. "EditBox", parent, "InputBoxTemplate")
    box:SetAutoFocus(false)
    box:SetSize(60, 24)
    box:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    box:SetText(tostring(initial))

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        box:SetText(value)
        if _G[name .. "Text"] then _G[name .. "Text"]:SetText(label .. ": " .. value) end
        if onChanged then onChanged(value) end
    end)

    box:SetScript("OnEnterPressed", function(self)
        local v = tonumber(self:GetText()) or minVal
        v = math.max(minVal, math.min(maxVal, v))
        v = math.floor(v)
        slider:SetValue(v)
        self:ClearFocus()
    end)

    box:SetScript("OnEscapePressed", function(self)
        self:SetText(slider:GetValue())
        self:ClearFocus()
    end)

    return slider, box
end

------------------------------------------------------------
-- CreateOptionsPanel (main + subpanels)
------------------------------------------------------------
local function CreateOptionsPanel()
    if panel then return end

    panel = CreateFrame("Frame", "AryUIOptionsPanel", UIParent)
    panel.name = "AryUI"

    local mainCategory
    if Settings and Settings.RegisterCanvasLayoutCategory then
        mainCategory = Settings.RegisterCanvasLayoutCategory(panel, "AryUI", "AryUI")
        Settings.RegisterAddOnCategory(mainCategory)
    else
        InterfaceOptions_AddCategory(panel)
    end

    local function CreateSubpanel(title, builder)
        local sub = CreateFrame("Frame", "AryUI_Subpanel_" .. title:gsub("%s+", ""), UIParent)
        sub.name = title
        sub.parent = "AryUI"

        if builder then builder(sub) end

        if Settings and Settings.RegisterCanvasLayoutSubcategory and mainCategory then
            local subcat = Settings.RegisterCanvasLayoutSubcategory(mainCategory, sub, title)
            Settings.RegisterAddOnCategory(subcat)
        else
            InterfaceOptions_AddCategory(sub)
        end
    end

    -------------------------------------------------------
    -- Tooltip Anchor subpanel
    -------------------------------------------------------
    CreateSubpanel("Tooltip Anchor", function(p)
        CreateHeader(p, "Tooltip Anchor", -16)

        CreateSliderWithBox("AryUITooltipX", p, "Offset X", -1000, 1000, AryUIDB.tooltipOffsetX or globalDefaults.tooltipOffsetX, 16, -70,
            function(v) AryUIDB.tooltipOffsetX = v end
        )

        CreateSliderWithBox("AryUITooltipY", p, "Offset Y", -1000, 1000, AryUIDB.tooltipOffsetY or globalDefaults.tooltipOffsetY, 16, -140,
            function(v) AryUIDB.tooltipOffsetY = v end
        )
    end)

    -------------------------------------------------------
    -- Chat Background subpanel
    -------------------------------------------------------
    CreateSubpanel("Chat Background", function(p)
        CreateHeader(p, "Chat Background", -16)

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
        CreateSliderWithBox("AryUIChatBGWidth", p, "Width", 50, 2000, (AryUIDB.chatBackground and AryUIDB.chatBackground.width) or 300, 16, -120,
            function(v)
                AryUIDB.chatBackground.width = v
                if AryUI.ChatBackgroundModule and AryUI.ChatBackgroundModule.ApplySettings then AryUI.ChatBackgroundModule:ApplySettings() end
            end
        )

        -- Height
        CreateSliderWithBox("AryUIChatBGHeight", p, "Height", 50, 2000, (AryUIDB.chatBackground and AryUIDB.chatBackground.height) or 200, 16, -190,
            function(v)
                AryUIDB.chatBackground.height = v
                if AryUI.ChatBackgroundModule and AryUI.ChatBackgroundModule.ApplySettings then AryUI.ChatBackgroundModule:ApplySettings() end
            end
        )

        -- Alpha (float)
        local alphaSlider, alphaBox = CreateSliderWithBox("AryUIChatBGAlpha", p, "Opacity", 0, 1, (AryUIDB.chatBackground and AryUIDB.chatBackground.alpha) or 0.6, 16, -260,
            function() end
        )
        alphaSlider:SetValueStep(0.01)
        alphaSlider:SetObeyStepOnDrag(true)
        alphaSlider:SetScript("OnValueChanged", function(self, value)
            value = tonumber(string.format("%.2f", value)) or 0
            alphaBox:SetText(string.format("%.2f", value))
            if _G["AryUIChatBGAlphaText"] then _G["AryUIChatBGAlphaText"]:SetText("Opacity: " .. string.format("%.2f", value)) end
            AryUIDB.chatBackground.alpha = value
            if AryUI.ChatBackgroundModule and AryUI.ChatBackgroundModule.ApplySettings then AryUI.ChatBackgroundModule:ApplySettings() end
        end)
        alphaBox:SetScript("OnEnterPressed", function(self)
            local val = tonumber(self:GetText())
            if not val then
                self:SetText(string.format("%.2f", AryUIDB.chatBackground and AryUIDB.chatBackground.alpha or 0.6))
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

        -- Frame Strata dropdown (re-added)
        local strataLabel = p:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        strataLabel:SetPoint("TOPLEFT", 16, -320)
        strataLabel:SetText("Frame Strata")

        local strataDrop = CreateFrame("Frame", "AryUIChatBGStrataDrop", p, "UIDropDownMenuTemplate")
        strataDrop:SetPoint("TOPLEFT", strataLabel, "BOTTOMLEFT", -16, -5)

        local strataOptions = {
            "BACKGROUND", "LOW", "MEDIUM", "HIGH",
            "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP"
        }

        UIDropDownMenu_SetWidth(strataDrop, 140)
        UIDropDownMenu_SetText(strataDrop, (AryUIDB.chatBackground and AryUIDB.chatBackground.strata) or "MEDIUM")

        UIDropDownMenu_Initialize(strataDrop, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            for _, s in ipairs(strataOptions) do
                info.text = s
                info.func = function()
                    AryUIDB.chatBackground = AryUIDB.chatBackground or {}
                    AryUIDB.chatBackground.strata = s
                    UIDropDownMenu_SetText(strataDrop, s)
                    if AryUI.ChatBackgroundModule and AryUI.ChatBackgroundModule.ApplySettings then AryUI.ChatBackgroundModule:ApplySettings() end
                end
                info.checked = (AryUIDB.chatBackground and AryUIDB.chatBackground.strata == s)
                UIDropDownMenu_AddButton(info)
            end
        end)
    end)

    -------------------------------------------------------
    -- Vault Report subpanel
    -------------------------------------------------------
    CreateSubpanel("Vault Report", function(p)
        CreateHeader(p, "Vault Report", -16)

        local vrCheckbox = CreateFrame("CheckButton", "AryUIVaultReportEnable_Sub", p, "ChatConfigCheckButtonTemplate")
        vrCheckbox:SetPoint("TOPLEFT", 16, -50)
        vrCheckbox.Text:SetText("Enable Vault Report")
        vrCheckbox:SetChecked(AryUIDB.vaultReport and AryUIDB.vaultReport.enabled)
        vrCheckbox:SetScript("OnClick", function(self)
            AryUIDB.vaultReport = AryUIDB.vaultReport or {}
            AryUIDB.vaultReport.enabled = self:GetChecked()
            if AryUI.VaultReportModule and AryUI.VaultReportModule.Toggle then
                AryUI.VaultReportModule:Toggle(self:GetChecked())
            end
        end)

        local vrButton = CreateFrame("Button", "AryUIVaultReportTest_Sub", p, "UIPanelButtonTemplate")
        vrButton:SetSize(100, 24)
        vrButton:SetPoint("TOPLEFT", vrCheckbox, "BOTTOMLEFT", 0, -10)
        vrButton:SetText("Open Vault")
        vrButton:SetScript("OnClick", function()
            if AryUI.VaultReportModule and AryUI.VaultReportModule.OpenVault then
                AryUI.VaultReportModule:OpenVault()
            end
        end)
    end)

    -------------------------------------------------------
    -- Auction House Filter subpanel
    -------------------------------------------------------
    CreateSubpanel("Auction House Filter", function(p)
        local ahHeader = CreateHeader(p, "Auction House Filter", -15)

        -- Separator
        local line0 = p:CreateTexture(nil, "ARTWORK")
        line0:SetColorTexture(1,1,1,0.05)
        line0:SetSize(600, 1)
        line0:SetPoint("TOPLEFT", ahHeader, "TOPLEFT", 0, -18)

        -- Section: Crafting Orders (Blizzard)
        local coTitle = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        coTitle:SetPoint("TOPLEFT", 16, -50)
        coTitle:SetText("Crafting Orders (Blizzard)")

        -- Crafting Orders: Set filter state
        local coSet = CreateFrame("CheckButton", nil, p, "ChatConfigCheckButtonTemplate")
        coSet:SetPoint("TOPLEFT", coTitle, "BOTTOMLEFT", 0, -8)
        coSet.Text:SetText("Set filter state")
        coSet:SetChecked(AryUIDB.ahFilter and AryUIDB.ahFilter.forCraftOrdersOverwrite)
        coSet:SetScript("OnClick", function(self)
            AryUIDB.ahFilter = AryUIDB.ahFilter or {}
            AryUIDB.ahFilter.forCraftOrdersOverwrite = self:GetChecked()
        end)

        -- Crafting Orders: Current Expansion Only value
        local coVal = CreateFrame("CheckButton", nil, p, "ChatConfigCheckButtonTemplate")
        coVal:SetPoint("LEFT", coSet, "RIGHT", 220, 0)
        coVal.Text:SetText("Current Expansion Only")
        coVal:SetChecked(AryUIDB.ahFilter and AryUIDB.ahFilter.forCraftOrdersValue)
        coVal:SetScript("OnClick", function(self)
            AryUIDB.ahFilter = AryUIDB.ahFilter or {}
            AryUIDB.ahFilter.forCraftOrdersValue = self:GetChecked()
        end)

        -- Crafting Orders: focus searchbar
        local coFocus = CreateFrame("CheckButton", nil, p, "ChatConfigCheckButtonTemplate")
        coFocus:SetPoint("TOPLEFT", coSet, "BOTTOMLEFT", 0, -8)
        coFocus.Text:SetText("... and focus search bar")
        coFocus:SetChecked(AryUIDB.ahFilter and AryUIDB.ahFilter.forCraftOrdersFocusSearchBar)
        coFocus:SetScript("OnClick", function(self)
            AryUIDB.ahFilter = AryUIDB.ahFilter or {}
            AryUIDB.ahFilter.forCraftOrdersFocusSearchBar = self:GetChecked()
        end)

        -- Separator
        local line1 = p:CreateTexture(nil, "ARTWORK")
        line1:SetColorTexture(1,1,1,0.05)
        line1:SetSize(600, 1)
        line1:SetPoint("TOPLEFT", coFocus, "BOTTOMLEFT", 0, -12)

        -- Section: Auction House (Blizzard)
        local ahTitle = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        ahTitle:SetPoint("TOPLEFT", line1, "BOTTOMLEFT", 0, -12)
        ahTitle:SetText("Auction House (Blizzard)")

        local ahSet = CreateFrame("CheckButton", nil, p, "ChatConfigCheckButtonTemplate")
        ahSet:SetPoint("TOPLEFT", ahTitle, "BOTTOMLEFT", 0, -8)
        ahSet.Text:SetText("Set filter state")
        ahSet:SetChecked(AryUIDB.ahFilter and AryUIDB.ahFilter.forAuctionHouseOverwrite)
        ahSet:SetScript("OnClick", function(self)
            AryUIDB.ahFilter = AryUIDB.ahFilter or {}
            AryUIDB.ahFilter.forAuctionHouseOverwrite = self:GetChecked()
        end)

        local ahVal = CreateFrame("CheckButton", nil, p, "ChatConfigCheckButtonTemplate")
        ahVal:SetPoint("LEFT", ahSet, "RIGHT", 220, 0)
        ahVal.Text:SetText("Current Expansion Only")
        ahVal:SetChecked(AryUIDB.ahFilter and AryUIDB.ahFilter.forAuctionHouseValue)
        ahVal:SetScript("OnClick", function(self)
            AryUIDB.ahFilter = AryUIDB.ahFilter or {}
            AryUIDB.ahFilter.forAuctionHouseValue = self:GetChecked()
        end)

        local ahFocus = CreateFrame("CheckButton", nil, p, "ChatConfigCheckButtonTemplate")
        ahFocus:SetPoint("TOPLEFT", ahSet, "BOTTOMLEFT", 0, -8)
        ahFocus.Text:SetText("... and focus search bar")
        ahFocus:SetChecked(AryUIDB.ahFilter and AryUIDB.ahFilter.forAuctionHouseFocusSearchBar)
        ahFocus:SetScript("OnClick", function(self)
            AryUIDB.ahFilter = AryUIDB.ahFilter or {}
            AryUIDB.ahFilter.forAuctionHouseFocusSearchBar = self:GetChecked()
        end)

        -- Separator
        local line2 = p:CreateTexture(nil, "ARTWORK")
        line2:SetColorTexture(1,1,1,0.05)
        line2:SetSize(600, 1)
        line2:SetPoint("TOPLEFT", ahFocus, "BOTTOMLEFT", 0, -12)

        -- Section: Auctionator (addon)
        local atTitle = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        atTitle:SetPoint("TOPLEFT", line2, "BOTTOMLEFT", 0, -12)
        atTitle:SetText("Auctionator (addon) -- disabled because lazy")
        
        --[[
        local atSet = CreateFrame("CheckButton", nil, p, "ChatConfigCheckButtonTemplate")
        atSet:SetPoint("TOPLEFT", atTitle, "BOTTOMLEFT", 0, -8)
        atSet.Text:SetText("Set filter state")
        atSet:SetChecked(AryUIDB.ahFilter and AryUIDB.ahFilter.forAuctionatorOverwrite)
        atSet:SetScript("OnClick", function(self)
            AryUIDB.ahFilter = AryUIDB.ahFilter or {}
            AryUIDB.ahFilter.forAuctionatorOverwrite = self:GetChecked()
        end)

        local atVal = CreateFrame("CheckButton", nil, p, "ChatConfigCheckButtonTemplate")
        atVal:SetPoint("LEFT", atSet, "RIGHT", 220, 0)
        atVal.Text:SetText("Current Expansion Only")
        atVal:SetChecked(AryUIDB.ahFilter and AryUIDB.ahFilter.forAuctionatorValue)
        atVal:SetScript("OnClick", function(self)
            AryUIDB.ahFilter = AryUIDB.ahFilter or {}
            AryUIDB.ahFilter.forAuctionatorValue = self:GetChecked()
        end)
        --]]
    end)

end

------------------------------------------------------------
-- ADDON LOAD HANDLER
------------------------------------------------------------
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, addon)
    if addon ~= "AryUI" then return end

    if not AryUIDB then AryUIDB = {} end
    ApplyDefaults(AryUIDB, globalDefaults)

    -- Allow modules to register defaults safely (modules may register themselves on file load)
    for _, mod in ipairs(AryUI.modules) do
        if mod.RegisterDefaults then
            mod:RegisterDefaults()
        end
    end

    -- Module OnLoad (attach/create frames)
    for _, mod in ipairs(AryUI.modules) do
        if mod.OnLoad then
            mod:OnLoad()
        end
    end

    -- Build options now
    CreateOptionsPanel()
end)
