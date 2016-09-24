--[[
	© Justin Snelgrove

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local FOLDER, _xrp = ...

local isWorgen = select(2, UnitRace("player")) == "Worgen"
local playerClass = select(2, UnitClassBase("player"))
if not (playerClass == "DRUID" or playerClass == "PRIEST" or playerClass == "SHAMAN") then
	playerClass = nil
end
local FORM_ID = {
	[1] = "CAT",
	[3] = "TRAVEL",
	[4] = "AQUATIC",
	[5] = "BEAR",
	[16] = "GHOSTWOLF",
	[27] = "FLIGHT",
	[29] = "FLIGHT",
	[31] = "MOONKIN",
	[35] = "MOONKIN",
}
local FORM_NO_RACE = {
	["CAT"] = true,
	["TREANT"] = true,
	["TRAVEL"] = true,
	["AQUATIC"] = true,
	["BEAR"] = true,
	["GHOSTWOLF"] = true,
	["FLIGHT"] = true,
	["MOONKIN"] = true,
	["ASTRAL"] = true, -- Shows worgen model, but cannot be human and astral.
}
local FORM_NO_EQUIPMENT = {
	["CAT"] = true,
	["TREANT"] = true,
	["TRAVEL"] = true,
	["AQUATIC"] = true,
	["BEAR"] = true,
	["GHOSTWOLF"] = true,
	["FLIGHT"] = true,
	["MOONKIN"] = true,
}
local lastEquipSet
local function GetCurrentForm()
	local mercenaryForm = UnitIsMercenary("player")

	local classForm
	if playerClass then
		if playerClass == "DRUID" or playerClass == "SHAMAN" then
			local formID = GetShapeshiftFormID()
			classForm = FORM_ID[formID]
			if classForm == "MOONKIN" and (formID == 31 and HasAttachedGlyph(24858) or formID == 35 and HasAttachedGlyph(197625)) then
				classForm = "ASTRAL"
			elseif not classForm and playerClass == "DRUID" and UnitBuff("player", _xrp.L.TREANT_BUFF) then
				classForm = "TREANT"
			end
		elseif playerClass == "PRIEST" and GetSpecialization() == 3 then
			classForm = "SHADOWFORM"
		end
	end

	local raceForm
	if isWorgen and not FORM_NO_RACE[classForm] then
		raceForm = select(2, HasAlternateForm()) and "HUMAN" or "DEFAULT"
	end

	local equipSet
	if not FORM_NO_EQUIPMENT[classForm] then
		local bestMatch, bestScore = nil, 0
		for i = 1, GetNumEquipmentSets() do
			local name, icon, setID, equipped, numItems, numEquip, numInv, numMissing = GetEquipmentSetInfo(i)
			if equipped then
				lastEquipSet = name
				break
			elseif not lastEquipSet and numItems > 0 then
				if numEquip == numItems then
					-- Sets with all items equipped (but slots that should
					-- be empty aren't) are penalized slightly. No way to find
					-- out how many slots should be empty.
					numEquip = numEquip - 1
				end
				-- Sets with items not in inventory are penalized.
				local score = numEquip / (numItems + numMissing)
				if score > bestScore then
					bestScore = score
					bestMatch = name
				end
			end
		end
		equipSet = lastEquipSet or bestMatch
	end

	return mercenaryForm, raceForm, classForm, equipSet
end

local timer
local function CancelTimer()
	if timer and not timer._cancelled then
		timer:Cancel()
	end
end

local mercenary, race, class, equip

local function DoSwap()
	timer = nil

	local form
	if mercenary then
		form = "MERCENARY"
	end
	if not _xrp.auto[form] and race then
		-- RACE-CLASS-Equipment (Worgen only)
		if class and equip then
			form = ("%s\30%s\29%s"):format(race, class, equip)
		end
		-- RACE-CLASS (Worgen only)
		if not _xrp.auto[form] and class then
			form = ("%s\30%s"):format(race, class)
		end
	end
	-- RACE-Equipment (Worgen only)/CLASS-Equipment
	if not _xrp.auto[form] and (race or class) and equip then
		form = ("%s\29%s"):format(race or class, equip)
	end
	-- RACE (Worgen only)/CLASS
	if not _xrp.auto[form] and (race or class) then
		form = race or class
	end
	-- DEFAULT-CLASS-Equipment (Worgen only)
	if not _xrp.auto[form] and race and race ~= "DEFAULT" and class and equip then
		form = ("DEFAULT\30%s\29%s"):format(class, equip)
	end
	-- DEFAULT-Equipment
	if not _xrp.auto[form] and equip then
		form = ("DEFAULT\29%s"):format(equip)
	end
	-- DEFAULT
	if not _xrp.auto[form] then
		form = "DEFAULT"
	end

	--print(form and (form:gsub("\30", "-"):gsub("\29", "-")) or "NONE")
	if not _xrp.auto[form] then
		return
	end
	xrp.profiles[_xrp.auto[form]]:Activate(true)
end

local function TestForm(event, unit)
	if InCombatLockdown() or event == "UNIT_PORTRAIT_UPDATE" and unit ~= "player" then return end
	local newMercenary, newRace, newClass, newEquip = GetCurrentForm()
	local newForm = mercenary ~= newMercenary or class ~= newClass or race ~= newRace or equip ~= newEquip
	if event == "PLAYER_REGEN_ENABLED" and (newForm or timer and timer._cancelled) then
		mercenary = newMercenary
		race = newRace
		class = newClass
		equip = newEquip
		CancelTimer()
		timer = C_Timer.NewTimer(6, DoSwap)
	elseif newForm then
		mercenary = newMercenary
		race = newRace
		class = newClass
		equip = newEquip
		CancelTimer()
		timer = C_Timer.NewTimer(3, DoSwap)
	end
end

local function RecheckForm()
	mercenary, race, class, equip = GetCurrentForm()
	CancelTimer()
	DoSwap()
end

-- Portrait update catches worgen form, equipment sets. Talent group catches
-- Shadowform. Shapeshift form catches others.
_xrp.HookGameEvent("UNIT_PORTRAIT_UPDATE", TestForm, "player")
_xrp.HookGameEvent("ACTIVE_TALENT_GROUP_CHANGED", TestForm)
_xrp.HookGameEvent("UPDATE_SHAPESHIFT_FORM", TestForm)
_xrp.HookGameEvent("PLAYER_REGEN_ENABLED", TestForm)
_xrp.HookGameEvent("PLAYER_REGEN_DISABLED", CancelTimer)

_xrp.HookGameEvent("ADDON_LOADED", function(event, addon)
	if addon ~= FOLDER then return end
	local now = time()
	if xrpSaved.lastCleanUp and xrpSaved.lastCleanUp > time() - 72000 then return end

	validForms = {
		["DEFAULT"] = true,
		["MERCENARY"] = true,
	}
	if isWorgen then
		validForms["HUMAN"] = true
	end
	if playerClass == "DRUID" then
		validForms["CAT"] = true
		validForms["TRAVEL"] = true
		validForms["AQUATIC"] = true
		validForms["BEAR"] = true
		validForms["FLIGHT"] = true
		validForms["MOONKIN"] = true
		validForms["ASTRAL"] = true
		validForms["TREANT"] = true
	elseif playerClass == "PRIEST" then
		validForms["SHADOWFORM"] = true
	elseif playerClass == "SHAMAN" then
		validForms["GHOSTWOLF"] = true
	end
	local validEquipSets = {}
	for i = 1, GetNumEquipmentSets() do
		validEquipSets[(GetEquipmentSetInfo(i))] = true
	end

	local toRemove = {}
	local importantRemove
	for form, profile in pairs(xrpSaved.auto) do
		if not xrpSaved.profiles[profile] then
			xrpSaved.auto[form] = nil
		else
			local form1, form2, equipSet = form:match("^([^\30\29]+)\30?([^\30\29]*)\29?(.*)$")
			if form1 ~= "" and not validForms[form1] or form2 ~= "" and not validForms[form2] then
				xrpSaved.auto[form] = nil
				importantRemove = true
			elseif equipSet ~= "" and not validEquipSets[equipSet] then
				toRemove[form] = 1
			end
		end
	end
	xrpSaved.lastCleanUp = now

	if importantRemove then
		StaticPopup_Show("XRP_ERROR", _xrp.L.REMOVED_AUTO_FORMS)
	end

	if not next(toRemove) then
		xrpSaved.autoCleanUp = nil
		return
	elseif not xrpSaved.autoCleanUp then
		xrpSaved.autoCleanUp = {}
	end

	for form, removeCount in pairs(xrpSaved.autoCleanUp) do
		if not toRemove[form] then
			xrpSaved.autoCleanUp[form] = nil
		end
	end
	for form, removeCount in pairs(toRemove) do
		xrpSaved.autoCleanUp[form] = (xrpSaved.autoCleanUp[form] or 0) + removeCount
	end
	for form, removeCount in pairs(xrpSaved.autoCleanUp) do
		if removeCount >= 3 then
			xrpSaved.auto[form] = nil
			xrpSaved.autoCleanUp[form] = nil
		end
	end
	if not next(xrpSaved.autoCleanUp) then
		xrpSaved.autoCleanUp = nil
	end
end)

_xrp.auto = setmetatable({}, {
	__index = function(self, form)
		local profile = xrpSaved.auto[form]
		if not xrpSaved.profiles[profile] then
			return nil
		end
		return profile
	end,
	__newindex = function(self, form, profile)
		if profile == xrpSaved.auto[form] or profile and not xrpSaved.profiles[profile] then return end
		xrpSaved.auto[form] = profile
		RecheckForm()
	end,
})
