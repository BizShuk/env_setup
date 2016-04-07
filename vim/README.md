# vim note


### vimrc
ref. .vimrc
- [Vim9](http://www.study-area.org/tips/vim/Vim-9.html)
- [VimScript hardway](http://learnvimscriptthehardway.stevelosh.com/)
- [Come home to VIM](http://stevelosh.com/blog/2010/09/coming-home-to-vim/)

### CMD

##### to specific line
:<number>
:help keycodes
:[n][nor]map , show map list



##### /
##### [[
##### ]]
##### ctrl+w ctrl+w
##### f5 
##### f8
##### ctrl + +
##### ctrl + -
##### ctrl+w + +
##### ctrl+w + -
##### ctrl+w + <
##### ctrl+w + >
##### ctrl+w + s (vertical split)
##### ctrl+w + v (horizontal split)
##### ctrl+q = :q
##### ctrl+w + H 
##### ctrl+w + J
##### ctrl+w + K 
##### ctrl+w + L 
##### :s (substitute)
replace and search



- `:%s/foo/bar/g`  
Find each occurrence of 'foo' (in all lines), and replace it with 'bar'.

- `:s/foo/bar/g`  
Find each occurrence of 'foo' (in the current line only), and replace it with 'bar'.

- `:%s/foo/bar/gc`  
Change each 'foo' to 'bar', but ask for confirmation first.  

- `:%s/\<foo\>/bar/gc`  
Change only whole words exactly matching 'foo' to 'bar'; ask for confirmation.      

- `:%s/foo/bar/gci`  
Change each 'foo' (case insensitive due to the i flag) to 'bar'; ask for confirmation.  

- `:%s/foo\c/bar/gc`  
is the same because \c makes the search case insensitive.  
This may be wanted after using :set noignorecase to make searches case sensitive (the default).  

- `:%s/foo/bar/gcI`  
Change each 'foo' (case sensitive due to the I flag) to 'bar'; ask for confirmation.  

- `:%s/foo\C/bar/gc`  
is the same because \C makes the search case sensitive. 
This may be wanted after using :set ignorecase to make searches case insensitive.
