
events = require "events"
express = require "express"
logger = new (require "devnull") base: true, namespacing: 4
async = require "async"

logger.log "Running"




class InvertedPort
  constructor: (gpio) ->
    @_gpio = gpio

  set: (value) =>
    @_gpio.set 1 - value


class ObservablePort extends events.EventEmitter
  set: (value) =>
    @emit "set", value


class LoggablePort
  constructor: (name, logger, gpio) ->
    @_name = name
    @_gpio = gpio
    @_logger = logger

  set: (value) =>
    @_gpio.set value
    @_logger.log @_name, "Switching " + @_name + " to " + value



class Pulsar
  constructor: (gpio, onInterval, offInterval) ->
    @_gpio = gpio
    @_onInterval = onInterval
    @_offInterval = offInterval
    @_timer = null
    @_blink()

  _blink: =>
    @_gpio.set 1
    @_timer = setTimeout (=> 
      @_gpio.set 0
      @_timer = setTimeout @_blink, @_offInterval
      ), @_onInterval


  setOnInterval: (onInterval) =>
    @_onInterval = onInterval
    clearTimeout @_timer
    @_blink()

  setOffInterval: (offInterval) =>
    @_offInterval = offInterval
    clearTimeout @_timer
    @_blink()
  





class Turntable
  constructor: (outputPort) ->
    @_outputPort = outputPort

  turnBy: (time, callback) =>
    @_outputPort.set 1
    setTimeout (=> 
        @_outputPort.set 0
        callback()
      ), 
      time - 25 ## to compensate the setTimout delay of about 25ms





turntable = null

gpio = require "gpio"

exportOut = (portNumber) ->
  (callback) ->
    port = undefined
    options =
      direction: "out"
      ready: -> callback null, port
    port = gpio.export portNumber, options


async.parallel
  turntablePort:    exportOut 7
  powerLedPort:     exportOut 10

, (err, results) ->
    originTurntablePort = new InvertedPort results.turntablePort
    originTurntablePort = new LoggablePort "turntable port", logger, originTurntablePort

    powerLedPulsar = new Pulsar results.powerLedPort, 300, 1700

    turntablePort = new ObservablePort()
    turntablePort.on "set", (value) ->
      powerLedPulsar.setOffInterval if value == 1 then 200 else 1700
    turntablePort.on "set", originTurntablePort.set


    turntable = new Turntable turntablePort

    setTimeout (-> 
      originTurntablePort.set 1
      originTurntablePort.set 0),
      100



app = express()

app.configure ->
  app.use express.bodyParser()
  app.use express.methodOverride()  
  app.use app.router

  app.use express.errorHandler dumpExceptions: true, showStack: true 



app.post "/turntable/turnBy", (req, res) ->
  req.connection.setTimeout 0
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
  req.connection.setTimeout 0
  turntable.turnBy req.params.time, =>
    body = 'Finished'
    res.setHeader 'Content-Type', 'text/plain'
    res.setHeader 'Content-Length', body.length
    res.end body

serverPort = 4243
app.listen serverPort
logger.log "Listening on port " + serverPort
