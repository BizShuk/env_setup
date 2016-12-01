

module.exports = {
    entry: {
        main: './app/index.js',
        // others
    },

    output: {
        // [name] => use entry key for each entry
        // [hash]
        // [chunkhash]
        filename: 'bundle.js',      // output filename
        path: path.resolve(__dirname,'./dist') // output dir
    },
    module: {
        loaders: [
            { test: /\.css$/, loader: "style!css" },
            { test: /\.js$/ , loader: "jsx-loader" },
            { test: /\.js[x]?$/, exclude: /node_modules/, loader: 'babel-loader' },
            { test: /\.js[x]?$/, exclude: /node_modules/, loader: 'babel-loader' },
            { test: /\.css$/, loader: "style!css" },
        ]

    },
    resolve: {
        extensions: ['','.js','.jsx','.json']
    },
    plugins: [] // [list of plugin](https://webpack.js.org/plugins)
}
