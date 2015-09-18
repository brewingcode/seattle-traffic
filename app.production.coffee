axis         = require 'axis'
rupture      = require 'rupture'
autoprefixer = require 'autoprefixer-stylus'
js_pipeline  = require 'js-pipeline'
css_pipeline = require 'css-pipeline'

module.exports =
  ignores: ['mongodata', 'readme.md', '**/layout.*', '**/_*', '.gitignore', 'ship.*conf']

  extensions: [
    js_pipeline(files: [
      'assets/js/shared/jquery-2.1.4.min.js'
      'assets/js/*.js'
      'assets/js/*.coffee'], out: 'js/build.js', minify: false, hash: true),
    css_pipeline(files: ['assets/css/*.css', 'assets/css/*.styl'], out: 'css/build.css', minify: true, hash: true)
  ]

  stylus:
    use: [axis(), rupture(), autoprefixer()]
