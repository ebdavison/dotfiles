" use visual bell instead of beeping
set vb

" incremental search
set incsearch

" syntax highlighting
set bg=light
syntax on

" autoindent
autocmd FileType perl set autoindent|set smartindent
autocmd FileType python set autoindent|set smartindent

" python specific
autocmd BufRead *.py set smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class

" 4 space tabs
autocmd FileType perl set tabstop=4|set shiftwidth=4|set expandtab|set softtabstop=4
autocmd FileType python set tabstop=4|set shiftwidth=4|set expandtab|set softtabstop=4

" show matching brackets
autocmd FileType perl set showmatch
autocmd FileType python set showmatch

" show line numbers
autocmd FileType perl set number
autocmd FileType python set number

" check perl code with :make
autocmd FileType perl set makeprg=perl\ -c\ %\ $*
autocmd FileType perl set errorformat=%f:%l:%m
autocmd FileType perl set autowrite

" dont use Q for Ex mode
map Q :q

" make tab in v mode ident code
vmap <tab> >gv
vmap <s-tab> <gv

" make tab in normal mode ident code
nmap <tab> I<tab><esc>
nmap <s-tab> ^i<bs><esc>

" paste mode - this will avoid unexpected effects when you
" cut or copy some text from one window and paste it in Vim.
set pastetoggle=<F11>

" comment/uncomment blocks of code (in vmode)
vmap _c :s/^/#/gi<Enter>
vmap _C :s/^#//gi<Enter>

" my perl includes pod
let perl_include_pod = 1

" syntax color complex things like @{${"foo"}}
let perl_extended_vars = 1

" Tidy selected lines (or entire file) with _t:
nnoremap <silent> _t :%!perltidy -q<Enter>
vnoremap <silent> _t :!perltidy -q<Enter>


" Deparse obfuscated code
nnoremap <silent> _d :.!perl -MO=Deparse 2>/dev/null<cr>
vnoremap <silent> _d :!perl -MO=Deparse 2>/dev/null<cr>

" my perl includes pod
let perl_include_pod = 1

" syntax color complex things like @{${"foo"}}
let perl_extended_vars = 1

" pathogen https://github.com/tpope/vim-pathogen
execute pathogen#infect()
filetype plugin indent on

" vim-header variables
let g:header_auto_add_header = 0
let g:header_field_author = 'Ed Davison'
let g:header_field_author_email = 'edavison@gmail.com'
let g:header_field_timestamp = 0
let g:header_max_size = 10
let g:header_field_filename = 0
map <F4> :AddHeader<CR>

" scroll window
:set scrolloff=5

colors elflord

" vim plug
"call plug#begin('~/.vim/plugged')
call plug#begin()

" vim-plug
Plug 'raghur/vim-ghost', {'do': ':GhostInstall'}
" Only enabled for Vim 8 (not for Neovim).
Plug 'roxma/nvim-yarp', v:version >= 800 && !has('nvim') ? {} : { 'on': [], 'for': [] }
Plug 'roxma/vim-hug-neovim-rpc', v:version >= 800 && !has('nvim') ? {} : { 'on': [], 'for': [] }
Plug 'itchyny/lightline.vim'
Plug 'dense-analysis/ale'

call plug#end()

set laststatus=2
