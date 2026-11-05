# app.rb

require 'bundler/setup'

# Set the Rails environment
ENV['RAILS_ENV'] ||= 'development'

# Set up ARGV like you typed `rails server`
ARGV.replace(['server', '-b', '0.0.0.0', '-p', '3000'])

# Load the Rails CLI, which includes the `server` command
require 'rails/cli'
