--[[
    Akimbo: Dual Monitor Workstation Addon
    UI/Wizard.lua: Interactive Multi-Monitor Setup & Calibration Wizard
--]]

local _, Akimbo = ...

local Wizard = {}
Akimbo.Wizard = Wizard

local wizardFrame
local seamGuideLine

-- ============================================================================
-- Monitor Topology Detection
-- ============================================================================
function Wizard:DetectTopology()
    local physW, physH
    if GetPhysicalScreenSize then
        physW, physH = GetPhysicalScreenSize()
    end

    if not physW or physW <= 0 then
        local resStr = GetCVar("gxWindowedResolution") or GetCVar("gxFullscreenResolution") or "0x0"
        local w, h = strsplit("x", resStr)
        physW = tonumber(w) or GetScreenWidth()
        physH = tonumber(h) or GetScreenHeight()
    end

    local ar = physW / math.max(physH, 1)

    local info = {
        physWidth = physW,
        physHeight = physH,
        aspectRatio = ar,
        isSpanned = false,
        recommendedPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT",
        recommendedDeckRatio = 0.36,
        description = "Single Display / Standard Resolution",
    }

    if physW >= 3500 and physH >= 2000 and ar < 2.0 then
        -- Signature: Vertical Portrait (1440x2560) + Landscape (2560x1440) = 4000x2560 (AR ~1.56)
        info.isSpanned = true
        info.recommendedPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT"
        info.recommendedDeckRatio = 0.36
        info.description = string.format("Possible mixed display span (%dx%d); confirm the seam", physW, physH)

    elseif ar >= 3.0 then
        -- Signature: Dual Side-by-Side Matching Displays (32:9 equivalent, e.g. 3840x1080, 5120x1440)
        info.isSpanned = true
        info.recommendedPreset = "LANDSCAPE_DUAL"
        info.recommendedDeckRatio = 0.50
        info.description = string.format("Possible dual landscape span (%dx%d); confirm the seam", physW, physH)

    elseif ar >= 2.0 then
        -- Ultrawide or partial span
        info.isSpanned = true
        info.recommendedPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT"
        info.recommendedDeckRatio = 0.36
        info.description = string.format("Wide window (%dx%d); confirm display layout", physW, physH)

    else
        -- Standard single monitor window
        info.isSpanned = false
        info.recommendedPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT"
        info.recommendedDeckRatio = 0.36
        info.description = string.format("Standard window (%dx%d); check window spanning.", physW, physH)
    end

    return info
end

-- ============================================================================
-- Visual Seam Alignment Guide Line
-- ============================================================================
local function ShowSeamGuide(deckRatio)
    if not seamGuideLine then
        seamGuideLine = CreateFrame("Frame", "AkimboSeamGuideLine", UIParent)
        seamGuideLine:SetFrameStrata("TOOLTIP")
        seamGuideLine:SetWidth(4)

        local tex = seamGuideLine:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints()
        tex:SetColorTexture(1.0, 0.2, 0.2, 0.85)
        seamGuideLine.texture = tex

        local label = seamGuideLine:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("CENTER", seamGuideLine, "CENTER", 0, 0)
        label:SetText("<< SEAM >>")
        label:SetTextColor(1, 1, 1, 1)
    end

    local screenW = UIParent:GetWidth()
    local x = screenW * deckRatio
    if Akimbo.db.primaryPosition == "LEFT" then x = screenW - x end
    seamGuideLine:ClearAllPoints()
    seamGuideLine:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x - 2, UIParent:GetHeight())
    seamGuideLine:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x - 2, 0)
    seamGuideLine:Show()
end

local function HideSeamGuide()
    if seamGuideLine then
        seamGuideLine:Hide()
    end
end

-- ============================================================================
-- Interactive Setup Wizard Modal
-- ============================================================================
function Wizard:CreateFrame()
    if wizardFrame then return wizardFrame end

    local f = CreateFrame("Frame", "AkimboWizardFrame", UIParent, "BackdropTemplate")
    f:SetSize(620, 640)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)

    Akimbo.Themes:ApplyBackdrop(f, "OBSIDIAN", 0.98)
    f.header = Akimbo.Themes:CreateBayHeader(f, "AKIMBO DISPLAY CALIBRATION")

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
    closeBtn:SetScript("OnClick", function()
        HideSeamGuide()
        f:Hide()
    end)

    -- Status & Detection Banner
    local banner = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    banner:SetPoint("TOPLEFT", 24, -40)
    banner:SetText("|cff00ccffWindow Size & Suggested Layout|r")
    f.banner = banner

    local desc = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", banner, "BOTTOMLEFT", 0, -6)
    desc:SetWidth(570)
    desc:SetJustifyH("LEFT")
    f.desc = desc

    -- Section 1: Orientation Presets
    local orientLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    orientLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -18)
    orientLabel:SetText("1. Select Your Display Orientation:")

    local btnPl = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnPl:SetSize(270, 32)
    btnPl:SetPoint("TOPLEFT", orientLabel, "BOTTOMLEFT", 0, -8)
    btnPl:SetText("Portrait (Left) + Game (Right)")

    local btnPr = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnPr:SetSize(270, 32)
    btnPr:SetPoint("LEFT", btnPl, "RIGHT", 16, 0)
    btnPr:SetText("Game (Left) + Portrait (Right)")

    local btnDual = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnDual:SetSize(270, 32)
    btnDual:SetPoint("TOPLEFT", btnPl, "BOTTOMLEFT", 0, -8)
    btnDual:SetText("Dual Side-by-Side (50/50)")

    -- Section 2: 3D Game Aspect Ratio
    local arLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    arLabel:SetPoint("TOPLEFT", btnDual, "BOTTOMLEFT", 0, -18)
    arLabel:SetText("2. 3D Game Viewport Aspect Ratio:")

    local btn169 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn169:SetSize(175, 28)
    btn169:SetPoint("TOPLEFT", arLabel, "BOTTOMLEFT", 0, -8)
    btn169:SetText("16:9 Widescreen")

    local btn219 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btn219:SetSize(175, 28)
    btn219:SetPoint("LEFT", btn169, "RIGHT", 16, 0)
    btn219:SetText("21:9 Ultrawide")

    local btnFill = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnFill:SetSize(175, 28)
    btnFill:SetPoint("LEFT", btn219, "RIGHT", 16, 0)
    btnFill:SetText("Use Height Setting")

    -- Section 3: Live Seam Alignment & Deck Ratio Slider
    local seamLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    seamLabel:SetPoint("TOPLEFT", btn169, "BOTTOMLEFT", 0, -18)
    seamLabel:SetText("|cffffcc003. Bezel Seam Calibration|r (Drag until RED line touches monitor frame):")

    local seamSlider = CreateFrame("Slider", nil, f, "BackdropTemplate")
    seamSlider:SetOrientation("HORIZONTAL")
    seamSlider:SetSize(340, 16)
    seamSlider:SetPoint("TOPLEFT", seamLabel, "BOTTOMLEFT", 0, -12)
    seamSlider:SetMinMaxValues(0.15, 0.80)
    seamSlider:SetValueStep(0.005)
    seamSlider:SetObeyStepOnDrag(true)
    seamSlider:EnableMouse(true)
    seamSlider:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    seamSlider:SetBackdropColor(0.12, 0.14, 0.18, 0.95)
    seamSlider:SetBackdropBorderColor(0.25, 0.3, 0.38, 1.0)

    local thumb = seamSlider:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(1.0, 0.3, 0.3, 1.0)
    thumb:SetSize(14, 18)
    seamSlider:SetThumbTexture(thumb)

    local btnMinus = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnMinus:SetSize(46, 22)
    btnMinus:SetPoint("LEFT", seamSlider, "RIGHT", 10, 0)
    btnMinus:SetText("- 1%")

    local btnPlus = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnPlus:SetSize(46, 22)
    btnPlus:SetPoint("LEFT", btnMinus, "RIGHT", 4, 0)
    btnPlus:SetText("+ 1%")

    local seamValText = seamSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    seamValText:SetPoint("LEFT", btnPlus, "RIGHT", 10, 0)

    seamSlider:SetScript("OnValueChanged", function(self, val)
        val = math.floor((val / 0.005) + 0.5) * 0.005
        Akimbo.db.deckWidthRatio = val
        seamValText:SetText(string.format("Seam: %.1f%%", val * 100))
        ShowSeamGuide(val)
        Akimbo:ApplyFullLayout()
    end)

    btnMinus:SetScript("OnClick", function()
        local current = seamSlider:GetValue() or 0.36
        local nextVal = math.max(0.15, current - 0.01)
        seamSlider:SetValue(nextVal)
    end)

    btnPlus:SetScript("OnClick", function()
        local current = seamSlider:GetValue() or 0.36
        local nextVal = math.min(0.80, current + 0.01)
        seamSlider:SetValue(nextVal)
    end)

    -- Quick Seam Presets
    local btnSeam36 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnSeam36:SetSize(175, 24)
    btnSeam36:SetPoint("TOPLEFT", seamSlider, "BOTTOMLEFT", 0, -8)
    btnSeam36:SetText("1440 / 4000 (36%)")
    btnSeam36:SetScript("OnClick", function() seamSlider:SetValue(0.36) end)

    local btnSeam50 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnSeam50:SetSize(175, 24)
    btnSeam50:SetPoint("LEFT", btnSeam36, "RIGHT", 16, 0)
    btnSeam50:SetText("Equal Split (50%)")
    btnSeam50:SetScript("OnClick", function() seamSlider:SetValue(0.50) end)

    local btnSeam55 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnSeam55:SetSize(175, 24)
    btnSeam55:SetPoint("LEFT", btnSeam50, "RIGHT", 16, 0)
    btnSeam55:SetText("Custom Split (55%)")
    btnSeam55:SetScript("OnClick", function() seamSlider:SetValue(0.55) end)

    -- Section 4: HUD Scale Presets
    local hudLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    hudLabel:SetPoint("TOPLEFT", btnSeam36, "BOTTOMLEFT", 0, -16)
    hudLabel:SetText("4. Global UI Size Relative to Game View:")

    local btnHud56 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnHud56:SetSize(175, 26)
    btnHud56:SetPoint("TOPLEFT", hudLabel, "BOTTOMLEFT", 0, -8)
    btnHud56:SetText("Compact (56%)")

    local btnHud65 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnHud65:SetSize(175, 26)
    btnHud65:SetPoint("LEFT", btnHud56, "RIGHT", 16, 0)
    btnHud65:SetText("Balanced (65%)")

    local btnHud70 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnHud70:SetSize(175, 26)
    btnHud70:SetPoint("LEFT", btnHud65, "RIGHT", 16, 0)
    btnHud70:SetText("Standard (70%)")

    local bottomControl = Akimbo.Options:CreateBottomControl(f)
    bottomControl:SetPoint("TOPLEFT", btnHud56, "BOTTOMLEFT", 0, -16)

    -- Action Buttons at Bottom
    local finishBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    finishBtn:SetSize(220, 36)
    finishBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 16)
    finishBtn:SetText("|cff00ff00Save & Complete Setup|r")

    finishBtn:SetScript("OnClick", function()
        Akimbo.db.firstRunComplete = true
        HideSeamGuide()
        Akimbo:ApplyFullLayout()
        f:Hide()
        Akimbo:Print("Configuration saved! Welcome to Akimbo.")
    end)

    -- Button Click Handlers
    local function UpdateButtonHighlights()
        local p = Akimbo.db.layoutPreset
        local pos = Akimbo.db.primaryPosition
        local ar = Akimbo.db.aspectRatioMode
        local hud = Akimbo.db.hudScale or 0.70

        btnPl:SetEnabled(not (p == "PORTRAIT_LEFT_LANDSCAPE_RIGHT" and pos == "RIGHT"))
        btnPr:SetEnabled(not (p == "PORTRAIT_LEFT_LANDSCAPE_RIGHT" and pos == "LEFT"))
        btnDual:SetEnabled(not (p == "LANDSCAPE_DUAL"))

        btn169:SetEnabled(ar ~= "16_9")
        btn219:SetEnabled(ar ~= "21_9")
        btnFill:SetEnabled(ar ~= "FILL")

        btnHud56:SetEnabled(math.abs(hud - 0.56) > 0.03)
        btnHud65:SetEnabled(math.abs(hud - 0.65) > 0.03)
        btnHud70:SetEnabled(math.abs(hud - 0.70) > 0.03)
    end

    btnPl:SetScript("OnClick", function()
        Akimbo.db.layoutPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT"
        Akimbo.db.primaryPosition = "RIGHT"
        local current = Akimbo.db.deckWidthRatio or 0.36
        seamSlider:SetValue(current)
        UpdateButtonHighlights()
        Akimbo:ApplyFullLayout()
    end)

    btnPr:SetScript("OnClick", function()
        Akimbo.db.layoutPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT"
        Akimbo.db.primaryPosition = "LEFT"
        local current = Akimbo.db.deckWidthRatio or 0.36
        seamSlider:SetValue(current)
        UpdateButtonHighlights()
        Akimbo:ApplyFullLayout()
    end)

    btnDual:SetScript("OnClick", function()
        Akimbo.db.layoutPreset = "LANDSCAPE_DUAL"
        Akimbo.db.primaryPosition = "LEFT"
        Akimbo.db.deckWidthRatio = 0.50
        seamSlider:SetValue(0.50)
        UpdateButtonHighlights()
        Akimbo:ApplyFullLayout()
    end)

    btn169:SetScript("OnClick", function()
        Akimbo.db.aspectRatioMode = "16_9"
        UpdateButtonHighlights()
        Akimbo:ApplyFullLayout()
    end)

    btn219:SetScript("OnClick", function()
        Akimbo.db.aspectRatioMode = "21_9"
        UpdateButtonHighlights()
        Akimbo:ApplyFullLayout()
    end)

    btnFill:SetScript("OnClick", function()
        Akimbo.db.aspectRatioMode = "FILL"
        UpdateButtonHighlights()
        Akimbo:ApplyFullLayout()
    end)

    btnHud56:SetScript("OnClick", function()
        Akimbo.db.hudScale = 0.56
        UpdateButtonHighlights()
        Akimbo:ApplyFullLayout()
    end)

    btnHud65:SetScript("OnClick", function()
        Akimbo.db.hudScale = 0.65
        UpdateButtonHighlights()
        Akimbo:ApplyFullLayout()
    end)

    btnHud70:SetScript("OnClick", function()
        Akimbo.db.hudScale = 0.70
        UpdateButtonHighlights()
        Akimbo:ApplyFullLayout()
    end)

    f.UpdateButtonHighlights = UpdateButtonHighlights
    f.seamSlider = seamSlider
    f.seamValText = seamValText

    wizardFrame = f
    return f
end

function Wizard:Open()
    local f = self:CreateFrame()
    local info = self:DetectTopology()

    f.desc:SetText(string.format("%s\n|cffffcc00Physical Window Size:|r %dx%d  |cffffcc00Aspect Ratio:|r %.2f:1",
        info.description, info.physWidth, info.physHeight, info.aspectRatio))

    local currentRatio = Akimbo.db.deckWidthRatio or info.recommendedDeckRatio or 0.36
    f.seamSlider:SetValue(currentRatio)
    f.seamValText:SetText(string.format("Seam: %.1f%%", currentRatio * 100))

    f:UpdateButtonHighlights()
    ShowSeamGuide(currentRatio)
    f:Show()
end

function Wizard:Close()
    HideSeamGuide()
    if wizardFrame then wizardFrame:Hide() end
end

function Akimbo:OpenWizard()
    Wizard:Open()
end
