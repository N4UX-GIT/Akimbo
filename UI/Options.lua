--[[
    Akimbo: Dual Monitor Workstation Addon
    UI/Options.lua: Unified Settings, Calibration Dashboard & Setup Guide
    (Pure ASCII, bulletproof native widgets, zero deprecated XML templates)
--]]

local _, Akimbo = ...

local Options = {}
Akimbo.Options = Options

local configFrame
local setupFrame
local seamGuideLine

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
        description = "Single Display / Standard Window",
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
    row:SetSize(550, 46)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetText("Game bottom offset (pixels above window bottom):")
    local input = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    input:SetSize(65, 22)
    input:SetPoint("TOPLEFT", 8, -20)
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
        button:SetSize(65, 22)
        button:SetPoint("LEFT", previous, "RIGHT", 8, 0)
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
-- Unified Authoritative Settings & Calibration Dashboard
-- ============================================================================
function Options:CreateFloatingPanel()
    if configFrame then return configFrame end

    configFrame = CreateFrame("Frame", "AkimboFloatingConfigFrame", UIParent, "BackdropTemplate")
    configFrame:SetSize(620, 690)
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
    configFrame.header = Akimbo.Themes:CreateBayHeader(configFrame, "AKIMBO DUAL MONITOR WORKSTATION DASHBOARD")

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
    banner:SetPoint("TOPLEFT", 20, -30)
    banner:SetPoint("TOPRIGHT", -20, -30)
    banner:SetJustifyH("LEFT")
    configFrame.banner = banner

    -- Top Row: Master Enable Checkbox + Red Seam Laser Toggle
    local enableCheck = CreateNativeCheckbox(configFrame, "Enable Akimbo Dual Monitor Workstation",
        function() return Akimbo.db and Akimbo.db.enabled end,
        function(val) Akimbo.db.enabled = val end
    )
    enableCheck:SetPoint("TOPLEFT", 20, -52)
    configFrame.enableCheck = enableCheck

    local laserCheck = CreateNativeCheckbox(configFrame, "Show Red Seam Guide Laser",
        function() return (seamGuideLine and seamGuideLine:IsShown()) or false end,
        function(val)
            if val then
                Options:ShowSeamGuide(Akimbo.db and Akimbo.db.deckWidthRatio)
            else
                Options:HideSeamGuide()
            end
        end
    )
    laserCheck:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -20, -52)
    configFrame.laserCheck = laserCheck

    -- Section 1: Display Orientation Preset
    local orientLabel = configFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    orientLabel:SetPoint("TOPLEFT", 20, -82)
    orientLabel:SetText("1. Display Orientation Preset:")

    local btnPl = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    btnPl:SetSize(280, 24)
    btnPl:SetPoint("TOPLEFT", orientLabel, "BOTTOMLEFT", 0, -6)
    btnPl:SetText("Portrait (Left) + Game (Right)")

    local btnPr = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    btnPr:SetSize(280, 24)
    btnPr:SetPoint("LEFT", btnPl, "RIGHT", 16, 0)
    btnPr:SetText("Game (Left) + Portrait (Right)")

    local btnDual = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    btnDual:SetSize(280, 24)
    btnDual:SetPoint("TOPLEFT", btnPl, "BOTTOMLEFT", 0, -4)
    btnDual:SetText("Dual Landscape Side-by-Side (50/50)")

    -- Section 2: 3D Game Aspect Ratio
    local arLabel = configFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    arLabel:SetPoint("TOPLEFT", btnDual, "BOTTOMLEFT", 0, -10)
    arLabel:SetText("2. 3D Game Viewport Aspect Ratio:")

    local btn169 = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    btn169:SetSize(180, 24)
    btn169:SetPoint("TOPLEFT", arLabel, "BOTTOMLEFT", 0, -6)
    btn169:SetText("16:9 Standard")

    local btn219 = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    btn219:SetSize(180, 24)
    btn219:SetPoint("LEFT", btn169, "RIGHT", 16, 0)
    btn219:SetText("21:9 Ultrawide")

    local btnFill = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    btnFill:SetSize(180, 24)
    btnFill:SetPoint("LEFT", btn219, "RIGHT", 16, 0)
    btnFill:SetText("Fit Window Height (Fill)")

    -- Section 3: Physical Bezel Seam Calibration
    local seamLabel = configFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    seamLabel:SetPoint("TOPLEFT", btn169, "BOTTOMLEFT", 0, -12)
    seamLabel:SetText("3. Bezel Seam & Physical Alignment:")

    local seamSlider = CreateFrame("Slider", nil, configFrame, "BackdropTemplate")
    seamSlider:SetOrientation("HORIZONTAL")
    seamSlider:SetSize(340, 16)
    seamSlider:SetPoint("TOPLEFT", seamLabel, "BOTTOMLEFT", 0, -8)
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

    local btnMinus = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    btnMinus:SetSize(46, 22)
    btnMinus:SetPoint("LEFT", seamSlider, "RIGHT", 10, 0)
    btnMinus:SetText("- 1%")

    local btnPlus = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    btnPlus:SetSize(46, 22)
    btnPlus:SetPoint("LEFT", btnMinus, "RIGHT", 4, 0)
    btnPlus:SetText("+ 1%")

    local seamValText = seamSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    seamValText:SetPoint("LEFT", btnPlus, "RIGHT", 10, 0)

    seamSlider:SetScript("OnValueChanged", function(self, val)
        val = math.floor((val / 0.005) + 0.5) * 0.005
        Akimbo.db.deckWidthRatio = val
        seamValText:SetText(string.format("Seam: %.1f%%", val * 100))
        Options:ShowSeamGuide(val)
        laserCheck:SetChecked(true)
        Akimbo:ApplyFullLayout()
    end)

    btnMinus:SetScript("OnClick", function()
        local cur = seamSlider:GetValue() or 0.36
        local nxt = math.max(0.15, cur - 0.01)
        seamSlider:SetValue(nxt)
    end)

    btnPlus:SetScript("OnClick", function()
        local cur = seamSlider:GetValue() or 0.36
        local nxt = math.min(0.80, cur + 0.01)
        seamSlider:SetValue(nxt)
    end)

    -- Quick Seam Preset Buttons
    local btnSeam36 = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    btnSeam36:SetSize(180, 22)
    btnSeam36:SetPoint("TOPLEFT", seamSlider, "BOTTOMLEFT", 0, -6)
    btnSeam36:SetText("1440 / 4000 (36%)")
    btnSeam36:SetScript("OnClick", function() seamSlider:SetValue(0.36) end)

    local btnSeam50 = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    btnSeam50:SetSize(180, 22)
    btnSeam50:SetPoint("LEFT", btnSeam36, "RIGHT", 16, 0)
    btnSeam50:SetText("Equal Split (50%)")
    btnSeam50:SetScript("OnClick", function() seamSlider:SetValue(0.50) end)

    local btnSeam55 = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    btnSeam55:SetSize(180, 22)
    btnSeam55:SetPoint("LEFT", btnSeam50, "RIGHT", 16, 0)
    btnSeam55:SetText("Custom Split (55%)")
    btnSeam55:SetScript("OnClick", function() seamSlider:SetValue(0.55) end)

    -- Bezel Gap and Alpha Sliders
    local bezelSlider = CreateNativeSlider(configFrame, "Bezel Compensation Gap", 0, 100, 2,
        function() return (Akimbo.db and Akimbo.db.bezelGap) or 0 end,
        function(val) Akimbo.db.bezelGap = val end,
        "%d px"
    )
    bezelSlider:SetPoint("TOPLEFT", btnSeam36, "BOTTOMLEFT", 0, -22)
    bezelSlider:SetWidth(270)

    local alphaSlider = CreateNativeSlider(configFrame, "Workspace Background Opacity", 0.20, 1.0, 0.05,
        function() return (Akimbo.db and Akimbo.db.canvasAlpha) or 0.95 end,
        function(val) Akimbo.db.canvasAlpha = val end,
        "%.0f%%"
    )
    alphaSlider:SetPoint("LEFT", bezelSlider, "RIGHT", 26, 0)
    alphaSlider:SetWidth(270)

    local bottomControl = Options:CreateBottomControl(configFrame)
    bottomControl:SetPoint("TOPLEFT", bezelSlider, "BOTTOMLEFT", 0, -8)

    -- Section 4: UI Scale & Command Deck
    local hudLabel = configFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    hudLabel:SetPoint("TOPLEFT", bottomControl, "BOTTOMLEFT", 0, -4)
    hudLabel:SetText("4. Global UI Size Relative to Game View:")

    local hudSlider = CreateNativeSlider(configFrame, "", 0.25, 1.25, 0.01,
        function() return (Akimbo.db and Akimbo.db.hudScale) or 0.70 end,
        function(val) Akimbo.db.hudScale = val end,
        "%.0f%%"
    )
    hudSlider:SetPoint("TOPLEFT", hudLabel, "BOTTOMLEFT", 0, -12)
    hudSlider:SetWidth(270)

    local btnHud56 = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    btnHud56:SetSize(86, 22)
    btnHud56:SetPoint("LEFT", hudSlider, "RIGHT", 16, 0)
    btnHud56:SetText("56% (Small)")
    btnHud56:SetScript("OnClick", function()
        hudSlider:SetValue(0.56)
        Options:RefreshPanel()
    end)

    local btnHud65 = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    btnHud65:SetSize(86, 22)
    btnHud65:SetPoint("LEFT", btnHud56, "RIGHT", 6, 0)
    btnHud65:SetText("65% (Med)")
    btnHud65:SetScript("OnClick", function()
        hudSlider:SetValue(0.65)
        Options:RefreshPanel()
    end)

    local btnHud70 = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    btnHud70:SetSize(86, 22)
    btnHud70:SetPoint("LEFT", btnHud65, "RIGHT", 6, 0)
    btnHud70:SetText("70% (Std)")
    btnHud70:SetScript("OnClick", function()
        hudSlider:SetValue(0.70)
        Options:RefreshPanel()
    end)

    -- Section 5: Workspace & Navigation Features
    local featLabel = configFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    featLabel:SetPoint("TOPLEFT", hudSlider, "BOTTOMLEFT", 0, -12)
    featLabel:SetText("5. Workspace & Window Behavior:")

    local seamCheck = CreateNativeCheckbox(configFrame, "Reroute Popups & Dialogs away from the center bezel",
        function() return Akimbo.db and Akimbo.db.seamRedirect end,
        function(val) Akimbo.db.seamRedirect = val end
    )
    seamCheck:SetPoint("TOPLEFT", featLabel, "BOTTOMLEFT", 0, -4)

    local mapMoveCheck = CreateNativeCheckbox(configFrame, "Keep World Map open while running / walking",
        function() return Akimbo.db and Akimbo.db.preventMapCloseOnMove end,
        function(val)
            Akimbo.db.preventMapCloseOnMove = val
            if Akimbo.Canvas and Akimbo.Canvas.UpdateMapMovementBehavior then
                Akimbo.Canvas:UpdateMapMovementBehavior()
            end
        end
    )
    mapMoveCheck:SetPoint("TOPLEFT", seamCheck, "BOTTOMLEFT", 0, -2)

    local mapDesc = configFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    mapDesc:SetPoint("TOPLEFT", mapMoveCheck, "BOTTOMLEFT", 26, -1)
    local hasLMap = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Leatrix_Maps") or (IsAddOnLoaded and IsAddOnLoaded("Leatrix_Maps"))
    if hasLMap then
        mapDesc:SetText("|cff00ff00Leatrix Maps detected:|r Map movement behavior can also be managed via Leatrix.")
    else
        mapDesc:SetText("|cff888888Tip: Leatrix Maps is also recommended for full map customization.|r")
    end

    local panelCheck = CreateNativeCheckbox(configFrame, "Keep panels placed on workspace open independently",
        function() return Akimbo.db and Akimbo.db.independentWorkspacePanels end,
        function(val) Akimbo.db.independentWorkspacePanels = val end
    )
    panelCheck:SetPoint("TOPLEFT", mapDesc, "BOTTOMLEFT", -26, -4)

    local panelDesc = configFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    panelDesc:SetPoint("TOPLEFT", panelCheck, "BOTTOMLEFT", 26, -1)
    local hasLPlus = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Leatrix_Plus") or (IsAddOnLoaded and IsAddOnLoaded("Leatrix_Plus"))
    if hasLPlus then
        panelDesc:SetText("|cff00ff00Leatrix Plus detected:|r Both Akimbo and Leatrix Plus support independent panels.")
    else
        panelDesc:SetText("|cff888888Panels dragged to the workspace won't close when opening other panels.|r")
    end

    local forceCheck = CreateNativeCheckbox(configFrame, "Force Dual Mode (Preview on single display)",
        function() return (Akimbo.db and Akimbo.db.forceDualOnSingle) or false end,
        function(val) Akimbo.db.forceDualOnSingle = val end
    )
    forceCheck:SetPoint("TOPLEFT", panelDesc, "BOTTOMLEFT", -26, -4)

    -- Bottom Action Buttons
    local guideBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    guideBtn:SetSize(160, 26)
    guideBtn:SetPoint("BOTTOMLEFT", 20, 16)
    guideBtn:SetText("Setup & Span Guide")
    guideBtn:SetScript("OnClick", function()
        Options:ShowSetupGuide()
    end)

    local applyBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    applyBtn:SetSize(140, 26)
    applyBtn:SetPoint("BOTTOMLEFT", guideBtn, "BOTTOMRIGHT", 16, 0)
    applyBtn:SetText("Apply Layout")
    applyBtn:SetScript("OnClick", function()
        Akimbo:ApplyFullLayout()
        Akimbo:Print("Layout applied successfully.")
    end)

    local closePanelBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    closePanelBtn:SetSize(160, 26)
    closePanelBtn:SetPoint("BOTTOMRIGHT", -20, 16)
    closePanelBtn:SetText("|cff00ff00Save & Close|r")
    closePanelBtn:SetScript("OnClick", function()
        Options:Close()
    end)

    -- Preset & Button Click Handlers
    local function UpdateButtonHighlights()
        local p = Akimbo.db and Akimbo.db.layoutPreset
        local pos = Akimbo.db and Akimbo.db.primaryPosition
        local ar = Akimbo.db and Akimbo.db.aspectRatioMode
        local hud = (Akimbo.db and Akimbo.db.hudScale) or 0.70

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
        local cur = Akimbo.db.deckWidthRatio or 0.36
        seamSlider:SetValue(cur)
        Options:RefreshPanel()
    end)

    btnPr:SetScript("OnClick", function()
        Akimbo.db.layoutPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT"
        Akimbo.db.primaryPosition = "LEFT"
        local cur = Akimbo.db.deckWidthRatio or 0.36
        seamSlider:SetValue(cur)
        Options:RefreshPanel()
    end)

    btnDual:SetScript("OnClick", function()
        Akimbo.db.layoutPreset = "LANDSCAPE_DUAL"
        Akimbo.db.primaryPosition = "LEFT"
        Akimbo.db.deckWidthRatio = 0.50
        seamSlider:SetValue(0.50)
        Options:RefreshPanel()
    end)

    btn169:SetScript("OnClick", function()
        Akimbo.db.aspectRatioMode = "16_9"
        Options:RefreshPanel()
    end)

    btn219:SetScript("OnClick", function()
        Akimbo.db.aspectRatioMode = "21_9"
        Options:RefreshPanel()
    end)

    btnFill:SetScript("OnClick", function()
        Akimbo.db.aspectRatioMode = "FILL"
        Options:RefreshPanel()
    end)

    function Options:RefreshPanel()
        if not configFrame then return end
        local info = Options:DetectTopology()
        banner:SetText(string.format("|cff00ccffWindow Size:|r %dx%d (AR %.2f:1)  |cffffcc00Status:|r %s",
            info.physWidth, info.physHeight, info.aspectRatio, info.description))

        local curSeam = (Akimbo.db and Akimbo.db.deckWidthRatio) or 0.36
        seamSlider:SetValue(curSeam)
        seamValText:SetText(string.format("Seam: %.1f%%", curSeam * 100))

        enableCheck:SetChecked((Akimbo.db and Akimbo.db.enabled) or false)
        laserCheck:SetChecked((seamGuideLine and seamGuideLine:IsShown()) or false)
        seamCheck:SetChecked((Akimbo.db and Akimbo.db.seamRedirect) or false)
        mapMoveCheck:SetChecked((Akimbo.db and Akimbo.db.preventMapCloseOnMove) or false)
        panelCheck:SetChecked((Akimbo.db and Akimbo.db.independentWorkspacePanels) or false)
        forceCheck:SetChecked((Akimbo.db and Akimbo.db.forceDualOnSingle) or false)

        bezelSlider:UpdateText()
        alphaSlider:UpdateText()
        hudSlider:UpdateText()

        UpdateButtonHighlights()
        Akimbo:ApplyFullLayout()
    end

    configFrame.seamSlider = seamSlider
    configFrame.seamValText = seamValText
    configFrame.UpdateButtonHighlights = UpdateButtonHighlights

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
