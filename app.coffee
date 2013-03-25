
events = require "events"
express = require "express"
logger = new (require "devnull") base: true, namespacing: 4

app = express()

app.configure =>
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.errorHandler dumpExceptions: true, showStack: true 

  #app.post "/turntable/"


app.listen 4243



class InstructionQueue extends events.EventEmitter
  add: (instructions, replaceExisting) =>




class Turntable
  constructor: (secondsPerRotation, gpio) =>
    @_secondsPerRotation = secondsPerRotation
    @_gpio = gpio



  _currentDegree: 0
  _getCurrentDegree: () =>
    @_currentDegree


  _setTurning: (turning, callback) => 



  resetOrigin: () =>
    @_currentDegree = 0


  startTurning: (callback) =>
    @_instructionQueue.clear()

    action: (next) =>
       @_setIsTurning true, next

    @_instructionQueue.add { action: action, onFinished: callback }
   

  stopTurning: (callback) =>
    @_instructionQueue.add { action: () => null, onFinished: callback }, true

    @_clearInstructionQueue()
    @_setIsTurning false, callback



  _instructionQueue = []

  _addInstruction: (instruction) =>


  _clearInstructionQueue: () =>
    queue = @_instructionQueue
    @_instructionQueue = []

    for instruction of queue
      instruction.callback result: "cancelled"


  turn: (targetDegree, replaceInstructionQueue, callback) =>
    if replaceInstructionQueue
      @_clearInstructionQueue()

    @_addInstruction targetDegree: targetDegree, callback: callback


  turnBy: (deltaDegree, replaceInstructionQueue, callback) =>
    currentDegree = if !replaceInstructionQueue && @_instructionQueue.length > 0
      @_instructionQueue[@_instructionQueue.length - 1].targetDegree
    else
      @_getCurrentDegree()
      
    @turn currentDegree + deltaDegree, callback



