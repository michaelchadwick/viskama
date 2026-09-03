-- config.lua
-- Centralised configuration for board, dart, and UI

return {
  env = 'development',

  game = {
    maxThrows    = 10,
    text         = {
      lose  = "You lose :(",
      retry = "Click, touch, or press any key to try again",
      start = "Click, touch, or press any key to begin",
      win   = "You win!"
    },
    title        = "Viskama",
    windowWidth  = 800,
    windowHeight = 600,
  },

  board = {
    numberFontSize    = 16,
    radius            = 200,
    innerBull         = 10,
    outerBull         = 20,
    ring              = 90,  -- inner single
    outerRing         = 200, -- outer single (double ring edge)
    maxError          = 12,  -- max random offset (px)
    maxForceMagnitude = 400, -- used to normalise drag length
    numbers           = { 20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5 },

    center            = {
      x = 400,
      y = 300,
      radius = 200
    },

    colors            = {
      background  = { 0.05, 0.05, 0.15 },
      boardBg     = { 0.8, 0.8, 0.8 },
      innerBull   = { 0.22, 0.573, 0.204 },
      outerBull   = { 0.91, 0.184, 0.153 },
      innerSingle = { 0.1, 0.1, 0.1 },
      outerSingle = { 0.98, 0.89, 0.725 },
      tripleRing  = { 0.22, 0.573, 0.204 },
      doubleRing  = { 0.91, 0.184, 0.153 },
      outerRim    = { 1, 1, 1 },
      numbers     = { 0.8, 0.8, 0.8 },
      floor       = { 0.5, 0.5, 0.5 }
    },

    score             = {
      innerBull = 50,
      outerBull = 25
    },
  },

  dart = {
    speed          = 400,
    duration       = 0.6,
    scaleStart     = 0.2,
    scalePeak      = 1.0,
    scaleEnd       = 0.2,
    crossSize      = 8,
    crossLineWidth = 2,
    colors         = {
      cross        = { 1, 1, 1 },
      crossOutline = { 0.1, 0.1, 0.1 },
      unholdDot    = { 0, 0, 1 },
      holdDot      = { 0, 1, 0 },
      dragLine     = { 0, 0.5, 0 },
      shaft        = { 0.6, 0.6, 0.6 },
      tip          = { 1, 0, 0 }
    }
  },

  ui = {
    titleFontSize = 48,
    smallFontSize = 20,
    debugFontSize = 14,
    colors        = {
      background = { 0.05, 0.05, 0.05 },
      text       = { 1, 1, 1 },
      title      = { 1, 1, 1 },
      highlight  = { 1, 0.9, 0 },
      hud        = { 1, 1, 1 },
      overlay    = { 0, 0, 0, 0.7 },
      forceBox   = { 0.3, 0.3, 0.3, 0.8 },
      forceMeter = { 0, 1, 0, 0.8 }
    }
  }
}
