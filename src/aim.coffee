Robot   = require('hubot').Robot
Adapter = require('hubot').Adapter
TextMessage = require('hubot').TextMessage
util = require "util"
oscar = require 'oscar'

class Aim extends Adapter
  send: (user, strings...) ->
    for str in strings
      console.log str
      @aim.sendIM user.reply_to, str

  reply: (user, strings...) ->
    for str in strings
      console.log str
      @send user, str

  run: ->
    self = @
    @options =
      email:      process.env.HUBOT_AIM_EMAIL
      password: process.env.HUBOT_AIM_PASSWORD
      name:     process.env.HUBOT_AIM_NAME or "#{self.name} Bot"
      rooms:    process.env.HUBOT_AIM_ROOMS or "@All"
      debug:    process.env.HUBOT_AIM_DEBUG or false
      host:     process.env.HUBOT_AIM_HOST or null

    console.log "Options:", @options
    aim = new oscar.OscarConnection
      connection:
        username: @options.email,
        password: @options.password
    mention = new RegExp("@#{@options.name.replace(' ', '')}\\b", "i")
    console.log mention

    aim.connect (err) ->
      if not err
        util.puts "aim online"
      else
        util.puts err

    aim.on "error", (e) ->
      util.puts e

    aim.on "im", (text, sender, flags, time) ->
      tmp = text.replace(/<(?:.|\n)*?>/gm, '')
      author = {}
      aname = tmp.match(/\([^()]*\)/)
      if (aname)
        aname = aname[0]
      else
        aname = sender.name
      aname = aname.replace('(', '')
      aname = aname.replace(')', '')
      hubot_msg = tmp.replace(/\([^()]*\)/, '')
      hubot_msg_trimmed = hubot_msg.replace(/^[ \t]+/, '')
      if (aname)
        name = aname.split("@")[0]
        author = self.userForId(aname, name)
      author.reply_to = sender.name  
      console.log 'sender:' + author.reply_to
      console.log 'received IM from ' + author.name + ' on ' + time + '::: ' + hubot_msg_trimmed
      self.receive new TextMessage(author, hubot_msg_trimmed)

    @aim = aim
    self.emit "connected"

 

exports.use = (robot) ->
  new Aim robot