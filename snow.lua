mcl_weather.snow = {}

--register and modify the snow
--get the height of the snow
local snowdata = {
	["default:snow"] = "mcl_weather:snow2",
	["mcl_weather:snow2"] = "mcl_weather:snow3",
	["mcl_weather:snow3"] = "mcl_weather:snow4",
	["mcl_weather:snow4"] = "mcl_weather:snow5",
	["mcl_weather:snow5"] = "mcl_weather:snow6",
	["mcl_weather:snow6"] = "mcl_weather:snow7",
	["mcl_weather:snow7"] = "mcl_weather:snow8",
	["mcl_weather:snow8"] = "default:snowblock"
}

local function get_snow_nodebox_collisionbox(layer)
	local height = layer/8 - 0.5
	local walkheight = (height + 0.5)/2 - 0.5
	local node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, height, 0.5},
		},
	}
	local collision_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, walkheight, 0.5},
		},
	}
	return node_box, collision_box
end
local snowdef = table.copy(core.registered_nodes["default:snow"])

--override the first sone
local nodebox1, collisionbox1 = get_snow_nodebox_collisionbox(1)
core.override_item("default:snow", {
	node_box = nodebox1,
	collison_box = collisionbox1,
	selection_box = nodebox1,
    on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing and pointed_thing.type == "node" and placer then
			local playername = placer:get_player_name() or "idk someone"
			local under = pointed_thing.under
			if under and not core.is_protected(under, playername) then
				local name = core.get_node(under).name
				if name then
					local nextnode = snowdata[name]
					if nextnode then
						core.set_node(under, {name = nextnode})
						if not core.is_creative_enabled(playername) then
							itemstack:take_item()
						end
						return itemstack
					end
				end
			end
		end
		core.item_place(itemstack, placer, pointed_thing)
		return itemstack
	end,
})
--register the rest
for i = 2, 8 do
	local name = "mcl_weather:snow" .. i
	local nodebox, collisionbox = get_snow_nodebox_collisionbox(i)

	snowdef.node_box = nodebox
	snowdef.collision_box = collisionbox
	snowdef.selection_box = nodebox
	snowdef.drop = "default:snow " .. i
	core.register_node(name, snowdef)
end 

local PARTICLES_COUNT_SNOW = 100
mcl_weather.snow.init_done = false

local psdef= {
	amount = PARTICLES_COUNT_SNOW,
	time = 0, --stay on til we turn it off
	minpos = vector.new(-25,20,-25),
	maxpos =vector.new(25,25,25),
	minvel = vector.new(-0.2,-1,-0.2),
	maxvel = vector.new(0.2,-4,0.2),
	minacc = vector.new(0,-1,0),
	maxacc = vector.new(0,-4,0),
	minexptime = 3,
	maxexptime = 5,
	minsize = 2,
	maxsize = 5,
	collisiondetection = true,
	collision_removal = true,
	object_collision = true,
	vertical = true,
	glow = 1
}

function mcl_weather.has_snow(pos)
	if not mcl_weather.can_see_outdoors(pos) then
		return false
	end
	local name = mcl_weather.get_biome_name (pos)
	return name and mcl_weather.is_position_cold (name, pos)
end

function mcl_weather.snow.set_sky_box()
	mcl_weather.skycolor.add_layer(
		"weather-pack-snow-sky",
		{{r=0, g=0, b=0},
		{r=85, g=86, b=86},
		{r=135, g=135, b=135},
		{r=85, g=86, b=86},
		{r=0, g=0, b=0}})
	mcl_weather.skycolor.active = true
	for _, player in ipairs(core.get_connected_players()) do
		player:set_clouds({color="#ADADADE8", density = 0.8})
	end
	mcl_weather.skycolor.active = true
end

function mcl_weather.snow.clear()
	mcl_weather.skycolor.remove_layer("weather-pack-snow-sky")
	mcl_weather.snow.init_done = false
	mcl_weather.remove_all_spawners()
end

local function make_weather_for_player(player)
	mcl_weather.rain.remove_sound(player)
	mcl_weather.snow.add_player(player)
	mcl_weather.snow.set_sky_box()
end
mcl_weather.snow.make_weather_for_player = make_weather_for_player

function mcl_weather.snow.make_weather()
	for _, player in ipairs(core.get_connected_players()) do
		local pos = player:get_pos()
		if mcl_weather.has_snow(pos) then
			make_weather_for_player(player)
		end
	end
end

function mcl_weather.snow.step(_)
	mcl_weather.snow.make_weather()
end

function mcl_weather.snow.add_player(player)
	for i=1,2 do
		psdef.texture="weather_pack_snow_snowflake"..i..".png"
		mcl_weather.add_spawner_player(player,"snow"..i,psdef)
	end
end

if mcl_weather.allow_abm then
	core.register_abm({
		label = "Snow piles up",
		nodenames = {"group:opaque","group:leaves","group:snow_cover"},
		neighbors = {"air"},
		interval = 27,
		chance = 33,
		min_y = -30,
		action = function(pos, node)
			local abovehalf = vector.offset(pos,0,0.5,0)
			if (mcl_weather.state ~= "rain"
			    and mcl_weather.state ~= "thunder"
			    and mcl_weather.state ~= "snow")
				or not mcl_weather.has_snow(abovehalf) then
				return
			end
			local above = vector.offset(pos,0,1,0)
			local above_node = core.get_node(above)
			if above_node.name == "air" and mcl_weather.is_outdoor(pos) then
				local nn = nil
				if snowdata[node.name] then
					core.set_node(pos, {name = snowdata[node.name]})
				else
					core.set_node(above,{name = "default:snow"})
				end
			end
		end
	})
end
