local module = {}
table.insert(AryUI.modules, module)

function module:OnLoad()
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        tooltip:SetOwner(parent, "ANCHOR_NONE")
        tooltip:ClearAllPoints()
        tooltip:SetPoint(
            "BOTTOMRIGHT",
            UIParent,
            "BOTTOMRIGHT",
            AryUIDB.tooltipOffsetX,
            AryUIDB.tooltipOffsetY
        )
    end)
end
