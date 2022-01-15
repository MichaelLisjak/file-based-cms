ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../cms"

class CmsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    # load the content of about.md to use for the post request test, so the file's content stays the same
    get "/about.md"
    @body = last_response.body
  end

  def test_index
    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
  end

  def test_get_document_history
    get "/history.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "Yukihiro Matsumoto"
    assert_includes last_response.body, "released"
  end

  def test_document_not_found
    get "/thisfilewillneverexist.xtx"

    assert_equal 302, last_response.status

    get last_response["Location"] # Request the page that the user was redirected to

    assert_equal 200, last_response.status
    assert_includes last_response.body, "thisfilewillneverexist.xtx does not exist."

    get "/"
    refute_includes last_response.body, "thisfilewillneverexist.xtx does not exist." # Assert that our message has been removed
  end

  def test_viewing_markdown_document
    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end

  def test_show_edit_form_page
    get "/about.md/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<form action="
    assert_includes last_response.body, "method=\"post\""
  end

  def test_post_request_for_file
    post "/about.md", edited_content: @body
    assert_equal 302, last_response.status
    
    get "/"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "about.md has been updated."
  end
end