
-- VARIABLES
local module = {
	var = "",
	map_name = "",
	background = nil,
	test = false,
	list_tileset = {},
	nb_tileset = 0,
	fog_done = "fog",
	--
	list_map = {},
	nb_map = 0,
}

-- FONCTIONS 
function module.load()
	log("## LECTURE DU FICHIER CFG.TXT")
	for line in love.filesystem.lines("cfg.txt") do
		words = split_words(line)
		if words[0] == "TILESET" then
			tileset = {}
			tileset['name']      = words[1] 
			layer                = words[2]
			tileset['layer']     = layer
			tileset['tile_size'] = tonumber(words[3])
			tileset['scale']     = cubesize / tileset['tile_size']
			tileset['grid']      = tonumber(words[4])
			
			--GESTION IMAGES--
			tileset['tileset_path'] = words[5]
			tileset['tileset_img'] = love.graphics.newImage(words[5])
			r = tonumber(words[6])
			v = tonumber(words[7])
			b = tonumber(words[8])
			tileset['r'] = r
			tileset['v'] = v
			tileset['b'] = b
			if string.find(layer, "2") then tileset['tileset_img_back'] = love.graphics.newImage(words[5]) end
			if string.find(layer, "3") then tileset['tileset_img_fa']   = love.graphics.newImage(words[5]) end
			if r ~= nil and v ~= nil and b ~= nil then 
				if string.find(layer, "1") then remove_tileset_background(tileset['tileset_img'], words[5], r, v, b) end
				if string.find(layer, "2") then remove_tileset_background(tileset['tileset_img_back'], words[5], r, v, b) end
				if string.find(layer, "3") then remove_tileset_background(tileset['tileset_img_fa'], words[5], r, v, b) end
			end
			--if string.find(layer, "2") then away_fx_image(tileset['tileset_img_back'], 200, 1.5) end
			--if string.find(layer, "3") then	away_fx_image(tileset['tileset_img_fa'], 200, 6) end
			--FIN GESTION IMAGES--
			
			module.list_tileset[module.nb_tileset] = tileset
			module.nb_tileset = module.nb_tileset + 1
			log("Tileset name:"..tileset['name'].." size:"..tileset['tile_size'].." img:"..words[5])
		end
		if words[0] == "MAP" then 
			--module.map_name = words[1]--old
			nmap = {}
			nmap['name'] = words[1]
			nmap['path'] = words[2]
			log("Map name:"..words[1].." path:"..words[2])
			module.list_map[module.nb_map] = nmap
			module.nb_map = module.nb_map + 1
		end
		if words[0] == "BACKGROUND" then 
			module.background = love.graphics.newImage(words[1])
			log("Background:"..words[1])
		end
		if words[0] == "TEST" and words[1] == "YES" then 
			module.test = true
			log("Jeux en mode test. les entites sont desactivees")
		end
	end
end

function module.apply_fog(r, v, b, bk_dist, fa_dist)
	if not string.find(module.fog_done, r..v..b..bk_dist..fa_dist) then
		module.fog_done = r..v..b..bk_dist..fa_dist
		for i = 0, module.nb_tileset - 1 do
			tileset = module.list_tileset[i]
			if string.find(tileset['layer'], "2") and tileset['tileset_img_back'] ~= nil then
				tileset['tileset_img_back'] = love.graphics.newImage(tileset['tileset_path'])
				--remove_tileset_background(tileset['tileset_img_back'], tileset['tileset_path'], tileset['r'], tileset['v'], tileset['b'])
				away_fx_image(tileset['tileset_img_back'], tileset['tileset_path'], tileset['r'], tileset['v'], tileset['b'], r,v,b, bk_dist)
				log("Apply fog on tileset "..tileset['name'].." layer 2")
			end
			if string.find(tileset['layer'], "3") and tileset['tileset_img_fa'] ~= nil then
				tileset['tileset_img_fa'] = love.graphics.newImage(tileset['tileset_path'])
				--remove_tileset_background(tileset['tileset_img_fa'], tileset['tileset_path'], tileset['r'], tileset['v'], tileset['b'])
				away_fx_image(tileset['tileset_img_fa'], tileset['tileset_path'], tileset['r'], tileset['v'], tileset['b'], r,v,b, fa_dist)
				log("Apply fog on tileset "..tileset['name'].." layer 3")
			end
		end
	else
		log("Fog already done")
	end
end

----------

function module.get_tile_quad(name, x, y)
	return get_tile_quad_from_tileset(module.get_tileset_img(name), module.get_tileset_tile_size(name), module.get_tileset_grid_size(name), x, y)
end
function module.get_tileset_img(name)
	for i = 0, module.nb_tileset - 1 do
		tileset = module.list_tileset[i]
		if tileset['name'] == name then
			return tileset['tileset_img']
		end
	end
	return nil
end
function module.get_tileset_tile_size(name)
	for i = 0, module.nb_tileset - 1 do
		tileset = module.list_tileset[i]
		if tileset['name'] == name then
			return tileset['tile_size']
		end
	end
	return nil
end
function module.get_tileset_grid_size(name)
	for i = 0, module.nb_tileset - 1 do
		tileset = module.list_tileset[i]
		if tileset['name'] == name then
			return tileset['grid']
		end
	end
	return nil
end
function module.get_tileset_scale(name)
	for i = 0, module.nb_tileset - 1 do
		tileset = module.list_tileset[i]
		if tileset['name'] == name then
			return tileset['scale']
		end
	end
	return nil
end
function module.get_tileset_img_back(name)
	for i = 0, module.nb_tileset - 1 do
		tileset = module.list_tileset[i]
		if tileset['name'] == name then
			return tileset['tileset_img_back']
		end
	end
	return nil
end
function module.get_tileset_img_fa(name)
	for i = 0, module.nb_tileset - 1 do
		tileset = module.list_tileset[i]
		if tileset['name'] == name then
			return tileset['tileset_img_fa']
		end
	end
	return nil
end

--

function module.draw_map_list()
	for i = 0, module.nb_map - 1 do
		nmap = module.list_map[i]
		love.graphics.print(nmap['name'], 10, i*20+33) 
	end
end
function module.select_map(i)
	nmap = module.list_map[i]
	module.map_name = nmap['path']
end

-- MODULE END
return module