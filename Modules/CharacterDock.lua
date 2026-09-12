-- Keep standard panels inside a physically visible monitor rectangle.
-- Leave UIPanelWindows intact so Blizzard's opening/closing logic still works.
local _, Akimbo = ...
local Panels = {}
Akimbo.modules.CharacterDock = Panels
Akimbo.Panels = Panels
local hooked, attempted, placing, queued = {}, {}, false, false
local pending = {}
local function IsTooltip(frame)
    return frame.IsObjectType and frame:IsObjectType("GameTooltip")
end
-- Enumerated children can expose frame methods but reject their receiver.
-- Probe without mutating so one inaccessible child cannot abort discovery.
local function Accessible(frame)
    if not frame then return false end
    local ok, allowed = pcall(function()
        if frame.IsForbidden and frame:IsForbidden() then return false end
        frame:GetName()
        return true
    end)
    return ok and allowed
end
local names = {
    "CharacterFrame", "SpellBookFrame", "PlayerSpellsFrame", "FriendsFrame",
    "TalentFrame", "PlayerTalentFrame", "QuestLogFrame", "QuestFrame",
    "TradeSkillFrame", "CraftFrame", "MerchantFrame", "MailFrame", "OpenMailFrame",
    "BankFrame", "PVEFrame", "InspectFrame", "MacroFrame", "TradeFrame",
    "ClassTrainerFrame", "GameMenuFrame", "SettingsPanel", "InterfaceOptionsFrame",
    "VideoOptionsFrame", "AudioOptionsFrame", "KeyBindingFrame", "HelpFrame",
    "WorldMapFrame", "ContainerFrameCombinedBags", "LFGParentFrame", "LFGListFrame",
    "LFDParentFrame", "RaidFrame", "GameTooltip", "ItemRefTooltip",
    "ShoppingTooltip1", "ShoppingTooltip2", "LibDBIconTooltip",
    "DropDownList1", "DropDownList2", "DropDownList3",
}

local function Inside(x,y,w,h,r)
    return x and y and x >= r.left-0.01 and y >= r.bottom-0.01
        and x+w <= r.right+0.01 and y+h <= r.top+0.01
end

function Panels:SavePosition(frame)
    if not Akimbo.db or not Akimbo.db.enabled or not Accessible(frame) or not frame:GetName() then return end
    if IsTooltip(frame) then return end
    local x,y,w,h=frame:GetRect()
    if not x then return end
    local m=Akimbo.Viewport:GetMetrics()
    local factor=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
    x,y,w,h=x*factor,y*factor,w*factor,h*factor
    local deckLeft=Akimbo.db.primaryPosition=="LEFT" and m.gameRight+m.bezel or 0
    local inDeck=x+w/2>=deckLeft and x+w/2<=deckLeft+m.deckWidth
    local left,top,width,height=m.gameLeft,m.gameTop,m.gameWidth,m.gameHeight
    if inDeck then left,top,width,height=deckLeft,m.screenHeight,m.deckWidth,m.screenHeight end
    Akimbo.db.panelPositions=Akimbo.db.panelPositions or {}
    Akimbo.db.panelPositions[frame:GetName()]={monitor=inDeck and "DECK" or "GAME",
        x=(x-left)/width,y=(top-y-h)/height}
end

function Panels:Place(frame)
    if Akimbo.SeamRedirect and Akimbo.SeamRedirect:IsManagedFrame(frame) then return end
    if placing or not Accessible(frame) or not frame:IsShown() or frame._akimboDragging
        or not Akimbo.db or not Akimbo.db.enabled then return end
    if InCombatLockdown() then
        if not queued then
            queued = true
            Akimbo:RunOrQueueCombat(function() queued=false; Panels:ApplyLayout() end)
        end
        return
    end
    placing=true
    local ok,err=pcall(function()
        local m=Akimbo.Viewport:GetMetrics()
        local game={left=m.gameLeft,bottom=m.gameBottom,right=m.gameRight,top=m.gameTop}
        local deckLeft=Akimbo.db.primaryPosition=="LEFT" and m.gameRight+m.bezel or 0
        local deck={left=deckLeft,bottom=0,right=deckLeft+m.deckWidth,top=m.screenHeight}
        local name=frame:GetName() or ""
        local tooltip=IsTooltip(frame)
        local isBag=name:match("^ContainerFrame%d+$") ~= nil or name=="ContainerFrameCombinedBags"
        local saved=not tooltip and Akimbo.db.panelPositions and Akimbo.db.panelPositions[name]
        local target=((frame==WorldMapFrame and Akimbo.db.dockMap)
            or (frame==CharacterFrame and Akimbo.db.dockCharacter)
            or (isBag and Akimbo.db.dockBags)) and deck or game
        local x,y,w,h=frame:GetRect()
        local factor=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
        if x then x,y,w,h=x*factor,y*factor,w*factor,h*factor end
        if tooltip and x then
            -- Keep native owner/cursor placement on either visible monitor.
            -- Only translate a completed tooltip when it crosses a monitor edge.
            if Inside(x,y,w,h,deck) or Inside(x,y,w,h,game) then return end
            local cx=x+w/2
            if cx>=deck.left and cx<=deck.right then target=deck end
        end
        local userPlaced=frame.IsUserPlaced and frame:IsUserPlaced()
        if not saved and userPlaced and x then
            if Inside(x,y,w,h,deck) then target=deck
            elseif Inside(x,y,w,h,game) then target=game end
        end
        if saved then target=saved.monitor=="DECK" and deck or game end
        local width,height=frame:GetWidth(),frame:GetHeight()
        if width<=0 or height<=0 then return end
        local margin=24*m.hudScale
        -- Preserve each addon's native relative scale. All roots inherit the same
        -- UIParent baseline; this module only owns placement and persistence.
        local scale=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
        frame:SetClampedToScreen(false) -- full UIParent includes invisible desktop gaps
        local nx,ny,nw,nh=frame:GetRect()
        local nf=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
        if nx then nx,ny,nw,nh=nx*nf,ny*nf,nw*nf,nh*nf end
        local safe={left=target.left+margin,bottom=target.bottom+margin,
            right=target.right-margin,top=target.top-margin}
        if not saved and Inside(nx,ny,nw,nh,safe) then return end
        local left,top
        if tooltip and nx then
            left=math.max(target.left+margin,math.min(nx,target.right-margin-width*scale))
            top=math.min(target.top-margin,math.max(ny+nh,target.bottom+margin+height*scale))
        elseif saved then
            left=target.left+(tonumber(saved.x) or 0)*(target.right-target.left)
            top=target.top-(tonumber(saved.y) or 0)*(target.top-target.bottom)
            left=math.max(target.left+margin,math.min(left,target.right-margin-width*scale))
            top=math.max(target.bottom+margin+height*scale,math.min(top,target.top-margin))
        elseif userPlaced and x then
            left=math.max(target.left+margin,math.min(x,target.right-margin-width*scale))
            top=math.max(target.bottom+margin+height*scale,math.min(y+h,target.top-margin))
        elseif frame==GameMenuFrame or frame==SettingsPanel then
            left=(target.left+target.right-width*scale)/2
            top=(target.bottom+target.top+height*scale)/2
        else
            local index=tonumber(name:match("^ContainerFrame(%d+)$")) or 1
            local offset=isBag and ((index-1)%5)*24*scale or 0
            left=target.left+margin+offset
            top=target.top-margin-offset
            left=math.max(target.left+margin,math.min(left,target.right-margin-width*scale))
            top=math.min(target.top-margin,math.max(top,target.bottom+margin+height*scale))
        end
        if nx and math.abs(nx-left)<0.01 and math.abs(ny+nh-top)<0.01 then return end
        -- Anchor-sized windows need explicit dimensions before removing anchors.
        frame:SetSize(width,height)
        frame:ClearAllPoints()
        if isBag then
            -- Blizzard replaces BOTTOMRIGHT without clearing existing anchors.
            -- Use that same anchor, so reopen cannot add a second size constraint.
            Akimbo.Viewport:SetPoint(frame,"BOTTOMRIGHT","BOTTOMLEFT",left+width*scale,top-height*scale)
        else
            Akimbo.Viewport:SetPoint(frame,"TOPLEFT","BOTTOMLEFT",left,top)
        end
    end)
    placing=false
    if not ok then Akimbo:Print("Panel layout error: %s",tostring(err)) end
end

-- SetPoint may be one of several anchors in a Blizzard layout transaction.
-- Never replace anchors synchronously inside that transaction.
function Panels:Schedule(frame)
    if placing or pending[frame] then return end
    pending[frame]=true
    C_Timer.After(0,function()
        pending[frame]=nil
        Panels:Place(frame)
    end)
end

function Panels:Discover()
    if InCombatLockdown() then return end
    local function Hook(frame)
        if not Accessible(frame) or attempted[frame] then return end
        attempted[frame]=true
        local function Place() if hooked[frame] then Panels:Schedule(frame) end end
        frame:HookScript("OnShow",Place)
        frame:HookScript("OnSizeChanged",Place)
        if frame.StartMoving and frame.StopMovingOrSizing then
            hooksecurefunc(frame,"StartMoving",function() if hooked[frame] then frame._akimboDragging=true end end)
            hooksecurefunc(frame,"StopMovingOrSizing",function()
                if hooked[frame] and frame._akimboDragging then
                    frame._akimboDragging=false
                    Panels:SavePosition(frame)
                    Panels:Place(frame)
                end
            end)
        end
        hooksecurefunc(frame,"SetPoint",Place)
        hooked[frame]=true
    end
    for _,name in ipairs(names) do pcall(Hook,_G[name]) end
    for i=1,(NUM_CONTAINER_FRAMES or 13) do pcall(Hook,_G["ContainerFrame"..i]) end
    -- Tooltips and library-created movable windows can be created after login.
    -- Only inspect top-level candidates; never rescale their individual children.
    if UIParent.GetChildren then
        for _,frame in ipairs({UIParent:GetChildren()}) do
            pcall(function()
                if not Accessible(frame) then return end
                local tooltip=frame.IsObjectType and frame:IsObjectType("GameTooltip")
                local window=frame.IsMovable and frame:IsMovable()
                local managed=Akimbo.SeamRedirect and Akimbo.SeamRedirect:IsManagedFrame(frame)
                if (tooltip or window) and not managed then Hook(frame) end
            end)
        end
    end
end

function Panels:Initialize()
    self:Discover()
    if C_Timer and C_Timer.NewTicker then
        self.discoveryTicker=C_Timer.NewTicker(1,function()
            if Akimbo.db and Akimbo.db.enabled then Panels:ApplyLayout() end
        end)
    end
    local events=CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED")
    events:SetScript("OnEvent",function() Panels:ApplyLayout() end)
    if ShowUIPanel then hooksecurefunc("ShowUIPanel",function(frame) if frame then Panels:Schedule(frame) end end) end
    if ContainerFrame_GenerateFrame then
        hooksecurefunc("ContainerFrame_GenerateFrame",function() C_Timer.After(0,function() Panels:ApplyLayout() end) end)
    end
end

function Panels:ApplyLayout()
    self:Discover()
    for frame in pairs(hooked) do self:Place(frame) end
end
