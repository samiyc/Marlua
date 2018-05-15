

-- VARIABLES
local module = {
	map_tileset = nil,
	quad_ground = nil,
	quad_glass = nil,
	scale = 0,
	var = 0,
}

-- FONCTIONS 
function module.load()
end

function module.update(mario, dt)
	if mario.x - 0.5*screen_width > 0 then
		xoffsetcam = math.floor(mario.x - 0.5*screen_width)
	else
		xoffsetcam = 0
	end
end

function module.render(cfg, module_map, module_mario, entity_manager)
	module.render_background(cfg)
	module.render_map(cfg, module_map)
	module.render_entity(cfg, module_map, entity_manager)
	module.render_mario(cfg, module_mario, entity_manager)
	--module.render_grid()
	--module.map_info(module_map)
	--module.entity_info(entity_manager)
end

function module.render_background(cfg)
	if cfg.background ~= nil then
		love.graphics.draw(cfg.background, 0, 0)
	end
end

function module.render_mario(cfg, m, entity_manager)
	clignement = true
	if m.protection_timer > 0 then
		if math.floor(m.protection_timer * 10) % 2 == 0 then
			clignement = false
		end
	end
	if clignement then
		x = math.floor(m.x - xoffsetcam)
		y = math.floor(screen_height - m.y - m.h)
		if cfg.test then love.graphics.rectangle("line", x, y, m.w, m.h) end
		--offset tile
		x = x -5
		y = y -10
		if m.big then y = y + 3 end
		--draw
		entity_type = entity_manager.get_entity_type(m.entity_type_name())
		et_statut   = entity_manager.get_entity_type_statut(entity_type, m.statut)
		frames = et_statut['frames']
		tileset_name = et_statut['tileset_name']
		img = cfg.get_tileset_img(tileset_name)
		scale = cfg.get_tileset_scale(tileset_name)
		if m.xacc > -30 then
			love.graphics.draw(img, frames[m.current_frame], x, y, 0, scale, scale)
		else
			love.graphics.draw(img, frames[m.current_frame], x + cubesize, y, 0, -scale, scale)
		end
	end
end

function module.render_map(cfg, module_map)
	map = module_map.map
	back_map = module_map.background
	fa_map = module_map.far_away
	nb_tile_disp = 0
	nb_tile_background_disp = 0
	nb_tile_fa_disp = 0
	blockleft = math.round((xoffsetcam - cubesize)/ cubesize)
	nbxtile = math.floor(screen_width/cubesize) + 2
	for i = blockleft, blockleft + nbxtile do
		xcur = cubesize * (i - xoffsetcam / cubesize)
		for j = 0, 18 do
			ycur = screen_height - cubesize * (j + 1) 
			--Far away
			if fa_map[i] ~= nil and fa_map[i][j] ~= nil then
				if module_map.tile_type_fa(fa_map[i][j]) == "DECO" then
					tileset_name = module_map.tileset_name_fa(fa_map[i][j])
					img = cfg.get_tileset_img_fa(tileset_name)
					scale = cfg.get_tileset_scale(tileset_name)
					--DRAW
					love.graphics.draw(img, module_map.tile_quad_fa(fa_map[i][j]), xcur, ycur, 0, scale, scale)
					nb_tile_fa_disp = nb_tile_fa_disp + 1
				end
			end
			--Background
			if back_map[i] ~= nil and back_map[i][j] ~= nil then
				if module_map.tile_type_background(back_map[i][j]) == "DECO" then
					tileset_name = module_map.tileset_name_background(back_map[i][j])
					img = cfg.get_tileset_img_back(tileset_name)
					scale = cfg.get_tileset_scale(tileset_name)
					--DRAW
					love.graphics.draw(img, module_map.tile_quad_background(back_map[i][j]), xcur, ycur, 0, scale, scale)
					nb_tile_background_disp = nb_tile_background_disp + 1
				end
			end
			--Foreground
			if map[i] ~= nil and map[i][j] ~= nil then
				if module_map.tile_type(map[i][j]) == "GROUND" then
					tileset_name = module_map.tileset_name(map[i][j])
					img = cfg.get_tileset_img(tileset_name)
					scale = cfg.get_tileset_scale(tileset_name)
					--DRAW
					love.graphics.draw(img, module_map.tile_quad(map[i][j]), xcur, ycur, 0, scale, scale)
					nb_tile_disp = nb_tile_disp + 1
				end
			end
		end
	end
end

function module.render_entity(cfg, module_map, entity_manager)
	nb_entity_disp = 0
	for i = 0, entity_manager.nb_entity - 1 do
		entity = entity_manager.list_entity[i]
		if entity['statut'] ~= "DEAD" then
			x = math.floor(entity['x'] - xoffsetcam)
			y = math.floor(screen_height - entity['y'])
			entity_type_name = entity['type']
			if x > -cubesize and x < screen_width then
				--et_type
				entity_type = entity_manager.get_entity_type(entity_type_name)
				et_statut   = entity_manager.get_entity_type_statut(entity_type, entity['statut'])
				if et_statut ~= nil then
					frames = et_statut['frames']
					tileset_name = et_statut['tileset_name']
					--cfg
					img = cfg.get_tileset_img(tileset_name)
					scale = cfg.get_tileset_scale(tileset_name)
					--small ?
					w = cubesize
					if entity_type_name == "CHAMP" then 
						x = x + enemi_hitbox_offset_x
						y = y + enemi_hitbox_offset_y - 3
						w = cubesize + enemi_hitbox_ajust_w
						scale = scale / 1.5
					end
					--offset tile
					if entity_type_name == "ENEMIE2" then y = y + 2 end
					--draw
					if entity['direction'] == "DROITE" then
						love.graphics.draw(img, frames[entity['current_frame']], x, y, 0, scale, scale)
					else
						love.graphics.draw(img, frames[entity['current_frame']], x + w, y, 0, -scale, scale)
					end
					nb_entity_disp = nb_entity_disp + 1
					
					--hitbox
					if cfg.test then
						hbx = x
						hby = y
						hbw = cubesize
						hbh = cubesize
						if small_entity(entity_type_name) then
							--love.graphics.rectangle("line", x, y, cubesize, cubesize)
							hbx = hbx + enemi_hitbox_offset_x
							hby = hby + enemi_hitbox_offset_y
							hbw = hbw + enemi_hitbox_ajust_w
							hbh = hbh + enemi_hitbox_ajust_h
						end
						love.graphics.setColor(200, 0, 0)
						love.graphics.rectangle("line", hbx, hby, hbw, hbh)
						love.graphics.setColor(255, 255, 255)
					end
				end
			end
		end
	end
end

function module.map_info(module_map)
	love.graphics.setColor(255, 255, 255)
	map = module_map.map
	blockleft = math.round((xoffsetcam - cubesize)/ cubesize)
	nbxtile = math.floor(screen_width/cubesize) + 1
	for i = blockleft, blockleft + nbxtile do
		xcur = cubesize * (i - xoffsetcam / cubesize)
		for j = 0, 18 do
			ycur = screen_height - cubesize * (j + 1) 
			if map[i] ~= nil and map[i][j] ~= nil then
				love.graphics.print(string.sub(module_map.tile_type(map[i][j]),1,1), xcur+5, ycur+5)
			end
		end
	end
end

function module.entity_info(entity_manager)
	love.graphics.setColor(255, 255, 255)
	count = 0
	for i = 0, entity_manager.nb_entity - 1 do
		entity = entity_manager.list_entity[i]
		x = entity['x'] - xoffsetcam
		y = entity['y']
		entity_type = entity['type']
		if entity_type ~= "DEAD" then
			if x > 0 and x < screen_width then
				love.graphics.print(i..", "..math.floor(x)..", "..math.floor(y)..", "..entity_type, 500, 13 + count * 20)
				count = count + 1
			end
		end
	end
end

function module.render_grid(module_map)
	love.graphics.setColor(0, 0, 0)
	blockleft = math.round((xoffsetcam - cubesize)/ cubesize)
	nbxtile = math.floor(screen_width/cubesize) + 1
	for i = blockleft, blockleft + nbxtile do
		xcur = cubesize * (i - xoffsetcam / cubesize)
		love.graphics.line(xcur, 0, xcur, screen_height)
	end
	for j = 0, 18 do
		ycur = screen_height - cubesize * (j + 1) 
		love.graphics.line(0, ycur, screen_width, ycur)
	end
end


-- MODULE END
return module

  
