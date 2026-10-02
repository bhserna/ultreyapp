require "rack/auth/basic"
require "active_support/security_utils"

class BasicAuthentication
  def initialize(app, username:, password:)
    @app = app
    @authentication = Rack::Auth::Basic.new(app, "Ultreya 2026") do |provided_username, provided_password|
      ActiveSupport::SecurityUtils.secure_compare(provided_username, username) &
        ActiveSupport::SecurityUtils.secure_compare(provided_password, password)
    end
  end

  def call(environment)
    return @app.call(environment) if environment["PATH_INFO"] == "/up"

    @authentication.call(environment)
  end
end
