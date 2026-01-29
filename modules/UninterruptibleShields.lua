local module = {}
AryUI.InterruptShields = module
table.insert(AryUI.modules, module)

local DEFAULT_TARGET_POINT = { "CENTER", UIParent, "CENTER", 0, 100 }
local DEFAULT_FOCUS_POINT  = { "CENTER", UIParent, "CENTER", 0, 70 }
local targetFrame = CreateFrame("Frame", "SpellcastingTargetShieldFrame", UIParent, "BackdropTemplate")
local focusFrame = CreateFrame("Frame", "SpellcastingFocusShieldFrame", UIParent, "BackdropTemplate")

targetFrame:SetSize(42, 42)
targetFrame:SetPoint("CENTER")
targetFrame:SetFrameStrata("HIGH")
targetFrame:SetFrameLevel(100)

focusFrame:SetSize(42, 42)
focusFrame:SetPoint("CENTER")
focusFrame:SetFrameStrata("HIGH")
focusFrame:SetFrameLevel(100)

targetFrame:SetMovable(true)
targetFrame:EnableMouse(true)
targetFrame:RegisterForDrag("LeftButton")
targetFrame:SetClampedToScreen(true)

focusFrame:SetMovable(true)
focusFrame:EnableMouse(true)
focusFrame:RegisterForDrag("LeftButton")
focusFrame:SetClampedToScreen(true)

local function SaveFramePosition(frame, key)
    if not AryUIDB.interruptShieldsPosition then
        AryUIDB.interruptShieldsPosition = {}
    end

    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()

    AryUIDB.interruptShieldsPosition[key] = {
        point = point,
        relativeTo = relativeTo and relativeTo:GetName() or "UIParent",
        relativePoint = relativePoint,
        x = xOfs,
        y = yOfs,
    }
end

local function RestoreFramePosition(frame, key, defaultPoint)
    local pos = AryUIDB.interruptShieldsPosition
        and AryUIDB.interruptShieldsPosition[key]

    frame:ClearAllPoints()

    if pos then
        local relativeTo = _G[pos.relativeTo] or UIParent
        frame:SetPoint(
            pos.point,
            relativeTo,
            pos.relativePoint,
            pos.x,
            pos.y
        )
    else
        frame:SetPoint(unpack(defaultPoint))
    end
end

function module:AryUIToggleInterruptShields()
    if AryUIDB.interruptShieldsEnabled then
        targetFrame:Show()
        focusFrame:Show()
    else
        targetFrame:Hide()
        focusFrame:Hide()
    end
end

function module:AryUILockInterruptShields()
    if AryUIDB.interruptShieldsLocked then
        targetFrame:EnableMouse(false)
        focusFrame:EnableMouse(false)
    else
        targetFrame:EnableMouse(true)
        focusFrame:EnableMouse(true)
    end
end

function module:OnLoad()
    -- Defaults
    AryUIDB.interruptShieldsEnabled = AryUIDB.interruptShieldsEnabled ~= false
    AryUIDB.interruptShieldsLocked  = AryUIDB.interruptShieldsLocked or false
    AryUIDB.interruptShieldsPosition = AryUIDB.interruptShieldsPosition or {}

    -- Restore positions
    RestoreFramePosition(targetFrame, "target", DEFAULT_TARGET_POINT)
    RestoreFramePosition(focusFrame, "focus", DEFAULT_FOCUS_POINT)

    -- Apply settings
    module:AryUILockInterruptShields()
    module:AryUIToggleInterruptShields()
end

targetFrame:SetScript("OnDragStart", function(self)
    if not AryUIDB.interruptShieldsLocked then
        self:StartMoving()
    end
end)

targetFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveFramePosition(self, "target")
end)


focusFrame:SetScript("OnDragStart", function(self)
    if not AryUIDB.interruptShieldsLocked then
        self:StartMoving()
    end
end)

focusFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveFramePosition(self, "focus")
end)

local targetTexture = targetFrame:CreateTexture(nil, "OVERLAY")
targetTexture:SetAllPoints(targetFrame)
targetTexture:SetTexture("Interface/AddOns/AryUI/art/spellcastingShield.tga")
targetFrame:Show()
targetFrame:SetAlpha(0)

local focusTexture = focusFrame:CreateTexture(nil, "OVERLAY")
focusTexture:SetAllPoints(focusFrame)
focusTexture:SetTexture("Interface/AddOns/AryUI/art/spellcastingShield.tga")
focusFrame:Show()
focusFrame:SetAlpha(0)

local function ShowTargetShield()
    targetFrame:SetAlpha(1)
end

local function HideTargetShield()
    targetFrame:SetAlpha(0)
end

local function ShowFocusShield()
    focusFrame:SetAlpha(1)
end

local function HideFocusShield()
    focusFrame:SetAlpha(0)
end

targetFrame:RegisterEvent("UNIT_SPELLCAST_START")
targetFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
targetFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
targetFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
targetFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
targetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

targetFrame:SetScript("OnEvent", function(_, event, unit, _, spellId)

    -- Check if there is a casting focus target. 
    if event == "PLAYER_FOCUS_CHANGED" then
        local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("focus")
        if name then
            ShowFocusShield()
            focusFrame:SetAlphaFromBoolean(notInterruptible, 1, 0)
        else
            HideFocusShield()
        end

        return
    end

    -- Check if there is a casting target. 
    if event == "PLAYER_TARGET_CHANGED" then
        local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
        if name then
            ShowTargetShield()
            targetFrame:SetAlphaFromBoolean(notInterruptible, 1, 0)
        else
            HideTargetShield()
        end

        return
    end

    -- Focus cast start (cast)
    if (event == "UNIT_SPELLCAST_START") then
        if unit == "target" then
            local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
            ShowTargetShield()
            targetFrame:SetAlphaFromBoolean(notInterruptible, 1, 0)
            return
        end

        if unit == "focus" then
            local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("focus")
            ShowFocusShield()
            focusFrame:SetAlphaFromBoolean(notInterruptible, 1, 0)
            return
        end

        return
    end

      -- Focus cast start (channel)
    if (event == "UNIT_SPELLCAST_CHANNEL_START") then
        if unit == "target" then
            local name, _, _, _, _, _, _, notInterruptible = UnitChannelInfo("target")
            ShowTargetShield()
            targetFrame:SetAlphaFromBoolean(notInterruptible, 1, 0)
            return
        end

        if unit == "focus" then
            local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("focus")
            ShowFocusShield()
            focusFrame:SetAlphaFromBoolean(notInterruptible, 1, 0)
            return
        end

        return
    end

    -- Focus cast end (cast or channel)
    if (event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP") then
        if unit == "target" then
            HideTargetShield()
            return
        end

        if unit == "focus" then
            HideFocusShield()
            return
        end

        return
    end
end)
