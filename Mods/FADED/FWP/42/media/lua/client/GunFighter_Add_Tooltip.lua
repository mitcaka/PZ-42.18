require "ISUI/ISToolTipInv"
require "FWP_UIScale"

local default = ISToolTipInv.render
local item = nil
local numRows = 0
local chargeText = nil
local charge = nil
local charge2 = nil
local triggerType = nil
-- FWP compact weapon part inventory tooltip: B42 prints the entire MountOn list for every part.
local function FWPCompactTooltipCall(obj, method)
	if obj == nil or obj[method] == nil then
		return nil
	end
	local ok, value = pcall(function()
		return obj[method](obj)
	end)
	if ok then
		return value
	end
	return nil
end

local function FWPCompactTooltipRound(value, digits)
	local n = tonumber(value)
	if n == nil then
		return nil
	end
	if round then
		return round(n, digits or 2)
	end
	local scale = math.pow(10, digits or 2)
	if n >= 0 then
		return math.floor(n * scale + 0.5) / scale
	end
	return math.ceil(n * scale - 0.5) / scale
end

local function FWPCompactTooltipAdd(rows, label, value)
	if value == nil then
		return
	end
	value = tostring(value)
	if value == "" or value == "nil" then
		return
	end
	table.insert(rows, {label, value})
end

local function FWPCompactTooltipAddNumber(rows, label, item, method, digits)
	local value = FWPCompactTooltipCall(item, method)
	local n = tonumber(value)
	if n == nil or math.abs(n) < 0.0001 then
		return
	end
	n = FWPCompactTooltipRound(n, digits or 2)
	local text = tostring(n)
	if n > 0 then
		text = "+" .. text
	end
	FWPCompactTooltipAdd(rows, label, text)
end

local function FWPCompactTooltipTrim(text, font, maxWidth)
	if text == nil then
		return ""
	end
	text = tostring(text)
	if getTextManager():MeasureStringX(font, text) <= maxWidth then
		return text
	end
	local suffix = "..."
	local suffixWidth = getTextManager():MeasureStringX(font, suffix)
	while string.len(text) > 0 and getTextManager():MeasureStringX(font, text) + suffixWidth > maxWidth do
		text = string.sub(text, 1, -2)
	end
	return text .. suffix
end

function FWPRenderCompactWeaponPartTooltip(panel, part)
	if panel == nil or part == nil then
		return false
	end
	if ISContextMenu.instance and ISContextMenu.instance.visibleCheck then
		return true
	end

	local rows = {}
	FWPCompactTooltipAdd(rows, "Type", FWPCompactTooltipCall(part, "getPartType"))
	FWPCompactTooltipAddNumber(rows, "Encumbrance", part, "getWeight", 2)
	FWPCompactTooltipAddNumber(rows, "Weight", part, "getWeightModifier", 2)
	FWPCompactTooltipAddNumber(rows, "Hit chance", part, "getHitChance", 0)
	FWPCompactTooltipAddNumber(rows, "Recoil", part, "getRecoilDelay", 2)
	FWPCompactTooltipAddNumber(rows, "Aim time", part, "getAimingTime", 0)
	FWPCompactTooltipAddNumber(rows, "Reload time", part, "getReloadTime", 0)
	FWPCompactTooltipAddNumber(rows, "Min range", part, "getMinRangeRanged", 1)
	FWPCompactTooltipAddNumber(rows, "Max range", part, "getMaxRange", 1)
	FWPCompactTooltipAddNumber(rows, "FOV", part, "getAngle", 3)
	FWPCompactTooltipAddNumber(rows, "Damage", part, "getDamage", 2)

	if part.getModData then
		local md = part:getModData()
		if md then
			if md.Charge ~= nil then
				FWPCompactTooltipAdd(rows, getText("ContextMenu_AttachmentCharge"), tostring(FWPCompactTooltipRound(md.Charge, 1)))
			end
			if md.TriggerType ~= nil then
				local triggerText = {
					[0] = getText("ContextMenu_FireMode_N/A"),
					[1] = getText("ContextMenu_FireMode_Single"),
					[2] = getText("ContextMenu_FireMode_Auto"),
					[3] = getText("ContextMenu_FireMode_Single") .. " / " .. getText("ContextMenu_FireMode_[2]Burst"),
					[4] = getText("ContextMenu_FireMode_Single") .. " / " .. getText("ContextMenu_FireMode_[3]Burst"),
					[5] = getText("ContextMenu_FireMode_Single") .. " / " .. getText("ContextMenu_FireMode_Auto"),
					[6] = getText("ContextMenu_FireMode_Single") .. " / " .. getText("ContextMenu_FireMode_[2]Burst") .. " / " .. getText("ContextMenu_FireMode_Auto"),
					[7] = getText("ContextMenu_FireMode_Single") .. " / " .. getText("ContextMenu_FireMode_[3]Burst") .. " / " .. getText("ContextMenu_FireMode_Auto"),
				}
				FWPCompactTooltipAdd(rows, getText("ContextMenu_FireModes"), triggerText[tonumber(md.TriggerType)] or tostring(md.TriggerType))
			end
		end
	end

	local font = UIFont[getCore():getOptionTooltipFont()] or UIFont.Small
	local u = FWPUIScale and FWPUIScale.value or function(value) return math.floor((tonumber(value) or 0) + 0.5) end
    local lineHeight = FWPUIScale and FWPUIScale.line(font, 14, 3) or (getTextManager():getFontHeight(font) + 3)
	local title = FWPCompactTooltipCall(part, "getDisplayName") or FWPCompactTooltipCall(part, "getName") or ""
	local width = u(292)
	local texture = nil
	if part.getTexture then
		texture = part:getTexture()
	end
	local textX = texture and u(48) or u(8)
	width = math.max(width, textX + getTextManager():MeasureStringX(font, title) + u(10))
	for i = 1, #rows do
		local rowText = tostring(rows[i][1]) .. ": " .. tostring(rows[i][2])
		width = math.max(width, u(16) + getTextManager():MeasureStringX(font, rowText))
	end
	width = math.min(width, u(420))
	local height = u(16) + math.max(u(34), lineHeight + (#rows * lineHeight))

	local mx = getMouseX() + u(24)
	local my = getMouseY() + u(24)
	if not panel.followMouse then
		mx = panel:getX()
		my = panel:getY()
		if panel.anchorBottomLeft then
			mx = panel.anchorBottomLeft.x
			my = panel.anchorBottomLeft.y
		end
	end
	local maxX = getCore():getScreenWidth()
	local maxY = getCore():getScreenHeight()
	panel:setX(math.max(0, math.min(mx, maxX - width - u(1))))
	panel:setY(math.max(0, math.min(my, maxY - height - u(1))))
	panel:setWidth(width)
	panel:setHeight(height)
	if panel.tooltip then
		panel.tooltip:setX(panel:getX())
		panel.tooltip:setY(panel:getY())
		panel.tooltip:setWidth(width)
	end
	if panel.followMouse and panel.contextMenu == nil then
		panel:adjustPositionToAvoidOverlap({ x = mx - u(48), y = my - u(48), width = u(48), height = u(48) })
	end

	panel:drawRect(0, 0, panel.width, panel.height, panel.backgroundColor.a, panel.backgroundColor.r, panel.backgroundColor.g, panel.backgroundColor.b)
	panel:drawRectBorder(0, 0, panel.width, panel.height, panel.borderColor.a, panel.borderColor.r, panel.borderColor.g, panel.borderColor.b)
	if texture then
		panel:drawTextureScaled(texture, u(8), u(8), u(32), u(32), 1.0, 1.0, 1.0, 1.0)
	end
	panel:drawText(FWPCompactTooltipTrim(title, font, width - textX - u(8)), textX, u(8), 1.0, 0.93, 0.58, 1.0, font)
	local y = u(8) + lineHeight
	for i = 1, #rows do
		local label = tostring(rows[i][1]) .. ": "
		local value = tostring(rows[i][2])
		local labelWidth = getTextManager():MeasureStringX(font, label)
		panel:drawText(label, u(8), y, 0.78, 0.78, 0.78, 1.0, font)
		panel:drawText(FWPCompactTooltipTrim(value, font, width - labelWidth - u(18)), u(8) + labelWidth, y, 0.92, 0.92, 0.92, 1.0, font)
		y = y + lineHeight
	end
	return true
end

function ISToolTipInv:render()
	numRows = 0
	if self.item ~= nil then
		item = self.item

		if FWPRenderCompactWeaponPartTooltip and instanceof(item, "WeaponPart") then

			if FWPRenderCompactWeaponPartTooltip(self, item) then

				return

			end

		end


		if (instanceof(item,"HandWeapon")) and (item:isAimedFirearm()) and (not isLauncher(item)) then
			------------------------------------------------------------------
			--	IF GAME DOES NOT GIVE MAG, BUT PRE-ATTACH UPGRADED MAG		--
			------------------------------------------------------------------
			if	item:isContainsClip() == false and FWPGetWeaponPart(item, "Clip") ~= nil then
			--	DebugSay(2,"[ITEM] Insert Generated Mag...")
				item:setContainsClip(true)				-- INSERT ONE
			end
			------------------------------------------------------------------
			--	IF MAG IS INSERTED BUT CURRENT MAGTYPE SET DOES NOT MATCH	--
			------------------------------------------------------------------
			if	item:isContainsClip() and FWPGetWeaponPart(item, "Clip") ~= nil then
				local	resetMag = nil
			--	if		(string.find(FWPGetWeaponPart(item, "Clip"):getType(), "Standard_Mag"))	and (item:getMagazineType() ~= nil) then
			--			resetMag = item:getMagazineType()
				if		(string.find(FWPGetWeaponPart(item, "Clip"):getType(), "Extended_Mag"))	and (item:getModData().ExtMagType ~= item:getMagazineType()) then
				--		DebugSay(2,"[ITEM] Extended Mag Detected...")
						resetMag = item:getModData().ExtMagType
				elseif	(string.find(FWPGetWeaponPart(item, "Clip"):getType(), "Drum_Mag"))		and (item:getModData().DrumMagType ~= item:getMagazineType()) then
				--		DebugSay(2,"[ITEM] Drum Mag Detected...")
						resetMag = item:getModData().DrumMagType
				end
				----------------------------------
				--	RESET IF NON-MATCH FOUND	--
				----------------------------------
				if resetMag ~= nil then
				--	DebugSay(2,"[ITEM] Update Mag Type...")
					item:setMagazineType(resetMag)	-- SET TO UPGRADED TYPE
					if		item:getMagazineType() ~= nil then
							item:setMaxAmmo(FWPCreateItem(item:getMagazineType()):getMaxAmmo())
					else	item:setMaxAmmo(item:getMaxAmmo())
					end						
				end
			end
		end
		
		------------------------------------------
		--	WORKS BUT GOTTA BE A BETTER WAY		--
		------------------------------------------
		if	(instanceof(item,"HandWeapon")) and item:isAimedFirearm() and item:getModData().TriggerType ~= nil then
		--	if	not item:getFireModePossibilities():contains(item:getFireMode()) then
				Update_TriggerGroup(item)
		--		DebugSay(2,"Updating Trigger Group from ToolTip")
		--	end
		end
		
		getPlayer()
		if item and instanceof(item, "WeaponPart") and ( item:hasTag(FWPGetItemTag("Light")) or item:hasTag(FWPGetItemTag("Laser")) or item:hasTag(FWPGetItemTag("Multi_Laser")) ) then		-- UNATTACHED PART
			charge2 = nil
			triggerType = nil
			if	item:getModData().Charge == nil then
				item:getModData().Charge = 0
			end
			charge = round(item:getModData().Charge,1)
		elseif item and instanceof(item, "HandWeapon") and item:isAimedFirearm() then 									-- ATTACHED PART
			triggerType = nil
			local stock = FWPGetWeaponPart(item, "Stock")
			local sling = FWPGetWeaponPart(item, "Sling")
			if stock and ( stock:hasTag(FWPGetItemTag("Light")) or stock:hasTag(FWPGetItemTag("Laser")) or stock:hasTag(FWPGetItemTag("Multi_Laser")) ) then	-- NEEDS POWER
				if	stock:getModData().Charge == nil then														-- CAN SHOW EMPTY
					stock:getModData().Charge = 0
				end
				charge = round(stock:getModData().Charge,1)
				----------------------------------------------------------
				--	NEEDED FOR NON-EQUIPPED INVENTORY OR GUNS PLACED	--
				--	ATTACHMENT MODDATA NOT SAVED, ONLY GUN MODDATA		--
				----------------------------------------------------------
				if charge == 0 and item:getModData().Charge ~= nil then			-- FOR ITEMS NOT IN HAND
					charge = round(item:getModData().Charge,1)
					stock:getModData().Charge = charge
				end
				----------------------------------------------------------
			else charge = nil
			end
			
			if sling and ( sling:hasTag(FWPGetItemTag("Light")) or sling:hasTag(FWPGetItemTag("Laser")) or sling:hasTag(FWPGetItemTag("Multi_Laser")) ) then	-- NEEDS POWER
				if	sling:getModData().Charge == nil then														-- CAN SHOW EMPTY
					sling:getModData().Charge = 0
				end
				charge2 = round(sling:getModData().Charge,1)
				----------------------------------------------------------
				--	NEEDED FOR NON-EQUIPPED INVENTORY OR GUNS PLACED	--
				--	ATTACHMENT MODDATA NOT SAVED, ONLY GUN MODDATA		--
				----------------------------------------------------------
				if charge2 == 0 and item:getModData().Charge2 ~= nil then		-- FOR ITEMS NOT IN HAND
					charge2 = round(item:getModData().Charge2,1)
					sling:getModData().Charge = charge2
				end
				----------------------------------------------------------
			else charge2 = nil
			end
		elseif item:hasTag(FWPGetItemTag("TriggerGroup")) then		-- TRIGGER GROUP TYPE
			charge = nil
			if item:getModData().TriggerType ~= nil then
				triggerType = item:getModData().TriggerType
			end			
		else
			return default(self)
		end
		
		if		charge ~= nil and charge2 ~= nil then
				numRows = 1
				chargeText = getText("ContextMenu_AttachmentCharge").." : " .. charge .. " / " .. charge2
		elseif	charge ~= nil then
				numRows = 1
				chargeText = getText("ContextMenu_AttachmentCharge").." : " .. charge
		elseif	charge2 ~= nil then
				numRows = 1
				chargeText = getText("ContextMenu_AttachmentCharge").." : " .. charge2
		elseif	triggerType ~= nil then
				numRows = 1
				if		triggerType == 0 then
						chargeText = getText("ContextMenu_FireModes") .. " : " .. getText("ContextMenu_FireMode_N/A")
				elseif	triggerType == 1 then
						chargeText = getText("ContextMenu_FireModes") .. " : " .. getText("ContextMenu_FireMode_Single")
				elseif	triggerType == 2 then
						chargeText = getText("ContextMenu_FireModes") .. " : " .. getText("ContextMenu_FireMode_Auto")
				elseif	triggerType == 3 then
						chargeText = getText("ContextMenu_FireModes") .. " : " .. getText("ContextMenu_FireMode_Single") .. " / " .. getText("ContextMenu_FireMode_[2]Burst")
				elseif	triggerType == 4 then
						chargeText = getText("ContextMenu_FireModes") .. " : " .. getText("ContextMenu_FireMode_Single") .. " / " .. getText("ContextMenu_FireMode_[3]Burst")
				elseif	triggerType == 5 then
						chargeText = getText("ContextMenu_FireModes") .. " : " .. getText("ContextMenu_FireMode_Single") .. " / " .. getText("ContextMenu_FireMode_Auto")
				elseif	triggerType == 6 then
						chargeText = getText("ContextMenu_FireModes") .. " : " .. getText("ContextMenu_FireMode_Single") .. " / " .. getText("ContextMenu_FireMode_[2]Burst") .. " / " .. getText("ContextMenu_FireMode_Auto")
				elseif	triggerType == 7 then
						chargeText = getText("ContextMenu_FireModes") .. " : " .. getText("ContextMenu_FireMode_Single") .. " / " .. getText("ContextMenu_FireMode_[3]Burst") .. " / " .. getText("ContextMenu_FireMode_Auto")
				end				
		end		
	end
	local default_y = 0
	local fontSize = 0
	local tooltipFontSize = 0
	local lineSpacing = self.tooltip:getLineSpacing()
	local default_setHeight = self.setHeight
	self.setHeight = function(self, num, ...)
		default_y = num
		num = num + numRows * lineSpacing
		return default_setHeight(self, num, ...)
	end
	local default_drawRectBorder = self.drawRectBorder
	self.drawRectBorder = function(self, ...)
		if numRows > 0 then
			local color = {0.0, 1.0, 0.0}
			local font = UIFont[getCore():getOptionTooltipFont()];
			self.tooltip:DrawText(font, chargeText, 5, default_y, color[1], color[2], color[3], 1);
		end
		return default_drawRectBorder(self, ...)
	end
	default(self)
	self.setHeight = default_setHeight
	self.drawRectBorder = default_drawRectBorder
end
