require "rubygems"
require "bundler"
require 'nokogiri'
require 'open-uri'

Bundler.require

require "./app"

map "/assets" do
  run App.settings.sprockets
end

map "/" do
  run App
end