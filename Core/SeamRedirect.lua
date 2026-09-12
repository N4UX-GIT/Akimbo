-- Anchor managed HUD frames inside the same rectangle used by WorldFrame.
local _, Akimbo = ...
local HUD = {}
Akimbo.SeamRedirect = HUD
local aligning, pending = false, false
local hooks = {}
local desiredFrames = {}
local function HasCustomActionBarAddon()
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded("Bartender4") or C_AddOns.IsAddOnLoaded("Dominos")
    elseif IsAddOnLoaded then
        return IsAddOnLoaded("Bartender4") or IsAddOnLoaded("Dominos")
    end
    return false
end

local actionNames = {"MainMenuBar", "MainActionBar", "StatusTrackingBarManager", "MainMenuExpBar",
    "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarLeft", "MultiBarRight",
    "StanceBar", "ShapeshiftBarFrame", "StanceBarFrame", "PetActionBar", "PetActionBarFrame"}
local function Remember(frame)
    desiredFrames[frame] = desiredFrames[frame] or {}
    return desiredFrames[frame]
end

-- Rewriting identical anchors dirties Blizzard layout again on the next frame.
local function Points(frame, ...)
    local desired = {...}
    Remember(frame).points = desired
    local same = frame:GetNumPoints() == #desired
    if same then
        for i, point in ipairs(desired) do
            local a, b, c, x, y = frame:GetPoint(i)
            if a ~= point[1] or b ~= point[2] or c ~= point[3]
                or math.abs((x or 0) - point[4]) > 0.001
                or math.abs((y or 0) - point[5]) > 0.001 then
                same = false; break
            end
        end
    end
    if same then return end
    frame:ClearAllPoints()
    for _, point in ipairs(desired) do frame:SetPoint(unpack(point)) end
end

local function ScreenPoint(frame, point, x, y)
    local factor = UIParent:GetEffectiveScale() / frame:GetEffectiveScale()
    Points(frame, {point, UIParent, "BOTTOMLEFT", x * factor, y * factor})
end

local function Anchor(frame, point, m, x, y, force)
    if not frame then return end
    if not force and frame.IsUserPlaced and frame:IsUserPlaced() then return end
    local px = point:find("LEFT") and m.gameLeft or point:find("RIGHT") and m.gameRight
        or (m.gameLeft + m.gameRight) / 2
    local py = point:find("TOP") and m.gameTop or point:find("BOTTOM") and m.gameBottom
        or (m.gameBottom + m.gameTop) / 2
    ScreenPoint(frame, point,
        px + (x or 0) * m.hudScale, py + (y or 0) * m.hudScale)
end

local function Prepare(frame, m)
    if not frame then return end
    frame:SetClampedToScreen(false)
end

function HUD:RequestLayout()
    if aligning or pending or not Akimbo.db or not Akimbo.db.enabled then return end
    pending = true
    C_Timer.After(0.05, function()
        if not Akimbo.db or not Akimbo.db.enabled then pending = false; return end
        -- A HUD repair must not resize WorldFrame, the deck or docked modules.
        Akimbo:RunOrQueueCombat(function()
            pending = false
            if Akimbo.db and Akimbo.db.enabled then HUD:AlignHUDFrames() end
        end)
    end)
end

function HUD:AlignChatFrame(m)
    if not ChatFrame1 or Akimbo.db.dockChat == false then return end
    local chat = ChatFrame1
    -- Chattynator replaces the visible chat frame. Use its exposed handler to
    -- locate the primary window without changing its saved profile or messages.
    local handler = Chattynator and Chattynator.API and Chattynator.API.GetHyperlinkHandler
        and Chattynator.API.GetHyperlinkHandler()
    if handler then
        for _, child in ipairs({handler:GetChildren()}) do
            if child:GetID() == 1 and child.ScrollingMessages then chat = child; break end
        end
    end
    Prepare(chat, m)
    if chat.IsUserPlaced and chat:IsUserPlaced() then return end
    if chat ~= ChatFrame1 and not hooks[chat] then
        hooks[chat] = true
        hooksecurefunc(chat, "SetPoint", function()
            if not (chat.IsUserPlaced and chat:IsUserPlaced()) then
                HUD:RequestLayout()
            end
        end)
    end
    if Akimbo.db.chatPosition == "DECK" and Akimbo.canvas then
        local x = Akimbo.db.primaryPosition == "LEFT" and m.gameRight + m.bezel or 0
        ScreenPoint(chat, "BOTTOMLEFT",
            x + 24 * m.hudScale, 45 * m.hudScale)
        chat:SetSize(math.min(460, m.deckWidth / m.hudScale - 48), 220)
    else
        Anchor(chat, "BOTTOMLEFT", m, 24, 120)
        chat:SetSize(math.min(460, m.gameWidth / m.hudScale * 0.40), 220)
    end
    if ChatFrame1EditBox then
        Points(ChatFrame1EditBox,
            {"TOPLEFT", chat, "BOTTOMLEFT", 0, 0},
            {"TOPRIGHT", chat, "BOTTOMRIGHT", 0, 0})
    end
end

function HUD:AlignHUDFrames(m)
    if aligning or InCombatLockdown() or not Akimbo.db.enabled then return end
    aligning = true
    local ok, err = pcall(function()
        m = m or Akimbo.Viewport:GetMetrics()
        if not HasCustomActionBarAddon() then
            local main = MainMenuBar or MainActionBar
            Prepare(main, m)
            if main then Anchor(main, "BOTTOM", m, 0, 0) end
            if MainActionBar and MainActionBar ~= main then
                Prepare(MainActionBar, m)
                Points(MainActionBar, {"BOTTOMLEFT", main, "BOTTOMLEFT", 8, 4})
            end

            local xp = StatusTrackingBarManager or MainMenuExpBar
            Prepare(xp, m)
            if xp and main then
                Points(xp, {"BOTTOM", main, "TOP", 0, -2})
            end
            -- Preserve Blizzard's visibility rules (XP at max level, pet, stance, etc.).
            local bottomLeft, bottomRight = MultiBarBottomLeft, MultiBarBottomRight
            Prepare(bottomLeft, m)
            Prepare(bottomRight, m)
            if bottomLeft and main then
                Points(bottomLeft, {"BOTTOMLEFT", main, "TOPLEFT", 0, 8})
            end
            if bottomRight and main then
                Points(bottomRight, {"BOTTOMLEFT", main, "TOPLEFT", 515, 8})
            end
            local barTop = bottomLeft and bottomLeft:IsShown() and bottomLeft or main
            for _, name in ipairs({"StanceBar", "ShapeshiftBarFrame", "StanceBarFrame",
                "PetActionBar", "PetActionBarFrame"}) do
                local frame = _G[name]
                Prepare(frame, m)
                if frame and barTop then
                    Points(frame, {"BOTTOMLEFT", barTop, "TOPLEFT", 30, 5})
                end
            end
            Prepare(MultiBarRight, m)
            if MultiBarRight then Anchor(MultiBarRight, "RIGHT", m, -4, 0) end
            Prepare(MultiBarLeft, m)
            if MultiBarLeft then Anchor(MultiBarLeft, "RIGHT", m, -48, 0) end
        end

        for _, item in ipairs({
            {"MinimapCluster", "TOPRIGHT", 0, 0},
            {"PlayerFrame", "TOPLEFT", 16, -16},
            {"TargetFrame", "TOPLEFT", 260, -16},
            {"BuffFrame", "TOPRIGHT", -210, -16},
            {"BuffCluster", "TOPRIGHT", -210, -16},
            {"CastingBarFrame", "BOTTOM", 0, 165},
            {"PlayerCastingBarFrame", "BOTTOM", 0, 165},
        }) do
            local frame = _G[item[1]]
            Prepare(frame, m)
            if frame then
                local force = (frame == PlayerFrame or frame == TargetFrame or frame == MinimapCluster)
                if force then
                    pcall(function() frame:SetUserPlaced(false) end)
                end
                Anchor(frame, item[2], m, item[3], item[4], force)
            end
        end

        self:AlignChatFrame(m)
        if Akimbo.db.seamRedirect then
            for _, item in ipairs({{"UIErrorsFrame", -60}, {"RaidWarningFrame", -100}}) do
                local frame = _G[item[1]]
                Prepare(frame, m)
                if frame then Anchor(frame, "TOP", m, 0, item[2]) end
            end
        end
    end)
    aligning = false
    if not ok then Akimbo:Print("HUD layout error: %s", tostring(err)) end
end

-- Replay the last committed layout for just the frame Blizzard changed. A timer
-- exposes the reset geometry for several rendered frames even when idle.
-- Cache only layout written by AlignHUDFrames; never replace Blizzard methods or
-- force visibility/action state. The guard prevents our setters from re-entering.
function HUD:RepairFrame(frame)
    if aligning or not Akimbo.db or not Akimbo.db.enabled then return end
    if frame.IsUserPlaced and frame:IsUserPlaced() then return end
    if HasCustomActionBarAddon() then return end
    local desired = desiredFrames[frame]
    if not desired then return end
    if InCombatLockdown() then self:RequestLayout(); return end
    aligning = true
    local ok, err = pcall(function()
        if desired.points then Points(frame, unpack(desired.points)) end
    end)
    aligning = false
    if not ok then Akimbo:Print("HUD layout error: %s", tostring(err)) end
end

function HUD:IsManagedFrame(frame)
    return desiredFrames[frame] ~= nil
end

function HUD:HookFrames()
    if not HasCustomActionBarAddon() then
        if not self.managerHooked and UIParent_ManageFramePositions then
            self.managerHooked = true
            hooksecurefunc("UIParent_ManageFramePositions", function()
                for _, name in ipairs(actionNames) do
                    local frame = _G[name]
                    if frame then HUD:RepairFrame(frame) end
                end
                HUD:RequestLayout()
            end)
        end
        for _, name in ipairs(actionNames) do
            local frame = _G[name]
            if frame and not hooks[frame] then
                hooks[frame] = true
                hooksecurefunc(frame, "SetPoint", function() HUD:RepairFrame(frame) end)
            end
        end
    end
    for _, name in ipairs({"PlayerFrame", "TargetFrame", "MinimapCluster", "ChatFrame1",
        "BuffFrame", "UIErrorsFrame", "RaidWarningFrame"}) do
        local frame = _G[name]
        if frame and not hooks[frame] then
            hooks[frame] = true
            hooksecurefunc(frame, "SetPoint", function()
                if not (frame.IsUserPlaced and frame:IsUserPlaced()) then
                    HUD:RequestLayout()
                end
            end)
        end
    end
    -- Center Game Menu (Escape menu) and settings panels onto the primary game monitor
    local function CenterGameMenu()
        for _, name in ipairs({"GameMenuFrame", "SettingsPanel", "InterfaceOptionsFrame", "VideoOptionsFrame"}) do
            local frame = _G[name]
            if frame and frame:IsShown() and not InCombatLockdown() and Akimbo.db and Akimbo.db.enabled then
                local m = Akimbo.Viewport:GetMetrics()
                frame:ClearAllPoints()
                local cx = (m.gameLeft + m.gameRight) / 2
                local cy = (m.gameBottom + m.gameTop) / 2
                local factor = UIParent:GetEffectiveScale() / frame:GetEffectiveScale()
                frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx * factor, cy * factor)
            end
        end
    end

    if UIPanelWindows then
        for _, name in ipairs({"GameMenuFrame", "SettingsPanel", "InterfaceOptionsFrame", "VideoOptionsFrame"}) do
            if UIPanelWindows[name] then
                UIPanelWindows[name].centerFrameSkipAnchoring = true
            end
        end
    end

    for _, name in ipairs({"GameMenuFrame", "SettingsPanel", "InterfaceOptionsFrame", "VideoOptionsFrame"}) do
        local frame = _G[name]
        if frame and not hooks[frame] then
            hooks[frame] = true
            frame:HookScript("OnShow", function(self)
                C_Timer.After(0, CenterGameMenu)
            end)
        end
    end

    if not self.menuHooksInstalled then
        self.menuHooksInstalled = true
        if ToggleGameMenu then
            hooksecurefunc("ToggleGameMenu", function()
                C_Timer.After(0, CenterGameMenu)
            end)
        end
        if ShowUIPanel then
            hooksecurefunc("ShowUIPanel", function(frame)
                if frame == GameMenuFrame or frame == SettingsPanel then
                    C_Timer.After(0, CenterGameMenu)
                end
            end)
        end
    end

    -- Keep bags on regular monitor unless user explicitly dragged them to workspace
    local isArrangingBags = false
    function HUD:LayoutBags()
        if isArrangingBags or InCombatLockdown() or not Akimbo.db or not Akimbo.db.enabled then return end
        isArrangingBags = true

        local m = Akimbo.Viewport:GetMetrics()
        local right = m.gameRight - 16
        local bottom = m.gameBottom + 32
        local bagSpacing = 4

        local bagIndex = 0
        for i = 1, (NUM_CONTAINER_FRAMES or 13) do
            local frame = _G["ContainerFrame" .. i]
            if frame and frame:IsShown() then
                local name = frame:GetName()
                local pos = Akimbo.db.savedWorkspacePositions and Akimbo.db.savedWorkspacePositions[name]
                if not pos then
                    frame:SetUserPlaced(false)
                    frame:ClearAllPoints()
                    local w = frame:GetWidth() or 192
                    local factor = UIParent:GetEffectiveScale() / frame:GetEffectiveScale()
                    local x = (right - (w + bagSpacing) * bagIndex) * factor
                    local y = bottom * factor
                    frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", x, y)
                    bagIndex = bagIndex + 1
                end
            end
        end

        if ContainerFrameCombinedBags and ContainerFrameCombinedBags:IsShown() then
            local pos = Akimbo.db.savedWorkspacePositions and Akimbo.db.savedWorkspacePositions["ContainerFrameCombinedBags"]
            if not pos then
                ContainerFrameCombinedBags:SetUserPlaced(false)
                ContainerFrameCombinedBags:ClearAllPoints()
                local factor = UIParent:GetEffectiveScale() / ContainerFrameCombinedBags:GetEffectiveScale()
                ContainerFrameCombinedBags:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", right * factor, bottom * factor)
            end
        end

        isArrangingBags = false
    end

    if not self.bagHooksInstalled then
        self.bagHooksInstalled = true
        if ContainerFrame_GenerateFrame then
            hooksecurefunc("ContainerFrame_GenerateFrame", function()
                C_Timer.After(0, function() HUD:LayoutBags() end)
            end)
        end
        if ToggleBag then
            hooksecurefunc("ToggleBag", function()
                C_Timer.After(0, function() HUD:LayoutBags() end)
            end)
        end
        if ToggleAllBags then
            hooksecurefunc("ToggleAllBags", function()
                C_Timer.After(0, function() HUD:LayoutBags() end)
            end)
        end
        if OpenAllBags then
            hooksecurefunc("OpenAllBags", function()
                C_Timer.After(0, function() HUD:LayoutBags() end)
            end)
        end
        if OpenBag then
            hooksecurefunc("OpenBag", function()
                C_Timer.After(0, function() HUD:LayoutBags() end)
            end)
        end
        if CloseBag then
            hooksecurefunc("CloseBag", function()
                C_Timer.After(0, function() HUD:LayoutBags() end)
            end)
        end
        if CloseAllBags then
            hooksecurefunc("CloseAllBags", function()
                C_Timer.After(0, function() HUD:LayoutBags() end)
            end)
        end
    end
    for i = 1, 4 do
        local frame = _G["StaticPopup" .. i]
        if frame and not hooks[frame] then
            hooks[frame] = true
            local index = i
            frame:HookScript("OnShow", function(self)
                if InCombatLockdown() or not Akimbo.db.enabled or not Akimbo.db.seamRedirect then return end
                local m = Akimbo.Viewport:GetMetrics()
                Prepare(self, m)
                Anchor(self, "CENTER", m, 0, (index - 1) * 120)
            end)
        end
    end
end

function Akimbo:InitializeSeamRedirect()
    HUD:HookFrames()
end
function Akimbo:UpdateSeamRedirect()
    HUD:HookFrames()
    HUD:AlignHUDFrames()
end
