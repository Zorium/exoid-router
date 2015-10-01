_ = require 'lodash'
log = require 'loga'
Joi = require 'joi'
Promise = require 'bluebird'

thrower = ({status, info}) ->
  status ?= 400

  error = new Error info
  Error.captureStackTrace error, thrower

  error.status = status
  error._exoid = true

  throw error

assert = (obj, schema) ->
  valid = Joi.validate obj, schema, {presence: 'required', convert: false}

  if valid.error
    try
      thrower info: valid.error.message
    catch error
      Error.captureStackTrace error, assert
      throw error

class ExoidRouter
  constructor: (@state = {}) -> null

  throw: thrower
  assert: assert

  bind: (transform) =>
    new ExoidRouter transform @state

  on: (path, handler) =>
    @bind (state) ->
      _.defaultsDeep {
        paths: {"#{path}": handler}
      }, state

  asMiddleware: =>
    (req, res, next) =>
      requests = req.body?.requests
      cache = []

      # TODO: test this
      try
        @assert requests, Joi.array().items Joi.object().keys
          path: Joi.string()
          body: Joi.any()
      catch error
        return res.status(400).json
          status: error.status
          info: error.info

      Promise.settle _.map requests, (request) =>
        return new Promise (resolve) =>
          handler = @state.paths[request.path]

          unless handler
            @throw {status: 400, info: 'Handler not found'}

          resolve @state.paths[request.path] request.body, _.defaults {
            cache: (id, resource) ->
              if _.isPlainObject id
                resource = id
                id = id.id
              cache.push {path: id, result: resource}
          }, req
      .then (settled) ->
        {
          results: _.map settled, (result) ->
            unless result.isFulfilled()
              return null
            result.value()

          errors: _.map settled, (result) ->
            unless result.isRejected()
              return null

            error = result.reason()
            log.error error
            if error._exoid
              {status: error.status, info: error.info}
            else
              {status: 500}

          cache: cache
        }
      .then (response) -> res.json response
      .catch next

module.exports = new ExoidRouter()
