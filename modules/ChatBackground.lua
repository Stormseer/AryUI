local module = {}
table.insert(AryUI.modules, module)

-- Default config for the module
local defaults = {
    chatBackground = {
        enabled = true,
        width = 300,
        height = 150,
        strata = "BACKGROUND",
        alpha = 0.6,
        lockPosition = false,
        pos = { point = "BOTTOMLEFT", x = 20, y = 20 },
    }
}

-- First: register defaults into DB
function module:RegisterDefaults()
    AryUIDB.chatBackground = AryUIDB.chatBackground or {}

    for k, v in pairs(defaults.chatBackground) do
        if AryUIDB.chatBackground[k] == nil then
            AryUIDB.chatBackground[k] = v
        end
    end
end

local frame

function module:CreateFrame()
    if frame then
        frame:Show()
        return 
    end

    frame = CreateFrame("Frame", "AryUIChatBackground", UIParent)
    frame:SetSize(AryUIDB.chatBackground.width, AryUIDB.chatBackground.height)
    frame:SetPoint(
        AryUIDB.chatBackground.pos.point,
        UIParent,
        AryUIDB.chatBackground.pos.point,
        AryUIDB.chatBackground.pos.x,
        AryUIDB.chatBackground.pos.y
    )
    frame:SetFrameStrata(AryUIDB.chatBackground.strata)

    frame.texture = frame:CreateTexture(nil, "BACKGROUND")
    frame.texture:SetAllPoints(true)
    frame.texture:SetColorTexture(0, 0, 0, AryUIDB.chatBackground.alpha)  -- translucent black background

    -- Movable
    frame:EnableMouse(true)
    frame:SetMovable(true)

    local function UpdateMovability()
        if AryUIDB.chatBackground.lockPosition then
            frame:RegisterForDrag() -- disable dragging
        else
            frame:RegisterForDrag("LeftButton")
        end
    end

    -- Movement handlers
    frame:SetScript("OnDragStart", function(self)
        if not AryUIDB.chatBackground.lockPosition then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        AryUIDB.chatBackground.pos.point = point
        AryUIDB.chatBackground.pos.x = x
        AryUIDB.chatBackground.pos.y = y
    end)

    UpdateMovability()

    module.UpdateMovability = UpdateMovability
end

function module:OnLoad()
    self:RegisterDefaults()
    if AryUIDB.chatBackground.enabled then
        self:CreateFrame()
    end
end

-- Called by the options UI
function module:ApplySettings()
    if not frame then return end

    frame:SetSize(AryUIDB.chatBackground.width, AryUIDB.chatBackground.height)
    frame:SetFrameStrata(AryUIDB.chatBackground.strata)

    frame:ClearAllPoints()
    frame:SetPoint(
        AryUIDB.chatBackground.pos.point,
        UIParent,
        AryUIDB.chatBackground.pos.point,
        AryUIDB.chatBackground.pos.x,
        AryUIDB.chatBackground.pos.y
    )
    frame.texture:SetColorTexture(0, 0, 0, AryUIDB.chatBackground.alpha)
end

AryUI.ChatBackgroundModule = module
