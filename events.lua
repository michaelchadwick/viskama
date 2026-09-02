-- events.lua
-- All Love2D event callbacks.  They use the global `game` object
-- that is created in main.lua.

local M = {}

function M.keypressed(key, scancode, isrepeat)
  if key == "escape" then
    love.event.quit()
  elseif game.state == "title" then
    game:reset()
  elseif game.state == "over" then
    game:reset() -- restart the round
  end
end

function M.mousepressed(x, y, button, istouch, presses)
  if button == 1 then
    if game.state == "title" or game.state == "over" then
      game:reset()
    else
      game:mousepressed(x, y, button)
    end
  end
end

function M.mousemoved(x, y, dx, dy, istouch)
  game:mousemoved(x, y, dx, dy)
end

function M.mousereleased(x, y, button, istouch, presses)
  game:mousereleased(x, y, button)
end

function M.touchpressed(id, x, y, dx, dy, pressure)
  if game.state == "title" or game.state == "over" then
    game:reset()
  else
    game:touchpressed(id, x, y, dx, dy, pressure)
  end
end

function M.touchmoved(id, x, y, dx, dy, pressure)
  game:touchmoved(id, x, y, dx, dy, pressure)
end

function M.touchreleased(id, x, y, dx, dy, pressure)
  game:touchreleased(id, x, y, dx, dy, pressure)
end

function M.joystickpressed(joy, button)
  if button == 1 then
    if game.state == "title" or game.state == "over" then
      game:reset()
    else
      game:joystickpressed(joy, button)
    end
  end
end

function M.joystickaxis(joy, axis, value)
  game:joystickaxis(joy, axis, value)
end

function M.joystickreleased(joy, button)
  game:joystickreleased(joy, button)
end

return M
