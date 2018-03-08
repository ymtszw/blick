const Uglifier = require('uglifyjs-webpack-plugin')

const BASE = `${__dirname}/priv/static`

const IS_CLOUD = (process.env.WEBPACK_BUILD_ENV === 'cloud')

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
        test: /\.css$/,
        loader: ['style-loader', 'css-loader'],
      },
      {
        test: /\.elm$/,
        loader: 'elm-webpack-loader',
        options: {
          warn: true,
          debug: !IS_CLOUD,
        }
      },
      {
        test: /\.js$/,
        exclude: /node_modules/,
        loader: 'babel-loader',
        options: {
          presets: [
            ['env', { targets: { browsers: ['since 2015'] } }]
          ]
        }
      }
    ]
  },
  plugins: IS_CLOUD ? [new Uglifier()] : [],
  devServer: {
    contentBase: BASE,
    port: '8079',
    proxy: {
      "/admin/authorize/callback": {
        target: 'http://blick.localhost:8080',
        changeOrigin: true,
        xfwd: true,
      }
    },
  }
}
