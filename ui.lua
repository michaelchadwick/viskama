-- ui.lua
local UI = {}
UI.__index = UI

----------------------------------------------------------------
--  ctor – receives the whole configuration table
----------------------------------------------------------------
function UI.new(config)
  local self = setmetatable({}, UI)

  self.title = config.game.title
  self.titleFont = love.graphics.newFont(config.ui.titleFontSize)
  self.smallFont = love.graphics.newFont(config.ui.smallFontSize)

  self.retryText = config.game.text.retry
  self.startText = config.game.text.start

  self.loseText = config.game.text.lose
  self.winText = config.game.text.win

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
  love.graphics.printf(self.title, 0, 200, love.graphics.getWidth(), "center")
  love.graphics.setFont(self.smallFont)
  love.graphics.printf(self.startText, 0, 260, love.graphics.getWidth(), "center")
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

  local msg = finalScore > 200 and self.winText or self.loseText
  love.graphics.setFont(self.smallFont)
  love.graphics.printf(msg, 0, 260, love.graphics.getWidth(), "center")
  love.graphics.printf(self.retryText, 0, 320, love.graphics.getWidth(), "center")
end

return UI
