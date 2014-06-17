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
if not (select(4, GetAddOnInfo("xrp_tooltip"))) then
	return
end

do
	local tooltip_settings = { "reaction", "watching", "guildrank", "rprace", "noopfaction", "nohostile", "extraspace" }

	function xrp.options.tooltip.okay()
		for _, tt in ipairs(tooltip_settings) do
			xrp_settings.tooltip[tt] = self[tt]:GetChecked() and true or false
		end
	end

	function xrp.options.tooltip:refresh()
		for _, tt in ipairs(tooltip_settings) do
			self[tt]:SetChecked(xrp_settings.tooltip[tt])
		end
	end
end

function xrp.options.tooltip:default()
	for tt, setting in pairs(xrp_settings.tooltip) do
		xrp_settings.tooltip[tt] = nil
	end

	self:refresh()
end

xrp.options.tooltip.parent = XRP
xrp.options.tooltip.name = xrp.L["Tooltip"]
InterfaceOptions_AddCategory(xrp.options.tooltip)

xrp:HookLoad(function()
	xrp.options.tooltip:refresh()
end)
