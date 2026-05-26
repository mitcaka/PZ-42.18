SpecialLootSpawns = SpecialLootSpawns or {}

-- 驻美应急兵团新闻月刊
SpecialLootSpawns.OnCreateKYEmergency = function(item)
    if not item then return; end;
	local text
	local bookList = SpecialLootSpawns.KYEmergency
	local comic = bookList[ZombRand(#bookList)+1]
	local details = SpecialLootSpawns.KYEmergencyDetails[comic]
	local issue = 0
	if details.issues == 0 then issue = 0
	else
	    local maxIssue = details.issues
	    local roll = ZombRand(details.issues) +1
	    local roll2 = ZombRand(details.issues) +1
	    local roll3 = ZombRand(details.issues) +1
	    if roll2 > roll then roll = roll2 end
	    if roll3 > roll then roll = roll3 end
	    issue = roll +1
	end

	local comic2 = "IGUI_KYEmergency_" .. comic

	if issue == 0 then
		text = getText(item:getDisplayName()) .. ": " .. getText(comic2)
	elseif issue <= 9 and details.issues >= 100 then
		text = getText(item:getDisplayName()) .. ": " .. getText(comic2)
	elseif issue <= 9 and details.issues >= 10 then
		text = getText(item:getDisplayName()) .. ": " .. getText(comic2)
	elseif issue <= 99 and details.issues >= 100 then
		text = getText(item:getDisplayName()) .. ": " .. getText(comic2)
	else
		text = getText(item:getDisplayName()) .. ": " .. getText(comic2)
	end
	item:setName(text)
    item:getModData().literatureTitle = comic
end