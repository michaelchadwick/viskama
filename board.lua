-- board.lua
-- Holds the dartboard geometry and scoring logic

local Board = {}
Board.__index = Board

function Board.new(x, y, radius)
  local self     = setmetatable({}, Board)

  self.x         = x or 400
  self.y         = y or 300
  self.radius    = radius or 200

  -- radii for the scoring rings
  self.innerBull = 30
  self.outerBull = 60
  self.ring      = 90
  self.outerRing = 120

  -- maximum random offset added to a throw (pixels)
  self.maxError  = 12

  return self
end

----------------------------------------------------------------
-- Draw the board (very simple coloured circles)
----------------------------------------------------------------
function Board:draw()
  love.graphics.setColor(0.8, 0.8, 0.8)   -- board background
  love.graphics.circle("fill", self.x, self.y, self.radius)

  love.graphics.setColor(1, 0, 0)   -- inner bull
  love.graphics.circle("fill", self.x, self.y, self.innerBull)

  love.graphics.setColor(1, 0.5, 0)   -- outer bull
  love.graphics.circle("fill", self.x, self.y, self.outerBull)

  love.graphics.setColor(1, 1, 0)   -- inner ring
  love.graphics.circle("fill", self.x, self.y, self.ring)

  love.graphics.setColor(0, 0, 1)   -- outer ring
  love.graphics.circle("fill", self.x, self.y, self.outerRing)

  love.graphics.setColor(0, 0, 0)   -- outline
  love.graphics.circle("line", self.x, self.y, self.radius, 32)
end

----------------------------------------------------------------
-- Simple radial scoring
----------------------------------------------------------------
function Board:calculateScore(pos)
  local dx = pos.x - self.x
  local dy = pos.y - self.y
  local dist = math.sqrt(dx * dx + dy * dy)

  if dist <= self.innerBull then
    return 100
  elseif dist <= self.outerBull then
    return 75
  elseif dist <= self.ring then
    return 50
  elseif dist <= self.outerRing then
    return 25
  else
    return 0
  end
end

return Board
