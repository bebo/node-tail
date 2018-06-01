path              = require 'path'
Tail              = require('../src/tail').Tail
fs                = require 'fs'
expect            = require('chai').expect

fileToTest        = path.join __dirname, 'example.txt'

useWatchFile = true
interval = 2000

describe 'Tail', ->

  beforeEach (done) ->
    fs.writeFile fileToTest, '',done

  afterEach (done) ->
    fs.unlink(fileToTest, done) 

  lineEndings = [{le:'\r\n', desc: "Windows"}, {le:'\n', desc: "Linux"}]

  lineEndings.forEach ({le, desc})->
    it 'should read a file with ' + desc + ' line ending', (done)->
      text = "This is a #{desc} line ending#{le}"
      nbOfLineToWrite = 100
      nbOfReadLines   = 0

      fd = fs.openSync fileToTest, 'w+'

      tailedFile = new Tail fileToTest, {useWatchFile: useWatchFile, fsWatchOptions: {interval: interval}, logger: console}

      tailedFile.on 'line', (line) ->
        expect(line).to.be.equal text.replace(/[\r\n]/g, '')
        ++nbOfReadLines

        if (nbOfReadLines is nbOfLineToWrite)
          tailedFile.unwatch()
          done()

      for index in [0..nbOfLineToWrite]
        fs.writeSync fd, text

      fs.closeSync fd

  it 'should respect fromBeginning flag', (done) ->
    fd = fs.openSync fileToTest, 'w+'
    lines = ['line#0', 'line#1']
    readLines = []
    fs.writeSync fd, lines[0]+'\n'

    tailedFile = new Tail(fileToTest, {useWatchFile: useWatchFile, fromBeginning:true, fsWatchOptions: {interval: interval}, logger:console})
    tailedFile.on 'line', (line) ->
      readLines.push(line)
      if (readLines.length is lines.length) 
        match = readLines.reduce((acc, val, idx)-> 
          acc and (val is lines[idx])
        , true)
        
        if match 
          tailedFile.unwatch()
          done()

    fs.writeSync fd, lines[1]+'\n'

    fs.closeSync fd

  it 'should send error event on deletion of file while watching', (done)->
    text = "This is a line\n"

    fd = fs.openSync fileToTest, 'w+'

    tailedFile = new Tail fileToTest, {useWatchFile: useWatchFile, fsWatchOptions: {interval: interval}, logger: console}

    # ensure error gets called when the file is deleted
    tailedFile.on 'error', (line) ->
      # recreate file so that `afterEach` can cleanup
      fd = fs.openSync fileToTest, 'w+'
      done()

    tailedFile.on 'line', (line) ->
      # delete the file
      fs.unlinkSync fileToTest

    fs.writeSync fd, text

    fs.closeSync fd

  # it 'should tail lines correctly with a high volume file', (done) ->
  #       fd = fs.openSync fileToTest, 'w+'

  #       lines = 1000000

  #       text = [0..lines].map (c) ->
  #         return "aaaaaaaa#{c}"
     
  #       tailedFile = new Tail fileToTest, {logger: console}
        
  #       cnt = 0 
  #       tailedFile.on 'line', (line) ->
  #         if line != text[cnt]
  #           console.log(line, text[cnt])
  #           done('line is different:#{line} <> #{text[cnt]}')  
  #         cnt++
  #         done() if lines == cnt

  #       tailedFile.on 'error', (line) ->
  #         console.log('error:' + line)

  #       for l, i in text      
  #         fs.write fd, "#{l}\n", (e, bw, b) ->
  #           if i == text.length-1 
  #             console.log("close")   
  #             fs.closeSync fd 

  #     .timeout(10000)
