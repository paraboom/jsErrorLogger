const path = require('path')
const webpack = require('webpack')
const UnminifiedWebpackPlugin = require('unminified-webpack-plugin')
const RewirePlugin = require('rewire-webpack')
const isProduction = process.env.NODE_ENV === 'production'

const plugins = []

if (isProduction) {
  plugins.push(
    new webpack.optimize.UglifyJsPlugin({minimize: true}),
    new UnminifiedWebpackPlugin()
  )
} else {
  plugins.push(new RewirePlugin())
}

module.exports = {
  devtool: 'source-map',
  entry: {
    js_error_logger: ['./src/index']
  },
  output: {
    path: path.resolve('./build'),
    filename: '[name].min.js',
    library: 'AsyncFn',
    libraryTarget: 'umd'
  },
  resolve: {
    root: process.cwd(),
    modulesDirectories: ['node_modules'],
    extensions: ['', '.js', '.coffee']
  },
  module: {
    loaders: [
      {
        test: /\.coffee$/,
        loaders: ['coffee']
      }
    ]
  },
  plugins: plugins
}
