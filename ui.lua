-- ui.lua
local UI = {}
UI.__index = UI

----------------------------------------------------------------
--  ctor – receives the whole configuration table
----------------------------------------------------------------
function UI.new(config)
  local self = setmetatable({}, UI)

  self.titleFont = love.graphics.newFont(config.ui.titleFontSize)
  self.smallFont = love.graphics.newFont(config.ui.smallFontSize)

  self.colors = config.ui.colors
  return self
end

----------------------------------------------------------------
--  Title screen
----------------------------------------------------------------
function UI:drawTitle()
  love.graphics.clear(unpack(self.colors.background))
  love.graphics.setColor(unpack(self.colors.title))
  love.graphics.setFont(self.titleFont)
  love.graphics.printf("Viskama", 0, 200, love.graphics.getWidth(), "center")
  love.graphics.setFont(self.smallFont)
  love.graphics.printf("Click, touch, or press any key to begin", 0, 260, love.graphics.getWidth(), "center")
end

----------------------------------------------------------------
--  Overlay (game‑over) – drawn over the main screen
----------------------------------------------------------------
function UI:drawOverlay(finalScore)
  love.graphics.setColor(unpack(self.colors.overlay))
  love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

  love.graphics.setColor(unpack(self.colors.title))
  love.graphics.setFont(self.titleFont)
  love.graphics.printf("Final Score: " .. finalScore, 0, 200, love.graphics.getWidth(), "center")

  local msg = finalScore > 200 and "You win!" or "You lose!"
  love.graphics.setFont(self.smallFont)
  love.graphics.printf(msg, 0, 260, love.graphics.getWidth(), "center")
  love.graphics.printf("Click, touch, or press any key to play again", 0, 320, love.graphics.getWidth(), "center")
end

----------------------------------------------------------------
--  Score screen (used only for debug, can be removed)
----------------------------------------------------------------
function UI:drawScore(finalScore)
  love.graphics.setColor(unpack(self.colors.overlay))
  love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

  love.graphics.setColor(unpack(self.colors.title))
  love.graphics.setFont(self.titleFont)
  love.graphics.printf("Final Score: " .. finalScore, 0, 200, love.graphics.getWidth(), "center")

  local msg = finalScore > 200 and "You win!" or "You lose!"
  love.graphics.setColor(unpack(self.colors.title))
  love.graphics.setFont(self.smallFont)
  love.graphics.printf(msg, 0, 260, love.graphics.getWidth(), "center")
  love.graphics.printf("Click, touch, or press any key to return", 0, 320, love.graphics.getWidth(), "center")
end

return UI
