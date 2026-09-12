--[[
    Akimbo: Dual Monitor Workstation Addon
    UI/Themes.lua: Authentic Classic WoW UI styling, theme presets, and color palettes
--]]

local _, Akimbo = ...

local Themes = {}
Akimbo.Themes = Themes

local THEME_DATA = {
    CLASSIC = {
        name = "Classic Warcraft",
        description = "Authentic WoW dialog style with gold trim and stone backdrop",
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
        bgColor = { 0.08, 0.08, 0.08, 0.96 },
        borderColor = { 1.0, 0.82, 0.0, 1.0 },       -- Blizzard Gold
        headerColor = { 0.18, 0.14, 0.09, 1.0 },      -- Warm Dark Bronze
        headerTextColor = { 1.0, 0.82, 0.0, 1.0 },  -- Classic Gold
    },
    BLIZZARD_SLATE = {
        name = "Blizzard Slate",
        description = "Muted charcoal dialog with pewter/silver trim",
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
        bgColor = { 0.07, 0.07, 0.08, 0.96 },
        borderColor = { 0.65, 0.68, 0.72, 1.0 },     -- Pewter Silver
        headerColor = { 0.11, 0.12, 0.14, 1.0 },
        headerTextColor = { 0.95, 0.95, 0.95, 1.0 },
    },
    OBSIDIAN = {
        name = "Obsidian Dark",
        description = "Clean modern dark theme with subtle stone borders",
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
        bgColor = { 0.06, 0.07, 0.08, 0.96 },
        borderColor = { 0.35, 0.36, 0.40, 1.0 },     -- Subtle Slate
        headerColor = { 0.12, 0.13, 0.15, 1.0 },
        headerTextColor = { 1.0, 0.82, 0.0, 1.0 },  -- Classic Gold text
    },
    PITCH_BLACK = {
        name = "Pitch Black (OLED)",
        description = "Pure black for OLED displays",
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
        bgColor = { 0.0, 0.0, 0.0, 1.0 },
        borderColor = { 0.18, 0.18, 0.18, 1.0 },
        headerColor = { 0.05, 0.05, 0.05, 1.0 },
        headerTextColor = { 0.8, 0.8, 0.8, 1.0 },
    },
}

-- Preset color options for trim/accents
local COLOR_PALETTES = {
    GOLD    = { name = "Blizzard Gold", r = 1.0,  g = 0.82, b = 0.0,  a = 1.0 },
    SILVER  = { name = "Pewter Silver", r = 0.72, g = 0.75, b = 0.78, a = 1.0 },
    BRONZE  = { name = "Warm Bronze",  r = 0.85, g = 0.58, b = 0.25, a = 1.0 },
    EMERALD = { name = "Emerald Green",r = 0.22, g = 0.82, b = 0.35, a = 1.0 },
    CRIMSON = { name = "Crimson Red",  r = 0.85, g = 0.22, b = 0.22, a = 1.0 },
}

-- Preset color options for the workspace background
local CANVAS_PALETTES = {
    CHARCOAL   = { name = "Charcoal Slate", r = 0.07, g = 0.08, b = 0.09 },
    WARM_NIGHT = { name = "Warm Night",     r = 0.08, g = 0.07, b = 0.06 },
    PURE_BLACK = { name = "Pitch Black",    r = 0.00, g = 0.00, b = 0.00 },
    DEEP_BLUE  = { name = "Midnight Navy",  r = 0.05, g = 0.06, b = 0.10 },
}

function Themes:GetThemeList()
    return { "CLASSIC", "BLIZZARD_SLATE", "OBSIDIAN", "PITCH_BLACK" }
end

function Themes:GetColorPalettes()
    return COLOR_PALETTES
end

function Themes:GetCanvasPalettes()
    return CANVAS_PALETTES
end

function Themes:GetThemeInfo(themeKey)
    return THEME_DATA[themeKey] or THEME_DATA.CLASSIC
end

function Themes:ApplyBackdrop(frame, themeKey, customAlpha)
    if not frame then return end
    local theme = self:GetThemeInfo(themeKey or (Akimbo.db and Akimbo.db.theme))
    local alpha = customAlpha or (Akimbo.db and Akimbo.db.canvasAlpha) or 0.95

    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end

    frame:SetBackdrop({
        bgFile = theme.bgFile,
        edgeFile = theme.edgeFile,
        tile = false,
        tileSize = 16,
        edgeSize = theme.edgeSize,
        insets = theme.insets,
    })

    -- Canvas color overrides
    local bg = theme.bgColor
    if frame == AkimboCanvasFrame and Akimbo.db and Akimbo.db.canvasColor and CANVAS_PALETTES[Akimbo.db.canvasColor] then
        local c = CANVAS_PALETTES[Akimbo.db.canvasColor]
        bg = { c.r, c.g, c.b }
    end
    frame:SetBackdropColor(bg[1], bg[2], bg[3], alpha)

    -- Window border color overrides
    local br = theme.borderColor
    if Akimbo.db and Akimbo.db.trimColor and COLOR_PALETTES[Akimbo.db.trimColor] then
        local c = COLOR_PALETTES[Akimbo.db.trimColor]
        br = { c.r, c.g, c.b, c.a }
    end
    frame:SetBackdropBorderColor(br[1], br[2], br[3], br[4] or 1.0)
end

function Themes:CreateBayHeader(parent, titleText)
    local header = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    header:SetHeight(30)
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -6)
    header:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -6)

    header:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", header, "LEFT", 12, 0)
    title:SetText(titleText or "")
    header.title = title

    self:UpdateHeader(header, titleText)
    return header
end

function Themes:UpdateHeader(header, titleText)
    if not header then return end
    local theme = self:GetThemeInfo(Akimbo.db and Akimbo.db.theme)

    local headBg = theme.headerColor
    header:SetBackdropColor(headBg[1], headBg[2], headBg[3], headBg[4] or 0.95)

    local br = theme.borderColor
    if Akimbo.db and Akimbo.db.trimColor and COLOR_PALETTES[Akimbo.db.trimColor] then
        local c = COLOR_PALETTES[Akimbo.db.trimColor]
        br = { c.r, c.g, c.b, c.a or 1.0 }
    end
    header:SetBackdropBorderColor(br[1], br[2], br[3], br[4] or 1.0)

    local textCol = theme.headerTextColor
    if Akimbo.db and Akimbo.db.trimColor and COLOR_PALETTES[Akimbo.db.trimColor] then
        local c = COLOR_PALETTES[Akimbo.db.trimColor]
        textCol = { c.r, c.g, c.b, 1.0 }
    end

    if header.title then
        if titleText then header.title:SetText(titleText) end
        header.title:SetTextColor(textCol[1], textCol[2], textCol[3], textCol[4] or 1.0)
    end
end

function Akimbo:UpdateTheme()
    local themeKey = (Akimbo.db and Akimbo.db.theme) or "CLASSIC"

    -- Update background workspace canvas
    if AkimboCanvasFrame then
        Themes:ApplyBackdrop(AkimboCanvasFrame, themeKey, Akimbo.db and Akimbo.db.canvasAlpha)
    end

    -- Update config dialog if created
    local config = Akimbo.Options and Akimbo.Options.GetConfigFrame and Akimbo.Options:GetConfigFrame()
    if config then
        Themes:ApplyBackdrop(config, themeKey, 0.98)
        if config.header then
            Themes:UpdateHeader(config.header)
        end
        if Akimbo.Options.UpdateCardThemes then
            Akimbo.Options:UpdateCardThemes()
        end
    end
end

function Akimbo:InitializeThemes()
    -- Theme registry ready
end
