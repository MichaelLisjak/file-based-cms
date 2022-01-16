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

# Display overview of all available files
get "/" do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  erb :files
end

# Display a specific file
get "/:filename" do
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
  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:edited_content])

  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end

# 10. Adding global style and behaviour

# create a css file for the stylesheet
  # use sans-serif font and add a little padding around the outside
  # session message should have yellow background
  # use sans-serif typeface for everything but the display of textfiles
