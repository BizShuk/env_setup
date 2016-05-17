```yaml
apiVersion: v1

clusters:
- cluster:
    certificate-authority-data: REDACTED
    server: https://10.128.112.11
  name: default

contexts:
- context:
    cluster: <cluster name>
    namespace: <namepace>
    user: <user setting name>
  name: <context name, specific group?>
- context:
    cluster: default
    namespace: SHUK
    user: shuk
  name: shuk

current-context: shuk

kind: Config
preferences: {}
users: 
- name: <user setting name>
  user:    # user config
    password: <password>
    username: <username>
- name: admin-crt-key
  user:
    client-certificate-data: REDACTED
    client-key-data: REDACTED
- name: admin-token
  user:
    token: <token>
```
