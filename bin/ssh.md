# sshd

- `ssh -T <host>` , for test

- system-wide ssh config: /etc/ssh/ssh_config
- user-specific ssh config : ~/.ssh/config

### Copy RSA

```bash
ssh-copy-id [-i .ssh/id_rsa.pub] <hostname>
```

### General RSA key

Copy `.ssh/id_rsa.pub` into `.ssh/authorized_keys`

### ssh-agent

```bash
# 加入私鑰: (預設會加入 ~/.ssh/id_rsa, id_ed25519 等標準名稱的鑰匙)
ssh-add ~/.ssh/id_ed25519
```

```bash
# 列出目前管理的鑰匙:
ssh-add -l
```

```bash
# 刪除所有快取的鑰匙
ssh-add -D
```
