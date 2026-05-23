-- Body location insertion adapted from The Only Cure's B42 arm visual setup.
local function copyBodyLocationProperties(oldGroup, oldLocID, newGroup)
    for k = 0, oldGroup:size() - 1 do
        local otherLocID = oldGroup:getLocationByIndex(k):getId()
        if oldGroup:isExclusive(oldLocID, otherLocID) then
            newGroup:setExclusive(oldLocID, otherLocID)
        end
        if oldGroup:isHideModel(oldLocID, otherLocID) then
            newGroup:setHideModel(oldLocID, otherLocID)
        end
        if oldGroup:isAltModel(oldLocID, otherLocID) then
            newGroup:setAltModel(oldLocID, otherLocID)
        end
    end
end

local function addBodyLocationsAt(groupName, locationList)
    local results = {}
    local allGroupsList = BodyLocations.getAllGroups()
    local allGroups = {}

    for i = 0, allGroupsList:size() - 1 do
        allGroups[i + 1] = allGroupsList:get(i)
    end

    BodyLocations.reset()

    for i = 1, #allGroups do
        local oldGroup = allGroups[i]
        local newGroup = BodyLocations.getGroup(oldGroup:getId())

        for j = 0, oldGroup:size() - 1 do
            local oldLoc = oldGroup:getLocationByIndex(j)
            local oldLocID = oldLoc:getId()

            for _, locDef in ipairs(locationList) do
                if oldGroup:getId() == groupName then
                    local newLocID = type(locDef.name) ~= "string"
                        and locDef.name
                        or ItemBodyLocation.get(ResourceLocation.of(locDef.name))
                    local refLocID = type(locDef.reference) ~= "string"
                        and locDef.reference
                        or ResourceLocation.of(locDef.reference)

                    if refLocID == oldLocID and locDef.before then
                        results[locDef.name] = newGroup:getOrCreateLocation(newLocID)
                    end
                end
            end

            newGroup:getOrCreateLocation(oldLocID)

            for _, locDef in ipairs(locationList) do
                if oldGroup:getId() == groupName then
                    local newLocID = type(locDef.name) ~= "string"
                        and locDef.name
                        or ItemBodyLocation.get(ResourceLocation.of(locDef.name))
                    local refLocID = type(locDef.reference) ~= "string"
                        and locDef.reference
                        or ResourceLocation.of(locDef.reference)

                    if refLocID == oldLocID and not locDef.before then
                        results[locDef.name] = newGroup:getOrCreateLocation(newLocID)
                    end
                end
            end
        end

        for j = 0, oldGroup:size() - 1 do
            local oldLocID = oldGroup:getLocationByIndex(j):getId()
            newGroup:setMultiItem(oldLocID, oldGroup:isMultiItem(oldLocID))
            copyBodyLocationProperties(oldGroup, oldLocID, newGroup)
        end
    end

    return results
end

local results = addBodyLocationsAt("Human", {
    { name = "fam:Arm_L", reference = ItemBodyLocation.FULL_TOP, before = false },
    { name = "fam:Arm_R", reference = ItemBodyLocation.FULL_TOP, before = false },
    { name = "fam:ArmProst_L", reference = ItemBodyLocation.FULL_TOP, before = false },
    { name = "fam:ArmProst_R", reference = ItemBodyLocation.FULL_TOP, before = false },
})

if results["fam:Arm_L"] then results["fam:Arm_L"]:setMultiItem(false) end
if results["fam:Arm_R"] then results["fam:Arm_R"]:setMultiItem(false) end
if results["fam:ArmProst_L"] then results["fam:ArmProst_L"]:setMultiItem(false) end
if results["fam:ArmProst_R"] then results["fam:ArmProst_R"]:setMultiItem(false) end
