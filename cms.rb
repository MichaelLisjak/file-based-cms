require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

helpers do

end

before do
  
end

get "/" do
  @files = Dir.entries("data").select { |file| file.include?(".txt") }
  erb :files
end


# 1. When a user visits the home page, they should see a list of the documents in the CMS: history.txt, changes.txt and about.txt:
  # create directory with the files
  # create a view template for the list (files.erb)
  # in files.erb, iterate through the files and print them to the browser as a list