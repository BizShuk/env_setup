" ref. http://www.study-area.org/tips/vim/Vim-9.html
" ref. http://vimdoc.sourceforge.net/htmldoc/help.html


colorscheme  molokai " 256-jungle , asu1dark

set t_Co=256        " set terminal color mode to 256

set statusline=%4*%<\%m%<[%f\%r%h%w]\ [%{&ff},%{&fileencoding},%Y]%=\[Position=%l,%v,%p%%]  " show status at bottom

syntax on           " syn on

set hlsearch        " highlight search result after searched
set incsearch       " highlight when searching
set mouse=a         " move cursor to where mouse clicked
set wildmenu        " 有點類似列出完整的指令 ls a<tab>  :spe<tab>

"set list            " turn on invisible characters like end of line as $

"set number          " turn on line number , it will effect copy block and paste

set ai              " autoidnent , default off
"set cin             " cindent , default off 

set ignorecase      " ignore case when searching
" set ic  " same as above


set nowrap          " 超過畫面不換行
set scrolloff=5     " 捲動捲軸時 游標預留n行捲動
set paste           " better pasting without pasting tab problem
set cursorline      " hightlight the line cursor now


" 
set encoding=utf8
set fileencoding=utf8
"set fileencodings=utf8,big5,big5-hkscs
 
  
set termencoding=utf-8
set shiftwidth=4        " sw
set tabstop=4           " ts
set softtabstop=4
set expandtab
set softtabstop=4 
set smartindent
set backspace=indent,eol,start
set bg=light

set backspace=2  " 在 insert 也可用 backspace
set ru           " 第幾行第幾個字
"set smartindent  " 設定 smartindent
set confirm      " 操作過程有衝突時，以明確的文字來詢問
set history=100  " 保留 100 個使用過的指令
set laststatus=2
set foldmethod=indent
" what is ?
" - tw



" =========================
" pathogen plugin in bundle
" =========================
execute pathogen#infect()

call plug#begin('~/.vim/plugged')
" Plug 'fatih/vim-go'
" Plug 'nsf/gocode', { 'rtp': 'vim', 'do': '~/.vim/plugged/gocode/vim/symlink.sh' }
call plug#end() 



" ==================
" .vim/plugin/Vim-go
" ==================
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1

au FileType go nmap <leader>r <Plug>(go-run)
au FileType go nmap <leader>b <Plug>(go-build)
au FileType go nmap <leader>t <Plug>(go-test)
au FileType go nmap <leader>c <Plug>(go-coverage)

" let g:go_fmt_command = "goimports" " 把go-fmt 換成 go-import 強烈推薦 :p

        " note for Vim-go option
	"#Save it and check goimport result
	":w
	"
	"#Build current project
	":GoBuild 
	"
	"#Run it
	":GoRun
	"
	"#Run Go Run directly 
	"            \r
	"
	"#Run Go Build directly
	"            \b
	"
	"#Go to definition
	"g d
	"
	"
	"
	


" =============	
" NERDTree note
" =============
nnoremap <silent> <F5> :NERDTree<CR>
":NERDTree 開啟
"? Help
"i 開在 split 視窗
"t 開在新的 tab
"o Open file / directory
"x close directory
"q 關掉
"








" ===========================
" autocmd = au
" ===========================
" [autocmd doc](http://vimdoc.sourceforge.net/htmldoc/autocmd.html)
" 
" au <event>[,<events>] file_pattern
" - [events](http://vimdoc.sourceforge.net/htmldoc/autocmd.html#autocmd-events)
" - [file_pattern](http://vimdoc.sourceforge.net/htmldoc/autocmd.html#file-pattern)
"
"
au BufNewFile,BufRead *.wpm setf wpm
au BufNewFile,BufRead *.jhtml setf java
au BufNewFile,BufRead *.c,*.cpp,*.java,*.jhtml,*.pl set cin
au BufNewFile,BufRead *.css set ai
au BufNewFile,BufRead *.css set nocin
au BufNewFIle,BufRead *.js set filetype=javascript
au BufNewFIle,BufRead *.html *.htm set filetype=html
au BufNewFIle,BufRead *.php set filetype=php
au BufNewFIle,BufRead *.sh set filetype=sh
au BufNewFIle,BufRead Dockerfile* set filetype=Dockerfile
au BufNewFIle,BufRead *.{md,mdown,mkd,mkdn,markdown,mdwn} set filetype=markdown
au BufNewFile,BufRead *.txt,*.tex set spell



" ==========
" map
" ==========
" n : normal only
" v ; visual and select
" o : operator-pending
" x : visual only
" s : select only
" i : insert
" c : command-line
" l : insert, command-line, regexp-search
"
" map :  recursive versions of the various mapping 
" normap: non-recursive versions of the various mapping 
" 

" select previous or next tab
nnoremap <C-Left> :tabp<CR>
nnoremap <C-Right> :tabn<CR>

" create new tab
nnoremap <C-n> :tabnew<CR>
nnoremap <C-t> :tabnew<CR>

" write file
nnoremap <C-w> :w<CR>

" quit
nnoremap <silent> <A-w> :q<CR>

" move current tab forward or backward
nnoremap <silent> <A-Left> :execute 'silent! tabmove ' . (tabpagenr()-2)<CR>
nnoremap <silent> <A-Right> :execute 'silent! tabmove ' . tabpagenr()<CR>



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

  highlight TabLineSel term=bold,underline cterm=bold,underline ctermfg=7 ctermbg=0
  highlight TabLine    term=bold cterm=bold
  highlight clear TabLineFill
  highlight Folded term=bold,underline ctermbg=0
end



