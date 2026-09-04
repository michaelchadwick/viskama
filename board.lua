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

  self.centerX               = configBoard.center.x
  self.centerY               = configBoard.center.y
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

  self.tripleRingWidth       = self.radius * 0.04 -- ~4 % of radius
  self.tripleRingInnerRadius = self.outerBull + self.radius * 0.40
  self.tripleRingOuterRadius = self.tripleRingInnerRadius + self.tripleRingWidth

  self.colors                = configBoard.colors
  self.numbers               = configBoard.numbers
  self.numberFont            = love.graphics.newFont(configBoard.numberFontSize)

  return self
end

----------------------------------------------------------------
--  draw – uses the colours from the config table
----------------------------------------------------------------
function Board:draw()
  love.graphics.push()
  love.graphics.translate(self.centerX, self.centerY)

  local segmentCount     = 20
  local segmentAngle     = math.rad(18)  -- 360° / 20
  local baseAngle        = math.rad(-90) -- 20 is at the top
  local halfSegmentAngle = math.rad(9)   -- 360° / 40  (half of 18°)

  local colors           = self.colors

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
    local startAngle = baseAngle + (i - 1) * segmentAngle + halfSegmentAngle
    local endAngle   = startAngle + segmentAngle
    local color      = (i % 2 == 1) and colors.innerSingle or colors.outerSingle
    drawRingSector(startAngle, endAngle,
      self.outerBull,
      self.tripleRingInnerRadius,
      color)
  end

  -------------------------------------------------------
  -- 2. outer single area  (triple‑outer → double‑inner)
  -------------------------------------------------------
  for i = 1, segmentCount do
    local startAngle = baseAngle + (i - 1) * segmentAngle + halfSegmentAngle
    local endAngle   = startAngle + segmentAngle
    local color      = (i % 2 == 1) and colors.innerSingle or colors.outerSingle
    drawRingSector(startAngle, endAngle,
      self.tripleRingOuterRadius,
      self.doubleRingInnerRadius,
      color)
  end

  -------------------------------------------------------
  -- 3. triple ring – alternating red/green
  -------------------------------------------------------
  for i = 1, segmentCount do
    local startAngle = baseAngle + (i - 1) * segmentAngle + halfSegmentAngle
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
    local startAngle = baseAngle + (i - 1) * segmentAngle + halfSegmentAngle
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
    local angle = baseAngle + (i - 1) * segmentAngle
    local numberRadius = self.radius + 20
    local nx = numberRadius * math.cos(angle)
    local ny = numberRadius * math.sin(angle)

    local numStr = tostring(self.numbers[i])
    local w = self.numberFont:getWidth(numStr)
    local h = self.numberFont:getHeight()

    drawOutlinedText(numStr, nx - w / 2, ny - h / 2,
      self.numberFont, colors.numbers)
  end

  love.graphics.pop()
end

-- Returns two values:
--   score  – numeric score (0 if missed)
--   text   – printable label, e.g. "T20", "IB50", "M0"
function Board:scoreFromPosition(pos)
  local cx, cy = self.centerX, self.centerY
  local dx, dy = pos.x - cx, pos.y - cy
  local r = math.sqrt(dx * dx + dy * dy)

  if r > self.radius then
    return 0, "M0"
  end

  if r <= self.innerBull then
    return self.score.innerBull, "IB50"
  elseif r <= self.outerBull then
    return self.score.outerBull, "OB25"
  end

  local multiplier
  if r <= self.ring then
    multiplier = 1
  elseif r <= self.tripleRingInnerRadius then
    multiplier = 3
  elseif r <= self.doubleRingInnerRadius then
    multiplier = 1
  else
    multiplier = 2
  end

  local deg       = math.deg(math.atan2(dy, dx)) -- 0° at +x, CCW
  deg             = (deg + 99) % 360             -- rotate to top

  local sectorIdx = math.floor(deg / 18) + 1
  local sectorVal = self.numbers[sectorIdx]

  local score     = sectorVal * multiplier
  local prefix    = (multiplier == 3 and "T") or
      (multiplier == 2 and "D") or
      (multiplier == 1 and "S")

  return score, prefix .. sectorVal
end

return Board
