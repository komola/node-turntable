express = require "express"
async = require "async"
wpi = require "wiring-pi"
wpi.setup()
pin = 11
wpi.pinMode(pin, wpi.OUTPUT)
wpi.digitalWrite(pin, 0)

turnBy = (miliseconds, callback) =>
  wpi.digitalWrite(pin, 1)
  console.log "start"
  setTimeout =>
    wpi.digitalWrite(pin, 0)
    console.log "stopp"
    callback()
  , miliseconds
  
app = express()

app.configure ->
  app.use express.bodyParser()
  app.use express.methodOverride()  
  app.use app.router

  app.use express.errorHandler dumpExceptions: true, showStack: true 

app.post "/turntable/turnBy", (req, res) ->
  req.connection.setTimeout 0
  turnBy req.body.time, =>
    res.json { "result" : "successful" }

app.get "/status", (req, res) ->
  res.json { "running": true }

app.get "/turntable/turnBy/:time", (req, res) ->
  req.connection.setTimeout 0
  turnBy req.params.time, =>
    res.json { "result" : "successful" }

serverPort = 4243
app.listen serverPort
console.log "Listening on port " + serverPort
