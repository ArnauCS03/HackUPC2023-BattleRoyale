-- Global variables                              
local target = nil
local cercle = nil
local inside = false
local direccio = nil
local entis_act = {}
local entis_past = {}


-- Initialize bot
function bot_init(me)
  entis_past = me:visible()
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
function im_in(me_pos, cercle)
  local distacia = vec.distance(me_pos, vec.new(cercle:x(), cercle:y()))
  return distacia < cercle:radius()
end

-- Returns the distance to the nearest enemy
function get_distance_nearest_enemy(me_pos)
  local min_distance = 600
  for _, player in ipairs(entis_act) do
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
  local min_distance = math.huge
  for _, player in ipairs(entis_act) do --OJO abans player sol
    local dist = vec.distance(me_pos, player:pos())
    if dist < min_distance then
      min_distance = dist
      closest_enemy = player
    end
  end
  return closest_enemy:pos():sub(me_pos)
end

-- Return true if the two given vectors are perpendicular and point same direction
function arePerpendicularAndPointingSameDirection(a, b)
  local dotProduct = a.x * b.x + a.y * b.y
  local magnitudeA = math.sqrt(a.x * a.x + a.y * a.y)
  local magnitudeB = math.sqrt(b.x * b.x + b.y * b.y)
  local normalizedA = { x = a.x / magnitudeA, y = a.y / magnitudeA }
  local normalizedB = { x = b.x / magnitudeB, y = b.y / magnitudeB }

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
  entis_act = me:visible() --store all sorrounding entities
  cercle = me:cod() --store the circle information: x, y, radius

  -- Update cooldowns

  -- for i = 1, 3 do
  --   if cooldowns[i] > 0 then
  --     cooldowns[i] = cooldowns[i] - 1
  --   end
  -- end

  -- Update cooldowns
  -- for i = 1, 3 do
  --   cooldowns[i] = me:cooldown(i)  --store the remaining coooldown for all the casts

  if cercle:x() ~= -1 then --exists the circle
    inside = im_in(me_pos, cercle)

    if not inside then
      target = cercle --plan to go to the cercle
      direccio = vec.new(cercle:x(), cercle:y()):sub(me_pos) --direction from player to center cercle

      -- MODE dodge bullet



      -- MODE meele attack
      if me:cooldown(2) then 

        if (enemy_close_in_direction_melee(me_pos)) then -- TODO si el enemic esta a radi 2 tb petarlo per molt que no estigui direccio
          me:cast(2, direccio) -- melee attack
          -- cooldowns[2] = 260
        end



      end

      -- MODE shoot
      if me:cooldown(0) == 0 then ---cooldowns[1] == 0 then
        direccio = get_dir_nearest_enemy()
        me:cast(0, direccio) -- shoot to nearest enemy
      end


    else -- MODE defence

      
      target = cercle
    end

  else
    -- MODO attack enemies
    local closest_enemy = nil
    local min_distance = math.huge
    for _, player in ipairs(me:visible()) do
      local dist = vec.distance(me_pos, player:pos())
      if dist < min_distance then
        min_distance = dist
        closest_enemy = player
      end
    end
    target = closest_enemy --we find a enemy closest target

    if target ~= nil then
      direccio = target:pos():sub(me_pos) --direction to the closest enemy

      -- If target is within melee range and melee attack is not on cooldown, use melee attack
      if min_distance <= 2 and me:cooldown(2) == 0 then
        me:cast(2, direccio)
        --cooldowns[3] = 50
        --cooldowns[3] = me:cooldown(2);

        -- If target is not within melee range and projectile is not on cooldown, use projec
      elseif me:cooldown(0) == 0 then --cooldowns[1] == 0 then

        -- Move towards the target
        me:cast(0, direccio)
        --cooldowns[1] = 1
      end
    end
  end
  -- Move the player
  me:move(direccio)

  entis_past = entis_act
end

