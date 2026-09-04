-- game.lua
local Board  = require "board"
local Dart   = require "dart"
local config = require "config"

local Game   = {}
Game.__index = Game

----------------------------------------------------------------
--  ctor – receives the board and the full configuration
----------------------------------------------------------------
function Game.new(board, config)
  local self             = setmetatable({}, Game)

  self.board             = board
  self.config            = config
  self.state             = "title"

  self.uiColors          = config.ui.colors
  self.textFont          = love.graphics.newFont(config.ui.smallFontSize)
  self.debugFont         = love.graphics.newFont(config.ui.debugFontSize)

  self.maxThrows         = config.game.maxThrows
  self.throwsLeft        = config.game.maxThrows
  self.scores            = {}
  self.totalScore        = 0
  self.darts             = {}

  self.currentThrow      = {
    holding  = false,
    startPos = { x = 0, y = 0 },
    lastPos  = { x = 0, y = 0 }
  }

  self.pullOrigin        = nil

  self.gameOverDelay     = 0.35 -- seconds to wait after the last dart lands
  self.gameOverTimer     = 0    -- accumulates time
  self.waitingForOverlay = false

  return self
end

----------------------------------------------------------------
--  reset round
----------------------------------------------------------------
function Game:reset()
  self.state                   = "play"
  self.maxThrows               = self.maxThrows
  self.throwsLeft              = self.maxThrows
  self.scores                  = {}
  self.totalScore              = 0
  self.darts                   = {}

  self.currentThrow.holding    = false
  self.currentThrow.startPos.x = 0
  self.currentThrow.startPos.y = 0
  self.currentThrow.lastPos.x  = 0
  self.currentThrow.lastPos.y  = 0

  self.gameOverTimer           = 0
  self.waitingForOverlay       = false
end

----------------------------------------------------------------
--  Input handling
----------------------------------------------------------------
function Game:mousepressed(x, y, button)
  if self.state ~= "play" or button ~= 1 then return end
  self.currentThrow.holding    = true
  self.currentThrow.startPos.x = x
  self.currentThrow.startPos.y = y
  self.currentThrow.lastPos.x  = x
  self.currentThrow.lastPos.y  = y
  self.pullOrigin              = { x = x, y = y }
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
  self.pullOrigin = nil
end

----------------------------------------------------------------
--  Throw logic
----------------------------------------------------------------
function Game:throwDart(vec)
  if self.throwsLeft <= 0 then return end

  local magnitude = math.sqrt(vec.x * vec.x + vec.y * vec.y)
  local forceRatio = magnitude / self.board.maxForceMagnitude

  local startPos = self.currentThrow.startPos
  local targetPos
  local angle

  local floorThreshold = 0.01
  if forceRatio < floorThreshold then
    targetPos = { x = startPos.x, y = love.graphics.getHeight() + 50 }
    angle = math.rad(90)
  else
    -- direction of flight (opposite of drag)
    local dir = {}
    if magnitude < 0.01 then
      dir.x, dir.y = 0, -1
    else
      dir.x = vec.x / magnitude
      dir.y = vec.y / magnitude
    end

    local travelMod = 1.75
    local travelDistance = math.min(forceRatio, 1) * self.board.radius * travelMod

    local optimumForce = 0.9
    local errorScale
    if forceRatio <= optimumForce then
      errorScale = 1 - (forceRatio / optimumForce)
    else
      errorScale = (forceRatio - optimumForce) / (1 - optimumForce)
    end
    local baseError = self.board.maxError
    local offsetX = (math.random() * 2 - 1) -- * errorScale * baseError
    local offsetY = (math.random() * 2 - 1) -- * errorScale * baseError

    targetPos = {
      x = startPos.x - dir.x * travelDistance + offsetX,
      y = startPos.y - dir.y * travelDistance + offsetY
    }

    angle = math.atan2(-dir.y, -dir.x)
  end

  local score, txt = self.board:scoreFromPosition(targetPos, self.board)
  local dart       = Dart.new(startPos, targetPos, score, angle,
    self.config.dart, self.board)

  table.insert(self.darts, dart)

  self.throwsLeft = self.throwsLeft - 1
end

----------------------------------------------------------------
--  Update – animate darts & transition to overlay after all are done
----------------------------------------------------------------
function Game:update(dt)
  for _, dart in ipairs(self.darts) do
    dart:update(dt)

    if not dart.isAnimating and not dart.scoreAdded then
      -- The dart has landed – add its score now
      self.totalScore = self.totalScore + dart.score
      dart.scoreAdded = true

      -- Build the human‑readable score string
      local score, txt = self.board:scoreFromPosition(dart.targetPos)
      dart.displayScore = txt
      dart.displayPos = (string.format("%d", dart.targetPos.x) .. ", " .. string.format("%d", dart.targetPos.y))
      dart.displayAngle = string.format("%5.1f", dart.angle)
    end
  end

  if self.throwsLeft <= 0 then
    local allDone = true
    for _, dart in ipairs(self.darts) do
      if dart.isAnimating then
        allDone = false
        break
      end
    end
    if allDone then
      if not self.waitingForOverlay then
        self.waitingForOverlay = true
        self.gameOverTimer = 0
      else
        self.gameOverTimer = self.gameOverTimer + dt
        if self.gameOverTimer >= self.gameOverDelay then
          self.state = "over" -- now show the overlay
          self.waitingForOverlay = false
        end
      end
    end
  end
end

----------------------------------------------------------------
--  Draw – board, darts and their values, pointer, force meter HUD
----------------------------------------------------------------
function Game:draw()
  love.graphics.clear(unpack(self.board.colors.background))

  -- Board
  self.board:draw()

  -- Darts
  for _, dart in ipairs(self.darts) do
    dart:draw()
  end

  -- Pointer Dot
  if self.currentThrow.holding then
    love.graphics.setColor(unpack(config.dart.colors.holdDot))
    love.graphics.circle("fill", self.currentThrow.lastPos.x,
      self.currentThrow.lastPos.y, 4)
  else
    local mx, my = love.mouse.getPosition()
    love.graphics.setColor(unpack(config.dart.colors.unholdDot))
    love.graphics.circle("fill", mx, my, 4)
  end

  -- Visual force meter (only while dragging)
  if self.currentThrow.holding then
    local dx           = self.currentThrow.lastPos.x - self.currentThrow.startPos.x
    local dy           = self.currentThrow.lastPos.y - self.currentThrow.startPos.y
    local forceMag     = math.sqrt(dx * dx + dy * dy)
    local forcePercent = math.min(
      math.log(forceMag + 1) / math.log(self.board.maxForceMagnitude + 1),
      1
    )

    local meterW       = 300
    local meterH       = 20
    local meterX       = (love.graphics.getWidth() - meterW) / 2
    local meterY       = love.graphics.getHeight() - 50

    -- background
    love.graphics.setColor(unpack(self.uiColors.forceBox))
    love.graphics.rectangle("fill", meterX, meterY, meterW, meterH)

    -- fill
    love.graphics.setColor(unpack(self.uiColors.forceMeter))
    love.graphics.rectangle("fill", meterX, meterY, meterW * forcePercent, meterH)

    -- text
    love.graphics.setColor(unpack(self.uiColors.text))
    local txt = string.format("Force: %.0f%%", forcePercent * 100)
    local txtW = self.textFont:getWidth(txt)
    love.graphics.print(txt, meterX + (meterW - txtW) / 2, meterY - 20)
  end

  if self.pullOrigin then
    local origin = self.pullOrigin
    local current = self.currentThrow.lastPos

    -- small circle at the origin
    love.graphics.setColor(unpack(config.dart.colors.unholdDot))
    love.graphics.circle("fill", origin.x, origin.y, 5)

    -- line to the current cursor position
    love.graphics.setColor(unpack(config.dart.colors.dragLine))
    love.graphics.setLineWidth(2)
    love.graphics.line(origin.x, origin.y,
      current.x, current.y)
  end

  -- HUD:
  --- current throw and totalScore
  local currentThrowNumber = math.min(self.maxThrows, (self.maxThrows + 1) - self.throwsLeft)
  love.graphics.setFont(self.textFont)
  love.graphics.setColor(unpack(self.uiColors.hud))
  love.graphics.print("Throw " .. currentThrowNumber .. " / " .. self.maxThrows, 10, 10)
  love.graphics.print("Total Score: " .. self.totalScore, 10, 40)

  -- individual dart scores
  local x = love.graphics.getWidth() + 20
  local y = 10
  local xOffset = 170
  local lineHeight = 14
  for i, dart in ipairs(self.darts) do
    local score = dart.displayScore or ""
    local pos = dart.displayPos or ""
    local angle = dart.displayAngle or ""

    love.graphics.setColor(self.uiColors.text)
    love.graphics.setFont(self.debugFont)
    love.graphics.print(i, x - xOffset, y + (i - 1) * lineHeight)
    love.graphics.print(score, x - (xOffset - 20), y + (i - 1) * lineHeight)
    love.graphics.setColor(self.uiColors.highlight)
    love.graphics.print(pos, x - (xOffset - 55), y + (i - 1) * lineHeight)
    love.graphics.print(angle, x - (xOffset - 115), y + (i - 1) * lineHeight)
  end

  -- cursor position
  x = love.graphics.getWidth() - 42
  y = love.graphics.getHeight() - 32
  love.graphics.setFont(self.debugFont)
  local mx, my = love.mouse.getPosition()
  love.graphics.print('X: ' .. mx, x, y)
  y = love.graphics.getHeight() - 20
  love.graphics.print('Y: ' .. my, x, y)
end

return Game
