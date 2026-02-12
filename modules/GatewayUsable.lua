local module = {}
AryUI.GatewayUsable = module
table.insert(AryUI.modules, module)

local gFrame = CreateFrame("Frame")
gFrame:RegisterEvent("SPELL_UPDATE_USABLE")

local comatTextFrame = CreateFrame("Frame", "GatewayUsableText", UIParent)
comatTextFrame:SetSize(400, 50)
comatTextFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 450)
comatTextFrame:SetFrameStrata("LOW")

local combatText = comatTextFrame:CreateFontString(nil, "OVERLAY")
combatText:SetFont("Fonts\\FRIZQT__.TTF", 60, "OUTLINE")
combatText:SetPoint("CENTER")
combatText:SetJustifyH("CENTER")
combatText:SetTextColor(135/255, 136/255, 238/255, 1)
combatText:SetText("GATEWAY USABLE")
comatTextFrame:Hide()

local function ShowGatewayText()
    if not comatTextFrame:IsShown() then
        comatTextFrame:Show()
    end
end

local function HideGatewayText()
    if comatTextFrame:IsShown() then
        comatTextFrame:Hide()
    end
end

function module:UpdateGatewayText()
    print("OnLoad Updater")
    if not AryUIDB.gatewayTextEnabled then
        HideGatewayText()
        return
    end

    comatTextFrame:ClearAllPoints()
    comatTextFrame:SetPoint(
        "CENTER",
        UIParent,
        "CENTER",
        AryUIDB.gatewayUsableOffsetX or 0,
        AryUIDB.gatewayUsableOffsetY or 450
    )

    local size = AryUIDB.gatewayUsableFontSize or 60
    combatText:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
end

function CheckUsable()
    if C_Item.IsUsableItem(188152) then
        ShowGatewayText()
    else
        HideGatewayText()
    end
end

function module:OnLoad()
    self:UpdateGatewayText()

    CheckUsable()
end

gFrame:SetScript("OnEvent", function()
    if not AryUIDB.gatewayTextEnabled then
        HideGatewayText()
        return
    end

    CheckUsable()
end)