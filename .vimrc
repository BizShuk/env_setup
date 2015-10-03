set encoding=utf-8
set fileencoding=utf-8
set termencoding=utf-8
set shiftwidth=4
set tabstop=8
set softtabstop=4
set expandtab
"set softtabstop=8 
set smartindent
set backspace=indent,eol,start
set bg=light
set wildmenu

set backspace=2  " 在 insert 也可用 backspace
set ic		 " 設定搜尋忽略大小寫
set ru           " 第幾行第幾個字
set hlsearch     " 設定高亮度顯示搜尋結果
set incsearch    " 在關鍵字還沒完全輸入完畢前就顯示結果
"set smartindent  " 設定 smartindent
set confirm      " 操作過程有衝突時，以明確的文字來詢問
set history=100  " 保留 100 個使用過的指令
set mouse=a
 
set laststatus=2
set statusline=%4*%<\%m%<[%f\%r%h%w]\ [%{&ff},%{&fileencoding},%Y]%=\[Position=%l,%v,%p%%]

set foldmethod=indent

nnoremap <C-Left> :tabprevious<CR>
nnoremap <C-Right> :tabnext<CR>
nnoremap <silent> <A-Left> :execute 'silent! tabmove ' . (tabpagenr()-2)<CR>
nnoremap <silent> <A-Right> :execute 'silent! tabmove ' . tabpagenr()<CR>

syn on
""set ts=4
""set sw=4
""set backspace=indent,eol,start
"set termencoding=big5
"set encoding=big5
"set fileencodings=utf8,big5,big5-hkscs
"set fileencoding=
"set cin
"set ai
""set nocin
"set foldexpr=getline(v:lnum)=~'^[^][{()}]*[)}\\]].*[[{(][^][{()}]*$'?'=':getline(v:lnum)=~'[[{(][^][{()}]*$'?'a1':getline(v:lnum)=~'^[^][{()}]*[])}]'?'s1':'='
"set foldmethod=expr
"set foldmethod=indent
""set bg=light
""set ruler
""set wildmenu
""syn on




au BufNewFile,BufRead *.wpm setf wpm
au BufNewFile,BufRead *.jhtml setf java
au BufNewFile,BufRead *.c,*.cpp,*.java,*.jhtml,*.pl set cin
au BufNewFile,BufRead *.css set ai
au BufNewFile,BufRead *.css set nocin
au BufNewFIle,BufRead *.md set filetype=mkd
au BufNewFIle,BufRead *.js set filetype=javascript
au BufNewFIle,BufRead *.html *.htm set filetype=html
au BufNewFIle,BufRead *.php set filetype=php
au BufNewFIle,BufRead *.sh set filetype=sh



if version >= 700
  map g1 :tabn 1<CR>
  map g2 :tabn 2<CR>
  map g3 :tabn 3<CR>
  map g4 :tabn 4<CR>
  map g5 :tabn 5<CR>
  map g6 :tabn 6<CR>
  map g7 :tabn 7<CR>
  map g8 :tabn 8<CR>
  map g9 :tabn 9<CR>
  map g0 :tabn 10<CR>
  map gm1 :tabm 0<CR>
  map gm2 :tabm 1<CR>
  map gm3 :tabm 2<CR>
  map gm4 :tabm 3<CR>
  map gm5 :tabm 4<CR>
  map gm6 :tabm 5<CR>
  map gm7 :tabm 6<CR>
  map gm8 :tabm 7<CR>
  map gm9 :tabm 8<CR>
  map gm0 :tabm 9<CR>
  map gc :tabnew<CR>
  map gn :tabn<CR>
  map gp :tabp<CR>
  map <C-o> :tabn<CR>
  map <C-p> :tabp<CR>
  imap <C-o> :tabn<CR>
  imap <C-p> :tabp<CR>

  highlight TabLineSel term=bold,underline cterm=bold,underline ctermfg=7 ctermbg=0
  highlight TabLine    term=bold cterm=bold
  highlight clear TabLineFill
  highlight Folded term=bold,underline ctermbg=0

  au BufNewFile,BufRead *.txt,*.tex set spell
end

set hlsearch

map <C-d> "_


set t_Co=256
"colorscheme  256-jungle
colorscheme  asu1dark
