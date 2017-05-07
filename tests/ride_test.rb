ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../ride"

class RideTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_home_page
    get "/home"
    assert_equal(200, last_response.status)
  end

  def test_distance_input_can_be_blank
    post "/rides/add", {distance: nil}
    assert_equal(302, last_response.status)
  end

  def test_invalid_character_for_distnace
    post "/rides/add", {distance: "invalid"}

    assert_equal(422, last_response.status)
    error_message = "Distance must be numeric. A decimal point is allowed."
    assert_includes(last_response.body, error_message)
  end

  def test_valid_distance_entry_no_decimal
    post "/rides/add", {distance: "40"}
    assert_equal(302, last_response.status)
    success_message = "Ride has been added successfully."
    assert_includes(last_response.body, success_message)
  end

  def test_valid_distance_entry_decimal
    post "/rides/add", {distance: "100.5"}
    assert_equal(302, last_response.status)
    success_message = "Ride has been added successfully."
    assert_includes(last_response.body, success_message)
  end
end