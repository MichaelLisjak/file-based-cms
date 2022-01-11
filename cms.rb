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




# add test folder with cms_test.rb file
# copy template minitest in cms_test.rb
# (update gemfile with minitest?)
# write tests for both routes and add as many assertions as I can think of
# run the test and pray that everything works