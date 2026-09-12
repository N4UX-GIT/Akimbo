--[[
    Akimbo: Dual Monitor Workstation Addon
    UI/Wizard.lua: Visual 1-Click Auto-Configuration Wizard & Display Calibration
    Provides an authentic Classic WoW dialog for 1-click display setup and physical seam calibration.
--]]

local _, Akimbo = ...

local Wizard = {}
Akimbo.Wizard = Wizard

local wizardFrame = nil

function Wizard:DetectTopology()
    if Akimbo.Options and Akimbo.Options.DetectTopology then
        return Akimbo.Options:DetectTopology()
    end
    return {
        physWidth = 1920,
        physHeight = 1080,
        aspectRatio = 16 / 9,
        isSpanned = false,
        recommendedPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT",
        recommendedDeckRatio = 0.36,
        recommendedPosition = "RIGHT",
        recommendedAR = "16_9",
        description = "Standard Display",
    }
end

local function CreateWizardCard(parent, titleText, yOffset, height)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetSize(608, height)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, yOffset)

    card:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    local themeKey = (Akimbo.db and Akimbo.db.theme) or "CLASSIC"
    if themeKey == "CLASSIC" then
        card:SetBackdropColor(1.0, 1.0, 1.0, 0.85)
        card:SetBackdropBorderColor(0.55, 0.50, 0.35, 0.85)
    else
        card:SetBackdropColor(0.04, 0.04, 0.05, 0.75)
        card:SetBackdropBorderColor(0.40, 0.40, 0.45, 0.85)
    end

    local title = card:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -8)
    title:SetText(titleText)
    card.title = title

    return card
end

function Wizard:CreateFrame()
    if wizardFrame then return wizardFrame end
    if not CreateFrame then return nil end

    local f = CreateFrame("Frame", "AkimboSetupWizardFrame", UIParent, "BackdropTemplate")
    f:SetSize(640, 520)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    if tinsert and UISpecialFrames then
        tinsert(UISpecialFrames, "AkimboSetupWizardFrame")
    end

    if Akimbo.Themes and Akimbo.Themes.ApplyBackdrop then
        Akimbo.Themes:ApplyBackdrop(f, (Akimbo.db and Akimbo.db.theme) or "CLASSIC", 0.98)
    end
    if Akimbo.Themes and Akimbo.Themes.CreateBayHeader then
        f.header = Akimbo.Themes:CreateBayHeader(f, "AKIMBO AUTO-CONFIGURATION WIZARD")
    end

    local closeBtn = CreateFrame("Button", nil, f.header or f, "UIPanelCloseButton")
    closeBtn:SetSize(28, 28)
    if f.header then
        closeBtn:SetPoint("RIGHT", f.header, "RIGHT", -2, 0)
    else
        closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    end
    closeBtn:SetScript("OnClick", function()
        Wizard:Close()
    end)

    f:SetScript("OnHide", function()
        if Akimbo.Options and Akimbo.Options.HideSeamGuide then
            Akimbo.Options:HideSeamGuide()
        end
    end)

    -- ========================================================================
    -- CARD 1: DISPLAY TOPOLOGY & 1-CLICK AUTO-SETUP
    -- ========================================================================
    local card1 = CreateWizardCard(f, "1. Display Topology & 1-Click Auto-Setup", -38, 122)

    local logoIcon = card1:CreateTexture(nil, "ARTWORK")
    local textLeft = 12
    if logoIcon and logoIcon.SetSize and logoIcon.SetPoint and logoIcon.SetTexture then
        logoIcon:SetSize(40, 40)
        logoIcon:SetPoint("TOPLEFT", 12, -22)
        logoIcon:SetTexture("Interface\\AddOns\\Akimbo\\Media\\akimbo-logo")
        card1.logoIcon = logoIcon
        textLeft = 60
    end

    local topoText = card1:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    topoText:SetPoint("TOPLEFT", textLeft, -24)
    topoText:SetPoint("TOPRIGHT", -12, -24)
    topoText:SetJustifyH("LEFT")
    f.topoText = topoText

    local recomText = card1:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    recomText:SetPoint("TOPLEFT", textLeft, -42)
    recomText:SetPoint("TOPRIGHT", -12, -42)
    recomText:SetJustifyH("LEFT")
    f.recomText = recomText

    local autoBtn = CreateFrame("Button", nil, card1, "UIPanelButtonTemplate")
    autoBtn:SetSize(584, 30)
    autoBtn:SetPoint("TOPLEFT", 12, -60)
    autoBtn:SetText("|cff00ff001-Click Auto-Configure & Apply (Recommended)|r")
    f.autoBtn = autoBtn

    local statusText = card1:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    statusText:SetPoint("TOPLEFT", 12, -96)
    statusText:SetPoint("TOPRIGHT", -12, -96)
    statusText:SetJustifyH("CENTER")
    statusText:SetText("Click above to automatically detect resolution and configure seam, orientation, and viewport.")
    f.statusText = statusText

    autoBtn:SetScript("OnClick", function()
        if Akimbo.Options and Akimbo.Options.AutoConfigure then
            local info = Akimbo.Options:AutoConfigure(false)
            f:UpdateState()
            statusText:SetText(string.format("|cff00ff00[Applied]|r Setup automatically configured for %s", info.description))
        end
    end)

    -- ========================================================================
    -- CARD 2: MONITOR ORIENTATION & 3D VIEWPORT
    -- ========================================================================
    local card2 = CreateWizardCard(f, "2. Monitor Orientation & 3D Viewport", -166, 125)

    local orientLabel = card2:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    orientLabel:SetPoint("TOPLEFT", 12, -26)
    orientLabel:SetText("Monitor Layout Preset:")

    local btnPl = CreateFrame("Button", nil, card2, "UIPanelButtonTemplate")
    btnPl:SetSize(188, 24)
    btnPl:SetPoint("TOPLEFT", 12, -44)
    btnPl:SetText("Portrait Left + Game Right")

    local btnPr = CreateFrame("Button", nil, card2, "UIPanelButtonTemplate")
    btnPr:SetSize(188, 24)
    btnPr:SetPoint("LEFT", btnPl, "RIGHT", 10, 0)
    btnPr:SetText("Game Left + Portrait Right")

    local btnDual = CreateFrame("Button", nil, card2, "UIPanelButtonTemplate")
    btnDual:SetSize(188, 24)
    btnDual:SetPoint("LEFT", btnPr, "RIGHT", 10, 0)
    btnDual:SetText("Dual Landscape (50/50)")

    local arLabel = card2:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    arLabel:SetPoint("TOPLEFT", 12, -74)
    arLabel:SetText("3D Game Viewport Aspect Ratio:")

    local btn169 = CreateFrame("Button", nil, card2, "UIPanelButtonTemplate")
    btn169:SetSize(188, 24)
    btn169:SetPoint("TOPLEFT", 12, -92)
    btn169:SetText("16:9 Standard Widescreen")

    local btn219 = CreateFrame("Button", nil, card2, "UIPanelButtonTemplate")
    btn219:SetSize(188, 24)
    btn219:SetPoint("LEFT", btn169, "RIGHT", 10, 0)
    btn219:SetText("21:9 Ultrawide")

    local btnFill = CreateFrame("Button", nil, card2, "UIPanelButtonTemplate")
    btnFill:SetSize(188, 24)
    btnFill:SetPoint("LEFT", btn219, "RIGHT", 10, 0)
    btnFill:SetText("Fit Window Height (Fill)")

    btnPl:SetScript("OnClick", function()
        Akimbo.db.layoutPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT"
        Akimbo.db.primaryPosition = "RIGHT"
        f:UpdateState()
        Akimbo:ApplyFullLayout()
    end)

    btnPr:SetScript("OnClick", function()
        Akimbo.db.layoutPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT"
        Akimbo.db.primaryPosition = "LEFT"
        f:UpdateState()
        Akimbo:ApplyFullLayout()
    end)

    btnDual:SetScript("OnClick", function()
        Akimbo.db.layoutPreset = "LANDSCAPE_DUAL"
        Akimbo.db.primaryPosition = "LEFT"
        Akimbo.db.deckWidthRatio = 0.50
        f:UpdateState()
        Akimbo:ApplyFullLayout()
    end)

    btn169:SetScript("OnClick", function()
        Akimbo.db.aspectRatioMode = "16_9"
        f:UpdateState()
        Akimbo:ApplyFullLayout()
    end)

    btn219:SetScript("OnClick", function()
        Akimbo.db.aspectRatioMode = "21_9"
        f:UpdateState()
        Akimbo:ApplyFullLayout()
    end)

    btnFill:SetScript("OnClick", function()
        Akimbo.db.aspectRatioMode = "FILL"
        f:UpdateState()
        Akimbo:ApplyFullLayout()
    end)

    -- ========================================================================
    -- CARD 3: BEZEL SEAM ALIGNMENT & LASER GUIDE
    -- ========================================================================
    local card3 = CreateWizardCard(f, "3. Physical Monitor Seam Alignment & Calibration", -299, 160)

    local seamHelp = card3:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    seamHelp:SetPoint("TOPLEFT", 12, -26)
    seamHelp:SetPoint("TOPRIGHT", -12, -26)
    seamHelp:SetJustifyH("LEFT")
    seamHelp:SetText("Align the red laser line with the physical bezel dividing your two monitors:")

    -- Seam Slider
    local seamSlider = CreateFrame("Slider", nil, card3, "BackdropTemplate")
    seamSlider:SetOrientation("HORIZONTAL")
    seamSlider:SetSize(280, 16)
    seamSlider:SetPoint("TOPLEFT", 12, -48)
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
    seamSlider:SetBackdropColor(0.08, 0.08, 0.09, 0.95)
    seamSlider:SetBackdropBorderColor(0.55, 0.48, 0.32, 0.9)

    local thumb = seamSlider:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(1.0, 0.82, 0.0, 1.0)
    thumb:SetSize(12, 16)
    seamSlider:SetThumbTexture(thumb)

    local seamValText = seamSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    seamValText:SetPoint("BOTTOMRIGHT", seamSlider, "TOPRIGHT", 0, 4)

    local seamTitle = seamSlider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    seamTitle:SetPoint("BOTTOMLEFT", seamSlider, "TOPLEFT", 0, 4)
    seamTitle:SetText("Bezel Seam Width:")

    local btnMinus = CreateFrame("Button", nil, card3, "UIPanelButtonTemplate")
    btnMinus:SetSize(46, 22)
    btnMinus:SetPoint("LEFT", seamSlider, "RIGHT", 10, 0)
    btnMinus:SetText("- 1%")

    local btnPlus = CreateFrame("Button", nil, card3, "UIPanelButtonTemplate")
    btnPlus:SetSize(46, 22)
    btnPlus:SetPoint("LEFT", btnMinus, "RIGHT", 4, 0)
    btnPlus:SetText("+ 1%")

    local btnLaser = CreateFrame("Button", nil, card3, "UIPanelButtonTemplate")
    btnLaser:SetSize(130, 22)
    btnLaser:SetPoint("LEFT", btnPlus, "RIGHT", 10, 0)
    btnLaser:SetText("Toggle Laser Guide")

    seamSlider:SetScript("OnValueChanged", function(self, val)
        val = math.floor((val / 0.005) + 0.5) * 0.005
        Akimbo.db.deckWidthRatio = val
        seamValText:SetText(string.format("Seam: %.1f%%", val * 100))
        if Akimbo.Options and Akimbo.Options.ShowSeamGuide then
            Akimbo.Options:ShowSeamGuide(val)
        end
        Akimbo:ApplyFullLayout()
        f:UpdateLaserButton()
    end)

    btnMinus:SetScript("OnClick", function()
        local current = seamSlider:GetValue() or 0.36
        seamSlider:SetValue(math.max(0.15, current - 0.01))
    end)

    btnPlus:SetScript("OnClick", function()
        local current = seamSlider:GetValue() or 0.36
        seamSlider:SetValue(math.min(0.80, current + 0.01))
    end)

    btnLaser:SetScript("OnClick", function()
        if Akimbo.Options then
            if Akimbo.Options:IsSeamGuideShown() then
                Akimbo.Options:HideSeamGuide()
            else
                Akimbo.Options:ShowSeamGuide(Akimbo.db.deckWidthRatio)
            end
            f:UpdateLaserButton()
        end
    end)

    -- Quick Seam Presets
    local btnSeam36 = CreateFrame("Button", nil, card3, "UIPanelButtonTemplate")
    btnSeam36:SetSize(188, 22)
    btnSeam36:SetPoint("TOPLEFT", seamSlider, "BOTTOMLEFT", 0, -10)
    btnSeam36:SetText("1440/4000 Seam (36%)")
    btnSeam36:SetScript("OnClick", function() seamSlider:SetValue(0.36) end)

    local btnSeam50 = CreateFrame("Button", nil, card3, "UIPanelButtonTemplate")
    btnSeam50:SetSize(188, 22)
    btnSeam50:SetPoint("LEFT", btnSeam36, "RIGHT", 10, 0)
    btnSeam50:SetText("Equal Split (50%)")
    btnSeam50:SetScript("OnClick", function() seamSlider:SetValue(0.50) end)

    local btnSeam55 = CreateFrame("Button", nil, card3, "UIPanelButtonTemplate")
    btnSeam55:SetSize(188, 22)
    btnSeam55:SetPoint("LEFT", btnSeam50, "RIGHT", 10, 0)
    btnSeam55:SetText("Custom Split (55%)")
    btnSeam55:SetScript("OnClick", function() seamSlider:SetValue(0.55) end)

    -- HUD Scale Presets
    local hudLabel = card3:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    hudLabel:SetPoint("TOPLEFT", btnSeam36, "BOTTOMLEFT", 0, -8)
    hudLabel:SetText("Global UI Scale Preset:")

    local btnHud56 = CreateFrame("Button", nil, card3, "UIPanelButtonTemplate")
    btnHud56:SetSize(188, 22)
    btnHud56:SetPoint("TOPLEFT", hudLabel, "BOTTOMLEFT", 0, -4)
    btnHud56:SetText("Compact (56%)")
    btnHud56:SetScript("OnClick", function()
        Akimbo.db.hudScale = 0.56
        f:UpdateState()
        Akimbo:ApplyFullLayout()
    end)

    local btnHud65 = CreateFrame("Button", nil, card3, "UIPanelButtonTemplate")
    btnHud65:SetSize(188, 22)
    btnHud65:SetPoint("LEFT", btnHud56, "RIGHT", 10, 0)
    btnHud65:SetText("Balanced (65%)")
    btnHud65:SetScript("OnClick", function()
        Akimbo.db.hudScale = 0.65
        f:UpdateState()
        Akimbo:ApplyFullLayout()
    end)

    local btnHud70 = CreateFrame("Button", nil, card3, "UIPanelButtonTemplate")
    btnHud70:SetSize(188, 22)
    btnHud70:SetPoint("LEFT", btnHud65, "RIGHT", 10, 0)
    btnHud70:SetText("Standard (70%)")
    btnHud70:SetScript("OnClick", function()
        Akimbo.db.hudScale = 0.70
        f:UpdateState()
        Akimbo:ApplyFullLayout()
    end)

    -- ========================================================================
    -- FOOTER ACTIONS
    -- ========================================================================
    local advBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    advBtn:SetSize(240, 28)
    advBtn:SetPoint("BOTTOMLEFT", 16, 14)
    advBtn:SetText("Advanced Settings (/akimbo)")
    advBtn:SetScript("OnClick", function()
        Wizard:Close()
        if Akimbo.Options and Akimbo.Options.Open then
            Akimbo.Options:Open()
        end
    end)

    local finishBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    finishBtn:SetSize(240, 28)
    finishBtn:SetPoint("BOTTOMRIGHT", -16, 14)
    finishBtn:SetText("|cffffd100Save & Finish Setup|r")
    finishBtn:SetScript("OnClick", function()
        if Akimbo.db then
            Akimbo.db.firstRunComplete = true
        end
        Wizard:Close()
        Akimbo:ApplyFullLayout()
        if Akimbo.Print then
            Akimbo:Print("Configuration saved! Welcome to Akimbo Dual Monitor Workstation.")
        end
    end)

    function f:UpdateLaserButton()
        local isShown = Akimbo.Options and Akimbo.Options.IsSeamGuideShown and Akimbo.Options:IsSeamGuideShown()
        btnLaser:SetText(isShown and "|cffff3333Hide Laser|r" or "Show Laser")
    end

    function f:UpdateState()
        if not Akimbo.db then return end
        local p = Akimbo.db.layoutPreset
        local pos = Akimbo.db.primaryPosition
        local ar = Akimbo.db.aspectRatioMode
        local hud = Akimbo.db.hudScale or 0.70
        local seam = Akimbo.db.deckWidthRatio or 0.36

        seamSlider:SetValue(seam)
        seamValText:SetText(string.format("Seam: %.1f%%", seam * 100))

        btnPl:SetEnabled(not (p == "PORTRAIT_LEFT_LANDSCAPE_RIGHT" and pos == "RIGHT"))
        btnPr:SetEnabled(not (p == "PORTRAIT_LEFT_LANDSCAPE_RIGHT" and pos == "LEFT"))
        btnDual:SetEnabled(not (p == "LANDSCAPE_DUAL"))

        btn169:SetEnabled(ar ~= "16_9")
        btn219:SetEnabled(ar ~= "21_9")
        btnFill:SetEnabled(ar ~= "FILL")

        btnHud56:SetEnabled(math.abs(hud - 0.56) > 0.03)
        btnHud65:SetEnabled(math.abs(hud - 0.65) > 0.03)
        btnHud70:SetEnabled(math.abs(hud - 0.70) > 0.03)

        self:UpdateLaserButton()
    end

    f.seamSlider = seamSlider
    f.seamValText = seamValText

    wizardFrame = f
    return f
end

function Wizard:Open()
    local f = self:CreateFrame()
    if not f then return end

    local info = self:DetectTopology()

    f.topoText:SetText(string.format("|cffffd100Detected Display:|r %s (%dx%d, AR %.2f:1)",
        info.description, info.physWidth, info.physHeight, info.aspectRatio))

    f.recomText:SetText(string.format("|cffffd100Recommendation:|r %s | Seam: %.1f%% | Viewport: %s",
        (info.recommendedPreset == "PORTRAIT_LEFT_LANDSCAPE_RIGHT" and (info.recommendedPosition == "RIGHT" and "Portrait Left + Game Right" or "Game Left + Portrait Right") or "Dual Landscape 50/50"),
        info.recommendedDeckRatio * 100,
        info.recommendedAR or "16:9"))

    f.statusText:SetText("Click above to automatically detect resolution and configure seam, orientation, and viewport.")

    f:UpdateState()

    -- Center over the 3D game screen if spanned
    local m = Akimbo.Viewport and Akimbo.Viewport:GetMetrics()
    if m and m.gameWidth and m.gameWidth > 0 then
        local cx = (m.gameLeft + m.gameRight) / 2
        local cy = (m.gameBottom + m.gameTop) / 2
        f:ClearAllPoints()
        f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)
    else
        f:ClearAllPoints()
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    if Akimbo.Options and Akimbo.Options.ShowSeamGuide then
        Akimbo.Options:ShowSeamGuide(Akimbo.db and Akimbo.db.deckWidthRatio)
        f:UpdateLaserButton()
    end

    f:Show()
end

function Wizard:Close()
    if Akimbo.Options and Akimbo.Options.HideSeamGuide then
        Akimbo.Options:HideSeamGuide()
    end
    if wizardFrame then
        wizardFrame:Hide()
    end
end

function Akimbo:OpenWizard()
    Wizard:Open()
end
