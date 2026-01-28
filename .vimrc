let home_dir = $HOME
set nocompatible

set number

set showcmd 
set ignorecase
set incsearch
set smartcase

set autoindent
set smartindent

set t_Co=256
set textwidth=100

filetype plugin on
set omnifunc=ccomplete#Complete
syntax on

" switching between c headers
imap <F2> <ESC>:w<CR>i

nnoremap <F3> :NERDTreeToggle <CR>
colorscheme gruvbox
set background=dark
let g:rainbow_active = 1

set tags=~/vim-config/tags

set pumheight=10

set complete=.,t
set completeopt=menu,menuone,noselect
filetype plugin on
set omnifunc=ccomplete#Complete

