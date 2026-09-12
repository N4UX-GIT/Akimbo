--[[
    Akimbo: Dual Monitor Workstation Addon
    UI/Options.lua: Native UI configuration panel, Setup Assistant, and controls
    (Self-contained: avoids deprecated XML templates removed in modern 1.15+ clients)
--]]

local _, Akimbo = ...

local Options = {}
Akimbo.Options = Options

local configFrame
local setupFrame

-- ============================================================================
-- Native Bulletproof UI Widget Builders
-- ============================================================================
local function CreateNativeCheckbox(parent, text, getVal, setVal)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(24, 24)

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

    return slider
end

-- Shared by settings and wizard. Opening either screen never changes calibration.
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
-- Floating Options Panel
-- ============================================================================
function Options:CreateFloatingPanel()
    if configFrame then return configFrame end

    configFrame = CreateFrame("Frame", "AkimboFloatingConfigFrame", UIParent, "BackdropTemplate")
    configFrame:SetSize(580, 640)
    configFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    configFrame:SetFrameStrata("DIALOG")
    configFrame:EnableMouse(true)
    configFrame:SetMovable(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)

    Akimbo.Themes:ApplyBackdrop(configFrame, "OBSIDIAN", 0.98)
    configFrame.header = Akimbo.Themes:CreateBayHeader(configFrame, "AKIMBO DUAL MONITOR WORKSTATION CONFIG")

    local closeBtn = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -4, -4)

    -- Master Enable Checkbox
    local enableCheck = CreateNativeCheckbox(configFrame, "Enable Akimbo Dual Monitor Workstation",
        function() return Akimbo.db.enabled end,
        function(val) Akimbo.db.enabled = val end
    )
    enableCheck:SetPoint("TOPLEFT", 20, -38)

    local wizardBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    wizardBtn:SetSize(150, 24)
    wizardBtn:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -36, -38)
    wizardBtn:SetText("|cff00ff00Launch Setup Wizard|r")
    wizardBtn:SetScript("OnClick", function()
        configFrame:Hide()
        if Akimbo.Wizard and Akimbo.Wizard.Open then
            Akimbo.Wizard:Open()
        end
    end)

    -- Layout Presets Section
    local layoutLabel = configFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    layoutLabel:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 0, -14)
    layoutLabel:SetText("Display Orientation Preset:")

    local p1Btn = CreateNativeCheckbox(configFrame, "Vertical Portrait (Left) + Horizontal 16:9 Game (Right)",
        function() return (Akimbo.db.layoutPreset == "PORTRAIT_LEFT_LANDSCAPE_RIGHT") end,
        function(val)
            if val then
                Akimbo.db.layoutPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT"
                Akimbo.db.primaryPosition = "RIGHT"
                Akimbo.db.deckWidthRatio = Akimbo.db.deckWidthRatio or 0.36
                Akimbo.db.gameHeightRatio = 0.5625
                Options:RefreshPanel()
            end
        end
    )
    p1Btn:SetPoint("TOPLEFT", layoutLabel, "BOTTOMLEFT", 10, -6)

    local p2Btn = CreateNativeCheckbox(configFrame, "Standard Dual Landscape (Side-by-side matching displays)",
        function() return (Akimbo.db.layoutPreset == "LANDSCAPE_DUAL") end,
        function(val)
            if val then
                Akimbo.db.layoutPreset = "LANDSCAPE_DUAL"
                Akimbo.db.primaryPosition = "LEFT"
                Akimbo.db.deckWidthRatio = 0.50
                Options:RefreshPanel()
            end
        end
    )
    p2Btn:SetPoint("TOPLEFT", p1Btn, "BOTTOMLEFT", 0, -4)
    -- Aspect Ratio Mode
    local arLabel = configFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    arLabel:SetPoint("TOPLEFT", p2Btn, "BOTTOMLEFT", 0, -10)
    arLabel:SetText("3D Game Aspect Ratio Lock:")

    local ar16Btn = CreateNativeCheckbox(configFrame, "16:9 Standard",
        function() return (Akimbo.db.aspectRatioMode == "16_9") end,
        function(val)
            if val then
                Akimbo.db.aspectRatioMode = "16_9"
                Options:RefreshPanel()
            end
        end
    )
    ar16Btn:SetPoint("TOPLEFT", arLabel, "BOTTOMLEFT", 0, -4)

    local ar21Btn = CreateNativeCheckbox(configFrame, "21:9 Ultrawide",
        function() return (Akimbo.db.aspectRatioMode == "21_9") end,
        function(val)
            if val then
                Akimbo.db.aspectRatioMode = "21_9"
                Options:RefreshPanel()
            end
        end
    )
    ar21Btn:SetPoint("LEFT", ar16Btn, "RIGHT", 80, 0)

    -- Sliders
    local bezelSlider = CreateNativeSlider(configFrame, "Bezel Compensation Gap", 0, 100, 2,
        function() return Akimbo.db.bezelGap or 0 end,
        function(val) Akimbo.db.bezelGap = val end,
        "%d px"
    )
    bezelSlider:SetPoint("TOPLEFT", ar16Btn, "BOTTOMLEFT", 0, -26)
    bezelSlider:SetWidth(240)

    local alphaSlider = CreateNativeSlider(configFrame, "Command Deck Background Opacity", 0.2, 1.0, 0.05,
        function() return Akimbo.db.canvasAlpha or 0.95 end,
        function(val) Akimbo.db.canvasAlpha = val end,
        "%.1f%%"
    )
    alphaSlider:SetPoint("LEFT", bezelSlider, "RIGHT", 40, 0)
    alphaSlider:SetWidth(240)

    local deckRatioSlider = CreateNativeSlider(configFrame, "Deck Width (% of Window)", 0.15, 0.80, 0.005,
        function() return Akimbo.db.deckWidthRatio or 0.36 end,
        function(val) Akimbo.db.deckWidthRatio = val end,
        "%.1f%%"
    )
    deckRatioSlider:SetPoint("TOPLEFT", bezelSlider, "BOTTOMLEFT", 0, -26)
    deckRatioSlider:SetWidth(240)

    local hudScaleSlider = CreateNativeSlider(configFrame, "Global UI Size (% of Game View)", 0.25, 1.25, 0.01,
        function() return Akimbo.db.hudScale or 0.70 end,
        function(val) Akimbo.db.hudScale = val end,
        "%.1f%%"
    )
    hudScaleSlider:SetPoint("LEFT", deckRatioSlider, "RIGHT", 40, 0)
    hudScaleSlider:SetWidth(240)

    local bottomControl = Options:CreateBottomControl(configFrame)
    bottomControl:SetPoint("TOPLEFT", deckRatioSlider, "BOTTOMLEFT", 0, -14)

    -- Module & Navigation Features
    local modLabel = configFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    modLabel:SetPoint("TOPLEFT", bottomControl, "BOTTOMLEFT", 0, -10)
    modLabel:SetText("Workspace & Navigation Options:")

    local seamCheck = CreateNativeCheckbox(configFrame, "Reroute Popups & Dialogs away from the center bezel",
        function() return Akimbo.db.seamRedirect end,
        function(val) Akimbo.db.seamRedirect = val end
    )
    seamCheck:SetPoint("TOPLEFT", modLabel, "BOTTOMLEFT", 0, -4)

    local mapMoveCheck = CreateNativeCheckbox(configFrame, "Keep World Map open while running / walking",
        function() return Akimbo.db.preventMapCloseOnMove end,
        function(val)
            Akimbo.db.preventMapCloseOnMove = val
            if Akimbo.Canvas and Akimbo.Canvas.UpdateMapMovementBehavior then
                Akimbo.Canvas:UpdateMapMovementBehavior()
            end
        end
    )
    mapMoveCheck:SetPoint("TOPLEFT", seamCheck, "BOTTOMLEFT", 0, -4)

    local mapDesc = configFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    mapDesc:SetPoint("TOPLEFT", mapMoveCheck, "BOTTOMLEFT", 28, -2)
    local hasLMap = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Leatrix_Maps") or (IsAddOnLoaded and IsAddOnLoaded("Leatrix_Maps"))
    if hasLMap then
        mapDesc:SetText("|cff00ff00Leatrix Maps detected:|r Map movement behavior can also be managed via Leatrix.")
    else
        mapDesc:SetText("|cff888888Tip: Leatrix Maps is also recommended for full map customization.|r")
    end

    local panelCheck = CreateNativeCheckbox(configFrame, "Keep panels placed on workspace open independently",
        function() return Akimbo.db.independentWorkspacePanels end,
        function(val) Akimbo.db.independentWorkspacePanels = val end
    )
    panelCheck:SetPoint("TOPLEFT", mapDesc, "BOTTOMLEFT", -28, -6)

    local panelDesc = configFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    panelDesc:SetPoint("TOPLEFT", panelCheck, "BOTTOMLEFT", 28, -2)
    local hasLPlus = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Leatrix_Plus") or (IsAddOnLoaded and IsAddOnLoaded("Leatrix_Plus"))
    if hasLPlus then
        panelDesc:SetText("|cff00ff00Leatrix Plus detected:|r Both Akimbo and Leatrix Plus support independent panels.")
    else
        panelDesc:SetText("|cff888888Panels dragged to the workspace won't close when opening other panels.|r")
    end

    local forceCheck = CreateNativeCheckbox(configFrame, "Force Dual Mode (Preview on single display)",
        function() return Akimbo.db.forceDualOnSingle or false end,
        function(val) Akimbo.db.forceDualOnSingle = val end
    )
    forceCheck:SetPoint("TOPLEFT", panelDesc, "BOTTOMLEFT", -28, -6)

    -- Action Buttons (Bottom)
    local setupBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    setupBtn:SetSize(170, 26)
    setupBtn:SetPoint("BOTTOMLEFT", 20, 16)
    setupBtn:SetText("Setup & Span Guide")
    setupBtn:SetScript("OnClick", function()
        Options:ShowSetupGuide()
    end)

    local applyBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    applyBtn:SetSize(130, 26)
    applyBtn:SetPoint("BOTTOMRIGHT", -20, 16)
    applyBtn:SetText("Apply Layout")
    applyBtn:SetScript("OnClick", function()
        Akimbo:ApplyFullLayout()
        Akimbo:Print("Layout applied successfully.")
    end)

    function Options:RefreshPanel()
        p1Btn:SetChecked(Akimbo.db.layoutPreset == "PORTRAIT_LEFT_LANDSCAPE_RIGHT")
        p2Btn:SetChecked(Akimbo.db.layoutPreset == "LANDSCAPE_DUAL")
        ar16Btn:SetChecked(Akimbo.db.aspectRatioMode == "16_9")
        ar21Btn:SetChecked(Akimbo.db.aspectRatioMode == "21_9")
        Akimbo:ApplyFullLayout()
    end

    return configFrame
end

function Options:Open()
    local panel = self:CreateFloatingPanel()
    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
    end
end

-- ============================================================================
-- Setup Assistant Window
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
Open /akimbo wizard, choose the game monitor side, and align the red seam guide.
A 1440-pixel left display within a 4000-pixel span uses 36% deck width.
Choose 16:9 for a 2560x1440 game view when the remaining width is 2560 pixels.
Other display layouts need their own calibration.

|cffffcc00Step 4: Adjust HUD and Vertical Alignment|r
Global UI size is based on the game view; 70% is the default.
Use the Game bottom offset control, or /akimbo bottom <pixels>, for vertical alignment.
Use 0 for aligned bottom edges; the measured test setup uses 6.
Use /akimbo height <percent> to set game height in Fill mode only.

/akimbo settings opens the detailed controls, including bezel gap.
/akimbo diag reports the actual game rectangle in physical pixels.

]])
    end

    setupFrame:Show()
end

function Akimbo:InitializeOptions()
    -- Options ready
end
