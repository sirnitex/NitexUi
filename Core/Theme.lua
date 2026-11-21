-- NitexUI: Theme
-- Central colour palette. Accent is the same #33ccff used in chat.

local _, ns = ...

ns.Theme = {
    accentHex    = "33ccff",
    accent       = { 0.20, 0.80, 1.00, 1 },
    accentDim    = { 0.20, 0.80, 1.00, 0.35 },

    bg           = { 0.090, 0.090, 0.100, 0.97 }, -- main window
    header       = { 0.060, 0.060, 0.068, 1 },    -- title bar
    sidebar      = { 0.070, 0.070, 0.078, 1 },    -- navigation
    border       = { 0.180, 0.180, 0.200, 1 },
    element      = { 0.150, 0.150, 0.170, 1 },    -- buttons, toggle tracks
    elementHover = { 0.200, 0.200, 0.225, 1 },

    text         = { 0.92, 0.92, 0.94, 1 },
    textDim      = { 0.58, 0.58, 0.63, 1 },
}
