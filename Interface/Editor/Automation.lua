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

XRP_AUTOMATION = _xrp.L.AUTOMATION

local isWorgen, playerClass = select(2, UnitRace("player")) == "Worgen", select(2, UnitClassBase("player"))
if not (playerClass == "DRUID" or playerClass == "PRIEST" or playerClass == "SHAMAN") then
	playerClass = nil
end

local FORM_NAMES = {
	["DEFAULT"] = isWorgen and xrp.L.VALUES.GR.Worgen or playerClass and (playerClass == "PRIEST" and _xrp.L.STANDARD or _xrp.L.HUMANOID) or _xrp.L.NOEQUIP,
	["CAT"] = _xrp.L.CAT,
	["BEAR"] = _xrp.L.BEAR,
	["MOONKIN"] = _xrp.L.MOONKIN,
	["ASTRAL"] = _xrp.L.ASTRAL,
	["AQUATIC"] = _xrp.L.AQUATIC,
	["TRAVEL"] = _xrp.L.TRAVEL,
	["FLIGHT"] = _xrp.L.FLIGHT,
	["TREANT"] = _xrp.L.TREANT,
	["SHADOWFORM"] = _xrp.L.SHADOWFORM,
	["GHOSTWOLF"] = _xrp.L.GHOST_WOLF,
	["HUMAN"] = xrp.L.VALUES.GR.Human,
	["DEFAULT\030SHADOWFORM"] = _xrp.L.WORGEN_SHADOW,
	["HUMAN\030SHADOWFORM"] = _xrp.L.HUMAN_SHADOW,
	["MERCENARY"] = _xrp.L.MERCENARY,
}

local function MakeWords(text)
	local form, equipment = text:match("^([^\029]+)\029?([^\029]*)$")
	if not equipment or equipment == "" then
		return FORM_NAMES[form]
	elseif not isWorgen and not playerClass then
		return equipment
	else
		return SUBTITLE_FORMAT:format(FORM_NAMES[form], equipment)
	end
end

local unsaved = {}
local function ToggleButtons(self)
	local changes = next(unsaved) ~= nil
	if next(xrpSaved.auto) and not _xrp.auto["DEFAULT"] and not unsaved["DEFAULT"] then
		self.Warning:Show()
		self.Warning:SetFormattedText(_xrp.L.WARN_FALLBACK, FORM_NAMES["DEFAULT"])
	else
		self.Warning:Hide()
	end
	self.Revert:SetEnabled(changes)
	self.Save:SetEnabled(changes)
end

function XRPEditorAutomationSave_OnClick(self, button, down)
	for form, profile in pairs(unsaved) do
		_xrp.auto[form] = profile or nil
	end
	table.wipe(unsaved)
	ToggleButtons(self:GetParent())
end

function XRPEditorAutomationRevert_OnClick(self, button, down)
	local parent = self:GetParent()
	local formProfile = _xrp.auto[parent.Form.contents]
	parent.Profile.contents = formProfile
	parent.Profile.Text:SetText(formProfile or NONE)
	table.wipe(unsaved)
	ToggleButtons(parent)
end

local function Profile_Checked(self)
	return self.arg1 == UIDROPDOWNMENU_INIT_MENU.contents
end

local function Profile_Click(self, arg1, arg2, checked)
	if not checked then
		UIDROPDOWNMENU_INIT_MENU.contents = arg1
		UIDROPDOWNMENU_INIT_MENU.Text:SetText(arg1 or NONE)
		local parent = UIDROPDOWNMENU_INIT_MENU:GetParent()
		unsaved[parent.Form.contents] = arg1 or false
		ToggleButtons(parent)
	end
end

local NONE_MENU = { text = NONE, checked = Profile_Checked, arg1 = nil, func = Profile_Click }
function XRPEditorAutomationProfile_PreClick(self, button, down)
	local parent = self:GetParent()
	parent.baseMenuList = { NONE_MENU }
	for i, profile in ipairs(xrp.profiles:List()) do
		parent.baseMenuList[i + 1] = { text = profile, checked = Profile_Checked, arg1 = profile, func = Profile_Click }
	end
end

local equipSets = {}
local function equipSets_Click(self, arg1, arg2, checked)
	if not checked then
		local set = (UIDROPDOWNMENU_MENU_VALUE or "DEFAULT") .. self.value
		UIDROPDOWNMENU_INIT_MENU.contents = set
		UIDROPDOWNMENU_INIT_MENU.Text:SetText(MakeWords(set))
		local parent = UIDROPDOWNMENU_INIT_MENU:GetParent()
		local setProfile
		if unsaved[set] ~= nil then
			setProfile = unsaved[set] or nil
		else
			setProfile = _xrp.auto[set]
		end
		parent.Profile.contents = setProfile
		parent.Profile.Text:SetText(setProfile or NONE)
		ToggleButtons(parent)
	end
	CloseDropDownMenus()
end

local function equipSets_Check(self)
	return (UIDROPDOWNMENU_MENU_VALUE or "DEFAULT") .. self.value == UIDROPDOWNMENU_INIT_MENU.contents
end

local function forms_Click(self, arg1, arg2, checked)
	if not checked then
		UIDROPDOWNMENU_INIT_MENU.contents = self.value
		UIDROPDOWNMENU_INIT_MENU.Text:SetText(MakeWords(self.value))
		local parent = UIDROPDOWNMENU_INIT_MENU:GetParent()
		local formProfile
		if unsaved[self.value] ~= nil then
			formProfile = unsaved[self.value] or nil
		else
			formProfile = _xrp.auto[self.value]
		end
		parent.Profile.contents = formProfile
		parent.Profile.Text:SetText(formProfile or NONE)
		ToggleButtons(parent)
	end
	CloseDropDownMenus()
end

local function forms_Check(self)
	return UIDROPDOWNMENU_INIT_MENU.contents == self.value
end

local noSet = not isWorgen and not playerClass and { text = FORM_NAMES["DEFAULT"], value = "", checked = equipSets_Check, func = equipSets_Click, } or nil
local mercenarySet = not isWorgen and not playerClass and { text = FORM_NAMES["MERCENARY"], value = "MERCENARY", checked = forms_Check, func = forms_Click, } or nil

XRPEditorAutomationForm_Mixin = {
	preClick = function(self, button, down)
		table.wipe(equipSets) -- Keep table reference the same.
		equipSets[1] = noSet
		local sets = C_EquipmentSet.GetEquipmentSetIDs()
		if #sets > 0 then
			for i, id in ipairs(sets) do
				sets[i] = C_EquipmentSet.GetEquipmentSetInfo(id)
			end
			table.sort(sets)
			for i, name in ipairs(sets) do
				equipSets[#equipSets + 1] = {
					text = name,
					value = "\029" .. name,
					checked = equipSets_Check,
					func = equipSets_Click,
				}
			end
		elseif not noSet then
			equipSets[#equipSets + 1]  = {
				text = _xrp.L.NO_SETS,
				disabled = true,
			}
		end
		equipSets[#equipSets + 1] = mercenarySet
	end,
}

local function FormMenuItem(form)
	local hasEquip = not _xrp.FORM_NO_EQUIPMENT[form]
	return {
		text = FORM_NAMES[form],
		value = form,
		func = forms_Click,
		checked = forms_Check,
		hasArrow = hasEquip and true or nil,
		menuList = hasEquip and equipSets or nil,
	}
end

if isWorgen then
	if playerClass == "DRUID" then
		XRPEditorAutomationForm_Mixin.baseMenuList = {
			FormMenuItem("DEFAULT"),
			FormMenuItem("HUMAN"),
			FormMenuItem("CAT"),
			FormMenuItem("BEAR"),
			FormMenuItem("MOONKIN"),
			FormMenuItem("ASTRAL"),
			FormMenuItem("TRAVEL"),
			FormMenuItem("FLIGHT"),
			FormMenuItem("AQUATIC"),
			FormMenuItem("TREANT"),
			FormMenuItem("MERCENARY"),
		}
	elseif playerClass == "PRIEST" then
		XRPEditorAutomationForm_Mixin.baseMenuList = {
			FormMenuItem("DEFAULT"),
			FormMenuItem("HUMAN"),
			FormMenuItem("DEFAULT\030SHADOWFORM"),
			FormMenuItem("HUMAN\030SHADOWFORM"),
			FormMenuItem("MERCENARY"),
		}
	else
		XRPEditorAutomationForm_Mixin.baseMenuList = {
			FormMenuItem("DEFAULT"),
			FormMenuItem("HUMAN"),
			FormMenuItem("MERCENARY"),
		}
	end
else
	if playerClass == "DRUID" then
		XRPEditorAutomationForm_Mixin.baseMenuList = {
			FormMenuItem("DEFAULT"),
			FormMenuItem("CAT"),
			FormMenuItem("BEAR"),
			FormMenuItem("MOONKIN"),
			FormMenuItem("ASTRAL"),
			FormMenuItem("TRAVEL"),
			FormMenuItem("FLIGHT"),
			FormMenuItem("AQUATIC"),
			FormMenuItem("TREANT"),
			FormMenuItem("MERCENARY"),
		}
	elseif playerClass == "PRIEST" then
		XRPEditorAutomationForm_Mixin.baseMenuList = {
			FormMenuItem("DEFAULT"),
			FormMenuItem("SHADOWFORM"),
			FormMenuItem("MERCENARY"),
		}
	elseif playerClass == "SHAMAN" then
		XRPEditorAutomationForm_Mixin.baseMenuList = {
			FormMenuItem("DEFAULT"),
			FormMenuItem("GHOSTWOLF"),
			FormMenuItem("MERCENARY"),
		}
	else
		XRPEditorAutomationForm_Mixin.baseMenuList = equipSets
	end
end

function XRPEditorAutomation_OnShow(self)
	local selectedForm, needsUpdate = self.Form.contents, false
	if not selectedForm then
		selectedForm = "DEFAULT"
		self.Form.contents = "DEFAULT"
		self.Form.Text:SetText(MakeWords("DEFAULT"))
	elseif selectedForm:find("\029", nil, true) then
		if not C_EquipmentSet.GetEquipmentSetID(selectedForm:match("^.*\029(.+)$")) then
			selectedForm = "DEFAULT"
			self.Form.Text:SetText(MakeWords(selectedForm))
			self.Form.contents = selectedForm
			needsUpdate = true
		end
	end
	for form, profile in pairs(unsaved) do
		if form:find("\029", nil, true) then
			if not C_EquipmentSet.GetEquipmentSetID(selectedForm:match("^.*\029(.+)$")) or not xrp.profiles[profile] then
				unsaved[form] = nil
			end
		end
	end
	needsUpdate = needsUpdate or not xrp.profiles[self.Profile.contents]
	if needsUpdate then
		local newProfile = _xrp.auto[selectedForm]
		self.Profile.contents = newProfile
		self.Profile.Text:SetText(newProfile or NONE)
	end
	ToggleButtons(self)
end