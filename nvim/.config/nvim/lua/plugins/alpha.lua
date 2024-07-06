return {
  'goolord/alpha-nvim',
  dependencies = { 'kyazdani42/nvim-web-devicons' },
  config = function()
    local dashboard = require('alpha.themes.dashboard')

    math.randomseed(os.time())

    local function meme()
      local memes = { 'bóbr', 'poczekaj', 'ratatuj', 'pingwin', 'panda', 'homik', 'jeżek', 'skunks', 'užik',
        'jeleń' }
      return memes[math.random(#memes)]
    end

    dashboard.section.header.val = {
      [[                      _           ]],
      [[                     (_)          ]],
      [[ _ __   ___    __   ___ _ __ ___  ]],
      [[| '_ \ / _ \   \ \ / / | '_ ` _ \ ]],
      [[| | | | (_) |   \ V /| | | | | | |]],
      [[|_| |_|\___( )   \_/ |_|_| |_| |_|]],
      [[           |/                     ]]
    }
    dashboard.section.buttons.val = {
      dashboard.button('n', 'new', '<cmd>ene <CR>'),
      dashboard.button('r', 'recent', ":Telescope oldfiles<CR>"),
      dashboard.button('q', 'quit', ':qa<CR>'),
    }
    dashboard.section.footer.val = { meme() }
    require('alpha').setup(dashboard.opts)
  end,
}
-- vim: ts=2 sts=2 sw=2 et
