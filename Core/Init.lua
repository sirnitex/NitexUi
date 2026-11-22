-- NitexUI: Init
-- Sets up the addon namespace, a central event dispatcher and a simple module system.

local addonName, ns = ...

ns.name = addonName

local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
ns.version = GetAddOnMetadata(addonName, "Version") or "dev"

-- Client flavour. Retail (Midnight) and Forever share the same Mainline UI/API,
-- so this is only for the rare spot where they differ.
ns.isRetail  = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
ns.isForever = not ns.isRetail
ns.modules = {}
ns.L = ns.L or {}

---------------------------------------------------------------------------
-- Event handling
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local handlers = {} -- [event] = { [owner] = func }

--- Register a callback for an event. `owner` lets several modules share one event.
function ns:RegisterEvent(event, owner, func)
    if not handlers[event] then
        handlers[event] = {}
        eventFrame:RegisterEvent(event)
    end
    handlers[event][owner] = func
end

function ns:UnregisterEvent(event, owner)
    local list = handlers[event]
    if not list then return end
    list[owner] = nil
    if next(list) == nil then
        handlers[event] = nil
        eventFrame:UnregisterEvent(event)
    end
end

-- Unit events for the player only (RegisterUnitEvent), on their own frame so a module that
-- wants e.g. UNIT_AURA for the player never gets it for every other unit.
local playerFrame = CreateFrame("Frame")
local playerHandlers = {} -- [event] = { [owner] = func }

function ns:RegisterPlayerEvent(event, owner, func)
    if not playerHandlers[event] then
        playerHandlers[event] = {}
        playerFrame:RegisterUnitEvent(event, "player")
    end
    playerHandlers[event][owner] = func
end

function ns:UnregisterPlayerEvent(event, owner)
    local list = playerHandlers[event]
    if not list then return end
    list[owner] = nil
    if next(list) == nil then
        playerHandlers[event] = nil
        playerFrame:UnregisterEvent(event)
    end
end

--- Debug helper: every event currently registered, with the owner (module) that wants it.
function ns:DumpEvents()
    local count = 0
    for i = 1, 2 do
        local all = i == 1 and handlers or playerHandlers
        for event, list in next, all do
            for owner in next, list do
                count = count + 1
                local name = owner == self and "Core" or (type(owner) == "table" and owner.name) or tostring(owner)
                print("  " .. event .. (i == 2 and " (player)" or "") .. "  <- " .. name)
            end
        end
    end
    return count
end

local function Dispatch(all, event, ...)
    local list = all[event]
    if not list then return end
    for owner, func in next, list do
        func(owner, event, ...)
    end
end

eventFrame:SetScript("OnEvent", function(_, event, ...) Dispatch(handlers, event, ...) end)
playerFrame:SetScript("OnEvent", function(_, event, ...) Dispatch(playerHandlers, event, ...) end)

---------------------------------------------------------------------------
-- Modules
---------------------------------------------------------------------------
--- Create a new module. Modules can define:
---   :OnInitialize()  ADDON_LOADED, always (SavedVariables ready). Keep it to setup only.
---   :OnEnable()      when the module is turned on (at login, or live from the options).
---   :OnDisable()     when the module is turned off live. Undo what OnEnable did if possible.
--- Every module is OFF by default; the user turns on only what they need.
function ns:NewModule(name)
    assert(not self.modules[name], "Module already exists: " .. name)
    local module = { name = name }
    self.modules[name] = module
    return module
end

function ns:GetModule(name)
    return self.modules[name]
end

function ns:IsModuleEnabled(name)
    return self.db.modules[name] == true
end

function ns:SetModuleEnabled(name, on)
    local module = self.modules[name]
    on = on and true or false
    self.db.modules[name] = on
    if on and not module.enabled then
        module.enabled = true
        if module.OnEnable then module:OnEnable() end
    elseif not on and module.enabled then
        module.enabled = false
        if module.OnDisable then module:OnDisable() end
    end
end

---------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------
ns:RegisterEvent("ADDON_LOADED", ns, function(self, _, loadedName)
    if loadedName ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED", self)

    self:InitDatabase()

    for _, module in pairs(self.modules) do
        if module.OnInitialize then module:OnInitialize() end
    end
end)

ns:RegisterEvent("PLAYER_LOGIN", ns, function(self)
    self:UnregisterEvent("PLAYER_LOGIN", self)

    for name, module in pairs(self.modules) do
        if self:IsModuleEnabled(name) then
            module.enabled = true
            if module.OnEnable then module:OnEnable() end
        end
    end

    self:Print(self.L["LOADED"]:format(self.version))
end)

-- Expose the namespace globally for debugging (/dump NitexUI)
_G[addonName] = ns
