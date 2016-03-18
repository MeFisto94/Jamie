#!/usr/bin/ruby

require 'dotenv'
require 'json'
require 'rubygems'
require 'pretty_inspect'
require 'uri'
require 'net/http'

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'slack-ruby-bot'
require 'jaime/commands/bet'
require 'jaime/commands/help'
require 'jaime/bot'
require 'jaime/util'
require 'jaime/vault'

Dotenv.load

SlackRubyBot.configure do |config|
    config.aliases = ['jaime', 'jamie?', 'jaime?']
end

Jaime::Vault.load()

begin
    Jaime::Bot.run
    rescue Exception => e
        STDERR.puts "ERROR: #{e}"
        STDERR.puts e.backtrace
        raise e
end