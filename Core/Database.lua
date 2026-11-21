-- NitexUI: Database (SavedVariables) with profiles, ElvUI/AceDB style – native, no libraries.
--
-- NitexUIDB (account-wide):
--   profiles       = { [profileName] = { ...settings... } }
--   profileKeys    = { ["Name - Realm"] = profileName }   -- a character's own choice (like AceDB)
--   defaultProfile = profileName used by every character without its own choice (also new ones)
--
-- ns.db always points at the ACTIVE profile, so modules just read ns.db.<...>.
-- Changing which settings are active (switch, copy, reset, import+switch) reloads the UI so
-- every module restarts cleanly with the new settings.
--
-- Import/export strings: "!NUI1!" .. Base64( Deflate( CBOR{ v = 1, name = ..., data = profile } ) )
-- using Blizzard's native C_EncodingUtil.

local _, ns = ...

local DEFAULT = "Default"
local EXPORT_PREFIX = "!NUI1!"
local MAX_NAME = 32

-- Profile defaults. Modules add their own keys (ns.defaults.<module> = {...}) at load time.
ns.defaults = {
    debug = false,
    modules = {},  -- [moduleName] = true when the user turned it on. Missing = off.
}

local root, charKey

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local issecret = issecretvalue or function() return false end

--- Copy a settings table. Only plain values are kept (used for copies and imports).
local function CopySettings(src, depth)
    depth = depth or 0
    local t = {}
    if depth > 20 then return t end
    for k, v in next, src do
        local kt, vt = type(k), type(v)
        if kt == "string" or kt == "number" then
            if vt == "table" then
                t[k] = CopySettings(v, depth + 1)
            elseif vt == "string" or vt == "number" or vt == "boolean" then
                t[k] = v
            end
        end
    end
    return t
end

local function CleanName(name)
    name = strtrim(tostring(name or ""))
    if #name > MAX_NAME then name = name:sub(1, MAX_NAME) end
    return name
end

local function UniqueName(name)
    if not root.profiles[name] then return name end
    local i = 2
    while root.profiles[name .. " (" .. i .. ")"] do i = i + 1 end
    return name .. " (" .. i .. ")"
end

--- "Name - Realm" (or just "Name" if the realm is empty or secret on this client).
local function MakeCharKey()
    local name = UnitName("player")
    if not name or issecret(name) then name = "?" end
    local realm = GetRealmName and GetRealmName()
    if realm and not issecret(realm) and realm ~= "" then
        return name .. " - " .. realm
    end
    return name
end

---------------------------------------------------------------------------
-- Init (ADDON_LOADED)
---------------------------------------------------------------------------
function ns:InitDatabase()
    root = type(NitexUIDB) == "table" and NitexUIDB or {}

    -- Migration 1: before 0.10 every setting lived directly in NitexUIDB.
    if not root.profiles then
        local old = root
        old.profile = nil
        root = { profiles = { [DEFAULT] = old } }
    end
    root.profileKeys = root.profileKeys or {}
    if not next(root.profiles) then root.profiles[DEFAULT] = {} end
    if root.defaultProfile and not root.profiles[root.defaultProfile] then root.defaultProfile = nil end

    charKey = MakeCharKey()

    -- Migration 2: 0.10 kept the character's choice in NitexUICharDB.profile.
    local char = type(NitexUICharDB) == "table" and NitexUICharDB or {}
    if char.profile then
        if root.profiles[char.profile] then root.profileKeys[charKey] = char.profile end
        char.profile = nil
    end

    local own = root.profileKeys[charKey]
    if own and not root.profiles[own] then
        root.profileKeys[charKey] = nil
        own = nil
    end

    NitexUIDB, NitexUICharDB = root, char
    self.root, self.charDB = root, char

    local name = own or self:GetDefaultProfile()
    self.profileName = name
    self.db = ns.CopyDefaults(root.profiles[name], self.defaults)
    root.profiles[name] = self.db
end

---------------------------------------------------------------------------
-- Queries
---------------------------------------------------------------------------
function ns:GetCharacterKey() return charKey end
function ns:GetCurrentProfile() return self.profileName end
function ns:ProfileExists(name) return root.profiles[name] ~= nil end

--- Profile used by every character without its own choice.
function ns:GetDefaultProfile()
    local name = root.defaultProfile
    if name and root.profiles[name] then return name end
    if root.profiles[DEFAULT] then return DEFAULT end
    return (next(root.profiles))
end

--- true when this character follows the default profile.
function ns:FollowsDefaultProfile()
    return root.profileKeys[charKey] == nil
end

--- Sorted list of profile names.
function ns:GetProfiles()
    local list = {}
    for name in next, root.profiles do list[#list + 1] = name end
    table.sort(list)
    return list
end

---------------------------------------------------------------------------
-- Changes
---------------------------------------------------------------------------
--- Create a profile (empty = defaults, or a copy of `copyFrom`). Returns the final name.
function ns:NewProfile(name, copyFrom)
    name = CleanName(name)
    if name == "" or root.profiles[name] then return nil end
    local src = copyFrom and root.profiles[copyFrom]
    root.profiles[name] = src and CopySettings(src) or {}
    return name
end

--- Use `name` on this character (nil = follow the default profile). Reloads the UI.
function ns:SetProfile(name)
    if name and not root.profiles[name] then return end
    root.profileKeys[charKey] = name
    ReloadUI()
end

--- Set the profile every character without its own choice uses (also new characters).
--- Returns true when this changes the active profile here (a reload is then needed).
function ns:SetDefaultProfile(name)
    if not root.profiles[name] then return false end
    root.defaultProfile = name
    return self:FollowsDefaultProfile() and name ~= self.profileName
end

--- Replace the active profile's settings with a copy of another profile. Reloads the UI.
function ns:CopyProfile(src)
    local from = root.profiles[src]
    if not from or src == self.profileName then return end
    local copy = CopySettings(from)
    wipe(self.db)
    for k, v in next, copy do self.db[k] = v end
    ReloadUI()
end

--- Delete a profile (not the active one). Characters that used it fall back to the default.
function ns:DeleteProfile(name)
    if not root.profiles[name] or name == self.profileName then return false end
    root.profiles[name] = nil
    for key, profile in next, root.profileKeys do
        if profile == name then root.profileKeys[key] = nil end
    end
    if root.defaultProfile == name then root.defaultProfile = nil end
    if not next(root.profiles) then root.profiles[DEFAULT] = {} end
    return true
end

--- Reset the active profile to defaults. Reloads the UI.
function ns:ResetProfile()
    wipe(self.db)
    ReloadUI()
end
ns.ResetDatabase = ns.ResetProfile -- used by /nitex reset

---------------------------------------------------------------------------
-- Import / export (native C_EncodingUtil)
---------------------------------------------------------------------------
local E = C_EncodingUtil

function ns:CanImportExport()
    return E and E.SerializeCBOR and E.CompressString and E.EncodeBase64 and true or false
end

--- Returns the export string for a profile, or nil + error message.
function ns:ExportProfile(name)
    name = name or self.profileName
    local data = root.profiles[name]
    if not data then return nil, "unknown profile" end
    if not self:CanImportExport() then return nil, "C_EncodingUtil is not available" end
    local ok, out = pcall(function()
        local cbor = E.SerializeCBOR({ v = 1, name = name, data = CopySettings(data) })
        return EXPORT_PREFIX .. E.EncodeBase64(E.CompressString(cbor))
    end)
    if not ok then return nil, tostring(out) end
    return out
end

--- Decode an export string. Returns payload { name, data } or nil + error message.
function ns:DecodeProfileString(str)
    if not self:CanImportExport() then return nil, "C_EncodingUtil is not available" end
    str = (str or ""):gsub("%s+", "")
    if str:sub(1, #EXPORT_PREFIX) ~= EXPORT_PREFIX then return nil, "not a NitexUI profile string" end
    local ok, payload = pcall(function()
        local raw = E.DecodeBase64(str:sub(#EXPORT_PREFIX + 1))
        return E.DeserializeCBOR(E.DecompressString(raw))
    end)
    if not ok or type(payload) ~= "table" or payload.v ~= 1 or type(payload.data) ~= "table" then
        return nil, "the string is damaged or incomplete"
    end
    return { name = CleanName(payload.name), data = CopySettings(payload.data) }
end

--- Import an export string as a NEW profile. Returns the new profile name, or nil + error.
function ns:ImportProfile(str, nameOverride)
    local payload, err = self:DecodeProfileString(str)
    if not payload then return nil, err end
    local name = CleanName(nameOverride)
    if name == "" then name = payload.name end
    if name == "" then name = "Imported" end
    name = UniqueName(name)
    root.profiles[name] = payload.data
    return name
end
