require 'NPCs/BodyLocations'

local bodyGroup = BodyLocations.getGroup("Human")
FWPBodyLocation = FWPBodyLocation or {}
FWPBodyLocation.SLING = FWPBodyLocation.SLING or ItemBodyLocation.register("fwp:FWPSling")
bodyGroup:getOrCreateLocation(FWPBodyLocation.SLING)
