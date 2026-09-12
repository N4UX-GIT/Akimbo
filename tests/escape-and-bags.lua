-- Test GameMenu Escape behavior and bag positioning
local addon = { modules = {}, db = { enabled = true, seamRedirect = true, independentWorkspacePanels = true, savedWorkspacePositions = { CharacterFrame = { x = 100, y = 200 } } } }

UIParent = {
    GetEffectiveScale = function() return 1 end,
    GetWidth = function() return 4000 end,
    GetHeight = function() return 2560 end,
    GetLeft = function() return 0 end,
    GetRight = function() return 4000 end,
    GetTop = function() return 2560 end,
    GetBottom = function() return 0 end,
    GetAttribute = function(self, key)
        if key == "DEFAULT_FRAME_WIDTH" then return 384 end
        if key == "RIGHT_OFFSET_BUFFER" then return 0 end
        return self[key] or 0
    end,
    SetAttribute = function(self, key, val) self[key] = val end,
}

local metrics = {
    gameLeft = 1440, gameRight = 4000, gameBottom = 6, gameTop = 1446,
    gameWidth = 2560, gameHeight = 1440, deckWidth = 1440, hudScale = 1,
}
addon.Viewport = { GetMetrics = function() return metrics end }
addon.Themes = { ApplyBackdrop = function() end }
addon.Print = function() end
addon.RunOrQueueCombat = function(self, fn) fn() end
InCombatLockdown = function() return false end

local timers = {}
C_Timer = {
    After = function(_, fn) table.insert(timers, fn) end,
}
local function flushTimers()
    local t = timers
    timers = {}
    for _, fn in ipairs(t) do fn() end
end

UISpecialFrames = {}
UIPanelWindows = {
    GameMenuFrame = { area = "center", pushable = 0, whileDead = 1 },
    CharacterFrame = { area = "left", pushable = 1 },
}

local panelAttributes = {}
function SetUIPanelAttribute(frame, key, val)
    local name = frame:GetName()
    panelAttributes[name] = panelAttributes[name] or {}
    panelAttributes[name][key] = val
end
function GetUIPanelAttribute(frame, key)
    local name = frame:GetName()
    if panelAttributes[name] and panelAttributes[name][key] ~= nil then
        return panelAttributes[name][key]
    end
    if UIPanelWindows[name] then
        return UIPanelWindows[name][key]
    end
    return nil
end

local delegate = { left = nil, center = nil }
function GetUIPanel(key) return delegate[key] end
function SetUIPanel(key, frame) delegate[key] = frame end

local function makeMockFrame(name, w, h)
    local f = {
        name = name, w = w or 200, h = h or 200,
        shown = false, alpha = 1, points = {}, scripts = {},
    }
    function f:GetName() return self.name end
    function f:GetWidth() return self.w end
    function f:GetHeight() return self.h end
    function f:GetEffectiveScale() return 1 end
    function f:GetScale() return 1 end
    function f:GetLeft() return self.points[1] and self.points[1][4] or 0 end
    function f:GetBottom() return self.points[1] and self.points[1][5] or 0 end
    function f:IsShown() return self.shown end
    function f:Show()
        self.shown = true
        if self.scripts["OnShow"] then self.scripts["OnShow"](self) end
    end
    function f:Hide()
        self.shown = false
        if self.scripts["OnHide"] then self.scripts["OnHide"](self) end
    end
    function f:SetAlpha(a) self.alpha = a end
    function f:GetAlpha() return self.alpha end
    function f:ClearAllPoints() self.points = {} end
    function f:SetPoint(...) table.insert(self.points, {...}) end
    function f:GetNumPoints() return #self.points end
    function f:GetPoint(i) return unpack(self.points[i] or {}) end
    function f:SetUserPlaced() end
    function f:IsUserPlaced() return false end
    function f:SetClampedToScreen() end
    function f:SetMovable() end
    function f:EnableMouse() end
    function f:RegisterForDrag() end
    function f:HookScript(script, fn)
        local orig = self.scripts[script]
        self.scripts[script] = function(s, ...)
            if orig then orig(s, ...) end
            fn(s, ...)
        end
    end
    _G[name] = f
    return f
end

CreateFrame = function(frameType, name)
    return makeMockFrame(name or "AnonFrame")
end

hooksecurefunc = function(arg1, arg2, arg3)
    if type(arg1) == "string" then
        local fnName = arg1
        local hookFn = arg2
        local orig = _G[fnName]
        _G[fnName] = function(...)
            local ret = orig and orig(...)
            hookFn(...)
            return ret
        end
    elseif type(arg1) == "table" then
        local tbl = arg1
        local method = arg2
        local hookFn = arg3
        local orig = tbl[method]
        tbl[method] = function(s, ...)
            local ret = orig and orig(s, ...)
            hookFn(s, ...)
            return ret
        end
    end
end

-- Mock frames
GameMenuFrame = makeMockFrame("GameMenuFrame", 200, 400)
CharacterFrame = makeMockFrame("CharacterFrame", 384, 512)
ContainerFrame1 = makeMockFrame("ContainerFrame1", 192, 250)
ContainerFrame2 = makeMockFrame("ContainerFrame2", 192, 250)

-- Mock Blizzard UI methods
function ShowUIPanel(frame)
    if not frame or frame:IsShown() then return end
    local area = GetUIPanelAttribute(frame, "area")
    if not area then
        frame:Show()
        return
    end
    if area == "center" then
        delegate.center = frame
    elseif area == "left" then
        delegate.left = frame
    end
    frame:Show()
end

function HideUIPanel(frame)
    if not frame or not frame:IsShown() then return end
    local area = GetUIPanelAttribute(frame, "area")
    if not area then
        frame:Hide()
        return
    end
    if delegate.left == frame then delegate.left = nil end
    if delegate.center == frame then delegate.center = nil end
    frame:Hide()
end

function CloseSpecialWindows()
    local found = nil
    for _, name in ipairs(UISpecialFrames) do
        local f = _G[name]
        if f and f:IsShown() then
            f:Hide()
            found = 1
        end
    end
    return found
end

function CloseWindows()
    local found = nil
    if delegate.left and delegate.left:IsShown() then
        HideUIPanel(delegate.left)
        found = 1
    end
    if delegate.center and delegate.center:IsShown() then
        HideUIPanel(delegate.center)
        found = 1
    end
    return found or CloseSpecialWindows()
end

function ToggleGameMenu(clicked)
    if not clicked then
        if CloseWindows() then
            return
        end
    end
    if GameMenuFrame:IsShown() then
        HideUIPanel(GameMenuFrame)
    else
        ShowUIPanel(GameMenuFrame)
    end
end

-- Load Akimbo files
assert(loadfile("Core/Canvas.lua"))("Akimbo", addon)
assert(loadfile("Core/SeamRedirect.lua"))("Akimbo", addon)

-- Initialize Canvas and SeamRedirect
addon.Canvas:EnableFreeDragging()
addon.SeamRedirect:HookFrames()

-- TEST 1: UIPanelWindows for GameMenuFrame and saved workspace panels must be demodalized
assert(UIPanelWindows.GameMenuFrame.area == nil, "GameMenuFrame area must be nil in UIPanelWindows")
assert(UIPanelWindows.CharacterFrame.area == nil, "CharacterFrame area must be nil because it has a saved workspace position")
local inSpecial = false
for _, n in ipairs(UISpecialFrames) do
    if n == "CharacterFrame" then inSpecial = true; break end
end
assert(inSpecial, "CharacterFrame must be registered in UISpecialFrames")

-- TEST 2: Pressing Escape on clean state opens Game Menu centered on gaming monitor
ToggleGameMenu()
flushTimers()
assert(GameMenuFrame:IsShown(), "GameMenuFrame must be shown after first Escape")
local p = GameMenuFrame.points[#GameMenuFrame.points]
assert(p and p[1] == "CENTER", "GameMenuFrame must be centered")
local expectedCX = (metrics.gameLeft + metrics.gameRight) / 2
assert(math.abs(p[4] - expectedCX) < 0.01, "GameMenuFrame centerX must match primary monitor center")

-- TEST 3: Pressing Escape while GameMenuFrame is open closes it
ToggleGameMenu()
assert(not GameMenuFrame:IsShown(), "GameMenuFrame must close on Escape")

-- TEST 4: Opening CharacterFrame places it at saved workspace position, bypassing FramePositionDelegate
CharacterFrame.points = {}
CharacterFrame:Show()
assert(CharacterFrame:IsShown(), "CharacterFrame must be shown")
assert(delegate.left == nil, "CharacterFrame must NOT occupy delegate.left")
local cp = CharacterFrame.points[#CharacterFrame.points]
assert(cp[1] == "BOTTOMLEFT" and cp[4] == 100 and cp[5] == 200, "CharacterFrame must restore saved position")

-- TEST 5: Pressing Escape while CharacterFrame is open closes CharacterFrame
ToggleGameMenu()
assert(not CharacterFrame:IsShown(), "CharacterFrame must be closed by Escape")
assert(not GameMenuFrame:IsShown(), "GameMenuFrame must not show on the same Escape press that closes CharacterFrame")

-- TEST 6: Pressing Escape AGAIN (after CharacterFrame was closed) opens GameMenuFrame
ToggleGameMenu()
flushTimers()
assert(GameMenuFrame:IsShown(), "GameMenuFrame must show on subsequent Escape press!")
local p2 = GameMenuFrame.points[#GameMenuFrame.points]
assert(math.abs(p2[4] - expectedCX) < 0.01, "GameMenuFrame must be centered on gaming monitor")

-- Close GameMenuFrame
ToggleGameMenu()
assert(not GameMenuFrame:IsShown())

-- TEST 7: Bag opening flicker prevention
ContainerFrame1:Show()
assert(ContainerFrame1:GetAlpha() == 1, "ContainerFrame1 must have alpha 1 after LayoutBags completes")
local bp = ContainerFrame1.points[#ContainerFrame1.points]
assert(bp[1] == "BOTTOMRIGHT", "ContainerFrame1 must be anchored BOTTOMRIGHT")
assert(bp[4] == metrics.gameRight - 16, "ContainerFrame1 x must be anchored to gaming monitor right edge")

print("PASS: escape menu centering, independent workspace panel lifecycle, and bag flicker prevention")