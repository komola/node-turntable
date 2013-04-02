
events = require "events"
express = require "express"
logger = new (require "devnull") base: true, namespacing: 4
async = require "async"

logger.log "Running"

turntable = null

gpio = require "gpio"


exportOut = (portNumber) ->
  (callback) -> port = gpio.export portNumber, direction: "out", ready: -> callback null, port


async.parallel
  turntablePort:    exportOut 7
  powerLedPort:     exportOut 10
  isTurningLedPort: exportOut 21
  (err, results) ->
    turntablePort = new PortFork results.turntablePort, results.isTurningLedPort
    turntable = new Turntable new LoggablePort logger, turntablePort

    setTimeout (-> 
      powerLedPort.set 0
      powerLedPort.set 1
      turntablePort.set 0
      turntablePort.set 1),
      100


class PortFork
  constructor: (gpio1, gpio2) ->
    @_gpio1 = gpio1
    @_gpio2 = gpio2

  set: (value) =>
    @_gpio1.set value
    @_gpio2.set value


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
      time - 25 ## to compensate the setTimout delay of about 25ms





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
