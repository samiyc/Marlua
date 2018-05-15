
-- Returns the distance between two points.
function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end

-- Returns 'n' rounded to the nearest 'deci'th (defaulting whole numbers).
function math.round(n, deci) deci = 10^(deci or 0) return math.floor(n*deci+.5)/deci end

-- Returns words of a sentence in a table
function split_words(txt)
	tableau = {}
	count = 0
	for word in string.gmatch(txt, "%S+") do
		tableau[count] = word
		count = count + 1
	end
	return tableau
end

-- Yes / no
function yesno(bool)
	if bool then return "Yes" end
	return "No"
end

--increment
function inc(var)
	var = var + 1
end

-------------------------------------------

-- collistion for mario
function check_collision_mario_box(m, x, y)
  return check_collision(m.x-xoffsetcam, screen_height-(m.y+m.h), m.w, m.h, x, y, cubesize, cubesize)
end

-- collistion for mario
function check_collision_mario(m, x, y, w, h)
  return check_collision(m.x-xoffsetcam, screen_height-(m.y+m.h), m.w, m.h, x, y, w, h)
end

-- Collision detection function.
-- Returns true if two boxes overlap, false if they don't
-- x1,y1 are the left-top coords of the first box, while w1,h1 are its width and height
-- x2,y2,w2 & h2 are the same, but for the second box
function check_collision(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 <= x2+w2 and
         x2 <= x1+w1 and
         y1 <= y2+h2 and
         y2 <= y1+h1
end

-- angle bettween tow quad
function angle_mario_quad(mario, x2,y2,w2,h2)
	return angle_quad_quad(mario.x-xoffsetcam,screen_height-(mario.y+mario.h),mario.w,mario.h, x2,y2,w2,h2) * 180 / math.pi
end

-- angle bettween tow quad
function angle_quad_quad(x1,y1,w1,h1, x2,y2,w2,h2)
	cx1 = x1 + w1 / 2
	cy1 = y1 + h1 / 2
	cx2 = x2 + w2 / 2
	cy2 = y2 + h2 / 2
	return math.atan2 ( cy1 - cy2, cx2 - cx1) 
end

-------------------------------------------

function change_game_statut(ngs)
	old_game_statut = game_statut
	game_statut = ngs
	log("## NEW GAME_STATUT : "..ngs)
end
function reset_map(mario, map)
	mario.load(map)
	mario.big = false
	xoffsetcam = 0
	timer = map.timer
	vie = vie_base
	score = 0
	coin = 0
end
function mario_death(m)
	if m.big then
		m.big = false
		m.protection_timer = 2
	elseif m.protection_timer > 0 then
		--mario est protegé
	elseif game_statut == "DEATH_FRAME" then
		--deja mort
	else
		game_statut = "DEATH_FRAME"
		love.graphics.setBackgroundColor(169, 204, 251)
		vie = vie - 1
	end
end

-------------------------------------------

-- Tileset fonctions
function get_tile_quad_from_tileset(tileset, ts, g, tx, ty)
	tileset_w = tileset:getWidth()
	tileset_h = tileset:getHeight()
	--quad = love.graphics.newQuad((tx-1)*ts+tx, (ty-1)*ts+ty, ts, ts, tileset_w, tileset_h)
	quad = love.graphics.newQuad((tx-1)*ts+tx*g, (ty-1)*ts+ty*g, ts, ts, tileset_w, tileset_h)
	return quad
end
function remove_tileset_background(img, path, br, bg, bb)
	img_data = love.image.newImageData(path)
	function r_back( x, y, r, g, b, a )
		if (clr_255(r) == br and clr_255(g) == bg and clr_255(b) == bb) then
			a = 0
		end
		return r,g,b,a
	end
	img_data:mapPixel(r_back)
	img:replacePixels(img_data)
end
function away_fx_image(img, path, br,bg,bb, tr,tv,tb, layer)
	img_data = love.image.newImageData(path)
	function rback_brighten( x, y, r, g, b, a )
		if (clr_255(r) == br and clr_255(g) == bg and clr_255(b) == bb) then
			a = 0
		else
			r = clr_01((clr_255(r) + tr * layer) / (layer + 1))
			g = clr_01((clr_255(g) + tv * layer) / (layer + 1))
			b = clr_01((clr_255(b) + tb * layer) / (layer + 1))
		end
		return r,g,b,a
	end
	img_data:mapPixel(rback_brighten)
	img:replacePixels(img_data)
end
function clr_255(color)
	return math.floor(color*255)
end
function clr_01(color)
	return color / 255
end

-------------------------------------------

function log(text)
	love.filesystem.append("log.txt", os.date("%d/%m/%y %H:%M:%S").." - "..text.."\r\n")
end

function win_lose_log(text, map)
	log("## "..text)
	log("Nombre de vie restantes:"..vie.."  ("..vie_base.." de base)")
	log("Nombre de pieces:"..coin)
	log("Temps restant:"..display_time(timer).."  ("..display_time(map.timer).." de base)")
	log("Score:"..score)
	log("SCORE TOTAL:"..calc_score_total())
end

function calc_score_total()
	if vie > 0 then
		return score + math.floor(timer) + vie * 30 + coin * 3
	end
	return score + coin * 3
end

function display_time(second)
	second = math.floor(second)
	if second > 60 then
		return ""..math.floor(second/60).."Min"..(second%60).."s"
	end
	return ""..second.."s"
end

-------------------------------------------

-- entity check
function suported_entity(txt)
	if string.find("BIG_MARIO,ENEMIE1,ENEMIE2,ENEMIE3,CAISSE,BLU_CAISSE,COIN_BOX,CHMP_BOX,CHAMP,INSTABLE", txt) then return true end
	if string.find("U_SPIKE,D_SPIKE,GOLD,FLAG,Y_CBOX,G_CBOX,R_CBOX,B_CBOX,Y_BOX,G_BOX,R_BOX,B_BOX", txt) then return true end
	if string.find("CARNV_PLANT,CARNV_PLANT_T,CARNV_PLANT_H,LAVA,NOTE", txt) then return true end
	return false
end
function moving_entity(txt)
	if string.find("ENEMIE1,ENEMIE2,ENEMIE3,CHAMP", txt) then return true end
	return false
end
function walkable_entity(txt)
	if string.find("CAISSE,BLU_CAISSE,COIN_BOX,CHMP_BOX,INSTABLE,U_SPIKE,D_SPIKE,Y_BOX,G_BOX,R_BOX,B_BOX,CARNV_PLANT,NOTE", txt) then return true end
	return false
end
function small_entity(txt)
	if string.find("ENEMIE1,ENEMIE2,ENEMIE3,CHAMP,U_SPIKE,D_SPIKE,GOLD,FLAG,CARNV_PLANT_H", txt) then return true end
	return false
end
function hitable_entity(txt)
	if string.find("INSTABLE,NOTE", txt) then return true end
	return false
end
function up_hitable_entity(txt)
	if string.find("COIN_BOX,CHMP_BOX", txt) then return true end
	return false
end

