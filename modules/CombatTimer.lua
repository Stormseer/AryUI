local module = {}
AryUI.CombatTimer = module
table.insert(AryUI.modules, module)

-------------------------------------------------
-- Frame setup
-------------------------------------------------
local combatTimerFrame = CreateFrame("Frame", "CombatTimeTrackercombatTimerFrame", UIParent, "BackdropTemplate")
combatTimerFrame:SetSize(90, 37)
combatTimerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
combatTimerFrame:SetBackdrop({
    bgFile = "Interface/Buttons/WHITE8x8",
})
combatTimerFrame:SetBackdropColor(0, 0, 0, 1)
combatTimerFrame:SetAlpha(0.8)
combatTimerFrame:Show()
combatTimerFrame:SetMovable(true)
combatTimerFrame:EnableMouse(true)
combatTimerFrame:RegisterForDrag("LeftButton")

combatTimerFrame:SetScript("OnDragStart", function(self)
    if AryUIDB.combatTimerLocked then return end
    self:StartMoving()
end)

combatTimerFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()

    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    AryUIDB.combatTimerPos = {
        point = point,
        relativePoint = relativePoint,
        x = xOfs,
        y = yOfs
    }
end)

-------------------------------------------------
-- combatTimerText
-------------------------------------------------
local combatTimerText = combatTimerFrame:CreateFontString(nil, "OVERLAY")
combatTimerText:SetFont("Fonts/FRIZQT__.TTF", 24, "OUTLINE")
combatTimerText:SetPoint("CENTER")
combatTimerText:SetTextColor(1, 1, 1)
combatTimerText:SetText("00:00")

-------------------------------------------------
-- Timer state
-------------------------------------------------
local elapsedSeconds = 0
local ticker = nil

local function FormatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%02d:%02d", m, s)
end

-------------------------------------------------
-- Helper Functions
-------------------------------------------------
local function StartTimer()
    if ticker then return end

    ticker = C_Timer.NewTicker(1, function()
        elapsedSeconds = elapsedSeconds + 1
        combatTimerText:SetText(FormatTime(elapsedSeconds))
    end)
end

local function StopTimer()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
end

local function RestorePosition()
    local pos = AryUIDB.combatTimerPos
    if pos and pos.point then
        combatTimerFrame:ClearAllPoints()
        combatTimerFrame:SetPoint(
            pos.point,
            UIParent,
            pos.relativePoint,
            pos.x,
            pos.y
        )
    end
end


function module:AryUIToggleCombatTimer()
    if AryUIDB.combatTimerEnabled then
        combatTimerFrame:Show()
    else
        combatTimerFrame:Hide()
        StopTimer()
    end
end

function module:AryUILockCombatTimer()
    if AryUIDB.combatTimerLocked then
        combatTimerFrame:EnableMouse(false)
    else
        combatTimerFrame:EnableMouse(true)
    end
end

function module:OnLoad()
    RestorePosition()
    module:AryUILockCombatTimer()
    module:AryUIToggleCombatTimer()

    AryUIDB.combatTimerEnabled = AryUIDB.combatTimerEnabled ~= false
    AryUIDB.combatTimerLocked  = AryUIDB.combatTimerLocked or false
    AryUIDB.combatTimerPos     = AryUIDB.combatTimerPos or {}
end

-------------------------------------------------
-- Combat events
-------------------------------------------------
combatTimerFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Enter combat
combatTimerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Leave combat

combatTimerFrame:SetScript("OnEvent", function(_, event)
    if not AryUIDB.combatTimerEnabled then return end

    if event == "PLAYER_REGEN_DISABLED" then
        elapsedSeconds = 0
        combatTimerText:SetText("00:00")
        combatTimerFrame:Show()
        StartTimer()

    elseif event == "PLAYER_REGEN_ENABLED" then
        StopTimer()
    end
end)