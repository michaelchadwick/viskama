-- dart.lua
-- Represents a single thrown dart

local Dart = {}
Dart.__index = Dart

function Dart.new(x, y, score)
  local self = setmetatable({}, Dart)
  self.x = x
  self.y = y
  self.score = score or 0
  return self
end

function Dart:draw()
  love.graphics.setColor(1, 0, 0)
  love.graphics.circle("fill", self.x, self.y, 6)
end

return Dart
