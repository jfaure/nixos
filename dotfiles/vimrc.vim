"Plugins
let g:rainbow_active = 1
au BufNewFile,BufRead *.agda setf agda
let maplocalleader = ","

au! Syntax arya source "/home/jamie/arya.vim"
augroup arya
  au!
  autocmd BufNewFile,BufRead *.nimzo set syntax=arya
augroup END

let g:PaperColor_Theme_Options = { 'theme': { 'default': { 'transparent_background': 1 }}}
colorscheme PaperColor

let vim_markdown_preview_github=1
vmap ga :EasyAlign
"nmap ga EasyAlign

set nocompatible
set smartcase
set ignorecase
set clipboard+=unnamed
"chinese must display correctly
set encoding=utf-8
scriptencoding=utf-8
set shiftwidth=2
"set cindnet
set expandtab
set splitright
filetype plugin on | syntax enable
filetype indent off
set mouse=a
set ruler
set backspace=indent,eol,start
set tags=tags;
set path+=..
let @t=':w|!j8 -c %'
let @m=':w|make'
cmap w!! w !sudo tee % >/dev/null
let &makeprg = 'if [ -f Makefile ]; then make; else make -C ..; fi'
let @h=':w | !stack ghci'
"let g:indent_guides_enable_on_vim_startup = 1
"let g:indent_guides_start_level = 2
"let g:indent_guides_start_size = 2

inoremap ö <ESC>
inoremap é <ESC>
inoremap ä :w
inoremap é :w
inoremap à :w
map ä :w
map à :w
"some nice keymappings
map <F2> :set hlsearch! hlsearch?
map <C-l> :nohls
map <C-f> :Files
map <C-o> :Files ~
map <C-h> :set syntax=haskell
map <C-p> :set syntax=arya
map <F3> :sp<cr>:e .<cr>
map <F4> :q<cr>
map <F5> <C-W>=
map <F9> :make<cr>
map <C-F9> :cnext<cr>
map <S-F9> :cprevious<cr>

imap <buffer> \forall ∀
imap <buffer> \FA ∀
imap <buffer> \to →
imap <buffer> \-> →
imap <buffer> \lam λ
imap <buffer> \pibinder Π
imap <buffer> \Sigma Σ
imap <buffer> \exists ∃
imap <buffer> \equiv ≡

" improving haskell setup
augroup ft_haskell
  au FileType haskell setlocal omnifunc=necoghc#omnifunc
  au FileType haskell setlocal makeprg=cabal
  au FileType haskell compiler ghc
  au FileType haskell nnoremap <buffer> gj :write<CR> :exec "AsyncRun " . &makeprg . " build"<CR>
  au FileType haskell nnoremap <buffer> gk :write<CR> :exec "AsyncRun " . &makeprg . " test"<CR>
  au FileType haskell setlocal makeprg=stack
  au FileType haskell nnoremap <buffer> gj :write<CR> :exec "AsyncRun " . &makeprg . " build"<CR>
  au FileType haskell nnoremap <buffer> gk :write<CR> :exec "AsyncRun " . &makeprg . " test"<CR>

  function! RunGhci(type)
    call VimuxRunCommand(" cabal repl && exit")
    if a:type
        call VimuxSendText(":l " . bufname("%"))
        call VimuxSendKeys("Enter")
    endif
  endfunction
  au FileType haskell nmap <silent><buffer> <leader>gg :call RunGhci(1)<CR>
  au FileType haskell nmap <silent><buffer> <leader>gs :call RunGhci(0)<CR>

  " hoogle kewywordprg (K to lookup keyword)
  au FileType haskell set kp=hoogle
augroup END
