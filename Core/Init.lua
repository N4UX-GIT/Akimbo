--[[
    Akimbo: Dual Monitor Workstation Addon
    Core/Init.lua: Addon initialization, namespace, event dispatcher, and combat-safe queue
--]]

local addonName, Akimbo = ...
_G.Akimbo = Akimbo

Akimbo.name = addonName
Akimbo.version = "1.0.0"
Akimbo.modules = {}
Akimbo.callbacks = {}

-- Client flavor detection
local tocVersion = select(4, GetBuildInfo())
Akimbo.tocVersion = tocVersion
Akimbo.isClassicEra = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
Akimbo.isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

-- Formatted chat printing
function Akimbo:Print(msg, ...)
    if select("#", ...) > 0 then
        msg = string.format(msg, ...)
    end
    local frame = DEFAULT_CHAT_FRAME or (ChatFrame1 and ChatFrame1:IsShown() and ChatFrame1)
    if frame then
        frame:AddMessage("|cff00ccff[Akimbo]|r " .. tostring(msg))
    end
end

function Akimbo:Debug(msg, ...)
    if AkimboDB and AkimboDB.debugMode then
        if select("#", ...) > 0 then
            msg = string.format(msg, ...)
        end
        local frame = DEFAULT_CHAT_FRAME or (ChatFrame1 and ChatFrame1:IsShown() and ChatFrame1)
        if frame then
            frame:AddMessage("|cff888888[Akimbo Debug]|r " .. tostring(msg))
        end
    end
end

-- ============================================================================
-- Combat-Safe Queue System
-- Modifying protected frames or layout during InCombatLockdown causes Lua errors.
-- We safely queue modifications until PLAYER_REGEN_ENABLED.
-- ============================================================================
local combatQueue = {}

function Akimbo:RunOrQueueCombat(action, ...)
    if not InCombatLockdown() then
        action(...)
    else
        table.insert(combatQueue, { func = action, args = { ... } })
        Akimbo:Debug("Action queued for post-combat execution.")
    end
end

local function ProcessCombatQueue()
    if #combatQueue == 0 then return end
    Akimbo:Debug("Processing %d combat-queued actions...", #combatQueue)
    local queueCopy = combatQueue
    combatQueue = {}
    for _, item in ipairs(queueCopy) do
        local success, err = pcall(item.func, unpack(item.args))
        if not success then
            Akimbo:Print("|cffff3333Queue Execution Error:|r %s", tostring(err))
        end
    end
end

-- ============================================================================
-- Core Event Dispatcher
-- ============================================================================
local eventFrame = CreateFrame("Frame", "AkimboEventFrame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("UI_SCALE_CHANGED")
eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")

eventFrame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == addonName then
        Akimbo:InitializeConfig()
        if Akimbo.InitializeThemes then Akimbo:InitializeThemes() end
        if Akimbo.InitializeCanvas then Akimbo:InitializeCanvas() end
        if Akimbo.InitializeViewport then Akimbo:InitializeViewport() end
        if Akimbo.InitializeSeamRedirect then Akimbo:InitializeSeamRedirect() end
        if Akimbo.InitializeOptions then Akimbo:InitializeOptions() end

        -- Initialize child modules
        for name, module in pairs(Akimbo.modules) do
            if module.Initialize then
                module:Initialize()
            end
        end

    elseif event == "PLAYER_LOGIN" then
        pcall(function()
            if ContainerFrame1 and not (Akimbo.db and Akimbo.db.savedWorkspacePositions and Akimbo.db.savedWorkspacePositions["ContainerFrame1"]) then
                ContainerFrame1:SetUserPlaced(false)
            end
            if ContainerFrameCombinedBags and not (Akimbo.db and Akimbo.db.savedWorkspacePositions and Akimbo.db.savedWorkspacePositions["ContainerFrameCombinedBags"]) then
                ContainerFrameCombinedBags:SetUserPlaced(false)
            end
            if PlayerFrame then PlayerFrame:SetUserPlaced(false) end
            if TargetFrame then TargetFrame:SetUserPlaced(false) end
            if MinimapCluster and not (Akimbo.db and Akimbo.db.savedWorkspacePositions and Akimbo.db.savedWorkspacePositions["MinimapCluster"]) then
                MinimapCluster:SetUserPlaced(false)
            end
            if SetCVar then
                SetCVar("rawMouseEnable", "1")
                SetCVar("rawMouseAccelerationEnable", "0")
            end
        end)
        Akimbo:ApplyFullLayout()
        Akimbo:Print("v%s loaded! Type |cffffcc00/akimbo|r to configure.", Akimbo.version)
        if not Akimbo.db.firstRunComplete then
            C_Timer.After(1.5, function()
                Akimbo:Print("First time using Akimbo? Type |cff00ff00/akimbo wizard|r for 1-click auto-setup & calibration.")
            end)
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Refresh viewport and layout after zone transition or loading screen
        C_Timer.After(0.5, function()
            Akimbo:ApplyFullLayout()
        end)

    elseif event == "PLAYER_REGEN_ENABLED" then
        ProcessCombatQueue()

    elseif event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        if not Akimbo._displayDebounceTimer then
            Akimbo._displayDebounceTimer = C_Timer.NewTimer(0.2, function()
                Akimbo._displayDebounceTimer = nil
                Akimbo:RunOrQueueCombat(function()
                    Akimbo:ApplyFullLayout()
                end)
            end)
        end
    end
end)

-- Convenience master layout apply with reentrancy protection
local isApplyingLayout = false
local layoutPending = false

function Akimbo:ApplyFullLayout()
    if not Akimbo.db then return end
    if InCombatLockdown() then
        if not layoutPending then
            layoutPending = true
            self:RunOrQueueCombat(function()
                layoutPending = false
                Akimbo:ApplyFullLayout()
            end)
        end
        return
    end
    if isApplyingLayout then return end
    isApplyingLayout = true

    local success, err = pcall(function()
        if Akimbo.Viewport and Akimbo.Viewport.ApplyGlobalScale then Akimbo.Viewport:ApplyGlobalScale() end
        if Akimbo.UpdateViewport then
            Akimbo:UpdateViewport()
        end
        if Akimbo.UpdateCanvas then
            Akimbo:UpdateCanvas()
        end
        if Akimbo.UpdateSeamRedirect then
            Akimbo:UpdateSeamRedirect()
        end
        for _, module in pairs(Akimbo.modules) do
            if module.ApplyLayout then
                module:ApplyLayout()
            end
        end
    end)

    isApplyingLayout = false
    if not success then
        Akimbo:Print("Layout error: %s", tostring(err))
    end
end

-- ============================================================================
-- Primary Slash Command Registration (Registered immediately on load)
-- ============================================================================
SLASH_AKIMBO1 = "/akimbo"
SLASH_AKIMBO2 = "/ak"

SlashCmdList["AKIMBO"] = function(msg)
    msg = strtrim(msg or ""):lower()

    local cmd, arg = strsplit(" ", msg, 2)

    if cmd == "16:9" or cmd == "16/9" or cmd == "169" then
        Akimbo.db.aspectRatioMode = "16_9"
        Akimbo:ApplyFullLayout()
        Akimbo:Print("Aspect Ratio locked to 16:9 (Standard Widescreen).")
    elseif cmd == "21:9" or cmd == "21/9" or cmd == "219" then
        Akimbo.db.aspectRatioMode = "21_9"
        Akimbo:ApplyFullLayout()
        Akimbo:Print("Aspect Ratio locked to 21:9 (Ultrawide).")
    elseif cmd == "fill" then
        Akimbo.db.aspectRatioMode = "FILL"
        Akimbo:ApplyFullLayout()
        Akimbo:Print("Using configured game height. Adjust with /akimbo height <5-100 percent>.")
    elseif (cmd == "ar" or cmd == "fov") and tonumber(arg) then
        local ratio = tonumber(arg)
        Akimbo.db.aspectRatioMode = "CUSTOM"
        Akimbo.db.customAspectRatio = ratio
        Akimbo:ApplyFullLayout()
        Akimbo:Print("Custom Aspect Ratio set to %.3f:1.", ratio)
    elseif cmd == "hud" or cmd == "scale" then
        if tonumber(arg) then
            local scale = tonumber(arg)
            if scale > 1.25 then scale = scale / 100 end
            scale = math.max(0.25, math.min(1.25, scale))
            Akimbo.db.hudScale = scale
            Akimbo:ApplyFullLayout()
            Akimbo:Print("Global UI size set to %.0f%% of game view.", scale * 100)
        else
            Akimbo:Print("Current global UI size multiplier: %.2f (default 0.70). Usage: /akimbo hud <25-125 percent>", Akimbo.db.hudScale or 0.70)
        end
    elseif cmd == "chat" then
        arg = strtrim(arg or ""):lower()
        if arg == "deck" or arg == "secondary" or arg == "bay" then
            Akimbo.db.chatPosition = "DECK"
            Akimbo:ApplyFullLayout()
            Akimbo:Print("Chat docked to Command Deck (Bottom Bay).")
        elseif arg == "game" or arg == "hud" or arg == "primary" then
            Akimbo.db.chatPosition = "GAME"
            Akimbo:ApplyFullLayout()
            Akimbo:Print("Chat locked to 3D Game Monitor (Bottom-Left).")
        else
            -- Toggle
            Akimbo.db.chatPosition = (Akimbo.db.chatPosition == "DECK") and "GAME" or "DECK"
            Akimbo:ApplyFullLayout()
            Akimbo:Print("Chat position toggled to: %s.", Akimbo.db.chatPosition)
        end
    elseif (cmd == "deck" or cmd == "seam") and tonumber(arg) then
        local pct = tonumber(arg)
        if pct > 1 then pct = pct / 100 end
        pct = math.max(0.15, math.min(0.80, pct))
        Akimbo.db.deckWidthRatio = pct
        Akimbo:ApplyFullLayout()
        Akimbo:Print("Seam & Secondary Deck width set to %.1f%%.", pct * 100)
    elseif cmd == "bottom" and tonumber(arg) then
        Akimbo.db.gameBottomPixels = math.max(0, tonumber(arg))
        Akimbo:ApplyFullLayout()
        Akimbo:Print("Game bottom inset set to %.0f pixels.", Akimbo.db.gameBottomPixels)
    elseif cmd == "height" and tonumber(arg) then
        local pct = tonumber(arg)
        if pct > 1 then pct = pct / 100 end
        pct = math.max(0.05, math.min(1, pct))
        Akimbo.db.gameHeightRatio = pct
        Akimbo:ApplyFullLayout()
        Akimbo:Print("Game height set to %.0f%% of canvas (used in Fill mode).", pct * 100)
    elseif cmd == "diag" or cmd == "metrics" or cmd == "info" then
        local snapshot = Akimbo.Viewport:CaptureDiagnostics()
        Akimbo:Print("Viewport bounds check: %s.", snapshot.viewportMatches and "PASS" or "MISMATCH")
        local physW, physH = 0, 0
        if GetPhysicalScreenSize then pcall(function() physW, physH = GetPhysicalScreenSize() end) end
        local screenW = GetScreenWidth()
        local screenH = GetScreenHeight()
        local m = Akimbo.Viewport and Akimbo.Viewport:GetMetrics() or {}
        local effScale = UIParent and UIParent:GetEffectiveScale() or 1.0
        Akimbo:Print("Game pixels: %dx%d at (%d, %d), global UI scale %.3f.",
            m.gamePixelWidth or 0, m.gamePixelHeight or 0, m.gamePixelLeft or 0,
            m.gamePixelBottom or 0, effScale)
        Akimbo:Print("Diagnostics: Phys=%dx%d | Screen=%dx%d | EffScale=%.3f | DeckWidth=%d (%.1f%%) | GameArea=%dx%d",
            physW, physH, screenW, screenH, effScale, m.deckWidth or 0, (Akimbo.db.deckWidthRatio or 0) * 100, m.gameWidth or 0, m.gameHeight or 0)
    elseif msg == "apply" or msg == "reload" then
        Akimbo:ApplyFullLayout()
        Akimbo:Print("Layout reapplied!")
    elseif msg == "reset" then
        Akimbo:ResetConfig()
    elseif msg == "toggle" then
        Akimbo.db.enabled = not Akimbo.db.enabled
        Akimbo:Print("Akimbo is now %s.", Akimbo.db.enabled and "|cff00ff00Enabled|r" or "|cffff3333Disabled|r")
        Akimbo:ApplyFullLayout()
    elseif msg == "debug" then
        Akimbo.db.debugMode = not Akimbo.db.debugMode
        Akimbo:Print("Debug mode %s.", Akimbo.db.debugMode and "|cff00ff00On|r" or "|cffff3333Off|r")
    elseif cmd == "wizard" or cmd == "setup" or cmd == "calibrate" then
        if Akimbo.Wizard and Akimbo.Wizard.Open then
            Akimbo.Wizard:Open()
        elseif Akimbo.Options and Akimbo.Options.Open then
            Akimbo.Options:Open(true)
        end
    elseif msg == "settings" or msg == "options" or msg == "config" then
        if Akimbo.Options and Akimbo.Options.Open then
            Akimbo.Options:Open()
        end
    elseif msg == "span" or msg == "guide" then
        if Akimbo.Options and Akimbo.Options.ShowSetupGuide then
            Akimbo.Options:ShowSetupGuide()
        else
            Akimbo:Print("Use the included Akimbo-Span.bat to stretch WoW across both monitors.")
        end
    else
        if Akimbo.Options and Akimbo.Options.Open then
            Akimbo.Options:Open()
        else
            Akimbo:Print("Status: %s. Type |cffffcc00/akimbo|r for options, or |cff00ff00/akimbo wizard|r for auto-setup.", 
                Akimbo.db.enabled and "|cff00ff00Enabled|r" or "|cffff3333Disabled|r")
        end
    end
end
