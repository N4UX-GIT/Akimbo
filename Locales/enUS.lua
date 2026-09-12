--[[
    Akimbo: Dual Monitor Workstation Addon
    Locales/enUS.lua: English localization dictionary and comprehensive user help tooltips
--]]

local _, Akimbo = ...

local L = setmetatable({}, {
    __index = function(t, key)
        return key
    end
})

Akimbo.L = L

-- ============================================================================
-- Core & General Strings
-- ============================================================================
L["ADDON_TITLE"] = "Akimbo: Dual Monitor Workstation"
L["ADDON_DESC"] = "Transforms dual monitor setups into a dedicated primary 3D viewport and secondary command deck."
L["CMD_HELP_TITLE"] = "Akimbo Slash Commands"
L["LAYOUT_REAPPLIED"] = "Layout reapplied!"
L["CONFIG_SAVED"] = "Configuration saved! Welcome to Akimbo Dual Monitor Workstation."

-- ============================================================================
-- Options Dashboard Header & Tabs
-- ============================================================================
L["OPTIONS_TITLE"] = "AKIMBO DUAL MONITOR WORKSTATION"
L["TAB_DISPLAY"] = "Display & Viewport"
L["TAB_WORKSPACE"] = "Workspace & Map"
L["TAB_THEMES"] = "Themes & Colors"
L["BTN_AUTO_WIZARD"] = "Auto-Setup Wizard"
L["BTN_AUTO_WIZARD_TIP_TITLE"] = "Display Calibration Wizard"
L["BTN_AUTO_WIZARD_TIP_DESC"] = "Open the guided 1-click display configuration wizard to automatically detect your screen resolution and calibrate your physical monitor seam."

-- ============================================================================
-- Tab 1: Display & Viewport
-- ============================================================================
L["CARD_LAYOUT_PRESETS"] = "1. Monitor Layout Preset"
L["CARD_LAYOUT_PRESETS_DESC"] = "Select which physical monitor displays your 3D game world and which displays your 2D workspace."
L["PRESET_PL_LR"] = "Portrait Left + Game Right"
L["PRESET_PL_LR_TIP_TITLE"] = "Portrait Left + Game Right"
L["PRESET_PL_LR_TIP_DESC"] = "Ideal for setups with a vertical secondary monitor on the left and your main horizontal gaming monitor on the right."

L["PRESET_GL_PR"] = "Game Left + Portrait Right"
L["PRESET_GL_PR_TIP_TITLE"] = "Game Left + Portrait Right"
L["PRESET_GL_PR_TIP_DESC"] = "Ideal for setups with your main gaming monitor on the left and a vertical secondary monitor on the right."

L["PRESET_DUAL_LANDSCAPE"] = "Dual Landscape (50/50)"
L["PRESET_DUAL_LANDSCAPE_TIP_TITLE"] = "Dual Landscape (Side by Side)"
L["PRESET_DUAL_LANDSCAPE_TIP_DESC"] = "Splits the game window equally in half across two identical horizontal monitors side by side."

L["BTN_1CLICK_AUTOCONFIG"] = "1-Click Auto-Configure"
L["BTN_1CLICK_AUTOCONFIG_TIP_TITLE"] = "Automatic Hardware Detection"
L["BTN_1CLICK_AUTOCONFIG_TIP_DESC"] = "Queries your active screen resolution and automatically applies recommended seam ratio, monitor orientation, and 3D aspect ratio."

L["CARD_VIEWPORT_AR"] = "2. 3D Viewport Aspect Ratio & Position"
L["AR_16_9"] = "16:9 Standard Widescreen"
L["AR_16_9_TIP_TITLE"] = "16:9 Aspect Ratio"
L["AR_16_9_TIP_DESC"] = "Locks the 3D game camera to standard 16:9 widescreen. Letterboxes top and bottom if necessary to maintain natural perspective without horizontal stretching."

L["AR_21_9"] = "21:9 Ultrawide"
L["AR_21_9_TIP_TITLE"] = "21:9 Aspect Ratio"
L["AR_21_9_TIP_DESC"] = "Locks the 3D game camera to 21:9 cinematic ultrawide for expanded field of view."

L["AR_FILL"] = "Fit Window Height (Fill)"
L["AR_FILL_TIP_TITLE"] = "Fit Window Height (Fill Mode)"
L["AR_FILL_TIP_DESC"] = "Stretches the 3D viewport vertically to match the configured height percentage without top or bottom letterboxing."

L["ALIGN_LABEL"] = "Game Viewport Alignment:"
L["ALIGN_CENTER"] = "Center"
L["ALIGN_CENTER_TIP_TITLE"] = "Center Alignment"
L["ALIGN_CENTER_TIP_DESC"] = "Centers the 3D game viewport within your dedicated game monitor area."

L["ALIGN_LEFT"] = "Left"
L["ALIGN_LEFT_TIP_TITLE"] = "Left Alignment"
L["ALIGN_LEFT_TIP_DESC"] = "Anchors the 3D game viewport flush to the left boundary of your game monitor area."

L["ALIGN_RIGHT"] = "Right"
L["ALIGN_RIGHT_TIP_TITLE"] = "Right Alignment"
L["ALIGN_RIGHT_TIP_DESC"] = "Anchors the 3D game viewport flush to the right boundary of your game monitor area."

L["SLIDER_GAME_HEIGHT"] = "Game Height Ratio:"
L["SLIDER_GAME_HEIGHT_TIP_TITLE"] = "Game Viewport Height"
L["SLIDER_GAME_HEIGHT_TIP_DESC"] = "Adjusts what percentage of the total window height is occupied by the 3D game viewport when using Fill mode."

L["LABEL_BOTTOM_OFFSET"] = "Game bottom offset (pixels):"
L["LABEL_BOTTOM_OFFSET_TIP_TITLE"] = "Bottom Inset Offset"
L["LABEL_BOTTOM_OFFSET_TIP_DESC"] = "Pushes the bottom of the 3D game viewport upward by the specified number of pixels to clear taskbars or secondary HUD elements."

L["CARD_SEAM_CALIBRATION"] = "3. Physical Monitor Seam Alignment & Laser Guide"
L["SLIDER_SEAM_WIDTH"] = "Seam Width (Secondary Deck):"
L["SLIDER_SEAM_WIDTH_TIP_TITLE"] = "Physical Seam Position"
L["SLIDER_SEAM_WIDTH_TIP_DESC"] = "Defines where the boundary between your secondary workspace and 3D game monitor sits, as a percentage of total spanned screen width."

L["BTN_SEAM_MINUS"] = "- 1%"
L["BTN_SEAM_MINUS_TIP_TITLE"] = "Nudge Seam Left"
L["BTN_SEAM_MINUS_TIP_DESC"] = "Moves the monitor dividing seam 1% to the left."

L["BTN_SEAM_PLUS"] = "+ 1%"
L["BTN_SEAM_PLUS_TIP_TITLE"] = "Nudge Seam Right"
L["BTN_SEAM_PLUS_TIP_DESC"] = "Moves the monitor dividing seam 1% to the right."

L["BTN_LASER_TOGGLE"] = "Toggle Laser Guide"
L["BTN_LASER_TOGGLE_TIP_TITLE"] = "Physical Bezel Laser Guide"
L["BTN_LASER_TOGGLE_TIP_DESC"] = "Shows or hides a bright vertical red laser line on screen. Adjust your seam slider until the line aligns exactly with your physical monitor plastic bezel."

L["SLIDER_BEZEL_GAP"] = "Physical Bezel Gap Correction:"
L["SLIDER_BEZEL_GAP_TIP_TITLE"] = "Bezel Gap Compensation"
L["SLIDER_BEZEL_GAP_TIP_DESC"] = "Compensates for the physical plastic border between your screens by creating a blank dead zone to prevent visual misalignment across monitors."

-- ============================================================================
-- Tab 2: Workspace & Map
-- ============================================================================
L["CARD_WORKSPACE_MGMT"] = "1. Workspace Panel Management & Behavior"
L["CHECK_CANVAS_ENABLED"] = "Enable Akimbo Workspace Canvas"
L["CHECK_CANVAS_ENABLED_TIP_TITLE"] = "Akimbo Workspace Canvas"
L["CHECK_CANVAS_ENABLED_TIP_DESC"] = "Enables the secondary monitor workstation backdrop where UI panels, maps, character sheets, and bags are organized."

L["CHECK_ESC_PERSIST"] = "Keep Panels in Workspace on ESC (Independent Panels)"
L["CHECK_ESC_PERSIST_TIP_TITLE"] = "Independent Workspace Panels"
L["CHECK_ESC_PERSIST_TIP_DESC"] = "Prevents pressing Escape from closing panels docked in your secondary workspace. Escape will only clear targets or open the game menu on your main monitor."

L["CHECK_ALLOW_DRAG"] = "Allow Panel Cross-Seam Dragging"
L["CHECK_ALLOW_DRAG_TIP_TITLE"] = "Cross-Seam Dragging"
L["CHECK_ALLOW_DRAG_TIP_DESC"] = "Allows you to freely drag supported frames (Character Frame, Spellbook, Bags) across the seam between your game monitor and workspace."

L["CHECK_SEAM_REDIRECT"] = "Workspace Panel Redirection (Bags, Char, Spellbook)"
L["CHECK_SEAM_REDIRECT_TIP_TITLE"] = "Automatic Panel Redirection"
L["CHECK_SEAM_REDIRECT_TIP_DESC"] = "Automatically routes standard Blizzard panels (Character, Spellbook, Quest Log) into the secondary workspace deck upon opening."

L["CHECK_SEAM_SNAP"] = "Clean Seam Snapping & Edge Alignment"
L["CHECK_SEAM_SNAP_TIP_TITLE"] = "Edge Snapping"
L["CHECK_SEAM_SNAP_TIP_DESC"] = "Snaps dragging frames neatly to the workspace borders and monitor seam so your secondary workstation stays tidy."

L["SLIDER_HUD_SCALE"] = "Global UI & HUD Scale:"
L["SLIDER_HUD_SCALE_TIP_TITLE"] = "Global Interface Scale"
L["SLIDER_HUD_SCALE_TIP_DESC"] = "Resizes the entire user interface (action bars, unit frames, dialogs). Recommended: 56% to 70% for multi-monitor setups."

L["CARD_MINIMAP_CONFIG"] = "2. Minimap Configuration & Positioning"
L["CHECK_DOCK_MINIMAP"] = "Dock Minimap into Secondary Workspace Deck"
L["CHECK_DOCK_MINIMAP_TIP_TITLE"] = "Workspace Minimap Docking"
L["CHECK_DOCK_MINIMAP_TIP_DESC"] = "Moves the Minimap from your main game screen into the top of your secondary workspace deck, keeping your 3D view clean and uncluttered."

L["SLIDER_MINIMAP_SCALE"] = "Minimap Scale Multiplier:"
L["SLIDER_MINIMAP_SCALE_TIP_TITLE"] = "Minimap Size"
L["SLIDER_MINIMAP_SCALE_TIP_DESC"] = "Controls the size of the Minimap when docked in your secondary workspace (0.6x to 2.0x)."

L["CHECK_LOCK_MINIMAP"] = "Lock Minimap Position in Workspace"
L["CHECK_LOCK_MINIMAP_TIP_TITLE"] = "Lock Minimap"
L["CHECK_LOCK_MINIMAP_TIP_DESC"] = "Prevents accidental dragging or repositioning of the Minimap in your secondary deck."

L["BTN_RESET_MINIMAP"] = "Reset Minimap to Default Workspace Position"
L["BTN_RESET_MINIMAP_TIP_TITLE"] = "Reset Minimap"
L["BTN_RESET_MINIMAP_TIP_DESC"] = "Resets the Minimap position, frame strata, and layout to the top center of the secondary workspace deck."

L["CARD_BAG_MGMT"] = "3. Bag Management & Docking"
L["CHECK_DOCK_BAGS"] = "Auto-Dock All Bags into Secondary Deck"
L["CHECK_DOCK_BAGS_TIP_TITLE"] = "Secondary Deck Bag Docking"
L["CHECK_DOCK_BAGS_TIP_DESC"] = "Automatically places all opened container bags into your secondary workspace, clearing your gaming monitor for full combat visibility."

L["CHECK_VERTICAL_BAGS"] = "Force Vertical Bag Column Layout"
L["CHECK_VERTICAL_BAGS_TIP_TITLE"] = "Vertical Bag Columns"
L["CHECK_VERTICAL_BAGS_TIP_DESC"] = "Stacks open container bags neatly in vertical columns on your secondary screen instead of sprawling horizontally."

L["SLIDER_BAG_SCALE"] = "Bag Scale Multiplier:"
L["SLIDER_BAG_SCALE_TIP_TITLE"] = "Bag Window Size"
L["SLIDER_BAG_SCALE_TIP_DESC"] = "Adjusts the scale of your container bags on the secondary monitor (0.6x to 1.5x)."

-- ============================================================================
-- Tab 3: Themes & Colors
-- ============================================================================
L["CARD_THEMES"] = "1. Visual Theme Style Presets"
L["THEME_CLASSIC"] = "Classic Warcraft"
L["THEME_CLASSIC_DESC"] = "Authentic WoW dialog style with gold trim and stone backdrop"
L["THEME_CLASSIC_TIP_TITLE"] = "Classic Warcraft Theme"
L["THEME_CLASSIC_TIP_DESC"] = "Uses genuine Blizzard dialog art and authentic stone textures matching the original World of Warcraft aesthetic."

L["THEME_SLATE"] = "Blizzard Slate"
L["THEME_SLATE_DESC"] = "Muted charcoal dialog with pewter/silver trim"
L["THEME_SLATE_TIP_TITLE"] = "Blizzard Slate Theme"
L["THEME_SLATE_TIP_DESC"] = "A sophisticated dark charcoal theme with sleek silver-pewter borders."

L["THEME_TINKER"] = "Gnomish Tinker"
L["THEME_TINKER_DESC"] = "Clockwork brass borders with glowing cyan engineering accents"
L["THEME_TINKER_TIP_TITLE"] = "Gnomish Tinker Theme"
L["THEME_TINKER_TIP_DESC"] = "Inspired by Gnomish engineering blueprints, featuring antique brass trim and bright electric cyan energy accents."

L["THEME_OBSIDIAN"] = "Obsidian Dark"
L["THEME_OBSIDIAN_DESC"] = "Clean modern dark theme with subtle stone borders"
L["THEME_OBSIDIAN_TIP_TITLE"] = "Obsidian Dark Theme"
L["THEME_OBSIDIAN_TIP_DESC"] = "A clean, minimalist dark theme designed for modern gaming aesthetics."

L["THEME_PITCH_BLACK"] = "Pitch Black (OLED)"
L["THEME_PITCH_BLACK_DESC"] = "Pure black for OLED displays"
L["THEME_PITCH_BLACK_TIP_TITLE"] = "Pitch Black (OLED) Theme"
L["THEME_PITCH_BLACK_TIP_DESC"] = "Pure black background designed to turn off pixels on OLED displays for maximum contrast."

L["CARD_TRIM_COLOR"] = "2. Border Trim & Accent Color"
L["TRIM_GOLD"] = "Blizzard Gold"
L["TRIM_BRASS"] = "Clockwork Brass"
L["TRIM_CYAN"] = "Goggle Cyan"
L["TRIM_SILVER"] = "Pewter Silver"
L["TRIM_BRONZE"] = "Warm Bronze"
L["TRIM_EMERALD"] = "Emerald Green"
L["TRIM_CRIMSON"] = "Crimson Red"

L["CARD_CANVAS_BACKGROUND"] = "3. Secondary Deck Background Tone & Opacity"
L["CANVAS_STONE"] = "Classic Stone"
L["CANVAS_TINKER"] = "Tinker Slate"
L["CANVAS_CHARCOAL"] = "Charcoal Slate"
L["CANVAS_WARM_NIGHT"] = "Warm Night"
L["CANVAS_NAVY"] = "Midnight Navy"
L["CANVAS_BLACK"] = "Pitch Black"
L["SLIDER_CANVAS_OPACITY"] = "Canvas Background Opacity:"
L["SLIDER_CANVAS_OPACITY_TIP_TITLE"] = "Canvas Transparency"
L["SLIDER_CANVAS_OPACITY_TIP_DESC"] = "Adjusts how solid or translucent the secondary monitor workspace background appears (0% to 100%)."

-- ============================================================================
-- Wizard Dialog Strings & Tooltips
-- ============================================================================
L["WIZARD_TITLE"] = "AKIMBO AUTO-CONFIGURATION WIZARD"
L["WIZARD_CARD1_TITLE"] = "1. Display Topology & 1-Click Auto-Setup"
L["WIZARD_DETECTED_PREFIX"] = "Detected Display:"
L["WIZARD_RECOM_PREFIX"] = "Recommendation:"
L["WIZARD_BTN_AUTOCONFIG"] = "1-Click Auto-Configure & Apply (Recommended)"
L["WIZARD_BTN_AUTOCONFIG_TIP_TITLE"] = "Automatic 1-Click Calibration"
L["WIZARD_BTN_AUTOCONFIG_TIP_DESC"] = "Instantly calibrates your dual monitor setup based on detected screen resolution. Sets the seam split, 3D viewport, and orientation with a single click."
L["WIZARD_STATUS_READY"] = "Click above to automatically detect resolution and configure seam, orientation, and viewport."
L["WIZARD_STATUS_APPLIED"] = "[Applied] Setup automatically configured for %s"

L["WIZARD_CARD2_TITLE"] = "2. Monitor Orientation & 3D Viewport"
L["WIZARD_LABEL_LAYOUT"] = "Monitor Layout Preset:"
L["WIZARD_LABEL_AR"] = "3D Game Viewport Aspect Ratio:"

L["WIZARD_CARD3_TITLE"] = "3. Physical Monitor Seam Alignment"
L["WIZARD_SEAM_INSTRUCTION"] = "Align the red laser line with the physical bezel dividing your two monitors:"
L["WIZARD_LABEL_SEAM"] = "Bezel Seam Width:"
L["WIZARD_BTN_LASER_SHOW"] = "Show Laser"
L["WIZARD_BTN_LASER_HIDE"] = "Hide Laser"
L["WIZARD_PRESET_SEAM_36"] = "1440/4000 Seam (36%)"
L["WIZARD_PRESET_SEAM_36_TIP_TITLE"] = "1440p Portrait + 4K Landscape"
L["WIZARD_PRESET_SEAM_36_TIP_DESC"] = "Configures a 36% seam split, precisely tailored for a 1440x2560 portrait screen paired with a 2560x1440 landscape screen."

L["WIZARD_PRESET_SEAM_50"] = "Equal Split (50%)"
L["WIZARD_PRESET_SEAM_50_TIP_TITLE"] = "50% Equal Split"
L["WIZARD_PRESET_SEAM_50_TIP_DESC"] = "Splits the display exactly in half across two monitors of equal width."

L["WIZARD_PRESET_SEAM_55"] = "Custom Split (55%)"
L["WIZARD_PRESET_SEAM_55_TIP_TITLE"] = "55% Asymmetric Split"
L["WIZARD_PRESET_SEAM_55_TIP_DESC"] = "Places 55% of the total screen width on the left monitor and 45% on the right monitor."

L["WIZARD_CARD4_TITLE"] = "4. Global UI Scale & Calibration"
L["WIZARD_UI_SCALE_INSTRUCTION"] = "Adjust the overall size of the user interface to suit your monitor viewing distance:"
L["WIZARD_LABEL_UI_SCALE"] = "Global UI Scale:"
L["WIZARD_UI_SCALE_TIP_TITLE"] = "Global UI Scale"
L["WIZARD_UI_SCALE_TIP_DESC"] = "Scales all action bars, unit frames, and dialogs. Choose a compact scale (56% to 70%) to keep your game screen unobstructed."

L["WIZARD_PRESET_SCALE_56"] = "Compact (56%)"
L["WIZARD_PRESET_SCALE_56_TIP_TITLE"] = "Compact UI (56%)"
L["WIZARD_PRESET_SCALE_56_TIP_DESC"] = "Ultra-clean minimalist scale, freeing maximum screen space for 3D world visuals."

L["WIZARD_PRESET_SCALE_65"] = "Balanced (65%)"
L["WIZARD_PRESET_SCALE_65_TIP_TITLE"] = "Balanced UI (65%)"
L["WIZARD_PRESET_SCALE_65_TIP_DESC"] = "A well-balanced scale providing crisp text legibility while maintaining generous screen real estate."

L["WIZARD_PRESET_SCALE_70"] = "Standard (70%)"
L["WIZARD_PRESET_SCALE_70_TIP_TITLE"] = "Standard UI (70%)"
L["WIZARD_PRESET_SCALE_70_TIP_DESC"] = "Standard Akimbo default scale, ideal for 1440p and 4K displays at normal desk viewing distance."

L["WIZARD_PRESET_SCALE_100"] = "Default (100%)"
L["WIZARD_PRESET_SCALE_100_TIP_TITLE"] = "Unscaled UI (100%)"
L["WIZARD_PRESET_SCALE_100_TIP_DESC"] = "Standard 100% Blizzard UI size without scaling reductions."

L["WIZARD_BTN_ADVANCED"] = "Advanced Settings (/akimbo)"
L["WIZARD_BTN_ADVANCED_TIP_TITLE"] = "Advanced Settings"
L["WIZARD_BTN_ADVANCED_TIP_DESC"] = "Closes the wizard and opens the full 3-tab Akimbo options dashboard with complete customization controls."

L["WIZARD_BTN_FINISH"] = "Save & Finish Setup"
L["WIZARD_BTN_FINISH_TIP_TITLE"] = "Finish Calibration"
L["WIZARD_BTN_FINISH_TIP_DESC"] = "Saves your configuration, marks initial setup complete, and applies your new multi-monitor layout."
