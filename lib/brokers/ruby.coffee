{BufferedProcess} = require "atom"

module.exports =
  exec         : (file, callback)->
    response = ""
    new BufferedProcess
      command: "/usr/bin/ruby"
      args: [file]
      stdout: (data)-> response += data.toString()
      exit: -> callback response

  printer      : "puts \"<$1>\" ($2) + \"</$1>\""
  prefix       : "#=>"
  matcher      : /(#=>)(.+)/gi
  comment      : "#"
