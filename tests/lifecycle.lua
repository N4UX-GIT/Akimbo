-- Run from the project root with Lua 5.1.
local addon = {}
local events = {}
local combat = false
GetBuildInfo = function() return "", "", "", 11509 end
CreateFrame = function()
    return { RegisterEvent = function() end,
        SetScript = function(_, name, fn) events[name] = fn end }
end
InCombatLockdown = function() return combat end
SlashCmdList = {}
assert(loadfile("Core/Init.lua"))("Akimbo", addon)
assert(loadfile("Core/Config.lua"))("Akimbo", addon)
local messages = {}
addon.Print = function(_, message) messages[#messages + 1] = message end

AkimboDB = { deckWidthRatio = 0.55, hudScale = 0.85 }
addon:InitializeConfig()
assert(addon.db.deckWidthRatio == 0.55, "migration changed seam")
assert(addon.db.hudScale == 0.85, "migration changed HUD scale")
AkimboDB = "invalid"
addon:InitializeConfig()
local defaultSeam = addon.db.deckWidthRatio
local defaultHeight = addon.db.gameHeightRatio
addon:ResetConfig()
assert(addon.db.deckWidthRatio == defaultSeam)
assert(addon.db.gameHeightRatio == defaultHeight)

local calls = 0
addon.UpdateViewport = function() calls = calls + 1 end
addon.UpdateCanvas = function() assert(not combat) end
combat = true
for i = 1, 20 do addon:ApplyFullLayout() end
assert(calls == 0, "layout ran during combat")
combat = false
events.OnEvent(nil, "PLAYER_REGEN_ENABLED")
assert(calls == 1, "combat requests were not coalesced")
addon.UpdateCanvas = function() error("injected layout failure") end
addon:ApplyFullLayout()
assert(messages[#messages] == "MSG_LAYOUT_ERROR", "failure was hidden")
addon.UpdateCanvas = function() addon:ApplyFullLayout() end
addon:ApplyFullLayout()
assert(calls == 3, "layout guard did not recover or prevent recursion")
print("PASS: config preservation, defaults, combat coalescing, error recovery, reentrancy")
