--[[
    Akimbo: Dual Monitor Workstation Addon
    Core/Canvas.lua: Unsegmented free-space secondary monitor workspace with universal window dragging
--]]

local _, Akimbo = ...

local Canvas = {}
Akimbo.Canvas = Canvas

local rootCanvas

function Canvas:CreateFrames()
    if rootCanvas then return end

    -- Root Canvas (covers the secondary monitor as an open, unsegmented free workspace)
    rootCanvas = CreateFrame("Frame", "AkimboCanvasFrame", UIParent, "BackdropTemplate")
    rootCanvas:SetFrameStrata("BACKGROUND")
    rootCanvas:SetFrameLevel(1)
    Akimbo.canvas = rootCanvas
end

function Canvas:UpdateLayout()
    if not rootCanvas then self:CreateFrames() end

    local metrics = Akimbo.Viewport:GetMetrics()

    if not metrics.isSpanned or not Akimbo.db.enabled then
        rootCanvas:Hide()
        return
    end

    rootCanvas:Show()
    rootCanvas:ClearAllPoints()

    local isPortraitDeck = Akimbo.db.primaryPosition ~= "LEFT"

    if isPortraitDeck then
        -- Secondary monitor (free space workspace) is on the LEFT
        rootCanvas:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
        rootCanvas:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", metrics.deckWidth, 0)
    else
        -- Secondary monitor is on the RIGHT
        local leftOffset = metrics.gameWidth + metrics.bezel
        rootCanvas:SetPoint("TOPLEFT", UIParent, "TOPLEFT", leftOffset, 0)
        rootCanvas:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
    end

    -- Apply clean, dark backdrop theme to the workspace
    Akimbo.Themes:ApplyBackdrop(rootCanvas, Akimbo.db.theme or "OBSIDIAN", Akimbo.db.canvasAlpha or 0.95)

    -- Enable free dragging for standard Blizzard frames so the player can move them anywhere on the workspace
    self:EnableFreeDragging()
    self:UpdateMapMovementBehavior()
end

local function HasLeatrixMaps()
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded("Leatrix_Maps")
    elseif IsAddOnLoaded then
        return IsAddOnLoaded("Leatrix_Maps")
    end
    return false
end

local function HasLeatrixPlus()
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded("Leatrix_Plus")
    elseif IsAddOnLoaded then
        return IsAddOnLoaded("Leatrix_Plus")
    end
    return false
end

function Canvas:UpdateMapMovementBehavior()
    local map = WorldMapFrame
    if not map then return end
    if HasLeatrixMaps() then return end

    if Akimbo.db and Akimbo.db.enabled and Akimbo.db.preventMapCloseOnMove then
        pcall(function() map:UnregisterEvent("PLAYER_STARTED_MOVING") end)
    else
        pcall(function() map:RegisterEvent("PLAYER_STARTED_MOVING") end)
    end
end

function Canvas:ConfigureWorldMap()
    local map = WorldMapFrame
    if not map or HasLeatrixMaps() or not Akimbo.db or not Akimbo.db.enabled then return end

    local m = Akimbo.Viewport and Akimbo.Viewport:GetMetrics()
    if not m or not m.isSpanned then return end

    -- Ensure windowed mini world map in Classic Era
    pcall(function()
        if GetCVar("miniWorldMap") ~= "1" then
            SetCVar("miniWorldMap", "1")
        end
        if map.IsMaximized and map:IsMaximized() and map.Minimize then
            map:Minimize()
        end
    end)

    -- If map is on the workspace, scale it down to fit the portrait width cleanly
    local pos = Akimbo.db.savedWorkspacePositions and Akimbo.db.savedWorkspacePositions["WorldMapFrame"]
    if pos or IsFrameOnWorkspace(map) then
        local baseWidth = map:GetWidth() or 610
        if baseWidth > 0 then
            local availableWidth = m.deckWidth - 24
            local fitScale = math.min(1, availableWidth / baseWidth)
            map:SetScale(fitScale)
        end
    end
end

local function IsFrameOnWorkspace(frame)
    if not frame then return false end
    local x = frame:GetLeft()
    if not x then return false end
    local m = Akimbo.Viewport and Akimbo.Viewport:GetMetrics()
    if not m then return false end
    local frameScale = (frame.GetEffectiveScale and frame:GetEffectiveScale()) or 1
    local parentScale = (UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
    local xInParent = x * (frameScale / parentScale)
    if Akimbo.db.primaryPosition ~= "LEFT" then
        return xInParent < (m.deckWidth + 10)
    else
        return xInParent >= (m.gameWidth + m.bezel - 10)
    end
end

local originalAreas = {}

local function RegisterSpecialFrame(name)
    if not name or not UISpecialFrames then return end
    for _, n in ipairs(UISpecialFrames) do
        if n == name then return end
    end
    table.insert(UISpecialFrames, name)
end

local function UnregisterSpecialFrame(name)
    if not name or not UISpecialFrames then return end
    for i = #UISpecialFrames, 1, -1 do
        if UISpecialFrames[i] == name then
            table.remove(UISpecialFrames, i)
        end
    end
end

local function DemodalizePanel(frame)
    if not frame then return end
    local name = frame:GetName()
    if not name then return end
    if UIPanelWindows and UIPanelWindows[name] then
        if not originalAreas[name] then
            originalAreas[name] = UIPanelWindows[name].area
        end
        UIPanelWindows[name].area = nil
    end
    if SetUIPanelAttribute then
        pcall(function() SetUIPanelAttribute(frame, "area", nil) end)
    end
    RegisterSpecialFrame(name)
end

local function RemodalizePanel(frame)
    if not frame then return end
    local name = frame:GetName()
    if not name then return end
    UnregisterSpecialFrame(name)
    if originalAreas[name] then
        if UIPanelWindows and UIPanelWindows[name] then
            UIPanelWindows[name].area = originalAreas[name]
        end
        if SetUIPanelAttribute then
            pcall(function() SetUIPanelAttribute(frame, "area", originalAreas[name]) end)
        end
    end
end

local function OnPanelDragStop(frame)
    frame:StopMovingOrSizing()
    pcall(function() frame:SetUserPlaced(true) end)
    frame._akimboDragging = false

    if not Akimbo.db or not Akimbo.db.enabled then return end
    local name = frame:GetName()
    if not name then return end

    Akimbo.db.savedWorkspacePositions = Akimbo.db.savedWorkspacePositions or {}

    if IsFrameOnWorkspace(frame) then
        local x, y = frame:GetLeft(), frame:GetBottom()
        if x and y then
            Akimbo.db.savedWorkspacePositions[name] = { x = x, y = y }
            if Akimbo.db.independentWorkspacePanels then
                -- Evict from Blizzard UIPanel slot if currently occupying one
                if GetUIPanel and (GetUIPanel("left") == frame or GetUIPanel("center") == frame or GetUIPanel("right") == frame or GetUIPanel("doublewide") == frame) then
                    pcall(function() HideUIPanel(frame, 1) end)
                    frame:ClearAllPoints()
                    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
                    frame:Show()
                end
                DemodalizePanel(frame)
            end
        end
        if frame == WorldMapFrame then
            Canvas:ConfigureWorldMap()
        end
    else
        Akimbo.db.savedWorkspacePositions[name] = nil
        RemodalizePanel(frame)
        if frame == WorldMapFrame then
            frame:SetScale(1)
        end
    end
end

local function RestoreWorkspacePosition(frame)
    if not frame or not Akimbo.db or not Akimbo.db.enabled then return end
    local name = frame:GetName()
    if not name then return end
    local pos = Akimbo.db.savedWorkspacePositions and Akimbo.db.savedWorkspacePositions[name]
    if pos and pos.x and pos.y then
        if Akimbo.db.independentWorkspacePanels then
            DemodalizePanel(frame)
        end
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", pos.x, pos.y)
        if frame == WorldMapFrame then
            Canvas:ConfigureWorldMap()
        end
    end
end

-- ============================================================================
-- Universal Panel Dragger (Allows moving panels to the secondary monitor)
-- ============================================================================
local function MakePanelDraggable(frame)
    if not frame or frame._akimboMovable then return end

    frame:SetMovable(true)
    frame:SetClampedToScreen(false)

    -- Create an elevated drag handle across the title bar area so clicks aren't swallowed by child elements
    local handle = frame._akimboHandle
    if not handle and CreateFrame then
        handle = CreateFrame("Frame", nil, frame)
        handle:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, 0)
        handle:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, 0)
        handle:SetHeight(32)
        local lvl = (frame.GetFrameLevel and frame:GetFrameLevel()) or 1
        handle:SetFrameLevel(lvl + 25)
        handle:EnableMouse(true)
        handle:RegisterForDrag("LeftButton")

        handle:HookScript("OnDragStart", function(self)
            if InCombatLockdown() or not Akimbo.db.enabled then return end
            frame._akimboDragging = true
            frame:StartMoving()
        end)

        handle:HookScript("OnDragStop", function(self)
            OnPanelDragStop(frame)
        end)

        frame._akimboHandle = handle
    end

    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    frame:HookScript("OnDragStart", function(self)
        if InCombatLockdown() or not Akimbo.db.enabled then return end
        frame._akimboDragging = true
        frame:StartMoving()
    end)

    frame:HookScript("OnDragStop", function(self)
        OnPanelDragStop(frame)
    end)

    frame:HookScript("OnShow", function(self)
        RestoreWorkspacePosition(frame)
    end)

    frame._akimboMovable = true
end

function Canvas:TryMakeFrameDraggable(frame)
    if not frame or frame._akimboMovable or not frame.GetName then return end
    local name = frame:GetName()
    if not name then return end
    local isPanel = UIPanelWindows and UIPanelWindows[name]
    if isPanel or frame.TitleContainer or frame.TitleText or _G[name .. "TitleText"] then
        frame:SetClampedToScreen(false)
        MakePanelDraggable(frame)
        if Akimbo.db and Akimbo.db.independentWorkspacePanels and Akimbo.db.savedWorkspacePositions and Akimbo.db.savedWorkspacePositions[name] then
            DemodalizePanel(frame)
        end
    end
end

function Canvas:EnableFreeDragging()
    if not Akimbo.db or not Akimbo.db.enabled then return end
    if InCombatLockdown() then
        if not self.dragSetupPending then
            self.dragSetupPending = true
            Akimbo:RunOrQueueCombat(function()
                Canvas.dragSetupPending = false
                Canvas:EnableFreeDragging()
            end)
        end
        return
    end
    -- List of standard frames that players love dragging to their secondary workspace
    local frameNames = {
        "WorldMapFrame",
        "CharacterFrame",
        "QuestLogFrame",
        "SpellBookFrame",
        "TalentFrame",
        "PlayerTalentFrame",
        "FriendsFrame",
        "TradeFrame",
        "MerchantFrame",
        "MailFrame",
        "OpenMailFrame",
        "BankFrame",
        "PVEFrame",
        "InspectFrame",
        "MacroFrame",
        "ClassTrainerFrame",
        "TradeSkillFrame",
        "CraftFrame",
    }

    for _, name in ipairs(frameNames) do
        local frame = _G[name]
        if frame then
            frame:SetClampedToScreen(false)
            MakePanelDraggable(frame)
            if Akimbo.db and Akimbo.db.independentWorkspacePanels and Akimbo.db.savedWorkspacePositions and Akimbo.db.savedWorkspacePositions[name] then
                DemodalizePanel(frame)
            end
        end
    end

    self:ConfigureWorldMap()
end

function Akimbo:InitializeCanvas()
    Canvas:CreateFrames()

    -- Re-check draggable frames when Blizzard on-demand addons load
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnEvent", function()
        Canvas:EnableFreeDragging()
        Canvas:UpdateMapMovementBehavior()
        Canvas:ConfigureWorldMap()
    end)
    Canvas:UpdateMapMovementBehavior()
    Canvas:ConfigureWorldMap()

    if not Canvas.showUIPanelHooked and ShowUIPanel then
        Canvas.showUIPanelHooked = true
        hooksecurefunc("ShowUIPanel", function(frame)
            Canvas:TryMakeFrameDraggable(frame)
        end)
    end
end

function Akimbo:UpdateCanvas()
    Canvas:UpdateLayout()
end
