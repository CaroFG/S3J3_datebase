require 'bundler'
Bundler.require
require 'open-uri'
require_relative 'lib/app/scrapper'

Scrapper.new.perform