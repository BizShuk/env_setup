#!/bin/bash

# 1. 檢查是否已安裝 Homebrew
if ! command -v brew &> /dev/null; then
    echo "錯誤: 未檢測到 Homebrew，請先安裝 Homebrew。"
    exit 1
fi

# 2. 安裝最新版 Bash
echo "正在安裝最新版 Bash..."
brew install bash

# 3. 獲取新版 Bash 的路徑
NEW_BASH=$(brew --prefix)/bin/bash

# 4. 將新版 Bash 路徑加入 /etc/shells (需要 sudo 權限)
if ! grep -Fxq "$NEW_BASH" /etc/shells; then
    echo "將新版 Bash 加入系統信任列表..."
    echo "$NEW_BASH" | sudo tee -a /etc/shells
fi

# 5. 切換預設 Shell 為新版 Bash
echo "正在切換預設 Shell 至 $NEW_BASH..."
chsh -s "$NEW_BASH"

echo "=========================================="
echo "設定完成！請關閉目前的終端機視窗並重新開啟。"
echo "重新開啟後，請輸入 'bash --version' 確認版本。"
echo "=========================================="


brew install bash-completion@2

