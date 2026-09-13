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
    if type(AkimboDB) ~= "table" then AkimboDB = {} end
    if type(AkimboCharDB) ~= "table" then AkimboCharDB = {} end

    -- Migrate legacy flat config to Profiles
    if type(AkimboDB.profiles) ~= "table" then
        AkimboDB.profiles = {}
        AkimboDB.profiles["Default"] = {}
        for k, v in pairs(AkimboDB) do
            if k ~= "profiles" then
                AkimboDB.profiles["Default"][k] = v
                AkimboDB[k] = nil
            end
        end
    end

    local current = AkimboCharDB.activeProfile or "Default"
    if not AkimboDB.profiles[current] then
        AkimboDB.profiles[current] = {}
        AkimboCharDB.activeProfile = current
    end

    Akimbo.db = AkimboDB.profiles[current]

    -- Auto-migrate to vertical portrait setup if preset is unset or old default
    if not Akimbo.db.layoutPreset or Akimbo.db.layoutPreset == "AUTO" then
        Akimbo.db.layoutPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT"
        Akimbo.db.primaryPosition = Akimbo.db.primaryPosition or "RIGHT"
    end
    -- Fill missing settings without overwriting a player's calibration.
    if not Akimbo.db.chatPosition then
        Akimbo.db.chatPosition = "GAME"
    end
    -- Purge legacy panelPositions from earlier Astra docking modules
    if Akimbo.db.panelPositions then
        Akimbo.db.panelPositions = nil
    end

    CopyDefaults(defaultSettings, Akimbo.db)
end

function Akimbo:GetProfiles()
    local list = {}
    if AkimboDB and AkimboDB.profiles then
        for k in pairs(AkimboDB.profiles) do
            table.insert(list, k)
        end
        table.sort(list)
    end
    return list
end

function Akimbo:SetProfile(name)
    if not AkimboDB.profiles[name] then
        AkimboDB.profiles[name] = CopyDefaults(defaultSettings, {})
    end
    AkimboCharDB.activeProfile = name
    Akimbo.db = AkimboDB.profiles[name]
    CopyDefaults(defaultSettings, Akimbo.db)
    
    local L = Akimbo.L or setmetatable({}, { __index = function(t, k) return k end })
    Akimbo:ApplyFullLayout()
    if self.Options and self.Options.RefreshPanel then self.Options:RefreshPanel() end
    Akimbo:Print(L["MSG_PROFILE_LOADED"]:format(name))
end

function Akimbo:CreateProfile(name)
    local L = Akimbo.L or setmetatable({}, { __index = function(t, k) return k end })
    if not name or strtrim(name) == "" then return false, L["PROFILES_WARN_EMPTY_NAME"] end
    name = strtrim(name)
    if AkimboDB.profiles[name] then return false, L["PROFILES_WARN_EXISTS"] end
    
    AkimboDB.profiles[name] = CopyDefaults(defaultSettings, {})
    self:SetProfile(name)
    Akimbo:Print(L["MSG_PROFILE_CREATED"]:format(name))
    return true
end

function Akimbo:DeleteProfile(name)
    local L = Akimbo.L or setmetatable({}, { __index = function(t, k) return k end })
    if name == "Default" then return false, L["PROFILES_WARN_DEFAULT"] end
    if name == AkimboCharDB.activeProfile then return false, L["PROFILES_WARN_DELETE_ACTIVE"] end
    
    AkimboDB.profiles[name] = nil
    if self.Options and self.Options.RefreshPanel then self.Options:RefreshPanel() end
    Akimbo:Print(L["MSG_PROFILE_DELETED"]:format(name))
    return true
end

function Akimbo:CopyProfile(sourceName)
    local L = Akimbo.L or setmetatable({}, { __index = function(t, k) return k end })
    if not AkimboDB.profiles[sourceName] then return false end
    
    local dest = AkimboCharDB.activeProfile
    AkimboDB.profiles[dest] = {}
    for k, v in pairs(AkimboDB.profiles[sourceName]) do
        if type(v) == "table" then
            AkimboDB.profiles[dest][k] = CopyDefaults(v, {})
        else
            AkimboDB.profiles[dest][k] = v
        end
    end
    
    Akimbo.db = AkimboDB.profiles[dest]
    CopyDefaults(defaultSettings, Akimbo.db)
    Akimbo:ApplyFullLayout()
    if self.Options and self.Options.RefreshPanel then self.Options:RefreshPanel() end
    Akimbo:Print(L["MSG_PROFILE_COPIED"]:format(sourceName))
    return true
end

function Akimbo:ResetConfig()
    local L = Akimbo.L or setmetatable({}, { __index = function(t, k) return k end })
    local current = (AkimboCharDB and AkimboCharDB.activeProfile) or "Default"
    AkimboDB.profiles[current] = CopyDefaults(defaultSettings, {})
    Akimbo.db = AkimboDB.profiles[current]
    
    Akimbo:ApplyFullLayout()
    if self.Options and self.Options.RefreshPanel then self.Options:RefreshPanel() end
    Akimbo:Print(L["MSG_PROFILE_RESET"])
end
