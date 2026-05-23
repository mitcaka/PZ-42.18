-- Antibodies entry point.
--
-- Previously this file patched ISHealthPanel to inject a button next to
-- the Fitness button.  That path is fragile in MP because vanilla Java
-- numeric getters (getX/getWidth/getRight) can return Java Number
-- objects which Kahlua refuses to add to Lua ints -- the resulting
-- `__add not defined for operands` is logged by PZ's error handler,
-- which then halts further Lua execution for the frame and bricks
-- unrelated UI like inventory clicks and the hotbar.
--
-- v1.x: the Antibody panel is now opened from the CSR Utility HUD via a
-- dedicated button (see CSR_UtilityHud.createChildren), so this file
-- only carries the public openPanel() helper.  The previous ISHealthPanel
-- monkey-patch has been removed.

require "CSR_FeatureFlags"
require "CSR_AntibodiesPanel"

CSR_AntibodiesEntry = CSR_AntibodiesEntry or {}

function CSR_AntibodiesEntry.open(playerObj)
    if not CSR_FeatureFlags.isAntibodySystemEnabled() then return end
    local doctor = playerObj or getPlayer()
    if not doctor then return end
    CSR_AntibodiesPanel.open(doctor, doctor)
end
