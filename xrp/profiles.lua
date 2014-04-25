--[[
	© Justin Snelgrove

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU Lesser General Public License as
	published by the Free Software Foundation, either version 3 of the
	License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public
	License along with this program.  If not, see
	<http://www.gnu.org/licenses/>.
]]

-- This key is used to 'hide' the name of a profile inside its own meta
-- table. This is obviously accessible, but it just prevents accidental
-- mucking with.
local nk = {}

local overrides = {}

xrp.profile = setmetatable({}, {
	__index = function(profile, field)
		local contents
		if xrp.toon.fields[field] then
			contents = xrp.toon.fields[field]
		elseif overrides[field] then
			contents = overrides[field]
		elseif xrp_profiles[xrp_selectedprofile] and xrp_profiles[xrp_selectedprofile][field] then
			contents = xrp_profiles[xrp_selectedprofile][field]
		elseif xrp.defaults[xrp_selectedprofile][field] == true and xrp.profiles["Default"][field] then
			contents = xrp_profiles["Default"][field]
		else
			return nil
		end
		if field == "AH" then
			return xrp:ConvertHeight(contents, "msp")
		elseif field == "AW" then
			return xrp:ConvertWeight(contents, "msp")
		else
			return contents
		end
	end,
	__newindex = function(profile, field, contents)
		if not xrp.msp.unitfields[field] and not xrp.msp.metafields[field] and field:match("^%u%u$") and overrides[field] ~= contents then
			overrides[field] = contents
			xrp.msp:UpdateField(field)
		end
	end,
	__call = function(profile, wantname)
		if wantname then
			return xrp_selectedprofile
		end
		local out = {}
		for field, contents in pairs(xrp_profiles["Default"]) do
			if xrp.defaults[xrp_selectedprofile][field] then
				out[field] = contents
			end
		end
		for field, contents in pairs(xrp_profiles[xrp_selectedprofile]) do
			out[field] = contents
		end
		for field, contents in pairs(overrides) do
			out[field] = contents
		end
		for field, contents in pairs(xrp.toon.fields) do
			out[field] = contents
		end
		out.AW = out.AW and xrp:ConvertWeight(out.AW, "msp") or nil
		out.AH = out.AH and xrp:ConvertHeight(out.AH, "msp") or nil
		return out
	end,
	__metatable = false,
})

local profmt = {
	__index = function(profile, field)
		if not xrp_profiles[profile[nk]] then
			xrp_profiles[profile[nk]] = {}
		end
		if xrp_profiles[profile[nk]][field] then
			return xrp_profiles[profile[nk]][field]
		end
		return nil
	end,
	__newindex = function(profile, field, contents)
		if xrp.msp.unitfields[field] or xrp.msp.metafields[field] or not field:match("^%u%u$") then
			return
		end
		local name = profile[nk]
		if type(contents) == "string" and contents ~= "" and (not xrp_profiles[name] or xrp_profiles[name][field] ~= contents) then
			if not xrp_profiles[name] then
				xrp_profiles[name] = {}
			end
			xrp_profiles[name][field] = contents
			if name == xrp_selectedprofile then
				xrp.msp:UpdateField(field)
			end
			xrp:FireEvent("PROFILE_FIELD_SAVE", name, field)
		elseif (contents == "" or not contents) and xrp_profiles[name] and xrp_profiles[name][field] then
			xrp_profiles[name][field] = nil
			if name == xrp_selectedprofile then
				xrp.msp:UpdateField(field)
			end
			xrp:FireEvent("PROFILE_FIELD_SAVE", name, field)
		end
	end,
	__call = function(profile, newname)
		if type(newname) == "number" then
			local length = 0
			for field, contents in pairs(xrp_profiles[profile[nk]]) do
				length = length + #contents
			end
			if length > newname then
				return length
			end
		elseif type(newname) == "string" then
			local name = profile[nk]
			if (type(xrp_profiles[name]) ~= "table" or (name == "Default" and name ~= newname and (not xrp_profiles["Default (Old)"] or newname == "Default (Old)"))) and type(xrp_profiles[newname]) == "table" then
				if name == "Default" and newname ~= "Default (Old)" then
					xrp_profiles["Default (Old)"] = xrp_profiles[name]
				end
				-- Copy profile into the empty table called.
				xrp_profiles[name] = {}
				for field, contents in pairs(xrp_profiles[newname]) do
					xrp_profiles[name][field] = contents
				end
				if xrp_selectedprofile == name then
					xrp.profiles(name)
				end
				return true
			elseif type(xrp_profiles[name]) == "table" and (type(xrp_profiles[newname]) ~= "table" or (newname == "Default" and name ~= newname and (not xrp_profiles["Default (Old)"] or name == "Default (Old)"))) then
				if newname == "Default" and name ~= "Default (Old)" then
					xrp_profiles["Default (Old)"] = xrp_profiles[newname]
				end
				-- Rename profile to the nonexistant table provided.
				xrp_profiles[newname] = xrp_profiles[name]
				-- Select the new name if this is our active profile.
				if xrp_selectedprofile == name then
					xrp.profiles(newname)
				end
				xrp.profiles[name] = nil -- Use table access to save Default.
				xrp:FireEvent("PROFILE_RENAME", name, newname)
				return true
			end
		elseif not newname then
			local profile = {}
			for field, contents in pairs(xrp_profiles[name]) do
				profile[field] = contents
			end
			return profile
		end
		return false
	end,
	__metatable = false,
}

local profs = setmetatable({}, { __mode = "v" })

xrp.profiles = setmetatable({}, {
	__index = function(profiles, name)
		if not profs[name] then
			profs[name] = setmetatable({ [nk] = name }, profmt)
		end
		return profs[name]
	end,
	__newindex = function(profiles, name, profile)
		if type(profile) == "table" then
			if not profs[name] then
				profs[name] = setmetatable({ [nk] = name }, profmt)
			end
			for field, contents in pairs(profile) do
				profs[name][field] = contents
			end
		elseif profile == "" or profile == nil then
			profs[name] = nil
			if name ~= "Default" then
				xrp_profiles[name] = nil
				xrp_defaults[name] = nil
			else
				-- Wipe fields if profile is Default, but don't delete
				-- the table.
				for field, _ in pairs(xrp_profiles[name]) do
					xrp_profiles[name][field] = nil
				end
				-- Fill out one default value...
				xrp_profiles[name].NA = xrp.toon.name
			end
			if name == xrp_selectedprofile then
				xrp.profiles("Default")
			end
			xrp:FireEvent("PROFILE_DELETE", name)
		end
	end,
	__call = function(profiles, name)
		if not name then
			local list = {}
			for name, _ in pairs(xrp_profiles) do
				list[#list + 1] = name ~= "Default" and name or nil
			end
			table.sort(list)
			table.insert(list, 1, "Default")
			return list
		elseif type(name) == "string" and xrp_profiles[name] then
			xrp_selectedprofile = name

			wipe(overrides) -- TODO: Should this really wipe the overrides?

			xrp.msp:Update()
			return true
		end
		return false
	end,
	__metatable = false,
})

local defmt = {
	__index = function(default, field)
		if default[nk] ~= "Default" and xrp_defaults[default[nk]] and xrp_defaults[default[nk]][field] ~= nil then
			return xrp_defaults[default[nk]][field]
		end
		return xrp_settings.defaults[field] == nil and true or xrp_settings.defaults[field]
	end,
	__newindex = function(default, field, state)
		if xrp.msp.unitfields[field] or xrp.msp.metafields[field] or not field:match("^%u%u$") or default[nk] == "Default" then
			return
		end
		if not xrp_defaults[default[nk]] then
			xrp_defaults[default[nk]] = {}
		end
		if state == nil or state == xrp_settings.defaults[field] then
			xrp_defaults[default[nk]][field] = nil
			if not next(xrp_defaults[default[nk]]) then
				xrp.defaults[default[nk]] = nil
			end
		elseif state == false or state == true then
			xrp_defaults[default[nk]][field] = state
		end
	end,
	__call = function(default)
		local out = {}
		for field, state in pairs(xrp_defaults[default[nk]]) do
			out[field] = state
		end
		return out
	end,
	__metatable = false,
}

local defs = setmetatable({}, { __mode = "v" })

xrp.defaults = setmetatable({}, {
	__index = function(defaults, name)
		if not defs[name] then
			defs[name] = setmetatable({ [nk] = name }, defmt)
		end
		return defs[name]
	end,
	__newindex = function(defaults, name, default)
		if type(default) == "table" then
			if not defs[name] then
				defs[name] = setmetatable({ [nk] = name }, defmt)
			end
			for field, default in pairs(default) do
				defs[name][field] = default
			end
		elseif default == "" or default == nil then
			defs[name] = nil
		end
	end,
	__metatable = false,
})

function xrp:Logout()
	-- Add one to the versions of any overriden fields. This means we can
	-- just pick them up where we left off next time (leading to lower
	-- bandwidth usage if the player doesn't change big fields often!),
	-- rather than incrementing by one on each and every login.
	local ttchanges = false
	for field, _ in pairs(overrides) do
		xrp_versions[field] = xrp_versions[field] + 1
		ttchanges = xrp.msp.ttfields[field] or ttchanges
	end
	if ttchanges then
		xrp_versions.TT = xrp_versions.TT + 1
	end
end
