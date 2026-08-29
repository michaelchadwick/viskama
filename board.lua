-- board.lua
local Board = {}
Board.__index = Board

-- ------------------------------------------------------------
--  Helper: draw text with a thin white outline
-- ------------------------------------------------------------
local function drawOutlinedText(txt, x, y, font, color)
  love.graphics.setFont(font)

  -- draw the outline in white
  love.graphics.setColor(1, 1, 1)
  local offsets = { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }
  for _, off in ipairs(offsets) do
    love.graphics.print(txt, x + off[1], y + off[2])
  end

  -- draw the real text
  love.graphics.setColor(unpack(color))
  love.graphics.print(txt, x, y)
end

-- constructor now receives the board configuration table
function Board.new(configBoard)
  local self                 = setmetatable({}, Board)

  self.x                     = 400
  self.y                     = 300
  self.radius                = configBoard.radius

  self.innerBull             = configBoard.innerBull
  self.outerBull             = configBoard.outerBull
  self.ring                  = configBoard.ring
  self.outerRing             = configBoard.outerRing

  self.score                 = {
    innerBull = configBoard.score.innerBull,
    outerBull = configBoard.score.outerBull
  }

  self.maxError              = configBoard.maxError
  self.maxForceMagnitude     = configBoard.maxForceMagnitude

  -- derived radii for the rings
  self.doubleRingWidth       = self.radius * 0.10
  self.doubleRingInnerRadius = self.radius - self.doubleRingWidth

  self.tripleRingWidth       = self.radius * 0.05
  self.tripleRingOuterRadius = self.doubleRingInnerRadius - self.tripleRingWidth
  self.tripleRingInnerRadius = self.tripleRingOuterRadius - self.tripleRingWidth

  self.colors                = configBoard.colors
  self.numbers               = { 20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5 }
  self.numberFont            = love.graphics.newFont(14)

  return self
end

----------------------------------------------------------------
--  draw – uses the colours from the config table
----------------------------------------------------------------
function Board:draw()
  love.graphics.push()
  love.graphics.translate(self.x, self.y)

  local segmentCount = 20
  local segmentAngle = math.rad(18)  -- 360° / 20
  local baseAngle    = math.rad(-90) -- 20 is at the top

  local colors       = self.colors

  -- helper: draw a ring sector (filled polygon)
  local function drawRingSector(startAngle, endAngle, innerR, outerR, color)
    local points = {}
    local steps = math.max(math.floor((endAngle - startAngle) / math.rad(2)), 2)
    for i = 0, steps do
      local a = startAngle + (endAngle - startAngle) * i / steps
      local x = outerR * math.cos(a)
      local y = outerR * math.sin(a)
      table.insert(points, x); table.insert(points, y)
    end
    for i = steps, 0, -1 do
      local a = startAngle + (endAngle - startAngle) * i / steps
      local x = innerR * math.cos(a)
      local y = innerR * math.sin(a)
      table.insert(points, x); table.insert(points, y)
    end
    love.graphics.setColor(color)
    love.graphics.polygon("fill", unpack(points))
  end

  -------------------------------------------------------
  -- 1. inner single area  (outer bull → triple‑inner)
  -------------------------------------------------------
  for i = 1, segmentCount do
    local startAngle = baseAngle + (i - 1) * segmentAngle
    local endAngle   = startAngle + segmentAngle
    local color      = (i % 2 == 1) and colors.innerSingle or colors.outerSingle
    drawRingSector(startAngle, endAngle,
      self.outerBull,             -- inner radius
      self.tripleRingInnerRadius, -- outer radius
      color)
  end

  -------------------------------------------------------
  -- 2. outer single area  (triple‑outer → double‑inner)
  -------------------------------------------------------
  for i = 1, segmentCount do
    local startAngle = baseAngle + (i - 1) * segmentAngle
    local endAngle   = startAngle + segmentAngle
    local color      = (i % 2 == 1) and colors.innerSingle or colors.outerSingle
    drawRingSector(startAngle, endAngle,
      self.tripleRingOuterRadius, -- inner radius
      self.doubleRingInnerRadius, -- outer radius
      color)
  end

  -------------------------------------------------------
  -- 3. triple ring – alternating red/green
  -------------------------------------------------------
  for i = 1, segmentCount do
    local startAngle = baseAngle + (i - 1) * segmentAngle
    local endAngle   = startAngle + segmentAngle
    local ringColor  = (i % 2 == 1) and colors.tripleRing or colors.doubleRing
    drawRingSector(startAngle, endAngle,
      self.tripleRingInnerRadius,
      self.tripleRingOuterRadius,
      ringColor)
  end

  -------------------------------------------------------
  -- 4. double ring – alternating red/green
  -------------------------------------------------------
  for i = 1, segmentCount do
    local startAngle = baseAngle + (i - 1) * segmentAngle
    local endAngle   = startAngle + segmentAngle
    local ringColor  = (i % 2 == 1) and colors.tripleRing or colors.doubleRing
    drawRingSector(startAngle, endAngle,
      self.doubleRingInnerRadius,
      self.radius,
      ringColor)
  end

  -------------------------------------------------------
  -- 5. outer rim (white)
  -------------------------------------------------------
  love.graphics.setColor(colors.outerRim)
  love.graphics.setLineWidth(3)
  love.graphics.circle("line", 0, 0, self.radius + 3)

  -------------------------------------------------------
  -- 6. bullseyes
  -------------------------------------------------------
  love.graphics.setColor(colors.innerBull)
  love.graphics.circle("fill", 0, 0, self.outerBull)
  love.graphics.setColor(colors.outerBull)
  love.graphics.circle("fill", 0, 0, self.innerBull)

  -------------------------------------------------------
  -- 7. numbers
  -------------------------------------------------------
  for i = 1, segmentCount do
    local angle = baseAngle + (i - 1) * segmentAngle + segmentAngle / 2
    local numberRadius = self.radius + 16
    local nx = numberRadius * math.cos(angle)
    local ny = numberRadius * math.sin(angle)
    local numStr = tostring(self.numbers[i])
    local w = self.numberFont:getWidth(numStr)
    local h = self.numberFont:getHeight()
    drawOutlinedText(numStr, nx - w / 2, ny - h / 2, love.graphics.newFont(16), colors.numbers)
  end

  love.graphics.pop()
end

----------------------------------------------------------------
--  scoring
----------------------------------------------------------------
function Board:calculateScore(pos)
  local dx = pos.x - self.x
  local dy = pos.y - self.y
  local dist = math.sqrt(dx * dx + dy * dy)

  if dist <= self.innerBull then return self.score.innerBull end
  if dist <= self.outerBull then return self.score.outerBull end
  local multiplier
  if dist <= self.tripleRingInnerRadius then     -- inner single
    multiplier = 1
  elseif dist <= self.tripleRingOuterRadius then -- triple
    multiplier = 3
  elseif dist <= self.doubleRingInnerRadius then -- outer single
    multiplier = 1
  elseif dist <= self.radius then                -- double
    multiplier = 2
  else
    return 0 -- missed the board
  end

  local angle = math.atan2(dx, -dy) -- dx, -dy rotates the system
  if angle < 0 then angle = angle + 2 * math.pi end

  local sectorIndex = math.floor(angle / (2 * math.pi / 20)) + 1
  local sectorValue = self.numbers[sectorIndex] or 0

  return sectorValue * multiplier
end

return Board
