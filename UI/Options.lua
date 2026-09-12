--[[
    Akimbo: Dual Monitor Workstation Addon
    UI/Options.lua: Clean Tabbed Settings, Calibration Dashboard & Setup Guide
    (Pure ASCII, sleek tabbed interface, zero clutter, bulletproof native widgets)
--]]

local _, Akimbo = ...

local Options = {}
Akimbo.Options = Options

local configFrame
local setupFrame
local seamGuideLine
local currentTab = 1

-- ============================================================================
-- Topology Detection
-- ============================================================================
function Options:DetectTopology()
    local physW, physH
    if GetPhysicalScreenSize then
        pcall(function() physW, physH = GetPhysicalScreenSize() end)
    end

    if not physW or physW <= 0 then
        local resStr = (GetCVar and (GetCVar("gxWindowedResolution") or GetCVar("gxFullscreenResolution"))) or "0x0"
        local w, h = strsplit("x", resStr)
        physW = tonumber(w) or (GetScreenWidth and GetScreenWidth()) or 1920
        physH = tonumber(h) or (GetScreenHeight and GetScreenHeight()) or 1080
    end

    local ar = physW / math.max(physH, 1)

    local info = {
        physWidth = physW,
        physHeight = physH,
        aspectRatio = ar,
        isSpanned = false,
        recommendedPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT",
        recommendedDeckRatio = 0.36,
        description = "Single Display",
    }

    if physW >= 3500 and physH >= 2000 and ar < 2.0 then
        info.isSpanned = true
        info.recommendedPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT"
        info.recommendedDeckRatio = 0.36
        info.description = string.format("Mixed Portrait + Landscape (%dx%d)", physW, physH)
    elseif ar >= 3.0 then
        info.isSpanned = true
        info.recommendedPreset = "LANDSCAPE_DUAL"
        info.recommendedDeckRatio = 0.50
        info.description = string.format("Dual Landscape Side-by-Side (%dx%d)", physW, physH)
    elseif ar >= 2.0 then
        info.isSpanned = true
        info.recommendedPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT"
        info.recommendedDeckRatio = 0.36
        info.description = string.format("Ultrawide Spanned (%dx%d)", physW, physH)
    else
        info.isSpanned = false
        info.recommendedPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT"
        info.recommendedDeckRatio = 0.36
        info.description = string.format("Windowed (%dx%d)", physW, physH)
    end

    return info
end

-- ============================================================================
-- Visual Seam Alignment Guide Line (Red Laser)
-- ============================================================================
function Options:ShowSeamGuide(deckRatio)
    if not UIParent then return end
    if not deckRatio then
        deckRatio = (Akimbo.db and Akimbo.db.deckWidthRatio) or 0.36
    end

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
        label:SetText("<< BEZEL SEAM >>")
        label:SetTextColor(1, 1, 1, 1)
    end

    local screenW = UIParent:GetWidth() or 1920
    local screenH = UIParent:GetHeight() or 1080
    local x = screenW * deckRatio
    if Akimbo.db and Akimbo.db.primaryPosition == "LEFT" then
        x = screenW - x
    end

    seamGuideLine:ClearAllPoints()
    seamGuideLine:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x - 2, screenH)
    seamGuideLine:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x - 2, 0)
    seamGuideLine:Show()
end

function Options:HideSeamGuide()
    if seamGuideLine then
        seamGuideLine:Hide()
    end
end

-- ============================================================================
-- Native Bulletproof UI Widget Builders
-- ============================================================================
local function CreateNativeCheckbox(parent, text, getVal, setVal)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(22, 22)

    local label = check:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", check, "RIGHT", 6, 1)
    label:SetText(text)
    check.Text = label

    check:SetChecked(getVal())
    check:SetScript("OnClick", function(self)
        setVal(self:GetChecked())
        Akimbo:ApplyFullLayout()
    end)
    return check
end

local function CreateNativeRadioButton(parent, text, getVal, setVal)
    local radio = CreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
    radio:SetSize(18, 18)

    local label = radio:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", radio, "RIGHT", 6, 1)
    label:SetText(text)
    radio.Text = label

    radio:SetChecked(getVal())
    radio:SetScript("OnClick", function(self)
        setVal()
        Options:RefreshPanel()
    end)
    return radio
end

local function CreateNativeSlider(parent, text, minVal, maxVal, step, getVal, setVal, formatStr)
    local slider = CreateFrame("Slider", nil, parent, "BackdropTemplate")
    slider:SetOrientation("HORIZONTAL")
    slider:SetSize(220, 16)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(getVal())
    slider:EnableMouse(true)

    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    slider:SetBackdropColor(0.12, 0.14, 0.18, 0.95)
    slider:SetBackdropBorderColor(0.25, 0.3, 0.38, 1.0)

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(0.0, 0.8, 1.0, 1.0)
    thumb:SetSize(12, 16)
    slider:SetThumbTexture(thumb)

    local title = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    title:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 4)
    title:SetText(text)

    local valueText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    valueText:SetPoint("BOTTOMRIGHT", slider, "TOPRIGHT", 0, 4)
    local function FormatValue(value)
        if formatStr and formatStr:find("%%%%") then value = value * 100 end
        return string.format(formatStr or "%d", value)
    end
    valueText:SetText(FormatValue(getVal()))

    slider:SetScript("OnValueChanged", function(self, val)
        val = math.floor((val / step) + 0.5) * step
        valueText:SetText(FormatValue(val))
        setVal(val)
        Akimbo:ApplyFullLayout()
    end)

    slider.UpdateText = function(self)
        valueText:SetText(FormatValue(getVal()))
    end

    return slider
end

-- Shared bottom control tested by regression tests
function Options:CreateBottomControl(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(270, 46)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetText("Game bottom offset (pixels):")
    local input = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    input:SetSize(55, 22)
    input:SetPoint("TOPLEFT", 4, -20)
    input:SetAutoFocus(false)
    input:SetNumeric(true)
    input:SetMaxLetters(5)
    local function Refresh()
        input:SetText(tostring(math.floor(Akimbo.db.gameBottomPixels or 0)))
    end
    local function Apply(delta)
        local value = tonumber(input:GetText())
        if not value then Refresh(); return end
        local _, height = GetPhysicalScreenSize()
        Akimbo.db.gameBottomPixels = math.max(0, math.min(height - 1,
            math.floor(value + (delta or 0) + 0.5)))
        Refresh()
        Akimbo:ApplyFullLayout()
    end
    local previous = input
    for _, item in ipairs({{"-1 px", -1}, {"+1 px", 1}, {"Apply", 0}}) do
        local button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        button:SetSize(54, 22)
        button:SetPoint("LEFT", previous, "RIGHT", 6, 0)
        button:SetText(item[1])
        local delta = item[2]
        button:SetScript("OnClick", function() Apply(delta) end)
        previous = button
    end
    input:SetScript("OnEnterPressed", function(self) Apply(0); self:ClearFocus() end)
    input:SetScript("OnEscapePressed", function(self) Refresh(); self:ClearFocus() end)
    row.Refresh = Refresh
    row:SetScript("OnShow", Refresh)
    Refresh()
    return row
end

-- ============================================================================
-- Unified Clean Tabbed Dashboard
-- ============================================================================
function Options:CreateFloatingPanel()
    if configFrame then return configFrame end

    configFrame = CreateFrame("Frame", "AkimboFloatingConfigFrame", UIParent, "BackdropTemplate")
    configFrame:SetSize(580, 490)
    configFrame:SetFrameStrata("DIALOG")
    configFrame:EnableMouse(true)
    configFrame:SetMovable(true)
    configFrame:SetClampedToScreen(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)

    if tinsert and UISpecialFrames then
        tinsert(UISpecialFrames, "AkimboFloatingConfigFrame")
    end

    Akimbo.Themes:ApplyBackdrop(configFrame, "OBSIDIAN", 0.98)
    configFrame.header = Akimbo.Themes:CreateBayHeader(configFrame, "AKIMBO DUAL MONITOR WORKSTATION")

    local closeBtn = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function()
        Options:Close()
    end)

    configFrame:SetScript("OnHide", function()
        Options:HideSeamGuide()
    end)

    -- Status & Topology Detection Banner
    local banner = configFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    banner:SetPoint("TOPLEFT", 18, -28)
    banner:SetPoint("TOPRIGHT", -18, -28)
    banner:SetJustifyH("LEFT")
    configFrame.banner = banner

    -- Two Clean Tab Switchers
    local tab1Btn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    tab1Btn:SetSize(180, 24)
    tab1Btn:SetPoint("TOPLEFT", 18, -50)
    tab1Btn:SetText("Display & Viewport")

    local tab2Btn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    tab2Btn:SetSize(180, 24)
    tab2Btn:SetPoint("LEFT", tab1Btn, "RIGHT", 8, 0)
    tab2Btn:SetText("Workspace & Behavior")

    -- Tab Content Containers
    local tab1 = CreateFrame("Frame", nil, configFrame)
    tab1:SetPoint("TOPLEFT", 18, -80)
    tab1:SetPoint("BOTTOMRIGHT", -18, 50)
    configFrame.tab1 = tab1

    local tab2 = CreateFrame("Frame", nil, configFrame)
    tab2:SetPoint("TOPLEFT", 18, -80)
    tab2:SetPoint("BOTTOMRIGHT", -18, 50)
    configFrame.tab2 = tab2

    local function SwitchTab(tabIndex)
        currentTab = tabIndex
        if tabIndex == 1 then
            tab1:Show()
            tab2:Hide()
            tab1Btn:SetEnabled(false)
            tab2Btn:SetEnabled(true)
        else
            tab1:Hide()
            tab2:Show()
            tab1Btn:SetEnabled(true)
            tab2Btn:SetEnabled(false)
        end
    end

    tab1Btn:SetScript("OnClick", function() SwitchTab(1) end)
    tab2Btn:SetScript("OnClick", function() SwitchTab(2) end)

    -- ========================================================================
    -- TAB 1: DISPLAY & VIEWPORT CALIBRATION
    -- ========================================================================
    -- Master Enable & Laser Checkboxes
    local enableCheck = CreateNativeCheckbox(tab1, "Enable Akimbo Dual Monitor Mode",
        function() return Akimbo.db and Akimbo.db.enabled end,
        function(val) Akimbo.db.enabled = val end
    )
    enableCheck:SetPoint("TOPLEFT", 0, 0)
    configFrame.enableCheck = enableCheck

    local laserCheck = CreateNativeCheckbox(tab1, "Show Red Seam Guide Laser",
        function() return (seamGuideLine and seamGuideLine:IsShown()) or false end,
        function(val)
            if val then
                Options:ShowSeamGuide(Akimbo.db and Akimbo.db.deckWidthRatio)
            else
                Options:HideSeamGuide()
            end
        end
    )
    laserCheck:SetPoint("LEFT", enableCheck, "RIGHT", 30, 0)
    configFrame.laserCheck = laserCheck

    -- Section 1: Display Orientation (Radio Buttons)
    local orientLabel = tab1:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    orientLabel:SetPoint("TOPLEFT", 0, -32)
    orientLabel:SetText("Display Orientation:")

    local rPortraitLeft = CreateNativeRadioButton(tab1, "Portrait (Left) + Game (Right)",
        function() return (Akimbo.db and Akimbo.db.layoutPreset == "PORTRAIT_LEFT_LANDSCAPE_RIGHT" and Akimbo.db.primaryPosition == "RIGHT") end,
        function()
            Akimbo.db.layoutPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT"
            Akimbo.db.primaryPosition = "RIGHT"
        end
    )
    rPortraitLeft:SetPoint("TOPLEFT", orientLabel, "BOTTOMLEFT", 4, -4)

    local rPortraitRight = CreateNativeRadioButton(tab1, "Game (Left) + Portrait (Right)",
        function() return (Akimbo.db and Akimbo.db.layoutPreset == "PORTRAIT_LEFT_LANDSCAPE_RIGHT" and Akimbo.db.primaryPosition == "LEFT") end,
        function()
            Akimbo.db.layoutPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT"
            Akimbo.db.primaryPosition = "LEFT"
        end
    )
    rPortraitRight:SetPoint("LEFT", rPortraitLeft, "RIGHT", 14, 0)

    local rDual = CreateNativeRadioButton(tab1, "Dual Landscape (50/50)",
        function() return (Akimbo.db and Akimbo.db.layoutPreset == "LANDSCAPE_DUAL") end,
        function()
            Akimbo.db.layoutPreset = "LANDSCAPE_DUAL"
            Akimbo.db.primaryPosition = "LEFT"
            Akimbo.db.deckWidthRatio = 0.50
        end
    )
    rDual:SetPoint("LEFT", rPortraitRight, "RIGHT", 14, 0)

    -- Section 2: 3D Viewport Aspect Ratio (Radio Buttons)
    local arLabel = tab1:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    arLabel:SetPoint("TOPLEFT", rPortraitLeft, "BOTTOMLEFT", -4, -10)
    arLabel:SetText("3D Game Viewport Aspect Ratio:")

    local r169 = CreateNativeRadioButton(tab1, "16:9 Standard",
        function() return (Akimbo.db and Akimbo.db.aspectRatioMode == "16_9") end,
        function() Akimbo.db.aspectRatioMode = "16_9" end
    )
    r169:SetPoint("TOPLEFT", arLabel, "BOTTOMLEFT", 4, -4)

    local r219 = CreateNativeRadioButton(tab1, "21:9 Ultrawide",
        function() return (Akimbo.db and Akimbo.db.aspectRatioMode == "21_9") end,
        function() Akimbo.db.aspectRatioMode = "21_9" end
    )
    r219:SetPoint("LEFT", r169, "RIGHT", 40, 0)

    local rFill = CreateNativeRadioButton(tab1, "Fit Window Height (Fill)",
        function() return (Akimbo.db and Akimbo.db.aspectRatioMode == "FILL") end,
        function() Akimbo.db.aspectRatioMode = "FILL" end
    )
    rFill:SetPoint("LEFT", r219, "RIGHT", 40, 0)

    -- Section 3: Bezel Seam Calibration Slider
    local seamSlider = CreateNativeSlider(tab1, "Bezel Seam Width (% of Window)", 0.15, 0.80, 0.005,
        function() return (Akimbo.db and Akimbo.db.deckWidthRatio) or 0.36 end,
        function(val)
            Akimbo.db.deckWidthRatio = val
            Options:ShowSeamGuide(val)
            laserCheck:SetChecked(true)
        end,
        "%.1f%%"
    )
    seamSlider:SetPoint("TOPLEFT", r169, "BOTTOMLEFT", -4, -20)
    seamSlider:SetWidth(320)

    -- Subtle Text Presets for Seam
    local p36Btn = CreateFrame("Button", nil, tab1, "UIPanelButtonTemplate")
    p36Btn:SetSize(62, 20)
    p36Btn:SetPoint("LEFT", seamSlider, "RIGHT", 14, 0)
    p36Btn:SetText("36%")
    p36Btn:SetScript("OnClick", function() seamSlider:SetValue(0.36) end)

    local p50Btn = CreateFrame("Button", nil, tab1, "UIPanelButtonTemplate")
    p50Btn:SetSize(62, 20)
    p50Btn:SetPoint("LEFT", p36Btn, "RIGHT", 6, 0)
    p50Btn:SetText("50%")
    p50Btn:SetScript("OnClick", function() seamSlider:SetValue(0.50) end)

    local p55Btn = CreateFrame("Button", nil, tab1, "UIPanelButtonTemplate")
    p55Btn:SetSize(62, 20)
    p55Btn:SetPoint("LEFT", p50Btn, "RIGHT", 6, 0)
    p55Btn:SetText("55%")
    p55Btn:SetScript("OnClick", function() seamSlider:SetValue(0.55) end)

    -- Section 4: Bottom Offset & UI Scale Row
    local bottomControl = Options:CreateBottomControl(tab1)
    bottomControl:SetPoint("TOPLEFT", seamSlider, "BOTTOMLEFT", 0, -12)

    local hudSlider = CreateNativeSlider(tab1, "Global UI Size (% of Game View)", 0.25, 1.25, 0.01,
        function() return (Akimbo.db and Akimbo.db.hudScale) or 0.70 end,
        function(val) Akimbo.db.hudScale = val end,
        "%.0f%%"
    )
    hudSlider:SetPoint("LEFT", bottomControl, "RIGHT", 20, 4)
    hudSlider:SetWidth(180)

    -- ========================================================================
    -- TAB 2: WORKSPACE & BEHAVIOR
    -- ========================================================================
    -- Appearance Sliders Row
    local bezelSlider = CreateNativeSlider(tab2, "Bezel Compensation Gap", 0, 100, 2,
        function() return (Akimbo.db and Akimbo.db.bezelGap) or 0 end,
        function(val) Akimbo.db.bezelGap = val end,
        "%d px"
    )
    bezelSlider:SetPoint("TOPLEFT", 0, -6)
    bezelSlider:SetWidth(250)

    local alphaSlider = CreateNativeSlider(tab2, "Workspace Background Opacity", 0.20, 1.0, 0.05,
        function() return (Akimbo.db and Akimbo.db.canvasAlpha) or 0.95 end,
        function(val) Akimbo.db.canvasAlpha = val end,
        "%.0f%%"
    )
    alphaSlider:SetPoint("LEFT", bezelSlider, "RIGHT", 30, 0)
    alphaSlider:SetWidth(250)

    -- Feature Checkboxes
    local featLabel = tab2:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    featLabel:SetPoint("TOPLEFT", bezelSlider, "BOTTOMLEFT", 0, -18)
    featLabel:SetText("Workspace Window Behavior:")

    local seamCheck = CreateNativeCheckbox(tab2, "Reroute Popups & Dialogs away from the center bezel",
        function() return Akimbo.db and Akimbo.db.seamRedirect end,
        function(val) Akimbo.db.seamRedirect = val end
    )
    seamCheck:SetPoint("TOPLEFT", featLabel, "BOTTOMLEFT", 0, -6)

    local mapMoveCheck = CreateNativeCheckbox(tab2, "Keep World Map open while running / walking",
        function() return Akimbo.db and Akimbo.db.preventMapCloseOnMove end,
        function(val)
            Akimbo.db.preventMapCloseOnMove = val
            if Akimbo.Canvas and Akimbo.Canvas.UpdateMapMovementBehavior then
                Akimbo.Canvas:UpdateMapMovementBehavior()
            end
        end
    )
    mapMoveCheck:SetPoint("TOPLEFT", seamCheck, "BOTTOMLEFT", 0, -4)

    local mapDesc = tab2:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    mapDesc:SetPoint("TOPLEFT", mapMoveCheck, "BOTTOMLEFT", 26, -1)
    local hasLMap = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Leatrix_Maps") or (IsAddOnLoaded and IsAddOnLoaded("Leatrix_Maps"))
    if hasLMap then
        mapDesc:SetText("|cff00ff00Leatrix Maps detected:|r Compatible with Leatrix.")
    else
        mapDesc:SetText("|cff888888Allows navigating with map open. (Compatible with Leatrix Maps)|r")
    end

    local panelCheck = CreateNativeCheckbox(tab2, "Keep panels placed on workspace open independently",
        function() return Akimbo.db and Akimbo.db.independentWorkspacePanels end,
        function(val) Akimbo.db.independentWorkspacePanels = val end
    )
    panelCheck:SetPoint("TOPLEFT", mapDesc, "BOTTOMLEFT", -26, -6)

    local panelDesc = tab2:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    panelDesc:SetPoint("TOPLEFT", panelCheck, "BOTTOMLEFT", 26, -1)
    local hasLPlus = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Leatrix_Plus") or (IsAddOnLoaded and IsAddOnLoaded("Leatrix_Plus"))
    if hasLPlus then
        panelDesc:SetText("|cff00ff00Leatrix Plus detected:|r Compatible with Leatrix Plus.")
    else
        panelDesc:SetText("|cff888888Panels dragged to the workspace won't close when opening other panels.|r")
    end

    local forceCheck = CreateNativeCheckbox(tab2, "Force Dual Mode (Preview on single display)",
        function() return (Akimbo.db and Akimbo.db.forceDualOnSingle) or false end,
        function(val) Akimbo.db.forceDualOnSingle = val end
    )
    forceCheck:SetPoint("TOPLEFT", panelDesc, "BOTTOMLEFT", -26, -6)

    local guideLinkBtn = CreateFrame("Button", nil, tab2, "UIPanelButtonTemplate")
    guideLinkBtn:SetSize(200, 24)
    guideLinkBtn:SetPoint("TOPLEFT", forceCheck, "BOTTOMLEFT", 0, -10)
    guideLinkBtn:SetText("View Window Spanning Guide")
    guideLinkBtn:SetScript("OnClick", function() Options:ShowSetupGuide() end)

    -- ========================================================================
    -- BOTTOM ACTION BAR (Shared across tabs)
    -- ========================================================================
    local applyBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    applyBtn:SetSize(130, 26)
    applyBtn:SetPoint("BOTTOMLEFT", 18, 14)
    applyBtn:SetText("Apply Layout")
    applyBtn:SetScript("OnClick", function()
        Akimbo:ApplyFullLayout()
        Akimbo:Print("Layout applied successfully.")
    end)

    local closePanelBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    closePanelBtn:SetSize(130, 26)
    closePanelBtn:SetPoint("BOTTOMRIGHT", -18, 14)
    closePanelBtn:SetText("|cff00ff00Save & Close|r")
    closePanelBtn:SetScript("OnClick", function()
        Options:Close()
    end)

    function Options:RefreshPanel()
        if not configFrame then return end
        local info = Options:DetectTopology()
        banner:SetText(string.format("|cff00ccffDisplay Topology:|r %s |cffffcc00Window:|r %dx%d (AR %.2f:1)",
            info.description, info.physWidth, info.physHeight, info.aspectRatio))

        local curSeam = (Akimbo.db and Akimbo.db.deckWidthRatio) or 0.36
        seamSlider:SetValue(curSeam)

        enableCheck:SetChecked((Akimbo.db and Akimbo.db.enabled) or false)
        laserCheck:SetChecked((seamGuideLine and seamGuideLine:IsShown()) or false)

        rPortraitLeft:SetChecked(Akimbo.db and Akimbo.db.layoutPreset == "PORTRAIT_LEFT_LANDSCAPE_RIGHT" and Akimbo.db.primaryPosition == "RIGHT")
        rPortraitRight:SetChecked(Akimbo.db and Akimbo.db.layoutPreset == "PORTRAIT_LEFT_LANDSCAPE_RIGHT" and Akimbo.db.primaryPosition == "LEFT")
        rDual:SetChecked(Akimbo.db and Akimbo.db.layoutPreset == "LANDSCAPE_DUAL")

        r169:SetChecked(Akimbo.db and Akimbo.db.aspectRatioMode == "16_9")
        r219:SetChecked(Akimbo.db and Akimbo.db.aspectRatioMode == "21_9")
        rFill:SetChecked(Akimbo.db and Akimbo.db.aspectRatioMode == "FILL")

        seamCheck:SetChecked((Akimbo.db and Akimbo.db.seamRedirect) or false)
        mapMoveCheck:SetChecked((Akimbo.db and Akimbo.db.preventMapCloseOnMove) or false)
        panelCheck:SetChecked((Akimbo.db and Akimbo.db.independentWorkspacePanels) or false)
        forceCheck:SetChecked((Akimbo.db and Akimbo.db.forceDualOnSingle) or false)

        bezelSlider:UpdateText()
        alphaSlider:UpdateText()
        hudSlider:UpdateText()

        Akimbo:ApplyFullLayout()
    end

    SwitchTab(currentTab or 1)
    return configFrame
end

function Options:Open(showSeamGuide)
    local panel = self:CreateFloatingPanel()
    if panel:IsShown() and not showSeamGuide then
        panel:Hide()
        return
    end

    local m = Akimbo.Viewport and Akimbo.Viewport:GetMetrics()
    if m and m.gameWidth and m.gameWidth > 0 then
        local cx = (m.gameLeft + m.gameRight) / 2
        local cy = (m.gameBottom + m.gameTop) / 2
        panel:ClearAllPoints()
        panel:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)
    else
        panel:ClearAllPoints()
        panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    self:RefreshPanel()
    panel:Show()

    if showSeamGuide then
        self:ShowSeamGuide(Akimbo.db and Akimbo.db.deckWidthRatio)
        if configFrame and configFrame.laserCheck then
            configFrame.laserCheck:SetChecked(true)
        end
    end
end

function Options:Close()
    self:HideSeamGuide()
    if Akimbo.db then
        Akimbo.db.firstRunComplete = true
    end
    if configFrame then
        configFrame:Hide()
    end
end

-- ============================================================================
-- Setup & Spanning Guide Window
-- ============================================================================
function Options:ShowSetupGuide()
    if not setupFrame then
        setupFrame = CreateFrame("Frame", "AkimboSetupGuideFrame", UIParent, "BackdropTemplate")
        setupFrame:SetSize(620, 500)
        setupFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        setupFrame:SetFrameStrata("DIALOG")
        setupFrame:EnableMouse(true)
        setupFrame:SetMovable(true)
        setupFrame:RegisterForDrag("LeftButton")
        setupFrame:SetScript("OnDragStart", setupFrame.StartMoving)
        setupFrame:SetScript("OnDragStop", setupFrame.StopMovingOrSizing)

        if tinsert and UISpecialFrames then
            tinsert(UISpecialFrames, "AkimboSetupGuideFrame")
        end

        Akimbo.Themes:ApplyBackdrop(setupFrame, "OBSIDIAN", 0.98)
        Akimbo.Themes:CreateBayHeader(setupFrame, "AKIMBO WINDOW SPANNING GUIDE")

        local closeBtn = CreateFrame("Button", nil, setupFrame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", setupFrame, "TOPRIGHT", -4, -4)

        local scrollFrame = CreateFrame("ScrollFrame", nil, setupFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 16, -36)
        scrollFrame:SetPoint("BOTTOMRIGHT", -32, 16)

        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(560, 680)
        scrollFrame:SetScrollChild(content)

        local guideText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        guideText:SetPoint("TOPLEFT", 0, 0)
        guideText:SetWidth(560)
        guideText:SetJustifyH("LEFT")
        guideText:SetText([[
|cff00ccffHow to Span WoW Across Mixed Vertical + Horizontal Displays|r

|cff00ff00Borderless Window Spanning|r
The companion sizes WoW to the Windows virtual desktop. Set display orientation
and placement in Windows first; the addon cannot measure individual monitors.

|cffffcc00Step 1: Set WoW to Windowed Mode|r
In WoW, open Graphics settings and select Windowed display mode.

|cffffcc00Step 2: Span the Window|r
While WoW is open, run Akimbo-Span.bat (or Akimbo-Span.ps1) from your Akimbo folder.
The resulting canvas size depends on your Windows display arrangement.

|cffffcc00Step 3: Calibrate the Game View|r
Type /akimbo to open the settings dashboard.
A 1440-pixel left display within a 4000-pixel span uses 36% deck width.
Choose 16:9 for a 2560x1440 game view when the remaining width is 2560 pixels.
Use the Red Seam Guide laser to align the seam exactly with your physical bezel.

|cffffcc00Step 4: Adjust HUD and Vertical Alignment|r
Global UI size is based on the game view; 70% is the standard default.
Use the Game bottom offset control, or /akimbo bottom <pixels>, for vertical alignment.
Use 0 for aligned bottom edges; the measured test setup uses 6.

Type /akimbo to return to settings anytime.
Type /akimbo diag to report the actual game rectangle in physical pixels.
]])
    end

    local m = Akimbo.Viewport and Akimbo.Viewport:GetMetrics()
    if m and m.gameWidth and m.gameWidth > 0 then
        local cx = (m.gameLeft + m.gameRight) / 2
        local cy = (m.gameBottom + m.gameTop) / 2
        setupFrame:ClearAllPoints()
        setupFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)
    else
        setupFrame:ClearAllPoints()
        setupFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    setupFrame:Show()
end

function Akimbo:InitializeOptions()
    -- Options ready
end
