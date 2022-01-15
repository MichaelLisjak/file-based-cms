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

root = File.expand_path("..", __FILE__) # gets the current absolute directory of the ruby program that is running

# Return the filepath for a given file
def get_file_path(file_name)
  @root + "/data/" + file_name
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
    render_markdown(content)
  end
end

# Display overview of all available files
get "/" do
  @files = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end
  erb :files
end

# Display a specific file
get "/:filename" do
  file_path = root + "/data/" + params[:filename]

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

# Load the edit page for a document
get "/:filename/edit" do
  @filename = params[:filename]
  file_path = root + "/data/" + @filename

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
  file_path = root + "/data/" + params[:filename]

  File.write(file_path, params[:edited_content])

  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end



# 8. Editing Document Content
## add a link "Edit" for every file
## create a new route for a get request to "/:filename/edit"
  # in the route load a form for editing the contents and display the current content in the form
  # the form page needs a "save changes" button that submits the form to the server --> POST request route
  # after submitting the form, redirect to the main page and display a message "$filename has been updated."