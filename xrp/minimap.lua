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

local L = xrp.L

do
	local settings
	xrp:HookLoad(function() settings = xrp.settings end)

	local minimap_UpdatePosition
	do
		local minimapShapes = {
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

		function minimap_UpdatePosition(self)
			local angle = math.rad(settings.minimap or 225)
			local x, y, q = math.cos(angle), math.sin(angle), 1
			if x < 0 then q = q + 1 end
			if y > 0 then q = q + 2 end
			if minimapShapes[GetMinimapShape and GetMinimapShape() or "ROUND"][q] then
				x, y = x*80, y*80
			else
				-- 103.13708498985 = math.sqrt(2*(80)^2)-10
				x = math.max(-80, math.min(x*103.13708498985, 80))
				y = math.max(-80, math.min(y*103.13708498985, 80))
			end
			self:SetPoint("CENTER", Minimap, "CENTER", x, y)
		end
	end

	do
		local function minimap_UpdateIcon()
			if xrp.units.target and xrp.units.target.VA then
				xrp.minimap.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_03")
			else
				if not xrp.current.FC or xrp.current.FC == "0" or xrp.current.FC == "1" then
					xrp.minimap.icon:SetTexture("Interface\\Icons\\Ability_Malkorok_BlightofYshaarj_Red")
				else
					xrp.minimap.icon:SetTexture("Interface\\Icons\\Ability_Malkorok_BlightofYshaarj_Green")
				end
			end
		end

		xrp:HookEvent("MSP_UPDATE", minimap_UpdateIcon)
		xrp:HookEvent("MSP_RECEIVE", minimap_UpdateIcon)

		xrp.minimap:SetScript("OnEvent", function(self, event, addon)
			if event == "ADDON_LOADED" and addon == "xrp" then
				minimap_UpdatePosition(self)
				minimap_UpdateIcon()
				self:UnregisterAllEvents()
				self:SetScript("OnEvent", minimap_UpdateIcon)
				self:RegisterEvent("PLAYER_TARGET_CHANGED")
			end
		end)
		xrp.minimap:RegisterEvent("ADDON_LOADED")
	end

	do
		local function minimap_OnUpdate(self)
			local mx, my = Minimap:GetCenter()
			local px, py = GetCursorPosition()
			local scale = Minimap:GetEffectiveScale()
			px, py = px / scale, py / scale
			settings.minimap = math.deg(math.atan2(py - my, px - mx)) % 360
			minimap_UpdatePosition(self)
		end

		xrp.minimap:SetScript("OnDragStart", function(self)
			self:LockHighlight()
			self.dim:Hide()
			self:SetScript("OnUpdate", minimap_OnUpdate)
		end)
	end
end

xrp.minimap:SetScript("OnDragStop", function(self)
	self:SetScript("OnUpdate", nil)
	self:UnlockHighlight()
end)

do
	local menulist_status = {}
	do
		local function minimap_StatusSelect(self, status, arg2, checked)
			local FC = xrp.selected.FC
			if not checked and status ~= FC then
				xrp.current.FC = status
			elseif not checked then
				xrp.current.FC = nil
			end
			ToggleDropDownMenu(nil, nil, xrp.minimap.menu)
		end

		menulist_status[#menulist_status + 1] = { text = xrp.values.FC_EMPTY, checked = false, arg1 = "0", func = minimap_StatusSelect }
		for value, text in ipairs(xrp.values.FC) do
			menulist_status[#menulist_status + 1] = { text = text, checked = false, arg1 = tostring(value), func = minimap_StatusSelect, }
		end
	end

	local menulist_profiles = {}
	local minimap_menulist = {
		{ text = XRP, isTitle = true, notCheckable = true, },
		{ text = L["Profiles"], notCheckable = true, hasArrow = true, menuList = menulist_profiles, },
		{ text = XRP_FC, notCheckable = true, hasArrow = true, menuList = menulist_status, },
		{ text = XRP_CU..CONTINUED, notCheckable = true, func = function() StaticPopup_Show("XRP_CURRENTLY") end, },
		{ text = L["Profile editor"], notCheckable = true, func = function() xrp:ToggleEditor() end, },
		{ text = L["Profile viewer"], notCheckable = true, func = function() xrp:ToggleViewer() end, },
		{ text = CANCEL, notCheckable = true, },
	}

	do
		local function minimap_ProfileSelect(self, name, arg2, checked)
			if not checked then
				xrp.profiles(name)
			end
			ToggleDropDownMenu(nil, nil, xrp.minimap.menu)
		end

		xrp.minimap:SetScript("OnClick", function(self, button, down)
			if not down then
				if button == "LeftButton" then
					if xrp.units.target and xrp.units.target.VA then
						xrp:ShowViewerUnit("target")
					else
						local FC, FCnil = xrp.current.FC, xrp.selected.FC
						local IC, ICnil = FC ~= nil and FC ~= "1" and FC ~= "0", FCnil ~= nil and FCnil ~= "1" and FCnil ~= "0"
						if FC ~= xrp.selected.FC and IC ~= ICnil then
							xrp.current.FC = nil
						elseif IC then
							xrp.current.FC = "1"
						else
							xrp.current.FC = "2"
						end
					end
				elseif button == "RightButton" then
					local FC = xrp.current.FC or "0"
					for _, item in ipairs(menulist_status) do
						item.checked = FC == item.arg1
					end

					wipe(menulist_profiles)
					for _, name in ipairs(xrp.profiles()) do
						menulist_profiles[#menulist_profiles + 1] = { text = name, checked = xrp_selectedprofile == name, arg1 = name, func = minimap_ProfileSelect, }
					end

					EasyMenu(minimap_menulist, xrp.minimap.menu, xrp.minimap, 3, 10, "MENU", nil)
				end
			end
		end)
	end
end

xrp.minimap:SetScript("OnEnter", function(self, motion)
	if motion then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", 30, 4)
		GameTooltip:SetText(L["Click to:"])
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(("|TInterface\\Icons\\Ability_Malkorok_BlightofYshaarj_Red:20|t: %s"):format(L["Toggle your status to IC."]))
		GameTooltip:AddLine(("|TInterface\\Icons\\Ability_Malkorok_BlightofYshaarj_Green:20|t: %s"):format(L["Toggle your status to OOC."]))
		GameTooltip:AddLine(("|TInterface\\Icons\\INV_Misc_Book_03:20|t: %s"):format(L["View your target's profile."]))
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["Right click for the menu."])
		GameTooltip:Show()
	end
end)

xrp.minimap:SetScript("OnLeave", function(self, motion)
	GameTooltip:Hide()
end)

StaticPopupDialogs["XRP_CURRENTLY"] = {
	text = L["What are you currently doing?"],
	button1 = ACCEPT,
	button2 = RESET,
	button3 = CANCEL,
	hasEditBox = true,
	OnShow = function(self, data)
		self.editBox:SetWidth(self.editBox:GetWidth() + 150)
		self.editBox:SetText(xrp.current.CU or "")
		self.editBox:HighlightText()
		self.button1:Disable()
		if xrp.current.CU == xrp.selected.CU then
			self.button2:Disable()
		end
	end,
	EditBoxOnTextChanged = function(self, data)
		if self:GetText() ~= (xrp.current.CU or "") then
			self:GetParent().button1:Enable()
		else
			self:GetParent().button1:Disable()
		end
	end,
	OnAccept = function(self, data, data2)
		xrp.current.CU = self.editBox:GetText()
	end,
	OnCancel = function(self, data, data2) -- Reset button.
		xrp.current.CU = nil
	end,
	enterClicksFirstButton = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
