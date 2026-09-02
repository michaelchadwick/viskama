-- main.lua
-- Entry point – forwards Love2D callbacks to the modules

local Board                     = require "board"
local Game                      = require "game"
local UI                        = require "ui"
local config                    = require "config"

local windowWidth, windowHeight = config.game.windowWidth, config.game.windowHeight

local fileModTimes              = {}

game                            = nil
ui                              = nil

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

  local board           = Board.new(config.board)
  game                  = Game.new(board, config)
  ui                    = UI.new(config)

  local events          = require "events"

  love.keypressed       = events.keypressed
  love.mousepressed     = events.mousepressed
  love.mousemoved       = events.mousemoved
  love.mousereleased    = events.mousereleased
  love.touchpressed     = events.touchpressed
  love.touchmoved       = events.touchmoved
  love.touchreleased    = events.touchreleased
  love.joystickpressed  = events.joystickpressed
  love.joystickaxis     = events.joystickaxis
  love.joystickreleased = events.joystickreleased
end

function love.update(dt)
  game:update(dt)
  -- comment out the next line for actual production
  if config.env == 'development' then
    watchFiles(dt)
  end
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
