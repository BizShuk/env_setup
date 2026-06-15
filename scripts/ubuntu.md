# Ubuntu

- [Setup overview](#setup-overview)
- [Hotkey](#hotkey)
- [Input method](#input-method)
- [Bash function library](#bash-function-library)
- [Shell aliases](#shell-aliases)
- [Bash foundation cheatsheet](#bash-foundation-cheatsheet)
- [Network tools cheatsheet](#network-tools-cheatsheet)
- [Useful one-liners](#useful-one-liners)
- [Troubleshooting](#troubleshooting)
- [Git config reference](#git-config-reference)
- [Bootable USB](#bootable-usb)

## Setup overview

`scripts/ubuntu.sh` 處理：

- `apt-get update && apt-get upgrade -y`
- 開發套件: `build-essential`, `autoconf`, `make`, `cmake`, `python3-dev`, `openssh-server`, `libssl-dev`, `whois`
- 使用者工具: `jq`, `screen`, `colordiff`, `wget`, `curl`, `dnsutils`
- 輸入法: `ibus-chewing` (新酷音), `fcitx-mozc`, `fcitx-googlepinyin`
- Locale: `zh_TW.UTF-8` + `en_US.UTF-8` 雙語系；`LC_CTYPE=zh_TW.UTF-8` 讓終端可輸入中文
- Timezone: `Asia/Taipei`
- 建立使用者帳號 / 群組（idempotent）

## Hotkey

### Window

- `快速縮放視窗`, `Super` + `方向鍵`
- `視窗移至左右半邊`, `Super` + `左/右`
- `視窗縮至最大/最小`, `Super` + `上/下`

### Desktop

- `切換桌面`, `Ctrl` + `Alt` + `方向鍵`
- `視窗跟著桌面移動`, `Ctrl` + `Shift` + `Alt` + `方向鍵`

## Input method

fcitx 框架支援多語系，安裝後以 `im-config` 切換系統輸入法：

```bash
# 簡中日文
sudo apt-get install -y fcitx-mozc fcitx-googlepinyin --install-suggests
# 繁中 (ibus)
sudo apt-get install -y ibus-chewing

# 重啟或登出後生效
im-config -n fcitx
```

## Bash function library

`shell/bash_function.sh` 提供兩支可重用函式。放進 `~/.bashrc` 或被其他腳本 `source`。

### `generate_passwd [length]`

從 `/dev/urandom` 產生英數字密碼，預設長度 16。

```bash
generate_passwd() {
    local l=$1
    [ "$l" == "" ] && l=16
    tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs
}
```

### `get_script-path`

回傳當前腳本所在的實體路徑（解開 symbolic link）。`DEBUG_RC=true` 時會把 `$0` / `dirname` / `pwd` 印到 stderr。

```bash
get_script-path () {
    if [ "$DEBUG_RC" == "true" ]; then
        (
            echo -e "${FUNCNAME[*]} script: $0"
            echo -e "${FUNCNAME[*]} dir: $(dirname $0)"
            echo -e "${FUNCNAME[*]} path: $(pwd)"
        ) 1>&2
    fi
    SCRIPTPATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
    echo $SCRIPTPATH
}
```

### `expand_aliases` for non-interactive shell

`bash_aliases.sh` 的核心一行 — 在非互動 shell（如 `bash script.sh`）啟用 alias：

```bash
shopt -s expand_aliases
```

## Shell aliases

放進 `~/.bashrc` 的 alias / function 片段。

### git trace 開關

詳見 [Git Internals - Environment Variables](https://git-scm.com/book/en/v2/Git-Internals-Environment-Variables)。

```bash
git_trace_on () {
    export GIT_TRACE=1
    export GIT_CURL_VERBOSE=1
}
git_trace_off () {
    unset GIT_TRACE
    unset GIT_CURL_VERBOSE
}
```

### python 版本相容

```bash
if which python3 > /dev/null ; then
    alias python='python3'
else
    alias python='python2.7'
fi
```

### python-config 與 lib 路徑

```bash
if command -v python3 > /dev/null ; then
    alias python-config='python3-config'
else
    alias python-config='python2.7-config'
fi
alias py-config='python-config'

get_python-config-dir () {
    if ! command -v python-config > /dev/null; then
        echo python config dir is not existed
        return 127
    fi
    python_config_dir=`python-config --ldflags |awk '{print $1}'`
    python_config_dir=${python_config_dir:2}
    echo "${python_config_dir}"
}
```

## Bash foundation cheatsheet

語法速查片段，源自 `shell/fundation/*.sh`。

### Array

```bash
files=("test.lua")
files+=("test1.lua")
files+=("test2.lua")

echo '${files[@]}:' ${files[@]}      # all elements
echo '${#files[@]}:' ${#files[@]}    # length
echo '${files}:'    ${files}         # first element only

for file in ${files[@]}; do
    echo "origin:$file trim:${file:0:-4}"
done
```

### Variable (`declare`)

```bash
declare -x Var1="Var1"      # 等同 export
declare -n Var2=Var1        # 參考（symbolic link）到另一變數
declare -p Var3             # 印出定義（不存在時 stderr）
declare -i Var4=4           # 整數
Var4=Var4+1                 # 此時會做數字加法
declare -u Var5=Uppercase   # 自動轉大寫
declare -l Var6=LOWCASE     # 自動轉小寫
declare -r Var7="Var7"      # readonly

# Indexed array
declare -a indexed_array
indexed_array[0]=0
indexed_array[3]=3
indexed_array[one]=one      # 注意：非數字 key 會被視為同一個 key

# Associative array
declare -A associative_array
associative_array[one]=one
```

### Function return

```bash
# 用 return: 只能回 0-255
function f1 () { return 30; }
f1; echo "retrieved by \$?: $?"

# 用 echo 回字串: 容易污染 stdout
function f2 () { echo "inside f2"; }
val=$(f2); echo "${val}"
```

### Function parameter

```bash
function F3 () {
    echo "\$1: $1"
    echo "\$@: $@"
    echo "\${#@}: ${#@}"
    array=("$@")
    echo "first of array: ${array[0]}"

    local arg1=$1
    retval="input: $arg1 without Function"   # 寫到全域變數
}

getval1="Bash Function"
F3 "$getval1"
echo "$retval"
```

### If

```bash
st=1
if [ "$st" == "1" ]; then
    echo "inside if" 1>&2
fi
```

### Loop

```bash
# C-style
for ((i=1; i<10; i++)); do echo "basic: $i"; done

# range
for i in {1..10}; do echo "range: $i"; done

# list
for i in 1 2 3 4 5; do echo "list: $i"; done

# seq gen
for i in $(seq 1 10); do echo "seq: $i"; done
```

### Case / switch

```bash
MODE="update_test"
case ${MODE} in
    update*) MODE="update" ;;
    *)       MODE="server" ;;
esac
echo "${MODE}"
```

### Color (`tput`)

```bash
# 前景色 0-7
for i in $(seq 0 7); do
    echo "$(tput setaf $i)color foreground $(tput init)"
done

# 背景色 0-7
for i in $(seq 0 7); do
    echo "$(tput setab $i)color background $(tput init)"
done

# 包成函式
function cy() {
    echo "$(tput setaf 3)$@$(tput init)"
}
```

## Network tools cheatsheet

### `ip` — link / address / route / neighbor

```bash
# Link (device)
ip l
ip l set <iface> up | down
ip l set txqueuelen <n> dev <iface>
ip l set mtu <n> dev <iface>

# Address
ip a
ip addr add [brd <bcast>] <ip> dev <iface>
ip addr del <ip> dev <iface>

# Route
ip r
ip r add <ip> dev <iface>
ip route add <ip> via <gateway>
ip route add default <network/mask> via <gateway>
ip route del <ip>
ip route del default
ip route del <ip> dev <iface>

# Neighbor (ARP)
ip n
ip neigh add <ip> dev <iface>
ip neigh del <ip> dev <iface>
```

### `iptables` 速查

> 注意：service 單元是 `iptables`，原檔拼成 `ipatbles` 是 typo。

```bash
sudo systemctl enable iptables
sudo systemctl start  iptables
sudo systemctl stop   iptables
sudo systemctl restart iptables
sudo systemctl status iptables

iptables <Command> <CHAIN> [<Options>]
```

常用參數：

- 命令: `-A` append, `-C` check, `-D` delete, `-F` flush, `-I` insert, `-N` new chain, `-L` list, `-X` delete chain
- 顯示: `-n` numeric, `-v` verbose, `-t <table>`
- 匹配: `-p` proto, `--tcp-flags`, `-s` src, `-sport`, `-d` dst, `-dport`, `-i` in iface, `-o` out iface
- 動作: `-j ACCEPT|DROP|REJECT|RETURN`
- 進階: `-m connlimit --connlimit-above <n>`, `-m multiport --dports <p,p>`, `-m conntrack --ctstate ESTABLISHED,RELATED`
- 紀錄: `-j LOG --log-prefix "iptables drop: "`

備份規則：

```bash
IPTABLES_BACKUP_PATH="~/.iptables.rules"
iptables-save > "${IPTABLES_BACKUP_PATH}"
```

### `host` / `whois`

```bash
host facebook.com                # DNS lookup
whois 192.168.0.1                # whois lookup
```

## Useful one-liners

```bash
# 依檔案數量自動編號備份
touch file.bak$(ls file* | wc -l)
```

## Troubleshooting

編譯 / build 階段常見錯誤對應套件：

| 錯誤訊息                                                  | 安裝指令                                       |
| --------------------------------------------------------- | ---------------------------------------------- |
| `autoreconf: not found`                                   | `sudo apt-get install autoconf`                |
| `possibly undefined macro: AM_GLIB_GNU_GETTEXT`           | `sudo apt-get install libgconf2-dev`           |
| `error: possibly undefined macro: AC_PROG_LIBTOOL`        | `sudo apt-get install libtool`                 |
| `intltoolize not found`                                   | `sudo apt-get install intltool`                |
| `couldn't find pppd.h`                                    | `sudo apt-get install ppp-dev`                 |
| `No package 'gtk+-3.0' found`                             | `sudo apt-get install gtk+-3.0`                |
| `No package 'gnome-keyring-1' found`                      | `sudo apt-get install libgnome-keyring-dev`    |
| `No package 'NetworkManager' found`                       | `sudo apt-get install network-manager-dev`     |
| `No package 'libnm-util' found`                           | `sudo apt-get install libnm-util-dev`          |
| `No package 'libnm-glib' found`                           | `sudo apt-get install libnm-glib-dev`          |
| `No package 'libnm-glib-vpn' found`                       | `sudo apt-get install libnm-glib-vpn-dev`      |
| `No package 'libnm' found`                                | `sudo apt-get install libnm-dev`               |
| `fatal error: dbus/dbus-glib.h: No such file or directory`| `sudo apt-get install libdbus-glib-1-dev`      |

## Git config reference

`shell/tools/git/` 底下保留一份已驗證的 `~/.gitconfig` 與 commit template，必要時手動 symlink：

```bash
ln -sf <repo>/shell/tools/git/.gitconfig   ~/.gitconfig
ln -sf <repo>/shell/tools/git/.gitmessage  ~/.gitmessage
```

`.gitconfig` 重點：

- `[alias]`：`co=checkout`, `ci=commit`, `st=status`, `br=branch`, `ca=cat-file`, `lt=ls-tree -r`, `lr=ls-remote`, `lf=ls-files`, `logv=log --name-status --graph --decorate`, `rollback=checkout`
- `[color]` log/diff/status/branch 全部 `auto`，`ui=true`
- `[merge] log = 25` 預設 merge 顯示 25 行
- `[core] editor = vim`, `quotepath = false`（中文路徑不跳脫）
- `[credential] helper = cache --timeout=3600`（一小時內不重打密碼）
- `[http] sslVerify = false`（內網 git server 常用）
- `[push] default = current`（push 同名分支）
- `[commit] template = ~/.gitmessage`

`.gitmessage` 目前僅 placeholder，正式使用可改成 Conventional Commits 模板。

### 自行編譯 git（不建議）

`shell/tools/git/install.sh` 走 kernel.org tarball 編譯 2.32.0，僅在 apt 版本太舊時使用。預設從 apt 裝 `git` 即可。

## Bootable USB

- [Create a bootable USB stick on Ubuntu](https://ubuntu.com/tutorials/create-a-usb-stick-on-ubuntu#1-overview)
