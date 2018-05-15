
-- STATUTS : IDLE, CROUCH, WALK

entity_speed = 50
turtle_speed = 150
entity_gravity = 200
kill_rebond = 250

-- VARIABLES
local module = {
	list_entity_type = {},
	nb_entity_type = 0,
	list_entity = {},
	nb_entity = 0,
	inc_animation = 0,
	old_color = "B",
}

-- INITIALISATION
function module.load(cfg)
	module.nb_entity_type = 0
	module.nb_entity = 0
	module.inc_animation = 0
	
	log("## INITIALISATION DES ENTITY")
	for line in love.filesystem.lines("entity_info.txt") do
		words = split_words(line)
		if words[0] ~= nil and suported_entity(words[0]) then
			entity_name = words[0]
			statut_name = words[1]
			starting_index = tonumber(words[2])
			amount         = tonumber(words[3])
			tileset_name   = words[4]
			x = tonumber(words[5])
			y = tonumber(words[6])
			
			-- Entity_type
			entity_type = module.get_entity_type(entity_name)
			if entity_type == nil then entity_type = module.add_entity_type(entity_name) end
			
			-- Statut
			statut = module.get_entity_type_statut(entity_type, statut_name)
			if statut == nil then statut = module.add_entity_type_statut(entity_type, statut_name, tileset_name) end
			
			-- Chargement des quad depuis le tileset
			module.load_quad_from_tileset(cfg, statut, starting_index, amount, tileset_name, x, y)

			log(entity_name.."."..statut_name.."."..starting_index..": Ajout de "..amount.." tile(s) depuis le tileset:"..tileset_name.." tile_x:"..x.." tile_y:"..y)
		end
	end
end

-- Récupération des entité présentes dans la map
function module.add_entity(entity_type, px, py)
	if entity_type == "CARNV_PLANT" then module.init_plant_carnv(px, py) end
	if suported_entity(entity_type) then
		entity = {}
		entity['type'] = entity_type
		entity['x'] = px
		entity['y'] = py
		entity['statut'] = module.default_statut(entity_type)
		entity['direction'] = module.default_orientation(entity_type)
		if entity_type == "CARNV_PLANT" then entity['direction'] = "DROITE" end
		entity['fly'] = "YES"
		entity['current_frame'] = 0
		entity['time_frame'] = 0
		module.list_entity[module.nb_entity] = entity
		module.nb_entity = module.nb_entity + 1
	end
end
function module.default_orientation(entity_type)
	if string.find(entity_type, "ENEMIE") then return "GAUCHE" end
	return "DROITE"
end
function module.default_statut(entity_type)
	if string.find(entity_type, "ENEMIE") then return "WALK" end
	return "IDLE"
end
function module.init_plant_carnv(px, py)
	module.add_entity("CARNV_PLANT_T", px, py)
	module.add_entity("CARNV_PLANT_H", px, py)
end

---------------------------------------------------

-- ENTITY TYPE / ANIMATION
function module.get_entity_type(name)
	for i = 0, module.nb_entity_type - 1 do
		entity_type = module.list_entity_type[i]
		if entity_type['name'] == name then
			return entity_type
		end
	end
	return nil
end
function module.add_entity_type(entity_name)
	entity = {}
	entity['name'] = entity_name
	entity['list_statut'] = {}
	entity['nb_statut'] = 0
	module.list_entity_type[module.nb_entity_type] = entity
	module.nb_entity_type = module.nb_entity_type + 1
	return entity
end
-- STATUT
function module.get_entity_type_statut(entity_type, S_name)
	for i = 0, entity_type['nb_statut'] - 1 do
		list_statut = entity_type['list_statut']
		statut = list_statut[i]
		if statut['name'] == S_name then
			return statut
		end
	end
	return nil
end
function module.add_entity_type_statut(entity, statut_name, tileset_name)
	statut = {}
	statut['name'] = statut_name
	statut['tileset_name'] = tileset_name
	statut['frames'] = {}
	list_statut = entity['list_statut']
	list_statut[entity['nb_statut']] = statut
	entity['nb_statut'] = entity['nb_statut'] + 1
	return statut
end
function module.next_frame(entity, statut)
	entity['current_frame'] = entity['current_frame'] + 1
	frames = statut['frames']
	if frames[entity['current_frame']] == nil then entity['current_frame'] = 0 end
end
function module.switch_to_statut(entity, statut)
	entity['statut'] = statut
	entity['current_frame'] = 0
	entity['time_frame'] = 0
end
-- QUAD
function module.load_quad_from_tileset(cfg, statut, starting_index, amount, tileset, x, y)
	frame_tab = statut['frames']
	for i = 0, amount - 1 do
		frame_tab[starting_index + i] = cfg.get_tile_quad(tileset, x + i, y)
	end
end

---------------------------------------------------

-- UPDATE
function module.update(mario, map, dt)
	module.inc_animation = module.inc_animation + dt
	for i = 0, module.nb_entity - 1 do
		e = module.list_entity[i]
		ex = e['x'] - xoffsetcam
		s = e['statut']
		if ex > -2 * cubesize and ex < screen_width + 5 * cubesize and s ~= "DEAD" then
			t = e['type']
			ey = screen_height - e['y']
			--Gestion des entity, one by one
			module.gestion_animation(e, dt)
			module.gestion_col_mario(mario, e, t, ex, ey, map)
			if moving_entity(t) then module.gestion_mov_entity(map, e, t, s, ex, ey, dt) end
			module.gestion_instable(e, t, s, dt)
			module.gestion_note(e, t, s)
			module.gestion_gift_box(e, map)
		end
	end
	module.gestion_color_box(mario)
	module.gestion_plant_carnv()
end

---------------------------------------------------

-- GESTION ANIMATION
function module.gestion_animation(entity, dt)
	entity['time_frame'] = entity['time_frame'] + dt
	if entity['time_frame'] > 0.1 then
		entity['time_frame'] = 0
		entity_type = module.get_entity_type(entity['type'])
		et_statut   = module.get_entity_type_statut(entity_type, entity['statut'])
		if et_statut ~= nil then module.next_frame(entity, et_statut) end
	end
end

---------------------------------------------------

-- Colision between mario and entity
function module.gestion_col_mario(mario, entity, entity_type, x, y, map)
	w = cubesize
	h = cubesize
	
	-- hitbox adjustement
	if small_entity(entity_type) then
		x = x + enemi_hitbox_offset_x
		y = y + enemi_hitbox_offset_y
		w = w + enemi_hitbox_ajust_w
		h = h + enemi_hitbox_ajust_h
	end
	if check_collision_mario(mario, x, y, w, h) then
		if entity_type == "ENEMIE1"  then module.col_with_enemi_1(mario, entity) end
		if entity_type == "ENEMIE3"  then module.col_with_enemi_3(mario, entity) end
		if entity_type == "ENEMIE2"  then mario_death(mario) end
		if entity_type == "U_SPIKE"  then mario_death(mario) end
		if entity_type == "D_SPIKE"  then mario_death(mario) end
		if entity_type == "GOLD"     then module.col_with_gold(mario, entity) end
		if entity_type == "FLAG"     then module.col_with_flag(mario, entity, map) end
		if entity_type == "CHAMP"    then module.col_with_champ(mario, entity) end
		if entity_type == "CARNV_PLANT_H" then mario_death(mario) end
		if entity_type == "LAVA"     then module.col_with_lava(mario, entity) end
	end
end
function module.col_with_enemi_1(m, e)
	if module.kill_or_death(m, e) then
		e['statut'] = "DEAD"
		score = score + 10
		m.yacc = kill_rebond
	else
		mario_death(m)
	end
end
function module.col_with_enemi_3(m, e)
	if e['statut'] ~= "CROUCH" then
		if module.kill_or_death(m, e) then
			score = score + 5
			module.switch_to_statut(e, "CROUCH")
			e['TURTLE_CROUCH_TIMER'] = 6
			if m.xacc < -10 then e['direction'] = "GAUCHE" end
			if m.xacc > 10  then e['direction'] = "DROITE" end
			m.yacc = kill_rebond
		else
			mario_death(m)
		end
	else
		if module.kill_or_death(m, e) then
			if m.xacc < -10 then e['direction'] = "GAUCHE" end
			if m.xacc > 10  then e['direction'] = "DROITE" end
			m.yacc = kill_rebond
		else
			mario_death(m)
		end
	end
end
function module.col_with_gold(m, e)
	coin = coin + 1
	e['statut'] = "DEAD"
end
function module.col_with_flag(m, e, map)
	e['statut'] = "DEAD"
	map.flag = true
	map.flagx = e['x']
	map.flagy = e['y']
end
function module.col_with_champ(m, e)
	e['statut'] = "DEAD"
	if not m.big then
		m.big = true
		m.big_timer = 0.8
	else
		vie = vie + 1 
	end
end
function module.col_with_lava(m, e)
	if not (e['y'] - m.y < cubesize / 2) then
		mario_death(m)
	end
end
function module.kill_or_death(m, e)
	ey = e['y'] - enemi_hitbox_offset_y
	h = cubesize + enemi_hitbox_ajust_h
	return (ey - m.y < h / 2) or m.yacc < -200
end

---------------------------------------------------

-- DEPLACEMENT DES ENTITE
function module.gestion_mov_entity(map, entity, t, s, x, y, dt)
	oldx = entity['x']
	oldy = entity['y']
	
	--move
	direction = -1
	if entity['direction'] == "DROITE" then	direction = 1 end
	entity['x'] = entity['x'] + module.entity_speed(entity) * dt * direction
	if module.col_entity_map(entity, map) or module.col_entity_caisse(entity) then
		entity['x'] = oldx
		if entity['direction'] == "GAUCHE" then	entity['direction'] = "DROITE"
		else entity['direction'] = "GAUCHE"	end
	end
	--gravity
	if module.col_entity_map(entity, map) or module.col_entity_caisse(entity) then
		entity['y'] = oldy + 1
		entity['fly'] = "NO"
	else
		entity['y'] = entity['y'] - entity_gravity * dt
		if module.col_entity_map(entity, map) or module.col_entity_caisse(entity) then
			entity['y'] = oldy
			entity['fly'] = "NO"
		end
	end
	if entity['y'] < 0 then entity['statut'] = "DEAD" end
	
	--rebord
	if entity['fly'] == "NO" then
		if (t == "ENEMIE3" and s == "CROUCH") or t == "CHAMP" then
			--low turtle don't see border
		else
			oldx = entity['x']
			oldy = entity['y']
			direction = -1
			if entity['direction'] == "DROITE" then	direction = 1 end
			entity['x'] = entity['x'] + cubesize * direction
			entity['y'] = entity['y'] - cubesize - 10
			if not (module.col_entity_map(entity, map) or module.col_entity_caisse(entity)) then
				if entity['direction'] == "GAUCHE" then	entity['direction'] = "DROITE"
				else entity['direction'] = "GAUCHE"	end
			end
			entity['x'] = oldx
			entity['y'] = oldy
		end
	end
	
	--col with turtle
	if entity['statut'] == "CROUCH" and entity['type'] == "ENEMIE3" then
		--no interaction between low turtle
		--timer
		entity['TURTLE_CROUCH_TIMER'] = entity['TURTLE_CROUCH_TIMER'] - dt
		if entity['TURTLE_CROUCH_TIMER'] < 0 then module.switch_to_statut(entity, "WALK") end 
	else
		if module.col_entity_turtle(entity) then
			entity['statut'] = "DEAD"
			if entity['type'] == "ENEMIE1" then score = score + 10 end
			if entity['type'] == "ENEMIE2" then score = score + 30 end
			if entity['type'] == "ENEMIE3" then score = score + 10 end
		end
	end
	
	--lava
	if module.col_entity_lava(entity) then
		entity['statut'] = "DEAD"
	end
end
--speed
function module.entity_speed(e)
	if (e['statut'] == "CROUCH" and e['type'] == "ENEMIE3") or e['type'] == "CHAMP" then
		return turtle_speed
	end
	return entity_speed
end
-- Colision with map
function module.col_entity_map(cm_entity, module_map)
	map = module_map.map	
	x = cm_entity['x'] - xoffsetcam
	y = screen_height - cm_entity['y']
	blockleft = math.round((xoffsetcam - 10 * cubesize)/ cubesize)
	nbxtile = math.floor(screen_width/cubesize) + 20
	for i = blockleft, blockleft + nbxtile do
		xcur = cubesize * (i - xoffsetcam / cubesize)
		for j = 0, 18 do
			ycur = screen_height - cubesize * (j + 1)
			if map[i] ~= nil and map[i][j] ~= nil then
				if module_map.tile_type(map[i][j]) == "GROUND" then
					if check_collision(x, y, cubesize, cubesize-1, xcur, ycur, cubesize-5, cubesize-5) then
						return true
					end
				end
			end
		end
	end
	return false
end
-- Colision with caisse
function module.col_entity_caisse(cc_entity)
	x1 = cc_entity['x'] - xoffsetcam
	y1 = screen_height - cc_entity['y']
	for i = 0, module.nb_entity - 1 do
		nentity = module.list_entity[i]
		if nentity['statut'] ~= "DEAD" and walkable_entity(nentity['type']) then
			x2 = nentity['x'] - xoffsetcam
			y2 = screen_height - nentity['y']
			if x2 > -10 * cubesize and x2 < screen_width + 10*cubesize then
				if check_collision(x1, y1, cubesize, cubesize-1, x2, y2, cubesize-5, cubesize-5) then
					return true
				end
			end
		end
	end
	return false
end
-- Colision with turtle
function module.col_entity_turtle(cc_entity)
	x1 = cc_entity['x'] - xoffsetcam
	y1 = screen_height - cc_entity['y']
	for i = 0, module.nb_entity - 1 do
		nentity = module.list_entity[i]
		if nentity['statut'] == "CROUCH" and nentity['type'] == "ENEMIE3" then
			x2 = nentity['x'] - xoffsetcam
			y2 = screen_height - nentity['y']
			if x2 > -2 * cubesize and x2 < screen_width + 5 * cubesize then
				-- hitbox adjustement
				x1 = x1 + enemi_hitbox_offset_x
				y1 = y1 + enemi_hitbox_offset_y
				w1 = cubesize + enemi_hitbox_ajust_w
				h1 = cubesize + enemi_hitbox_ajust_h
				-- hitbox adjustement
				y2 = y2 + cubesize / 2
				w2 = cubesize
				h2 = cubesize / 2
			
				if check_collision(x1, y1, w1, h1, x2, y2, w2, h2) then
					return true
				end
			end
		end
	end
	return false
end
-- Colision with lava
function module.col_entity_lava(cc_entity)
	x1 = cc_entity['x'] - xoffsetcam
	y1 = screen_height - cc_entity['y']
	for i = 0, module.nb_entity - 1 do
		nentity = module.list_entity[i]
		if nentity['type'] == "LAVA" then
			x2 = nentity['x'] - xoffsetcam
			y2 = screen_height - nentity['y']
			if x2 > -2 * cubesize and x2 < screen_width + 5 * cubesize then
				-- hitbox adjustement
				x1 = x1 + enemi_hitbox_offset_x
				y1 = y1 + enemi_hitbox_offset_y
				w1 = cubesize + enemi_hitbox_ajust_w
				h1 = cubesize + enemi_hitbox_ajust_h
				-- hitbox adjustement
				x2 = x2 + enemi_hitbox_offset_x
				y2 = y2 + enemi_hitbox_offset_y
				w2 = cubesize + enemi_hitbox_ajust_w
				h2 = cubesize + enemi_hitbox_ajust_h
			
				if check_collision(x1, y1, w1, h1, x2, y2, w2, h2) then
					return true
				end
			end
		end
	end
	return false
end

---------------------------------------------------

function module.gestion_instable(e, t, s, dt)
	if t == "INSTABLE" then
		if s == "IDLE" and e['HIT'] then
			e['statut'] = "WALK"
			e['DROP_ANIMATION'] = 2
		end
		if s == "WALK" then
			if e['DROP_ANIMATION'] > 0 then
				e['DROP_ANIMATION'] = e['DROP_ANIMATION'] - dt
			else
				e['statut'] = "DEAD"
			end
		end
	end
end
function module.gestion_note(e, t, s)
	if t == "NOTE" then
		if s == "IDLE" and e['HIT'] then
			e['statut'] = "WALK"
		end
	end
end
function module.gestion_gift_box(e, map)
	if e['type'] == "COIN_BOX" and e['HIT'] then
		e['type'] = default_caisse(map)
		e['current_frame'] = 0
		e['time_frame'] = 0
		module.add_entity("GOLD", e['x'], e['y']+cubesize)
		gold = module.list_entity[module.nb_entity - 1]
		gold['YACC'] = 161
	end
	if e['type'] == "GOLD" and e['YACC'] ~= nil and e['YACC'] >= 0 then
		e['y'] = e['y'] + e['YACC'] * 0.0166
		e['YACC'] = e['YACC'] - 5
		if e['YACC'] < 0 then e['YACC'] = nil end
	end
	if e['type'] == "CHMP_BOX" and e['HIT'] then
		e['type'] = default_caisse(map)
		e['current_frame'] = 0
		e['time_frame'] = 0
		module.add_entity("CHAMP", e['x'], e['y']+cubesize+1)
		champ = module.list_entity[module.nb_entity - 1]
		champ['statut'] = "WALK"
		champ['direction'] = "DROITE"
	end
end
function default_caisse(map)
	if map.ice_level then
		return "BLU_CAISSE"
	end
	return "CAISSE"
end

function module.gestion_color_box(mario)
	num_color = math.floor(module.inc_animation/2) % 4
	ncolor = module.get_color_box(num_color)
	if ncolor ~= module.old_color then
		for i = 0, module.nb_entity - 1 do
			e = module.list_entity[i]
			x = e['x'] - xoffsetcam
			if x > -cubesize and x < screen_width then
				if e['type'] == module.old_color.."_BOX" then
					e['type'] = module.old_color.."_CBOX"
				end
				if e['type'] == ncolor.."_CBOX" then
					y = screen_height - e['y']
					if not check_collision_mario_box(mario, x, y) then
						e['type'] = ncolor.."_BOX"
					end
				end
			end
		end
		module.old_color = ncolor
	end
end
function module.get_color_box(n)
	if n == 0 then return "Y" end
	if n == 1 then return "G" end
	if n == 2 then return "R" end
	return "B"
end

function module.gestion_plant_carnv()
	n = module.inc_animation*3 % 20
	if (0 <= n and n <= 5) or (10 <= n and n <= 15) then 
		for i = 0, module.nb_entity - 1 do
			e = module.list_entity[i]
			x = e['x'] - xoffsetcam
			if x > -cubesize and x < screen_width and e['type'] == "CARNV_PLANT" then
				t = module.list_entity[i-2]
				h = module.list_entity[i-1]
				if n < 8 then
					if n > 2.5 then t['y'] = e['y'] + cubesize * (n-2.5)/2.5 end
					h['y'] = e['y'] + cubesize * 2 * n/5
				else
					if n < 12.5 then
						t['y'] = e['y'] + cubesize * (12.5-n)/2.5
					else	
						t['y'] = e['y']
					end
					h['y'] = e['y'] + cubesize * 2 * (15-n)/5
				end
			end
		end
	end
end


-- MODULE END
return module