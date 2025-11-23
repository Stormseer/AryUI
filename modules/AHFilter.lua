local module = {}
local function RegisterModule()
    AryUI = AryUI or {}
    AryUI.modules = AryUI.modules or {}
    for _, m in ipairs(AryUI.modules) do if m==module then return end end
    table.insert(AryUI.modules, module)
    AryUI.AHFilterModule = module
end

if AryUI and AryUI.modules then RegisterModule() else
    local f=CreateFrame("Frame"); f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self,ev,addon)
        if addon=="AryUI" then RegisterModule() end
    end)
end

local defaults={ahFilter={enabled=true}}
function module:RegisterDefaults()
    AryUIDB=AryUIDB or {}; AryUIDB.ahFilter=AryUIDB.ahFilter or {}
    if AryUIDB.ahFilter.enabled==nil then AryUIDB.ahFilter.enabled=true end
end

local function ApplyAH()
    if not AryUIDB.ahFilter.enabled then return end
    if not AuctionHouseFrame or not AuctionHouseFrame.SearchBar then return end
    local b=AuctionHouseFrame.SearchBar
    if b.FilterButton and b.FilterButton.filters then
        b.FilterButton.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly]=true
        if b.UpdateClearFiltersButton then b:UpdateClearFiltersButton() end
    end
end

local function ApplyCO()
    if not AryUIDB.ahFilter.enabled then return end
    local f=ProfessionsCustomerOrdersFrame
    if not f then return end
    local dd=f.BrowseOrders.SearchBar.FilterDropdown
    if dd and dd.filters then
        dd.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly]=true
        if dd.ValidateResetState then dd:ValidateResetState() end
    end
end

local function ApplyAT()
    if not AryUIDB.ahFilter.enabled then return end
    if not C_AddOns.IsAddOnLoaded("Auctionator") then return end
    local fr=AuctionatorShoppingTabItemFrame
    if fr and fr.ExpansionContainer and fr.ExpansionContainer.DropDown then
        fr.ExpansionContainer.DropDown:SetValue(tostring(LE_EXPANSION_LEVEL_CURRENT))
    end
end

local e=CreateFrame("Frame")
e:RegisterEvent("AUCTION_HOUSE_SHOW")
e:RegisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER")
e:RegisterEvent("ADDON_LOADED")
e:SetScript("OnEvent", function(self,ev,a1)
    if ev=="ADDON_LOADED" and a1=="Blizzard_AuctionHouseUI" then C_Timer.After(0,ApplyAH) end
    if ev=="AUCTION_HOUSE_SHOW" then C_Timer.After(0,ApplyAH) end
    if ev=="CRAFTINGORDERS_SHOW_CUSTOMER" then C_Timer.After(0,ApplyCO) end
    C_Timer.After(0.1,ApplyAT)
end)

function module:OnLoad() self:RegisterDefaults() end
function module:Toggle(en) AryUIDB.ahFilter.enabled=en end

return module