-- main.lua
-- Viskama – A simple darts game for Love2D
-- Author: ChatGPT – 2026-08-25

-- ---------------------------------------------------------------------------
-- Configuration ------------------------------------------------------------
-- ---------------------------------------------------------------------------

local windowWidth, windowHeight = 800, 600

local board                     = { x = 400, y = 300, radius = 200 }
local innerBull                 = 30 -- radius of bull’s‑eye
local outerBull                 = 60 -- radius of outer bull
local ring                      = 90 -- radius of inner scoring ring
local outerRing                 = 120 -- radius of outer scoring ring

local maxError                  = 12 -- maximum random offset (pixels)
local maxForceMagnitude         = 400 -- vector length that gives full force
local threshold                 = 200 -- win threshold

-- ---------------------------------------------------------------------------
-- Global state --------------------------------------------------------------
-- ---------------------------------------------------------------------------

local state                     = "title" -- "title", "play", "score"

local currentThrow              = {
  holding  = false,
  startPos = { x = 0, y = 0 },
  lastPos  = { x = 0, y = 0 }
}

local game                      = {
  throwsLeft       = 3,
  scores           = {},
  totalScore       = 0,
  landingPositions = {}
}

local titleFont, smallFont

-- ---------------------------------------------------------------------------
-- Love2D callbacks ----------------------------------------------------------
-- ---------------------------------------------------------------------------

function love.load()
  love.window.setTitle("Viskama")
  love.window.setMode(windowWidth, windowHeight, { resizable = false, vsync = true })
  math.randomseed(os.time())

  titleFont = love.graphics.newFont(48)
  smallFont = love.graphics.newFont(24)
end

-----------------------------------------------------------------------
-- State machine --------------------------------------------------------
-----------------------------------------------------------------------

local function resetGame()
  game.throwsLeft       = 3
  game.scores           = {}
  game.totalScore       = 0
  game.landingPositions = {}
  currentThrow.holding  = false
  currentThrow.startPos = { x = 0, y = 0 }
  currentThrow.lastPos  = { x = 0, y = 0 }
end

function love.keypressed(key, scancode, isrepeat)
  if state == "title" then
    resetGame()
    state = "play"
  elseif state == "score" then
    state = "title"
  elseif key == "escape" then
    love.event.quit()
  end
end

-----------------------------------------------------------------------
-- Input handling ---------------------------------------------------------
-----------------------------------------------------------------------

-- Mouse ---------------------------------------------------------------

function love.mousepressed(x, y, button, istouch, presses)
  if state ~= "play" or button ~= 1 then return end
  currentThrow.holding  = true
  currentThrow.startPos = { x = x, y = y }
  currentThrow.lastPos  = { x = x, y = y }
end

function love.mousemoved(x, y, dx, dy, istouch)
  if currentThrow.holding then
    currentThrow.lastPos = { x = x, y = y }
  end
end

function love.mousereleased(x, y, button, istouch, presses)
  if state ~= "play" or not currentThrow.holding or button ~= 1 then return end
  local vec = {
    x = currentThrow.lastPos.x - currentThrow.startPos.x,
    y = currentThrow.lastPos.y - currentThrow.startPos.y
  }
  performThrow(vec)
  currentThrow.holding = false
end

-- Touch ---------------------------------------------------------------

function love.touchpressed(id, x, y, dx, dy, pressure)
  if state ~= "play" then return end
  currentThrow.holding  = true
  currentThrow.startPos = { x = x, y = y }
  currentThrow.lastPos  = { x = x, y = y }
end

function love.touchmoved(id, x, y, dx, dy, pressure)
  if currentThrow.holding then
    currentThrow.lastPos = { x = x, y = y }
  end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
  if state ~= "play" or not currentThrow.holding then return end
  local vec = {
    x = currentThrow.lastPos.x - currentThrow.startPos.x,
    y = currentThrow.lastPos.y - currentThrow.startPos.y
  }
  performThrow(vec)
  currentThrow.holding = false
end

-- Joystick ------------------------------------------------------------

local joystickScale = 200 -- converts analog value (-1…1) to pixel units

function love.joystickpressed(joy, button)
  if state ~= "play" or button ~= 1 then return end
  currentThrow.holding  = true
  local ax              = joy:getGamepadAxis("leftx") * joystickScale
  local ay              = joy:getGamepadAxis("lefty") * joystickScale
  currentThrow.startPos = { x = ax, y = ay }
  currentThrow.lastPos  = { x = ax, y = ay }
end

function love.joystickaxis(joy, axis, value)
  if not currentThrow.holding then return end
  if axis == "leftx" then
    currentThrow.lastPos.x = value * joystickScale
  elseif axis == "lefty" then
    currentThrow.lastPos.y = value * joystickScale
  end
end

function love.joystickreleased(joy, button)
  if state ~= "play" or not currentThrow.holding or button ~= 1 then return end
  local vec = {
    x = currentThrow.lastPos.x - currentThrow.startPos.x,
    y = currentThrow.lastPos.y - currentThrow.startPos.y
  }
  performThrow(vec)
  currentThrow.holding = false
end

-----------------------------------------------------------------------
-- Game logic ------------------------------------------------------------
-----------------------------------------------------------------------

function performThrow(vec)
  -- Direction & force
  local magnitude = math.sqrt(vec.x * vec.x + vec.y * vec.y)
  local dir
  if magnitude < 0.01 then
    dir = { x = 0, y = -1 }   -- default forward if no movement
  else
    dir = { x = vec.x / magnitude, y = vec.y / magnitude }
  end

  -- Landing point on the board
  local landingPos = {
    x = board.x + dir.x * board.radius,
    y = board.y + dir.y * board.radius
  }

  -- Random error that decreases with force
  local forceScale = math.min(magnitude / maxForceMagnitude, 1)
  local errorScale = maxError * (1 - forceScale)
  local offsetX = (math.random() * 2 - 1) * errorScale
  local offsetY = (math.random() * 2 - 1) * errorScale
  landingPos.x = landingPos.x + offsetX
  landingPos.y = landingPos.y + offsetY

  -- Score
  local score = calculateScore(landingPos)

  table.insert(game.landingPositions, landingPos)
  table.insert(game.scores, score)
  game.totalScore = game.totalScore + score
  game.throwsLeft = game.throwsLeft - 1

  if game.throwsLeft <= 0 then
    state = "score"
  end
end

function calculateScore(pos)
  local dx = pos.x - board.x
  local dy = pos.y - board.y
  local dist = math.sqrt(dx * dx + dy * dy)

  if dist <= innerBull then return 100 end
  if dist <= outerBull then return 75 end
  if dist <= ring then return 50 end
  if dist <= outerRing then return 25 end
  return 0
end

-----------------------------------------------------------------------
-- Drawing ---------------------------------------------------------------
-----------------------------------------------------------------------

function love.draw()
  if state == "title" then
    drawTitleScreen()
  elseif state == "play" then
    drawGameScreen()
  elseif state == "score" then
    drawScoreScreen()
  end
end

function drawTitleScreen()
  love.graphics.clear(0.05, 0.05, 0.05)
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(titleFont)
  love.graphics.printf("Viskama", 0, 200, windowWidth, "center")
  love.graphics.setFont(smallFont)
  love.graphics.printf("Press any key to begin", 0, 260, windowWidth, "center")
end

function drawGameScreen()
  love.graphics.clear(0.1, 0.1, 0.1)
  drawBoard()

  -- Draw darts that have landed
  love.graphics.setColor(1, 0, 0)
  for _, pos in ipairs(game.landingPositions) do
    love.graphics.circle("fill", pos.x, pos.y, 6)
  end

  -- Optional: show the current aim if a throw is in progress
  if currentThrow.holding then
    love.graphics.setColor(0, 1, 0)
    love.graphics.circle("fill", currentThrow.lastPos.x, currentThrow.lastPos.y, 4)
  end

  -- UI
  love.graphics.setFont(smallFont)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Throw " .. (4 - game.throwsLeft) .. " of 3", 10, 10)
  love.graphics.print("Total Score: " .. game.totalScore, 10, 40)
end

function drawScoreScreen()
  love.graphics.clear(0.05, 0.05, 0.05)
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(titleFont)
  love.graphics.printf("Final Score: " .. game.totalScore, 0, 200, windowWidth, "center")

  local msg = "You lose!"
  if game.totalScore > threshold then msg = "You win!" end
  love.graphics.setFont(smallFont)
  love.graphics.printf(msg, 0, 260, windowWidth, "center")
  love.graphics.printf("Press any key to return", 0, 320, windowWidth, "center")
end

function drawBoard()
  -- Board background
  love.graphics.setColor(0.8, 0.8, 0.8)
  love.graphics.circle("fill", board.x, board.y, board.radius)

  -- Bull's eye
  love.graphics.setColor(1, 0, 0)
  love.graphics.circle("fill", board.x, board.y, innerBull)

  -- Outer bull
  love.graphics.setColor(1, 0.5, 0)
  love.graphics.circle("fill", board.x, board.y, outerBull)

  -- Inner scoring ring
  love.graphics.setColor(1, 1, 0)
  love.graphics.circle("fill", board.x, board.y, ring)

  -- Outer scoring ring
  love.graphics.setColor(0, 0, 1)
  love.graphics.circle("fill", board.x, board.y, outerRing)

  -- Border
  love.graphics.setColor(0, 0, 0)
  love.graphics.circle("line", board.x, board.y, board.radius, 32)
end
