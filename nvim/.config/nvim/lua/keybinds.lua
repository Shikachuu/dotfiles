require('functions.git')

vim.api.nvim_set_keymap('n', '<leader>fs', ':Telescope grep_string<CR>', { noremap = true, desc = '[f]ind [s]tring' })
vim.api.nvim_set_keymap('n', '<leader>fa', ':Telescope live_grep<CR>', { noremap = true, desc = '[f]ind [s]tring' })
vim.api.nvim_set_keymap('n', '<leader>ff', ':Telescope find_files<CR>', { noremap = true, desc = '[f]ind [f]iles' })

vim.api.nvim_set_keymap('n', '<leader>Gcs', ':Telescope git_commits<CR>', { noremap = true, desc = '[G]it [c]ommits' })
vim.api.nvim_set_keymap('n', '<leader>Gb', ':Telescope git_branches<CR>', { noremap = true, desc = '[G]it [b]ranches' })
vim.keymap.set('n', '<leader>Gp', Git_push, { noremap = true, desc = '[G]it [p]ush' })
vim.api.nvim_set_keymap('n', '<leader>Gh', ':Gitsigns toggle_current_line_blame<CR>',
    { noremap = true, desc = '[G]it [h]istory' })
vim.keymap.set('n', '<leader>Gc', Git_commit, { noremap = true, silent = true, desc = '[g]it [c]ommit' })

vim.api.nvim_set_keymap('n', '<C-f>', ':Telescope current_buffer_fuzzy_find<CR>', { noremap = true, desc = '[F]ind' })

vim.api.nvim_set_keymap('n', '<leader>tt', ':sp term://bash<CR>', { noremap = true, desc = '[tt]erminal' })

vim.api.nvim_set_keymap('n', '<leader>sk', ":Telescope keymaps<CR>", { noremap = true, desc = '[s]earch [k]eymaps' })

vim.api.nvim_set_keymap('n', '<leader><TAB>', ":Telescope buffers<CR>", { noremap = true, desc = 'show open buffers' })

vim.keymap.set('n', '<C-S-Up>', ':m -2<CR>', { noremap = true, desc = 'move line up', silent = true })
vim.keymap.set('n', '<C-S-Down>', ':m +1<CR>', { noremap = true, desc = 'move line down', silent = true })

vim.keymap.set('n', '<leader>spv', ':vsplit<CR>', { noremap = true, desc = '[s][p]lit [v]ertical', silent = true })
vim.keymap.set('n', '<leader>sph', ':split<CR>', { noremap = true, desc = '[s][p]lit [h]orizontal', silent = true })

vim.keymap.set('x', '<leader>es', ':Refactor extract<CR>', { noremap = true, desc = '[e]xtract [s]cope' })
vim.keymap.set('x', '<leader>ev', ':Refactor extract_var<CR>', { noremap = true, desc = '[e]xtract [v]ariable' })
vim.keymap.set({ 'n', 'x' }, '<leader>iv', ':Refactor inline_var<CR>', { noremap = true, desc = '[i]line [v]ariable' })

vim.keymap.set('n', '<C-Q>', ':bd<CR>', { noremap = true, desc = '[q]uit current tab', silent = true })

vim.keymap.set('n', '<leader>!', 'za', { noremap = true, desc = 'toggle fold under cursor', silent = true })
vim.keymap.set('n', '<leader>.', 'zA', { noremap = true, desc = 'toggle all fold in file', silent = true })
