_ = require 'lodash'
gulp = require 'gulp'
mocha = require 'gulp-mocha'
rename = require 'gulp-rename'
webpack = require 'webpack-stream'
istanbul = require 'gulp-coffee-istanbul'
coffeelint = require 'gulp-coffeelint'
clayLintConfig = require 'clay-coffeescript-style-guide'

TEST_TIMEOUT = 300

paths =
  coffee: ['./src/**/*.coffee', './*.coffee', './test/**/*.coffee']
  cover: ['./src/**/*.coffee', './*.coffee']
  rootScripts: './src/index.coffee'
  rootTests: './test/**/*.coffee'
  build: './build'
  output:
    tests: 'tests.js'

gulp.task 'test', ['lint', 'test:coverage']

gulp.task 'watch', ->
  gulp.watch paths.coffee, ['test:node']

gulp.task 'lint', ->
  gulp.src paths.coffee
    .pipe coffeelint(null, clayLintConfig)
    .pipe coffeelint.reporter()

gulp.task 'test:node', ->
  gulp.src paths.rootTests
    .pipe mocha({timeout: TEST_TIMEOUT})

gulp.task 'test:coverage', ->
  gulp.src paths.cover
    .pipe istanbul includeUntested: false
    .pipe istanbul.hookRequire()
    .on 'finish', ->
      gulp.src paths.rootTests
        .pipe mocha({timeout: TEST_TIMEOUT})
        .pipe istanbul.writeReports({
          reporters: ['html', 'text', 'text-summary']
        })
