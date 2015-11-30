偶爾參考練習新快捷鍵
ref. http://www.howzhi.com/group/it/discuss/10051
ref. [sublime unofficial doc](http://docs.sublimetext.info/)

##### User Settings:
ref. shuk.sublime-settings

## sublime tutorial
https://scotch.io/bar-talk/the-best-sublime-text-3-themes-of-2014

## sublime key shortcut

https://scotch.io/bar-talk/sublime-text-keyboard-shortcuts

[shortcut key](http://docs.sublimetext.info/en/latest/reference/keyboard_shortcuts_win.html):
  ctrl + d      => 選游標當下的字串, 連按=複選相同字串 可一起修改
  alt + F3      => 一次選擇全部相同字串
  ctrl + 0      => focus on sidebar
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

## sublime plugins-and-settings
https://scotch.io/bar-talk/best-of-sublime-text-3-features-plugins-and-settings





## Sublime-Settings Hierarchy
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





