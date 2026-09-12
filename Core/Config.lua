--[[
    Akimbo: Dual Monitor Workstation Addon
    Core/Config.lua: SavedVariables management and defaults
--]]

local _, Akimbo = ...

local defaultSettings = {
    enabled = true,
    layoutPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT", -- "PORTRAIT_LEFT_LANDSCAPE_RIGHT", "LANDSCAPE_DUAL", "CUSTOM"
    primaryPosition = "RIGHT",      -- "LEFT" or "RIGHT" (In Portrait Left, Primary 3D Game is on the RIGHT!)
    primaryWidthMode = "AUTO",      -- "AUTO", "CUSTOM"
    customPrimaryWidth = 2560,      -- 16:9 width
    deckWidthRatio = 0.36,          -- 1440 / 4000; saved manual calibration takes precedence
    gameHeightRatio = 0.5625,       -- 1440 / 2560 for the default portrait/landscape canvas
    gameBottomPixels = 0,          -- Primary monitor bottom inset within the spanned client
    bezelGap = 0,                   -- Pixels gap between monitors
    theme = "CLASSIC",              -- "CLASSIC", "BLIZZARD_SLATE", "OBSIDIAN", "PITCH_BLACK"
    trimColor = "GOLD",             -- "GOLD", "SILVER", "BRONZE", "EMERALD", "CRIMSON", "CUSTOM"
    customTrimColor = { r = 1.0, g = 0.82, b = 0.0 }, -- User-selected custom accent
    canvasColor = "CHARCOAL",       -- "CHARCOAL", "WARM_NIGHT", "PURE_BLACK", "DEEP_BLUE", "CUSTOM"
    customCanvasColor = { r = 0.12, g = 0.22, b = 0.35 }, -- User-selected custom workspace background
    canvasAlpha = 0.95,             -- Alpha of the secondary monitor background
    workspaceMapScale = "AUTO",     -- "AUTO" (fits deck width) or number (0.50 to 1.50)
    mainMapScale = 1.0,             -- Map scale when placed on the main gaming monitor
    debugMode = false,
    forceDualOnSingle = false,      -- For testing
    hudScale = 0.70,                -- Global UI size multiplier relative to the game viewport (default 70%)
    chatPosition = "GAME",          -- "GAME" (bottom-left of 3D curved monitor) or "DECK" (bottom bay of vertical monitor)
    dockChat = true,                -- Enable managed chat positioning

    -- Feature toggles
    seamRedirect = true,            -- Redirect popups and errors away from center bezel
    preventMapCloseOnMove = true,   -- Keep WorldMap open while running/walking
    independentWorkspacePanels = true, -- Panels placed on the secondary workspace stay open independently
    persistentWorkspacePanels = true,  -- Keep workspace panels and maps open when pressing Escape
    savedWorkspacePositions = {},   -- Persisted coordinates for frames placed on the secondary workspace
    savedMainPositions = {},        -- Persisted coordinates for movable frames on the main screen
}

local function CopyDefaults(src, dst)
    if type(src) ~= "table" then return {} end
    if type(dst) ~= "table" then dst = {} end
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

function Akimbo:InitializeConfig()
    if type(AkimboDB) ~= "table" then
        AkimboDB = {}
    end
    -- Auto-migrate to vertical portrait setup if preset is unset or old default
    if not AkimboDB.layoutPreset or AkimboDB.layoutPreset == "AUTO" then
        AkimboDB.layoutPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT"
        AkimboDB.primaryPosition = AkimboDB.primaryPosition or "RIGHT"
    end
    -- Fill missing settings without overwriting a player's calibration.
    -- Legacy uiScale values are retained but no longer used or created.
    if not AkimboDB.chatPosition then
        AkimboDB.chatPosition = "GAME"
    end
    -- Purge legacy panelPositions from earlier Astra docking modules
    if AkimboDB.panelPositions then
        AkimboDB.panelPositions = nil
    end
    CopyDefaults(defaultSettings, AkimboDB)
    Akimbo.db = AkimboDB
end

function Akimbo:ResetConfig()
    AkimboDB = CopyDefaults(defaultSettings, {})
    Akimbo.db = AkimboDB
    Akimbo:ApplyFullLayout()
    Akimbo:Print("Settings reset to defaults.")
end
