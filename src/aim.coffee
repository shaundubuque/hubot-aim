Robot   = require('hubot').Robot
Adapter = require('hubot').Adapter
TextMessage = require('hubot').TextMessage
util = require "util"
oscar = require 'oscar'

class Aim extends Adapter
  send: (user, strings...) ->
    for str in strings
      str = unescape(encodeURIComponent(str))
      str = str.replace(/</g, '&lt;')
      str = str.replace(/>/g, '&gt;')
      str = str.replace(/(\r\n|\n|\r)/g,'<br>');
      str = str.replace(/\s/g, '&nbsp;')
      console.log str
      @aim.sendIM user.reply_to, str

  reply: (user, strings...) ->
    for str in strings
      console.log str
      @send user, str

  run: ->
    self = @
    @options =
      email:    process.env.HUBOT_AIM_EMAIL
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

    # Parses messages from AIM, stripping out HTML and deducing the correct
    # sender when in group chats.
    #
    # Since 'sender' arrives as a full AIM stanza, create a new 'author'
    # and populate with only the fields Hubot needs.
    #
    # Messaging Hubot Directly
    # ------------------------
    # message:
    #   '<html><body><font size="2" face="arial">hubot ping</font></body></html>'
    #
    # author:
    # {
    #   '0': 'a',
    #   '1': 'd',
    #   '2': 'a',
    #   '3': 'm',
    #   '4': '.',
    #   '5': 'l',
    #   '6': 'u',
    #   '7': 'i',
    #   '8': 'k',
    #   '9': 'a',
    #   '10': 'r',
    #   '11': 't',
    #   id: 'adam.luikart@thirteen23.com',
    #   name: 'adam.luikart@thirteen23.com',
    #   reply_to: 'adam.luikart@thirteen23.com'
    # }
    # 
    # Messaging in a Group Chat
    # -------------------------
    # message:
    #
    #   '(<B>adam.luikart@thirteen23.com</B>) <html><body><font size="2" face="arial">hubot ping</font></body></html>'
    #
    # author:
    #
    # {
    #   '0': 'a',
    #   '1': 'd',
    #   '2': 'a',
    #   '3': 'm',
    #   '4': '.',
    #   '5': 'l',
    #   '6': 'u',
    #   '7': 'i',
    #   '8': 'k',
    #   '9': 'a',
    #   '10': 'r',
    #   '11': 't',
    #   id: 'adam.luikart@thirteen23.com',
    #   name: 'adam.luikart@thirteen23.com',
    #   reply_to: '[Test Group Chat]'
    # }
    aim.on "im", (text, sender, flags, time) ->
      group_chat_sender_re = /\([^()]*\)/

      # Strip out HTML tags
      tmp = text.replace(/<(?:.|\n)*?>/gm, '')

      # Look for the real sender's name between parens in the message text.
      aname = tmp.match(group_chat_sender_re)

      if (aname)
        aname = aname[0]
      else
        aname = sender.name or ''

      aname = aname.replace('(', '')
      aname = aname.replace(')', '')

      hubot_msg = tmp.replace(group_chat_sender_re, '')
      hubot_msg_trimmed = hubot_msg.replace(/^[ \t]+/, '')

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
