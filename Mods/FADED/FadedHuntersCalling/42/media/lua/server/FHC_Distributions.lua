-- FHC_Distributions.lua
-- Loot-table entries for Hunter Hub literature.

require "Items/ProceduralDistributions"
require "FHC_Constants"

local function addToProcedural(tableName, item, weight)
    local list = ProceduralDistributions and ProceduralDistributions.list
    local dist = list and list[tableName]
    if not dist or not dist.items then return end
    table.insert(dist.items, item)
    table.insert(dist.items, weight)
end

local function addAnimalCallBooks()
    if FHC.DistributionsAdded then return end
    FHC.DistributionsAdded = true

    addToProcedural("BookstoreOutdoors", "Base.FHC_HuntersJournal", 2.0)
    addToProcedural("LibraryOutdoors", "Base.FHC_HuntersJournal", 1.0)
    addToProcedural("CrateBooks", "Base.FHC_HuntersJournal", 0.4)
    addToProcedural("LivingRoomShelfRedneck", "Base.FHC_HuntersJournal", 0.3)

    for _, animalKey in ipairs(FHC.ANIMAL_CALL_ORDER or {}) do
        local call = FHC.ANIMAL_CALLS and FHC.ANIMAL_CALLS[animalKey] or nil
        if call and call.book then
            addToProcedural("BookstoreOutdoors", call.book, 2.0)
            addToProcedural("LibraryOutdoors", call.book, 1.2)
            addToProcedural("BookstoreHobbies", call.book, 0.8)
            addToProcedural("LibrarySports", call.book, 0.6)
            addToProcedural("CrateBooks", call.book, 0.35)
            addToProcedural("LivingRoomShelfRedneck", call.book, 0.25)
        end
    end
end

Events.OnPreDistributionMerge.Add(addAnimalCallBooks)
