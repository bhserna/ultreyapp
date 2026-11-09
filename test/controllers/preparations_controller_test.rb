require "application_request_test_case"

class PreparationsControllerTest < ApplicationRequestTestCase
  test "reject an unknown preparation" do
    get preparation_url(Preparation.maximum(:id) + 1)

    assert_response :not_found
  end
end
