local addonName, private = ...
private.L = setmetatable({}, {
    __index = function(t, k)
        local v = tostring(k)
        rawset(t, k, v)
        return v
    end,
})

local L = private.L
L.addonName = "Bank Officer"
