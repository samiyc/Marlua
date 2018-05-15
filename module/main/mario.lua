
-- VARIABLES
local module = {
	x = 0,
	y = 0,
	w = cubesize - 10,
	h = cubesize - 10,
	xacc = 0,
	yacc = 0,
	max_xacc = 500,
	max_yacc = -1000,
	angle_col = -1,
	cx = 0,
	cy = 0,
	
	current_frame = 0,
	time_frame = 0,
	statut = "WALK",
	
	col_ground = false,
	big = false,
	big_timer = 0,
	protection_timer = 0,
}

-- FONCTIONS 
function module.load(map)
	if map.flag then
		module.x = map.flagx
		module.y = map.flagy
	else
		module.x = map.xstart * cubesize
		module.y = map.ystart * cubesize
	end
	module.xacc = 0
	module.yacc = 0
end

-- Animation
function module.update_frame(entity_manager, dt)
	--protection
	if module.protection_timer > 0 then
		module.protection_timer = module.protection_timer - dt
		if module.protection_timer < 0 then module.protection_timer = 0 end
	end
	--transform
	if module.big_timer > 0 then
		module.big_timer = module.big_timer - dt
		if module.big_timer < 0 then module.big_timer = 0 end
	end
	--update statut
	if module.xacc > -10 and module.xacc < 10 then
		if module.statut ~= "IDLE" then module.switch_to_statut("IDLE") end
	else
		if module.statut ~= "WALK" then module.switch_to_statut("WALK") end
	end
	--update frame
	module.time_frame = module.time_frame + dt
	if module.time_frame > 0.1 then
		module.time_frame = 0
		module.current_frame = module.current_frame + 1
		entity_type = entity_manager.get_entity_type(module.entity_type_name())
		et_statut   = entity_manager.get_entity_type_statut(entity_type, module.statut)
		frames = et_statut['frames']
		if frames[module.current_frame] == nil then module.current_frame = 0 end
	end
end
function module.switch_to_statut(statut)
	module.statut = statut
	module.current_frame = 0
	module.time_frame = 0
end
function module.entity_type_name()
	var = "MARIO"
	transformation = true
	if module.big_timer > 0 then
		if math.floor(module.big_timer * 10) % 2 == 0 then
			transformation = false
		end
	end
	if module.big and transformation then var = "BIG_"..var end
	return var
end


-- MODULE END
return module