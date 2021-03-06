require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "redcarpet"
require "yaml"
require "bcrypt"
require "pry"

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

def image_path
  if ENV["RACK_ENV"] == "test"
    # gets the current absolute directory of the ruby program that is running
    File.expand_path("../test/public/images", __FILE__)
  else
    File.expand_path("../public/images", __FILE__)
  end
end

# Returns the given markdown file as HTML
def render_markdown(md_file)
  # Initialize Markdown object for converting markdown files into HTML
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(md_file)
end

# Loads the files content for displaying it in the browser
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

# Checks if a user is signed in
def user_signed_in?
  @users.keys.include?(session[:username])
end

# Checks if an action requires a user to be signed in
def require_signed_in_user
  if !user_signed_in?
    session[:message] = "You must be signed in to do that."
    redirect "/"
  end
end

# Checks if a user/password combination is valid
def user_valid?(username, password)
  @users.each do |user, pw|
    return true if (user == username && BCrypt::Password.new(pw) == password)
  end
  false
end

# Register a new user and save his credentials in the user.yaml file
def register_new_user(username, password)
  users = load_user_credentials
  if users.include?(username)
    session[:message] = "That username already exists"
    redirect "/"
  else
    hashed_password = BCrypt::Password.create(password)
    users[username] = hashed_password.to_s
    File.open("users.yaml", "w") { |file| YAML.dump(users, file)}
  end
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/users.yaml", __FILE__)
  else
    File.expand_path("../users.yaml", __FILE__)
  end
  YAML.load_file(credentials_path)
end

# Create incremented filename for duplicating names
def duplicate_filename(original_name)
  filename, extention = original_name.split(".")
  if filename[-1].to_i.to_s == filename[-1]
    new_increment = filename[-1].to_i + 1
    filename = filename[0..-2] + new_increment.to_s
  else
    filename = filename + "1"
  end
  filename + "." + extention 
end

before do
  @users = load_user_credentials
end

# --------------------- Routes -------------------------

# Display overview of all available files
get "/" do
  if user_signed_in?
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
    @content = File.read(file_path)
    erb :edit_file
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

# Load the upload form for images
get "/upload/image" do
  erb :upload_image
end

# Save the image in correct path
post "/upload/image" do
  image = params[:image_file]
  file_path = File.join(image_path, image[:filename])
  File.new(file_path, 111)
  #File.write(file_path, File.read(image))
  File.write(file_path, image)
  session[:message] = "image has been uploaded successfully"
  #redirect "/"
  params.to_s
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

post "/:filename/duplicate" do
  require_signed_in_user
  file_path = File.join(data_path, params[:filename])
  file_path_new_file = File.join(data_path, duplicate_filename(params[:filename]))
  File.new(file_path_new_file, 111)
  File.write(file_path_new_file, File.read(file_path))
  redirect "/"
end

# Form to login with username and password
get "/users/signin" do
erb :sign_in
end

# Handling the login data
post "/users/signin" do

  if user_valid?(params[:username], params[:password] )
    session[:username] = params[:username]
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

# register a new user
get "/users/register" do
  erb :register
end

post "/users/register" do
  register_new_user(params[:username], params[:password])
  redirect "/"
end

get "/test/test" do
  register_new_user("test123", "123456")
end

# 19. next steps

# We encourage you to explore this project further or create another of your own to practice some of the 
# techniques we've covered in this project and the course as a whole. Here are a few ideas:

## 1. Validate that document names contain an extension that the application supports.
# 2. Add a "duplicate" button that creates a new document based on an old one.
## 3. Extend this project with a user signup form.
# 4. Add the ability to upload images to the CMS (which could be referenced within markdown files).
# 5. Modify the CMS so that each version of a document is preserved as changes are made to it.

# 4. upload images in the CMS
  # create an upload form for pictures
  # store uploaded images in public/images
  # find out what kind of picture files can be referenced within markdown files
  # check out how to reference pictures in markdown

  # create a get route for the image upload form
  # create a post route to handle the image upload


     


# TODO
  # when duplicating files, make sure to not overwrite files. eg. file, file1 - duplicate file --> file1 gets overwritten
  # 