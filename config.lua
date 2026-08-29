-- config.lua
-- Centralised configuration for board, dart, and UI

return {
  board = {
    radius            = 200,
    innerBull         = 10,
    outerBull         = 20,
    ring              = 90,  -- inner single
    outerRing         = 200, -- outer single (double ring edge)
    maxError          = 12,  -- max random offset (px)
    maxForceMagnitude = 400, -- used to normalise drag length

    colors            = {
      background  = { 0.05, 0.05, 0.15 },
      boardBg     = { 0.8, 0.8, 0.8 },
      innerBull   = { 0.22, 0.573, 0.204 },
      outerBull   = { 0.91, 0.184, 0.153 },
      innerSingle = { 0.1, 0.1, 0.1 },
      outerSingle = { 0.98, 0.89, 0.725 },
      tripleRing  = { 0.91, 0.184, 0.153 },
      doubleRing  = { 0.22, 0.573, 0.204 },
      outerRim    = { 1, 1, 1 },
      numbers     = { 0.8, 0.8, 0.8 },
      floor       = { 0.5, 0.5, 0.5 }
    }
  },

  dart = {
    speed          = 400,
    duration       = 0.6,
    scaleStart     = 0.2,
    scalePeak      = 1.0,
    scaleEnd       = 0.2,
    crossSize      = 12,
    crossColor     = { 1, 0.9, 0 },
    crossLineWidth = 4
  },

  ui = {
    titleFontSize = 48,
    smallFontSize = 24,
    colors        = {
      background = { 0.05, 0.05, 0.05 },
      title      = { 1, 1, 1 },
      hud        = { 1, 1, 1 },
      overlay    = { 0, 0, 0, 0.7 }
    }
  }
}
