# `git-secret` — 安裝與運作說明 (Installation & Usage)

> 取代先前 vendored 版本 `bin/git-secret` (52KB / 2082 行), 改用 Homebrew 安裝。

## 安裝 (Install)

```bash
brew install git-secret
```

gpg (GnuPG) 為相依工具, 若尚未安裝可一併裝:

```bash
brew install gnupg
```

## 運作原理 (How It Works)

`git-secret` 將 GPG 加密的機密檔案存進 git repo, 僅允許指定公鑰 (recipient) 解密。流程:

1. **初始化 (init)**
   ```bash
   git secret init
   ```
   在 repo 根目錄建立 `.gitsecret/` (預設 ignore) 儲存加密 metadata 與亂數種子。

2. **新增 GPG 收件人 (add recipient)**
   ```bash
   git secret tell alice@host.com
   # 或以 key-id / fingerprint 指定
   git secret tell 0xDEADBEEF
   ```
   公鑰指紋寫入 `.gitsecret/pubring.gpg` 並 commit。

3. **加入要加密的檔案 (add)**
   ```bash
   git secret add path/to/secret.env
   ```
   把路徑加入 `.gitignore` (反向: `.gitignore` 內以 `# git-secret` 標示)。

4. **加密 (encrypt)**
   ```bash
   git secret reveal   # 解密 (本地需對應私鑰)
   git secret hide     # 加密並寫入 *.secret 檔
   ```
   加密後檔案 (例 `secret.env.secret`) 可安全 commit; 解密需團隊成員各自私鑰。

5. **變更收件人時 (rotate)**
   ```bash
   git secret rotate -f
   ```

## 與 `env_setup` 的整合 (Integration)

- 個人敏感值 (`passwd` / `email` / `token`) 一律改由 `~/.config/env_setup/settings.private.sh` 提供, 不放進 git。
- 跨機器共用的密碼 (例: 團隊 ssh key passphrase) 才考慮用 `git-secret` 加密進 `bin/bash/.ssh/` 或獨立的 secrets repo。
- 解密後請確認不要把解密檔案 commit 進 git; `git secret add` 自動處理 `.gitignore` 但仍需注意編輯器暫存檔。

## 為何不再 vendored (Why De-vendored)

- Vendored 版本 `bin/git-secret` 為 52KB / 2082 行 bash 腳本, 改版需手動同步上游。
- Homebrew 套件與上游 `sobolevn/git-secret` 同步, `brew upgrade` 即更新。
- 本地端不再重複維護, 減少 repo 雜訊與安全修補延遲。
