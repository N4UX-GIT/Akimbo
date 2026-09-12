--[[
    tests/wizard-autoconfig.lua
    Verifies 1-click Auto-Configuration heuristics, Options:AutoConfigure,
    Wizard dialog initialization, button bindings, and slash command routing.
--]]

local frames = {}
local registeredEvents = {}
local slashCmds = {}

SLASH_AKIMBO1 = "/akimbo"
SlashCmdList = {}
UISpecialFrames = {}

function CreateFrame(kind, name, parent, template)
    local f = {
        kind = kind,
        name = name,
        parent = parent,
        template = template,
        shown = false,
        points = {},
        scripts = {},
        texts = {},
        enabled = true,
        checked = false,
        val = 0.36,
    }
    function f:SetSize(w, h) self.width, self.height = w, h end
    function f:GetSize() return self.width, self.height end
    function f:GetWidth() return self.width or 0 end
    function f:GetHeight() return self.height or 0 end
    function f:SetWidth(w) self.width = w end
    function f:SetHeight(h) self.height = h end
    function f:SetPoint(point, rel, relPoint, x, y)
        self.points[point] = { rel = rel, relPoint = relPoint, x = x, y = y }
    end
    function f:ClearAllPoints() self.points = {} end
    function f:SetAutoFocus() end
    function f:SetNumeric() end
    function f:SetMaxLetters() end
    function f:HighlightText() end
    function f:ClearFocus() end
    function f:SetFontObject() end
    function f:SetTextColor() end
    function f:SetTextInsets() end
    function f:SetFrameStrata(strata) self.strata = strata end
    function f:EnableMouse() end
    function f:SetMovable() end
    function f:SetClampedToScreen() end
    function f:RegisterForDrag() end
    function f:SetScript(evt, handler) self.scripts[evt] = handler end
    function f:Show() self.shown = true; if self.scripts["OnShow"] then self.scripts["OnShow"](self) end end
    function f:Hide() self.shown = false; if self.scripts["OnHide"] then self.scripts["OnHide"](self) end end
    function f:SetShown(shown) if shown then self:Show() else self:Hide() end end
    function f:IsShown() return self.shown end
    function f:SetText(t) self.text = t end
    function f:GetText() return self.text end
    function f:SetTextColor() end
    function f:SetEnabled(val) self.enabled = val end
    function f:IsEnabled() return self.enabled end
    function f:SetChecked(val) self.checked = val end
    function f:GetChecked() return self.checked end
    function f:SetMinMaxValues(min, max) self.minVal, self.maxVal = min, max end
    function f:SetValueStep(step) self.step = step end
    function f:SetObeyStepOnDrag() end
    function f:SetOrientation() end
    function f:SetValue(v)
        self.val = v
        if self.scripts["OnValueChanged"] then self.scripts["OnValueChanged"](self, v) end
    end
    function f:GetValue() return self.val end
    function f:SetBackdrop() end
    function f:SetBackdropColor() end
    function f:SetBackdropBorderColor() end
    function f:SetThumbTexture() end
    function f:CreateTexture()
        local t = { SetAllPoints = function() end, SetColorTexture = function() end, SetSize = function() end }
        return t
    end
    function f:CreateFontString(layer, sublayer, template)
        local fs = {
            text = "",
            points = {},
            SetText = function(s, t) s.text = t end,
            GetText = function(s) return s.text end,
            SetPoint = function(s, pt, rel, relPt, x, y) s.points[pt] = { rel = rel, relPt = relPt, x = x, y = y } end,
            SetJustifyH = function() end,
            SetTextColor = function() end,
            SetWidth = function() end,
        }
        return fs
    end
    function f:RegisterEvent(evt) registeredEvents[evt] = true end
    frames[#frames + 1] = f
    if name then _G[name] = f end
    return f
end

UIParent = CreateFrame("Frame", "UIParent")
UIParent:SetSize(4000, 2560)
function UIParent:GetEffectiveScale() return 1.0 end

InCombatLockdown = function() return false end
strtrim = function(s) return (s:gsub("^%s*(.-)%s*$", "%1")) end
strsplit = function(delim, str)
    local t = {}
    for part in string.gmatch(str, "[^" .. delim .. "]+") do table.insert(t, part) end
    return unpack(t)
end

-- Mock C_Timer
C_Timer = {
    After = function(sec, cb) cb() end,
    NewTimer = function(sec, cb) return { Cancel = function() end } end,
}

-- Mock physical resolution: 4000x2560 (portrait left + landscape right)
GetPhysicalScreenSize = function() return 4000, 2560 end
GetScreenWidth = function() return 4000 end
GetScreenHeight = function() return 2560 end
GetBuildInfo = function() return "1.15.5", "58238", "Jan 1 2025", 11505 end
hooksecurefunc = function(t, name, fn) end

-- Load Akimbo modules
local addon = { modules = {} }
assert(loadfile("Core/Init.lua"))("Akimbo", addon)
assert(loadfile("Core/Config.lua"))("Akimbo", addon)
assert(loadfile("Core/Viewport.lua"))("Akimbo", addon)
assert(loadfile("Core/SeamRedirect.lua"))("Akimbo", addon)
assert(loadfile("Core/Canvas.lua"))("Akimbo", addon)
assert(loadfile("UI/Themes.lua"))("Akimbo", addon)
assert(loadfile("UI/Options.lua"))("Akimbo", addon)
assert(loadfile("UI/Wizard.lua"))("Akimbo", addon)

-- Initialize defaults
addon.db = {
    enabled = true,
    layoutPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT",
    deckWidthRatio = 0.36,
    primaryPosition = "RIGHT",
    aspectRatioMode = "16_9",
    hudScale = 0.70,
    theme = "CLASSIC",
    firstRunComplete = false,
}

local layoutAppliedCount = 0
function addon:ApplyFullLayout()
    layoutAppliedCount = layoutAppliedCount + 1
end

-- ============================================================================
-- 1. Test Topology Detection Heuristics
-- ============================================================================
local infoMixed = addon.Options:DetectTopology()
assert(infoMixed.isSpanned == true, "4000x2560 must be detected as spanned")
assert(infoMixed.recommendedPreset == "PORTRAIT_LEFT_LANDSCAPE_RIGHT", "Mixed setup must recommend PORTRAIT_LEFT_LANDSCAPE_RIGHT")
assert(math.abs(infoMixed.recommendedDeckRatio - 0.36) < 0.001, "Mixed setup must recommend 36% deck ratio")
assert(infoMixed.recommendedPosition == "RIGHT", "Mixed setup must recommend game monitor on RIGHT")
assert(infoMixed.recommendedAR == "16_9", "Mixed setup must recommend 16:9 AR")

-- Test 3840x1080 (dual landscape side by side)
GetPhysicalScreenSize = function() return 3840, 1080 end
local infoDual = addon.Options:DetectTopology()
assert(infoDual.isSpanned == true, "3840x1080 must be detected as spanned")
assert(infoDual.recommendedPreset == "LANDSCAPE_DUAL", "Dual 1080p must recommend LANDSCAPE_DUAL")
assert(math.abs(infoDual.recommendedDeckRatio - 0.50) < 0.001, "Dual 1080p must recommend 50% seam")

-- Reset back to 4000x2560
GetPhysicalScreenSize = function() return 4000, 2560 end

-- ============================================================================
-- 2. Test 1-Click AutoConfigure Operation
-- ============================================================================
addon.db.deckWidthRatio = 0.50
addon.db.primaryPosition = "LEFT"
addon.db.aspectRatioMode = "FILL"
addon.db.firstRunComplete = false
layoutAppliedCount = 0

local appliedInfo = addon.Options:AutoConfigure(true)
assert(appliedInfo.isSpanned == true, "AutoConfigure must detect spanned")
assert(math.abs(addon.db.deckWidthRatio - 0.36) < 0.001, "AutoConfigure must apply 36% seam")
assert(addon.db.primaryPosition == "RIGHT", "AutoConfigure must set primary position RIGHT")
assert(addon.db.aspectRatioMode == "16_9", "AutoConfigure must set 16:9 AR")
assert(addon.db.firstRunComplete == true, "AutoConfigure must mark firstRunComplete true")
assert(layoutAppliedCount >= 1, "AutoConfigure must trigger ApplyFullLayout")

-- ============================================================================
-- 3. Test Wizard Dialog Frame & Interactive Controls
-- ============================================================================
assert(addon.Wizard ~= nil, "Akimbo.Wizard must exist")
addon.Wizard:Open()

local wizardFrame = _G["AkimboSetupWizardFrame"]
assert(wizardFrame ~= nil, "AkimboSetupWizardFrame must be created")
assert(wizardFrame:IsShown() == true, "Wizard frame must be shown after Wizard:Open()")
assert(wizardFrame.topoText:GetText():find("4000x2560"), "Wizard topoText must show detected resolution")
assert(wizardFrame.recomText:GetText():find("36.0%%"), "Wizard recomText must show recommended 36% seam")

-- Click 1-Click Auto-Configure inside wizard
addon.db.deckWidthRatio = 0.55
wizardFrame.autoBtn.scripts["OnClick"]()
assert(math.abs(addon.db.deckWidthRatio - 0.36) < 0.001, "AutoConfigure button in Wizard must set 36% seam")
assert(wizardFrame.statusText:GetText():find("%[Applied%]"), "Wizard status text must confirm applied setup")

-- Test Laser Toggle in Wizard
assert(addon.Options.IsSeamGuideShown ~= nil, "Options:IsSeamGuideShown must exist")
local seamGuideLine = _G["AkimboSeamGuideLine"]
assert(seamGuideLine ~= nil, "Seam guide line must exist")

-- Close Wizard
addon.Wizard:Close()
assert(wizardFrame:IsShown() == false, "Wizard:Close must hide wizardFrame")
assert(addon.Options:IsSeamGuideShown() == false, "Wizard:Close must hide seam guide")

-- ============================================================================
-- 4. Test Slash Commands Routing
-- ============================================================================
local wizardOpened = false
local originalWizardOpen = addon.Wizard.Open
addon.Wizard.Open = function() wizardOpened = true end

SlashCmdList["AKIMBO"]("wizard")
assert(wizardOpened == true, "/akimbo wizard must call Akimbo.Wizard:Open()")

wizardOpened = false
SlashCmdList["AKIMBO"]("setup")
assert(wizardOpened == true, "/akimbo setup must call Akimbo.Wizard:Open()")

wizardOpened = false
SlashCmdList["AKIMBO"]("calibrate")
assert(wizardOpened == true, "/akimbo calibrate must call Akimbo.Wizard:Open()")

addon.Wizard.Open = originalWizardOpen

-- ============================================================================
-- 5. Test Options Dialog 1-Click and Wizard Integration Buttons
-- ============================================================================
local optPanel = addon.Options:CreateFloatingPanel()
assert(optPanel.autoWizardBtn ~= nil, "Options dashboard must have autoWizardBtn in top banner")

local wizardOpenedFromOpt = false
addon.Wizard.Open = function() wizardOpenedFromOpt = true end
optPanel.autoWizardBtn.scripts["OnClick"]()
assert(wizardOpenedFromOpt == true, "Clicking Auto-Setup Wizard button must open Wizard")
addon.Wizard.Open = originalWizardOpen

-- Card 1_1 1-Click button
assert(optPanel.tab1 ~= nil, "Tab 1 must exist")
local card1_1 = optPanel.tab1
-- card1_1 has autoDetectBtn
local foundAutoDetectBtn = false
for _, f in ipairs(frames) do
    if f.text == "1-Click Auto-Configure" then
        foundAutoDetectBtn = true
        addon.db.deckWidthRatio = 0.50
        f.scripts["OnClick"]()
        assert(math.abs(addon.db.deckWidthRatio - 0.36) < 0.001, "Card 1_1 1-Click button must auto-configure")
    end
end
assert(foundAutoDetectBtn, "Card 1_1 must contain 1-Click Auto-Configure button")

print("PASS: 1-click auto-configuration, topology heuristics, wizard frame, and UI buttons verified!")
