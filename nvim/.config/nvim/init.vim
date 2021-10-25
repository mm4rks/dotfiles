set path+=**

" Nice menu when typing `:find *.py`
set wildmode=longest,list,full
set wildmenu
" Ignore files
set wildignore+=*.pyc
set wildignore+=*_build/*
set wildignore+=**/coverage/*
set wildignore+=**/node_modules/*
set wildignore+=**/ios/*
set wildignore+=**/android/*
set wildignore+=**/.git/*

syntax enable
set guicursor=
set noshowmatch
set relativenumber
set nohlsearch
set hidden
set noerrorbells
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set nu
set nowrap
set smartcase
set noswapfile
set nobackup
set nowritebackup
set undodir=~/.vim/undodir
set undofile
set incsearch
set termguicolors
set scrolloff=8
set mouse=a
set spelllang=en
set spell
set encoding=UTF-8
" set shellcmdflag=-ic

" Give more space for displaying messages.
set cmdheight=2

" Having longer update time (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=50

" Don't pass messages to |ins-completion-menu|.
" set shortmess+=c
" set completeopt=menuone,noselect

set signcolumn=yes

set colorcolumn=80
highlight ColorColumn ctermbg=0 guibg=lightgrey

call plug#begin('~/.vim/plugged')

" requirements
Plug 'nvim-lua/plenary.nvim'

" git
Plug 'mhinz/vim-signify'
Plug 'tpope/vim-fugitive'

" editing
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'windwp/nvim-autopairs'

" telescope
Plug 'nvim-telescope/telescope.nvim'

" lsp
Plug 'neovim/nvim-lspconfig'

" completer
Plug 'ms-jpq/coq_nvim', {'branch': 'coq'}
Plug 'ms-jpq/coq.artifacts', {'branch': 'artifacts'} " 9000+ Snippets

" python
Plug 'psf/black', { 'tag': '19.10b0' } " temp fix for missing find_pyproject_toml
Plug 'jpalardy/vim-slime'

" treesitter
Plug 'nvim-treesitter/nvim-treesitter', {'branch': '0.5-compat', 'do': ':TSUpdate'}  " We recommend updating the parsers on update
Plug 'lewis6991/spellsitter.nvim'
Plug 'p00f/nvim-ts-rainbow'

" themes
Plug 'gruvbox-community/gruvbox'
Plug 'vim-airline/vim-airline'
Plug 'folke/zen-mode.nvim'
call plug#end()

" theme settings
let g:gruvbox_contrast_dark = 'hard'
if exists('+termguicolors')
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif
let g:gruvbox_invert_selection='0'

colorscheme gruvbox
set background=dark

" slime
let g:slime_target = "tmux"
let g:slime_paste_file = "$HOME/.slime_paste"
let g:slime_default_config = {"socket_name": "default", "target_pane": "{last}"}
let g:slime_python_ipython = 1
let g:slime_no_mappings = 1
xmap <c-c><c-c> <Plug>SlimeRegionSend
nmap <c-c><c-c> <Plug>SlimeParagraphSend

" Lua settings
lua require("mm4rks")
lua require('nvim-autopairs').setup{}
lua << EOF
require("zen-mode").setup {
  window = {
    backdrop = 0.90, -- shade the backdrop of the Zen window. Set to 1 to keep the same as Normal
    width = 120, -- width of the Zen window
    height = 1, -- height of the Zen window
  },
  plugins = {
    options = {
      enabled = true,
      ruler = true, -- disables the ruler text in the cmd line area
      showcmd = true, -- disables the command in the last line of the screen
    },
    twilight = { enabled = false }, -- enable to start Twilight when zen mode opens
    gitsigns = { enabled = true }, -- disables git signs
  },
}
EOF

let loaded_matchparen = 1
let loaded_matchit = 1

" Mappings
let mapleader = " "

" fugitive
nmap <leader>gj :diffget //3<CR>
nmap <leader>gf :diffget //2<CR>
nmap <leader>gs :G<CR>

" pane movement
nnoremap <leader>h :wincmd h<CR>
nnoremap <leader>j :wincmd j<CR>
nnoremap <leader>k :wincmd k<CR>
nnoremap <leader>l :wincmd l<CR>

" telescope mappings
nnoremap <leader>gb :Telescope git_branches<CR>
nnoremap <C-p> :Telescope git_files<CR>
nnoremap <C-f> :Telescope find_files<CR>
nnoremap <leader>rg :lua require('telescope.builtin').grep_string({ search = vim.fn.input("Grep For > ")})<CR>
nnoremap <leader>gg :Telescope lsp_workspace_diagnostics<CR>
nnoremap <leader>dg :Telescope lsp_document_diagnostics<CR>
nnoremap <leader>lg :Telescope live_grep<CR>
nnoremap <leader>rr :Telescope lsp_workspace_symbols query=<c-r>=expand("<cword>")<CR><CR>
nnoremap <leader>rs :Telescope grep_string<CR>

" back to normal mode
inoremap <C-c> <esc>
inoremap jj <esc>
inoremap jk <esc>
inoremap kj <esc>

" highlight search results toggle
nnoremap <leader># :set hlsearch!<CR>

" indent/unindent with tab/shift-tab
" nmap <Tab> >>
imap <S-Tab> <Esc><<i
nmap <S-tab> <<
vnoremap <Tab> >
vmap <S-Tab> <

" paste and keep paste
vnoremap p "_dp

" yank end of line
nnoremap Y y$

" keep centered
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap J mzJ`z

" undo breakpoints
inoremap , ,<c-g>u
inoremap . .<c-g>u

" jumplist mutations
nnoremap <expr> k (v:count > 5 ? "m'" . v:count : "") . 'k'
nnoremap <expr> j (v:count > 5 ? "m'" . v:count : "") . 'j'

" moving text
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" " Copy to clipboard
vnoremap  <leader>y  "+y
"nnoremap  <leader>Y  "+yg_
nnoremap  <leader>y  "+y
nnoremap  <leader>yy  "+yy

" " Paste from clipboard
nnoremap <leader>p "+p
nnoremap <leader>P "+P
vnoremap <leader>p "+p
vnoremap <leader>P "+P

" python Black and isort on save
autocmd BufWritePost *.py silent execute ':!black %'
autocmd BufWritePost *.py silent execute ':!isort %'
" autocmd BufWritePost *.py execute ':e'

" start completer
autocmd VimEnter * execute ':COQnow -s'
