-- main.lua
-- Entry point – forwards Love2D callbacks to the modules

local Board                     = require "board"
local Game                      = require "game"
local UI                        = require "ui"
local config                    = require "config"

local windowWidth, windowHeight = config.game.windowWidth, config.game.windowHeight

local game -- will hold the Game instance
local ui   -- will hold the UI instance
local fileModTimes              = {}

----------------------------------------------------------------
--  Reload a module and return success status
----------------------------------------------------------------
local function reloadModule(name)
  package.loaded[name] = nil
  local ok, mod = pcall(require, name)
  if not ok then
    print("Error reloading module '" .. name .. "': " .. tostring(mod))
  end
  return ok
end

----------------------------------------------------------------
--  Watch files for changes – call this each frame
----------------------------------------------------------------
local function watchFiles()
  for name, _ in pairs(package.loaded) do
    if type(name) == "string" and name ~= "main" then
      local path = name:gsub("%.", "/") .. ".lua"
      local info = love.filesystem.getInfo(path)
      if info then
        local last = fileModTimes[path]
        if not last or info.modtime > last then
          fileModTimes[path] = info.modtime
          if reloadModule(name) then
            -- re‑import updated modules and rebuild everything
            if name == "board" then
              Board = require "board"
            elseif name == "game" then
              Game = require "game"
            elseif name == "ui" then
              UI = require "ui"
            end
            local board = Board.new(config.board)
            game        = Game.new(board, config)
            ui          = UI.new(config)
          end
        end
      end
    end
  end
end

-----------------------------------------------------------------------
-- LOVE2D callbacks
-----------------------------------------------------------------------
function love.load()
  love.window.setTitle(config.game.title)
  love.window.setMode(windowWidth, windowHeight, { resizable = false, vsync = true })
  math.randomseed(os.time())

  local board = Board.new(config.board)
  game        = Game.new(board, config)
  ui          = UI.new(config)
end

function love.update(dt)
  game:update(dt)
  -- comment out the next line for actual production
  watchFiles(dt)
end

-- draw ------------------------------------------------------------
function love.draw()
  if game.state == "title" then
    ui:drawTitle()
  else
    game:draw()                  -- always show the board & darts
    if game.state == "over" then -- overlay only when finished
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
    game:reset() -- restart the round (stay in play)
  end
end

-----------------------------------------------------------------------
-- Forward all other input to the Game module
-----------------------------------------------------------------------
function love.mousepressed(x, y, button, istouch, presses)
  if button == 1 then
    if game.state == "title" or game.state == "over" then
      game:reset()
    else
      game:mousepressed(x, y, button)
    end
  end
end

function love.mousemoved(x, y, dx, dy, istouch)
  game:mousemoved(x, y, dx, dy)
end

function love.mousereleased(x, y, button, istouch, presses)
  game:mousereleased(x, y, button)
end

function love.touchpressed(id, x, y, dx, dy, pressure)
  if game.state == "title" or game.state == "over" then
    game:reset()
  else
    game:touchpressed(id, x, y, dx, dy, pressure)
  end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
  game:touchmoved(id, x, y, dx, dy, pressure)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
  game:touchreleased(id, x, y, dx, dy, pressure)
end

function love.joystickpressed(joy, button)
  if button == 1 then
    if game.state == "title" or game.state == "over" then
      game:reset()
    else
      game:joystickpressed(joy, button)
    end
  end
end

function love.joystickaxis(joy, axis, value)
  game:joystickaxis(joy, axis, value)
end

function love.joystickreleased(joy, button)
  game:joystickreleased(joy, button)
end
