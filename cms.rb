require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "redcarpet"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
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

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
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




# create an if clause in the "/:file_name" that handles the response for non-existing files
# check if file exists with File.file?(file)
  # if yes, load contents into @contents and load file.erb
  # else use a flash error message that the file was not found and redirect to index page "/"
  