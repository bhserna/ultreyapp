require "test_helper"
require "rack/mock"
require "base64"

class BasicAuthenticationTest < ActiveSupport::TestCase
  setup do
    application = ->(_environment) { [ 200, { "content-type" => "text/plain" }, [ "allowed" ] ] }
    @request = Rack::MockRequest.new(BasicAuthentication.new(application, username: "ultreya", password: "secret"))
  end

  test "requires credentials for application pages and files" do
    [ "/", "/schedule_entries/1/documents", "/rails/active_storage/blobs/example" ].each do |path|
      response = @request.get(path)

      assert_equal 401, response.status
      assert_equal 'Basic realm="Ultreya 2026"', response["www-authenticate"]
    end
  end

  test "rejects incorrect credentials" do
    assert_equal 401, @request.get("/", "HTTP_AUTHORIZATION" => authorization("ultreya", "wrong")).status
    assert_equal 401, @request.get("/", "HTTP_AUTHORIZATION" => authorization("wrong", "secret")).status
  end

  test "accepts valid credentials" do
    assert_equal 200, @request.get("/", "HTTP_AUTHORIZATION" => authorization("ultreya", "secret")).status
  end

  test "keeps the health check accessible" do
    assert_equal 200, @request.get("/up").status
  end

  test "requires configured credentials at startup" do
    assert_raises(RuntimeError) do
      BasicAuthentication.new(->(_environment) { [ 200, {}, [] ] }, username: "", password: "")
    end
  end

  private

  def authorization(username, password)
    "Basic #{Base64.strict_encode64("#{username}:#{password}")}"
  end
end
