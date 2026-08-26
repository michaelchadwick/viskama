-- board.lua
-- Holds the dartboard geometry and scoring logic

local Board = {}
Board.__index = Board

-- -------------------------------------------------------
--  Board.new – add derived radii for a realistic board
-- -------------------------------------------------------
function Board.new(x, y, radius)
  local self                 = setmetatable({}, Board)

  self.x                     = x or 400
  self.y                     = y or 300
  self.radius                = radius or 200

  -- existing scoring radii
  self.innerBull             = 30
  self.outerBull             = 60
  self.ring                  = 90
  self.outerRing             = 200

  -- **RE‑ADD maxError for throw‑accuracy calculation**
  self.maxError              = 12

  -- ------------------------------------------------------------------
  --  Derived radii for drawing a realistic board
  --  These are *not* used for scoring – they only affect the look.
  -- ------------------------------------------------------------------
  self.doubleRingWidth       = self.radius * 0.10  -- 10 % of radius
  self.doubleRingInnerRadius = self.radius - self.doubleRingWidth

  self.tripleRingWidth       = self.radius * 0.05  -- 5 % of radius
  self.tripleRingOuterRadius = self.doubleRingInnerRadius - self.tripleRingWidth
  self.tripleRingInnerRadius = self.tripleRingOuterRadius - self.tripleRingWidth

  -- number font (cached so we don’t recreate each frame)
  self.numberFont            = love.graphics.newFont(14)

  return self
end

-- -------------------------------------------------------
--  Board:draw – realistic board with alternating colors,
--  triple & double rings, and numbered segments
-- -------------------------------------------------------
function Board:draw()
  love.graphics.push()
  love.graphics.translate(self.x, self.y)

  local segmentCount = 20
  local segmentAngle = math.rad(18)  -- 360° / 20
  local baseAngle    = math.rad(-90) -- 20 is at the top

  -- colors
  local colorA       = { 0.1, 0.1, 0.1 } -- dark gray
  local colorB       = { 0.8, 0.6, 0.2 } -- orange‑ish
  local colorTriple  = { 0.9, 0.5, 0.1 } -- orange for the triple ring
  local colorDouble  = { 0, 0, 0 }       -- black for the double ring

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
    -- **CHANGED LINE** – use `unpack` instead of `table.unpack`
    love.graphics.polygon("fill", unpack(points))
  end


  -------------------------------------------------------
  -- 1. main single area (inner + outer single) – alternating colors
  -------------------------------------------------------
  for i = 1, segmentCount do
    local startAngle = baseAngle + (i - 1) * segmentAngle
    local endAngle   = startAngle + segmentAngle
    local color      = (i % 2 == 1) and colorA or colorB
    drawRingSector(startAngle, endAngle,
      self.outerBull, -- inner radius (outer bull)
      self.radius,    -- outer radius (board edge)
      color)
  end

  -------------------------------------------------------
  -- 2. triple ring – thin orange strip
  -------------------------------------------------------
  for i = 1, segmentCount do
    local startAngle = baseAngle + (i - 1) * segmentAngle
    local endAngle   = startAngle + segmentAngle
    drawRingSector(startAngle, endAngle,
      self.tripleRingInnerRadius,
      self.tripleRingOuterRadius,
      colorTriple)
  end

  -------------------------------------------------------
  -- 3. double ring – thick black strip
  -------------------------------------------------------
  for i = 1, segmentCount do
    local startAngle = baseAngle + (i - 1) * segmentAngle
    local endAngle   = startAngle + segmentAngle
    drawRingSector(startAngle, endAngle,
      self.doubleRingInnerRadius,
      self.radius,
      colorDouble)
  end

  -------------------------------------------------------
  -- 4. segment numbers (white)
  -------------------------------------------------------
  local numbers = { 20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5 }
  love.graphics.setFont(self.numberFont)
  for i = 1, segmentCount do
    local angle = baseAngle + (i - 1) * segmentAngle + segmentAngle / 2
    local radiusNumber = self.radius - 10 -- a bit inside the outer ring
    local nx = radiusNumber * math.cos(angle)
    local ny = radiusNumber * math.sin(angle)
    local numStr = tostring(numbers[i])
    local w = self.numberFont:getWidth(numStr)
    local h = self.numberFont:getHeight()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(numStr, nx - w / 2, ny - h / 2)
  end

  -------------------------------------------------------
  -- 5. bullseyes (red inner, green outer)
  -------------------------------------------------------
  love.graphics.setColor(1, 0, 0) -- inner bull
  love.graphics.circle("fill", 0, 0, self.innerBull)
  love.graphics.setColor(0, 1, 0) -- outer bull
  love.graphics.circle("fill", 0, 0, self.outerBull)

  -------------------------------------------------------
  -- 6. outer board outline
  -------------------------------------------------------
  love.graphics.setColor(0, 0, 0)
  love.graphics.setLineWidth(2)
  love.graphics.circle("line", 0, 0, self.radius)

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
