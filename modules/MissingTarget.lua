local module = {}
table.insert(AryUI.modules, module)

local tFrame = CreateFrame("Frame")
tFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
tFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
tFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

local comatTextFrame = CreateFrame("Frame", "NoTargetText", UIParent)
comatTextFrame:SetSize(400, 50)
comatTextFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 450)
comatTextFrame:SetFrameStrata("LOW")

local combatText = comatTextFrame:CreateFontString(nil, "OVERLAY")
combatText:SetFont("Fonts\\FRIZQT__.TTF", 60, "OUTLINE")
combatText:SetPoint("CENTER")
combatText:SetJustifyH("CENTER")
combatText:SetTextColor(1, 1, 1, 1)
combatText:SetText("NO TARGET")

local anim = comatTextFrame:CreateAnimationGroup()
local fadeOut = anim:CreateAnimation("Alpha")
fadeOut:SetFromAlpha(1)
fadeOut:SetToAlpha(0.3)
fadeOut:SetDuration(0.8)
fadeOut:SetSmoothing("IN_OUT")

local fadeIn = anim:CreateAnimation("Alpha")
fadeIn:SetFromAlpha(0.3)
fadeIn:SetToAlpha(1)
fadeIn:SetDuration(0.8)
fadeIn:SetSmoothing("IN_OUT")
fadeIn:SetOrder(2)

anim:SetLooping("REPEAT")
comatTextFrame:Hide()

local function ShowNoTarget()
    if not comatTextFrame:IsShown() then
        comatTextFrame:Show()
        anim:Play()
    end
end

local function HideNoTarget()
    if comatTextFrame:IsShown() then
        anim:Stop()
        comatTextFrame:Hide()
    end
end

tFrame:SetScript("OnEvent", function()
    if (not UnitExists("target")) and UnitAffectingCombat("player") then
        ShowNoTarget()
    else
        HideNoTarget()
    end
end)