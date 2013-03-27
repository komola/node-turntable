
events = require "events"
express = require "express"
logger = new (require "devnull") base: true, namespacing: 4


logger.log "Running"

turntable = null

gpio = require "gpio"
turntablePort = gpio.export 7,
    direction: "out",
    ready: ->
      turntable = new Turntable new LoggablePort logger, turntablePort

      setTimeout (-> 
        turntablePort.set 0
        turntablePort.set 1),
        100


class LoggablePort
  constructor: (logger, gpio) ->
    @_gpio = gpio
    @_logger = logger

  set: (value) =>
    @_gpio.set value
    @_logger.log "Switching to ", value




class Turntable
  constructor: (outputPort) ->
    @_outputPort = outputPort

  turnBy: (time, callback) =>
    @_outputPort.set 0
    setTimeout (=> 
        @_outputPort.set 1
        callback()
      ), 
      time - 25





app = express()

app.configure ->
  
  app.use express.bodyParser()
  app.use express.methodOverride()  
  app.use app.router

  app.use express.errorHandler dumpExceptions: true, showStack: true 



app.post "/turntable/turnBy", (req, res) ->
  
  turntable.turnBy req.body.time, =>
    body = '{ "result" : "successful" }'
    res.setHeader 'Content-Type', 'text/plain'
    res.setHeader 'Content-Length', body.length
    res.end body


app.get "/status", (req, res) ->
  logger.log req.body
  body = 'running'
  res.setHeader 'Content-Type', 'text/plain'
  res.setHeader 'Content-Length', body.length
  res.end body

app.get "/turntable/turnBy/:time", (req, res) ->
  turntable.turnBy req.params.time, =>
    body = 'Finished'
    res.setHeader 'Content-Type', 'text/plain'
    res.setHeader 'Content-Length', body.length
    res.end body

app.listen 4243
