" This is necessary for VimTeX to load properly. The "indent" is optional.
" Note that most plugin managers will do this automatically.
filetype plugin indent on

" This enables Vim's and neovim's syntax-related features. Without this, some
" VimTeX features will not work (see ":help vimtex-requirements" for more
" info).
syntax enable

" Viewer options: One may configure the viewer either by specifying a built-in
" viewer method:
let g:vimtex_view_method = 'zathura_simple'

" Or with a generic interface:
let g:vimtex_view_general_viewer = 'okular'
let g:vimtex_view_general_options = '--unique file:@pdf\#src:@line@tex'

" Do not show quickfix list after compilation
" let g:vimtex_quickfix_enabled = 0
let g:vimtex_quickfix_open_on_warning = 0

" VimTeX uses latexmk as the default compiler backend. If you use it, which is
" strongly recommended, you probably don't need to configure anything. If you
" want another compiler backend, you can change it as follows. The list of
" supported backends and further explanation is provided in the documentation,
" see ":help vimtex-compiler".
" let g:vimtex_compiler_method = 'latexrun'

" Most VimTeX mappings rely on localleader and this can be changed with the
" following line. The default is usually fine and is the symbol "\".
let maplocalleader = ","
" " Get Vim's window ID for switching focus from Zathura to Vim using xdotool.
" " Only set this variable once for the current Vim instance.
" if !exists("g:vim_window_id")
"   let g:vim_window_id = system("xdotool getactivewindow")
" endif

" function! s:TexFocusVim() abort
"   " Give window manager time to recognize focus moved to Zathura;
"   " tweak the 200m (200 ms) as needed for your hardware and window manager.
"   sleep 200m  

"   " Refocus Vim and redraw the screen
"   silent execute "!xdotool windowfocus " . expand(g:vim_window_id)
"   redraw!
" endfunction

" augroup vimtex_event_focus
"   au!
"   au User VimtexEventView call s:TexFocusVim()
" augroup END
