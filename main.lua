

-- VARIABLE GLOBAL
--cubesize = 32 old
cubesize = 45
screen_width  = 800
screen_height = 600
old_game_statut = "MENU"
game_statut = "MENU"
xoffsetcam = 0
menu_pos = 0

-- def stat
vie_base = 10
timer_base = 60*6

-- Stat
score = 0
coin = 0
vie = vie_base
timer = timer_base

-- TEST
nb_tile_disp = 0
nb_tile_background_disp = 0
nb_tile_fa_disp = 0
nb_entity_disp = 0

-- Fps
fps = 0
fps_tick = 0
fps_var = 0

-- HIT BOX
enemi_hitbox_offset_x = 10
enemi_hitbox_offset_y = 20
enemi_hitbox_ajust_w = -20
enemi_hitbox_ajust_h = -20


-- MODULES
require "module.main.tool"
local cfg    = require "module.main.cfg"
local map    = require "module.main.map"
local mario  = require "module.main.mario"
local rule   = require "module.rule.rule"
local screen = require "module.interface.screen"
local entity_manager = require "module.rule.entity_manager"

--local sprite = require "module.interface.sprite"
--local brain  = require "module.brain.brain"


-- INITIALISATION
function love.load()
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setBackgroundColor(0,0,0)
	love.graphics.print("LOADING...", 10, 10)
	
	-- Log
	love.filesystem.remove("log.txt")
	log("Lancement du jeux")
	
	-- Lecture du fichier de config
	cfg.load()
	entity_manager.load(cfg)
end

-- AFFICHAGE
function love.draw()
	if game_statut == "MENU" then
		love.graphics.setColor(0.2, 0.2, 0.2)
		love.graphics.rectangle("fill", 0, math.floor(menu_pos)*20+30, 200, 20)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("> Utiliser les fleches et la touche Entree. Echap -> Retour au menu", 10, 13)
		cfg.draw_map_list()
		--love.graphics.print("MAP 1", 10, 33)
	elseif game_statut == "DEATH_FRAME" then
	elseif game_statut == "LOAD_MAP" then
		love.graphics.print("Chargement...", 10, 13)
	elseif game_statut == "WIN" or game_statut == "LOSE" then
		love.graphics.print("--- YOU "..game_statut.." !! ---", 10, 13)
		love.graphics.print("Nombre de vie restantes:"..vie.."  ("..vie_base.." de base)", 10, 33)
		love.graphics.print("Nombre de pieces:"..coin, 10, 53)
		love.graphics.print("Temps restant:"..display_time(timer).."  ("..display_time(map.timer).." de base)", 10, 73)
		love.graphics.print("Score:"..score, 10, 93)
		love.graphics.print("SCORE TOTAL:"..calc_score_total(), 10, 113)
		love.graphics.print("Entree -> Continuer", 10, 153)
		love.graphics.print("Echape -> Menu", 10, 173)
	else
		screen.render(cfg, map, mario, entity_manager)
		love.graphics.setColor(1, 1, 1, 0.3)
		love.graphics.rectangle("fill", 0, 0, 320, 40)
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.print("fps:"..fps.." tile:"..nb_tile_disp..","..nb_tile_background_disp..","..nb_tile_fa_disp.." entity:"..nb_entity_disp.."/"..entity_manager.nb_entity.." rule:"..rule.x_acc_speed..","..rule.frotement, 10, 3)
		love.graphics.print("Timer:"..display_time(timer).." - Vie:"..vie.." - Pieces:"..coin.." - Score:"..score, 10, 23)
		love.graphics.setColor(1, 1, 1, 1)
	end
end

-- UPDATE / TIME
function love.update(dt)
	-- nothing if fps < 10
	if dt < 0.1 then
		-- Fps calc
		fps_var = fps_var + dt
		fps_tick = fps_tick + 1
		if fps_tick >= 20 then
			fps_var = fps_var / 20
			fps = math.floor(1/fps_var)
			fps_tick = 0
			fps_var = 0
		end
		
		-- MENU
		if game_statut == "MENU" then
			speed = 15*dt
			if love.keyboard.isDown("up") and menu_pos > speed then menu_pos = menu_pos - speed end
			if love.keyboard.isDown("down") and menu_pos < cfg.nb_map-speed then menu_pos = menu_pos + speed end
			if love.keyboard.isDown("return") then
				change_game_statut("LOAD_MAP")
			end
		
		-- LOAD MAP
		elseif game_statut == "LOAD_MAP" then
			if old_game_statut == "MENU" then
				cfg.select_map(math.floor(menu_pos))
				map.load(cfg, entity_manager, false)
				rule.load(map)--ice friction
			elseif old_game_statut == "WIN-LOSE" then
				map.load(cfg, entity_manager, true)
			end
			reset_map(mario, map)
			change_game_statut("GAME")
		
		-- DEATH
		elseif game_statut == "DEATH" then
			mario.load(map)
			xoffsetcam = 0
			if vie < 1 then
				change_game_statut("LOSE")
				win_lose_log("LOSE. 0 LIFE", map)
			else
				change_game_statut("GAME")
			end
		elseif game_statut == "DEATH_FRAME" then
			change_game_statut("DEATH")
			love.graphics.setBackgroundColor(0, 0, 0)
		
		-- WIN / LOSE
		elseif game_statut == "WIN" or game_statut == "LOSE" then
			if love.keyboard.isDown("return") and (game_statut == "WIN" or game_statut == "LOSE") then
				change_game_statut("LOAD_MAP")
				old_game_statut = "WIN-LOSE"
			end
		
		-- IN GAME
		else 
			--timer
			if not cfg.test then timer = timer - dt end
			if timer < 1 then
				timer = 0
				change_game_statut("LOSE")
				win_lose_log("LOSE. END OF TIMER", map)
			end
			--keyboard
			if love.keyboard.isDown("left")  then rule.left_key(screen, map, mario, entity, dt) end
			if love.keyboard.isDown("right") then rule.right_key(screen, map, mario, entity, dt) end
			if love.keyboard.isDown("up")    then rule.up_key(screen, map, mario, entity, dt) end
			if love.keyboard.isDown("down")  then rule.down_key(screen, map, mario, entity, dt) end
			--class update
			if not cfg.test then entity_manager.update(mario, map, dt) end
			mario.update_frame(entity_manager, dt)
			rule.update(screen, map, mario, entity_manager, dt)
			screen.update(mario, dt)
			--end of map
			if mario.x > map.end_of_map then
				change_game_statut("WIN")
				win_lose_log("WIN", map)
			end
		end
	end
end

-- ACTION DE LA SOURIE
function love.mousepressed(x, y, button)
end
function love.mousereleased(x, y, button)
end

-- ACTION CLAVIER
function love.keypressed(key)
	if key == "escape" then
		if game_statut == "MENU" then
			love.event.quit()
		else
			change_game_statut("MENU")
		end
	end
end
function love.keyreleased(key)
	if key == "0" then
		map.load(cfg, entity_manager, false)
	end
end

-- QUIT
function love.quit()
	log("## FERMETURE DU JEUX")
end

