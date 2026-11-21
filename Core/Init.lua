-- NitexUI: Init
-- Sets up the addon namespace, a central event dispatcher and a simple module system.

local addonName, ns = ...

ns.name = addonName
ns.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "dev"
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

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local list = handlers[event]
    if not list then return end
    for owner, func in pairs(list) do
        local ok, err = pcall(func, owner, event, ...)
        if not ok then
            geterrorhandler()(err)
        end
    end
end)

---------------------------------------------------------------------------
-- Modules
---------------------------------------------------------------------------
--- Create a new module. Modules can define :OnInitialize() and :OnEnable().
function ns:NewModule(name)
    assert(not self.modules[name], "Module already exists: " .. name)
    local module = { name = name }
    self.modules[name] = module
    return module
end

function ns:GetModule(name)
    return self.modules[name]
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
        local enabled = self.db.modules[name]
        if enabled == nil or enabled then
            if module.OnEnable then module:OnEnable() end
        end
    end

    self:Print(self.L["LOADED"]:format(self.version))
end)

-- Expose the namespace globally for debugging (/dump NitexUI)
_G[addonName] = ns
