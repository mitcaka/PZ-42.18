local function applyFlashlightAttachedLocations()
    if not AttachedLocations or not AttachedLocations.getGroup then
        return
    end

    local group = AttachedLocations.getGroup("Human")
    if not group or not group.getOrCreateLocation then
        return
    end

    local function safeLoc(name, attachment)
        local loc = group:getOrCreateLocation(name)
        if loc and loc.setAttachmentName then
            loc:setAttachmentName(attachment)
        end
    end

    safeLoc("BeltTorchLeftSmall", "torch_left_small")
    safeLoc("BeltTorchLeftVerySmall", "torch_left_verysmall")
    safeLoc("BeltTorchRightSmall", "torch_right_small")
    safeLoc("BeltTorchRightVerySmall", "torch_right_verysmall")
    safeLoc("BeltTorchLeftAngled", "torch_left_angled")
    safeLoc("BeltTorchRightAngled", "torch_right_angled")
    safeLoc("WebbingTorchLeftAngled", "webbing_left_walkie")
    safeLoc("WebbingTorchRightAngled", "webbing_right_walkie")
    safeLoc("WebbingTorchLeftSmall", "webbing_left_walkie")
    safeLoc("WebbingTorchRightSmall", "webbing_right_walkie")
    safeLoc("WebbingTorchLeftVerySmall", "webbing_left_walkie")
    safeLoc("WebbingTorchRightVerySmall", "webbing_right_walkie")

    -- Bag bottom weapon attach locations
    safeLoc("Big Weapon Bottom Bag", "big_weapon_bottom_bag")
    safeLoc("Big Weapon Bottom Bag Big", "big_weapon_bottom_bag_big")
    safeLoc("Big Weapon Bottom Bag ALICE", "big_weapon_bottom_bag_alice")
    safeLoc("Big Blade Bottom Bag", "big_blade_bottom_bag")
    safeLoc("Big Blade Bottom Bag Big", "big_blade_bottom_bag_big")
    safeLoc("Big Blade Bottom Bag ALICE", "big_blade_bottom_bag_alice")
    safeLoc("Racket Bottom Bag", "racket_bottom_bag")
    safeLoc("Racket Bottom Bag Big", "racket_bottom_bag_big")
    safeLoc("Racket Bottom Bag ALICE", "racket_bottom_bag_alice")
    safeLoc("Shovel Bottom Bag", "shovel_bottom_bag")
    safeLoc("Shovel Bottom Bag Big", "shovel_bottom_bag_big")
    safeLoc("Shovel Bottom Bag ALICE", "shovel_bottom_bag_alice")
    safeLoc("Pan Bottom Bag", "pan_bottom_bag")
    safeLoc("Pan Bottom Bag Big", "pan_bottom_bag_big")
    safeLoc("Pan Bottom Bag ALICE", "pan_bottom_bag_alice")
    safeLoc("Rifle Bottom Bag", "rifle_bottom_bag")
    safeLoc("Rifle Bottom Bag Big", "rifle_bottom_bag_big")
    safeLoc("Rifle Bottom Bag ALICE", "rifle_bottom_bag_alice")
    safeLoc("Saucepan Bottom Bag", "saucepan_bottom_bag")
    safeLoc("Saucepan Bottom Bag Big", "saucepan_bottom_bag_big")
    safeLoc("Saucepan Bottom Bag ALICE", "saucepan_bottom_bag_alice")

    -- Left-side backpack weapon attach locations
    safeLoc("Big Weapon Left Bag", "big_weapon_left_bag")
    safeLoc("Big Weapon Left Bag Big", "big_weapon_left_bag_big")
    safeLoc("Big Weapon Left Bag ALICE", "big_weapon_left_bag_alice")
    safeLoc("Big Blade Left Bag", "big_blade_left_bag")
    safeLoc("Big Blade Left Bag Big", "big_blade_left_bag_big")
    safeLoc("Big Blade Left Bag ALICE", "big_blade_left_bag_alice")
    safeLoc("Racket Left Bag", "racket_left_bag")
    safeLoc("Racket Left Bag Big", "racket_left_bag_big")
    safeLoc("Racket Left Bag ALICE", "racket_left_bag_alice")
    safeLoc("Shovel Left Bag", "shovel_left_bag")
    safeLoc("Shovel Left Bag Big", "shovel_left_bag_big")
    safeLoc("Shovel Left Bag ALICE", "shovel_left_bag_alice")
    safeLoc("Pan Left Bag", "pan_left_bag")
    safeLoc("Pan Left Bag Big", "pan_left_bag_big")
    safeLoc("Pan Left Bag ALICE", "pan_left_bag_alice")
    safeLoc("Rifle Left Bag", "rifle_left_bag")
    safeLoc("Rifle Left Bag Big", "rifle_left_bag_big")
    safeLoc("Rifle Left Bag ALICE", "rifle_left_bag_alice")
    safeLoc("Saucepan Left Bag", "saucepan_left_bag")
    safeLoc("Saucepan Left Bag Big", "saucepan_left_bag_big")
    safeLoc("Saucepan Left Bag ALICE", "saucepan_left_bag_alice")
end

local _flashlightApplied = false
local function applyFlashlightAttachedLocationsOnce()
    if _flashlightApplied then return end
    _flashlightApplied = true
    applyFlashlightAttachedLocations()
end
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(applyFlashlightAttachedLocationsOnce)
end
if Events and Events.OnServerStarted then
    Events.OnServerStarted.Add(applyFlashlightAttachedLocationsOnce)
end
