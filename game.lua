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
--  Game:throwDart ---------------------------------------------
----------------------------------------------------------------
function Game:throwDart(vec)
  if self.throwsLeft <= 0 then
    return
  end

  local magnitude = math.sqrt(vec.x * vec.x + vec.y * vec.y)
  local forceRatio = magnitude / MAX_FORCE_MAG
  local startPos = self.currentThrow.startPos

  local floorThreshold = 0.1
  local targetPos
  local angle

  if forceRatio < floorThreshold then
    targetPos = { x = startPos.x, y = love.graphics.getHeight() + 50 }
    angle = math.rad(90)
  else
    local dir = {}
    if magnitude < 0.01 then
      dir.x, dir.y = 0, -1
    else
      dir.x = vec.x / magnitude
      dir.y = vec.y / magnitude
    end

    local travelDistance = math.min(forceRatio, 1) * self.board.radius
    local optimumForce = 0.9
    local errorScale
    if forceRatio <= optimumForce then
      errorScale = 1 - (forceRatio / optimumForce)
    else
      errorScale = (forceRatio - optimumForce) / (1 - optimumForce)
    end
    local baseError = self.board.maxError
    local offsetX = (math.random() * 2 - 1) * errorScale * baseError
    local offsetY = (math.random() * 2 - 1) * errorScale * baseError

    targetPos = {
      x = startPos.x - dir.x * travelDistance + offsetX,
      y = startPos.y - dir.y * travelDistance + offsetY
    }

    angle = math.atan2(-dir.y, -dir.x)
  end

  local score = self.board:calculateScore(targetPos)
  local dart  = Dart.new(startPos, targetPos, score, angle, self.board.radius)
  table.insert(self.darts, dart)

  table.insert(self.scores, score)
  self.totalScore = self.totalScore + score
  self.throwsLeft = self.throwsLeft - 1
end

----------------------------------------------------------------
--  Game:update -------------------------------------------------
----------------------------------------------------------------
function Game:update(dt)
  -- 1. Update all dart animations
  for _, dart in ipairs(self.darts) do
    dart:update(dt)
  end

  -- 2. If all throws are used, wait until every dart stops animating
  if self.throwsLeft <= 0 then
    local allDone = true
    for _, dart in ipairs(self.darts) do
      if dart.isAnimating then
        allDone = false
        break
      end
    end
    if allDone then
      self.state = "over" -- now show the overlay
    end
  end
end

----------------------------------------------------------------
-- DRAW – board, darts and in‑game UI
----------------------------------------------------------------
function Game:draw()
  love.graphics.clear(0.05, 0.05, 0.05)

  -- 1. Board & darts
  self.board:draw()
  for _, dart in ipairs(self.darts) do
    dart:draw()
  end

  -- 2. Pointer dot
  if self.currentThrow.holding then
    -- dragging: green dot at last drag position
    love.graphics.setColor(0, 1, 0)
    love.graphics.circle("fill", self.currentThrow.lastPos.x, self.currentThrow.lastPos.y, 4)
  else
    -- idle: blue dot at mouse position
    local mx, my = love.mouse.getPosition()
    love.graphics.setColor(0, 0, 1)
    love.graphics.circle("fill", mx, my, 4)
  end

  -- 3. Visual force meter (only while dragging)
  if self.currentThrow.holding then
    local dx           = self.currentThrow.lastPos.x - self.currentThrow.startPos.x
    local dy           = self.currentThrow.lastPos.y - self.currentThrow.startPos.y
    local forceMag     = math.sqrt(dx * dx + dy * dy)
    local forcePercent = math.min(forceMag / MAX_FORCE_MAG, 1)

    local meterW       = 300
    local meterH       = 20
    local meterX       = (love.graphics.getWidth() - meterW) / 2
    local meterY       = love.graphics.getHeight() - 50

    -- background
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("fill", meterX, meterY, meterW, meterH)

    -- fill
    love.graphics.setColor(0, 1, 0, 0.8)
    love.graphics.rectangle("fill", meterX, meterY, meterW * forcePercent, meterH)

    -- text
    love.graphics.setColor(1, 1, 1)
    local txt = string.format("Force: %.0f%%", forcePercent * 100)
    local txtW = self.font:getWidth(txt)
    love.graphics.print(txt, meterX + (meterW - txtW) / 2, meterY - 20)
  end

  -- 4. HUD
  local currentThrowNumber = math.min(3, 4 - self.throwsLeft)
  love.graphics.setFont(self.font)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Throw " .. currentThrowNumber .. " of 3", 10, 10)
  love.graphics.print("Total Score: " .. self.totalScore, 10, 40)
end

return Game
