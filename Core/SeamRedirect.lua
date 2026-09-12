-- Anchor managed HUD frames inside the same rectangle used by WorldFrame.
local _, Akimbo = ...
local HUD = {}
Akimbo.SeamRedirect = HUD
local aligning, pending = false, false
local hooks = {}
local desiredFrames = {}
local actionNames = {"MainMenuBar", "MainActionBar", "StatusTrackingBarManager", "MainMenuExpBar",
    "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarLeft", "MultiBarRight",
    "StanceBar", "ShapeshiftBarFrame", "StanceBarFrame", "PetActionBar", "PetActionBarFrame",
    "MicroMenuContainer", "MicroMenu", "BagsBar", "MicroButtonAndBagsBar",
    "MainMenuBarBackpackButton", "CharacterBag0Slot", "CharacterBag1Slot",
    "CharacterBag2Slot", "CharacterBag3Slot"}
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

local function Anchor(frame, point, m, x, y)
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
    if chat ~= ChatFrame1 and not hooks[chat] then
        hooks[chat] = true
        hooksecurefunc(chat, "SetPoint", function() HUD:RequestLayout() end)
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
            if frame then Anchor(frame, item[2], m, item[3], item[4]) end
        end
        -- Classic uses a separate MicroMenuContainer. Give menu and bags distinct
        -- slots in the right half of the artwork rather than sharing a screen anchor.
        local leftmostBag
        if main and BagsBar then
            BagsBar:SetFrameLevel(main:GetFrameLevel()+5)
            Points(BagsBar, {"BOTTOMRIGHT", main, "BOTTOMRIGHT", -8, 4})
            local previous
            for _,name in ipairs({"MainMenuBarBackpackButton", "CharacterBag0Slot",
                "CharacterBag1Slot", "CharacterBag2Slot", "CharacterBag3Slot"}) do
                local button=_G[name]
                if button then
                    button:SetFrameLevel(BagsBar:GetFrameLevel()+1)
                    if previous then
                        Points(button,{"BOTTOMRIGHT",previous,"BOTTOMLEFT",-4,0})
                    else
                        Points(button,{"BOTTOMRIGHT",main,"BOTTOMRIGHT",-8,4})
                    end
                    previous=button
                end
            end
            leftmostBag=previous
        end
        if main and MicroMenu then
            MicroMenu:SetFrameLevel(main:GetFrameLevel()+6)
            if leftmostBag then
                Points(MicroMenu, {"BOTTOMRIGHT", leftmostBag, "BOTTOMLEFT", -12, 0})
            else
                Points(MicroMenu, {"BOTTOMRIGHT", main, "BOTTOMRIGHT", -208, 4})
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
    for _, name in ipairs({"PlayerFrame", "TargetFrame", "MinimapCluster", "ChatFrame1",
        "BuffFrame", "UIErrorsFrame", "RaidWarningFrame"}) do
        local frame = _G[name]
        if frame and not hooks[frame] then
            hooks[frame] = true
            hooksecurefunc(frame, "SetPoint", function() HUD:RequestLayout() end)
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
