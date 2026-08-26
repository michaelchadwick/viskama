-- ui.lua
-- Handles the title screen and final score screen

local UI = {}
UI.__index = UI

function UI.new()
  local self = setmetatable({}, UI)
  self.titleFont = love.graphics.newFont(48)
  self.smallFont = love.graphics.newFont(24)
  return self
end

----------------------------------------------------------------
-- Title screen
----------------------------------------------------------------
function UI:drawTitle()
  love.graphics.setBackgroundColor(0.05, 0.05, 0.05)
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(self.titleFont)
  love.graphics.printf("Viskama", 0, 200, love.graphics.getWidth(), "center")
  love.graphics.setFont(self.smallFont)
  love.graphics.printf("Press any key to begin", 0, 260, love.graphics.getWidth(), "center")
end

----------------------------------------------------------------
-- Final score screen
----------------------------------------------------------------
function UI:drawScore(finalScore)
  love.graphics.setBackgroundColor(0.05, 0.05, 0.05)
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(self.titleFont)
  love.graphics.printf("Final Score: " .. finalScore, 0, 200, love.graphics.getWidth(), "center")

  local msg = "You lose!"
  if finalScore > 200 then
    msg = "You win!"
  end
  love.graphics.setFont(self.smallFont)
  love.graphics.printf(msg, 0, 260, love.graphics.getWidth(), "center")
  love.graphics.printf("Press any key to return", 0, 320, love.graphics.getWidth(), "center")
end

return UI
