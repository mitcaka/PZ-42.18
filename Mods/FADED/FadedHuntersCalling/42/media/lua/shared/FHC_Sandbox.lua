-- FHC_Sandbox.lua
-- Thin convenience layer over SandboxVars.FadedHuntersCalling.
-- All keys default to safe values if the option is missing.

require "FHC_Constants"
require "FHC_Utils"

FHC.SB = FHC.SB or {}
local SB = FHC.SB
local U = FHC.Utils

function SB.enabled()              return U.sb("Enable_Mod", true) end
function SB.guiEnabled()           return SB.enabled() and U.sb("Enable_GUI", true) end
function SB.hotkeyEnabled()        return SB.guiEnabled() and U.sb("Enable_Hotkey", true) end

function SB.trapping()             return SB.enabled() and U.sb("Enable_Trapping", true) end
function SB.liveCapture()          return SB.trapping() and U.sb("Enable_LiveCapture", true) end
function SB.trapBoard()            return SB.trapping() and U.sb("Enable_TrapBoard", true) end

function SB.bushcraft()            return SB.enabled() and U.sb("Enable_Bushcraft", true) end
function SB.fieldDress()           return SB.bushcraft() and U.sb("Enable_FieldDress", true) end
function SB.meatDrying()           return SB.bushcraft() and U.sb("Enable_MeatDrying", true) end
function SB.hideCuring()           return SB.bushcraft() and U.sb("Enable_HideCuring", true) end

function SB.tools()                return SB.enabled() and U.sb("Enable_Tools", true) end

function SB.outline()              return SB.enabled() and U.sb("Enable_AnimalOutline", true) end
function SB.outlineAlwaysOnAllowed() return U.sb("Outline_AlwaysOn", false) end
function SB.outlineRadius()        return tonumber(U.sb("Outline_Radius", 30)) or 30 end

function SB.nearbyPanel()          return SB.enabled() and U.sb("Enable_NearbyPanel", true) end
function SB.mapMarkers()           return SB.enabled() and U.sb("Enable_MapMarkers", true) end
function SB.mapMarkersRadius()     return tonumber(U.sb("MapMarkers_Radius", 150)) or 150 end

function SB.traitHunter()          return SB.enabled() and U.sb("Trait_RegisterHunter", true) end
function SB.profTrapper()          return SB.enabled() and U.sb("Trait_RegisterTrapperProf", true) end
function SB.difficulty()           return tonumber(U.sb("Difficulty", 2)) or 2 end
function SB.processingSpeed()      return tonumber(U.sb("ProcessingSpeed", 1.0)) or 1.0 end
function SB.requireTools()         return U.sb("RequireTools", true) end

function SB.serverQoL()            return SB.enabled() and U.sb("Enable_ServerQoL", true) end
function SB.adminPop()             return SB.serverQoL() and U.sb("Enable_AdminPopulationControl", true) end

function SB.strictValidation()     return U.sb("MP_StrictValidation", true) end
function SB.debugLog()             return U.sb("Debug_Logging", false) end
function SB.scanThrottleMs()       return tonumber(U.sb("Scan_ThrottleMs", 500)) or 500 end
