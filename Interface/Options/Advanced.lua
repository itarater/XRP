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

XRP_CLEAR_CACHE = _xrp.L.CLEAR_CACHE .. CONTINUED
XRP_TIDY_CACHE = _xrp.L.TIDY_CACHE

function XRPOptionsAdvancedAutoClean_OnClick(self, button, down)
	if self:Get() then
		self:GetParent().CacheTidy:Hide()
	else
		self:GetParent().CacheTidy:Show()
	end
end