--[[
    Akimbo: Dual Monitor Workstation Addon
    UI/Themes.lua: Backdrop styles, panel aesthetics, and themes for Monitor 2 Canvas
--]]

local _, Akimbo = ...

local Themes = {}
Akimbo.Themes = Themes

local THEME_DATA = {
    OBSIDIAN = {
        name = "Obsidian HUD",
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
        bgColor = { 0.07, 0.08, 0.09, 0.95 },
        borderColor = { 0.22, 0.24, 0.28, 1.0 },
        headerColor = { 0.12, 0.14, 0.17, 1.0 },
        headerTextColor = { 0.0, 0.8, 1.0, 1.0 }, -- Cyan
    },
    CLASSIC = {
        name = "Classic Warcraft",
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
        bgColor = { 0.1, 0.1, 0.1, 0.95 },
        borderColor = { 0.7, 0.6, 0.4, 1.0 }, -- Gold/Stone
        headerColor = { 0.15, 0.12, 0.08, 1.0 },
        headerTextColor = { 1.0, 0.82, 0.0, 1.0 }, -- Gold
    },
    PITCH_BLACK = {
        name = "Pitch Black (OLED)",
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
        bgColor = { 0.0, 0.0, 0.0, 1.0 },
        borderColor = { 0.12, 0.12, 0.12, 1.0 },
        headerColor = { 0.04, 0.04, 0.04, 1.0 },
        headerTextColor = { 0.7, 0.7, 0.7, 1.0 },
    },
}

function Themes:GetThemeList()
    return { "OBSIDIAN", "CLASSIC", "PITCH_BLACK" }
end

function Themes:GetThemeInfo(themeKey)
    return THEME_DATA[themeKey] or THEME_DATA.OBSIDIAN
end

function Themes:ApplyBackdrop(frame, themeKey, customAlpha)
    local theme = self:GetThemeInfo(themeKey or (Akimbo.db and Akimbo.db.theme))
    local alpha = customAlpha or (Akimbo.db and Akimbo.db.canvasAlpha) or 0.95

    -- WoW 9.0+ / 1.15+ uses BackdropTemplate or SetBackdrop on standard frames
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

    local bg = theme.bgColor
    frame:SetBackdropColor(bg[1], bg[2], bg[3], alpha)

    local br = theme.borderColor
    frame:SetBackdropBorderColor(br[1], br[2], br[3], br[4])
end

function Themes:CreateBayHeader(parent, titleText)
    local header = CreateFrame("Frame", nil, parent)
    header:SetHeight(22)
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -1, -1)

    local bg = header:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.12, 0.14, 0.17, 1.0)
    header.bg = bg

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("LEFT", header, "LEFT", 8, 0)
    title:SetText(titleText or "")
    title:SetTextColor(0.0, 0.8, 1.0, 1.0)
    header.title = title

    return header
end

function Akimbo:InitializeThemes()
    -- Theme registry ready
end
