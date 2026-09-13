-- Docked map is an independent window; other panels retain Blizzard behavior.
local _, Offhand = ...
local Akimbo = Offhand
local L = Offhand.L or Akimbo.L or setmetatable({}, { __index = function(t, k) return k end })
local Map = {}
Offhand.modules.MapDock = Map
Akimbo.modules.MapDock = Map
local busy=false
local scheduled=false
function Map:Schedule()
    if busy or scheduled then return end
    scheduled=true
    C_Timer.After(0,function() scheduled=false; Map:Configure() end)
end

function Map:Configure()
    local frame=WorldMapFrame
    if not frame or busy or InCombatLockdown() then return end
    busy=true
    local ok,err=pcall(function()
        local enabled=Akimbo.db.enabled and Akimbo.db.dockMap
        if enabled and not self.original then
            local info=UIPanelWindows and UIPanelWindows.WorldMapFrame
            if not SetUIPanelAttribute or not info then return end
            self.original={area=info.area, width=frame.minimizedWidth, height=frame.minimizedHeight,
                ignoreScale=frame.IsIgnoringParentScale and frame:IsIgnoringParentScale(),
                moving=frame:IsEventRegistered("PLAYER_STARTED_MOVING"), mini=GetCVar("miniWorldMap")}
            if frame.SetIgnoreParentScale then frame:SetIgnoreParentScale(false) end
            -- Release any current panel-stack slot before taking ownership.
            local shown=frame:IsShown()
            if shown then HideUIPanel(frame) end
            SetUIPanelAttribute(frame,"area",nil)
            if GetCVar("miniWorldMap")~="1" then SetCVar("miniWorldMap","1") end
            if frame.Minimize then frame:Minimize() end
            SetUIPanelAttribute(frame,"area",nil)
            if shown then frame:Show() end
        elseif not enabled and self.original then
            local original=self.original
            local shown=frame:IsShown()
            if shown then frame:Hide() end
            frame.minimizedWidth,frame.minimizedHeight=original.width,original.height
            if frame.SetIgnoreParentScale then frame:SetIgnoreParentScale(original.ignoreScale or false) end
            if MiniBorderLeft then MiniBorderLeft:SetSize(512,512) end
            if MiniBorderRight then MiniBorderRight:SetSize(128,512) end
            SetUIPanelAttribute(frame,"area",original.area)
            if original.moving then frame:RegisterEvent("PLAYER_STARTED_MOVING") end
            self.original=nil
            if self.grip then self.grip:Hide() end
            if self.handle then self.handle:Hide() end
            if original.mini and GetCVar("miniWorldMap")~=original.mini then SetCVar("miniWorldMap",original.mini) end
            if shown then ShowUIPanel(frame) end
            return
        end
        if not enabled or not self.original then return end
        if frame._akimboDragging then return end
        -- Minimize/RestoreUIPanelArea can reset metadata, so detach after sync too.
        SetUIPanelAttribute(frame,"area",nil)
        if Akimbo.db.preventMapCloseOnMove then frame:UnregisterEvent("PLAYER_STARTED_MOVING")
        elseif self.original.moving then frame:RegisterEvent("PLAYER_STARTED_MOVING") end
        if frame.IsMaximized and frame:IsMaximized() then frame:Minimize() end
        SetUIPanelAttribute(frame,"area",nil)
        local size=Akimbo.db.mapWindowSize
        if size and not frame._akimboDragging then
            local m=Akimbo.Viewport:GetMetrics()
            local factor=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
            local width=math.max(320,math.min(tonumber(size.width) or 610,(m.deckWidth-48)/factor))
            local height=math.max(240,math.min(tonumber(size.height) or 438,(m.screenHeight-48)/factor))
            frame.minimizedWidth,frame.minimizedHeight=width,height
            if math.abs(frame:GetWidth()-width)>0.01 or math.abs(frame:GetHeight()-height)>0.01 then
                frame:SetSize(width,height)
                if frame.OnFrameSizeChanged then frame:OnFrameSizeChanged() end
            end
        end
        -- Era's small-map border uses fixed-size textures instead of nine-slice.
        -- Resize the artwork together with the actual map canvas.
        local width,height=frame:GetWidth(),frame:GetHeight()
        if MiniBorderLeft then MiniBorderLeft:SetSize(512*width/610,512*height/438) end
        if MiniBorderRight then MiniBorderRight:SetSize(128*width/610,512*height/438) end
        if WorldMapFrameCloseButton then
            WorldMapFrameCloseButton:ClearAllPoints()
            WorldMapFrameCloseButton:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-4,2)
        end
        if not self.grip then
            frame:SetResizable(true)
            local grip=CreateFrame("Button",nil,frame)
            grip:SetSize(20,20)
            grip:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-2,2)
            grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
            grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
            grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
            grip:SetScript("OnMouseDown",function(_,button)
                if button~="LeftButton" or InCombatLockdown() then return end
                local m=Akimbo.Viewport:GetMetrics()
                local factor=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
                if frame.SetResizeBounds then frame:SetResizeBounds(320,240,
                    math.max(320,(m.deckWidth-48)/factor),math.max(240,(m.screenHeight-48)/factor)) end
                frame._akimboDragging=true
                frame:StartSizing("BOTTOMRIGHT")
            end)
            grip:SetScript("OnMouseUp",function()
                if not frame._akimboDragging then return end
                frame:StopMovingOrSizing()
                frame._akimboDragging=false
                Akimbo.db.mapWindowSize={width=frame:GetWidth(),height=frame:GetHeight()}
                frame.minimizedWidth,frame.minimizedHeight=frame:GetWidth(),frame:GetHeight()
                if frame.OnFrameSizeChanged then frame:OnFrameSizeChanged() end
                if Akimbo.Panels then Akimbo.Panels:SavePosition(frame); Akimbo.Panels:Place(frame) end
            end)
            self.grip=grip
            -- The Blizzard title button owns mouse input; the map root's drag
            -- scripts never receive it. Add a handle without replacing its scripts.
            local handle=CreateFrame("Frame",nil,frame)
            handle:SetPoint("TOPLEFT",frame,"TOPLEFT",20,0)
            handle:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-70,0)
            handle:SetHeight(22)
            handle:SetFrameLevel(frame:GetFrameLevel()+10)
            handle:EnableMouse(true)
            handle:RegisterForDrag("LeftButton")
            handle:SetScript("OnDragStart",function()
                if InCombatLockdown() or not Akimbo.db.enabled or not Akimbo.db.dockMap then return end
                frame._akimboDragging=true
                frame:StartMoving()
            end)
            handle:SetScript("OnDragStop",function()
                frame:StopMovingOrSizing()
                frame._akimboDragging=false
                if Akimbo.Panels then Akimbo.Panels:SavePosition(frame); Akimbo.Panels:Place(frame) end
            end)
            self.handle=handle
        end
        self.grip:Show()
        if self.handle then self.handle:Show() end
        if Akimbo.Panels then Akimbo.Panels:Place(frame) end
    end)
    busy=false
    if not ok then Akimbo:Print(L["MSG_MAP_LAYOUT_ERROR"],tostring(err)) end
end

function Map:Initialize()
    local events=CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:SetScript("OnEvent",function() Map:ApplyLayout() end)
    self:ApplyLayout()
end

function Map:ApplyLayout()
    local frame=WorldMapFrame
    if not frame then return end
    if not self.hooked then
        self.hooked=true
        frame:HookScript("OnShow",function() Map:Schedule() end)
        if frame.SynchronizeDisplayState then
            hooksecurefunc(frame,"SynchronizeDisplayState",function() Map:Schedule() end)
        end
    end
    self:Configure()
end
