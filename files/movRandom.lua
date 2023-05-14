-- Global variables
local target = nil
local cooldowns = { 0, 0, 0 }

local function getRandomDirection()
  local angle = math.random() * 2 * math.pi
  local direction = {
    x = math.cos(angle),
    y = math.sin(angle)
  }
  return direction
end

-- Initialize bot
function bot_init(me)
end

-- Main bot function
function bot_main(me)
  local me_pos = me:pos()
  local randomDirection = getRandomDirection()
  me:move(randomDirection)

end
