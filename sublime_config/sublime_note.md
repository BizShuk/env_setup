偶爾參考練習新快捷鍵
ref. http://www.howzhi.com/group/it/discuss/10051
ref. [sublime unofficial doc](http://docs.sublimetext.info/)

##### User Settings:
ref. shuk.sublime-settings

### Sublime-Settings Hierarchy
    Packages/Default/Preferences.sublime-settings
    Packages/Default/Preferences (Windows).sublime-settings
    Packages/AnyOtherPackage/Preferences.sublime-settings
    Packages/AnyOtherPackage/Preferences (Windows).sublime-settings
    Packages/User/Preferences.sublime-settings
    Settings from the current project
    Packages/Python/Python.sublime-settings
    Packages/Python/Python (Windows).sublime-settings
    Packages/User/Python.sublime-settings
    Session data for the current file
    Auto-adjusted settings


##### Markdown theme for sublime 3
1. copy packages/MarkdownEditing dir to sublime package location
2. choose syntax/MarkdownEditing/Markdown for md file
3. change `packages/MarkdownEditing/Markdown (Standard).sublime-settings` color-theme to MarkdownEditing-Dark.tmTheme




##### install package controller

1. ctrl+`

2. paste below

  import urllib2,os,hashlib; h = 'eb2297e1a458f27d836c04bb0cbaf282' + 'd0e7a3098092775ccb37ca9d6b2e4b7d'; pf = 'Package Control.sublime-package'; ipp = sublime.installed_packages_path(); os.makedirs( ipp ) if not os.path.exists(ipp) else None; urllib2.install_opener( urllib2.build_opener( urllib2.ProxyHandler()) ); by = urllib2.urlopen( 'http://packagecontrol.io/' + pf.replace(' ', '%20')).read(); dh = hashlib.sha256(by).hexdigest(); open( os.path.join( ipp, pf), 'wb' ).write(by) if dh == h else None; print('Error validating download (got %s instead of %s), please try manual install' % (dh, h) if dh != h else 'Please restart Sublime Text to finish installation')


###install package manually

1. copy /note/sublime/package/* to sublime user package dir (by perferences->browser package)

  ex: "C:\Users\Shuk\AppData\Roaming\Sublime Text 2\Packages"

2. select from perferences->code theme->sublime-monokai-extended





[shortcut key](http://docs.sublimetext.info/en/latest/reference/keyboard_shortcuts_win.html):
  ctrl + d      => 選游標當下的字串, 連按=複選相同字串 可一起修改
  alt + F3      => 一次選擇全部相同字串

  ctrl + m      => 游標移動到括號開始或結束
  ctrl + p       => 搜尋整個folder的function , 輸入 @ 變搜尋該文件的function
  ctrl + shift + [  => 摺疊
  ctrl + shift + ]  => 展開
  ctrl + shift + 上,下=> 上下移動選取的區塊
  ctrl + /      => 註解整行

  ctrl + F2      => 設置標籤
  shift + F2      => 上一個標籤
  F2          => 下一個標籤

  F9          => 行排序
  F6          => 檢測語法
  F11          => 全螢幕




### sublime build

by .sublime-build

`Ctrl+B`        Run default build task
`F7`            Run default build task
`Ctrl+Shift+B`  Run ‘Run’ build task
`Ctrl+Break`    Cancel running build task



example:
{
    "cmd": ["python", "-u", "$file"],
    "file_regex": "^[ ]*File \"(...*?)\", line ([0-9]*)",
    working_dir": "${project_path:${folder}}",
    "selector": "source.python"

    "windows": {
        "cmd": ["python.bat"]
    },

    "variants": [

        { "name": "List Python Files",
          "cmd": ["ls -l *.py"],
          "shell": true
        },

        { "name": "Word Count (current file)",
          "cmd": ["wc", "$file"]
        },

        { "name": "Run",
          "cmd": ["python", "-u", "$file"]
        }
    ]

}



### completions files
by .sublime-completion

{
   "scope": "text.html - source - meta.tag, punctuation.definition.tag.begin",

   "completions":
   [
      { "trigger": "a", "contents": "<a href=\"$1\">$0</a>" },
      { "trigger": "abbr\t<abbr>", "contents": "<abbr>$0</abbr>" },
      { "trigger": "acronym", "contents": "<acronym>$0</acronym>" }
   ]
}





