const Uglifier = require('uglifyjs-webpack-plugin')

const BASE = `${__dirname}/priv/static`

module.exports = {
  entry: {
    blick: `${__dirname}/ui/src/blick.js`
  },
  output: {
    path: BASE,
    filename: 'dist/index.js',
    libraryTarget: 'window',
  },
  module: {
    rules: [
      {
        test: /\.elm$/,
        loader: 'elm-webpack-loader',
        options: {
          warn: true,
        }
      }
    ]
  },
  plugins: (process.env.WEBPACK_BUILD_ENV === 'cloud') ? [new Uglifier()] : [],
  devServer: {
    contentBase: BASE,
    port: '8079',
    noInfo: true,
    proxy: {
      "/admin/authorize/callback": {
        target: 'http://blick.localhost:8080',
        changeOrigin: true,
        xfwd: true,
      }
    },
  }
}
