-- game.lua
-- Handles game state, input, throws, and scoring

local Board         = require "board"
local Dart          = require "dart"

local Game          = {}
Game.__index        = Game

local MAX_FORCE_MAG = 400 -- vector length that yields maximum force

----------------------------------------------------------------
-- Constructor
----------------------------------------------------------------
function Game.new(board, smallFont)
  local self = setmetatable({}, Game)

  self.board = board
  self.state = "title"

  self.font = smallFont -- font used for the HUD

  self.throwsLeft = 3
  self.scores = {}
  self.totalScore = 0
  self.darts = {}

  self.currentThrow = {
    holding  = false,
    startPos = { x = 0, y = 0 },
    lastPos  = { x = 0, y = 0 }
  }

  return self
end

----------------------------------------------------------------
-- Reset/Start a new round
----------------------------------------------------------------
function Game:reset()
  self.state                   = "play"
  self.throwsLeft              = 3
  self.scores                  = {}
  self.totalScore              = 0
  self.darts                   = {}

  self.currentThrow.holding    = false
  self.currentThrow.startPos.x = 0
  self.currentThrow.startPos.y = 0
  self.currentThrow.lastPos.x  = 0
  self.currentThrow.lastPos.y  = 0
end

----------------------------------------------------------------
-- INPUT HANDLERS – mouse, touch, joystick
----------------------------------------------------------------
function Game:mousepressed(x, y, button)
  if self.state ~= "play" or button ~= 1 then return end
  self.currentThrow.holding    = true
  self.currentThrow.startPos.x = x
  self.currentThrow.startPos.y = y
  self.currentThrow.lastPos.x  = x
  self.currentThrow.lastPos.y  = y
end

function Game:mousemoved(x, y, dx, dy)
  if self.currentThrow.holding then
    self.currentThrow.lastPos.x = x
    self.currentThrow.lastPos.y = y
  end
end

function Game:mousereleased(x, y, button)
  if self.state ~= "play" or not self.currentThrow.holding or button ~= 1 then return end
  local vec = {
    x = self.currentThrow.lastPos.x - self.currentThrow.startPos.x,
    y = self.currentThrow.lastPos.y - self.currentThrow.startPos.y
  }
  self:throwDart(vec)
  self.currentThrow.holding = false
end

function Game:touchpressed(id, x, y, dx, dy, pressure)
  if self.state ~= "play" then return end
  self.currentThrow.holding    = true
  self.currentThrow.startPos.x = x
  self.currentThrow.startPos.y = y
  self.currentThrow.lastPos.x  = x
  self.currentThrow.lastPos.y  = y
end

function Game:touchmoved(id, x, y, dx, dy, pressure)
  if self.currentThrow.holding then
    self.currentThrow.lastPos.x = x
    self.currentThrow.lastPos.y = y
  end
end

function Game:touchreleased(id, x, y, dx, dy, pressure)
  if self.state ~= "play" or not self.currentThrow.holding then return end
  local vec = {
    x = self.currentThrow.lastPos.x - self.currentThrow.startPos.x,
    y = self.currentThrow.lastPos.y - self.currentThrow.startPos.y
  }
  self:throwDart(vec)
  self.currentThrow.holding = false
end

function Game:joystickpressed(joy, button)
  if self.state ~= "play" or button ~= 1 then return end
  self.currentThrow.holding    = true
  local ax                     = joy:getGamepadAxis("leftx") * MAX_FORCE_MAG
  local ay                     = joy:getGamepadAxis("lefty") * MAX_FORCE_MAG
  self.currentThrow.startPos.x = ax
  self.currentThrow.startPos.y = ay
  self.currentThrow.lastPos.x  = ax
  self.currentThrow.lastPos.y  = ay
end

function Game:joystickaxis(joy, axis, value)
  if not self.currentThrow.holding then return end
  if axis == "leftx" then
    self.currentThrow.lastPos.x = value * MAX_FORCE_MAG
  elseif axis == "lefty" then
    self.currentThrow.lastPos.y = value * MAX_FORCE_MAG
  end
end

function Game:joystickreleased(joy, button)
  if self.state ~= "play" or not self.currentThrow.holding or button ~= 1 then return end
  local vec = {
    x = self.currentThrow.lastPos.x - self.currentThrow.startPos.x,
    y = self.currentThrow.lastPos.y - self.currentThrow.startPos.y
  }
  self:throwDart(vec)
  self.currentThrow.holding = false
end

----------------------------------------------------------------
-- Throw logic – calculates landing position, applies error,
-- creates a Dart instance, updates score, and checks end of game
----------------------------------------------------------------
function Game:throwDart(vec)
  local magnitude = math.sqrt(vec.x * vec.x + vec.y * vec.y)
  local dir = {}
  if magnitude < 0.01 then
    dir.x, dir.y = 0, -1 -- default forward if the player taps
  else
    dir.x = vec.x / magnitude
    dir.y = vec.y / magnitude
  end

  local landingPos = {
    x = self.board.x + dir.x * self.board.radius,
    y = self.board.y + dir.y * self.board.radius
  }

  -- random error inversely proportional to force
  local forceScale = math.min(magnitude / MAX_FORCE_MAG, 1)
  local errorScale = self.board.maxError * (1 - forceScale)
  local offsetX = (math.random() * 2 - 1) * errorScale
  local offsetY = (math.random() * 2 - 1) * errorScale
  landingPos.x = landingPos.x + offsetX
  landingPos.y = landingPos.y + offsetY

  local score = self.board:calculateScore(landingPos)

  local dart = Dart.new(landingPos.x, landingPos.y, score)
  table.insert(self.darts, dart)

  table.insert(self.scores, score)
  self.totalScore = self.totalScore + score
  self.throwsLeft = self.throwsLeft - 1

  -- after a dart is thrown
  if self.throwsLeft <= 0 then
    self.state = "over"
  end
end

----------------------------------------------------------------
-- UPDATE – no per‑frame logic for now, but keep for future
----------------------------------------------------------------
function Game:update(dt)
  -- placeholder for future animations or timers
end

----------------------------------------------------------------
-- DRAW – board, darts and in‑game UI
----------------------------------------------------------------
function Game:draw()
  love.graphics.clear(0.05, 0.05, 0.05) -- dark background

  self.board:draw()
  for _, dart in ipairs(self.darts) do
    dart:draw()
  end

  love.graphics.setFont(self.font)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Throw " .. (4 - self.throwsLeft) .. " of 3", 10, 10)
  love.graphics.print("Total Score: " .. self.totalScore, 10, 40)

  if self.currentThrow.holding then
    love.graphics.setColor(0, 1, 0)
    love.graphics.circle("fill", self.currentThrow.lastPos.x, self.currentThrow.lastPos.y, 4)
  end
end

return Game
