#!/usr/bin/env ruby
require "socket"
require "openssl"

# Variables
@help_msg     = "I can calculate the following operations on the integers: \\ * - + ()"
@server       = "irc.cat.pdx.edu"
@port         = "6697"
@nick         = "Math"
@channel      = "#robots"
@channelPass  = "catsonly"

# Connect
@socket = TCPSocket.open(@server, @port)
@ssl_context = OpenSSL::SSL::SSLContext.new()
@irc_server = OpenSSL::SSL::SSLSocket.new(@socket, @ssl_context)
@irc_server.connect

@irc_server.puts "USER Math 0 Math :I iz a bot"
@irc_server.puts "NICK #{@nick}"
@irc_server.puts "JOIN #{@channel} #{@channelPass}"


def well_formed_equation? (astring)
  (astring.delete "1234567890+-/*)(").chomp.length == 0 and
  (astring.include? "+" or
   astring.include? "-" or
   astring.include? ")" or
   astring.include? "(" or
   astring.include? "*" or
   astring.include? "/")
end

def evaluate (calculation)
  begin
    eval(calculation)
  rescue ZeroDivisionError => e
    "#{e.class}"
  rescue Exception
    nil
  end
end

until @irc_server.eof? do
  msg = @irc_server.gets
  p msg
  calc = msg.split(":")[2]
  result = nil
  if calc != nil 
    if calc.chomp == "Math help"
      @irc_server.puts "PRIVMSG #{@channel} :" + @help_msg
    else well_formed_equation? calc
      result = evaluate calc
    end
  end
  if result != nil
    @irc_server.puts "PRIVMSG #{@channel} :" + result.to_s
  end
end
