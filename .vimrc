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

set tags=home_dir/tags;homedir,tags;

"let g:ale_linters = {
"\	'c': ['cppcheck', ''],
"\}

"let g:ale_lint_on_text_changed = 'always'
"let g:ale_lint_on_insert_leave = 1

"let g:ale_c_gcc_options = '-I$HOME/esp/esp-idf/components -I$HOME/esp/esp-idf/components/esp_wifi/include -I$HOME/esp/esp-idf/components/freertos/include -std=c11 -Wall'

"nmap <silent> <C-k> <Plug>(ale_previous_wrap)
"nmap <silent> <C-j> <Plug>(ale_next_wrap)
