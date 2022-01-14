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
  if File.file?(get_file_path(file_name))
    @contents = File.read(get_file_path(file_name))
    erb :file
  else
    session[:error] = "#{file_name} does not exist."
    redirect "/"
  end
end




# create an if clause in the "/:file_name" that handles the response for non-existing files
# check if file exists with File.file?(file)
  # if yes, load contents into @contents and load file.erb
  # else use a flash error message that the file was not found and redirect to index page "/"
  