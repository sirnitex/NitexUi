-- NitexUI: Database (SavedVariables) with profiles
--
-- NitexUIDB (account):
--   profiles       = { [name] = { ...all settings... } }
--   defaultProfile = name used by every character that has not picked its own profile
-- NitexUICharDB (per character):
--   profile        = name, or nil = follow the account default
--
-- ns.db always points at the ACTIVE profile table, so modules simply read ns.db.<...>.
-- Switching, copying or resetting a profile reloads the UI so every module restarts cleanly.

local _, ns = ...

local DEFAULT = "Default"

-- Profile defaults. Modules add their own keys (ns.defaults.<module> = {...}) at load time.
ns.defaults = {
    debug = false,
    modules = {},  -- [moduleName] = true when the user turned it on. Missing = off.
}

local function DeepCopy(src)
    local t = {}
    for k, v in next, src do
        t[k] = type(v) == "table" and DeepCopy(v) or v
    end
    return t
end

---------------------------------------------------------------------------
-- Init (ADDON_LOADED)
---------------------------------------------------------------------------
function ns:InitDatabase()
    local root = type(NitexUIDB) == "table" and NitexUIDB or {}

    -- Migration: before profiles existed, all settings lived directly in NitexUIDB.
    if not root.profiles then
        local old = root
        old.profile = nil -- unused leftover key from 0.1
        root = { profiles = { [DEFAULT] = old } }
    end
    if not next(root.profiles) then
        root.profiles[DEFAULT] = {}
    end
    if root.defaultProfile and not root.profiles[root.defaultProfile] then
        root.defaultProfile = nil
    end

    local char = type(NitexUICharDB) == "table" and NitexUICharDB or {}
    if char.profile and not root.profiles[char.profile] then
        char.profile = nil -- the profile was deleted on another character
    end

    NitexUIDB, NitexUICharDB = root, char
    self.root, self.charDB = root, char

    local name = char.profile or self:GetDefaultProfile()
    self.profileName = name
    self.db = ns.CopyDefaults(root.profiles[name], self.defaults)
    root.profiles[name] = self.db
end

---------------------------------------------------------------------------
-- Queries
---------------------------------------------------------------------------
--- The profile used by characters that follow the account default.
function ns:GetDefaultProfile()
    local root = self.root or NitexUIDB
    local name = root.defaultProfile
    if name and root.profiles[name] then return name end
    if root.profiles[DEFAULT] then return DEFAULT end
    return (next(root.profiles))
end

--- Sorted list of profile names.
function ns:GetProfiles()
    local list = {}
    for name in next, self.root.profiles do list[#list + 1] = name end
    table.sort(list)
    return list
end

function ns:ProfileExists(name)
    return self.root.profiles[name] ~= nil
end

--- true when this character follows the account default instead of its own choice.
function ns:FollowsDefaultProfile()
    return self.charDB.profile == nil
end

--- "Name - Realm", or just "Name" if the realm is empty or kept secret by the client.
function ns:GetCharacterName()
    local secret = issecretvalue or function() return false end
    local name = UnitName("player")
    if not name or secret(name) then name = "?" end
    local realm = GetRealmName and GetRealmName()
    if realm and not secret(realm) and realm ~= "" then
        return name .. " - " .. realm
    end
    return name
end

---------------------------------------------------------------------------
-- Changes
-- Anything that changes which settings are active ends in ReloadUI().
---------------------------------------------------------------------------
--- Create a new profile (empty, or a copy of `copyFrom`). Does not switch to it.
function ns:CreateProfile(name, copyFrom)
    if not name or name == "" or self.root.profiles[name] then return false end
    local src = copyFrom and self.root.profiles[copyFrom]
    self.root.profiles[name] = src and DeepCopy(src) or {}
    return true
end

--- Pick the profile for this character. nil = follow the account default.
function ns:SetCharacterProfile(name)
    if name and not self.root.profiles[name] then return end
    self.charDB.profile = name
    ReloadUI()
end

--- Profile every character without its own choice uses (also new characters).
--- Returns true if this changes the active profile here (a reload is then needed).
function ns:SetDefaultProfile(name)
    if not self.root.profiles[name] then return false end
    self.root.defaultProfile = name
    return self:FollowsDefaultProfile() and name ~= self.profileName
end

--- Replace the active profile's settings with a copy of another profile.
function ns:CopyIntoActiveProfile(src)
    local from = self.root.profiles[src]
    if not from or src == self.profileName then return end
    local copy = DeepCopy(from)
    wipe(self.db)
    for k, v in next, copy do self.db[k] = v end
    ReloadUI()
end

--- Delete a profile. The active profile and the last remaining profile cannot be deleted.
function ns:DeleteProfile(name)
    local root = self.root
    if not root.profiles[name] or name == self.profileName then return false end
    root.profiles[name] = nil
    if not next(root.profiles) then root.profiles[DEFAULT] = {} end
    if root.defaultProfile == name then root.defaultProfile = nil end
    return true
end

--- Reset the active profile to defaults.
function ns:ResetProfile()
    wipe(self.db)
    ReloadUI()
end

-- Older name, still used by /nitex reset.
ns.ResetDatabase = ns.ResetProfile
