require "test_helper"

class PreparationsControllerTest < ActionDispatch::IntegrationTest
  test "reject an unknown preparation" do
    get preparation_url(Preparation.maximum(:id) + 1)

    assert_response :not_found
  end
end
