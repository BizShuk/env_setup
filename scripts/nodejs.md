# Node

- [pnpm](#pnpm)
- [nvm](#nvm)
- [webpack](webpack.md)

### nvm

node version manager , [official github](https://github.com/creationix/nvm)

##### install nvm

##### how to use nvm

env: `export NVM_DIR="~/.nvm"`

- `nvm install stable`
- `nvm uninstall stable`
- `nvm use [<version> or stable]`
- `nvm install iojs`
- `bvn alias default <version>`

### pnpm

node package manager , [document](https://pnpm.io/)

本機唯一的 node package manager. npm / npx / corepack 已由 `scripts/nodejs_nvm.sh`
自 Node.js runtime 移除, pnpm 由 `scripts/pnpm.sh` 以 standalone binary 安裝,
版本以 `package.json` 的 `packageManager` 欄位為準, 所有機器與 CI 拿到同一版.

### install package

- Global , `pnpm add -g <package_name>@<version>`
- Local , `pnpm add -D <package_name>@<version>`
- search , `pnpm search <package_name>`
- update one or all packages , `pnpm update [<package_name>]`
- install from lockfile (CI) , `pnpm install --frozen-lockfile`
- run package.json , `pnpm run`
- run package.json script test , `pnpm test`
- run package.json script start , `pnpm start`

### package.json

[personal sample](package.json)
