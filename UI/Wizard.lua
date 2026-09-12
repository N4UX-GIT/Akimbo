--[[
    Akimbo: Dual Monitor Workstation Addon
    UI/Wizard.lua: Visual 1-Click Auto-Configuration Wizard & Display Calibration
    Provides an authentic Classic WoW dialog for 1-click display setup, physical seam calibration,
    and fine continuous Global UI Scale adjustment.
--]]

local _, Akimbo = ...

local L = Akimbo.L or setmetatable({}, {
    __index = function(t, key)
        return key
    end
})

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
    card:SetSize(628, height)
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
    f:SetSize(668, 672)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
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
        Akimbo.Themes:ApplyBackdrop(f, (Akimbo.db and Akimbo.db.theme) or "CLASSIC", 1.0)
    end
    if Akimbo.Themes and Akimbo.Themes.CreateBayHeader then
        f.header = Akimbo.Themes:CreateBayHeader(f, L["WIZARD_TITLE"])
    end

    local closeBtn = CreateFrame("Button", nil, f.header or f, "UIPanelCloseButton")
    closeBtn:SetSize(28, 28)
    if f.header then
        closeBtn:SetPoint("RIGHT", f.header, "RIGHT", -4, 0)
    else
        closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    end
    closeBtn:SetScript("OnClick", function()
        Wizard:Close()
        if Wizard.openedFromOptions then
            Wizard.openedFromOptions = false
            if Akimbo.Options and Akimbo.Options.Open then
                Akimbo.Options:Open()
            end
        end
    end)
    if Akimbo.SetTooltip then
        Akimbo:SetTooltip(closeBtn, "Close Wizard", "Close the setup wizard without saving new preferences.")
    end

    f:SetScript("OnHide", function()
        if Akimbo.Options and Akimbo.Options.HideSeamGuide then
            Akimbo.Options:HideSeamGuide()
        end
    end)

    -- ========================================================================
    -- CARD 1: DISPLAY TOPOLOGY & 1-CLICK AUTO-SETUP
    -- ========================================================================
    local card1 = CreateWizardCard(f, L["WIZARD_CARD1_TITLE"], -56, 132)

    local logoIcon = card1:CreateTexture(nil, "ARTWORK")
    local textLeft = 14
    if logoIcon and logoIcon.SetSize and logoIcon.SetPoint and logoIcon.SetTexture then
        logoIcon:SetSize(38, 38)
        logoIcon:SetPoint("TOPLEFT", 14, -28)
        logoIcon:SetTexture("Interface\\AddOns\\Akimbo\\Media\\akimbo-logo")
        card1.logoIcon = logoIcon
        textLeft = 60
    end

    local topoText = card1:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    topoText:SetPoint("TOPLEFT", textLeft, -28)
    topoText:SetPoint("TOPRIGHT", -14, -28)
    topoText:SetJustifyH("LEFT")
    f.topoText = topoText

    local recomText = card1:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    recomText:SetPoint("TOPLEFT", textLeft, -48)
    recomText:SetPoint("TOPRIGHT", -14, -48)
    recomText:SetJustifyH("LEFT")
    f.recomText = recomText

    local autoBtn = CreateFrame("Button", nil, card1, "UIPanelButtonTemplate")
    autoBtn:SetSize(608, 28)
    autoBtn:SetPoint("TOPLEFT", 14, -72)
    autoBtn:SetText("|cff00ff00" .. L["WIZARD_BTN_AUTOCONFIG"] .. "|r")
    if Akimbo.SetTooltip then
        Akimbo:SetTooltip(autoBtn, L["WIZARD_BTN_AUTOCONFIG_TIP_TITLE"], L["WIZARD_BTN_AUTOCONFIG_TIP_DESC"])
    end
    f.autoBtn = autoBtn

    local statusText = card1:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    statusText:SetPoint("TOPLEFT", 14, -106)
    statusText:SetPoint("TOPRIGHT", -14, -106)
    statusText:SetJustifyH("CENTER")
    statusText:SetText(L["WIZARD_STATUS_READY"])
    f.statusText = statusText

    autoBtn:SetScript("OnClick", function()
        if Akimbo.Options and Akimbo.Options.AutoConfigure then
            local info = Akimbo.Options:AutoConfigure(false)
            f:UpdateState()
            statusText:SetText(string.format("|cff00ff00[Applied]|r " .. (L["WIZARD_STATUS_APPLIED"] and string.format(L["WIZARD_STATUS_APPLIED"], info.description) or "Setup automatically configured for " .. info.description)))
        end
    end)

    -- ========================================================================
    -- CARD 2: MONITOR ORIENTATION & 3D VIEWPORT
    -- ========================================================================
    local card2 = CreateWizardCard(f, L["WIZARD_CARD2_TITLE"], -196, 138)

    local orientLabel = card2:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    orientLabel:SetPoint("TOPLEFT", 14, -28)
    orientLabel:SetText(L["WIZARD_LABEL_LAYOUT"])

    local btnPl = CreateFrame("Button", nil, card2, "UIPanelButtonTemplate")
    btnPl:SetSize(196, 24)
    btnPl:SetPoint("TOPLEFT", 14, -46)
    btnPl:SetText(L["PRESET_PL_LR"])
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btnPl, L["PRESET_PL_LR_TIP_TITLE"], L["PRESET_PL_LR_TIP_DESC"]) end

    local btnPr = CreateFrame("Button", nil, card2, "UIPanelButtonTemplate")
    btnPr:SetSize(196, 24)
    btnPr:SetPoint("LEFT", btnPl, "RIGHT", 10, 0)
    btnPr:SetText(L["PRESET_GL_PR"])
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btnPr, L["PRESET_GL_PR_TIP_TITLE"], L["PRESET_GL_PR_TIP_DESC"]) end

    local btnDual = CreateFrame("Button", nil, card2, "UIPanelButtonTemplate")
    btnDual:SetSize(196, 24)
    btnDual:SetPoint("LEFT", btnPr, "RIGHT", 10, 0)
    btnDual:SetText(L["PRESET_DUAL_LANDSCAPE"])
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btnDual, L["PRESET_DUAL_LANDSCAPE_TIP_TITLE"], L["PRESET_DUAL_LANDSCAPE_TIP_DESC"]) end

    local arLabel = card2:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    arLabel:SetPoint("TOPLEFT", 14, -80)
    arLabel:SetText(L["WIZARD_LABEL_AR"])

    local btn169 = CreateFrame("Button", nil, card2, "UIPanelButtonTemplate")
    btn169:SetSize(196, 24)
    btn169:SetPoint("TOPLEFT", 14, -98)
    btn169:SetText(L["AR_16_9"])
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btn169, L["AR_16_9_TIP_TITLE"], L["AR_16_9_TIP_DESC"]) end

    local btn219 = CreateFrame("Button", nil, card2, "UIPanelButtonTemplate")
    btn219:SetSize(196, 24)
    btn219:SetPoint("LEFT", btn169, "RIGHT", 10, 0)
    btn219:SetText(L["AR_21_9"])
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btn219, L["AR_21_9_TIP_TITLE"], L["AR_21_9_TIP_DESC"]) end

    local btnFill = CreateFrame("Button", nil, card2, "UIPanelButtonTemplate")
    btnFill:SetSize(196, 24)
    btnFill:SetPoint("LEFT", btn219, "RIGHT", 10, 0)
    btnFill:SetText(L["AR_FILL"])
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btnFill, L["AR_FILL_TIP_TITLE"], L["AR_FILL_TIP_DESC"]) end

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
    local card3 = CreateWizardCard(f, L["WIZARD_CARD3_TITLE"], -342, 136)

    local seamHelp = card3:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    seamHelp:SetPoint("TOPLEFT", 14, -28)
    seamHelp:SetPoint("TOPRIGHT", -14, -28)
    seamHelp:SetJustifyH("LEFT")
    seamHelp:SetText(L["WIZARD_SEAM_INSTRUCTION"])

    local seamTitle = card3:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    seamTitle:SetPoint("TOPLEFT", 14, -48)
    seamTitle:SetText(L["WIZARD_LABEL_SEAM"])

    local seamEditBox = CreateFrame("EditBox", nil, card3, "BackdropTemplate")
    seamEditBox:SetSize(60, 20)
    seamEditBox:SetPoint("LEFT", seamTitle, "RIGHT", 10, 0)
    seamEditBox:SetAutoFocus(false)
    if seamEditBox.SetFontObject then seamEditBox:SetFontObject("GameFontHighlightSmall") end
    if seamEditBox.SetJustifyH then seamEditBox:SetJustifyH("CENTER") end
    if seamEditBox.SetBackdrop then
        seamEditBox:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        seamEditBox:SetBackdropColor(0.04, 0.04, 0.06, 0.9)
        seamEditBox:SetBackdropBorderColor(0.35, 0.33, 0.28, 0.9)
    end
    seamEditBox:SetText(string.format("%.1f%%", ((Akimbo.db and Akimbo.db.deckWidthRatio) or 0.36) * 100))
    f.seamEditBox = seamEditBox
    if Akimbo.SetTooltip then
        Akimbo:SetTooltip(seamEditBox, "Manual Seam Width Entry", "Type a percentage (e.g. 36%) or ratio (e.g. 0.36) and press Enter.")
    end

    local seamValText = card3:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    seamValText:SetPoint("LEFT", seamEditBox, "RIGHT", 8, 0)
    seamValText:SetText(string.format("Seam: %.1f%%", ((Akimbo.db and Akimbo.db.deckWidthRatio) or 0.36) * 100))
    f.seamValText = seamValText

    -- Seam Slider
    local seamSlider = CreateFrame("Slider", nil, card3, "BackdropTemplate")
    seamSlider:SetOrientation("HORIZONTAL")
    seamSlider:SetSize(280, 16)
    seamSlider:SetPoint("TOPLEFT", 14, -68)
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
    seamSlider:SetBackdropColor(0.06, 0.06, 0.08, 0.95)
    seamSlider:SetBackdropBorderColor(0.40, 0.38, 0.30, 0.9)

    local thumb = seamSlider:CreateTexture(nil, "OVERLAY")
    if thumb and thumb.SetTexture then
        thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    elseif thumb and thumb.SetColorTexture then
        thumb:SetColorTexture(1.0, 0.82, 0.0, 1.0)
    end
    if thumb and thumb.SetSize then
        thumb:SetSize(18, 20)
    end
    seamSlider:SetThumbTexture(thumb)
    seamSlider.thumb = thumb

    seamSlider.SetValueDirect = function(self, val)
        self._isDirect = true
        self:SetValue(val)
        self._isDirect = nil
    end

    local function CommitSeamEditBox()
        local txt = seamEditBox:GetText()
        local parsed = Akimbo.ParseSliderInput and Akimbo:ParseSliderInput(txt, 0.15, 0.80, 0.005, "%.1f%%")
        if parsed then
            seamSlider:SetValueDirect(parsed)
        else
            local cur = (Akimbo.db and Akimbo.db.deckWidthRatio) or 0.36
            seamEditBox:SetText(string.format("%.1f%%", cur * 100))
        end
        if seamEditBox.ClearFocus then seamEditBox:ClearFocus() end
    end

    seamEditBox:SetScript("OnEnterPressed", function() CommitSeamEditBox() end)
    seamEditBox:SetScript("OnEscapePressed", function(s)
        local cur = (Akimbo.db and Akimbo.db.deckWidthRatio) or 0.36
        s:SetText(string.format("%.1f%%", cur * 100))
        if s.ClearFocus then s:ClearFocus() end
    end)
    seamEditBox:SetScript("OnEditFocusLost", function(s)
        CommitSeamEditBox()
        if s.SetBackdropBorderColor then s:SetBackdropBorderColor(0.35, 0.33, 0.28, 0.9) end
    end)
    seamEditBox:SetScript("OnEditFocusGained", function(s)
        if s.HighlightText then s:HighlightText() end
        if s.SetBackdropBorderColor then s:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0) end
    end)

    local btnMinus = CreateFrame("Button", nil, card3, "UIPanelButtonTemplate")
    btnMinus:SetSize(46, 22)
    btnMinus:SetPoint("LEFT", seamSlider, "RIGHT", 12, 0)
    btnMinus:SetText(L["BTN_SEAM_MINUS"])
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btnMinus, L["BTN_SEAM_MINUS_TIP_TITLE"], L["BTN_SEAM_MINUS_TIP_DESC"]) end

    local btnPlus = CreateFrame("Button", nil, card3, "UIPanelButtonTemplate")
    btnPlus:SetSize(46, 22)
    btnPlus:SetPoint("LEFT", btnMinus, "RIGHT", 4, 0)
    btnPlus:SetText(L["BTN_SEAM_PLUS"])
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btnPlus, L["BTN_SEAM_PLUS_TIP_TITLE"], L["BTN_SEAM_PLUS_TIP_DESC"]) end

    local btnLaser = CreateFrame("Button", nil, card3, "UIPanelButtonTemplate")
    btnLaser:SetSize(138, 22)
    btnLaser:SetPoint("LEFT", btnPlus, "RIGHT", 12, 0)
    btnLaser:SetText(L["BTN_LASER_TOGGLE"])
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btnLaser, L["BTN_LASER_TOGGLE_TIP_TITLE"], L["BTN_LASER_TOGGLE_TIP_DESC"]) end

    seamSlider:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then self.isDragging = true end
    end)

    seamSlider:SetScript("OnMouseUp", function(self, button)
        self.isDragging = false
        if self._pendingApply then
            self._pendingApply = false
            self:SetScript("OnUpdate", nil)
            Akimbo:ApplyFullLayout()
        end
    end)

    seamSlider:SetScript("OnValueChanged", function(self, val, userInput)
        val = math.floor((val / 0.005) + 0.5) * 0.005
        Akimbo.db.deckWidthRatio = val
        seamValText:SetText(string.format("Seam: %.1f%%", val * 100))
        if seamEditBox and not (seamEditBox.HasFocus and seamEditBox:HasFocus()) then
            seamEditBox:SetText(string.format("%.1f%%", val * 100))
        end
        if Akimbo.Options and Akimbo.Options.ShowSeamGuide and Akimbo.Options:IsSeamGuideShown() then
            Akimbo.Options:ShowSeamGuide(val)
        end
        f:UpdateLaserButton()

        if self._isDirect then
            self._pendingApply = false
            self:SetScript("OnUpdate", nil)
            Akimbo:ApplyFullLayout()
            return
        end

        local isMouseDown = (IsMouseButtonDown and IsMouseButtonDown("LeftButton")) or (self.isDragging == true) or (userInput == true)
        if isMouseDown then
            self._pendingApply = true
            self:SetScript("OnUpdate", function(s)
                local stillDown = (IsMouseButtonDown and IsMouseButtonDown("LeftButton"))
                if not stillDown then
                    s.isDragging = false
                    if s._pendingApply then
                        s._pendingApply = false
                        s:SetScript("OnUpdate", nil)
                        Akimbo:ApplyFullLayout()
                    end
                end
            end)
        else
            self._pendingApply = false
            self:SetScript("OnUpdate", nil)
            Akimbo:ApplyFullLayout()
        end
    end)
    if Akimbo.SetTooltip then Akimbo:SetTooltip(seamSlider, L["SLIDER_SEAM_WIDTH_TIP_TITLE"], L["SLIDER_SEAM_WIDTH_TIP_DESC"]) end

    btnMinus:SetScript("OnClick", function()
        local current = seamSlider:GetValue() or 0.36
        seamSlider:SetValueDirect(math.max(0.15, current - 0.01))
    end)

    btnPlus:SetScript("OnClick", function()
        local current = seamSlider:GetValue() or 0.36
        seamSlider:SetValueDirect(math.min(0.80, current + 0.01))
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
    btnSeam36:SetSize(196, 24)
    btnSeam36:SetPoint("TOPLEFT", 14, -98)
    btnSeam36:SetText(L["WIZARD_PRESET_SEAM_36"])
    btnSeam36:SetScript("OnClick", function() seamSlider:SetValue(0.36) end)
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btnSeam36, L["WIZARD_PRESET_SEAM_36_TIP_TITLE"], L["WIZARD_PRESET_SEAM_36_TIP_DESC"]) end

    local btnSeam50 = CreateFrame("Button", nil, card3, "UIPanelButtonTemplate")
    btnSeam50:SetSize(196, 24)
    btnSeam50:SetPoint("LEFT", btnSeam36, "RIGHT", 10, 0)
    btnSeam50:SetText(L["WIZARD_PRESET_SEAM_50"])
    btnSeam50:SetScript("OnClick", function() seamSlider:SetValue(0.50) end)
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btnSeam50, L["WIZARD_PRESET_SEAM_50_TIP_TITLE"], L["WIZARD_PRESET_SEAM_50_TIP_DESC"]) end

    local btnSeam55 = CreateFrame("Button", nil, card3, "UIPanelButtonTemplate")
    btnSeam55:SetSize(196, 24)
    btnSeam55:SetPoint("LEFT", btnSeam50, "RIGHT", 10, 0)
    btnSeam55:SetText(L["WIZARD_PRESET_SEAM_55"])
    btnSeam55:SetScript("OnClick", function() seamSlider:SetValue(0.55) end)
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btnSeam55, L["WIZARD_PRESET_SEAM_55_TIP_TITLE"], L["WIZARD_PRESET_SEAM_55_TIP_DESC"]) end

    -- ========================================================================
    -- CARD 4: GLOBAL UI SCALE & CALIBRATION (CONTINUOUS SLIDER)
    -- ========================================================================
    local card4 = CreateWizardCard(f, L["WIZARD_CARD4_TITLE"], -486, 136)

    local scaleHelp = card4:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    scaleHelp:SetPoint("TOPLEFT", 14, -28)
    scaleHelp:SetPoint("TOPRIGHT", -14, -28)
    scaleHelp:SetJustifyH("LEFT")
    scaleHelp:SetText(L["WIZARD_UI_SCALE_INSTRUCTION"])

    local scaleTitle = card4:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    scaleTitle:SetPoint("TOPLEFT", 14, -48)
    scaleTitle:SetText(L["WIZARD_LABEL_UI_SCALE"])

    local scaleEditBox = CreateFrame("EditBox", nil, card4, "BackdropTemplate")
    scaleEditBox:SetSize(60, 20)
    scaleEditBox:SetPoint("LEFT", scaleTitle, "RIGHT", 10, 0)
    scaleEditBox:SetAutoFocus(false)
    if scaleEditBox.SetFontObject then scaleEditBox:SetFontObject("GameFontHighlightSmall") end
    if scaleEditBox.SetJustifyH then scaleEditBox:SetJustifyH("CENTER") end
    if scaleEditBox.SetBackdrop then
        scaleEditBox:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        scaleEditBox:SetBackdropColor(0.04, 0.04, 0.06, 0.9)
        scaleEditBox:SetBackdropBorderColor(0.35, 0.33, 0.28, 0.9)
    end
    scaleEditBox:SetText(string.format("%.0f%%", ((Akimbo.db and Akimbo.db.hudScale) or 0.70) * 100))
    f.scaleEditBox = scaleEditBox
    if Akimbo.SetTooltip then
        Akimbo:SetTooltip(scaleEditBox, "Manual UI Scale Entry", "Type a percentage (e.g. 70%) or number (e.g. 0.70) and press Enter.")
    end

    local scaleValText = card4:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    scaleValText:SetPoint("LEFT", scaleEditBox, "RIGHT", 8, 0)
    scaleValText:SetText(string.format("Scale: %.0f%%", ((Akimbo.db and Akimbo.db.hudScale) or 0.70) * 100))
    f.scaleValText = scaleValText

    -- Continuous UI Scale Slider
    local scaleSlider = CreateFrame("Slider", nil, card4, "BackdropTemplate")
    scaleSlider:SetOrientation("HORIZONTAL")
    scaleSlider:SetSize(280, 16)
    scaleSlider:SetPoint("TOPLEFT", 14, -68)
    scaleSlider:SetMinMaxValues(0.25, 1.25)
    scaleSlider:SetValueStep(0.01)
    scaleSlider:SetObeyStepOnDrag(true)
    scaleSlider:EnableMouse(true)
    scaleSlider:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    scaleSlider:SetBackdropColor(0.06, 0.06, 0.08, 0.95)
    scaleSlider:SetBackdropBorderColor(0.40, 0.38, 0.30, 0.9)

    local scaleThumb = scaleSlider:CreateTexture(nil, "OVERLAY")
    if scaleThumb and scaleThumb.SetTexture then
        thumb = scaleThumb
        scaleThumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    elseif scaleThumb and scaleThumb.SetColorTexture then
        scaleThumb:SetColorTexture(1.0, 0.82, 0.0, 1.0)
    end
    if scaleThumb and scaleThumb.SetSize then
        scaleThumb:SetSize(18, 20)
    end
    scaleSlider:SetThumbTexture(scaleThumb)
    scaleSlider.thumb = scaleThumb

    scaleSlider.SetValueDirect = function(self, val)
        self._isDirect = true
        self:SetValue(val)
        self._isDirect = nil
    end

    local function CommitScaleEditBox()
        local txt = scaleEditBox:GetText()
        local parsed = Akimbo.ParseSliderInput and Akimbo:ParseSliderInput(txt, 0.25, 1.25, 0.01, "%.0f%%")
        if parsed then
            scaleSlider:SetValueDirect(parsed)
        else
            local cur = (Akimbo.db and Akimbo.db.hudScale) or 0.70
            scaleEditBox:SetText(string.format("%.0f%%", cur * 100))
        end
        if scaleEditBox.ClearFocus then scaleEditBox:ClearFocus() end
    end

    scaleEditBox:SetScript("OnEnterPressed", function() CommitScaleEditBox() end)
    scaleEditBox:SetScript("OnEscapePressed", function(s)
        local cur = (Akimbo.db and Akimbo.db.hudScale) or 0.70
        s:SetText(string.format("%.0f%%", cur * 100))
        if s.ClearFocus then s:ClearFocus() end
    end)
    scaleEditBox:SetScript("OnEditFocusLost", function(s)
        CommitScaleEditBox()
        if s.SetBackdropBorderColor then s:SetBackdropBorderColor(0.35, 0.33, 0.28, 0.9) end
    end)
    scaleEditBox:SetScript("OnEditFocusGained", function(s)
        if s.HighlightText then s:HighlightText() end
        if s.SetBackdropBorderColor then s:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0) end
    end)

    local btnScaleMinus = CreateFrame("Button", nil, card4, "UIPanelButtonTemplate")
    btnScaleMinus:SetSize(46, 22)
    btnScaleMinus:SetPoint("LEFT", scaleSlider, "RIGHT", 12, 0)
    btnScaleMinus:SetText("- 1%")
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btnScaleMinus, "Scale Down", "Decreases the global UI scale by 1%.") end

    local btnScalePlus = CreateFrame("Button", nil, card4, "UIPanelButtonTemplate")
    btnScalePlus:SetSize(46, 22)
    btnScalePlus:SetPoint("LEFT", btnScaleMinus, "RIGHT", 4, 0)
    btnScalePlus:SetText("+ 1%")
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btnScalePlus, "Scale Up", "Increases the global UI scale by 1%.") end

    local btnScaleReset = CreateFrame("Button", nil, card4, "UIPanelButtonTemplate")
    btnScaleReset:SetSize(138, 22)
    btnScaleReset:SetPoint("LEFT", btnScalePlus, "RIGHT", 12, 0)
    btnScaleReset:SetText("Reset (70%)")
    btnScaleReset:SetScript("OnClick", function()
        scaleSlider:SetValueDirect(0.70)
    end)
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btnScaleReset, "Reset UI Scale", "Resets the Global UI Scale to the recommended standard default of 70%.") end

    scaleSlider:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then self.isDragging = true end
    end)

    scaleSlider:SetScript("OnMouseUp", function(self, button)
        self.isDragging = false
        if self._pendingApply then
            self._pendingApply = false
            self:SetScript("OnUpdate", nil)
            Akimbo:ApplyFullLayout()
        end
    end)

    scaleSlider:SetScript("OnValueChanged", function(self, val, userInput)
        val = math.floor((val / 0.01) + 0.5) * 0.01
        Akimbo.db.hudScale = val
        scaleValText:SetText(string.format("Scale: %.0f%%", val * 100))
        if scaleEditBox and not (scaleEditBox.HasFocus and scaleEditBox:HasFocus()) then
            scaleEditBox:SetText(string.format("%.0f%%", val * 100))
        end

        if self._isDirect then
            self._pendingApply = false
            self:SetScript("OnUpdate", nil)
            Akimbo:ApplyFullLayout()
            return
        end

        local isMouseDown = (IsMouseButtonDown and IsMouseButtonDown("LeftButton")) or (self.isDragging == true) or (userInput == true)
        if isMouseDown then
            self._pendingApply = true
            self:SetScript("OnUpdate", function(s)
                local stillDown = (IsMouseButtonDown and IsMouseButtonDown("LeftButton"))
                if not stillDown then
                    s.isDragging = false
                    if s._pendingApply then
                        s._pendingApply = false
                        s:SetScript("OnUpdate", nil)
                        Akimbo:ApplyFullLayout()
                    end
                end
            end)
        else
            self._pendingApply = false
            self:SetScript("OnUpdate", nil)
            Akimbo:ApplyFullLayout()
        end
    end)
    if Akimbo.SetTooltip then Akimbo:SetTooltip(scaleSlider, L["WIZARD_UI_SCALE_TIP_TITLE"], L["WIZARD_UI_SCALE_TIP_DESC"]) end

    btnScaleMinus:SetScript("OnClick", function()
        local current = scaleSlider:GetValue() or 0.70
        scaleSlider:SetValueDirect(math.max(0.25, current - 0.01))
    end)

    btnScalePlus:SetScript("OnClick", function()
        local current = scaleSlider:GetValue() or 0.70
        scaleSlider:SetValueDirect(math.min(1.25, current + 0.01))
    end)

    -- Quick Scale Preset Buttons
    local btnHud56 = CreateFrame("Button", nil, card4, "UIPanelButtonTemplate")
    btnHud56:SetSize(145, 24)
    btnHud56:SetPoint("TOPLEFT", 14, -98)
    btnHud56:SetText(L["WIZARD_PRESET_SCALE_56"])
    btnHud56:SetScript("OnClick", function() scaleSlider:SetValueDirect(0.56) end)
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btnHud56, L["WIZARD_PRESET_SCALE_56_TIP_TITLE"], L["WIZARD_PRESET_SCALE_56_TIP_DESC"]) end

    local btnHud65 = CreateFrame("Button", nil, card4, "UIPanelButtonTemplate")
    btnHud65:SetSize(145, 24)
    btnHud65:SetPoint("LEFT", btnHud56, "RIGHT", 9, 0)
    btnHud65:SetText(L["WIZARD_PRESET_SCALE_65"])
    btnHud65:SetScript("OnClick", function() scaleSlider:SetValueDirect(0.65) end)
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btnHud65, L["WIZARD_PRESET_SCALE_65_TIP_TITLE"], L["WIZARD_PRESET_SCALE_65_TIP_DESC"]) end

    local btnHud70 = CreateFrame("Button", nil, card4, "UIPanelButtonTemplate")
    btnHud70:SetSize(145, 24)
    btnHud70:SetPoint("LEFT", btnHud65, "RIGHT", 9, 0)
    btnHud70:SetText(L["WIZARD_PRESET_SCALE_70"])
    btnHud70:SetScript("OnClick", function() scaleSlider:SetValueDirect(0.70) end)
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btnHud70, L["WIZARD_PRESET_SCALE_70_TIP_TITLE"], L["WIZARD_PRESET_SCALE_70_TIP_DESC"]) end

    local btnHud100 = CreateFrame("Button", nil, card4, "UIPanelButtonTemplate")
    btnHud100:SetSize(145, 24)
    btnHud100:SetPoint("LEFT", btnHud70, "RIGHT", 9, 0)
    btnHud100:SetText(L["WIZARD_PRESET_SCALE_100"])
    btnHud100:SetScript("OnClick", function() scaleSlider:SetValueDirect(1.00) end)
    if Akimbo.SetTooltip then Akimbo:SetTooltip(btnHud100, L["WIZARD_PRESET_SCALE_100_TIP_TITLE"], L["WIZARD_PRESET_SCALE_100_TIP_DESC"]) end

    -- ========================================================================
    -- FOOTER ACTIONS
    -- ========================================================================
    local advBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    advBtn:SetSize(280, 28)
    advBtn:SetPoint("BOTTOMLEFT", 18, 14)
    advBtn:SetText(L["WIZARD_BTN_ADVANCED"])
    advBtn:SetScript("OnClick", function()
        Wizard.openedFromOptions = false
        Wizard:Close()
        if Akimbo.Options and Akimbo.Options.Open then
            Akimbo.Options:Open()
        end
    end)
    if Akimbo.SetTooltip then Akimbo:SetTooltip(advBtn, L["WIZARD_BTN_ADVANCED_TIP_TITLE"], L["WIZARD_BTN_ADVANCED_TIP_DESC"]) end

    local finishBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    finishBtn:SetSize(280, 28)
    finishBtn:SetPoint("BOTTOMRIGHT", -18, 14)
    finishBtn:SetText("|cffffd100" .. L["WIZARD_BTN_FINISH"] .. "|r")
    finishBtn:SetScript("OnClick", function()
        if Akimbo.db then
            Akimbo.db.firstRunComplete = true
        end
        Wizard.openedFromOptions = false
        Wizard:Close()
        Akimbo:ApplyFullLayout()
        if Akimbo.Print then
            Akimbo:Print(L["CONFIG_SAVED"] or "Configuration saved! Welcome to Akimbo Dual Monitor Workstation.")
        end
    end)
    if Akimbo.SetTooltip then Akimbo:SetTooltip(finishBtn, L["WIZARD_BTN_FINISH_TIP_TITLE"], L["WIZARD_BTN_FINISH_TIP_DESC"]) end

    function f:UpdateLaserButton()
        local isShown = Akimbo.Options and Akimbo.Options.IsSeamGuideShown and Akimbo.Options:IsSeamGuideShown()
        btnLaser:SetText(isShown and ("|cffff3333" .. L["WIZARD_BTN_LASER_HIDE"] .. "|r") or L["WIZARD_BTN_LASER_SHOW"])
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
        if seamEditBox and not (seamEditBox.HasFocus and seamEditBox:HasFocus()) then
            seamEditBox:SetText(string.format("%.1f%%", seam * 100))
        end

        scaleSlider:SetValue(hud)
        scaleValText:SetText(string.format("Scale: %.0f%%", hud * 100))
        if scaleEditBox and not (scaleEditBox.HasFocus and scaleEditBox:HasFocus()) then
            scaleEditBox:SetText(string.format("%.0f%%", hud * 100))
        end

        btnPl:SetEnabled(not (p == "PORTRAIT_LEFT_LANDSCAPE_RIGHT" and pos == "RIGHT"))
        btnPr:SetEnabled(not (p == "PORTRAIT_LEFT_LANDSCAPE_RIGHT" and pos == "LEFT"))
        btnDual:SetEnabled(not (p == "LANDSCAPE_DUAL"))

        btn169:SetEnabled(ar ~= "16_9")
        btn219:SetEnabled(ar ~= "21_9")
        btnFill:SetEnabled(ar ~= "FILL")

        btnHud56:SetEnabled(math.abs(hud - 0.56) > 0.02)
        btnHud65:SetEnabled(math.abs(hud - 0.65) > 0.02)
        btnHud70:SetEnabled(math.abs(hud - 0.70) > 0.02)
        btnHud100:SetEnabled(math.abs(hud - 1.00) > 0.02)

        local trimKey = (Akimbo.db and Akimbo.db.trimColor) or "GOLD"
        local pals = Akimbo.Themes and Akimbo.Themes.GetColorPalettes and Akimbo.Themes:GetColorPalettes()
        local c = pals and pals[trimKey]
        if c then
            if seamSlider.thumb and seamSlider.thumb.SetVertexColor then
                seamSlider.thumb:SetVertexColor(c.r, c.g, c.b, 1.0)
            end
            if scaleSlider.thumb and scaleSlider.thumb.SetVertexColor then
                scaleSlider.thumb:SetVertexColor(c.r, c.g, c.b, 1.0)
            end
        else
            if seamSlider.thumb and seamSlider.thumb.SetVertexColor then
                seamSlider.thumb:SetVertexColor(1.0, 0.82, 0.0, 1.0)
            end
            if scaleSlider.thumb and scaleSlider.thumb.SetVertexColor then
                scaleSlider.thumb:SetVertexColor(1.0, 0.82, 0.0, 1.0)
            end
        end

        self:UpdateLaserButton()
    end

    f.seamSlider = seamSlider
    f.seamValText = seamValText
    f.seamEditBox = seamEditBox
    f.scaleSlider = scaleSlider
    f.scaleValText = scaleValText
    f.scaleEditBox = scaleEditBox

    wizardFrame = f
    return f
end

function Wizard:Open()
    -- Hide Options dashboard if it is currently open to prevent overlapping windows
    if Akimbo.Options and Akimbo.Options.GetConfigFrame then
        local cfg = Akimbo.Options:GetConfigFrame()
        if cfg and cfg:IsShown() then
            Wizard.openedFromOptions = true
            cfg:Hide()
        end
    end

    local f = self:CreateFrame()
    if not f then return end

    local info = self:DetectTopology()

    f.topoText:SetText(string.format("|cffffd100%s|r %s (%dx%d, AR %.2f:1)",
        L["WIZARD_DETECTED_PREFIX"], info.description, info.physWidth, info.physHeight, info.aspectRatio))

    f.recomText:SetText(string.format("|cffffd100%s|r %s | Seam: %.1f%% | Viewport: %s",
        L["WIZARD_RECOM_PREFIX"],
        (info.recommendedPreset == "PORTRAIT_LEFT_LANDSCAPE_RIGHT" and (info.recommendedPosition == "RIGHT" and L["PRESET_PL_LR"] or L["PRESET_GL_PR"]) or L["PRESET_DUAL_LANDSCAPE"]),
        info.recommendedDeckRatio * 100,
        info.recommendedAR or "16:9"))

    f.statusText:SetText(L["WIZARD_STATUS_READY"])

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
