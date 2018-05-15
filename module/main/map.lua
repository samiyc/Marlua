
-- VARIABLES
local module = {
	map = {},
	background = {},
	far_away = {},
	--tile info
	list_tile_info = {},
	nb_tile = 0,
	--background
	list_tile_info_back = {},
	nb_tile_back = 0,
	--far away
	list_tile_info_fa = {},
	nb_tile_fa = 0,
	--flag checkpoint
	flag = false,
	flagx = 0,
	flagy = 0,
	--mario on ice
	ice_level = false,
	--start
	xstart = 2,
	ystart = 3,
	--end
	end_of_map,
	--fog
	r_fog = 200,
	v_fog = 200,
	b_fog = 200,
	bk_dist = 1.5,
	fa_dist = 6,
	--timer
	timer = 360,
}

-- Initialisation
function module.load(cfg, entity_manager, only_entity)

	log("")
	log("## LECTURE DE LA MAP")
	if only_entity then
		log("Charge uniquement les entites")
	else
		--var
		module.nb_tile = 0
		module.nb_tile_back = 0
		module.nb_tile_fa = 0
		module.ice_level = false
		--fog
		module.r_fog = 200
		module.v_fog = 200
		module.b_fog = 200
		module.bk_dist = 1.5
		module.fa_dist = 6
	
		--fichier info
		module.load_info(cfg)
		--fog
		log("## FOG")
		cfg.apply_fog(module.r_fog, module.v_fog, module.b_fog, module.bk_dist, module.fa_dist)
	end
	module.flag = false
	
	--lecture map
	count = 0
	entity_manager.nb_entity = 0
	for line in love.filesystem.lines(cfg.map_name..".txt") do
		t = {}
		for i = 1, #line do
			t[i-1] = line:sub(i, i)
			entity_type = module.tile_type(t[i-1])
			if entity_type ~= nil then entity_manager.add_entity(entity_type, cubesize * count, cubesize * i) end
		end
		if not only_entity then module.map[count] = t end
		count = count + 1
	end
	
	if not only_entity then
		log("## CHARGEMENT DE L'ARRIERE PLAN")
		module.load_background_info(cfg)
		count = 0
		for line in love.filesystem.lines(cfg.map_name.."_background.txt") do
			t = {}
			for i = 1, #line do
				t[i-1] = line:sub(i, i)
			end
			module.background[count] = t
			count = count + 1
		end
		
		log("## CHARGEMENT DE L'ARRIERE PLAN DE L'ARRIERE PLAN")
		module.load_fa_info(cfg)
		count = 0
		for line in love.filesystem.lines(cfg.map_name.."_far_away.txt") do
			t = {}
			for i = 1, #line do
				t[i-1] = line:sub(i, i)
			end
			module.far_away[count] = t
			count = count + 1
		end
	end
	log("## FIN DE LECTURE DE LA MAP")
	log("")
end

function module.load_info(cfg)
	for line in love.filesystem.lines(cfg.map_name.."_info.txt") do
		words = split_words(line)
		if words[0] == "TIMER" then
			module.timer = tonumber(words[1])
			log("Timer : "..module.timer.."s")
		end
		if words[0] == "ICE_LEVEL" then
			module.ice_level = true
			log("ICE_LEVEL : acceleration/friction will be reduce on this map")
		end
		if words[0] == "FOG" then
			module.r_fog = tonumber(words[1])
			module.v_fog = tonumber(words[2])
			module.b_fog = tonumber(words[3])
			module.bk_dist = tonumber(words[4])
			module.fa_dist = tonumber(words[5])
			log("Fog color r:"..module.r_fog.." v:"..module.r_fog.." b:"..module.r_fog.." Layer2_dist:"..module.bk_dist.." Layer3_dist:"..module.fa_dist)
		end
		if words[0] == "START" then
			module.xstart = tonumber(words[1])
			module.ystart = tonumber(words[2])
			log("Start location x:"..module.xstart.." y:"..module.ystart)
		end
		if words[0] == "END" then
			var = tonumber(words[1])
			module.end_of_map = var * cubesize
			log("End location ligne:"..var.." xPos:"..module.end_of_map)
		end
		if words[0] == "GROUND" then
			tile = {}
			tile['tile_type'] = words[0]
			tile['char']      = words[1]
			tileset_name      = words[2]
			tile['tileset_name'] = tileset_name
			x = tonumber(words[3])
			y = tonumber(words[4])
			tile['quad'] = cfg.get_tile_quad(tileset_name, x, y)
	
			module.list_tile_info[module.nb_tile] = tile
			module.nb_tile = module.nb_tile + 1
			log(tile['tile_type'].." char:"..tile['char'].." tileset:"..tile['tileset_name'].." tile_x:"..x.." tile_y:"..y)
		end
		if words[0] == "ENTITY" then
			tile = {}
			tile['tile_type'] = words[2]
			tile['char']      = words[1]
	
			module.list_tile_info[module.nb_tile] = tile
			module.nb_tile = module.nb_tile + 1
			log(tile['tile_type'].." char:"..tile['char'])
		end
	end
end

function module.load_background_info(cfg)
	for line in love.filesystem.lines(cfg.map_name.."_background_info.txt") do
		words = split_words(line)
		if words[0] == "DECO" then
			tile = {}
			tile['tile_type'] = words[0]
			tile['char']      = words[1]
			tileset_name      = words[2]
			tile['tileset_name'] = tileset_name
			x = tonumber(words[3])
			y = tonumber(words[4])
			tile['quad'] = cfg.get_tile_quad(tileset_name, x, y)
			
			module.list_tile_info_back[module.nb_tile_back] = tile
			module.nb_tile_back = module.nb_tile_back + 1
			log(tile['tile_type'].." char:"..tile['char'].." tileset:"..tile['tileset_name'].." tile_x:"..x.." tile_y:"..y)
		end
	end
end

function module.load_fa_info(cfg)
	for line in love.filesystem.lines(cfg.map_name.."_far_away_info.txt") do
		words = split_words(line)
		if words[0] == "DECO" then
			tile = {}
			tile['tile_type'] = words[0]
			tile['char']      = words[1]
			tileset_name      = words[2]
			tile['tileset_name'] = tileset_name
			x = tonumber(words[3])
			y = tonumber(words[4])
			tile['quad'] = cfg.get_tile_quad(tileset_name, x, y)
			
			module.list_tile_info_fa[module.nb_tile_fa] = tile
			module.nb_tile_fa = module.nb_tile_fa + 1
			log(tile['tile_type'].." char:"..tile['char'].." tileset:"..tile['tileset_name'].." tile_x:"..x.." tile_y:"..y)
		end
	end
end

---------------------------------------------


-- GET TILE_TYPE
function module.tile_type(char)
	for i = 0, module.nb_tile - 1 do
		tile = module.list_tile_info[i]
		if tile['char'] == char then
			return tile['tile_type']
		end
	end
	return nil
end

-- GET QUAD
function module.tile_quad(char)
	for i = 0, module.nb_tile - 1 do
		tile = module.list_tile_info[i]
		if tile['char'] == char then
			return tile['quad']
		end
	end
	return nil
end
function module.tile_quad_via_type(tile_type)
	for i = 0, module.nb_tile - 1 do
		tile = module.list_tile_info[i]
		if tile['tile_type'] == tile_type then
			return tile['quad']
		end
	end
	return nil
end

-- GET TILESET_NAME
function module.tileset_name(char)
	for i = 0, module.nb_tile - 1 do
		tile = module.list_tile_info[i]
		if tile['char'] == char then
			return tile['tileset_name']
		end
	end
	return nil
end
function module.tileset_name_via_type(tile_type)
	for i = 0, module.nb_tile - 1 do
		tile = module.list_tile_info[i]
		if tile['tile_type'] == tile_type then
			return tile['tileset_name']
		end
	end
	return nil
end

--BACKGROUND
function module.tile_type_background(char)
	for i = 0, module.nb_tile_back - 1 do
		tile = module.list_tile_info_back[i]
		if tile['char'] == char then
			return tile['tile_type']
		end
	end
	return nil
end
function module.tile_quad_background(char)
	for i = 0, module.nb_tile_back - 1 do
		tile = module.list_tile_info_back[i]
		if tile['char'] == char then
			return tile['quad']
		end
	end
	return nil
end
function module.tileset_name_background(char)
	for i = 0, module.nb_tile_back - 1 do
		tile = module.list_tile_info_back[i]
		if tile['char'] == char then
			return tile['tileset_name']
		end
	end
	return nil
end

--FAR FAR AWAY
function module.tile_type_fa(char)
	for i = 0, module.nb_tile_fa - 1 do
		tile = module.list_tile_info_fa[i]
		if tile['char'] == char then
			return tile['tile_type']
		end
	end
	return nil
end
function module.tile_quad_fa(char)
	for i = 0, module.nb_tile_fa - 1 do
		tile = module.list_tile_info_fa[i]
		if tile['char'] == char then
			return tile['quad']
		end
	end
	return nil
end
function module.tileset_name_fa(char)
	for i = 0, module.nb_tile_fa - 1 do
		tile = module.list_tile_info_fa[i]
		if tile['char'] == char then
			return tile['tileset_name']
		end
	end
	return nil
end



-- MODULE END
return module