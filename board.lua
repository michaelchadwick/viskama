-- board.lua
-- Holds the dartboard geometry and scoring logic

local Board = {}
Board.__index = Board

-- -------------------------------------------------------
--  Board.new – set the bullseye radii to a much smaller size
-- -------------------------------------------------------
function Board.new(x, y, radius)
  local self                 = setmetatable({}, Board)

  self.x                     = x or 400
  self.y                     = y or 300
  self.radius                = radius or 200

  -- ----------------------------------------
  --  Bullseye radii (much smaller now)
  -- ----------------------------------------
  self.innerBull             = self.radius * 0.04 -- ~8 px for a 200‑px board
  self.outerBull             = self.radius * 0.09 -- ~18 px

  -- ----------------------------------------
  --  Derived radii for the rings
  -- ----------------------------------------
  self.doubleRingWidth       = self.radius * 0.10
  self.doubleRingInnerRadius = self.radius - self.doubleRingWidth

  self.tripleRingWidth       = self.radius * 0.05
  self.tripleRingOuterRadius = self.doubleRingInnerRadius - self.tripleRingWidth
  self.tripleRingInnerRadius = self.tripleRingOuterRadius - self.tripleRingWidth

  -- ----------------------------------------
  --  Score‑related radii (used by calculateScore)
  -- ----------------------------------------
  self.ring                  = self.tripleRingInnerRadius -- inner single area
  self.outerRing             = self.radius       -- outer single area (double ring)

  -- ----------------------------------------
  --  Misc. (used for error jitter)
  -- ----------------------------------------
  self.maxError              = 12 -- maximum random offset (pixels)

  -- number font
  self.numberFont            = love.graphics.newFont(14)

  return self
end

-- -------------------------------------------------------
--  Board:draw – realistic dartboard with alternating
--  red/green colors for the triple and double rings,
--  light‑grey numbers, and a small green‑red bullseye
-- -------------------------------------------------------
function Board:draw()
  love.graphics.push()
  love.graphics.translate(self.x, self.y)

  local segmentCount = 20
  local segmentAngle = math.rad(18)  -- 360° / 20
  local baseAngle    = math.rad(-97) -- 20 is at the top (97 instead of 90 to better align numbers)

  -- base colors
  local colorA       = { 0.1, 0.1, 0.1 } -- dark gray
  local colorB       = { 0.8, 0.6, 0.2 } -- orange‑ish
  local colorRed     = { 0.7, 0, 0 }
  local colorGreen   = { 0, 0.7, 0 }

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
    local color      = (i % 2 == 1) and colorA or colorB
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
    local color      = (i % 2 == 1) and colorA or colorB
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
    local ringColor  = (i % 2 == 1) and colorRed or colorGreen
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
    local ringColor  = (i % 2 == 1) and colorRed or colorGreen
    drawRingSector(startAngle, endAngle,
      self.doubleRingInnerRadius,
      self.radius,
      ringColor)
  end

  -------------------------------------------------------
  -- 5. outer rim (white)
  -------------------------------------------------------
  love.graphics.setColor(1, 1, 1)
  love.graphics.setLineWidth(3)
  love.graphics.circle("line", 0, 0, self.radius + 3)

  -------------------------------------------------------
  -- 6. bullseye – small green outer bull, tiny red inner bull
  -------------------------------------------------------
  love.graphics.setColor(0, 1, 0) -- green outer bull
  love.graphics.circle("fill", 0, 0, self.outerBull)
  love.graphics.setColor(1, 0, 0) -- red inner bull
  love.graphics.circle("fill", 0, 0, self.innerBull)

  -------------------------------------------------------
  -- 7. numbers – light grey, positioned just outside the rim
  -------------------------------------------------------
  local numbers = { 20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5 }
  love.graphics.setColor(0.95, 0.95, 0.95) -- light grey
  for i = 1, segmentCount do
    local angle = (baseAngle + (i - 1) * segmentAngle + segmentAngle / 2)
    local numberRadius = self.radius + 10
    local nudgeAmount = 6 -- to better align numbers
    local nx = numberRadius * math.cos(angle) - nudgeAmount
    local ny = numberRadius * math.sin(angle) - nudgeAmount / 2
    local numStr = tostring(numbers[i])
    local w = self.numberFont:getWidth(numStr)
    local h = self.numberFont:getHeight()
    love.graphics.print(numStr, nx - w / 2, ny - h / 2)
  end

  love.graphics.pop()
end

----------------------------------------------------------------
-- Simple radial scoring
----------------------------------------------------------------
function Board:calculateScore(pos)
  local dx = pos.x - self.x
  local dy = pos.y - self.y
  local dist = math.sqrt(dx * dx + dy * dy)

  if dist <= self.innerBull then
    return 100
  elseif dist <= self.outerBull then
    return 75
  elseif dist <= self.ring then
    return 50
  elseif dist <= self.outerRing then
    return 25
  else
    return 0
  end
end

return Board
