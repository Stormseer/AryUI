local module = {}

------------------------------------------------------------
-- MODULE REGISTRATION
------------------------------------------------------------
local function RegisterModule()
    AryUI = AryUI or {}
    AryUI.modules = AryUI.modules or {}
    for _, m in ipairs(AryUI.modules) do
        if m == module then return end
    end
    tinsert(AryUI.modules, module)
    AryUI.AHFilterModule = module
end

if AryUI and AryUI.modules then
    RegisterModule()
else
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, event, addon)
        if addon == "AryUI" then
            RegisterModule()
            self:UnregisterEvent("ADDON_LOADED")
            self:SetScript("OnEvent", nil)
        end
    end)
end

------------------------------------------------------------
-- Defaults & SavedVariables
------------------------------------------------------------
local defaults = {
    ahFilter = {
        enabled = true,

        -- Auction House (Blizzard)
        forAuctionHouseOverwrite = true,           -- "Set filter state"
        forAuctionHouseValue = true,               -- "Current Expansion Only" value
        forAuctionHouseFocusSearchBar = true,      -- focus search box after applying

        -- Crafting Orders (Blizzard)
        forCraftOrdersOverwrite = true,
        forCraftOrdersValue = true,
        forCraftOrdersFocusSearchBar = true,

        -- Auctionator (addon)
        forAuctionatorOverwrite = true,
        forAuctionatorValue = true,
    }
}

function module:RegisterDefaults()
    AryUIDB = AryUIDB or {}
    AryUIDB.ahFilter = AryUIDB.ahFilter or {}
    for k, v in pairs(defaults.ahFilter) do
        if AryUIDB.ahFilter[k] == nil then
            AryUIDB.ahFilter[k] = v
        end
    end
end

------------------------------------------------------------
-- Helpers to set filters
------------------------------------------------------------
local function focusSearchBar(editBox, shouldFocus)
    shouldFocus = shouldFocus or false
    if not editBox then return end
    if (not shouldFocus) and editBox:HasFocus() then
        editBox:ClearFocus()
    end
    if shouldFocus and not editBox:HasFocus() then
        editBox:SetFocus()
    end
end

local function ApplyAHFilterFromConfig(cfg)
    if not cfg.forAuctionHouseOverwrite then return end
    if not AuctionHouseFrame or not AuctionHouseFrame.SearchBar then return end

    local searchBar = AuctionHouseFrame.SearchBar
    if searchBar.FilterButton and searchBar.FilterButton.filters then
        searchBar.FilterButton.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly] = cfg.forAuctionHouseValue and true or false
        if searchBar.UpdateClearFiltersButton then
            pcall(searchBar.UpdateClearFiltersButton, searchBar)
        end
    end

    if searchBar.SearchBox then
        focusSearchBar(searchBar.SearchBox, cfg.forAuctionHouseFocusSearchBar)
    end
end

local function ApplyCraftOrdersFilterFromConfig(cfg)
    if not cfg.forCraftOrdersOverwrite then return end
    if not ProfessionsCustomerOrdersFrame then return end
    local browse = ProfessionsCustomerOrdersFrame.BrowseOrders
    if not browse or not browse.SearchBar then return end

    local filterDropdown = browse.SearchBar.FilterDropdown
    local searchBox = browse.SearchBar.SearchBox
    if filterDropdown and filterDropdown.filters then
        filterDropdown.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly] = cfg.forCraftOrdersValue and true or false
        if filterDropdown.ValidateResetState then
            pcall(filterDropdown.ValidateResetState, filterDropdown)
        end
    end
    focusSearchBar(searchBox, cfg.forCraftOrdersFocusSearchBar)
end

local function ApplyAuctionatorFilterFromConfig(cfg)
    if not cfg.forAuctionatorOverwrite then return end
    if not C_AddOns or not C_AddOns.IsAddOnLoaded then return end
    if not C_AddOns.IsAddOnLoaded("Auctionator") then return end
    local frame = AuctionatorShoppingTabItemFrame
    if not frame or not frame.ExpansionContainer or not frame.ExpansionContainer.DropDown then return end
    local drop = frame.ExpansionContainer.DropDown
    local val = cfg.forAuctionatorValue and tostring(LE_EXPANSION_LEVEL_CURRENT) or ""
    pcall(function() drop:SetValue(val) end)
end

------------------------------------------------------------
-- Hooking & initialization logic (mirrors the WA structure)
------------------------------------------------------------
local function EnsureAHHookOnce()
    if not AuctionHouseFrame or not AuctionHouseFrame.SearchBar then return end
    if module._ahHooked then return end
    module._ahHooked = true

    local searchBar = AuctionHouseFrame.SearchBar
    local function onShow()
        local cfg = AryUIDB.ahFilter
        if not cfg then return end
        ApplyAHFilterFromConfig(cfg)
    end

    -- reapply when the search bar is shown (tab switching etc.)
    searchBar:HookScript("OnShow", function()
        C_Timer.After(0, onShow)
    end)

    -- ensure initial application
    C_Timer.After(0, onShow)
end

local function EnsureCraftOrdersHookOnce()
    if not ProfessionsCustomerOrdersFrame then return end
    if module._craftHooked then return end
    module._craftHooked = true

    local filterDropdown = ProfessionsCustomerOrdersFrame.BrowseOrders and ProfessionsCustomerOrdersFrame.BrowseOrders.SearchBar and ProfessionsCustomerOrdersFrame.BrowseOrders.SearchBar.FilterDropdown
    local searchBox = ProfessionsCustomerOrdersFrame.BrowseOrders and ProfessionsCustomerOrdersFrame.BrowseOrders.SearchBar and ProfessionsCustomerOrdersFrame.BrowseOrders.SearchBar.SearchBox

    if not filterDropdown then
        -- some times the frame is not yet constructed; schedule a small delay
        C_Timer.After(0.05, function() EnsureCraftOrdersHookOnce() end)
        return
    end

    local function onShow()
        local cfg = AryUIDB.ahFilter
        if not cfg then return end
        ApplyCraftOrdersFilterFromConfig(cfg)
    end

    filterDropdown:HookScript("OnShow", function()
        C_Timer.After(0, onShow)
    end)

    C_Timer.After(0, onShow)
end

local function EnsureAuctionatorHookOnce()
    if module._auctionatorHooked then return end
    module._auctionatorHooked = true

    -- Auctionator frames often initialize on load; try to hook shortly after
    C_Timer.After(0.1, function()
        if not C_AddOns or not C_AddOns.IsAddOnLoaded or not C_AddOns.IsAddOnLoaded("Auctionator") then
            -- not present
            return
        end
        -- safe call
        C_Timer.After(0, function()
            local cfg = AryUIDB.ahFilter
            if cfg then ApplyAuctionatorFilterFromConfig(cfg) end
        end)
    end)
end

------------------------------------------------------------
-- Event handler
------------------------------------------------------------
local evt = CreateFrame("Frame")
evt:RegisterEvent("ADDON_LOADED")
evt:RegisterEvent("AUCTION_HOUSE_SHOW")
evt:RegisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER")
evt:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW") -- for Auctionator PIM opening
evt:SetScript("OnEvent", function(self, event, arg1, ...)
    -- ensure db present
    AryUIDB = AryUIDB or {}
    AryUIDB.ahFilter = AryUIDB.ahFilter or defaults.ahFilter

    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_AuctionHouseUI" then
            C_Timer.After(0, EnsureAHHookOnce)
        end
        if arg1 == "Blizzard_CraftingUI" or arg1 == "Blizzard_Professions" then
            C_Timer.After(0, EnsureCraftOrdersHookOnce)
        end
        -- if Auctionator is loaded later, attempt hooking
        if arg1 == "Auctionator" then
            C_Timer.After(0.05, EnsureAuctionatorHookOnce)
        end
        return
    end

    if event == "AUCTION_HOUSE_SHOW" then
        C_Timer.After(0, EnsureAHHookOnce)
        C_Timer.After(0, function() ApplyAHFilterFromConfig(AryUIDB.ahFilter) end)
    elseif event == "CRAFTINGORDERS_SHOW_CUSTOMER" then
        C_Timer.After(0, EnsureCraftOrdersHookOnce)
        C_Timer.After(0, function() ApplyCraftOrdersFilterFromConfig(AryUIDB.ahFilter) end)
    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
        local ptype = arg1
        if ptype == Enum.PlayerInteractionType.Auctioneer then
            -- wait a short bit for Auctionator or other addons
            C_Timer.After(0.05, EnsureAuctionatorHookOnce)
        end
    end
end)

------------------------------------------------------------
-- API
------------------------------------------------------------
function module:Toggle(enabled)
    AryUIDB = AryUIDB or {}
    AryUIDB.ahFilter = AryUIDB.ahFilter or {}
    AryUIDB.ahFilter.enabled = enabled
    if enabled then
        -- attempt to apply immediately
        C_Timer.After(0, function()
            ApplyAHFilterFromConfig(AryUIDB.ahFilter)
            ApplyCraftOrdersFilterFromConfig(AryUIDB.ahFilter)
            ApplyAuctionatorFilterFromConfig(AryUIDB.ahFilter)
        end)
    end
end

function module:OnLoad()
    self:RegisterDefaults()
    -- nothing else; events will trigger application when UI opens
end

return module
