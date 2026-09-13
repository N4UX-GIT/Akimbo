--[[
    Offhand: Multi-Monitor Workspace Addon
    Modules/BagDock.lua: Container and inventory management for secondary workspace
--]]

local _, Offhand = ...

local BagDock = {}
Offhand.modules.BagDock = BagDock

function BagDock:Initialize()
    -- Hook container frames to remove screen clamping so they can be dragged freely to the secondary monitor
    for i = 1, (NUM_CONTAINER_FRAMES or 13) do
        local frame = _G["ContainerFrame" .. i]
        if frame then
            frame:SetClampedToScreen(false)
            frame:SetMovable(true)
        end
    end

    if ContainerFrameCombinedBags then
        ContainerFrameCombinedBags:SetClampedToScreen(false)
        ContainerFrameCombinedBags:SetMovable(true)
    end
end

function BagDock:ApplyLayout()
    -- No-op: Bags are freely positioned and dragged by the user
end

