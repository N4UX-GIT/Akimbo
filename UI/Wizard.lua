--[[
    Akimbo: Dual Monitor Workstation Addon
    UI/Wizard.lua: Wizard entry point (delegates to authoritative unified dashboard)
--]]

local _, Akimbo = ...

local Wizard = {}
Akimbo.Wizard = Wizard

function Wizard:DetectTopology()
    if Akimbo.Options and Akimbo.Options.DetectTopology then
        return Akimbo.Options:DetectTopology()
    end
    return {
        physWidth = 1920,
        physHeight = 1080,
        aspectRatio = 16 / 9,
        isSpanned = false,
        recommendedPreset = "PORTRAIT_LEFT_LANDSCAPE_RIGHT",
        recommendedDeckRatio = 0.36,
        description = "Standard Window",
    }
end

function Wizard:Open()
    if Akimbo.Options and Akimbo.Options.Open then
        Akimbo.Options:Open(true)
    end
end

function Wizard:Close()
    if Akimbo.Options and Akimbo.Options.Close then
        Akimbo.Options:Close()
    end
end

function Akimbo:OpenWizard()
    Wizard:Open()
end
