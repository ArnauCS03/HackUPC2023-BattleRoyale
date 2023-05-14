-- Global variables                              
local target = nil
local cercle = nil
local inside = false
local direccio = nil
local entities_act = {}
local entities_past = {}


-- Initialize bot
function bot_init(me)
    entities_past = me:visible()
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
        dist = vec.distance(me_pos, cercle:pos()) --dist to center radius   --OJO sino amb x i y
    else return -1
    end
        
    return cercle:radius() - dist
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



      -- MODE meele attack
      if me:cooldown(2) then 

        if (enemy_close_in_direction_melee(me_pos)) then -- TODO si el enemic esta a radi 2 tb petarlo per molt que no estigui direccio
          me:cast(2, direccio) -- melee attack
         
        end

      end

      -- MODE shoot
      if me:cooldown(0) == 0 then 
        direccio = get_dir_nearest_enemy()
        me:cast(0, direccio) -- shoot to nearest enemy
      end


    else -- MODE defence

      target = cercle
    end

  else

    -- if im close to circle, move to center
    if (distance_to_cercle(me_pos, cercle)) < 10 then
        direccio = vec.new(cercle:x()-2, cercle:y()-2):sub(me_pos) 

    else
        --esquivar tot i enemics

        direccio = getRandomDirection()

    end


  end

  me:move(direccio)

  entities_past = entities_act  -- store the previous round enemies and bullets

end

