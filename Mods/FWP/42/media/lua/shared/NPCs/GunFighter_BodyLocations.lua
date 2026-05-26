require 'NPCs/BodyLocations'

local group = BodyLocations.getGroup("Human")
group:getOrCreateLocation(FWPBodyLocation.STUCK)
group:getOrCreateLocation(FWPBodyLocation.NV_EYES)



--[[	EXCLUSIVE CAUSES ERROR WHEN BACKPACK BUMPS SHIELD OFF BACK

group:getOrCreateLocation("Shield_Back")
group:getOrCreateLocation("Shield_Left")
group:getOrCreateLocation("Shield_Right")

group:setExclusive("Shield_Back", "Back")
group:setExclusive("Back", "Shield_Back")

group:setHideModel("", "")

group:setMultiItem("", true)

]]
