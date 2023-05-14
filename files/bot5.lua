-- Global variables                              
local target = nil
local cercle = nil
local inside = false
local direccio = nil
local safe_b_dir = nil
local act_nearest_bullet_loc = nil
local past_nearest_bullet_loc = nil
local entities_act = {}
local entities_past = {}


-- Initialize bot
function bot_init(me)
    entities_past = me:visible()
    past_nearest_bullet_loc = vec.new(250, 250)   --dummy value
end


-- Generate random number in 2D
function getRandomDirection()
  local angle = math.random() * 2 * math.pi --random number between 0-1 and convert it to radians
  local direction = {
    x = math.cos(angle),
    y = math.sin(angle)
  }
  return direction
end


-- Returns true whether the player is in the circle
function inside_cercle(me_pos, cercle)
  local distacia = vec.distance(me_pos, vec.new(cercle:x(), cercle:y()))
  return distacia < cercle:radius()
end


-- Return the distance to the closest point to the circle form the inside, if the player it's outside it returns -1
function distance_to_cercle(me_pos, cercle) 
    local dist = -1

    if inside then 
        dist = vec.distance(me_pos, cercle:pos()) --dist to center radius   
    else return -1
    end
        
    return cercle:radius() - dist
end


-- Return true if i there is a near incoming bullet, and store it's position
function bullet_coming(me_pos) 
    local near = false
    for _, entity in ipairs(entities_act) do
      if entity:type() == "small_projectile" then
  
        local distancia = vec.distance(me_pos, entity:pos())
        if distancia <= 5.3 then
          near = true
          act_nearest_bullet_loc = entity:pos()
        end
      end
    end
    return near 
end


-- Returns a safe perpendicular direction, considering the direction of the nearest bullet
function safe_bullet_dir(me_pos) 
    local dir_bullet = vec.distance(past_nearest_bullet_loc, act_nearest_bullet_loc)

    safe_b_dir = {x = dir_bullet:y(), y = -dir_bullet:x()}   --perpendicular direction that is safe, for movement
end


-- Returns the distance to the nearest enemy
function get_distance_nearest_enemy(me_pos)
  local min_distance = 600
  for _, player in ipairs(entities_act) do
    local dist = vec.distance(me_pos, player:pos())
    if dist < min_distance then
      min_distance = dist
    end
  end
  return min_distance
end


-- Returns the direction of the nearest enemy
function get_dir_nearest_enemy(me_pos)
  local closest_enemy = nil
  local min_distance = 9999
  for _, player in ipairs(entities_act) do
    local dist = vec.distance(me_pos, player:pos())
    if dist < min_distance then
      min_distance = dist
      closest_enemy = player
    end
  end
  return closest_enemy:pos():sub(me_pos)
end


-- Return true if the two given vectors are perpendicular and point to same direction
function arePerpendicularAndPointingSameDirection(a, b)
  local dotProduct = a:x() * b:x() + a:y() * b:y()
  
  local magnitudeA = math.sqrt(a:x() * a:x() + a:y() * a:y())
  local magnitudeB = math.sqrt(b:x() * b:x() + b:y() * b:y())
  local normalizedA = { x = a:x() / magnitudeA, y = a:y() / magnitudeA }
  local normalizedB = { x = b:x() / magnitudeB, y = b:y() / magnitudeB }

  return dotProduct == 0 and normalizedA.x == normalizedB.x and normalizedA.y == normalizedB.y --Dot Product == 0 and normalizing and checking if their components are equal
end


-- Return true if an enemy is in range of a melee attack in the direction the player is moving
function enemy_close_in_direction_melee(me_pos)

  return get_distance_nearest_enemy(me_pos) <= 2 and
      arePerpendicularAndPointingSameDirection(get_dir_nearest_enemy(me_pos), direccio)
end


-- Main bot function
function bot_main(me)

  local me_pos = me:pos()
  entities_act = me:visible() --store all sorrounding entities
  cercle = me:cod() --store the circle information: x, y, radius

  if cercle:x() ~= -1 then --exists the circle
    inside = inside_cercle(me_pos, cercle)

    if not inside then
      target = cercle --plan to go to the cercle
      direccio = vec.new(cercle:x()-2, cercle:y()-2):sub(me_pos) --direction from player to center cercle (with little offset so they don't shoot at the center)


      -- MODE dodge bullet
      if bullet_coming(me_pos) then
        safe_bullet_dir(me_pos);  --calculates best direction to move to avoid bullets
        direccio = safe_b_dir
      
      else
        -- MODE meele attack
        if me:cooldown(2) then 

        if (enemy_close_in_direction_melee(me_pos)) then 
          me:cast(2, direccio) -- melee attack
         
        end
        else
            -- MODE shoot
            if me:cooldown(0) == 0 then 
                direccio = get_dir_nearest_enemy()
                me:cast(0, direccio) -- shoot to nearest enemy
            end
        end
      end
    else
        -- MODE dodge bullet
        if bullet_coming(me_pos) then
            safe_bullet_dir(me_pos);  --calculates best direction to move to avoid bullets
            direccio = safe_b_dir
        end
    end

  else
    -- if the circle is close to me, move to center
    if (distance_to_cercle(me_pos, cercle)) < 30 then
        direccio = vec.new(cercle:x(), cercle:y()):sub(me_pos) 

    else
        --avoid everything and enemies
        if bullet_coming(me_pos) then
            safe_bullet_dir(me_pos);  --calculates best direction to move to avoid bullets
            direccio = safe_b_dir
           
        end

        --attack near enemies
        if get_distance_nearest_enemy(me_pos) <= 2 then
            direccio = get_dir_nearest_enemy(me_pos)
            if me:cooldown(2) then 
                if (enemy_close_in_direction_melee(me_pos)) then
                    me:cast(2, direccio) -- melee attack
                end
            end
        
        else
            --dodge bullets
            if bullet_coming(me_pos) then
                safe_bullet_dir(me_pos);  --calculates best direction to move to avoid bullets
                direccio = safe_b_dir
            end
        end

    end

  end

  me:move(direccio)

  entities_past = entities_act  --store the previous round enemies and bullets
  past_nearest_bullet_loc = act_nearest_bullet_loc   -- store the previous round position of nearest bullet

end

