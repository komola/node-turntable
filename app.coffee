ON = 1
OFF = 0

express = require "express"
async = require "async"

ftdi = require "ftdi"

device = null

turnBy = (miliseconds, callback) =>
  array = new Array(ON, ON, ON, ON).reverse()
  device.write [parseInt(array.join(""), 2)], (err) =>
    console.log "start"
    setTimeout =>
      array = new Array(OFF, OFF, OFF, OFF).reverse()
      device.write [parseInt(array.join(""), 2)], (err) =>
        console.log "stop"
        callback()
    , miliseconds

async.series [
  (cb) =>
    ftdi.find (err, devices) =>
      device = new ftdi.FtdiDevice(devices[0])
      cb err
  ], (err) =>

    deviceOptions =
      baudrate: 9600
      databits: 8
      stopbits: 1
      parity: 'none'
      bitmode: 0x04
      bitmask: 0xff
    device.open deviceOptions, (err) =>

      device.on "data", (data) =>
        console.log data

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
