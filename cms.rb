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
  # Return the filepath for a given file
  def get_file_path(file_name)
    @root + "/data/" + file_name
  end
end

before do
  @root = File.expand_path("..", __FILE__) # gets the current absolute directory of the ruby program that is running
end

get "/" do
  @files = Dir.entries("data").select { |file| file.include?(".txt") }
  erb :files
end

get "/:file_name" do
  file_name = params[:file_name]
  headers["Content-Type"] = "text/plain"
  @contents = File.read(get_file_path(file_name))
  erb :file
end




# 1. When a user visits the home page, they should see a list of the documents in the CMS: history.txt, changes.txt and about.txt:
  # create directory with the files
  # create a view template for the list (files.erb)
  # in files.erb, iterate through the files and print them to the browser as a list

# create a filepath for every file --> helper method that takes filename and returns the path?
# 