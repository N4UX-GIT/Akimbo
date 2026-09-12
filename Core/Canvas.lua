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

    -- Subtle, clean top banner for the workspace
    rootCanvas.header = Akimbo.Themes:CreateBayHeader(rootCanvas, "AKIMBO SECONDARY WORKSPACE")

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
        frame:StopMovingOrSizing()
        pcall(function() frame:SetUserPlaced(true) end)
        frame._akimboDragging = false
        if Akimbo.Panels then
            Akimbo.Panels:SavePosition(frame)
            Akimbo.Panels:Place(frame)
        end
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
        "ContainerFrameCombinedBags",
    }

    for _, name in ipairs(frameNames) do
        local frame = _G[name]
        if frame then
            frame:SetClampedToScreen(false)
            MakePanelDraggable(frame)
        end
    end

    -- Add individual bag frames (ContainerFrame1..13)
    for i = 1, (NUM_CONTAINER_FRAMES or 13) do
        local frame = _G["ContainerFrame" .. i]
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
    end)
end

function Akimbo:UpdateCanvas()
    Canvas:UpdateLayout()
end
