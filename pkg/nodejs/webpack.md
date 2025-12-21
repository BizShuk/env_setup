# webpack

- [official website](https://webpack.js.org/)
- [blog1](http://blog.kkbruce.net/2015/10/webpack.html)

### installation

`npm install webpack -g`

### webpack.config.js

[personal sample](webpack.config.js)

### how to use it

`webpack --config webpack.config.js`
`webpack`：會在開發模式下開始一次性的建置
`webpack -p`：會建置 production-ready 的程式碼 (壓縮)
`webpack --watch`：會在開發模式下因應程式碼修改(儲存時有異動)持續更新建置
`webpack -d`：加入 source maps 檔案
`webpack --progress --colors`：含處理進度與顏色

##### use with npm

```
{   // in package.json
    "scripts":{
        "build":"webpack --config <webpack.config.js>"
    }
}
```

### webpack-dev-server

`webpack-dev-server --devtool eval --progress --colors --hot --content-base build`
