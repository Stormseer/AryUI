local module = {}

------------------------------------------------------------
-- Registration (safe regardless of load order)
------------------------------------------------------------
local regFrame = CreateFrame("Frame")
regFrame:RegisterEvent("ADDON_LOADED")
regFrame:SetScript("OnEvent", function(self, event, addon)
    if addon ~= "AryUI" then return end

    AryUI = AryUI or {}
    AryUI.modules = AryUI.modules or {}

    for _, m in ipairs(AryUI.modules) do
        if m == module then
            self:UnregisterEvent("ADDON_LOADED")
            return
        end
    end

    tinsert(AryUI.modules, module)
    AryUI.PartyGreetingModule = module

    self:UnregisterEvent("ADDON_LOADED")
end)

------------------------------------------------------------
-- Defaults
------------------------------------------------------------
local defaults = {
    partyGreeting = {
        enabled = true,

        delayMin = 6,
        delayMax = 10,

        greetings = {
            "Yo.",
            "Heya",
            "Yo",
            "Hello",
            "Greetings",
            "Well met, o7",
            "Sup",
            "o7",
            "Meowsers!",
            "Meowdy everybunny!",
            "Meowdy everybunny, how's it hoppin'"
        }
    }
}

function module:RegisterDefaults()
    AryUIDB.partyGreeting = AryUIDB.partyGreeting or {}
    for k, v in pairs(defaults.partyGreeting) do
        if AryUIDB.partyGreeting[k] == nil then
            -- Deep copy greetings
            if k == "greetings" then
                AryUIDB.partyGreeting.greetings = {}
                for i, g in ipairs(defaults.partyGreeting.greetings) do
                    AryUIDB.partyGreeting.greetings[i] = g
                end
            else
                AryUIDB.partyGreeting[k] = v
            end
        end
    end
end

------------------------------------------------------------
-- Core functionality
------------------------------------------------------------
local function SendPartyGreeting()
    local cfg = AryUIDB.partyGreeting
    if not cfg or not cfg.enabled then return end
    if IsInRaid() then return end
    if not IsInGroup() then return end

    local greetings = cfg.greetings
    if not greetings or #greetings == 0 then return end

    local greeting = greetings[math.random(1, #greetings)]
    SendChatMessage(greeting, "PARTY")
end

------------------------------------------------------------
-- Event handler
------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("GROUP_JOINED")
f:SetScript("OnEvent", function(_, event)
    if not AryUIDB.partyGreeting or not AryUIDB.partyGreeting.enabled then return end
    if IsInRaid() then return end

    local cfg = AryUIDB.partyGreeting
    local minDelay = tonumber(cfg.delayMin) or 6
    local maxDelay = tonumber(cfg.delayMax) or 10
    if maxDelay < minDelay then maxDelay = minDelay end

    local delay = math.random(minDelay, maxDelay)
    C_Timer.After(delay, SendPartyGreeting)
end)

------------------------------------------------------------
-- API
------------------------------------------------------------
function module:Toggle(enabled)
    AryUIDB.partyGreeting.enabled = enabled and true or false
end

return module
