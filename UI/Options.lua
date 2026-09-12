--[[
    Akimbo: Dual Monitor Workstation Addon
    UI/Options.lua: Clean Tabbed Settings, Calibration Dashboard & Setup Guide
    (Pure ASCII, sleek tabbed interface, zero clutter, bulletproof native widgets)
--]]

local _, Akimbo = ...

local tinsert = table.insert

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
    label:SetPoint("LEFT", check, "RIGHT", 8, 1)
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
    slider:SetBackdropColor(0.08, 0.08, 0.09, 0.95)
    slider:SetBackdropBorderColor(0.55, 0.48, 0.32, 0.9)

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(1.0, 0.82, 0.0, 1.0)
    thumb:SetSize(12, 16)
    slider:SetThumbTexture(thumb)

    local valueText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    valueText:SetPoint("BOTTOMRIGHT", slider, "TOPRIGHT", 0, 4)
    local function FormatValue(value)
        if formatStr and formatStr:find("%%%%") then value = value * 100 end
        return string.format(formatStr or "%d", value)
    end
    valueText:SetText(FormatValue(getVal()))

    local title = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    title:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 4)
    title:SetPoint("BOTTOMRIGHT", valueText, "BOTTOMLEFT", -6, 0)
    title:SetJustifyH("LEFT")
    title:SetText(text)

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
    row:SetSize(280, 46)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
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

function Options:GetConfigFrame()
    return configFrame
end

-- ============================================================================
-- Unified Clean Tabbed Dashboard
-- ============================================================================
function Options:CreateFloatingPanel()
    if configFrame then return configFrame end

    configFrame = CreateFrame("Frame", "AkimboFloatingConfigFrame", UIParent, "BackdropTemplate")
    configFrame:SetSize(720, 630)
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

    Akimbo.Themes:ApplyBackdrop(configFrame, (Akimbo.db and Akimbo.db.theme) or "CLASSIC", 0.98)
    configFrame.header = Akimbo.Themes:CreateBayHeader(configFrame, "AKIMBO DUAL MONITOR WORKSTATION")

    local closeBtn = CreateFrame("Button", nil, configFrame.header, "UIPanelCloseButton")
    closeBtn:SetSize(28, 28)
    closeBtn:SetPoint("RIGHT", configFrame.header, "RIGHT", -2, 0)
    closeBtn:SetScript("OnClick", function()
        Options:Close()
    end)

    configFrame:SetScript("OnHide", function()
        Options:HideSeamGuide()
    end)

    -- Status & Topology Detection Banner
    local banner = configFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    banner:SetPoint("TOPLEFT", 18, -40)
    banner:SetPoint("TOPRIGHT", -18, -40)
    banner:SetJustifyH("LEFT")
    configFrame.banner = banner

    -- Three Distinct Tab Switchers
    local tab1Btn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    tab1Btn:SetSize(220, 26)
    tab1Btn:SetPoint("TOPLEFT", 18, -60)
    tab1Btn:SetText("Display & Viewport")

    local tab2Btn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    tab2Btn:SetSize(220, 26)
    tab2Btn:SetPoint("LEFT", tab1Btn, "RIGHT", 12, 0)
    tab2Btn:SetText("Workspace & Map")

    local tab3Btn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    tab3Btn:SetSize(220, 26)
    tab3Btn:SetPoint("LEFT", tab2Btn, "RIGHT", 12, 0)
    tab3Btn:SetText("Themes & Colors")

    -- Tab Content Containers (Anchored below tab headers)
    local tab1 = CreateFrame("Frame", nil, configFrame)
    tab1:SetPoint("TOPLEFT", 16, -92)
    tab1:SetPoint("BOTTOMRIGHT", -16, 50)
    configFrame.tab1 = tab1

    local tab2 = CreateFrame("Frame", nil, configFrame)
    tab2:SetPoint("TOPLEFT", 16, -92)
    tab2:SetPoint("BOTTOMRIGHT", -16, 50)
    configFrame.tab2 = tab2

    local tab3 = CreateFrame("Frame", nil, configFrame)
    tab3:SetPoint("TOPLEFT", 16, -92)
    tab3:SetPoint("BOTTOMRIGHT", -16, 50)
    configFrame.tab3 = tab3

    local registeredCards = {}

    local function CreateCard(parent, titleText, yOffset, height)
        local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        card:SetSize(686, height)
        card:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)

        card:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        card:SetBackdropColor(0.04, 0.04, 0.05, 0.70)
        card:SetBackdropBorderColor(0.35, 0.35, 0.40, 0.75)

        local title = card:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        title:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -8)
        title:SetText(titleText)
        card.title = title

        tinsert(registeredCards, card)
        return card
    end

    function Options:UpdateCardThemes()
        local trimKey = (Akimbo.db and Akimbo.db.trimColor) or "GOLD"
        local pals = Akimbo.Themes and Akimbo.Themes.GetColorPalettes and Akimbo.Themes:GetColorPalettes()
        local c = pals and pals[trimKey]
        local br = c and { c.r * 0.75, c.g * 0.75, c.b * 0.75, 0.85 } or { 0.5, 0.4, 0.1, 0.85 }
        local textR, textG, textB = (c and c.r) or 1.0, (c and c.g) or 0.82, (c and c.b) or 0.0

        for _, card in ipairs(registeredCards) do
            card:SetBackdropBorderColor(br[1], br[2], br[3], br[4])
            if card.title then
                card.title:SetTextColor(textR, textG, textB, 1.0)
            end
        end
    end

    local function SwitchTab(tabIndex)
        currentTab = tabIndex
        tab1:SetShown(tabIndex == 1)
        tab2:SetShown(tabIndex == 2)
        tab3:SetShown(tabIndex == 3)

        tab1Btn:SetEnabled(tabIndex ~= 1)
        tab2Btn:SetEnabled(tabIndex ~= 2)
        tab3Btn:SetEnabled(tabIndex ~= 3)
    end

    tab1Btn:SetScript("OnClick", function() SwitchTab(1) end)
    tab2Btn:SetScript("OnClick", function() SwitchTab(2) end)
    tab3Btn:SetScript("OnClick", function() SwitchTab(3) end)

    -- ========================================================================
    -- TAB 1: DISPLAY & VIEWPORT CALIBRATION
    -- ========================================================================
    local card1_1 = CreateCard(tab1, "Display Mode & Dual Monitor Orientation", 0, 104)

    local enableCheck = CreateNativeCheckbox(card1_1, "Enable Akimbo Dual Monitor Mode",
        function() return Akimbo.db and Akimbo.db.enabled end,
        function(val) Akimbo.db.enabled = val end
    )
    enableCheck:SetPoint("TOPLEFT", 12, -26)
    configFrame.enableCheck = enableCheck

    local laserCheck = CreateNativeCheckbox(card1_1, "Show Red Seam Guide Laser",
        function() return (seamGuideLine and seamGuideLine:IsShown()) or false end,
        function(val)
            if val then
                Options:ShowSeamGuide(Akimbo.db and Akimbo.db.deckWidthRatio)
            else
                Options:HideSeamGuide()
            end
        end
    )
    laserCheck:SetPoint("TOPLEFT", 360, -26)
    configFrame.laserCheck = laserCheck

    local rPortraitLeft = CreateNativeRadioButton(card1_1, "Portrait (Left) + Game (Right)",
        function() return (Akimbo.db and Akimbo.db.layoutPreset == "PORTRAIT_LEFT_LANDSCAPE_RIGHT" and Akimbo.db.primaryPosition == "RIGHT") end,
        function()
            Akimbo.db.layoutPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT"
            Akimbo.db.primaryPosition = "RIGHT"
        end
    )
    rPortraitLeft:SetPoint("TOPLEFT", 12, -50)

    local rPortraitRight = CreateNativeRadioButton(card1_1, "Game (Left) + Portrait (Right)",
        function() return (Akimbo.db and Akimbo.db.layoutPreset == "PORTRAIT_LEFT_LANDSCAPE_RIGHT" and Akimbo.db.primaryPosition == "LEFT") end,
        function()
            Akimbo.db.layoutPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT"
            Akimbo.db.primaryPosition = "LEFT"
        end
    )
    rPortraitRight:SetPoint("TOPLEFT", 360, -50)

    local rDual = CreateNativeRadioButton(card1_1, "Dual Landscape Side-by-Side (50/50)",
        function() return (Akimbo.db and Akimbo.db.layoutPreset == "LANDSCAPE_DUAL") end,
        function()
            Akimbo.db.layoutPreset = "LANDSCAPE_DUAL"
            Akimbo.db.primaryPosition = "LEFT"
            Akimbo.db.deckWidthRatio = 0.50
        end
    )
    rDual:SetPoint("TOPLEFT", 12, -74)


    local card1_2 = CreateCard(tab1, "3D Game Viewport Geometry & Bezel Seam", -118, 120)

    local r169 = CreateNativeRadioButton(card1_2, "16:9 Standard",
        function() return (Akimbo.db and Akimbo.db.aspectRatioMode == "16_9") end,
        function() Akimbo.db.aspectRatioMode = "16_9" end
    )
    r169:SetPoint("TOPLEFT", 12, -26)

    local r219 = CreateNativeRadioButton(card1_2, "21:9 Ultrawide",
        function() return (Akimbo.db and Akimbo.db.aspectRatioMode == "21_9") end,
        function() Akimbo.db.aspectRatioMode = "21_9" end
    )
    r219:SetPoint("TOPLEFT", 200, -26)

    local rFill = CreateNativeRadioButton(card1_2, "Fit Window Height (Fill)",
        function() return (Akimbo.db and Akimbo.db.aspectRatioMode == "FILL") end,
        function() Akimbo.db.aspectRatioMode = "FILL" end
    )
    rFill:SetPoint("TOPLEFT", 380, -26)

    local seamSlider = CreateNativeSlider(card1_2, "Bezel Seam Width (% of Window)", 0.15, 0.80, 0.005,
        function() return (Akimbo.db and Akimbo.db.deckWidthRatio) or 0.36 end,
        function(val)
            Akimbo.db.deckWidthRatio = val
            Options:ShowSeamGuide(val)
            laserCheck:SetChecked(true)
        end,
        "%.1f%%"
    )
    seamSlider:SetPoint("TOPLEFT", 12, -64)
    seamSlider:SetWidth(350)

    local p36Btn = CreateFrame("Button", nil, card1_2, "UIPanelButtonTemplate")
    p36Btn:SetSize(66, 22)
    p36Btn:SetPoint("LEFT", seamSlider, "RIGHT", 16, -6)
    p36Btn:SetText("36%")
    p36Btn:SetScript("OnClick", function() seamSlider:SetValue(0.36) end)

    local p50Btn = CreateFrame("Button", nil, card1_2, "UIPanelButtonTemplate")
    p50Btn:SetSize(66, 22)
    p50Btn:SetPoint("LEFT", p36Btn, "RIGHT", 6, 0)
    p50Btn:SetText("50%")
    p50Btn:SetScript("OnClick", function() seamSlider:SetValue(0.50) end)

    local p55Btn = CreateFrame("Button", nil, card1_2, "UIPanelButtonTemplate")
    p55Btn:SetSize(66, 22)
    p55Btn:SetPoint("LEFT", p50Btn, "RIGHT", 6, 0)
    p55Btn:SetText("55%")
    p55Btn:SetScript("OnClick", function() seamSlider:SetValue(0.55) end)


    local card1_3 = CreateCard(tab1, "Screen Bottom Offset & Global UI Scale", -252, 180)

    local bottomControl = Options:CreateBottomControl(card1_3)
    bottomControl:SetPoint("TOPLEFT", 12, -26)

    local hudSlider = CreateNativeSlider(card1_3, "Global UI Size (% of Game View)", 0.25, 1.25, 0.01,
        function() return (Akimbo.db and Akimbo.db.hudScale) or 0.70 end,
        function(val) Akimbo.db.hudScale = val end,
        "%.0f%%"
    )
    hudSlider:SetPoint("TOPLEFT", 360, -46)
    hudSlider:SetWidth(300)

    -- ========================================================================
    -- TAB 2: WORKSPACE & WORLD MAP
    -- ========================================================================
    local card2_1 = CreateCard(tab2, "World Map Scaling & Navigation", 0, 150)

    local mapScaleSlider = CreateNativeSlider(card2_1, "Workspace Map Scale (% of Native)", 0.50, 2.50, 0.05,
        function()
            local s = Akimbo.db and Akimbo.db.workspaceMapScale
            if s == "AUTO" then
                local m = Akimbo.Viewport and Akimbo.Viewport:GetMetrics()
                local baseWidth = (WorldMapFrame and WorldMapFrame:GetWidth()) or 610
                if baseWidth <= 0 then baseWidth = 610 end
                local availableWidth = (m and m.deckWidth and (m.deckWidth - 24)) or 610
                return math.max(0.50, math.min(2.50, math.floor((availableWidth / baseWidth) * 100 + 0.5) / 100))
            end
            return (tonumber(s) and tonumber(s)) or 1.00
        end,
        function(val)
            Akimbo.db.workspaceMapScale = val
            if Akimbo.Canvas and Akimbo.Canvas.ConfigureWorldMap then
                Akimbo.Canvas:ConfigureWorldMap()
            end
        end,
        "%.0f%%"
    )
    mapScaleSlider:SetPoint("TOPLEFT", 12, -44)
    mapScaleSlider:SetWidth(270)

    local autoFitBtn = CreateFrame("Button", nil, card2_1, "UIPanelButtonTemplate")
    autoFitBtn:SetSize(72, 22)
    autoFitBtn:SetPoint("LEFT", mapScaleSlider, "RIGHT", 12, -6)
    autoFitBtn:SetText("Auto-Fit")
    autoFitBtn:SetScript("OnClick", function()
        Akimbo.db.workspaceMapScale = "AUTO"
        if Akimbo.Canvas and Akimbo.Canvas.ConfigureWorldMap then
            Akimbo.Canvas:ConfigureWorldMap()
        end
        local m = Akimbo.Viewport and Akimbo.Viewport:GetMetrics()
        local baseWidth = (WorldMapFrame and WorldMapFrame:GetWidth()) or 610
        if baseWidth <= 0 then baseWidth = 610 end
        local availableWidth = (m and m.deckWidth and (m.deckWidth - 24)) or 610
        local computedScale = math.max(0.50, math.min(2.50, math.floor((availableWidth / baseWidth) * 100 + 0.5) / 100))
        mapScaleSlider:SetValue(computedScale)
    end)

    local p100Btn = CreateFrame("Button", nil, card2_1, "UIPanelButtonTemplate")
    p100Btn:SetSize(48, 22)
    p100Btn:SetPoint("LEFT", autoFitBtn, "RIGHT", 5, 0)
    p100Btn:SetText("100%")
    p100Btn:SetScript("OnClick", function() mapScaleSlider:SetValue(1.00) end)

    local p150Btn = CreateFrame("Button", nil, card2_1, "UIPanelButtonTemplate")
    p150Btn:SetSize(48, 22)
    p150Btn:SetPoint("LEFT", p100Btn, "RIGHT", 5, 0)
    p150Btn:SetText("150%")
    p150Btn:SetScript("OnClick", function() mapScaleSlider:SetValue(1.50) end)

    local p200Btn = CreateFrame("Button", nil, card2_1, "UIPanelButtonTemplate")
    p200Btn:SetSize(48, 22)
    p200Btn:SetPoint("LEFT", p150Btn, "RIGHT", 5, 0)
    p200Btn:SetText("200%")
    p200Btn:SetScript("OnClick", function() mapScaleSlider:SetValue(2.00) end)

    local p250Btn = CreateFrame("Button", nil, card2_1, "UIPanelButtonTemplate")
    p250Btn:SetSize(48, 22)
    p250Btn:SetPoint("LEFT", p200Btn, "RIGHT", 5, 0)
    p250Btn:SetText("250%")
    p250Btn:SetScript("OnClick", function() mapScaleSlider:SetValue(2.50) end)

    local mapTip = card2_1:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    mapTip:SetPoint("TOPLEFT", 12, -76)
    mapTip:SetText("|cffffd100Map Zoom Tip:|r Hold |cffffffffCtrl + Mousewheel|r over the World Map to scale it in real-time!")

    local mapMoveCheck = CreateNativeCheckbox(card2_1, "Keep World Map open while running / walking",
        function() return Akimbo.db and Akimbo.db.preventMapCloseOnMove end,
        function(val)
            Akimbo.db.preventMapCloseOnMove = val
            if Akimbo.Canvas and Akimbo.Canvas.UpdateMapMovementBehavior then
                Akimbo.Canvas:UpdateMapMovementBehavior()
            end
        end
    )
    mapMoveCheck:SetPoint("TOPLEFT", 10, -98)

    local mapDesc = card2_1:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    mapDesc:SetPoint("TOPLEFT", 32, -124)
    local hasLMap = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Leatrix_Maps") or (IsAddOnLoaded and IsAddOnLoaded("Leatrix_Maps"))
    if hasLMap then
        mapDesc:SetText("|cff00ff00Leatrix Maps detected:|r Compatible with Leatrix.")
    else
        mapDesc:SetText("|cff888888Allows navigating with map open. (Compatible with Leatrix)|r")
    end


    local card2_2 = CreateCard(tab2, "Workspace Window Management & Persistence", -164, 190)

    local panelCheck = CreateNativeCheckbox(card2_2, "Keep panels placed on workspace open independently",
        function() return Akimbo.db and Akimbo.db.independentWorkspacePanels end,
        function(val) Akimbo.db.independentWorkspacePanels = val end
    )
    panelCheck:SetPoint("TOPLEFT", 10, -26)

    local panelDesc = card2_2:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    panelDesc:SetPoint("TOPLEFT", 32, -48)
    panelDesc:SetText("|cff888888Allows opening bags, character pane, spellbook & map simultaneously.|r")

    local escapeCheck = CreateNativeCheckbox(card2_2, "Keep workspace panels open when pressing Escape",
        function() return Akimbo.db and Akimbo.db.persistentWorkspacePanels ~= false end,
        function(val)
            Akimbo.db.persistentWorkspacePanels = val
            if Akimbo.Canvas and Akimbo.Canvas.UpdatePersistenceBehavior then
                Akimbo.Canvas:UpdatePersistenceBehavior()
            end
        end
    )
    escapeCheck:SetPoint("TOPLEFT", 10, -70)

    local escapeDesc = card2_2:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    escapeDesc:SetPoint("TOPLEFT", 32, -92)
    escapeDesc:SetText("|cff888888Escape clears targets or opens Game Menu without closing workspace elements.|r")

    local seamCheck = CreateNativeCheckbox(card2_2, "Reroute popups & dialogs away from center bezel",
        function() return Akimbo.db and Akimbo.db.seamRedirect end,
        function(val) Akimbo.db.seamRedirect = val end
    )
    seamCheck:SetPoint("TOPLEFT", 10, -114)

    local forceCheck = CreateNativeCheckbox(card2_2, "Force Dual Mode (Preview on single display)",
        function() return (Akimbo.db and Akimbo.db.forceDualOnSingle) or false end,
        function(val) Akimbo.db.forceDualOnSingle = val end
    )
    forceCheck:SetPoint("TOPLEFT", 10, -138)

    local compatDesc = card2_2:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    compatDesc:SetPoint("TOPLEFT", 12, -164)
    card2_2.compatDesc = compatDesc


    local card2_3 = CreateCard(tab2, "Bezel Compensation & Window Spanning", -366, 104)

    local bezelSlider = CreateNativeSlider(card2_3, "Bezel Compensation Gap", 0, 100, 2,
        function() return (Akimbo.db and Akimbo.db.bezelGap) or 0 end,
        function(val) Akimbo.db.bezelGap = val end,
        "%d px"
    )
    bezelSlider:SetPoint("TOPLEFT", 12, -44)
    bezelSlider:SetWidth(290)

    local guideLinkBtn = CreateFrame("Button", nil, card2_3, "UIPanelButtonTemplate")
    guideLinkBtn:SetSize(240, 24)
    guideLinkBtn:SetPoint("TOPLEFT", 350, -38)
    guideLinkBtn:SetText("View Window Spanning Guide")
    guideLinkBtn:SetScript("OnClick", function() Options:ShowSetupGuide() end)

    local bezelNote = card2_3:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    bezelNote:SetPoint("TOPLEFT", 12, -76)
    bezelNote:SetText("|cff888888Compensates for physical display monitor edges to align frames continuously.|r")

    -- ========================================================================
    -- TAB 3: THEMES & COLOR CUSTOMIZATION
    -- ========================================================================
    local card3_1 = CreateCard(tab3, "Visual Theme Preset", 0, 114)

    local rClassic = CreateNativeRadioButton(card3_1, "Classic Warcraft",
        function() return (Akimbo.db and Akimbo.db.theme == "CLASSIC") end,
        function()
            Akimbo.db.theme = "CLASSIC"
            Akimbo.db.trimColor = "GOLD"
            Akimbo:UpdateTheme()
        end
    )
    rClassic:SetPoint("TOPLEFT", 12, -26)

    local subClassic = card3_1:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subClassic:SetPoint("TOPLEFT", 34, -46)
    subClassic:SetText("|cff888888Authentic WoW dialog & gold trim|r")

    local rSlate = CreateNativeRadioButton(card3_1, "Blizzard Slate",
        function() return (Akimbo.db and Akimbo.db.theme == "BLIZZARD_SLATE") end,
        function()
            Akimbo.db.theme = "BLIZZARD_SLATE"
            Akimbo.db.trimColor = "SILVER"
            Akimbo:UpdateTheme()
        end
    )
    rSlate:SetPoint("TOPLEFT", 320, -26)

    local subSlate = card3_1:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subSlate:SetPoint("TOPLEFT", 342, -46)
    subSlate:SetText("|cff888888Charcoal dialog & pewter trim|r")

    local rObsidian = CreateNativeRadioButton(card3_1, "Obsidian Dark",
        function() return (Akimbo.db and Akimbo.db.theme == "OBSIDIAN") end,
        function()
            Akimbo.db.theme = "OBSIDIAN"
            Akimbo:UpdateTheme()
        end
    )
    rObsidian:SetPoint("TOPLEFT", 12, -68)

    local subObsidian = card3_1:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subObsidian:SetPoint("TOPLEFT", 34, -88)
    subObsidian:SetText("|cff888888Dark neutral slate workspace|r")

    local rPitchBlack = CreateNativeRadioButton(card3_1, "Pitch Black",
        function() return (Akimbo.db and Akimbo.db.theme == "PITCH_BLACK") end,
        function()
            Akimbo.db.theme = "PITCH_BLACK"
            Akimbo.db.canvasColor = "PURE_BLACK"
            Akimbo:UpdateTheme()
        end
    )
    rPitchBlack:SetPoint("TOPLEFT", 350, -68)

    local subPitchBlack = card3_1:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subPitchBlack:SetPoint("TOPLEFT", 372, -88)
    subPitchBlack:SetText("|cff888888True OLED pure black canvas|r")


    local card3_2 = CreateCard(tab3, "Dialog Header & Border Trim Palette", -132, 78)

    local trimButtons = {
        { "GOLD", "Blizzard Gold", 1.0, 0.82, 0.0 },
        { "SILVER", "Pewter Silver", 0.72, 0.75, 0.78 },
        { "BRONZE", "Warm Bronze", 0.85, 0.58, 0.25 },
        { "EMERALD", "Emerald Green", 0.22, 0.82, 0.35 },
        { "CRIMSON", "Crimson Red", 0.85, 0.22, 0.22 },
    }
    local prevTrimBtn = nil
    for _, t in ipairs(trimButtons) do
        local btn = CreateFrame("Button", nil, card3_2, "UIPanelButtonTemplate")
        btn:SetSize(126, 24)
        if not prevTrimBtn then
            btn:SetPoint("TOPLEFT", 12, -32)
        else
            btn:SetPoint("LEFT", prevTrimBtn, "RIGHT", 8, 0)
        end
        btn:SetText(string.format("|cff%02x%02x%02x%s|r", t[3]*255, t[4]*255, t[5]*255, t[2]))
        local trimKey = t[1]
        btn:SetScript("OnClick", function()
            Akimbo.db.trimColor = trimKey
            Akimbo:UpdateTheme()
            Options:RefreshPanel()
        end)
        prevTrimBtn = btn
    end


    local card3_3 = CreateCard(tab3, "Workspace Canvas Background (Secondary Monitor)", -224, 154)

    local canvasButtons = {
        { "CHARCOAL", "Charcoal Slate", 0.07, 0.08, 0.09 },
        { "WARM_NIGHT", "Warm Night", 0.08, 0.07, 0.06 },
        { "PURE_BLACK", "Pitch Black", 0.00, 0.00, 0.00 },
        { "DEEP_BLUE", "Midnight Navy", 0.05, 0.06, 0.10 },
    }
    local prevCanvasBtn = nil
    for _, c in ipairs(canvasButtons) do
        local btn = CreateFrame("Button", nil, card3_3, "UIPanelButtonTemplate")
        btn:SetSize(156, 24)
        if not prevCanvasBtn then
            btn:SetPoint("TOPLEFT", 12, -32)
        else
            btn:SetPoint("LEFT", prevCanvasBtn, "RIGHT", 10, 0)
        end
        btn:SetText(c[2])
        local canvasKey = c[1]
        btn:SetScript("OnClick", function()
            Akimbo.db.canvasColor = canvasKey
            Akimbo:UpdateTheme()
            Options:RefreshPanel()
        end)
        prevCanvasBtn = btn
    end

    local alphaSlider = CreateNativeSlider(card3_3, "Workspace Background Opacity", 0.20, 1.0, 0.05,
        function() return (Akimbo.db and Akimbo.db.canvasAlpha) or 0.95 end,
        function(val)
            Akimbo.db.canvasAlpha = val
            Akimbo:UpdateTheme()
        end,
        "%.0f%%"
    )
    alphaSlider:SetPoint("TOPLEFT", 12, -80)
    alphaSlider:SetWidth(350)

    local themeNote = card3_3:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    themeNote:SetPoint("TOPLEFT", 12, -118)
    themeNote:SetText("|cff888888Theme and background colors apply immediately to your secondary workspace.|r")

    -- ========================================================================
    -- BOTTOM ACTION BAR (Shared across tabs)
    -- ========================================================================
    local applyBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    applyBtn:SetSize(150, 28)
    applyBtn:SetPoint("BOTTOMLEFT", 20, 14)
    applyBtn:SetText("Apply Layout")
    applyBtn:SetScript("OnClick", function()
        Akimbo:ApplyFullLayout()
        Akimbo:Print("Layout applied successfully.")
    end)

    local closePanelBtn = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    closePanelBtn:SetSize(150, 28)
    closePanelBtn:SetPoint("BOTTOMRIGHT", -20, 14)
    closePanelBtn:SetText("|cffffd100Save & Close|r")
    closePanelBtn:SetScript("OnClick", function()
        Options:Close()
    end)

    function Options:RefreshPanel()
        if not configFrame then return end
        local info = Options:DetectTopology()
        banner:SetText(string.format("|cffffd100Display:|r %s  |cffffd100Window:|r %dx%d (AR %.2f:1)",
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
        escapeCheck:SetChecked((Akimbo.db and Akimbo.db.persistentWorkspacePanels ~= false) or false)
        forceCheck:SetChecked((Akimbo.db and Akimbo.db.forceDualOnSingle) or false)

        local curTheme = (Akimbo.db and Akimbo.db.theme) or "CLASSIC"
        rClassic:SetChecked(curTheme == "CLASSIC")
        rSlate:SetChecked(curTheme == "BLIZZARD_SLATE")
        rObsidian:SetChecked(curTheme == "OBSIDIAN")
        rPitchBlack:SetChecked(curTheme == "PITCH_BLACK")

        bezelSlider:UpdateText()
        alphaSlider:UpdateText()
        hudSlider:UpdateText()
        mapScaleSlider:UpdateText()

        local bagAddon = Akimbo.HasCustomBagAddon and Akimbo.HasCustomBagAddon()
        local mmAddon = Akimbo.HasCustomMinimapAddon and Akimbo.HasCustomMinimapAddon()
        if card2_2.compatDesc then
            if bagAddon and mmAddon then
                card2_2.compatDesc:SetText("|cff00ff00Addon Compatibility:|r Custom Bag & Minimap addons active (control yielded).")
            elseif bagAddon then
                card2_2.compatDesc:SetText("|cff00ff00Addon Compatibility:|r Custom Bag addon active (control yielded).")
            elseif mmAddon then
                card2_2.compatDesc:SetText("|cff00ff00Addon Compatibility:|r Custom Minimap addon active (control yielded).")
            else
                card2_2.compatDesc:SetText("|cff888888Auto-detects Bagnon, SexyMap, AdiBags, ElvUI, etc. to prevent conflicts.|r")
            end
        end

        Options:UpdateCardThemes()
        Akimbo:ApplyFullLayout()
    end

    SwitchTab(currentTab or 1)
    Options:UpdateCardThemes()
    configFrame:Hide()
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
