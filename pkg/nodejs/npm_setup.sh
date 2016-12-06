#!/bin/bash

curl http://npmjs.org/install.sh | sh


### global tools ###
npm install -g html2jade
npm install -g nodemon
npm install -g webpack
npm install -g express-generator


exit 0

### webpack set ###
# maybe change all of these to ~/.node_modules , require testing
npm install --save-dev style-loader         # css
    npm install --save-dev file-loader
    npm install --save-dev webpack
npm install --save-dev css-loader
npm install --save-dev sass-loader
npm install --save-dev node-sass
npm install --save-dev react                # react
npm install --save-dev react-dom
npm install --save-dev jsx-loader
npm install --save-dev babel-core           # bable
npm install --save-dev babel-loader
npm install --save-dev babel-preset-react   # webpack 1.3 resolveloader cannot work , -g instead
npm install --save-dev babel-preset-es2015  # webpack 1.3 resolveloader cannot work , -g instead
npm install --save-dev img-loader
npm install --save-dev url-loader
#npm install --save-dev clipboard

### Production for express basic
npm install --save express
npm install --save serve-favicon
npm install --save morgan
npm install --save cookie-parser
npm install --save body-parser
npm install --save node-sass-middleware
npm install --save debug
npm install --save jade

### production ###
npm install --save es6-promise
npm install --save mysql
npm install --save sqlstring
npm install --save urlencode
npm install --save mongo
### may not require ###
#npm install --save crypto-random-string





