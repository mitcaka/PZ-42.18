local group = AttachedLocations and AttachedLocations.getGroup and AttachedLocations.getGroup("Human") or nil
if not group then return end

group:getOrCreateLocation("FWP SlingRifle"):setAttachmentName("fwp_sling_rifle")
group:getOrCreateLocation("FWP SlingRifle2"):setAttachmentName("fwp_sling_rifle2")
group:getOrCreateLocation("FWP SlingRifle3"):setAttachmentName("fwp_sling_rifle3")
group:getOrCreateLocation("FWP SlingRifle Back"):setAttachmentName("fwp_sling_rifleback")

group:getOrCreateLocation("FWP SlingWeapon"):setAttachmentName("fwp_sling_weapon")
group:getOrCreateLocation("FWP SlingWeapon2"):setAttachmentName("fwp_sling_weapon2")
group:getOrCreateLocation("FWP SlingWeapon3"):setAttachmentName("fwp_sling_weapon3")
group:getOrCreateLocation("FWP SlingWeapon Back"):setAttachmentName("fwp_sling_weaponback")

group:getOrCreateLocation("FWP SlingShovel"):setAttachmentName("fwp_sling_shovel")
group:getOrCreateLocation("FWP SlingShovel2"):setAttachmentName("fwp_sling_shovel2")
group:getOrCreateLocation("FWP SlingShovel3"):setAttachmentName("fwp_sling_shovel3")
group:getOrCreateLocation("FWP SlingShovel Back"):setAttachmentName("fwp_sling_shovelback")
