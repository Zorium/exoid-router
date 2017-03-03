_ = require 'lodash'
Joi = require 'joi'

thrower = (data) ->
  if _.isString data
    data = {message: data}

  error = new Error data.message
  Error.captureStackTrace error, thrower
  error._exoid = true
  error._exoid_data = data
  throw error

assert = (obj, schema) ->
  valid = Joi.validate obj, schema, {presence: 'required', convert: false}

  if valid.error
    try
      thrower message: valid.error.message
    catch error
      Error.captureStackTrace error, assert
      throw error

class ExoidRouter
  constructor: (@state = {paths: {}}) -> null

  throw: thrower
  assert: assert

  bind: (transform) =>
    new ExoidRouter transform @state

  on: (path, handler) =>
    @bind (state) ->
      _.defaultsDeep {
        paths: {"#{path}": handler}
      }, state

  resolve: (path, body, req) =>
    cache = []
    return new Promise (resolve) =>
      handler = @state.paths[path]

      unless handler
        @throw {status: 400, info: "Handler not found for path: #{path}"}

      resolve @state.paths[path] body, _.defaults {
        cache: (id, resource) ->
          if _.isPlainObject id
            resource = id
            id = id.id
          cache.push {path: id, result: resource}
      }, req
    .then (result) ->
      {result, cache, error: null}
    .catch (error) ->
      unless error._exoid
        throw error # HTTP 500
      {result: null, error: error._exoid_data, cache: cache}

  asMiddleware: =>
    (req, res, next) =>
      requests = req.body?.requests
      cache = []

      # TODO: test this
      try
        @assert requests, Joi.array().items Joi.object().keys
          path: Joi.string()
          body: Joi.any().optional()
      catch error
        return res.status(400).json
          status: error.status
          info: error.info

      Promise.all _.map requests, (request) =>
        @resolve request.path, request.body, req
      .then (settled) ->
        {
          results: _.map settled, ({result}) -> result
          errors: _.map settled, ({error}) -> error
          cache: _.reduce settled, (cache, result) ->
            cache.concat result.cache
          , []
        }
      .then (response) -> res.json response
      .catch next

module.exports = new ExoidRouter()
