winston = require 'winston'
require './rootRequire'
rootSchema = rootRequire 'app/schemas/root.schema'
mongoose = require 'mongoose'

module.exports.start = (readyCallback) ->
  return if @server
  
  #- setup globals
  GLOBAL._ = require 'lodash'
  _.string = require 'underscore.string'
  global.tv4 = require 'tv4' # required for TreemaUtils to work
  tv4.addSchema rootSchema
  
  
  #- setup logging
  winston.remove(winston.transports.Console)
  winston.add(winston.transports.Console,
    colorize: true,
    timestamp: true
  )
  
  
  #- connect to db
  Grid = require 'gridfs-stream'
  config = rootRequire 'server/server-config'
  if config.runningTests
    mockgoose = require('mockgoose')
    mockgoose(mongoose)

  dbName = config.mongo.db
  address = "#{config.mongo.host}:#{config.mongo.port}"
  if config.mongo.username and config.mongo.password
    address = "#{config.mongo.username}:#{config.mongo.password}@#{address}"
  address = "mongodb://#{address}/#{dbName}"
  
  winston.info "DB connecting to #{address}"
  mongoose.connect address
  mongoose.connection.once 'open', -> 
    Grid.gfs = Grid(mongoose.connection.db, mongoose.mongo)
  
  
  #- express creation, config
  express = require 'express'
  app = express()
  app.set 'port', config.port
  app.set 'env', if config.isProduction then 'production' else 'development'

  
  #- express middleware
  compressible = require 'compressible'
  if config.isProduction

    productionLogging = (tokens, req, res) ->
      status = res.statusCode
      color = 32
      if status >= 500 then color = 31
      else if status >= 400 then color = 33
      else if status >= 300 then color = 36
      elapsed = (new Date()) - req._startTime
      elapsedColor = if elapsed < 500 then 90 else 31
      if (status not in [200, 204, 302, 304]) or elapsed > 500
        return "\x1b[90m#{req.method} #{req.originalUrl} \x1b[#{color}m#{res.statusCode} \x1b[#{elapsedColor}m#{elapsed}ms\x1b[0m"
      null
    
    express.logger.format 'prod', productionLogging
    app.use express.logger('prod')
    app.use express.compress()
  else
    app.use express.logger('dev')

  path = require 'path'
  useragent = require 'express-useragent'
  app.use(express.static(path.join(__dirname, '../public')))
  app.use(useragent.express())

  app.use express.favicon()
  app.use express.cookieParser(config.cookie_secret)
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieSession({secret:'2EqPfxTEqUtRXVfZygLR'})


  #- passport middlware
  authentication = require('passport')
  app.use(authentication.initialize())
  app.use(authentication.session())


  #- setup routes
  routes = require './routes'
  routes(app)

  
  #- Serve main.html
  fs = require 'graceful-fs'
  try
    mainHTML = fs.readFileSync(path.join(__dirname, '../public', 'main.html'), 'utf8')
  catch e
    log.error "Error modifying main.html: #{e}"

  app.all '*', (req, res) ->
    # insert the user object directly into the html so the application can have it immediately. Sanitize </script>
#      data = mainHTML.replace('"userObjectTag"', JSON.stringify(UserHandler.formatEntity(req, req.user)).replace(/\//g, '\\/'))
    res.header 'Cache-Control', 'no-cache, no-store, must-revalidate'
    res.header 'Pragma', 'no-cache'
    res.header 'Expires', 0
    res.send 200, mainHTML
  
  http = require 'http'
  @server = http.createServer(app).listen app.get('port'), ->
    winston.info('Express server listening on port ' + app.get('port'))
    readyCallback?()
    
    
module.exports.close = ->
  @server?.close()
  @server = null