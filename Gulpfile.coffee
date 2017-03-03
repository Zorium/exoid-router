gulp = require 'gulp'
mocha = require 'gulp-mocha'
coffeelint = require 'gulp-coffeelint'

paths =
  coffee: ['./src/**/*.coffee', './*.coffee', './test/**/*.coffee']
  tests: './test/**/*.coffee'

gulp.task 'watch', ->
  gulp.watch paths.coffee, ['test']

gulp.task 'lint', ->
  gulp.src paths.coffee
    .pipe coffeelint()
    .pipe coffeelint.reporter()

gulp.task 'test', (if process.env.LINT is '0' then [] else ['lint']), ->
  gulp.src paths.tests
    .pipe mocha({compilers: 'coffee:coffee-script/register'})
