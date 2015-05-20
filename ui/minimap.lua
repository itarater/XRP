--[[
	© Justin Snelgrove
	(C) 2008-2011 Rabbit <rabbit.magtheridon@gmail.com>

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

local addonName, _xrp = ...

local Button

local TEXTURES = {
	"Interface\\Icons\\INV_Misc_Book_03", -- Target
	"Interface\\Icons\\Ability_Malkorok_BlightofYshaarj_Red", -- OOC
	"Interface\\Icons\\Ability_Malkorok_BlightofYshaarj_Green", -- IC
}

function XRPButton_UpdateIcon()
	local target = xrp.characters.byUnit.target
	if target and (target.hide or target.fields.VA) then
		Button:SetNormalTexture(TEXTURES[1])
		Button:SetPushedTexture(TEXTURES[1])
		return
	end
	local FC = xrp.current.fields.FC
	if not FC or FC == "0" or FC == "1" then
		Button:SetNormalTexture(TEXTURES[2])
		Button:SetPushedTexture(TEXTURES[2])
	else
		Button:SetNormalTexture(TEXTURES[3])
		Button:SetPushedTexture(TEXTURES[3])
	end
end

function XRPButton_OnEnter(self, motion)
	if motion then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", 0, 32)
		GameTooltip:SetText(xrp.current.fields.NA)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(SUBTITLE_FORMAT:format(_xrp.L.PROFILE, ("|cffffffff%s|r"):format(tostring(xrp.profiles.SELECTED))))
		local FC = xrp.current.fields.FC
		if FC and FC ~= "0" then
			GameTooltip:AddLine(SUBTITLE_FORMAT:format(_xrp.L.STATUS, ("|cff%s%s|r"):format(FC == "1" and "99664d" or "66b380", xrp.values.FC[FC])))
		end
		local CU = xrp.current.fields.CU
		if CU then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(STAT_FORMAT:format(xrp.fields.CU))
			GameTooltip:AddLine(("%s"):format(CU), 0.9, 0.7, 0.6, true)
		end
		GameTooltip:AddLine(" ")
		local target = xrp.characters.byUnit.target
		if target and (target.hide or target.fields.VA) then
			GameTooltip:AddLine(_xrp.L.CLICK_VIEW_TARGET, 1, 0.93, 0.67)
		elseif not FC or FC == "0" or FC == "1" then
			GameTooltip:AddLine(_xrp.L.CLICK_IC, 0.4, 0.7, 0.5)
		else
			GameTooltip:AddLine(_xrp.L.CLICK_OOC, 0.6, 0.4, 0.3)
		end
		GameTooltip:AddLine(_xrp.L.RTCLICK_MENU, 0.6, 0.6, 0.6)
		GameTooltip:Show()
	end
end

do
	local Status_menuList = {}
	do
		local function Status_Click(self, status, arg2, checked)
			if not checked then
				xrp:Status(status or "0")
			end
			CloseDropDownMenus()
		end
		local function Status_Checked(self)
			return self.arg1 == xrp.current.fields.FC
		end

		for i = 0, 4 do
			local s = tostring(i)
			Status_menuList[i + 1] = { text = xrp.menuValues.FC[s], checked = Status_Checked, arg1 = i ~= 0 and s or nil, func = Status_Click, }
		end
	end

	local Profiles_menuList = {}
	XRPButton_baseMenuList = {
		{ text = _xrp.L.PROFILES, notCheckable = true, hasArrow = true, menuList = Profiles_menuList, },
		{ text = _xrp.L.CHARACTER_STATUS, notCheckable = true, hasArrow = true, menuList = Status_menuList, },
		{ text = xrp.fields.CU .. CONTINUED, notCheckable = true, func = function() StaticPopup_Show("XRP_CURRENTLY") end, },
		{ text = _xrp.L.BOOKMARKS, notCheckable = true, func = function() XRPBookmarks:Toggle(1) end, },
		{ text = _xrp.L.VIEWER, notCheckable = true, func = function() XRPViewer:View() end, },
		{ text = _xrp.L.EDITOR, notCheckable = true, func = function() XRPEditor:Edit() end, },
		{ text = _xrp.L.OPTIONS, notCheckable = true, func = function() _xrp.Options() end, },
		{ text = CANCEL, notCheckable = true, func = _xrp.noFunc, },
	}

	do
		local function Profiles_Click(self, profileName, arg2, checked)
			if not checked and xrp.profiles[profileName] then
				xrp.profiles[profileName]:Activate()
			end
			CloseDropDownMenus()
		end

		function XRPButton_OnClick(self, button, down)
			if button == "LeftButton" then
				local target = xrp.characters.byUnit.target
				if target and (target.hide or target.fields.VA) then
					XRPViewer:View("target")
				else
					xrp:Status()
				end
				XRPButton_OnEnter(self, true)
				CloseDropDownMenus()
			elseif button == "RightButton" then
				table.wipe(Profiles_menuList)
				local selected = tostring(xrp.profiles.SELECTED)
				for i, profileName in ipairs(xrp.profiles:List()) do
					Profiles_menuList[#Profiles_menuList + 1] = { text = profileName, checked = selected == profileName, arg1 = profileName, func = Profiles_Click, }
				end
				XRPTemplatesMenu_OnClick(self, button, down)
			end
		end
	end
end

local UpdatePositionAttached
do
	do
		local MINIMAP_SHAPES = {
			["ROUND"] = { true, true, true, true },
			["SQUARE"] = { false, false, false, false },
			["CORNER-TOPLEFT"] = { false, false, false, true },
			["CORNER-TOPRIGHT"] = { false, false, true, false },
			["CORNER-BOTTOMLEFT"] = { false, true, false, false },
			["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
			["SIDE-LEFT"] = { false, true, false, true },
			["SIDE-RIGHT"] = { true, false, true, false },
			["SIDE-TOP"] = { false, false, true, true },
			["SIDE-BOTTOM"] = { true, true, false, false },
			["TRICORNER-TOPLEFT"] = { false, true, true, true },
			["TRICORNER-TOPRIGHT"] = { true, false, true, true },
			["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
			["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
		}
		function UpdatePositionAttached(self)
			local angle = math.rad(_xrp.settings.minimap.angle)
			local x, y, q = math.cos(angle), math.sin(angle), 1
			if x < 0 then q = q + 1 end
			if y > 0 then q = q + 2 end
			if MINIMAP_SHAPES[GetMinimapShape and GetMinimapShape() or "ROUND"][q] then
				x, y = x * 80, y * 80
			else
				-- 103.13708498985 = math.sqrt(2*(80)^2)-10
				x = math.max(-80, math.min(x * 103.13708498985, 80))
				y = math.max(-80, math.min(y * 103.13708498985, 80))
			end
			self:ClearAllPoints()
			self:SetPoint("CENTER", Minimap, "CENTER", x, y)
		end
	end
	local function Minimap_OnUpdate(self, elapsed)
		local mx, my = Minimap:GetCenter()
		local px, py = GetCursorPosition()
		local scale = Minimap:GetEffectiveScale()
		px, py = px / scale, py / scale
		_xrp.settings.minimap.angle = math.deg(math.atan2(py - my, px - mx)) % 360
		UpdatePositionAttached(self)
	end

	function XRPButtonAttached_OnDragStart(self, button)
		self:LockHighlight()
		self:SetScript("OnUpdate", Minimap_OnUpdate)
	end

	function XRPButtonAttached_OnDragStop(self)
		self:SetScript("OnUpdate", nil)
		self:UnlockHighlight()
	end
end

function XRPButtonDetached_OnDragStart(self, button)
	if IsShiftKeyDown() then
		self:LockHighlight()
		self:StartMoving()
	end
end

function XRPButtonDetached_OnDragStop(self)
	self:StopMovingOrSizing()
	_xrp.settings.minimap.point, _xrp.settings.minimap.x, _xrp.settings.minimap.y = select(3, self:GetPoint())
	self:UnlockHighlight()
end

_xrp.settingsToggles.minimap = {
	enabled = function(setting)
		if setting then
			xrp:HookEvent("UPDATE", XRPButton_UpdateIcon)
			xrp:HookEvent("RECEIVE", XRPButton_UpdateIcon)
			if _xrp.settings.minimap.detached then
				if Button and Button == LibDBIcon10_XRP then
					Button:UnregisterAllEvents()
					Button:Hide()
				end
				if not XRPButton then
					CreateFrame("Button", "XRPButton", UIParent, "XRPButtonTemplate")
					XRPButton:SetPoint(_xrp.settings.minimap.point, UIParent, _xrp.settings.minimap.point, _xrp.settings.minimap.x, _xrp.settings.minimap.y)
				end
				Button = XRPButton
			else
				if Button and Button == XRPButton then
					Button:UnregisterAllEvents()
					Button:Hide()
				end
				if not LibDBIcon10_XRP then
					CreateFrame("Button", "LibDBIcon10_XRP", Minimap, "XRPMinimapTemplate")
					UpdatePositionAttached(LibDBIcon10_XRP)
				end
				Button = LibDBIcon10_XRP
			end
			XRPButton_UpdateIcon()
			Button:RegisterEvent("PLAYER_TARGET_CHANGED")
			Button:RegisterEvent("PLAYER_ENTERING_WORLD")
			Button:Show()
		elseif Button ~= nil then
			xrp:UnhookEvent("UPDATE", XRPButton_UpdateIcon)
			xrp:UnhookEvent("RECEIVE", XRPButton_UpdateIcon)
			Button:UnregisterAllEvents()
			Button:Hide()
			Button = nil
		end
	end,
	detached = function(setting)
		if not _xrp.settings.minimap.enabled or not Button or setting and Button == XRPButton or not setting and Button == LibDBIcon10_XRP then return end
		_xrp.settingsToggles.minimap.enabled(_xrp.settings.minimap.enabled)
	end,
}
