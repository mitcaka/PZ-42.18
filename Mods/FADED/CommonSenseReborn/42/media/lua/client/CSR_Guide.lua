require "CSR_FeatureFlags"

--[[
    CSR_Guide.lua
    In-game guide window accessible from the Utility HUD.
    Uses ISCollapsableWindow + ISRichTextPanel to display feature documentation.
]]

CSR_Guide = {}

local guideWindow = nil

local GUIDE_SECTIONS = {
    {
        title = "Getting Started",
        text = "<SIZE:medium> <RGB:0.6,0.9,1.0> Common Sense Reborn <RGB:1,1,1> <SIZE:small> <LINE>"
            .. " <LINE> CSR adds practical quality-of-life features to Project Zomboid."
            .. " <LINE> <LINE> <RGB:1,0.8,0.3> Toggling Features On/Off <RGB:1,1,1>"
            .. " <LINE> Every feature can be toggled in <RGB:0.7,1,0.7> Sandbox Settings > Common Sense Reborn <RGB:1,1,1>."
            .. " <LINE> Access this from the main menu before starting, or from the admin"
            .. " <LINE> panel in multiplayer. Changes take effect immediately."
            .. " <LINE> <LINE> <RGB:1,0.8,0.3> Hiding UI Panels <RGB:1,1,1>"
            .. " <LINE> All CSR panels can be toggled with hotkeys (see Controls below)."
            .. " <LINE> Press the same hotkey again to hide any panel."
            .. " <LINE> The Utility HUD's Lock button prevents accidental dragging."
            .. " <LINE> Close this guide with the X button or the ? button on the HUD.",
    },
    {
        title = "Controls & Hotkeys",
        text = "<SIZE:medium> <RGB:1,0.7,0.3> Controls & Hotkeys <SIZE:small> <RGB:1,1,1> <LINE>"
            .. " <LINE> All hotkeys are rebindable via Mod Options (main menu or in-game)."
            .. " <LINE> <LINE> <RGB:0.6,0.9,1.0> HUD & Overlays <RGB:1,1,1>"
            .. " <LINE> <RGB:0.7,1,0.7> Numpad /    <RGB:1,1,1> Toggle Utility HUD"
            .. " <LINE> <RGB:0.7,1,0.7> Numpad *    <RGB:1,1,1> Toggle Zombie Density Overlay"
            .. " <LINE> <RGB:0.7,1,0.7> Numpad 0    <RGB:1,1,1> Toggle Nearby Density HUD"
            .. " <LINE> <RGB:0.7,1,0.7> Numpad 1    <RGB:1,1,1> Toggle Equipment Panel"
            .. " <LINE> <RGB:0.7,1,0.7> Numpad 3    <RGB:1,1,1> Toggle Vehicle Dashboard"
            .. " <LINE> <RGB:0.7,1,0.7> Numpad 4    <RGB:1,1,1> Toggle Survivor's Ledger"
            .. " <LINE> <RGB:0.7,1,0.7> Numpad 9    <RGB:1,1,1> Open TV / VCR / radio radial"
            .. " <LINE> <LINE> <RGB:0.6,0.9,1.0> Inventory <RGB:1,1,1>"
            .. " <LINE> <RGB:0.7,1,0.7> \\           <RGB:1,1,1> Open Loot Filter Dropdown (or click the F button on the inventory window)"
            .. " <LINE> <RGB:0.7,1,0.7> .           <RGB:1,1,1> Toggle Hide Equipped Items"
            .. " <LINE> <RGB:0.7,1,0.7> Tab         <RGB:1,1,1> Snap Loot Window to / from CSR Nearby virtual container"
            .. " <LINE> <RGB:0.7,1,0.7> Numpad 6    <RGB:1,1,1> Toggle Nested Containers"
            .. " <LINE> <LINE> <RGB:0.6,0.9,1.0> Actions <RGB:1,1,1>"
            .. " <LINE> <RGB:0.7,1,0.7> V           <RGB:1,1,1> Open the CSR radial menu"
            .. " <LINE> <RGB:0.7,1,0.7> Numpad +    <RGB:1,1,1> Toggle Seatbelt"
            .. " <LINE> <RGB:0.7,1,0.7> Numpad -    <RGB:1,1,1> Quick Sit / Stand"
            .. " <LINE> <RGB:0.7,1,0.7> Numpad 8    <RGB:1,1,1> Toggle Dual Wield"
            .. " <LINE> <RGB:0.7,1,0.7> Numpad 7    <RGB:1,1,1> Dual Wield Quick Equip swap (when DW is enabled)"
            .. " <LINE> <LINE> <RGB:0.6,0.9,1.0> Utility HUD Buttons <RGB:1,1,1>"
            .. " <LINE> <RGB:0.7,1,0.7> ? button    <RGB:1,1,1> Open/close this guide"
            .. " <LINE> <RGB:0.7,1,0.7> S button    <RGB:1,1,1> Open per-player CSR settings"
            .. " <LINE> <RGB:0.7,1,0.7> Lock/Unlock <RGB:1,1,1> Prevent accidental panel dragging"
            .. " <LINE> <RGB:0.7,1,0.7> P / Z / O   <RGB:1,1,1> Filter sound cues (Players/Zombies/Other)"
            .. " <LINE> <RGB:0.7,1,0.7> DW button   <RGB:1,1,1> Toggle Dual Wield on/off"
            .. " <LINE> <RGB:0.7,1,0.7> ES / EA     <RGB:1,1,1> Dual Wield emergency swap / entry actions"
            .. " <LINE> <RGB:0.7,1,0.7> LD / DH     <RGB:1,1,1> Survivor's Ledger / Nearby Density HUD"
            .. " <LINE> <RGB:0.7,1,0.7> Claims      <RGB:1,1,1> Open Personal, Faction, and Vehicle claims"
            .. " <LINE> <RGB:0.7,1,0.7> HP/Ammo/Zeds <RGB:1,1,1> Aim-cursor pills for health, ammo, and nearby density"
            .. " <LINE> <RGB:0.7,1,0.7> Journal     <RGB:1,1,1> Open the Skill Journal"
            .. " <LINE> <RGB:0.7,1,0.7> Admin       <RGB:1,1,1> Admin-only sandbox variable reference"
            .. " <LINE> <LINE> <RGB:0.6,0.9,1.0> Admin Control <RGB:1,1,1>"
            .. " <LINE> When Admin Authoritative Control is enabled in sandbox, per-player"
            .. " <LINE> toggles (DW, Nested Containers) are locked to the server values."
            .. " <LINE> Locked buttons show a lock indicator. Players cannot override.",
    },
    {
        title = "Pry System",
        text = "<SIZE:medium> <RGB:1,0.7,0.3> Pry System <SIZE:small> <RGB:1,1,1> <LINE>"
            .. " <LINE> Right-click doors, safes, and vehicle doors with a crowbar or pry tool to force them open."
            .. " <LINE> <RGB:0.7,1,0.7> Garage doors, safe doors, and vehicle doors <RGB:1,1,1> each have separate toggles."
            .. " <LINE> <RGB:0.7,1,0.7> Bolt cutters <RGB:1,1,1> can cut padlocks and chain-link fences."
            .. " <LINE> Tool condition matters -- damaged tools may break during use.",
    },
    {
        title = "Lockpicking",
        text = "<SIZE:medium> <RGB:1,0.7,0.3> Lockpicking <SIZE:small> <RGB:1,1,1> <LINE>"
            .. " <LINE> Use a screwdriver on locked doors to attempt picking the lock."
            .. " <LINE> Success depends on skill and luck. Higher Electrical skill helps.",
    },
    {
        title = "Vehicle Features",
        text = "<SIZE:medium> <RGB:1,0.7,0.3> Vehicle Features <SIZE:small> <RGB:1,1,1> <LINE>"
            .. " <LINE> <RGB:0.7,1,0.7> Mechanics QoL: <RGB:1,1,1> Batch uninstall parts, improved part inspection."
            .. " <LINE> <RGB:0.7,1,0.7> Vehicle Salvage: <RGB:1,1,1> Salvage wrecked vehicles for Mechanics and Metalworking XP."
            .. " <LINE> <RGB:0.7,1,0.7> Seatbelt: <RGB:1,1,1> Toggle with <RGB:0.7,1,0.7> Numpad + <RGB:1,1,1>. Reduces crash injury."
            .. " <LINE> <RGB:0.7,1,0.7> Dashboard: <RGB:1,1,1> Toggle with <RGB:0.7,1,0.7> Numpad 3 <RGB:1,1,1>. Color-coded gauges, clock, radio."
            .. " <LINE> <RGB:0.7,1,0.7> Smart Key Labels: <RGB:1,1,1> Keys show which vehicle they belong to."
            .. " <LINE> <RGB:0.7,1,0.7> Vehicle Claim: <RGB:1,1,1> Mark a vehicle as yours (MP safehouse integration)."
            .. " <LINE>   Claim keys are bound to the vehicle and reissue/revoke through the Claims panel."
            .. " <LINE> <RGB:0.7,1,0.7> Vehicle HVAC: <RGB:1,1,1> Vehicle heating/cooling affects player temperature."
            .. " <LINE> <RGB:0.7,1,0.7> Hotwire: <RGB:1,1,1> Improvised hotwiring with Electrical skill."
            .. " <LINE> <RGB:0.7,1,0.7> Remove Hotwire: <RGB:1,1,1> Seated as driver of a hotwired vehicle with the engine off and a screwdriver in inventory, the V radial menu shows a 'Remove Hotwire' slice."
            .. " <LINE>   Duration scales with Electricity and Mechanics. Costs 1 condition on the screwdriver. SP + MP. Toggle in sandbox: EnableUnHotwire."
            .. " <LINE> <RGB:0.7,1,0.7> Rope Tow: <RGB:1,1,1> Dead vehicles need rope, chain, heavy chain, or hook before towing. Sandbox: EnableRopeTow."
            .. " <LINE> <RGB:0.7,1,0.7> Corpse Trunk: <RGB:1,1,1> Put nearby corpses into accessible trunks, truck beds, trailers, or cargo containers. Sandbox: EnableCorpseTrunk.",
    },
    {
        title = "Combat & Survival",
        text = "<SIZE:medium> <RGB:1,0.7,0.3> Combat & Survival <SIZE:small> <RGB:1,1,1> <LINE>"
            .. " <LINE> <RGB:0.7,1,0.7> Point Blank: <RGB:1,1,1> Bonus damage at extremely close range."
            .. " <LINE> <RGB:0.7,1,0.7> Bullet Penetration: <RGB:1,1,1> Bullets can pass through killed zombies."
            .. " <LINE> <RGB:0.7,1,0.7> Dual Wield: <RGB:1,1,1> Hold a weapon in each hand. Toggle via HUD DW button."
            .. " <LINE>   Disabled by default -- enable in sandbox settings first."
            .. " <LINE>   If Admin Authoritative Control is on, the DW toggle is locked."
            .. " <LINE> <RGB:0.7,1,0.7> Back 2 Slot: <RGB:1,1,1> Carry two large weapons on your back."
            .. " <LINE> <RGB:0.7,1,0.7> Stop, Drop & Roll: <RGB:1,1,1> When on fire, right-click to drop and roll."
            .. " <LINE>   Lucky trait extinguishes faster. May damage outer clothing."
            .. " <LINE> <RGB:0.7,1,0.7> Corpse Ignite: <RGB:1,1,1> Burn zombie corpses with lighter + fuel."
            .. " <LINE> <RGB:0.7,1,0.7> Field Dress: <RGB:1,1,1> Optional last-resort corpse flesh from zombie bodies; player bodies require a separate sandbox toggle."
            .. " <LINE> <RGB:0.7,1,0.7> Hide in Furniture: <RGB:1,1,1> Hide in closets, beds, dumpsters, fridges, couches, tables, crates, barrels."
            .. " <LINE>   Become invisible to zombies AND lifted out of their pathfinding range while hidden, so wandering hordes can't crowd-attack you through the world."
            .. " <LINE>   Boredom increases. ESC or move to stop. Survives logout/reconnect -- your original position is restored on unhide. Container must not be too full."
            .. " <LINE> <RGB:0.7,1,0.7> Vision Cone Outline: <RGB:1,1,1> Zombies in your view cone glow with an outline."
            .. " <LINE>   Only while aiming (RMB). Requires melee outline in game settings."
            .. " <LINE> <RGB:0.7,1,0.7> Infection Resilience: <RGB:1,1,1> Small chance to survive a zombie infection."
            .. " <LINE>   When infection reaches a random threshold, the game rolls for survival."
            .. " <LINE>   Success converts the infection to a recoverable fever."
            .. " <LINE>   Multiple bites reduce your odds. All values configurable in sandbox."
            .. " <LINE> <RGB:0.7,1,0.7> Field Filters: <RGB:1,1,1> Craft makeshift respirator and gas mask filters."
            .. " <LINE>   Uses common materials (charcoal, ripped sheets, cans, tape)."
            .. " <LINE>   Filter lifespan multiplier adjustable in sandbox settings.",
    },
    {
        title = "Inventory & Items",
        text = "<SIZE:medium> <RGB:1,0.7,0.3> Inventory & Items <SIZE:small> <RGB:1,1,1> <LINE>"
            .. " <LINE> <RGB:0.7,1,0.7> Alternate Can Opening: <RGB:1,1,1> Open cans with knives, axes, etc."
            .. " <LINE> <RGB:0.7,1,0.7> Eat All Stack: <RGB:1,1,1> Eat or drink an entire stack at once."
            .. " <LINE> <RGB:0.7,1,0.7> Magazine Batch: <RGB:1,1,1> Load/unload all magazines at once."
            .. " <LINE> <RGB:0.7,1,0.7> Equipment QoL: <RGB:1,1,1> Quick equip improvements."
            .. " <LINE> <RGB:0.7,1,0.7> Loot Filter: <RGB:1,1,1> Click the <RGB:0.7,1,0.7> F <RGB:1,1,1> button on any inventory or loot window (or press <RGB:0.7,1,0.7> \\ <RGB:1,1,1>) to open a dropdown of category toggles, hide-equipped, whitelist, and reset."
            .. " <LINE> <RGB:0.7,1,0.7> Clipboard Filter: <RGB:1,1,1> Found in the filter dropdown under Personal. Hides items already on your clipboard checklists."
            .. " <LINE> <RGB:0.7,1,0.7> Proximity Loot: <RGB:1,1,1> Adds a <RGB:0.7,1,0.7> CSR Nearby <RGB:1,1,1> tab to the vanilla loot window aggregating every nearby container. Press <RGB:0.7,1,0.7> Tab <RGB:1,1,1> to snap to / from it. While selected the loot window border turns purple."
            .. " <LINE> <RGB:0.7,1,0.7> Hide Equipped: <RGB:1,1,1> Toggle with <RGB:0.7,1,0.7> . <RGB:1,1,1>. Hide equipped items in list."
            .. " <LINE> <RGB:0.7,1,0.7> Nested Containers: <RGB:1,1,1> Toggle with <RGB:0.7,1,0.7> Numpad 6 <RGB:1,1,1>. Bags show as buttons."
            .. " <LINE> <RGB:0.7,1,0.7> Item Insight Tooltips: <RGB:1,1,1> Extended item info on hover."
            .. " <LINE> <RGB:0.7,1,0.7> Item Rename: <RGB:1,1,1> Rename items with custom labels."
            .. " <LINE> <RGB:0.7,1,0.7> Tool Set: <RGB:1,1,1> Craft combined tool items (tool roll, toolbox)."
            .. " <LINE> <RGB:0.7,1,0.7> Bag Bottom Attach: <RGB:1,1,1> Attach weapons to the bottom of backpacks."
            .. " <LINE> <RGB:0.7,1,0.7> Backpack Left Slot: <RGB:1,1,1> Worn backpacks can expose a left-side hotbar slot for long weapons and tools."
            .. " <LINE> <RGB:0.7,1,0.7> Dismantle All Watches: <RGB:1,1,1> Batch dismantle watches for parts."
            .. " <LINE> <RGB:0.7,1,0.7> Extended Battery Life: <RGB:1,1,1> Flashlights, penlights, angle-head lights, and crafted electric lanterns use the sandbox BatteryLifeMultiplier."
            .. " <LINE> <RGB:0.7,1,0.7> Gear Sling: <RGB:1,1,1> Adds a dedicated csr:gearsling equip slot for shoulder bags, satchels, chest rigs, duffels, and other crossbody carriers."
            .. " <LINE>   Note: when EnableGearSling is on, sling bags move into csr:gearsling, while fanny packs use dedicated front/back CSR slots so both can still be worn together."
            .. " <LINE>   Disable EnableGearSling in sandbox to restore vanilla slot routing. The toggle requires a save reload to take effect because B42 CanBeEquipped is rewritten at startup.",
    },
    {
        title = "Actions & Comfort",
        text = "<SIZE:medium> <RGB:1,0.7,0.3> Actions & Comfort <SIZE:small> <RGB:1,1,1> <LINE>"
            .. " <LINE> <RGB:0.7,1,0.7> Walking Actions: <RGB:1,1,1> Read books, magazines, newspapers, comics, and maps while walking; also wear/unwear clothing, craft, and handcraft on the move."
            .. " <LINE>   Sprinting still cancels. Toggle per-player in the CSR Settings panel (S button on the HUD), or server-wide via Sandbox > EnableWalkingItemActions."
            .. " <LINE> <RGB:0.7,1,0.7> Quick Sit: <RGB:1,1,1> Toggle with <RGB:0.7,1,0.7> Numpad - <RGB:1,1,1>. Sit on the ground anywhere."
            .. " <LINE> <RGB:0.7,1,0.7> Ladder Climb: <RGB:1,1,1> Right-click compatible wall ladders to climb up or down with CSR's ladder animation layer."
            .. " <LINE> <RGB:0.7,1,0.7> Stair Vault Guard: <RGB:1,1,1> Suppresses accidental auto-vaulting only beside stairs and hoppable railings. Sandbox: EnableStairVaultGuard."
            .. " <LINE> <RGB:0.7,1,0.7> Warm Up: <RGB:1,1,1> Rub hands together when cold (right-click menu)."
            .. " <LINE>   Blocked by hand injuries. Unequips held items. You can walk while warming."
            .. " <LINE> <RGB:0.7,1,0.7> Sleep Anywhere: <RGB:1,1,1> Sleep on the ground without a bed."
            .. " <LINE> <RGB:0.7,1,0.7> Sleep Benefits: <RGB:1,1,1> Sleeping reduces boredom and unhappiness."
            .. " <LINE> <RGB:0.7,1,0.7> Massage: <RGB:1,1,1> Massage another player to reduce pain."
            .. " <LINE> <RGB:0.7,1,0.7> Towel Drying: <RGB:1,1,1> Use a towel to dry off faster."
            .. " <LINE> <RGB:0.7,1,0.7> Exercise With Gear: <RGB:1,1,1> Keep bags and clothing on during exercise.",
    },
    {
        title = "Multiplayer",
        text = "<SIZE:medium> <RGB:1,0.7,0.3> Multiplayer <SIZE:small> <RGB:1,1,1> <LINE>"
            .. " <LINE> <RGB:0.7,1,0.7> Rally Point Beacon: <RGB:1,1,1> Right-click the world map to set a personal pin or share a waypoint with your faction, safehouse, a specific player, or everyone online -- in a single click."
            .. " <LINE>   Shared waypoints draw an amber diamond and route line on the world map and minimap, and auto-clear when you arrive within 15 tiles."
            .. " <LINE> <RGB:0.7,1,0.7> Survivor Bond: <RGB:1,1,1> Stay near another player to accumulate a bond."
            .. " <LINE>   Once the threshold is met, Stress, Boredom, Fatigue, and Unhappiness gradually decrease."
            .. " <LINE>   Bond strength scales with continued closeness. All parameters configurable in sandbox.",
    },
    {
        title = "Faction Claims",
        text = "<SIZE:medium> <RGB:1,0.7,0.3> Faction Claims <SIZE:small> <RGB:1,1,1> <LINE>"
            .. " <LINE> Faction owners can claim safehouses on behalf of their faction, separate from each member's personal safehouse allowance."
            .. " <LINE> <RGB:0.7,1,0.7> Claim: <RGB:1,1,1> Right-click an unclaimed building and pick 'Claim Faction Safehouse' (faction owner only)."
            .. " <LINE> <RGB:0.7,1,0.7> Cap: <RGB:1,1,1> Up to 'Max Faction Safehouses' per faction (default 2, configurable 1-5 in sandbox)."
            .. " <LINE> <RGB:0.7,1,0.7> Validation: <RGB:1,1,1> Spawn-protection radius and inter-safehouse padding are checked before the cap; optional 'Faction claims residential only' mode requires at least one residential room in the building."
            .. " <LINE> <RGB:0.7,1,0.7> Manage: <RGB:1,1,1> Right-click the world for 'Manage Faction Claims' to release, transfer, or recenter a claim on the map."
            .. " <LINE> <RGB:0.7,1,0.7> Roles: <RGB:1,1,1> The faction owner or an admin can assign per-member role tags (stored on the safehouse modData)."
            .. " <LINE> <RGB:0.7,1,0.7> RV access: <RGB:1,1,1> Faction members are treated like an allowlist entry on a faction-owner's claimed vehicle, so teammates can enter and exit shared RVs."
            .. " <LINE> <RGB:0.7,1,0.7> Member limit: <RGB:1,1,1> Faction owners cannot invite past 'Max faction members' (default 8). The Add Player button shows the current count vs. cap.",
    },
    {
        title = "Skill Journal",
        text = "<SIZE:medium> <RGB:1,0.7,0.3> Skill Journal <SIZE:small> <RGB:1,1,1> <LINE>"
            .. " <LINE> Server-authoritative snapshot of your perks, learned recipes, and"
            .. " <LINE> read magazines, keyed to your Steam ID."
            .. " <LINE> <RGB:0.7,1,0.7> Open: <RGB:1,1,1> Click the 'Journal' button on the Utility HUD."
            .. " <LINE> <RGB:0.7,1,0.7> Save Snapshot: <RGB:1,1,1> Captures your current progress to the server."
            .. " <LINE> <RGB:0.7,1,0.7> Recover: <RGB:1,1,1> Restores everything from your latest snapshot,"
            .. " <LINE>   minus the configured death penalty per outstanding death."
            .. " <LINE> <RGB:0.7,1,0.7> Admins: <RGB:1,1,1> A 'Blacklist...' button is available to ban specific"
            .. " <LINE>   usernames or perks from being saved/recovered."
            .. " <LINE> Sandbox: EnableSkillJournal, SkillJournalDeathPenalty, and per-feature toggles.",
    },
    {
        title = "Admin Tools",
        text = "<SIZE:medium> <RGB:1,0.7,0.3> Admin Tools <SIZE:small> <RGB:1,1,1> <LINE>"
            .. " <LINE> Tools that only appear for Admin / Moderator / GM / Overseer accounts."
            .. " <LINE> <RGB:0.7,1,0.7> Sandbox Variable Reference: <RGB:1,1,1> Click the red 'Admin' button next"
            .. " <LINE>   to the Journal button on the Utility HUD."
            .. " <LINE>   Lists every CSR sandbox variable with its current value and tooltip, including new feature toggles such as EnableCorpseTrunk and EnableExtendedBatteryLife."
            .. " <LINE>   Read-only: changing values still requires the standard sandbox menu."
            .. " <LINE>   Filter by name, refresh to re-read live values, click any row to see its tooltip.",
    },
    {
        title = "Knowledge Sharing",
        text = "<SIZE:medium> <RGB:1,0.7,0.3> Knowledge Sharing <SIZE:small> <RGB:1,1,1> <LINE>"
            .. " <LINE> In multiplayer, teach recipes and give lectures to other players."
            .. " <LINE> <RGB:0.7,1,0.7> Recipe Teaching: <RGB:1,1,1> Teach a recipe you know to a nearby player."
            .. " <LINE>   The student must not already know it."
            .. " <LINE> <RGB:0.7,1,0.7> Lectures: <RGB:1,1,1> Give a lecture to nearby students for skill XP."
            .. " <LINE>   Students up to the configured max level receive XP pulses."
            .. " <LINE>   Higher teacher skill gives a small XP bonus.",
    },
    {
        title = "HUD & Overlays",
        text = "<SIZE:medium> <RGB:1,0.7,0.3> HUD & Overlays <SIZE:small> <RGB:1,1,1> <LINE>"
            .. " <LINE> <RGB:0.7,1,0.7> Utility HUD: <RGB:1,1,1> Toggle with <RGB:0.7,1,0.7> Numpad / <RGB:1,1,1>. Draggable status panel."
            .. " <LINE>   Shows food freshness, standpipe status, repair hints, zombie density."
            .. " <LINE>   Lock button prevents dragging. ? opens this guide. S opens per-player CSR settings."
            .. " <LINE> <RGB:0.7,1,0.7> Weapon HUD Overlay: <RGB:1,1,1> Weapon condition display near hotbar."
            .. " <LINE> <RGB:0.7,1,0.7> Visual Sound Cues: <RGB:1,1,1> On-screen indicators for sounds."
            .. " <LINE>   Filter with HUD buttons: P=players, Z=zombies, O=other."
            .. " <LINE> <RGB:0.7,1,0.7> Zombie Density: <RGB:1,1,1> Toggle with <RGB:0.7,1,0.7> Numpad * <RGB:1,1,1>. Heatmap overlay."
            .. " <LINE>   DH / Numpad 0 toggles the compact Nearby Density HUD."
            .. " <LINE> <RGB:0.7,1,0.7> Player Map Tracking: <RGB:1,1,1> See other players on the map (MP)."
            .. " <LINE> <RGB:0.7,1,0.7> Hotbar Flashlight: <RGB:1,1,1> Flashlight indicator on the hotbar."
            .. " <LINE> <RGB:0.7,1,0.7> ADS Ammo Counter: <RGB:1,1,1> Floating ammo pill near your cursor when aiming any firearm."
            .. " <LINE>   Independent from the hotbar pill strip and weapon HUD counter. Toggle in sandbox."
            .. " <LINE> <RGB:0.7,1,0.7> Survivor's Ledger: <RGB:1,1,1> Draggable HUD strip showing days survived, kills, distance, weight, session kills, and avg K/D."
            .. " <LINE>   Stats persist across saves. Drag to reposition. Default OFF; enable under Interface settings."
            .. " <LINE> <RGB:0.7,1,0.7> Safehouse Overlay: <RGB:1,1,1> Open the vanilla Safehouse menu and click the 'CSR Overlay: ON / OFF' button next to OK."
            .. " <LINE>   Tints owned safehouse floor tiles gold and faction-member safehouses purple, live on the ground (no UI needed)."
            .. " <LINE>   The right-click world entry 'Show / Hide CSR Safehouse Overlay' is kept as a secondary access path. Per-character preference persists."
            .. " <LINE> <RGB:0.7,1,0.7> Passive Generator Overlay: <RGB:1,1,1> Open any Generator Info window and click the 'Overlay: ON / OFF' button next to Range."
            .. " <LINE>   Draws a dim purple ring around every activated generator on your floor so you can see power coverage without opening each gen."
            .. " <LINE>   The single-gen Range button and carry preview continue to work independently. Per-character preference persists.",
    },
    {
        title = "Utility",
        text = "<SIZE:medium> <RGB:1,0.7,0.3> Utility <SIZE:small> <RGB:1,1,1> <LINE>"
            .. " <LINE> <RGB:0.7,1,0.7> City Standpipes: <RGB:1,1,1> Standpipes provide emergency water in cities."
            .. " <LINE> <RGB:0.7,1,0.7> Useful Barrels: <RGB:1,1,1> Uncap vanilla barrels with a pipe wrench."
            .. " <LINE>   Once uncapped, barrels store fluids and collect rain when outdoors."
            .. " <LINE>   Capacity configurable in sandbox. Uses vanilla fluid system."
            .. " <LINE> <RGB:0.7,1,0.7> Wash Menu Split: <RGB:1,1,1> Separate wash and drink options."
            .. " <LINE> <RGB:0.7,1,0.7> Sweep Trash: <RGB:1,1,1> Clean up floor debris."
            .. " <LINE> <RGB:0.7,1,0.7> Clipboard QoL: <RGB:1,1,1> Clipboard interaction improvements."
            .. " <LINE> <RGB:0.7,1,0.7> Room Scanner: <RGB:1,1,1> Scan Room button on clipboard. Detects enclosed room and lists all items."
            .. "   Requires paper + pen. Auto-names from room type. Rescan to update."
            .. " <LINE> <RGB:0.7,1,0.7> Notice Board: <RGB:1,1,1> Right-click paper notice tiles or whiteboards to read or write messages."
            .. "   Writing requires a pen, pencil, or marker. Whiteboards hold up to 6 lines."
            .. " <LINE> <RGB:0.7,1,0.7> Video Insert/Eject: <RGB:1,1,1> Right-click a TV or VCR to insert or eject a VHS tape or DVD."
            .. " <LINE> <RGB:0.7,1,0.7> TV Radial: <RGB:1,1,1> Press Numpad 9 near a TV, VCR, or radio for power, volume, insert, and eject controls."
            .. " <LINE> <RGB:0.7,1,0.7> Quick Device Toggle: <RGB:1,1,1> Quickly toggle flashlights and radios."
            .. " <LINE> <RGB:0.7,1,0.7> Saw All Drop: <RGB:1,1,1> Sawing logs drops planks to the ground."
            .. " <LINE> <RGB:0.7,1,0.7> Firework: <RGB:1,1,1> Light fireworks to distract zombies."
            .. " <LINE> <RGB:0.7,1,0.7> Signal Tools: <RGB:1,1,1> Glow sticks, hand flares, and signal rounds create temporary light."
            .. " <LINE> <RGB:0.7,1,0.7> Small Electronics: <RGB:1,1,1> Batch dismantle watches, clocks, and small electronics for scrap."
            .. " <LINE> <RGB:0.7,1,0.7> Repair Extensions: <RGB:1,1,1> Expanded repair options for more items."
            .. " <LINE> <RGB:0.7,1,0.7> Multiple Safehouse: <RGB:1,1,1> Claim more than one safehouse (MP)."
            .. " <LINE> <RGB:0.7,1,0.7> Advanced Sound Options: <RGB:1,1,1> Fine-tune sound settings."
            .. " <LINE> <RGB:0.7,1,0.7> Character Info: <RGB:1,1,1> Enhanced character info panel."
            .. " <LINE> <RGB:0.7,1,0.7> Hide Watermark: <RGB:1,1,1> Remove the version watermark from screen."
            .. " <LINE> <RGB:0.7,1,0.7> Climb With Bags: <RGB:1,1,1> Keep bags in your hands when climbing windows and fences."
            .. " <LINE>   Heavier bags slow you down. Works with all bag types."
            .. " <LINE> <RGB:0.7,1,0.7> Climb With Generator: <RGB:1,1,1> Carry generators through windows and over fences."
            .. "   Heavier time penalty than bags (0.25/kg). Visible generator model."
            .. " <LINE> <RGB:0.7,1,0.7> Wearable Slot Fix: <RGB:1,1,1> Ear muffs and protectors use Ears slot instead of Hat."
            .. "   Wear ear protection and a hat at the same time."
            .. " <LINE> <RGB:0.7,1,0.7> Tow Assist: <RGB:1,1,1> Vehicles get a forward boost while towing."
            .. " <LINE>   Force scales with both vehicle masses. Per-type factors in sandbox.",
    },
    {
        title = "Outfit Sets",
        text = "<SIZE:medium> <RGB:1,0.7,0.3> Outfit Sets <SIZE:small> <RGB:1,1,1> <LINE>"
            .. " <LINE> Save and recall complete outfits from any wardrobe-class furniture (Wardrobe, Dresser, Locker, Shelves, Clothes Stand, Crate, Chest, Rack)."
            .. " <LINE> <RGB:0.7,1,0.7> Open: <RGB:1,1,1> Right-click the wardrobe -> 'Outfit Sets', or click the small 'Outfit' button in that container's loot-window header."
            .. " <LINE> <RGB:0.7,1,0.7> Save: <RGB:1,1,1> 'Save current outfit' takes a snapshot of every item you're wearing and asks for a name + optional category (Casual / Combat / Work / Sleep / Other)."
            .. " <LINE> <RGB:0.7,1,0.7> Wear: <RGB:1,1,1> Pick a saved outfit; CSR matches each slot by item type + best non-Ruined condition, unequips conflicts, transfers excess to the wardrobe, and dresses you. Laundering or replacing one shirt does NOT break the slot."
            .. " <LINE> <RGB:0.7,1,0.7> Multi-container scan: <RGB:1,1,1> When access mode is 'Safehouse Only', Wear searches every container in the same room (or 4-tile radius if the room can't be detected). Treats your bedroom as the wardrobe."
            .. " <LINE> <RGB:0.7,1,0.7> Wardrobe capacity bonus: <RGB:1,1,1> First time you use a wardrobe-class container, it gets a one-time +30% capacity bonus (sandbox 0-200%)."
            .. " <LINE> <RGB:0.7,1,0.7> Sandbox: <RGB:1,1,1> EnableOutfitSets, OutfitSetsAccess (Anywhere / Safehouse Only), OutfitSetsMultiContainerScan, OutfitSetsMaxSlots (default 8), OutfitSetsWardrobeBonusPct."
            .. " <LINE> <RGB:0.7,1,0.7> Concept credit: <RGB:1,1,1> Inspired by Yuki's Outfit Control. CSR's implementation is original code with type-based matching, multi-container scan, categories, and capacity bonus folded in. Reimplemented with permission.",
    },
    {
        title = "Power Line & Battery Top-Up",
        text = "<SIZE:medium> <RGB:1,0.7,0.3> Power Line <SIZE:small> <RGB:1,1,1> <LINE>"
            .. " <LINE> Run a temporary 'cord' from a powered tile (generator, vanilla power coverage, or another Power Line tile) to anywhere you want power -- up to 24 tiles by default."
            .. " <LINE> <RGB:0.7,1,0.7> Start: <RGB:1,1,1> Stand on a powered tile, right-click the world -> 'Start Power Line'. A purple trail paints under you as you walk."
            .. " <LINE> <RGB:0.7,1,0.7> End: <RGB:1,1,1> Right-click -> 'End Power Line Here'. Consumes one Power Bar; the trail turns gold/energized and supplies CSR Power Bar chargers along its length."
            .. " <LINE> <RGB:0.7,1,0.7> Cancel: <RGB:1,1,1> Right-click -> 'Cancel Power Line' at any time before ending. Trails clean up automatically near the end point."
            .. " <LINE> <RGB:0.7,1,0.7> Battery top-up: <RGB:1,1,1> While standing on an energized Power Line tile, drainable battery items in your inventory (flashlights, lighters, lanterns) tick toward full. Flavor only; no XP, no stats."
            .. " <LINE> <RGB:0.7,1,0.7> Extended Battery Life: <RGB:1,1,1> Separate from Power Line top-up; it changes normal drain rates through EnableExtendedBatteryLife and BatteryLifeMultiplier."
            .. " <LINE> <RGB:0.7,1,0.7> Sandbox: <RGB:1,1,1> EnablePowerLine, PowerLineMaxLength (4-64, default 24), EnablePowerLineBatteryPlacebo.",
    },
    {
        title = "Bathing",
        text = "<SIZE:medium> <RGB:1,0.7,0.3> Bathing <SIZE:small> <RGB:1,1,1> <LINE>"
            .. " <LINE> Right-click a supported bathtub with water -> 'Take A Bath' to wash yourself and your worn clothing in one action."
            .. " <LINE> Optional toggles for stripping headwear / clothes / underwear / backpack before bathing, and for clearing muscle strain.",
    },
    {
        title = "Equipment Panel",
        text = "<SIZE:medium> <RGB:1,0.7,0.3> Equipment Panel <SIZE:small> <RGB:1,1,1> <LINE>"
            .. " <LINE> Side panel that shows every worn item over a live 3D model of your character."
            .. " <LINE> <RGB:0.7,1,0.7> Open: <RGB:1,1,1> Opens automatically with the inventory window. You can also press Numpad 1, or click the small purple 'E' button next to the inventory title bar."
            .. " <LINE> <RGB:0.7,1,0.7> Docked vs Floating: <RGB:1,1,1> Click the < / > button on the panel's title bar to detach it (Floating) or re-attach (Docked). Docked panel sticks to the inventory window. Sandbox EquipmentPanelDockMode controls the default."
            .. " <LINE> <RGB:0.7,1,0.7> Slot interactions: <RGB:1,1,1> Click an empty slot to pick a wearable from carried or nested containers. Click an occupied slot to unequip. Right-click for full vanilla item context menu."
            .. " <LINE> <RGB:0.7,1,0.7> Drag and drop: <RGB:1,1,1> Drag wearable gear onto body slots, or drag inventory items onto hotbar slots shown inside the panel."
            .. " <LINE> <RGB:0.7,1,0.7> Hotbar strip: <RGB:1,1,1> Live hotbar slots can equip, activate, or attach compatible items directly from the Equipment Panel."
            .. " <LINE> <RGB:0.7,1,0.7> Visual refresh: <RGB:1,1,1> The paper-doll slots and 3D model refresh when worn gear changes, including Gear Sling and CSR fanny-pack locations."
            .. " <LINE> <RGB:0.7,1,0.7> Persistence: <RGB:1,1,1> Open/closed and docked/floating preferences are saved per character.",
    },
}

local function buildFullText()
    local parts = {}
    for i, section in ipairs(GUIDE_SECTIONS) do
        if i > 1 then
            table.insert(parts, " <LINE> <LINE> ")
        end
        table.insert(parts, section.text)
    end
    return table.concat(parts)
end

function CSR_Guide.toggle()
    if guideWindow and guideWindow:isVisible() then
        guideWindow:setVisible(false)
        guideWindow:removeFromUIManager()
        guideWindow = nil
        return
    end

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local w = math.min(520, screenW - 40)
    local h = math.min(560, screenH - 40)
    local x = math.floor((screenW - w) / 2)
    local y = math.floor((screenH - h) / 2)

    guideWindow = ISCollapsableWindow:new(x, y, w, h)
    guideWindow:initialise()
    guideWindow:setTitle(getText("IGUI_CSR_Guide_Title"))
    guideWindow.resizable = true
    guideWindow.drawFrame = true

    local titleBarHeight = guideWindow:titleBarHeight()

    local richText = ISRichTextPanel:new(0, titleBarHeight, w, h - titleBarHeight)
    richText:initialise()
    richText.autosetheight = false
    richText.background = true
    richText.backgroundColor = { r = 0, g = 0, b = 0, a = 0.85 }
    richText.borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 0.6 }
    richText.marginLeft = 12
    richText.marginTop = 8
    richText.marginRight = 12
    richText.marginBottom = 8
    richText.anchorLeft = true
    richText.anchorRight = true
    richText.anchorTop = true
    richText.anchorBottom = true
    richText:setText(buildFullText())
    richText:paginate()

    guideWindow:addChild(richText)
    guideWindow:addToUIManager()
    guideWindow:setVisible(true)
    guideWindow:bringToTop()
end
