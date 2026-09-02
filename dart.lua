-- dart.lua
local Dart = {}
Dart.__index = Dart

----------------------------------------------------------------
--  ctor – initialise everything and set the start scale
----------------------------------------------------------------
function Dart.new(startPos, targetPos, score, angle, config)
  local self          = setmetatable({}, Dart)

  self.startPos       = { x = startPos.x, y = startPos.y }
  self.targetPos      = { x = targetPos.x, y = targetPos.y }
  self.x              = startPos.x
  self.y              = startPos.y
  self.score          = score
  self.angle          = angle
  self.displayScore   = ""
  self.colors         = config.colors

  self.elapsed        = 0
  self.duration       = config.duration
  self.isAnimating    = true

  self.scaleStart     = config.scaleStart
  self.scalePeak      = config.scalePeak
  self.scaleEnd       = config.scaleEnd

  self.hitBoard       = score > 0
  self.crossSize      = config.crossSize
  self.crossLineWidth = config.crossLineWidth

  self.scoreAdded     = false

  return self
end

----------------------------------------------------------------
--  Update animation
----------------------------------------------------------------
function Dart:update(dt)
  if not self.isAnimating then return end

  self.elapsed = self.elapsed + dt
  local t = math.min(self.elapsed / self.duration, 1)

  self.x = self.startPos.x + (self.targetPos.x - self.startPos.x) * t
  self.y = self.startPos.y + (self.targetPos.y - self.startPos.y) * t

  local scale = self.scaleStart +
      (self.scalePeak - self.scaleStart) * (1 - math.abs(t - 0.5) * 2)

  self.scale = scale

  if t >= 1 then
    self.isAnimating = false
    self.x = self.targetPos.x
    self.y = self.targetPos.y
    self.scale = self.scaleEnd
  end
end

----------------------------------------------------------------
--  Draw – bright landing cross when finished
----------------------------------------------------------------
function Dart:draw()
  if self.isAnimating then
    -- normal dart shape while flying
    local shaftW  = 4
    local shaftH  = 20
    local tipSize = 6

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle + 80)
    love.graphics.scale(self.scale, self.scale)

    -- shaft
    love.graphics.setColor(self.colors.shaft)
    love.graphics.rectangle("fill", -shaftW / 2, -shaftH / 2, shaftW, shaftH)

    -- tip
    love.graphics.setColor(self.colors.tip)
    love.graphics.polygon("fill",
      0, -shaftH / 2,
      -tipSize / 2, -shaftH / 2 - tipSize,
      tipSize / 2, -shaftH / 2 - tipSize)

    love.graphics.pop()
  else
    if self.hitBoard then
      local s = self.crossSize

      -- outline (thicker, white)
      love.graphics.setColor(unpack(self.colors.crossOutline))
      love.graphics.setLineWidth(self.crossLineWidth + 4)
      love.graphics.line(self.x - s, self.y, self.x + s, self.y)
      love.graphics.line(self.x, self.y - s, self.x, self.y + s)

      -- main cross (actual colour)
      love.graphics.setColor(unpack(self.colors.cross))
      love.graphics.setLineWidth(self.crossLineWidth)
      love.graphics.line(self.x - s, self.y, self.x + s, self.y)
      love.graphics.line(self.x, self.y - s, self.x, self.y + s)
    end
  end
end

return Dart
