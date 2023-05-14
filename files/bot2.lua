local target = nil
local cooldowns = { 0, 0, 0 }
local cercle = nil
local inside = false
local dirs = { { -1, 0 }, { 0, -1 }, { 1, 0 }, { 0, 1 } } --{1,1 }
--local last_b_pos = nil


-- Initialize bot
function bot_init(me)

end

local function getRandomDirection()
  local numrand = math.random(1, 4)
  local numrand2 = math.random(1, 4)
  local direction = {
    x = numrand,
    y = numrand2
  }
  return direction
end

function im_in(me_pos, cercle)
  local distacia = vec.distance(me_pos, vec.new(cercle:x(), cercle:y()))
  return distacia < cercle:radius()
end

-- retorna true si tinc una bala molt propera que ve cap a mi
function bullet_near_danger(me_pos)
  local near = false
  for _, entity in ipairs(me:visible()) do
    if entity:type() == "small_projectile" then

      local distancia = vec.distance(me_pos, entity:pos())
      if distancia <= 5 then
        near = true
      end
    end
  end
  return near 
end

function bot_main(me)
  cercle = me:cod() -- objecte cercle
  local me_pos = me:pos()
  local direccio = nil
  inside = im_in(me_pos, cercle)
  target = cercle

  if not inside then
    direccio = vec.new(target:x(), target:y()):sub(me_pos)
    -- si bullet a prop, dash per esquivar
    if bullet_near_danger(me_pos) then
      if cooldowns[2] == 0 then
        me:cast(1, direccio)  
        cooldowns[2] = 250
      end
    end
  else
   
    local numrand = math.random(1, 4)
    direccio = vec.new(dirs[numrand][1], dirs[numrand][2])
  end
  me:move(direccio)

end

