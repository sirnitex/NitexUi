-- NitexUI: Utils

local _, ns = ...

local PREFIX = "|cff" .. ns.Theme.accentHex .. "Nitex|rUI: "

function ns:Print(...)
    print(PREFIX .. string.join(" ", tostringall(...)))
end

function ns:Debug(...)
    if self.db and self.db.debug then
        print("|cffff8800[NitexUI debug]|r " .. string.join(" ", tostringall(...)))
    end
end

--- Recursively copy missing keys from `defaults` into `target`.
function ns.CopyDefaults(target, defaults)
    if type(target) ~= "table" then target = {} end
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            target[k] = ns.CopyDefaults(target[k], v)
        elseif target[k] == nil then
            target[k] = v
        end
    end
    return target
end
