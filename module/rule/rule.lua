
max_xacc = 400
fast = 2000
slow = 800
frot = 900
low_frot = 200

max_yacc = -1000
gravity = 800
jump = 470
drop = 1500
xoffsetcam = 0

-- VARIABLES
local module = {
	x = 10,
	y = 10,
	x_acc_speed = fast,
	frotement = frot,
}

function module.load(map)
	if map.ice_level then
		module.x_acc_speed = slow
		module.frotement = low_frot
	else
		module.x_acc_speed = fast
		module.frotement = frot
	end
end

-- UPDATE
function module.update(screen, map, mario, entity_manager, dt)
	
	-- Save the position in case of colision
	oldmx = mario.x
	oldmy = mario.y
	
	-- Update la position avec l'accel
	mario.x = mario.x + mario.xacc * dt
	if module.col_mario_caisse(mario, entity_manager) or module.col_mario_map(screen, map, mario) then
		mario.xacc = 0.5 * mario.xacc
		mario.x = oldmx
	end
	mario.col_ground = false
	mario.y = mario.y + mario.yacc * dt
	if module.col_mario_caisse(mario, entity_manager) or module.col_mario_map(screen, map, mario) then
		if mario.yacc < 0 then mario.col_ground = true end
		mario.yacc = 0.5 * mario.yacc
		mario.y = oldmy
	end
	
	-- Frotement horizontal
	if mario.xacc > 10 then
		mario.xacc = mario.xacc - module.frotement * dt
	elseif mario.xacc < -10 then
		mario.xacc = mario.xacc + module.frotement * dt
	else
		mario.xacc = 0
	end
	
	-- Falling gravity
	if mario.yacc > max_yacc then mario.yacc = mario.yacc - gravity * dt
	else mario.yacc = max_yacc end
	
	-- Limit bord gauche
	if mario.x-xoffsetcam < 5 then 
		mario.xacc = 0
		mario.x = xoffsetcam + 5
	end
	
	-- Mort par chute
	if mario.y < - cubesize - mario.h then
		mario.big = false
		game_statut = "DEATH_FRAME"
		vie = vie - 1
	end
end

-- Colision with map
function module.col_mario_map(screen, module_map, mario)
	map = module_map.map	
	blockleft = math.round((xoffsetcam - cubesize)/ cubesize)
	nbxtile = math.floor(screen_width/cubesize) + 1
	for i = blockleft, blockleft + nbxtile do
		xcur = cubesize * (i - xoffsetcam / cubesize)
		for j = 0, 18 do
			ycur = screen_height - cubesize * (j + 1)
			if map[i] ~= nil then
				if module_map.tile_type(map[i][j]) == "GROUND" then
					if check_collision_mario_box(mario, xcur, ycur) then
						--mario.cx = xcur
						--mario.cy = ycur
						return true
					end
				end
			end
		end
	end
	return false
end

-- Colision with caisse
function module.col_mario_caisse(mario, em)
	for i = 0, em.nb_entity - 1 do
		entity = em.list_entity[i]
		if entity['statut'] ~= "DEAD" and walkable_entity(entity['type']) then
			x = entity['x'] - xoffsetcam
			y = screen_height - entity['y']
			if x > -cubesize and x < screen_width then
				if not string.find("U_SPIKE,D_SPIKE", entity['type']) then
					if check_collision_mario_box(mario, x, y) then
						--if entity['type'] == "INSTABLE" then
							--if entity['statut'] == "IDLE" then
								--entity['statut'] = "WALK"
								--entity['DROP_ANIMATION'] = 2
							--end
						--end
						if hitable_entity(entity['type']) then
							entity['HIT'] = true
						end
						if up_hitable_entity(entity['type']) and mario.yacc > 100 then
							if check_collision_mario(mario, x+5, y + (cubesize/2), cubesize-10, cubesize/2) then
								entity['HIT'] = true
							end
						end
						return true
					end
				else
					var = 0
					if entity['type'] == "U_SPIKE" then var = 1 end
					if check_collision_mario(mario, x, y + (cubesize/2) * var, cubesize, cubesize/2) then
						return true
					end
				end
			end
		end
	end
	return false
end

-- DIRECTION HORIZONTAL
function module.left_key(screen, map, mario, entity, dt)
	if mario.xacc > -max_xacc/2 then
		mario.xacc = mario.xacc - module.x_acc_speed * dt
	else
		mario.xacc = mario.xacc - module.x_acc_speed / 2 * dt
	end
	if mario.xacc < -max_xacc then mario.xacc = -max_xacc end
end
function module.right_key(screen, map, mario, entity, dt)
	if mario.xacc < max_xacc/2 then
		mario.xacc = mario.xacc + module.x_acc_speed * dt
	else
		mario.xacc = mario.xacc + module.x_acc_speed / 2 * dt
	end
	if mario.xacc > max_xacc then mario.xacc = max_xacc end
end

-- DIRECTION VERTICAL
function module.up_key(screen, map, mario, entity, dt)
	if mario.col_ground then
		mario.yacc = jump
	end
end
function module.down_key(screen, map, mario, entity, dt)
	mario.yacc = mario.yacc - drop * dt
end



-- MODULE END
return module