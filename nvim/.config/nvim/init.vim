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

" lsp
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-telescope/telescope.nvim'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'
Plug 'hrsh7th/cmp-buffer'
Plug 'rafamadriz/friendly-snippets'

" treesitter
Plug 'nvim-treesitter/nvim-treesitter', {'branch': '0.5-compat', 'do': ':TSUpdate'}  " We recommend updating the parsers on update
Plug 'lewis6991/spellsitter.nvim'
Plug 'p00f/nvim-ts-rainbow'
Plug 'folke/twilight.nvim'

" themes
Plug 'gruvbox-community/gruvbox'
Plug 'vim-airline/vim-airline'
call plug#end()

let g:gruvbox_contrast_dark = 'hard'
if exists('+termguicolors')
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif
let g:gruvbox_invert_selection='0'

colorscheme gruvbox
set background=dark



" Lua settings
lua require("mm4rks")
lua require('nvim-autopairs').setup{}

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
nnoremap <leader>rg :Telescope lsp_dynamic_workspace_symbols<CR>
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


" " vsnip config
" " Expand
" imap <expr> <C-j>   vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-j>'
" smap <expr> <C-j>   vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-j>'

" " Expand or jump
" imap <expr> <C-l>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>'
" smap <expr> <C-l>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>'

" " Jump forward or backward
" imap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
" smap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
" imap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
" smap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'

" " Select or cut text to use as $TM_SELECTED_TEXT in the next snippet.
" " See https://github.com/hrsh7th/vim-vsnip/pull/50
" nmap        s   <Plug>(vsnip-select-text)
" xmap        s   <Plug>(vsnip-select-text)
" nmap        S   <Plug>(vsnip-cut-text)
" xmap        S   <Plug>(vsnip-cut-text)

" " If you want to use snippet for multiple filetypes, you can `g:vsnip_filetypes` for it.
" let g:vsnip_filetypes = {}
" let g:vsnip_filetypes.javascriptreact = ['javascript']
" let g:vsnip_filetypes.typescriptreact = ['typescript']

