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

local function IsFrameOnWorkspace(frame)
    if not frame then return false end
    local x = frame:GetLeft()
    if not x then return false end
    local m = Akimbo.Viewport and Akimbo.Viewport:GetMetrics()
    if not m then return false end
    if Akimbo.db.primaryPosition ~= "LEFT" then
        return x < m.deckWidth
    else
        return x >= (m.gameWidth + m.bezel)
    end
end

local originalAreas = {}

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
            if Akimbo.db.independentWorkspacePanels and SetUIPanelAttribute then
                local currentArea = GetUIPanelAttribute and GetUIPanelAttribute(frame, "area")
                if currentArea and not originalAreas[name] then
                    originalAreas[name] = currentArea
                end
                SetUIPanelAttribute(frame, "area", nil)
            end
        end
    else
        Akimbo.db.savedWorkspacePositions[name] = nil
        if originalAreas[name] and SetUIPanelAttribute then
            SetUIPanelAttribute(frame, "area", originalAreas[name])
        end
    end
end

local function RestoreWorkspacePosition(frame)
    if not frame or not Akimbo.db or not Akimbo.db.enabled then return end
    local name = frame:GetName()
    if not name then return end
    local pos = Akimbo.db.savedWorkspacePositions and Akimbo.db.savedWorkspacePositions[name]
    if pos and pos.x and pos.y then
        if Akimbo.db.independentWorkspacePanels and SetUIPanelAttribute then
            local currentArea = GetUIPanelAttribute and GetUIPanelAttribute(frame, "area")
            if currentArea and not originalAreas[name] then
                originalAreas[name] = currentArea
            end
            SetUIPanelAttribute(frame, "area", nil)
        end
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", pos.x, pos.y)
    end
end

-- ============================================================================
-- Universal Panel Dragger (Allows moving panels to the secondary monitor)
-- ============================================================================
local function MakePanelDraggable(frame, dragHandle)
    if not frame or frame._akimboMovable then return end

    dragHandle = dragHandle or frame
    frame:SetMovable(true)
    frame:SetClampedToScreen(false)

    dragHandle:EnableMouse(true)
    dragHandle:RegisterForDrag("LeftButton")

    dragHandle:HookScript("OnDragStart", function(self)
        if InCombatLockdown() or not Akimbo.db.enabled then return end
        frame._akimboDragging = true
        frame:StartMoving()
    end)

    dragHandle:HookScript("OnDragStop", function(self)
        OnPanelDragStop(frame)
    end)

    frame:HookScript("OnShow", function(self)
        RestoreWorkspacePosition(frame)
    end)

    frame._akimboMovable = true
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
        end
    end
end

function Akimbo:InitializeCanvas()
    Canvas:CreateFrames()

    -- Re-check draggable frames when Blizzard on-demand addons load
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnEvent", function()
        Canvas:EnableFreeDragging()
        Canvas:UpdateMapMovementBehavior()
    end)
    Canvas:UpdateMapMovementBehavior()
end

function Akimbo:UpdateCanvas()
    Canvas:UpdateLayout()
end
