#!/usr/bin/env ruby
require "socket"
require "openssl"

# Variables
@help_msg     = ["Use the following symbols in a message: 0-9, +, -, /, *, (, ), !.", \
								"If it's a syntactically correct mathematical expression, I will try to evaluate it.",\
								"Use '**' for exponentiation.",\
								"The variable '!' holds the result of the previous calculation."]
@server       = "irc.cat.pdx.edu"
@port         = "6697"
@nick         = "Math"
@channel      = "#test-test"
@channelPass  = "catsonly"

# Connect
@socket = TCPSocket.open(@server, @port)
@ssl_context = OpenSSL::SSL::SSLContext.new()
@irc_server = OpenSSL::SSL::SSLSocket.new(@socket, @ssl_context)
@irc_server.connect

@irc_server.puts "USER Math 0 Math :I iz a bot"
@irc_server.puts "NICK #{@nick}"
@irc_server.puts "JOIN #{@channel} #{@channelPass}"

@previous_value = 0

def help_msg
	@help_msg.each do |msg|
      @irc_server.puts "PRIVMSG #{@channel} :" + msg
	end
end


def well_formed_equation? (astring)
  (astring.delete "!1234567890+\-/*)(").chomp.length == 0 and
  (astring.include? "+" or
   astring.include? "-" or
   astring.include? ")" or
   astring.include? "(" or
   astring.include? "*" or
   astring.include? "/")
end

def replace_special_characters! (astring)
	astring.gsub! /!/,  @previous_value.to_s
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
  if msg =~ /^PING/
    @irc_server.puts "PONG" 
  end
  calc = msg.split(":")[2]
  result = nil
  if calc != nil 
    if calc.chomp == "Math help"
			help_msg
    else well_formed_equation? calc
			replace_special_characters! calc
      result = evaluate calc
    end
  end
  if result != nil
		@previous_value = result.to_s
    @irc_server.puts "PRIVMSG #{@channel} :" + result.to_s
  end
end
