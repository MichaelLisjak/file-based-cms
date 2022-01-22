ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

require_relative "../cms"

class CmsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  # Create documents for testing environment to work with
  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => { username: "admin" } }
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def test_index
    create_document "about.md"
    create_document "changes.txt"
    create_document "history.txt"
    
    get "/", {}, admin_session

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
  end

  def test_get_document_history
    create_document "history.txt", "Yukihiro Matsumoto released"
    get "/history.txt", {}, admin_session

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "Yukihiro Matsumoto"
    assert_includes last_response.body, "released"
  end

  def test_document_not_found
    get "/thisfilewillneverexist.xtx", {}, admin_session

    assert_equal 302, last_response.status
    assert_equal "thisfilewillneverexist.xtx does not exist.", session[:message]

    get last_response["Location"] # Request the page that the user was redirected to

    assert_equal 200, last_response.status

    get "/"
    refute_includes last_response.body, "thisfilewillneverexist.xtx does not exist." # Assert that our message has been removed
  end

  def test_viewing_markdown_document
    create_document "about.md", "<h1>Ruby is...</h1>"
    get "/about.md", {}, admin_session

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end

  def test_show_edit_form_page
    create_document "about.md"
    get "/about.md/edit", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<form action="
    assert_includes last_response.body, "method=\"post\""
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_post_request_for_file
    create_document "about.md"
    post "/about.md", {edited_content: @body}, admin_session
    assert_equal 302, last_response.status
    
    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "about.md has been updated."
  end

  def test_create_new_txt_or_md_file
    get "/new", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<form action=\"/new\""
    assert_includes last_response.body, "method=\"post\""
    assert_includes last_response.body, %q(<button type="submit")
    
    post "/new", new_document: "test.txt"

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "test.txt has been successfully created!"
  end

  def test_create_invalid_file
    get "/new", {}, admin_session

    assert_equal 200, last_response.status

    post "/new", new_document: "test.xtx"

    assert_equal last_response.status, 422
    assert_includes last_response.body, "file must be of type .txt or .md"

    get "/"
    refute_includes last_response.body, "file must be of type .txt or .md"
  end

  def test_delete_file
    create_document "test.md"
    post "/test.md/destroy", {}, admin_session

    assert_equal 302, last_response.status
    
    assert_equal "test.md has been deleted.", session[:message] 

    get "/"
  
    refute_equal "test.md has been deleted.", session[:message]
  end

  def test_signin_form
    get "/users/signin"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_signin
    post "/users/signin", username: "admin", password: "secret"
    assert_equal 302, last_response.status
    assert_equal "Welcome!", session[:message]
    assert_equal "admin", session[:username]

    get last_response["Location"]

    assert_includes last_response.body, "Signed in as admin"
  end

  def test_signin_with_bad_credentials
    post "/users/signin", username: "guest", password: "shhhh"
    assert_equal 422, last_response.status
    assert_nil session[:username]
    assert_includes last_response.body, "Invalid Credentials"
  end

  def test_signout
    get "/", {}, admin_session
    assert_includes last_response.body, "Signed in as admin"

    post "/users/signout"
    assert_equal "You have been signed out", session[:message]

    get last_response["Location"]
    assert_nil session[:username]
    # assert_includes last_response.body, "Sign In" # doesn't work
  end

  def test_restrict_actions_if_not_signed_in
    get "/new"
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
    
    create_document "testme.txt"
    get "/testme.txt"
    assert_equal "You must be signed in to do that.", session[:message]

    get "/testme.txt/edit"
    assert_equal "You must be signed in to do that.", session[:message]

    post "/testme.txt"
    assert_equal "You must be signed in to do that.", session[:message]

    post "testme.txt/destroy"
    assert_equal "You must be signed in to do that.", session[:message]

    # after signing in as admin, the you must be signed in ... message is not displayed anymore
    get "/new", {}, admin_session
    refute_equal "You must be signed in to do that.", session[:message]

    create_document "testme.txt"
    get "/testme.txt"
    refute_equal "You must be signed in to do that.", session[:message]

    get "/testme.txt/edit"
    refute_equal "You must be signed in to do that.", session[:message]

    assert_equal "admin", session[:username]
    post "testme.txt/destroy", {}, admin_session # don't know why I have to add the admin session again here
    assert_equal "admin", session[:username]
    refute_equal "You must be signed in to do that.", session[:message]

    post "/testme.txt"
    refute_equal "You must be signed in to do that.", session[:message]



  end
end