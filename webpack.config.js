const Uglifier = require('uglifyjs-webpack-plugin')

module.exports = {
  entry: {
    blick: `${__dirname}/ui/src/blick.js`
  },
  output: {
    path: `${__dirname}/priv/static/dist`,
    filename: 'index.js',
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
    contentBase: `${__dirname}/priv/static`,
    port: '8081',
  }
}
