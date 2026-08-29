-- dart.lua
-- A single dart that flies from the “hand” to the board,
-- scaling up while in flight and shrinking again when it lands.

local Dart = {}
Dart.__index = Dart

-- ctor : startPos → targetPos → score → angle
function Dart.new(startPos, targetPos, score, angle)
  local self       = setmetatable({}, Dart)

  self.startPos    = { x = startPos.x, y = startPos.y }
  self.targetPos   = { x = targetPos.x, y = targetPos.y }
  self.x           = startPos.x
  self.y           = startPos.y
  self.score       = score
  self.angle       = angle

  self.elapsed     = 0
  self.duration    = 0.6  -- seconds
  self.isAnimating = true
  self.scale       = 0.2  -- start small

  return self
end

function Dart:update(dt)
  if not self.isAnimating then return end

  self.elapsed = self.elapsed + dt
  local t      = math.min(self.elapsed / self.duration, 1)

  -- linear interpolation of position
  self.x       = self.startPos.x + (self.targetPos.x - self.startPos.x) * t
  self.y       = self.startPos.y + (self.targetPos.y - self.startPos.y) * t

  -- scale: small → peak → small
  local peak   = 1.0
  local min    = 0.2
  local scale  = min + (peak - min) * (1 - math.abs(t - 0.5) * 2)
  self.scale   = scale

  if t >= 1 then
    self.isAnimating = false
    self.x = self.targetPos.x
    self.y = self.targetPos.y
    self.scale = min     -- final small size on the board
  end
end

function Dart:draw()
  local shaftW  = 4
  local shaftH  = 20
  local tipSize = 6

  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(self.angle)
  love.graphics.scale(self.scale, self.scale)

  -- shaft (grey)
  love.graphics.setColor(0.6, 0.6, 0.6)
  love.graphics.rectangle("fill", -shaftW / 2, -shaftH / 2, shaftW, shaftH)

  -- tip (red triangle)
  love.graphics.setColor(1, 0, 0)
  love.graphics.polygon("fill",
    0, -shaftH / 2,
    -tipSize / 2, -shaftH / 2 - tipSize,
    tipSize / 2, -shaftH / 2 - tipSize)

  love.graphics.pop()
end

return Dart
