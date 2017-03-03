# Exoid Router

Create Exoid compatible APIs

```coffee
router = require 'exoid-router'

authed = (handler) ->
  unless handler?
    return null

  (body, req, rest...) ->
    unless req.isAuthed
      router.throw status: 401, message: 'Unauthorized'

    handler body, req, rest...

routes = router
# Public Routes
.on 'auth.login', AuthCtrl.login

# Authed Routes
.on 'users.getMe', authed UserCtrl.getMe

# As Express Middleware
app.post '/exoid', routes.asMiddleware()

# Joi schema validation
Joi = require 'joi'
# validate {presence: 'required', convert: false}
router.assert('str', Joi.string())

# manual throw, error sent to client
router.throw message: 'invalid api call'

routes.resolve path, body, req
.then ({result, error, cache}) -> null
```
