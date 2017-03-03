Joi = require 'joi'
assert = require 'assert'
b = require 'b-assert'

router = require '../src'

describe 'exoid-router', ->
  it 'should assert schema - success', ->
    router.assert {key: 'valid'}, {key: Joi.string()}

  it 'should assert schema - fail', ->
    assert.throws ->
      router.assert {key: 123}, {key: Joi.string()}

  it 'should throw', ->
    assert.throws ->
      router.throw message: 'xxx'

  it 'routes existing', ->
    called = 0
    routes = router.on 'test', (num) ->
      b num, 123
      called += 1
      return '123'

    routes.resolve 'test', 123
    .then ({result}) ->
      b result, '123'
      b called, 1

  it 'errors missing', ->
    router.resolve 'test'
    .then ({error}) ->
      b error?

  it 'handles expected errors', ->
    routes = router.on 'test', ->
      router.throw 'expected'
    routes.resolve 'test'
    .then ({error}) ->
      b error?.message, 'expected'

  it 'throws on unexpected errors', ->
    routes = router.on 'test', ->
      throw new Error 'expected'
    routes.resolve 'test'
    .then (-> throw new Error 'missing'), (error) ->
      b error?.message, 'expected'

  it 'generates middleware', ->
    routes = router.on 'test', -> 'xxx'

    called = 0
    routes.asMiddleware() {
      body: requests: [{path: 'test'}]
    }, {
      json: (res) ->
        b res, {
          results: ['xxx']
          errors: [null]
          cache: []
        }
        called += 1
    }
    .then ->
      b called, 1

  it 'generates middleware with expected error', ->
    routes = router.on 'test', -> router.throw 'xxx'

    called = 0
    routes.asMiddleware() {
      body: requests: [{path: 'test'}]
    }, {
      json: (res) ->
        b res, {
          results: [null]
          errors: [{message: 'xxx'}]
          cache: []
        }
        called += 1
    }
    .then ->
      b called, 1

  it 'rejects on invalid request', ->
    routes = router.on 'test', -> 'xxx'

    called = 0
    routes.asMiddleware() {
      body: requests: {}
    }, {
      status: (status) ->
        b status, 400
        return json: (error) ->
          called += 1
          b error?

    }
    b called, 1

  it 'throws on 500', (cb) ->
    routes = router.on 'test', -> throw new Error 'xxx'

    called = 0
    routes.asMiddleware() {
      body: requests: [{path: 'test'}]
    }, null, (error) ->
      called += 1
      b error?.message, 'xxx'
      b called, 1
      cb()
