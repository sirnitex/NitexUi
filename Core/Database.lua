-- NitexUI: Database (SavedVariables)

local _, ns = ...

-- Account-wide defaults (NitexUIDB)
ns.defaults = {
    debug = false,
    modules = {},  -- [moduleName] = true/false
    profile = {},
}

-- Per-character defaults (NitexUICharDB)
ns.charDefaults = {}

function ns:InitDatabase()
    NitexUIDB = ns.CopyDefaults(NitexUIDB, self.defaults)
    NitexUICharDB = ns.CopyDefaults(NitexUICharDB, self.charDefaults)
    self.db = NitexUIDB
    self.charDB = NitexUICharDB
end

function ns:ResetDatabase()
    NitexUIDB = nil
    NitexUICharDB = nil
    self:InitDatabase()
end
