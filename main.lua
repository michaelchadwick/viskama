-- main.lua
-- Entry point – forwards Love2D callbacks to the modules

local Board                     = require "board"
local Game                      = require "game"
local UI                        = require "ui"

local windowWidth, windowHeight = 800, 600

-- The UI module creates its own fonts, but the game needs a small font for
-- the in‑game HUD.  We create it here and pass it explicitly to `Game`.
local smallFont                 = love.graphics.newFont(24)

local game -- will hold the Game instance
local ui   -- will hold the UI instance

-----------------------------------------------------------------------
-- LOVE2D callbacks
-----------------------------------------------------------------------
function love.load()
  love.window.setTitle("Viskama")
  love.window.setMode(windowWidth, windowHeight, { resizable = false, vsync = true })
  math.randomseed(os.time())

  local board = Board.new(windowWidth / 2, windowHeight / 2, 200)
  game        = Game.new(board, smallFont) -- pass the font to Game
  ui          = UI.new()
end

function love.update(dt)
  game:update(dt)
end

-- draw ------------------------------------------------------------
function love.draw()
  if game.state == "title" then
    ui:drawTitle()
  else
    game:draw()                      -- always show the board & darts
    if game.state == "over" then     -- overlay only when finished
      ui:drawOverlay(game.totalScore)
    end
  end
end

-- keypressed -------------------------------------------------------
function love.keypressed(key, scancode, isrepeat)
  if key == "escape" then
    love.event.quit()
  elseif game.state == "title" then
    game:reset()
  elseif game.state == "over" then
    game:reset()     -- restart the round (stay in play)
  end
end

-----------------------------------------------------------------------
-- Forward all other input to the Game module
-----------------------------------------------------------------------
function love.mousepressed(x, y, button, istouch, presses)
  game:mousepressed(x, y, button)
end

function love.mousemoved(x, y, dx, dy, istouch)
  game:mousemoved(x, y, dx, dy)
end

function love.mousereleased(x, y, button, istouch, presses)
  game:mousereleased(x, y, button)
end

function love.touchpressed(id, x, y, dx, dy, pressure)
  game:touchpressed(id, x, y, dx, dy, pressure)
end

function love.touchmoved(id, x, y, dx, dy, pressure)
  game:touchmoved(id, x, y, dx, dy, pressure)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
  game:touchreleased(id, x, y, dx, dy, pressure)
end

function love.joystickpressed(joy, button)
  game:joystickpressed(joy, button)
end

function love.joystickaxis(joy, axis, value)
  game:joystickaxis(joy, axis, value)
end

function love.joystickreleased(joy, button)
  game:joystickreleased(joy, button)
end
