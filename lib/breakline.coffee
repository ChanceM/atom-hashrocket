{BufferedProcess, $} = require 'atom'
Brokers              = require './brokers'
fs                   = require 'fs'
os                   = require 'os'
path                 = require 'path'

module.exports =

  activate: ->
    atom.workspaceView.command "breakline:run", => @run()
    atom.workspaceView.command "breakline:insert", => @insertBreakline()
    atom.workspaceView.command "breakline:insertRun", =>
      @insertBreakline()
      @run()

  serialize: ->
    #

  makeBroker: (args...)->
    {scope} = @getEditor()
    broker = Brokers.clients[scope]

    {exec, printer} = broker

    execute: exec
    printer: printer.replace /\$(\d+)/gi, (m)-> args[m[1]-1]

  setCode: (data)->
    {editor} = @getEditor()

    cursor = editor.getCursorBufferPosition()

    editor.setText data
    editor.setCursorBufferPosition cursor

  generateToken: ->
    token = Math.random().toString(36)[2..].toUpperCase()
    "ATOM-BL-#{token}"

  getEditor: ->
    editor = atom.workspace.activePane.getActiveEditor()
    grammar = editor.getGrammar()

    editor: editor
    scope: grammar.scopeName
    name: grammar.name
    code: editor.getText()

  insertBreakline: ->
    {editor, scope} = @getEditor()
    {prefix} = Brokers.clients[scope]

    word = editor.getWordUnderCursor() or ""

    editor.insertNewlineBelow()
    editor.insertText "#{prefix} #{word}"

  run: ->

    fileToken = @generateToken()

    {code, scope, name} = @getEditor()

    broker = Brokers.clients[scope]

    unless broker
      alert "#{name} broker doesn't exist for Breakline."
      return

    {matcher, exec, comment} = broker
    tokens     = []

    # Clean all results
    code = code.replace ///#{comment}(.*)\sresult.*///gi, "#{comment}$1"

    tokenizedCode = code.replace matcher, (all, prompt, data)=>
      data = data.trim()
      token = @generateToken()
      {printer} = @makeBroker token, data

      tokens.push {token, data, printer}
      printer

    tokenFile = path.join path.sep, "tmp", "#{fileToken}.#{scope}"
    fs.writeFileSync tokenFile, tokenizedCode

    exec tokenFile, (data)=>
      fs.unlink tokenFile
      html = $ "<div>#{data}</div>"
      for token, index in tokens
        tokenInOut = html.find(token.token).last()
        tokens[index].output = if tokenInOut.length > 0 then tokenInOut.text().trim() else "unreachable"

      index = 0
      replacedCode = code.replace matcher, (all, prompt, data)=>

        {output} = tokens[index]

        # figure out somehow. CDATA may be useful.
        output = output
          .replace /\n/g, '' # single line outputs.
          .replace /&gt/g, '>'
          .replace /&lt/g, '<'

        replaced = "#{all} result #{output}"

        index++
        replaced

      @setCode replacedCode
