require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "redcarpet"

configure do
  enable :sessions
  set :session_secret, 'secret'
  #set :erb, :escape_html => true
end

# Return the filepath depending on environment
def data_path
  if ENV["RACK_ENV"] == "test"
    # gets the current absolute directory of the ruby program that is running
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

# Returns the given markdown file as HTML
def render_markdown(md_file)
  # Initialize Markdown object for converting markdown files into HTML
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(md_file)
end

def load_file_content(path, post_request: false)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain" unless post_request
    content
  when ".md"
    erb render_markdown(content)
  end
end

def user_signed_in?
  session[:username] == "admin"
end

def require_signed_in_user
  if !user_signed_in?
    session[:message] = "You must be signed in to do that."
    redirect "/"
  end
end

# Display overview of all available files
get "/" do
  if session[:username] == "admin"
    pattern = File.join(data_path, "*")
    @files = Dir.glob(pattern).map do |path|
      File.basename(path)
    end
    erb :files
  else
    redirect "/users/signin"
  end
end

# Create a new document
get "/new" do
  require_signed_in_user
  erb :new
end

# Submit the new document to the server
post "/new" do 
  if params[:new_document].match(/\.(txt|md)/)  #.size == 0
    session[:message] = "#{params[:new_document]} has been successfully created!"
    file_path = File.join(data_path, params[:new_document])
    File.new(file_path, 111)
    redirect "/"
  else
    session[:message] = "file must be of type .txt or .md"
    status 422
    erb :new
  end
end

# Display a specific file
get "/:filename" do
  require_signed_in_user
  file_path = File.join(data_path, params[:filename])

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

# Load the edit page for a document
get "/:filename/edit" do
  require_signed_in_user
  @filename = params[:filename]
  file_path = File.join(data_path, params[:filename])

  if File.exist?(file_path)
    @content = File.read(file_path) # load_file_content(file_path, post_request: true)
    erb :edit_file
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

# Submit changes to document
post "/:filename" do
  require_signed_in_user
  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:edited_content])

  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end

post "/:filename/destroy" do
  require_signed_in_user
  file_path = File.join(data_path, params[:filename])
  
  File.delete(file_path)

  session[:message] = "#{params[:filename]} has been deleted."
  redirect "/"
end

# Form to login with username and password
get "/users/signin" do
erb :sign_in
end

# Handling the login data
post "/users/signin" do
# the sign in data is handled in this route
  if params[:username] == "admin" && params[:password] == "secret"
    session[:username] = "admin"
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid Credentials"
    status 422
    erb :sign_in
  end
end

# delete the username from the session
post "/users/signout" do
  session.delete(:username)
  session[:message] = "You have been signed out"
  redirect "/"
end

# 16. Restricting actions to only signed-in users

# Write a method that returns true or false based on if a user is signed in.
# Write a method that checks the return value of the method created in #1 and, if a user is not signed in, stores a message in the session and redirects to the index page.
# Call the method created in #2 at the beginning of actions that only signed-in users should access.
# Add additional tests to verify that signed-out users are handled properly.

